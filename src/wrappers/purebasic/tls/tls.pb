ImportC "libtls.so"
  tls_init_server()
  tls_listen(port.i)
  tls_accept(server.i)
  tls_send(sock.i, *buf, len.i)
  tls_recv(sock.i, *buf, maxlen.i)
  tls_close(sock.i)
EndImport

Define server.i
Define client.i

tls_init_server()

port = 9092
server = tls_listen(port)

If server < 0
  PrintN("Failed to listen on port " + Str(port))
  End
EndIf

PrintN("TLS server listening on port " + Str(port))

client = tls_accept(server)

If client >= 0
  PrintN("Client connected, fd = " + Str(client))

  ; loop pour garder le serveur vivant
  Repeat
    Delay(100)
  ForEver

  tls_close(client) ; unreachable ici mais correct
Else
  PrintN("tls_accept failed: " + Str(client))
EndIf

tls_close(server)
; IDE Options = PureBasic 6.30 (Linux - x64)
; ExecutableFormat = Console
; CursorPosition = 39
; EnableXP
; DPIAware
; Executable = tls_server.sh
; Debugger = Standalone