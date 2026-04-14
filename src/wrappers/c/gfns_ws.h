/* gfns_ws.h */

#ifndef GFNS_WS_H
#define GFNS_WS_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct gfns_conn gfns_conn_t;   /* from your TLS/TCP layer */
typedef struct gfns_ws   gfns_ws_t;

typedef enum {
    GFNS_WS_OP_CONT   = 0x0,
    GFNS_WS_OP_TEXT   = 0x1,
    GFNS_WS_OP_BINARY = 0x2,
    GFNS_WS_OP_CLOSE  = 0x8,
    GFNS_WS_OP_PING   = 0x9,
    GFNS_WS_OP_PONG   = 0xA
} gfns_ws_opcode_t;

gfns_ws_t *gfns_ws_connect(
    gfns_conn_t *conn,
    const char  *host,
    const char  *path,
    const char  *subprotocol /* NULL if none */
);

int gfns_ws_send(
    gfns_ws_t        *ws,
    gfns_ws_opcode_t  opcode,
    const void       *data,
    size_t            len
);

int gfns_ws_recv(
    gfns_ws_t        *ws,
    gfns_ws_opcode_t *opcode_out,
    void             *buf,
    size_t            buf_size,
    size_t           *len_out
);

int  gfns_ws_close(gfns_ws_t *ws, uint16_t code, const char *reason);
void gfns_ws_free(gfns_ws_t *ws);

/* High-level helper for PureBasic: ws:// or wss:// URL */
gfns_ws_t *gfns_ws_open_url(const char *url);   /* returns NULL on error */

#ifdef __cplusplus
}
#endif

#endif

