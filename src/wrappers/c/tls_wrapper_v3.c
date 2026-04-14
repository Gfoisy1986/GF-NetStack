// ============================================================================
// tls_wrapper_v3.c
// BearSSL 0.6
// - Non-blocking multi-client TLS server (JSON length-prefixed)
// - Blocking PB-friendly TLS client (JSON length-prefixed)
// - CERT + KEY in DER (no PEM, no base64, no pemdec)
// ============================================================================

#include <arpa/inet.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <errno.h>
#include <stdint.h>

#include <bearssl.h>



static int tls_low_read(void *ctx, unsigned char *buf, size_t len) {
    int fd = *(int*)ctx;
    ssize_t r = read(fd, buf, len);
    if (r < 0) return -1;
    return (int)r;
}

static int tls_low_write(void *ctx, const unsigned char *buf, size_t len) {
    int fd = *(int*)ctx;
    ssize_t r = write(fd, buf, len);
    if (r < 0) return -1;
    return (int)r;
}


// ============================================================================
// CONFIGURATION
// ============================================================================

#define TLSV2_MAX_CLIENTS        64
#define TLSV2_MAX_JSON_SIZE      65536

// BearSSL buffers
#define TLSV2_IOBUF_SIZE         (16 * 1024)   // encrypted I/O buffer
#define TLSV2_PLAINTEXT_SIZE     (70 * 1024)   // decrypted plaintext buffer

// ============================================================================
// SERVER TYPES
// ============================================================================

typedef enum {
    TLSV2_STATE_UNUSED = 0,
    TLSV2_STATE_HANDSHAKE,
    TLSV2_STATE_OPEN,
    TLSV2_STATE_CLOSING
} tlsv2_client_state_t;

typedef struct tlsv2_client_s {
    int fd;

    // BearSSL engine
    br_ssl_server_context sc;
    br_x509_certificate   *certs;
    size_t                 certs_len;
    br_rsa_private_key     skey;

    unsigned char iobuf[TLSV2_IOBUF_SIZE];
    unsigned char plainbuf[TLSV2_PLAINTEXT_SIZE];

    tlsv2_client_state_t state;

    // JSON framing
    unsigned char in_buf[TLSV2_MAX_JSON_SIZE + 4];
    size_t        in_used;
    uint32_t      expected_len;

    unsigned char out_buf[TLSV2_MAX_JSON_SIZE + 4];
    size_t        out_used;
    size_t        out_sent;

} tlsv2_client_t;

typedef void (*tlsv2_on_client_connected)(int client_id);
typedef void (*tlsv2_on_client_disconnected)(int client_id);
typedef void (*tlsv2_on_json_received)(int client_id, const char *json, size_t len);

typedef struct {
    int port;
    const char *cert_file; // DER
    const char *key_file;  // DER

    tlsv2_on_client_connected    on_client_connected;
    tlsv2_on_client_disconnected on_client_disconnected;
    tlsv2_on_json_received       on_json_received;
} tlsv2_server_config_t;

// ============================================================================
// GLOBALS
// ============================================================================

static tlsv2_client_t        g_clients[TLSV2_MAX_CLIENTS];
static tlsv2_server_config_t g_cfg;
static int                   g_listen_fd = -1;

// We must keep DER buffers alive for the lifetime of the server
static unsigned char        *g_cert_der_buf = NULL;
static br_x509_certificate  *g_certs        = NULL;
static size_t                g_certs_len    = 0;

static unsigned char        *g_key_der_buf  = NULL;
static br_rsa_private_key    g_skey;

// ============================================================================
// HELPER: Make socket non-blocking
// ============================================================================

static int make_nonblocking(int fd) {
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags < 0) return -1;
    if (fcntl(fd, F_SETFL, flags | O_NONBLOCK) < 0) return -1;
    return 0;
}

// ============================================================================
// DER LOADERS (NO PEM, NO BASE64)
// ============================================================================

