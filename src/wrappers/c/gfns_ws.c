/* gfns_ws.c */

#include "gfns_ws.h"
#include "gfns_conn.h"   /* your TCP/TLS abstraction */
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

struct gfns_ws {
    gfns_conn_t *conn;
    int          is_client;
    int          closed;
};

static int ws_send_handshake(gfns_ws_t *ws,
                             const char *host,
                             const char *path,
                             const char *subprotocol)
{
    /* TODO: generate real Sec-WebSocket-Key and validate Accept */
    char req[512];

    snprintf(req, sizeof(req),
             "GET %s HTTP/1.1\r\n"
             "Host: %s\r\n"
             "Upgrade: websocket\r\n"
             "Connection: Upgrade\r\n"
             "Sec-WebSocket-Version: 13\r\n"
             "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"
             "%s"
             "\r\n",
             path,
             host,
             subprotocol ? "Sec-WebSocket-Protocol: %s\r\n" : "");


    if (gfns_conn_write(ws->conn, req, strlen(req)) < 0)
        return -1;

    /* TODO: read and validate HTTP/1.1 101 response */
    /* For now, just read some bytes and ignore */
    char buf[512];
    int  n = gfns_conn_read(ws->conn, buf, sizeof(buf));
    if (n <= 0)
        return -1;

    return 0;
}

gfns_ws_t *gfns_ws_connect(
    gfns_conn_t *conn,
    const char  *host,
    const char  *path,
    const char  *subprotocol)
{
    if (!conn || !host || !path)
        return NULL;

    gfns_ws_t *ws = (gfns_ws_t *)calloc(1, sizeof(*ws));
    if (!ws)
        return NULL;

    ws->conn      = conn;
    ws->is_client = 1;
    ws->closed    = 0;

    if (ws_send_handshake(ws, host, path, subprotocol) < 0) {
        free(ws);
        return NULL;
    }

    return ws;
}

/* Minimal frame sender: no fragmentation, always FIN=1, client masking */
static int ws_send_frame(
    gfns_ws_t        *ws,
    gfns_ws_opcode_t  opcode,
    const void       *data,
    size_t            len)
{
    if (!ws || ws->closed)
        return -1;

    uint8_t header[14];
    size_t  hlen = 0;

    uint8_t fin_opcode = 0x80 | (opcode & 0x0F); /* FIN=1 */
    header[hlen++] = fin_opcode;

    uint8_t mask_bit = 0x80; /* client → server must mask */
    if (len <= 125) {
        header[hlen++] = mask_bit | (uint8_t)len;
    } else if (len <= 0xFFFF) {
        header[hlen++] = mask_bit | 126;
        header[hlen++] = (uint8_t)((len >> 8) & 0xFF);
        header[hlen++] = (uint8_t)(len & 0xFF);
    } else {
        header[hlen++] = mask_bit | 127;
        for (int i = 7; i >= 0; --i)
            header[hlen++] = (uint8_t)((len >> (8 * i)) & 0xFF);
    }

    /* Simple pseudo-random mask (replace with better RNG later) */
    uint8_t mask[4] = { 0x12, 0x34, 0x56, 0x78 };
    memcpy(&header[hlen], mask, 4);
    hlen += 4;

    if (gfns_conn_write(ws->conn, header, hlen) < 0)
        return -1;

    /* Mask payload */
    const uint8_t *src = (const uint8_t *)data;
    uint8_t       *tmp = NULL;

    if (len > 0) {
        tmp = (uint8_t *)malloc(len);
        if (!tmp)
            return -1;

        for (size_t i = 0; i < len; ++i)
            tmp[i] = src[i] ^ mask[i & 3];

        if (gfns_conn_write(ws->conn, tmp, len) < 0) {
            free(tmp);
            return -1;
        }
        free(tmp);
    }

    return 0;
}

int gfns_ws_send(
    gfns_ws_t        *ws,
    gfns_ws_opcode_t  opcode,
    const void       *data,
    size_t            len)
{
    return ws_send_frame(ws, opcode, data, len);
}

