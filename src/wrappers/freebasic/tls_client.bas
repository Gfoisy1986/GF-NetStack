#Inclib "bearssl"
#Include "tls_wrapper_v3.bi"

Extern "C"
    Declare Function tlsv2_client_init() As Long
    Declare Function tlsv2_client_connect(ByVal host As ZString Ptr, ByVal port As Long) As Long
    Declare Function tlsv2_client_send_json(ByVal sock As Long, ByVal json As ZString Ptr, ByVal len As Long) As Long
    Declare Function tlsv2_client_recv_json(ByVal sock As Long, ByVal buf As ZString Ptr, ByVal maxlen As Long) As Long
    Declare Sub tlsv2_client_close_fd(ByVal sock As Long)
End Extern

Const MAXBUF = 65536

Dim As String host = "127.0.0.1"
Dim As Long port = 8443
Dim As Long sock, ret

Print "[CLIENT] Init..."
tlsv2_client_init()

Print "[CLIENT] Connecting..."
sock = tlsv2_client_connect(StrPtr(host), port)
If sock < 0 Then
    Print "[CLIENT] Connect failed: "; sock
    End
End If
Print "[CLIENT] Connected, sock = "; sock

Dim As String jsonOut = "{""msg"":""hello from client""}"
ret = tlsv2_client_send_json(sock, StrPtr(jsonOut), Len(jsonOut))
Print "[CLIENT] Send ret = "; ret

Dim As ZString * (MAXBUF+1) jsonIn
ret = tlsv2_client_recv_json(sock, @jsonIn, MAXBUF)
If ret > 0 Then
    Print "[CLIENT] Received ("; ret; "): "; Left(jsonIn, ret)
Else
    Print "[CLIENT] Receive error: "; ret
End If

Print "[CLIENT] Closing..."
tlsv2_client_close_fd(sock)
Print "[CLIENT] Done."