static unsigned char *load_der(const char *path, size_t *out_len) {
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;

    if (fseek(f, 0, SEEK_END) != 0) {
        fclose(f);
        return NULL;
    }
    long sz = ftell(f);
    if (sz <= 0) {
        fclose(f);
        return NULL;
    }
    if (fseek(f, 0, SEEK_SET) != 0) {
        fclose(f);
        return NULL;
    }

    unsigned char *buf = malloc((size_t)sz);
    if (!buf) {
        fclose(f);
        return NULL;
    }

    if (fread(buf, 1, (size_t)sz, f) != (size_t)sz) {
        fclose(f);
        free(buf);
        return NULL;
    }

    fclose(f);
    *out_len = (size_t)sz;
    return buf;
}

// Load certificate chain from DER (single cert)
static int load_certificate_der(const char *path,
                                br_x509_certificate **out_certs,
                                size_t *out_len,
                                unsigned char **out_der_buf)
{
    size_t der_len;
    unsigned char *der = load_der(path, &der_len);
    if (!der) return -1;

    br_x509_certificate *certs = malloc(sizeof(br_x509_certificate));
    if (!certs) {
        free(der);
        return -1;
    }

    certs[0].data = der;
    certs[0].data_len = der_len;

    *out_certs   = certs;
    *out_len     = 1;
    *out_der_buf = der;
    return 0;
}

// Load RSA private key from DER
static int load_rsa_key_der(const char *path,
                            br_rsa_private_key *out_skey,
                            unsigned char **out_der_buf)
{
    size_t der_len;
    unsigned char *der = load_der(path, &der_len);
    if (!der) return -1;

    br_skey_decoder_context kc;
    br_skey_decoder_init(&kc);
    br_skey_decoder_push(&kc, der, der_len);

    if (br_skey_decoder_last_error(&kc) != 0) {
        free(der);
        return -1;
    }

    const br_rsa_private_key *k = br_skey_decoder_get_rsa(&kc);
    if (!k) {
        free(der);
        return -1;
    }

    *out_skey = *k;
    *out_der_buf = der; // must stay alive
    return 0;
}

// ============================================================================
// CLIENT INITIALIZATION
// ============================================================================

static void tlsv2_clients_init(void) {
    for (int i = 0; i < TLSV2_MAX_CLIENTS; i++) {
        g_clients[i].fd = -1;
        g_clients[i].state = TLSV2_STATE_UNUSED;
        g_clients[i].in_used = 0;
        g_clients[i].expected_len = 0;
        g_clients[i].out_used = 0;
        g_clients[i].out_sent = 0;
        g_clients[i].certs = NULL;
        g_clients[i].certs_len = 0;
    }
}

static tlsv2_client_t *tlsv2_client_alloc(int fd,
                                          br_x509_certificate *certs,
                                          size_t certs_len,
                                          const br_rsa_private_key *skey)
{
    for (int i = 0; i < TLSV2_MAX_CLIENTS; i++) {
        if (g_clients[i].state == TLSV2_STATE_UNUSED) {

            tlsv2_client_t *c = &g_clients[i];
            c->fd = fd;
            c->state = TLSV2_STATE_HANDSHAKE;

            // Copy cert chain + key struct (pointers remain valid because DER buffers are global)
            c->certs = certs;
            c->certs_len = certs_len;
            c->skey = *skey;

            // Reset JSON buffers
            c->in_used = 0;
            c->expected_len = 0;
            c->out_used = 0;
            c->out_sent = 0;

            // Initialize BearSSL server engine
            br_ssl_server_init_full_rsa(
                &c->sc,
                c->certs,
                c->certs_len,
                &c->skey
            );

            // Set I/O buffers
            br_ssl_engine_set_buffers_bidi(
                &c->sc.eng,
                c->iobuf, TLSV2_IOBUF_SIZE,
                c->plainbuf, TLSV2_PLAINTEXT_SIZE
            );

            // Start handshake
            br_ssl_server_reset(&c->sc);

            return c;
        }
    }
    return NULL;
}

// ============================================================================
// CLOSE CLIENT
// ============================================================================

