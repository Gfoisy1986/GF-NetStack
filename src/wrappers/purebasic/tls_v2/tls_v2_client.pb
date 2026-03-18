;===========================
; client.pb
;===========================

EnableExplicit
IncludeFile "tls_wrapper_v2.pbi"

OpenConsole()

PrintN("TLS Client starting...")

;-------------------------------------------------------
; Init TLS client
;-------------------------------------------------------
If tlsv2_client_init() <> 0
  PrintN("Failed to initialize TLS client.")
  End
EndIf

;-------------------------------------------------------
; Connect to server
;-------------------------------------------------------
Define host$ = "127.0.0.1"
Define *host = MakeCStringAscii(host$)

Define sock.i = tlsv2_client_connect(*host, 8000)

If sock < 0
  PrintN("Connection failed.")
  End
EndIf

PrintN("Connected to TLS server.")

;-------------------------------------------------------
; Send JSON message
;-------------------------------------------------------
Define json$ = "{"+#DQUOTE$+"hello"+#DQUOTE$+":"+ #DQUOTE$+"server"+#DQUOTE$+"}"
Define *json = MakeCStringAscii(json$)

tlsv2_client_send_json(sock, *json, StringByteLength(json$, #PB_Ascii))
PrintN("Sent JSON: " + json$)

;-------------------------------------------------------
; Receive JSON reply
;-------------------------------------------------------
Define *buf = AllocateMemory(65536)
Define n.i = tlsv2_client_recv_json(sock, *buf, 65536)

If n > 0
  Define reply$ = PeekS(*buf, n, #PB_Ascii)
  PrintN("Received reply: " + reply$)
Else
  PrintN("No reply or error.")
EndIf

;-------------------------------------------------------
; Close connection
;-------------------------------------------------------
tlsv2_client_close_fd(sock)
PrintN("Connection closed.")

Input()
; IDE Options = PureBasic 6.30 (Linux - x64)
; CursorPosition = 47
; EnableXP
; DPIAware
; Executable = tls_v2_client.sh