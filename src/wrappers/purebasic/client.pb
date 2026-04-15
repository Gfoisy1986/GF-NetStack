; --- TLS Client Test (PureBasic) ---

EnableExplicit

ImportC "tls_wrapper_v3.dll"
  tlsv2_client_init()
  tlsv2_client_connect(*host, port.l)
  tlsv2_client_send_json(sock.l, *json, len.i)
  tlsv2_client_recv_json(sock.l, *buf, maxlen.i)
  tlsv2_client_close_fd(sock.l)
EndImport

Define host.s = "127.0.0.1"
Define port.l = 4443
Define sock.l
Define json.s
Define buf.s
Define res.i

If tlsv2_client_init() <> 0
  Debug "tlsv2_client_init() a échoué."
  End
EndIf

sock = tlsv2_client_connect(@host, port)
If sock < 0
  Debug "tlsv2_client_connect() a échoué."
  End
EndIf

Debug "Connecté au serveur TLS."

json = "{""msg"":""hello from PureBasic client"",""value"":42}"
res = tlsv2_client_send_json(sock, @json, Len(json))
If res <> 0
  Debug "tlsv2_client_send_json() a échoué: " + Str(res)
  tlsv2_client_close_fd(sock)
  End
EndIf

Debug "JSON envoyé, attente de réponse..."

buf = Space(65536)
res = tlsv2_client_recv_json(sock, @buf, Len(buf))
If res > 0
  Debug "Réponse (" + Str(res) + " octets): " + Left(buf, res)
Else
  Debug "tlsv2_client_recv_json() a échoué: " + Str(res)
EndIf

tlsv2_client_close_fd(sock)
Debug "Connexion fermée."
End

; IDE Options = PureBasic 6.20 (Windows - x64)
; ExecutableFormat = Console
; CursorPosition = 53
; EnableThread
; EnableXP
; DPIAware
; Compiler = PureBasic 6.20 (Windows - x64)