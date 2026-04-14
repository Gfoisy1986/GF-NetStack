// tls_v2.c
// Non-blocking, multi-client, JSON-framed TLS server (OpenSSL)
// + Blocking, PB-friendly TLS client

#include <arpa/inet.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <errno.h>

#include <openssl/ssl.h>
#include <openssl/err.h>

#define TLSV2_MAX_CLIENTS    256
#define TLSV2_MAX_JSON_SIZE  65536   // <--- aligné avec #MAX_JSON PB

// ======================================================
// SERVER-SIDE TYPES AND GLOBALS
// ======================================================

typedef enum {
    TLSV2_STATE_UNUSED = 0,
    TLSV2_STATE_HANDSHAKE,
    TLSV2_STATE_OPEN,
    TLSV2_STATE_CLOSING
} tlsv2_client_state_t;

typedef struct tlsv2_client_s {
    int                  fd;
    SSL                 *ssl;
    tlsv2_client_state_t state;

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
    int  port;
    const char *cert_file;
    const char *key_file;

    tlsv2_on_client_connected    on_client_connected;
    tlsv2_on_client_disconnected on_client_disconnected;
    tlsv2_on_json_received       on_json_received;
} tlsv2_server_config_t;

static tlsv2_client_t        g_clients[TLSV2_MAX_CLIENTS];
static tlsv2_server_config_t g_cfg;
static SSL_CTX              *g_ctx_server = NULL;
static int                   g_listen_fd  = -1;

// ---------------------------------------------------------
// Helpers
// ---------------------------------------------------------
static void tlsv2_log_ssl_error(const char *msg) {
    fprintf(stderr, "[tlsv2] %s\n", msg);
    ERR_print_errors_fp(stderr);
}

static int make_nonblocking(int fd) {
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags < 0) return -1;
    if (fcntl(fd, F_SETFL, flags | O_NONBLOCK) < 0) return -1;
    return 0;
}

static void tlsv2_clients_init(void) {
    for (int i = 0; i < TLSV2_MAX_CLIENTS; i++) {
        g_clients[i].fd    = -1;
        g_clients[i].ssl   = NULL;
        g_clients[i].state = TLSV2_STATE_UNUSED;
        g_clients[i].in_used      = 0;
        g_clients[i].expected_len = 0;
        g_clients[i].out_used     = 0;
        g_clients[i].out_sent     = 0;
    }
}

static tlsv2_client_t *tlsv2_client_alloc(int fd, SSL *ssl) {
    for (int i = 0; i < TLSV2_MAX_CLIENTS; i++) {
        if (g_clients[i].state == TLSV2_STATE_UNUSED) {
            g_clients[i].fd    = fd;
            g_clients[i].ssl   = ssl;
            g_clients[i].state = TLSV2_STATE_HANDSHAKE;
            g_clients[i].in_used      = 0;
            g_clients[i].expected_len = 0;
            g_clients[i].out_used     = 0;
            g_clients[i].out_sent     = 0;
            return &g_clients[i];
        }
    }
    return NULL;
}

static void tlsv2_client_close(tlsv2_client_t *c) {
    if (!c || c->state == TLSV2_STATE_UNUSED) return;

    int fd = c->fd;

    if (c->ssl) {
        SSL_shutdown(c->ssl);
        SSL_free(c->ssl);
        c->ssl = NULL;
    }
    if (fd >= 0) {
        close(fd);
    }

    c->fd    = -1;
    c->state = TLSV2_STATE_UNUSED;
    c->in_used      = 0;
    c->expected_len = 0;
    c->out_used     = 0;
    c->out_sent     = 0;

    if (g_cfg.on_client_disconnected && fd >= 0) {
        g_cfg.on_client_disconnected(fd);
    }
}

// ---------------------------------------------------------
// JSON framing helpers (length-prefixed)
// ---------------------------------------------------------

