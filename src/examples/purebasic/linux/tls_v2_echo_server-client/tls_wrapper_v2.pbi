; ============================================================
; tls_v2.pbi - PureBasic FFI wrapper for libtls_v2.so
; ============================================================

EnableExplicit

; ------------------------------------------------------------
; Platform-specific library name
; ------------------------------------------------------------
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  #TLSV2_Lib = "libtls_v2.dll"
CompilerElseIf #PB_Compiler_OS = #PB_OS_Linux
  #TLSV2_Lib = "libtls_v2.so"
CompilerElseIf #PB_Compiler_OS = #PB_OS_MacOS
  #TLSV2_Lib = "libtls_v2.dylib"
CompilerEndIf


; ------------------------------------------------------------
; C struct: tlsv2_server_config_t
; ------------------------------------------------------------
;   int  port;
;   const char *cert_file;
;   const char *key_file;
;   void (*on_client_connected)(int);
;   void (*on_client_disconnected)(int);
;   void (*on_json_received)(int, const char*, size_t);
; ------------------------------------------------------------

Structure tlsv2_server_config_t
  port.i
  cert_file.i
  key_file.i
  on_client_connected.i
  on_client_disconnected.i
  on_json_received.i
EndStructure


; ------------------------------------------------------------
; Import C functions from libtls_v2
; ------------------------------------------------------------
ImportC #TLSV2_Lib

  ; --- Server API ---
  tlsv2_server_run(*cfg.tlsv2_server_config_t)
  tlsv2_send_json(client_id.i, *json, len.i)

  ; --- Client API ---
  tlsv2_client_init()
  tlsv2_client_connect(host.i, port.i)
  tlsv2_client_close_fd(sock.i)
  tlsv2_client_send_json(sock.i, *json, len.i)
  tlsv2_client_recv_json(sock.i, *buf, maxlen.i)

EndImport


; ------------------------------------------------------------
; PureBasic callback handlers (C calling convention)
; ------------------------------------------------------------
ProcedureC on_connect(id.i)
  PrintN("Client connected: " + Str(id))
EndProcedure

ProcedureC on_disconnect(id.i)
  PrintN("Client disconnected: " + Str(id))
EndProcedure



; ------------------------------------------------------------
; Helper: allocate a C-style ASCII string
; ------------------------------------------------------------
Procedure.i MakeCStringAscii(text$)
  Protected *mem, size.i
  size = StringByteLength(text$, #PB_Ascii)
  *mem = AllocateMemory(size + 1)
  If *mem
    PokeS(*mem, text$, -1, #PB_Ascii)
  EndIf
  ProcedureReturn *mem
EndProcedure

ProcedureC on_json(id.i, *json, len.i)
  Protected msg$

  msg$ = PeekS(*json, len, #PB_Ascii)
  PrintN("From client " + Str(id) + ": " + msg$)

  tlsv2_send_json(id, *json, len)
  PrintN("Echoed back to " + Str(id))
EndProcedure
;-------------------------------------------------------
; Main – equivalent to your C main()
;-------------------------------------------------------
Define cfg.tlsv2_server_config_t
Define *cert, *key

*cert = MakeCStringAscii("server.pem")
*key  = MakeCStringAscii("server.key")

cfg\port                  = 8000
cfg\cert_file             = *cert
cfg\key_file              = *key
cfg\on_client_connected   = @on_connect()
cfg\on_client_disconnected= @on_disconnect()
cfg\on_json_received      = @on_json()

; Blocking server loop (like C main)
tlsv2_server_run(@cfg)

; Cleanup (won’t be reached unless server_run returns)
If *cert : FreeMemory(*cert) : EndIf
If *key  : FreeMemory(*key)  : EndIf

; IDE Options = PureBasic 6.30 (Linux - x64)
; ExecutableFormat = Console
; CursorPosition = 102
; FirstLine = 47
; Folding = -
; EnableXP
; DPIAware