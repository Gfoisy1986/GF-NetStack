EnableExplicit

; ---------------------------------------------------------
; 1. PROTOTYPES (toujours en premier)
; ---------------------------------------------------------
PrototypeC tlsv2_on_client_connected(client_id.i)
PrototypeC tlsv2_on_client_disconnected(client_id.i)
PrototypeC tlsv2_on_json_received(client_id.i, *json, len.i)

; ---------------------------------------------------------
; 2. DECLAREC (PureBasic DOIT les voir avant usage)
; ---------------------------------------------------------
DeclareC OnClientConnected(client_id.i)
DeclareC OnClientDisconnected(client_id.i)
DeclareC OnJsonReceived(client_id.i, *json, len.i)

; ---------------------------------------------------------
; 3. IMPORT DLL (après DeclareC)
; ---------------------------------------------------------
CompilerSelect #PB_Compiler_OS

  CompilerCase #PB_OS_Windows
    ImportC "tls_wrapper_v3.dll"
      tlsv2_server_run(*cfg)
      tlsv2_send_json(client_id.i, *json, len.i)
    EndImport

  CompilerCase #PB_OS_Linux
    ImportC "tls_wrapper_v3.so"
      tlsv2_server_run(*cfg)
      tlsv2_send_json(client_id.i, *json, len.i)
    EndImport

  CompilerCase #PB_OS_MacOS
    ImportC "tls_wrapper_v3.dylib"
      tlsv2_server_run(*cfg)
      tlsv2_send_json(client_id.i, *json, len.i)
    EndImport

CompilerEndSelect


; ---------------------------------------------------------
; 4. STRUCTURE (après ImportC)
; ---------------------------------------------------------
Structure tlsv2_server_config_t
  port.i
  cert_file.i
  key_file.i
  on_client_connected.i
  on_client_disconnected.i
  on_json_received.i
EndStructure

; ---------------------------------------------------------
; 5. PROCEDURES (implémentations réelles)
; ---------------------------------------------------------
ProcedureC OnClientConnected(client_id.i)
  Debug "Client connecté: " + Str(client_id)
EndProcedure

ProcedureC OnClientDisconnected(client_id.i)
  Debug "Client déconnecté: " + Str(client_id)
EndProcedure

ProcedureC OnJsonReceived(client_id.i, *json, len.i)
  Protected s.s = PeekS(*json, len, #PB_Ascii)
  Debug "JSON reçu: " + s

  Protected reply.s = ~"{\"status\":\"ok\",\"echo\":\"" + s + "}"
  tlsv2_send_json(client_id, @reply, Len(reply))
EndProcedure

; ---------------------------------------------------------
; 6. MAIN (maintenant PB connaît tout)
; ---------------------------------------------------------
Define cfg.tlsv2_server_config_t
Define cert.s = "server_cert.der"
Define key.s  = "server_key.der"

cfg\port = 4443
cfg\cert_file = @cert
cfg\key_file  = @key
cfg\on_client_connected    = @OnClientConnected()
cfg\on_client_disconnected = @OnClientDisconnected()
cfg\on_json_received       = @OnJsonReceived()

Debug "Démarrage serveur TLS..."
tlsv2_server_run(@cfg)

; IDE Options = PureBasic 6.20 (Windows - x64)
; CursorPosition = 22
; Folding = -
; EnableThread
; EnableXP
; DPIAware
; Executable = Z:\home\gfoisy\server.exe
; Compiler = PureBasic 6.20 (Windows - x64)