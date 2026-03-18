; ============================================================
; tls_v2_server.pb – PureBasic TLS JSON Server using libtls_v2
; ============================================================

EnableExplicit
IncludeFile "tls_wrapper_v2.pbi"


OpenConsole()

PrintN("===========================================")
PrintN("   TLSv2 JSON Server (PureBasic Wrapper)   ")
PrintN("===========================================")
PrintN("Listening on port 8000...")
PrintN("Waiting for TLS clients...")
PrintN("")

; ------------------------------------------------------------
; Allocate C‑style strings for certificate + key
; ------------------------------------------------------------
Define *cert = MakeCStringAscii("server.pem")
Define *key  = MakeCStringAscii("server.key")

If *cert = 0 Or *key = 0
  PrintN("ERROR: Failed to allocate certificate/key strings.")
  End
EndIf

; ------------------------------------------------------------
; Prepare server configuration struct
; ------------------------------------------------------------
Define cfg.tlsv2_server_config_t

cfg\port                   = 8000
cfg\cert_file              = *cert
cfg\key_file               = *key
cfg\on_client_connected    = @on_connect()
cfg\on_client_disconnected = @on_disconnect()
cfg\on_json_received       = @on_json()

; ------------------------------------------------------------
; Start the blocking TLS server loop
; ------------------------------------------------------------
PrintN("Starting TLS server...")
PrintN("")

tlsv2_server_run(@cfg)

; ------------------------------------------------------------
; Cleanup (normally never reached)
; ------------------------------------------------------------
If *cert : FreeMemory(*cert) : EndIf
If *key  : FreeMemory(*key)  : EndIf

PrintN("")
PrintN("Server stopped. Press ENTER to exit.")
Input()
; IDE Options = PureBasic 6.30 (Linux - x64)
; CursorPosition = 13
; EnableXP
; DPIAware
; Executable = tls_v2_server.sh