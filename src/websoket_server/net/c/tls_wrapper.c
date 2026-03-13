#include <arpa/inet.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include <openssl/ssl.h>
#include <openssl/err.h>

#define MAX_SSL_CONNECTIONS 128

typedef struct {
    int  fd;
    SSL *ssl;
} ssl_entry;

static SSL_CTX   *ctx_server = NULL;
static SSL_CTX   *ctx_client = NULL;
static ssl_entry  ssl_table[MAX_SSL_CONNECTIONS];

/* ---------------------------------------------------------
   Internal helpers
   --------------------------------------------------------- */

static void ssl_table_init(void) {
    int i;
    for (i = 0; i < MAX_SSL_CONNECTIONS; i++) {
        ssl_table[i].fd  = -1;
        ssl_table[i].ssl = NULL;
    }
}

static int ssl_table_add(int fd, SSL *ssl) {
    int i;
    for (i = 0; i < MAX_SSL_CONNECTIONS; i++) {
        if (ssl_table[i].fd < 0) {
            ssl_table[i].fd  = fd;
            ssl_table[i].ssl = ssl;
            return 0;
        }
    }
    return -1; /* table full */
}

static SSL *ssl_table_get(int fd) {
    int i;
    for (i = 0; i < MAX_SSL_CONNECTIONS; i++) {
        if (ssl_table[i].fd == fd) {
            return ssl_table[i].ssl;
        }
    }
    return NULL;
}

static void ssl_table_remove(int fd) {
    int i;
    for (i = 0; i < MAX_SSL_CONNECTIONS; i++) {
        if (ssl_table[i].fd == fd) {
            ssl_table[i].fd  = -1;
            ssl_table[i].ssl = NULL;
            return;
        }
    }
}

/* ---------------------------------------------------------
   Server-side TLS init (loads cert + key)
   --------------------------------------------------------- */
void tls_init_server(void) {
    SSL_library_init();
    SSL_load_error_strings();
    OpenSSL_add_all_algorithms();

    ssl_table_init();

    ctx_server = SSL_CTX_new(TLS_server_method());
    if (!ctx_server) {
        ERR_print_errors_fp(stderr);
        return;
    }

    if (SSL_CTX_use_certificate_file(ctx_server, "server.pem", SSL_FILETYPE_PEM) <= 0) {
        ERR_print_errors_fp(stderr);
        return;
    }

    if (SSL_CTX_use_PrivateKey_file(ctx_server, "server.key", SSL_FILETYPE_PEM) <= 0) {
        ERR_print_errors_fp(stderr);
        return;
    }

    if (!SSL_CTX_check_private_key(ctx_server)) {
        fprintf(stderr, "Server private key does not match certificate\n");
        return;
    }
}

/* ---------------------------------------------------------
   Client-side TLS init (no cert for now)
   --------------------------------------------------------- */
void tls_init_client(void) {
    SSL_library_init();
    SSL_load_error_strings();
    OpenSSL_add_all_algorithms();

    ssl_table_init();

    ctx_client = SSL_CTX_new(TLS_client_method());
    if (!ctx_client) {
        ERR_print_errors_fp(stderr);
        return;
    }

    /* No verification for now; can be tightened later */
    SSL_CTX_set_verify(ctx_client, SSL_VERIFY_NONE, NULL);
}

/* ---------------------------------------------------------
   Create TCP listening socket
   --------------------------------------------------------- */
int tls_listen(int port) {
    int sock;
    struct sockaddr_in addr;

    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) return -1;

    memset(&addr, 0, sizeof(addr));
    addr.sin_family      = AF_INET;
    addr.sin_port        = htons(port);
    addr.sin_addr.s_addr = INADDR_ANY;

    if (bind(sock, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        close(sock);
        return -2;
    }

    if (listen(sock, 5) < 0) {
        close(sock);
        return -3;
    }

    return sock;
}

/* ---------------------------------------------------------
   Accept TCP client and perform TLS handshake (server)
   --------------------------------------------------------- */
int tls_accept(int server) {
    int client_fd;
    SSL *ssl;

    client_fd = accept(server, NULL, NULL);
    if (client_fd < 0) return -1;

    if (!ctx_server) {
        fprintf(stderr, "tls_accept: ctx_server is NULL\n");
        close(client_fd);
        return -2;
    }

    ssl = SSL_new(ctx_server);
    if (!ssl) {
        ERR_print_errors_fp(stderr);
        close(client_fd);
        return -3;
    }

    SSL_set_fd(ssl, client_fd);

    if (SSL_accept(ssl) <= 0) {
        ERR_print_errors_fp(stderr);
        SSL_free(ssl);
        close(client_fd);
        return -4;
    }

    if (ssl_table_add(client_fd, ssl) != 0) {
        fprintf(stderr, "tls_accept: SSL table full\n");
        SSL_shutdown(ssl);
        SSL_free(ssl);
        close(client_fd);
        return -5;
    }

    return client_fd;
}

/* ---------------------------------------------------------
   Connect to remote server and perform TLS handshake (client)
   --------------------------------------------------------- */
int tls_connect(const char *host, int port) {
    int sock;
    struct sockaddr_in addr;
    SSL *ssl;

    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) return -1;

    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port   = htons(port);

    if (inet_pton(AF_INET, host, &addr.sin_addr) <= 0) {
        close(sock);
        return -2;
    }

    if (connect(sock, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        close(sock);
        return -3;
    }

    if (!ctx_client) {
        fprintf(stderr, "tls_connect: ctx_client is NULL\n");
        close(sock);
        return -4;
    }

    ssl = SSL_new(ctx_client);
    if (!ssl) {
        ERR_print_errors_fp(stderr);
        close(sock);
        return -5;
    }

    SSL_set_fd(ssl, sock);

    if (SSL_connect(ssl) <= 0) {
        ERR_print_errors_fp(stderr);
        SSL_free(ssl);
        close(sock);
        return -6;
    }

    if (ssl_table_add(sock, ssl) != 0) {
        fprintf(stderr, "tls_connect: SSL table full\n");
        SSL_shutdown(ssl);
        SSL_free(ssl);
        close(sock);
        return -7;
    }

    return sock;
}

/* ---------------------------------------------------------
   Send data over TLS (server or client)
   --------------------------------------------------------- */
int tls_send(int sock, const char *buf, int len) {
    SSL *ssl = ssl_table_get(sock);
    if (ssl) {
        int ret = SSL_write(ssl, buf, len);
        return ret;
    }
    /* Fallback (should not normally happen) */
    return send(sock, buf, len, 0);
}

/* ---------------------------------------------------------
   Receive data over TLS (server or client)
   --------------------------------------------------------- */
int tls_recv(int sock, char *buf, int maxlen) {
    SSL *ssl = ssl_table_get(sock);
    if (ssl) {
        int ret = SSL_read(ssl, buf, maxlen);
        return ret;
    }
    /* Fallback */
    return recv(sock, buf, maxlen, 0);
}

/* ---------------------------------------------------------
   Close TLS + socket
   --------------------------------------------------------- */
void tls_close(int sock) {
    SSL *ssl = ssl_table_get(sock);
    if (ssl) {
        SSL_shutdown(ssl);
        SSL_free(ssl);
        ssl_table_remove(sock);
    }
    close(sock);
}
