#ifndef TLS_WRAPPER_V3_H
#define TLS_WRAPPER_V3_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// ---------------------------------------------------------------------------
// EXPORT MACRO (Windows DLL / other platforms)
// ---------------------------------------------------------------------------
#if defined(_WIN32) || defined(_WIN64)
  #ifdef TLSV2_BUILD_DLL
    #define DLL_EXPORT __declspec(dllexport)
  #else
    #define DLL_EXPORT __declspec(dllimport)
  #endif
#else
  #define DLL_EXPORT
#endif

// ---------------------------------------------------------------------------
// SERVER CONFIG STRUCT
// ---------------------------------------------------------------------------

typedef void (*tlsv2_on_client_connected)(int client_id);
typedef void (*tlsv2_on_client_disconnected)(int client_id);
typedef void (*tlsv2_on_json_received)(int client_id, const char *json, size_t len);

typedef struct {
    int port;
    const char *cert_file;   // DER
    const char *key_file;    // DER

    tlsv2_on_client_connected    on_client_connected;
    tlsv2_on_client_disconnected on_client_disconnected;
    tlsv2_on_json_received       on_json_received;

} tlsv2_server_config_t;

// ---------------------------------------------------------------------------
// SERVER API
// ---------------------------------------------------------------------------

DLL_EXPORT void tlsv2_set_callbacks(
    tlsv2_on_client_connected,
    tlsv2_on_client_disconnected,
    tlsv2_on_json_received);

DLL_EXPORT int tlsv2_server_run(const tlsv2_server_config_t *cfg);
DLL_EXPORT int tlsv2_send_json(int client_id, const char *json, size_t len);

// ---------------------------------------------------------------------------
// CLIENT API (blocking, PB/FB friendly)
// ---------------------------------------------------------------------------

DLL_EXPORT int tlsv2_client_init(void);
DLL_EXPORT int tlsv2_client_connect(const char *host, int port);
DLL_EXPORT int tlsv2_client_send_json(int sock, const char *json, size_t len);
DLL_EXPORT int tlsv2_client_recv_json(int sock, char *buf, size_t maxlen);
DLL_EXPORT void tlsv2_client_close_fd(int sock);

#ifdef __cplusplus
}
#endif

#endif // TLS_WRAPPER_V3_H