static int tlsv2_json_queue_send(tlsv2_client_t *c, const char *json, size_t len) {
    if (!c || c->state != TLSV2_STATE_OPEN) return -1;
    if (len > TLSV2_MAX_JSON_SIZE) return -1;

    if (c->out_used != c->out_sent) {
        return -2; // previous message still pending
    }

    uint32_t nlen = htonl((uint32_t)len);
    memcpy(c->out_buf, &nlen, 4);
    memcpy(c->out_buf + 4, json, len);

    c->out_used = 4 + len;
    c->out_sent = 0;
    return 0;
}

static int tlsv2_json_flush(tlsv2_client_t *c) {
    if (!c || c->state != TLSV2_STATE_OPEN) return -1;
    if (c->out_sent >= c->out_used) return 0;

    int to_send = (int)(c->out_used - c->out_sent);
    int ret = SSL_write(c->ssl, c->out_buf + c->out_sent, to_send);

    if (ret > 0) {
        c->out_sent += ret;
        if (c->out_sent >= c->out_used) {
            c->out_used = 0;
            c->out_sent = 0;
        }
        return 1;
    }

    int err = SSL_get_error(c->ssl, ret);
    if (err == SSL_ERROR_WANT_READ || err == SSL_ERROR_WANT_WRITE) {
        return 0;
    }

    return -1;
}

static int tlsv2_json_try_receive(tlsv2_client_t *c) {
    if (!c || c->state != TLSV2_STATE_OPEN) return -1;

    for (;;) {
        int ret = SSL_read(c->ssl,
                           c->in_buf + c->in_used,
                           sizeof(c->in_buf) - c->in_used);
        if (ret > 0) {
            c->in_used += ret;
        } else {
            int err = SSL_get_error(c->ssl, ret);
            if (err == SSL_ERROR_WANT_READ || err == SSL_ERROR_WANT_WRITE) {
                break;
            }
            return -1;
        }

        for (;;) {
            if (c->expected_len == 0) {
                if (c->in_used >= 4) {
                    uint32_t nlen;
                    memcpy(&nlen, c->in_buf, 4);
                    c->expected_len = ntohl(nlen);
                    if (c->expected_len > TLSV2_MAX_JSON_SIZE) {
                        return -1;
                    }
                } else {
                    break;
                }
            }

            if (c->expected_len > 0 &&
                c->in_used >= 4 + c->expected_len) {

                size_t json_len = c->expected_len;
                char *json = (char*)malloc(json_len + 1);
                if (!json) return -1;

                memcpy(json, c->in_buf + 4, json_len);
                json[json_len] = '\0';

                size_t remaining = c->in_used - (4 + c->expected_len);
                memmove(c->in_buf,
                        c->in_buf + 4 + c->expected_len,
                        remaining);
                c->in_used      = remaining;
                c->expected_len = 0;

                if (g_cfg.on_json_received) {
                    g_cfg.on_json_received(c->fd, json, json_len);
                }

                free(json);
            } else {
                break;
            }
        }
    }

    return 0;
}

// ---------------------------------------------------------
// TLS server init
// ---------------------------------------------------------

static int tlsv2_init_openssl(void) {
    SSL_library_init();
    SSL_load_error_strings();
    OpenSSL_add_all_algorithms();
    return 0;
}

static int tlsv2_init_server_ctx(const char *cert_file, const char *key_file) {
    g_ctx_server = SSL_CTX_new(TLS_server_method());
    if (!g_ctx_server) {
        tlsv2_log_ssl_error("SSL_CTX_new failed");
        return -1;
    }

    if (SSL_CTX_use_certificate_file(g_ctx_server, cert_file, SSL_FILETYPE_PEM) <= 0) {
        tlsv2_log_ssl_error("SSL_CTX_use_certificate_file failed");
        return -1;
    }

    if (SSL_CTX_use_PrivateKey_file(g_ctx_server, key_file, SSL_FILETYPE_PEM) <= 0) {
        tlsv2_log_ssl_error("SSL_CTX_use_PrivateKey_file failed");
        return -1;
    }

    if (!SSL_CTX_check_private_key(g_ctx_server)) {
        fprintf(stderr, "[tlsv2] Private key does not match certificate\n");
        return -1;
    }

    return 0;
}

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

