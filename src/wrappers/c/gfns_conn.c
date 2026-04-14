/* gfns_conn.c — minimal TCP/TLS abstraction */

#include "gfns_conn.h"
#include "tls_wrapper_v3.h"   /* your BearSSL wrapper */
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <unistd.h>           /* or closesocket() on Windows */
#include <sys/socket.h>
#include <netdb.h>

struct gfns_conn {
    int      sock;
    int      is_tls;
    void    *tls_ctx;   /* pointer to your BearSSL client context */
};

/* --------------------------------------------------------- */
/* TCP backend                                               */
/* --------------------------------------------------------- */
static int tcp_connect_raw(const char *host, uint16_t port)
{
    char portstr[16];
    snprintf(portstr, sizeof(portstr), "%u", port);

    struct addrinfo hints, *res = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_family   = AF_UNSPEC;

    if (getaddrinfo(host, portstr, &hints, &res) != 0)
        return -1;

    int s = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (s < 0) {
        freeaddrinfo(res);
        return -1;
    }

    if (connect(s, res->ai_addr, res->ai_addrlen) < 0) {
        close(s);
        freeaddrinfo(res);
        return -1;
    }

    freeaddrinfo(res);
    return s;
}

gfns_conn_t *gfns_tcp_connect(const char *host, uint16_t port)
{
    int s = tcp_connect_raw(host, port);
    if (s < 0)
        return NULL;

    gfns_conn_t *c = calloc(1, sizeof(*c));
    if (!c) {
        close(s);
        return NULL;
    }

    c->sock   = s;
    c->is_tls = 0;
    c->tls_ctx = NULL;

    return c;
}

/* --------------------------------------------------------- */
/* TLS backend (BearSSL wrapper)                             */
/* --------------------------------------------------------- */
gfns_conn_t *gfns_tls_connect(const char *host, uint16_t port)
{
    int s = tcp_connect_raw(host, port);
    if (s < 0)
        return NULL;

    void *ctx = tlsv3_client_connect(s, host);
    if (!ctx) {
        close(s);
        return NULL;
    }

    gfns_conn_t *c = calloc(1, sizeof(*c));
    if (!c) {
        tlsv3_client_free(ctx);
        close(s);
        return NULL;
    }

    c->sock    = s;
    c->is_tls  = 1;
    c->tls_ctx = ctx;

    return c;
}

/* --------------------------------------------------------- */
/* Unified read/write                                        */
/* --------------------------------------------------------- */
int gfns_conn_read(gfns_conn_t *c, void *buf, size_t len)
{
    if (!c)
        return -1;

    if (c->is_tls)
        return tlsv3_client_read(c->tls_ctx, buf, len);

    return recv(c->sock, buf, len, 0);
}

int gfns_conn_write(gfns_conn_t *c, const void *buf, size_t len)
{
    if (!c)
        return -1;

    if (c->is_tls)
        return tlsv3_client_write(c->tls_ctx, buf, len);

    return send(c->sock, buf, len, 0);
}

/* --------------------------------------------------------- */
/* Close connection                                          */
/* --------------------------------------------------------- */
int gfns_conn_close(gfns_conn_t *c)
{
    if (!c)
        return -1;

    if (c->is_tls)
        tlsv3_client_free(c->tls_ctx);

    close(c->sock);
    free(c);
    return 0;
}

/* --------------------------------------------------------- */
/* Optional: raw socket                                      */
/* --------------------------------------------------------- */
int gfns_conn_get_fd(gfns_conn_t *c)
{
    return c ? c->sock : -1;
}