/* Minimal recv: assumes server frames are unmasked, no fragmentation */
int gfns_ws_recv(
    gfns_ws_t        *ws,
    gfns_ws_opcode_t *opcode_out,
    void             *buf,
    size_t            buf_size,
    size_t           *len_out)
{
    if (!ws || ws->closed || !opcode_out || !buf || !len_out)
        return -1;

    uint8_t h2[2];
    if (gfns_conn_read(ws->conn, h2, 2) != 2)
        return -1;

    uint8_t fin    = (h2[0] & 0x80) != 0;
    uint8_t opcode = (h2[0] & 0x0F);
    uint8_t mask   = (h2[1] & 0x80) != 0;
    uint64_t len   = (h2[1] & 0x7F);

    if (!fin) {
        /* TODO: handle fragmentation later */
    }

    if (len == 126) {
        uint8_t ext[2];
        if (gfns_conn_read(ws->conn, ext, 2) != 2)
            return -1;
        len = ((uint16_t)ext[0] << 8) | ext[1];
    } else if (len == 127) {
        uint8_t ext[8];
        if (gfns_conn_read(ws->conn, ext, 8) != 8)
            return -1;
        len = 0;
        for (int i = 0; i < 8; ++i)
            len = (len << 8) | ext[i];
    }

    uint8_t mask_key[4];
    if (mask) {
        /* Server should not mask; read and ignore or treat as error */
        if (gfns_conn_read(ws->conn, mask_key, 4) != 4)
            return -1;
    }

    if (len > buf_size)
        return -1;

    if (gfns_conn_read(ws->conn, buf, (size_t)len) != (int)len)
        return -1;

    *opcode_out = (gfns_ws_opcode_t)opcode;
    *len_out    = (size_t)len;

    return 0;
}

int gfns_ws_close(gfns_ws_t *ws, uint16_t code, const char *reason)
{
    (void)code;
    (void)reason;

    if (!ws || ws->closed)
        return -1;

    ws_send_frame(ws, GFNS_WS_OP_CLOSE, NULL, 0);
    ws->closed = 1;
    return 0;
}

void gfns_ws_free(gfns_ws_t *ws)
{
    if (!ws)
        return;
    /* transport (gfns_conn_t) is owned by caller */
    free(ws);
}

/* Very simple URL parser: wss://host/path or ws://host/path */
extern gfns_conn_t *gfns_tcp_connect(const char *host, uint16_t port);
extern gfns_conn_t *gfns_tls_connect(const char *host, uint16_t port);

static int parse_url(const char *url,
                     int        *is_secure,
                     char       *host,
                     size_t      host_sz,
                     char       *path,
                     size_t      path_sz)
{
    const char *p = NULL;

    if (!strncmp(url, "wss://", 6)) {
        *is_secure = 1;
        p = url + 6;
    } else if (!strncmp(url, "ws://", 5)) {
        *is_secure = 0;
        p = url + 5;
    } else {
        return -1;
    }

    const char *slash = strchr(p, '/');
    if (!slash)
        return -1;

    size_t hlen = (size_t)(slash - p);
    if (hlen >= host_sz)
        return -1;

    memcpy(host, p, hlen);
    host[hlen] = '\0';

    strncpy(path, slash, path_sz - 1);
    path[path_sz - 1] = '\0';

    return 0;
}

gfns_ws_t *gfns_ws_open_url(const char *url)
{
    int   is_secure = 0;
    char  host[256];
    char  path[256];

    if (parse_url(url, &is_secure, host, sizeof(host), path, sizeof(path)) < 0)
        return NULL;

    gfns_conn_t *conn = NULL;
    if (is_secure)
        conn = gfns_tls_connect(host, 443);
    else
        conn = gfns_tcp_connect(host, 80);

    if (!conn)
        return NULL;

    gfns_ws_t *ws = gfns_ws_connect(conn, host, path, NULL);
    if (!ws) {
        /* caller should close conn if needed */
        return NULL;
    }

    return ws;
}