// ---------------------------------------------------------
// Accept new client (non-blocking)
// ---------------------------------------------------------

static void tlsv2_accept_new_client(void) {
    for (;;) {
        int client_fd = accept(g_listen_fd, NULL, NULL);
        if (client_fd < 0) {
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                break;
            }
            perror("accept");
            break;
        }

        if (make_nonblocking(client_fd) < 0) {
            perror("fcntl");
            close(client_fd);
            continue;
        }

        SSL *ssl = SSL_new(g_ctx_server);
        if (!ssl) {
            tlsv2_log_ssl_error("SSL_new failed");
            close(client_fd);
            continue;
        }

        SSL_set_fd(ssl, client_fd);

        tlsv2_client_t *c = tlsv2_client_alloc(client_fd, ssl);
        if (!c) {
            fprintf(stderr, "[tlsv2] Max clients reached\n");
            SSL_free(ssl);
            close(client_fd);
            continue;
        }

        if (g_cfg.on_client_connected) {
            g_cfg.on_client_connected(client_fd);
        }
    }
}

// ---------------------------------------------------------
// Handle handshake and I/O for a client
// ---------------------------------------------------------

static void tlsv2_handle_client_read(tlsv2_client_t *c) {
    if (!c) return;

    if (c->state == TLSV2_STATE_HANDSHAKE) {
        int ret = SSL_accept(c->ssl);
        if (ret > 0) {
            c->state = TLSV2_STATE_OPEN;
        } else {
            int err = SSL_get_error(c->ssl, ret);
            if (err == SSL_ERROR_WANT_READ || err == SSL_ERROR_WANT_WRITE) {
                return;
            }
            tlsv2_client_close(c);
        }
        return;
    }

    if (c->state == TLSV2_STATE_OPEN) {
        if (tlsv2_json_try_receive(c) < 0) {
            tlsv2_client_close(c);
        }
    }
}

static void tlsv2_handle_client_write(tlsv2_client_t *c) {
    if (!c) return;

    if (c->state == TLSV2_STATE_HANDSHAKE) {
        int ret = SSL_accept(c->ssl);
        if (ret > 0) {
            c->state = TLSV2_STATE_OPEN;
        } else {
            int err = SSL_get_error(c->ssl, ret);
            if (err == SSL_ERROR_WANT_READ || err == SSL_ERROR_WANT_WRITE) {
                return;
            }
            tlsv2_client_close(c);
        }
        return;
    }

    if (c->state == TLSV2_STATE_OPEN) {
        if (tlsv2_json_flush(c) < 0) {
            tlsv2_client_close(c);
        }
    }
}

// ---------------------------------------------------------
// Public server API
// ---------------------------------------------------------

