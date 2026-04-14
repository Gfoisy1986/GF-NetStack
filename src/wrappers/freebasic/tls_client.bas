#Include "tls_wrapper_v3.bi"
#inclib "bearssl"

Const MAXBUF = 65536

Dim As Long sock
Dim As String host = "127.0.0.1"
Dim As Long port = 8443

Print "Init TLS client..."
tlsv2_client_init()

Print "Connecting..."
sock = tlsv2_client_connect(StrPtr(host), port)

If sock < 0 Then
    Print "Connection failed: "; sock
    End
End If

Print "Connected! Socket = "; sock

' -------------------------
' SEND JSON
' -------------------------
Dim As String jsonOut = "{""cmd"":""hello"",""msg"":""from FreeBASIC""}"
Dim As Long ret

ret = tlsv2_client_send_json(sock, StrPtr(jsonOut), Len(jsonOut))
If ret <> 0 Then
    Print "Send error: "; ret
    tlsv2_client_close_fd(sock)
    End
End If

Print "JSON sent."

' -------------------------
' RECEIVE JSON
' -------------------------
Dim As ZString * (MAXBUF+1) jsonIn
ret = tlsv2_client_recv_json(sock, @jsonIn, MAXBUF)

If ret < 0 Then
    Print "Receive error: "; ret
Else
    Print "Received JSON ("; ret; " bytes):"
    Print jsonIn
End If

' -------------------------
' CLOSE
' -------------------------
tlsv2_client_close_fd(sock)
Print "Connection closed."
