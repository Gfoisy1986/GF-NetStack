ImportC "libtls.so"
  tls_init_client()
  tls_connect(host.i, port.i)
  tls_send(sock.i, *buf, len.i)
  tls_recv(sock.i, *buf, maxlen.i)
  tls_close(sock.i)
EndImport

Define client.i
Define *host

tls_init_client()

host$ = "127.0.0.1"
*host = Ascii(host$)

client = tls_connect(*host, 9092)

If client >= 0
  PrintN("Connected to TLS server, fd = " + Str(client))

  ; garde le programme vivant
  Repeat
    Delay(100)
  ForEver

  tls_close(client) ; (inatteignable ici, mais correct)
Else
  PrintN("Failed to connect, code = " + Str(client))
  ; surtout PAS tls_close(client) ici
EndIf
; IDE Options = PureBasic 6.30 (Linux - x64)
; ExecutableFormat = Console
; CursorPosition = 30
; EnableXP
; DPIAware
; Executable = tls_client.sh