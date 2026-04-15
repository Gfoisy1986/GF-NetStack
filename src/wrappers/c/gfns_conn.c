/* gfns_conn.c — minimal TCP/TLS abstraction */

#include "gfns_conn.h"
#include "tls_wrapper_v3.h"   /* your BearSSL wrapper */
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#ifdef _WIN32
    #include <windows.h>
    #include <winsock2.h>
    #include <ws2tcpip.h>
    #pragma comment(lib, "ws2_32.lib")
#else
    #include <unistd.h>
    #include <sys/socket.h>
    #include <arpa/inet.h>
    #include <netdb.h>
    #include <errno.h>
#endif

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

#ifdef _WIN32
    WSADATA wsa;
    WSAStartup(MAKEWORD(2,2), &wsa);
#endif

    if (getaddrinfo(host, portstr, &hints, &res) != 0)
        return -1;

    int s = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    if (s < 0) {
        freeaddrinfo(res);
        return -1;
    }

    if (connect(s, res->ai_addr, (int)res->ai_addrlen) < 0) {
#ifdef _WIN32
        closesocket(s);
#else
        close(s);
#endif
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
#ifdef _WIN32
        closesocket(s);
#else
        close(s);
#endif
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
#ifdef _WIN32
        closesocket(s);
#else
        close(s);
#endif
        return NULL;
    }

    gfns_conn_t *c = calloc(1, sizeof(*c));
    if (!c) {
        tlsv3_client_free(ctx);
#ifdef _WIN32
        closesocket(s);
#else
        close(s);
#endif
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

#ifdef _WIN32
    return recv(c->sock, (char*)buf, (int)len, 0);
#else
    return recv(c->sock, buf, len, 0);
#endif
}

int gfns_conn_write(gfns_conn_t *c, const void *buf, size_t len)
{
    if (!c)
        return -1;

    if (c->is_tls)
        return tlsv3_client_write(c->tls_ctx, buf, len);

#ifdef _WIN32
    return send(c->sock, (const char*)buf, (int)len, 0);
#else
    return send(c->sock, buf, len, 0);
#endif
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

#ifdef _WIN32
    closesocket(c->sock);
    WSACleanup();
#else
    close(c->sock);
#endif

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
