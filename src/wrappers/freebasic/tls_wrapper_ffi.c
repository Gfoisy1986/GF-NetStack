#include "tls_wrapper_v3.h"

// Pointeurs de callbacks fournis par FreeBASIC
static tlsv2_on_client_connected    fb_on_connect = NULL;
static tlsv2_on_client_disconnected fb_on_disconnect = NULL;
static tlsv2_on_json_received       fb_on_json = NULL;

extern void _tls_on_connect(int id);
extern void _tls_on_disconnect(int id);
extern void _tls_on_json(int id, const char *json, size_t len);

int tlsv2_server_run_simple(int port,
                            const char *cert_file,
                            const char *key_file)
{
    tlsv2_server_config_t cfg;

    cfg.port = port;
    cfg.cert_file = cert_file;
    cfg.key_file  = key_file;

    cfg.on_client_connected    = _tls_on_connect;
    cfg.on_client_disconnected = _tls_on_disconnect;
    cfg.on_json_received       = _tls_on_json;

    return tlsv2_server_run(&cfg);
}

void tlsv2_set_callbacks(
    tlsv2_on_client_connected c1,
    tlsv2_on_client_disconnected c2,
    tlsv2_on_json_received c3)
{
    fb_on_connect = c1;
    fb_on_disconnect = c2;
    fb_on_json = c3;
}

// Wrappers appelés par le serveur TLS
void _tls_on_connect(int id) {
    if (fb_on_connect) fb_on_connect(id);
}

void _tls_on_disconnect(int id) {
    if (fb_on_disconnect) fb_on_disconnect(id);
}

void _tls_on_json(int id, const char *json, size_t len) {
    static char buffer[65536];

    if (len > 65535) len = 65535;
    memcpy(buffer, json, len);
    buffer[len] = 0;

    if (fb_on_json) fb_on_json(id, buffer);
}