static void tlsv2_client_close(tlsv2_client_t *c) {
    if (!c || c->state == TLSV2_STATE_UNUSED)
        return;

    int fd = c->fd;

    if (fd >= 0)
        close(fd);

    c->fd = -1;
    c->state = TLSV2_STATE_UNUSED;

    if (g_cfg.on_client_disconnected && fd >= 0)
        g_cfg.on_client_disconnected(fd);
}

// ============================================================================
// ACCEPT NEW CLIENT (NON-BLOCKING)
// ============================================================================

static void tlsv2_accept_new_client(br_x509_certificate *certs,
                                    size_t certs_len,
                                    const br_rsa_private_key *skey)
{
    for (;;) {
        int client_fd = accept(g_listen_fd, NULL, NULL);
        if (client_fd < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK)
                break;
            perror("accept");
            break;
        }

        if (make_nonblocking(client_fd) < 0) {
            perror("fcntl");
            close(client_fd);
            continue;
        }

        tlsv2_client_t *c = tlsv2_client_alloc(client_fd, certs, certs_len, skey);
        if (!c) {
            fprintf(stderr, "[tlsv2] Max clients reached\n");
            close(client_fd);
            continue;
        }

        if (g_cfg.on_client_connected)
            g_cfg.on_client_connected(client_fd);
    }
}

// ============================================================================
// TLS ENGINE: FEED SOCKET → ENGINE (encrypted input)
// ============================================================================

static int tlsv2_engine_recv(tlsv2_client_t *c) {
    unsigned char *buf;
    size_t len;

    for (;;) {
        int st = br_ssl_engine_current_state(&c->sc.eng);

        if (!(st & BR_SSL_RECVREC))
            return 0;

        buf = br_ssl_engine_recvrec_buf(&c->sc.eng, &len);
        if (len == 0)
            return 0;

        int r = read(c->fd, buf, len);
        if (r > 0) {
            br_ssl_engine_recvrec_ack(&c->sc.eng, r);
        } else {
            if (r < 0 && (errno == EAGAIN || errno == EWOULDBLOCK))
                return 0;
            return -1;
        }
    }
}

// ============================================================================
// TLS ENGINE: FEED ENGINE → SOCKET (encrypted output)
// ============================================================================

static int tlsv2_engine_send(tlsv2_client_t *c) {
    unsigned char *buf;
    size_t len;

    for (;;) {
        int st = br_ssl_engine_current_state(&c->sc.eng);

        if (!(st & BR_SSL_SENDREC))
            return 0;

        buf = br_ssl_engine_sendrec_buf(&c->sc.eng, &len);
        if (len == 0)
            return 0;

        int r = write(c->fd, buf, len);
        if (r > 0) {
            br_ssl_engine_sendrec_ack(&c->sc.eng, r);
        } else {
            if (r < 0 && (errno == EAGAIN || errno == EWOULDBLOCK))
                return 0;
            return -1;
        }
    }
}

// ============================================================================
// TLS ENGINE: READ PLAINTEXT FROM ENGINE → JSON FRAMING
// ============================================================================

static int tlsv2_engine_read_plain(tlsv2_client_t *c) {
    unsigned char *buf;
    size_t len;

    for (;;) {
        int st = br_ssl_engine_current_state(&c->sc.eng);

        if (!(st & BR_SSL_RECVAPP))
            return 0;

        buf = br_ssl_engine_recvapp_buf(&c->sc.eng, &len);
        if (len == 0)
            return 0;

        if (c->in_used + len > sizeof(c->in_buf))
            return -1;

        memcpy(c->in_buf + c->in_used, buf, len);
        c->in_used += len;

        br_ssl_engine_recvapp_ack(&c->sc.eng, len);

        for (;;) {
            if (c->expected_len == 0) {
                if (c->in_used >= 4) {
                    uint32_t nlen;
                    memcpy(&nlen, c->in_buf, 4);
                    c->expected_len = ntohl(nlen);
                    if (c->expected_len > TLSV2_MAX_JSON_SIZE)
                        return -1;
                } else {
                    break;
                }
            }

            if (c->expected_len > 0 &&
                c->in_used >= 4 + c->expected_len)
            {
                size_t json_len = c->expected_len;
                char *json = malloc(json_len + 1);
                if (!json)
                    return -1;

                memcpy(json, c->in_buf + 4, json_len);
                json[json_len] = 0;

                size_t rem = c->in_used - (4 + json_len);
                memmove(c->in_buf, c->in_buf + 4 + json_len, rem);
                c->in_used = rem;
                c->expected_len = 0;

                if (g_cfg.on_json_received)
                    g_cfg.on_json_received(c->fd, json, json_len);

                free(json);
            } else {
                break;
            }
        }
    }
}