int tlsv2_server_run(const tlsv2_server_config_t *cfg) {
    if (!cfg || !cfg->cert_file || !cfg->key_file) {
        fprintf(stderr, "[tlsv2] Invalid server config\n");
        return -1;
    }

    g_cfg = *cfg;

    if (tlsv2_init_openssl() < 0) {
        return -1;
    }

    if (tlsv2_init_server_ctx(cfg->cert_file, cfg->key_file) < 0) {
        return -1;
    }

    tlsv2_clients_init();

    g_listen_fd = tlsv2_create_listen_socket(cfg->port);
    if (g_listen_fd < 0) {
        return -1;
    }

    fprintf(stderr, "[tlsv2] Server listening on port %d\n", cfg->port);

    for (;;) {
        fd_set readfds, writefds;
        FD_ZERO(&readfds);
        FD_ZERO(&writefds);

        FD_SET(g_listen_fd, &readfds);
        int maxfd = g_listen_fd;

        for (int i = 0; i < TLSV2_MAX_CLIENTS; i++) {
            tlsv2_client_t *c = &g_clients[i];
            if (c->state == TLSV2_STATE_UNUSED) continue;

            FD_SET(c->fd, &readfds);

            if (c->state == TLSV2_STATE_HANDSHAKE ||
                (c->state == TLSV2_STATE_OPEN && c->out_used > c->out_sent)) {
                FD_SET(c->fd, &writefds);
            }

            if (c->fd > maxfd) maxfd = c->fd;
        }

        int ret = select(maxfd + 1, &readfds, &writefds, NULL, NULL);
        if (ret < 0) {
            if (errno == EINTR) continue;
            perror("select");
            break;
        }

        if (FD_ISSET(g_listen_fd, &readfds)) {
            tlsv2_accept_new_client();
        }

        for (int i = 0; i < TLSV2_MAX_CLIENTS; i++) {
            tlsv2_client_t *c = &g_clients[i];
            if (c->state == TLSV2_STATE_UNUSED) continue;

            if (FD_ISSET(c->fd, &readfds)) {
                tlsv2_handle_client_read(c);
            }

            if (c->state != TLSV2_STATE_UNUSED &&
                FD_ISSET(c->fd, &writefds)) {
                tlsv2_handle_client_write(c);
            }
        }
    }

    close(g_listen_fd);
    g_listen_fd = -1;

    for (int i = 0; i < TLSV2_MAX_CLIENTS; i++) {
        tlsv2_client_close(&g_clients[i]);
    }

    SSL_CTX_free(g_ctx_server);
    g_ctx_server = NULL;

    return 0;
}

// Send a JSON message to a client (identified by its socket fd)
int tlsv2_send_json(int client_id, const char *json, size_t len) {
    if (len > TLSV2_MAX_JSON_SIZE) {
        return -1;
    }

    for (int i = 0; i < TLSV2_MAX_CLIENTS; i++) {
        tlsv2_client_t *c = &g_clients[i];
        if (c->state != TLSV2_STATE_UNUSED && c->fd == client_id) {
            return tlsv2_json_queue_send(c, json, len);
        }
    }
    return -1;
}

// ======================================================
// CLEAN TLS CLIENT API (blocking, PB-friendly)
// ======================================================

typedef struct tlsv2_client_conn_s {
    int   sock;
    SSL  *ssl;
} tlsv2_client_conn_t;

#define TLSV2_MAX_CLIENT_CONNS 64
static tlsv2_client_conn_t *g_client_conns[TLSV2_MAX_CLIENT_CONNS] = {0};
static SSL_CTX *g_client_ctx = NULL;

// ------------------------------------------------------
// Registry helpers
// ------------------------------------------------------
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

// ------------------------------------------------------
// Init
// ------------------------------------------------------
int tlsv2_client_init(void) {
    SSL_library_init();
    SSL_load_error_strings();
    OpenSSL_add_all_algorithms();

    g_client_ctx = SSL_CTX_new(TLS_client_method());
    return g_client_ctx ? 0 : -1;
}

