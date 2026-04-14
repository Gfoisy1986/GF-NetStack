/* gfns_conn.h — unified TCP/TLS abstraction */

#ifndef GFNS_CONN_H
#define GFNS_CONN_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct gfns_conn gfns_conn_t;

/* Create TCP or TLS connections */
gfns_conn_t *gfns_tcp_connect(const char *host, uint16_t port);
gfns_conn_t *gfns_tls_connect(const char *host, uint16_t port);

/* Unified I/O */
int gfns_conn_read (gfns_conn_t *c, void *buf, size_t len);
int gfns_conn_write(gfns_conn_t *c, const void *buf, size_t len);
int gfns_conn_close(gfns_conn_t *c);

/* Optional: expose raw socket if needed */
int gfns_conn_get_fd(gfns_conn_t *c);

#ifdef __cplusplus
}
#endif

#endif