// ============================================================================
// TLS ENGINE: WRITE PLAINTEXT → ENGINE (JSON OUT)
// ============================================================================

static int tlsv2_engine_write_plain(tlsv2_client_t *c) {
    if (c->out_sent >= c->out_used)
        return 0;

    unsigned char *buf;
    size_t len;

    for (;;) {
        int st = br_ssl_engine_current_state(&c->sc.eng);

        if (!(st & BR_SSL_SENDAPP))
            return 0;

        buf = br_ssl_engine_sendapp_buf(&c->sc.eng, &len);
        if (len == 0)
            return 0;

        size_t to_copy = c->out_used - c->out_sent;
        if (to_copy > len)
            to_copy = len;

        memcpy(buf, c->out_buf + c->out_sent, to_copy);
        c->out_sent += to_copy;

        br_ssl_engine_sendapp_ack(&c->sc.eng, to_copy);

        if (c->out_sent >= c->out_used) {
            c->out_used = 0;
            c->out_sent = 0;
            return 1;
        }
    }
}

// ============================================================================
// HANDLE CLIENT (READ + WRITE + HANDSHAKE)
// ============================================================================

static void tlsv2_handle_client(tlsv2_client_t *c) {
    if (!c || c->state == TLSV2_STATE_UNUSED)
        return;

    if (tlsv2_engine_recv(c) < 0 ||
        tlsv2_engine_send(c) < 0)
    {
        tlsv2_client_close(c);
        return;
    }

    int st = br_ssl_engine_current_state(&c->sc.eng);

    if (c->state == TLSV2_STATE_HANDSHAKE) {
        if (st & BR_SSL_CLOSED) {
            tlsv2_client_close(c);
            return;
        }
        if (st & BR_SSL_SENDAPP) {
            c->state = TLSV2_STATE_OPEN;
        }
    }

    if (c->state == TLSV2_STATE_OPEN) {
        if (tlsv2_engine_read_plain(c) < 0 ||
            tlsv2_engine_write_plain(c) < 0)
        {
            tlsv2_client_close(c);
            return;
        }
    }

    if (tlsv2_engine_send(c) < 0)
        tlsv2_client_close(c);
}

// ============================================================================
// PUBLIC API: SEND JSON TO CLIENT
// ============================================================================

int tlsv2_send_json(int client_id, const char *json, size_t len) {
    if (len > TLSV2_MAX_JSON_SIZE)
        return -1;

    for (int i = 0; i < TLSV2_MAX_CLIENTS; i++) {
        tlsv2_client_t *c = &g_clients[i];
        if (c->state != TLSV2_STATE_UNUSED && c->fd == client_id) {

            if (c->out_used != c->out_sent)
                return -2;

            uint32_t nlen = htonl((uint32_t)len);
            memcpy(c->out_buf, &nlen, 4);
            memcpy(c->out_buf + 4, json, len);

            c->out_used = 4 + len;
            c->out_sent = 0;
            return 0;
        }
    }
    return -1;
}

// ============================================================================
// CREATE LISTEN SOCKET
// ============================================================================

