#include <stdio.h>
#include <string.h>
#include "tls_wrapper_v3.h"   // ton header si tu en as un, sinon déclare les prototypes

// Prototypes si tu n'as pas de .h

int tlsv2_send_json(int client_id, const char *json, size_t len);

// Callbacks
void on_client_connected(int client_id) {
    printf("[SERVER] Client connected: %d\n", client_id);
}

void on_client_disconnected(int client_id) {
    printf("[SERVER] Client disconnected: %d\n", client_id);
}

void on_json_received(int client_id, const char *json, size_t len) {
    printf("[SERVER] Received from %d: %.*s\n", client_id, (int)len, json);

    // Réponse simple
    const char *pong = "{\"reply\":\"pong\"}";
    tlsv2_send_json(client_id, pong, strlen(pong));
}

int main() {
    tlsv2_server_config_t cfg;

    cfg.port = 8443;
    cfg.cert_file = "cert.der";
    cfg.key_file  = "key.der";

    cfg.on_client_connected    = on_client_connected;
    cfg.on_client_disconnected = on_client_disconnected;
    cfg.on_json_received       = on_json_received;

    printf("[SERVER] Starting TLS server on port 8443...\n");

    tlsv2_server_run(&cfg);

    return 0;
}