// ------------------------------------------------------
// Connect
// ------------------------------------------------------
int tlsv2_client_connect(const char *host, int port) {
    tlsv2_client_conn_t *c = calloc(1, sizeof(tlsv2_client_conn_t));
    if (!c) return -1;

    c->sock = socket(AF_INET, SOCK_STREAM, 0);
    if (c->sock < 0) { free(c); return -1; }

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port   = htons(port);
    inet_pton(AF_INET, host, &addr.sin_addr);

    if (connect(c->sock, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        close(c->sock);
        free(c);
        return -2;
    }

    c->ssl = SSL_new(g_client_ctx);
    SSL_set_fd(c->ssl, c->sock);

    if (SSL_connect(c->ssl) <= 0) {
        SSL_free(c->ssl);
        close(c->sock);
        free(c);
        return -3;
    }

    tlsv2_register_client_conn(c);
    return c->sock;
}

// ------------------------------------------------------
// Send JSON (length-prefixed)
// ------------------------------------------------------
int tlsv2_client_send_json(int sock, const char *json, size_t len) {
    tlsv2_client_conn_t *c = tlsv2_lookup_client_conn(sock);
    if (!c) return -1;

    if (len > TLSV2_MAX_JSON_SIZE)
        return -2;

    uint32_t nlen = htonl((uint32_t)len);
    if (SSL_write(c->ssl, &nlen, 4) <= 0) return -3;

    size_t total = 0;
    while (total < len) {
        int r = SSL_write(c->ssl, json + total, (int)(len - total));
        if (r <= 0) return -4;
        total += r;
    }

    return 0;
}

// ------------------------------------------------------
// Receive JSON (blocking, PB-friendly)
// ------------------------------------------------------
int tlsv2_client_recv_json(int sock, char *buf, size_t maxlen) {
    tlsv2_client_conn_t *c = tlsv2_lookup_client_conn(sock);
    if (!c) return -1;

    uint32_t nlen;
    int r = SSL_read(c->ssl, &nlen, 4);
    if (r <= 0)
        return -2;

    nlen = ntohl(nlen);

    // Need space for JSON + '\0'
    if (nlen + 1 > maxlen)
        return -3;

    size_t total = 0;
    while (total < nlen) {
        r = SSL_read(c->ssl, buf + total, (int)(nlen - total));
        if (r <= 0)
            return -4;
        total += r;
    }

    buf[nlen] = '\0';   // PB-safe

    return (int)nlen;
}

// ------------------------------------------------------
// Close
// ------------------------------------------------------
void tlsv2_client_close_fd(int sock) {
    tlsv2_client_conn_t *c = tlsv2_lookup_client_conn(sock);
    if (!c) return;

    SSL_shutdown(c->ssl);
    SSL_free(c->ssl);
    close(c->sock);

    tlsv2_unregister_client_conn(sock);
    free(c);
    }
    

// ============================================================================
// CLIENT SIDE (BLOCKING, PB-FRIENDLY)
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

// ---------------------------------------------------------------------------
// Registry helpers
// ---------------------------------------------------------------------------

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
    // Nothing to initialize globally for BearSSL client
    return 0;
}

// ============================================================================
// CLIENT CONNECT (BLOCKING)
// ============================================================================

int tlsv2_client_connect(const char *host, int port) {
    tlsv2_client_conn_t *c = calloc(1, sizeof(tlsv2_client_conn_t));
    if (!c) return -1;

    // Create socket
    c->sock = socket(AF_INET, SOCK_STREAM, 0);
    if (c->sock < 0) {
        free(c);
        return -1;
    }

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port   = htons(port);
    inet_pton(AF_INET, host, &addr.sin_addr);

    if (connect(c->sock, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        close(c->sock);
        free(c);
        return -2;
    }

    // ---------------------------
    // BearSSL client setup
    // ---------------------------

    // Minimal X.509 engine (no certificate validation)
    br_x509_minimal_init(&c->xc, &br_sha256_vtable, NULL, 0);
    br_ssl_client_init_full(&c->sc, &c->xc, NULL, 0);

    // Set I/O buffers
    br_ssl_engine_set_buffers_bidi(
        &c->sc.eng,
        c->iobuf, TLSV2_IOBUF_SIZE,
        c->plainbuf, TLSV2_PLAINTEXT_SIZE
    );

    // Set SNI
    br_ssl_client_reset(&c->sc, host, 0);

    // Bind to socket using br_sslio
    br_sslio_init(&c->ioc,
                  &c->sc.eng,
                  read,  c->sock,
                  write, c->sock);

    // Perform handshake (blocking)
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

    // Send length
    if (br_sslio_write_all(&c->ioc, &nlen, 4) < 0)
        return -3;

    // Send JSON
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

    // Read length
    if (br_sslio_read(&c->ioc, &nlen, 4) != 4)
        return -2;

    nlen = ntohl(nlen);

    if (nlen + 1 > maxlen)
        return -3;

    size_t total = 0;
    while (total < nlen) {
        int r = br_sslio_read(&c->ioc, buf + total, nlen - total);
        if (r <= 0)
            return -4;
        total += r;
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