static int tlsv2_create_listen_socket(int port) {
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        perror("socket");
        return -1;
    }

    int opt = 1;
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family      = AF_INET;
    addr.sin_port        = htons(port);
    addr.sin_addr.s_addr = INADDR_ANY;

    if (bind(sock, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        perror("bind");
        close(sock);
        return -1;
    }

    if (listen(sock, 16) < 0) {
        perror("listen");
        close(sock);
        return -1;
    }

    if (make_nonblocking(sock) < 0) {
        perror("fcntl");
        close(sock);
        return -1;
    }

    return sock;
}

// ============================================================================
// MAIN SERVER LOOP
// ============================================================================

int tlsv2_server_run(const tlsv2_server_config_t *cfg) {
    if (!cfg || !cfg->cert_file || !cfg->key_file) {
        fprintf(stderr, "[tlsv2] Invalid server config\n");
        return -1;
    }

    g_cfg = *cfg;

    if (load_certificate_der(cfg->cert_file,
                             &g_certs,
                             &g_certs_len,
                             &g_cert_der_buf) < 0)
    {
        fprintf(stderr, "[tlsv2] Failed to load DER certificate\n");
        return -1;
    }

    if (load_rsa_key_der(cfg->key_file,
                         &g_skey,
                         &g_key_der_buf) < 0)
    {
        fprintf(stderr, "[tlsv2] Failed to load DER RSA key\n");
        return -1;
    }

    tlsv2_clients_init();

    g_listen_fd = tlsv2_create_listen_socket(cfg->port);
    if (g_listen_fd < 0)
        return -1;

    fprintf(stderr, "[tlsv2] Server listening on port %d\n", cfg->port);

    for (;;) {
        fd_set readfds, writefds;
        FD_ZERO(&readfds);
        FD_ZERO(&writefds);

        FD_SET(g_listen_fd, &readfds);
        int maxfd = g_listen_fd;

        for (int i = 0; i < TLSV2_MAX_CLIENTS; i++) {
            tlsv2_client_t *c = &g_clients[i];
            if (c->state == TLSV2_STATE_UNUSED)
                continue;

            FD_SET(c->fd, &readfds);
            FD_SET(c->fd, &writefds);

            if (c->fd > maxfd)
                maxfd = c->fd;
        }

        int ret = select(maxfd + 1, &readfds, &writefds, NULL, NULL);
        if (ret < 0) {
            if (errno == EINTR)
                continue;
            perror("select");
            break;
        }

        if (FD_ISSET(g_listen_fd, &readfds)) {
            tlsv2_accept_new_client(g_certs, g_certs_len, &g_skey);
        }

        for (int i = 0; i < TLSV2_MAX_CLIENTS; i++) {
            tlsv2_client_t *c = &g_clients[i];
            if (c->state == TLSV2_STATE_UNUSED)
                continue;

            if (FD_ISSET(c->fd, &readfds) ||
                FD_ISSET(c->fd, &writefds))
            {
                tlsv2_handle_client(c);
            }
        }
    }

    close(g_listen_fd);
    g_listen_fd = -1;

    for (int i = 0; i < TLSV2_MAX_CLIENTS; i++)
        tlsv2_client_close(&g_clients[i]);

    return 0;
}

// ============================================================================
// CLIENT SIDE (BLOCKING, PB-FRIENDLY) — BearSSL br_sslio
// ============================================================================

typedef struct tlsv2_client_conn_s {
    int   sock;
    br_ssl_client_context sc;
    br_x509_minimal_context xc;
    br_sslio_context ioc;

    unsigned char iobuf[TLSV2_IOBUF_SIZE];
    unsigned char plainbuf[TLSV2_PLAINTEXT_SIZE];

} tlsv2_client_conn_t;

#define TLSV2_MAX_CLIENT_CONNS 64
static tlsv2_client_conn_t *g_client_conns[TLSV2_MAX_CLIENT_CONNS] = {0};

static void tlsv2_register_client_conn(tlsv2_client_conn_t *c) {
    for (int i = 0; i < TLSV2_MAX_CLIENT_CONNS; i++) {
        if (!g_client_conns[i]) {
            g_client_conns[i] = c;
            return;
        }
    }
}

static tlsv2_client_conn_t *tlsv2_lookup_client_conn(int sock) {
    for (int i = 0; i < TLSV2_MAX_CLIENT_CONNS; i++) {
        if (g_client_conns[i] && g_client_conns[i]->sock == sock)
            return g_client_conns[i];
    }
    return NULL;
}

static void tlsv2_unregister_client_conn(int sock) {
    for (int i = 0; i < TLSV2_MAX_CLIENT_CONNS; i++) {
        if (g_client_conns[i] && g_client_conns[i]->sock == sock) {
            g_client_conns[i] = NULL;
            return;
        }
    }
}

// ============================================================================
// CLIENT INIT
// ============================================================================

int tlsv2_client_init(void) {
    return 0;
}

// ============================================================================
// CLIENT CONNECT (BLOCKING)
// ============================================================================

int tlsv2_client_connect(const char *host, int port) {
    tlsv2_client_conn_t *c = calloc(1, sizeof(tlsv2_client_conn_t));
    if (!c) return -1;

    c->sock = socket(AF_INET, SOCK_STREAM, 0);
    if (c->sock < 0) {
        free(c);
        return -1;
    }

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port   = htons(port);
    if (inet_pton(AF_INET, host, &addr.sin_addr) <= 0) {
        close(c->sock);
        free(c);
        return -1;
    }

    if (connect(c->sock, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        close(c->sock);
        free(c);
        return -2;
    }

    br_x509_minimal_init(&c->xc, &br_sha256_vtable, NULL, 0);
    br_ssl_client_init_full(&c->sc, &c->xc, NULL, 0);

    br_ssl_engine_set_buffers_bidi(
        &c->sc.eng,
        c->iobuf, TLSV2_IOBUF_SIZE,
        c->plainbuf, TLSV2_PLAINTEXT_SIZE
    );

    br_ssl_client_reset(&c->sc, host, 0);

    br_sslio_init(&c->ioc,
              &c->sc.eng,
              tls_low_read,  &c->sock,
              tls_low_write, &c->sock);

    if (br_sslio_flush(&c->ioc) < 0) {
        close(c->sock);
        free(c);
        return -3;
    }

    tlsv2_register_client_conn(c);
    return c->sock;
}

// ============================================================================
// CLIENT SEND JSON (BLOCKING)
// ============================================================================

int tlsv2_client_send_json(int sock, const char *json, size_t len) {
    tlsv2_client_conn_t *c = tlsv2_lookup_client_conn(sock);
    if (!c) return -1;

    if (len > TLSV2_MAX_JSON_SIZE)
        return -2;

    uint32_t nlen = htonl((uint32_t)len);

    if (br_sslio_write_all(&c->ioc, &nlen, 4) < 0)
        return -3;

    if (br_sslio_write_all(&c->ioc, json, len) < 0)
        return -4;

    if (br_sslio_flush(&c->ioc) < 0)
        return -5;

    return 0;
}

// ============================================================================
// CLIENT RECEIVE JSON (BLOCKING)
// ============================================================================

int tlsv2_client_recv_json(int sock, char *buf, size_t maxlen) {
    tlsv2_client_conn_t *c = tlsv2_lookup_client_conn(sock);
    if (!c) return -1;

    uint32_t nlen;

    int r = br_sslio_read(&c->ioc, &nlen, 4);
    if (r != 4)
        return -2;

    nlen = ntohl(nlen);

    if (nlen + 1 > maxlen)
        return -3;

    size_t total = 0;
    while (total < nlen) {
        int rr = br_sslio_read(&c->ioc, buf + total, nlen - total);
        if (rr <= 0)
            return -4;
        total += rr;
    }

    buf[nlen] = 0;
    return (int)nlen;
}

// ============================================================================
// CLIENT CLOSE
// ============================================================================

void tlsv2_client_close_fd(int sock) {
    tlsv2_client_conn_t *c = tlsv2_lookup_client_conn(sock);
    if (!c) return;

    close(c->sock);
    tlsv2_unregister_client_conn(sock);
    free(c);
}
