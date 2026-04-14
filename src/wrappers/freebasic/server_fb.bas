#Inclib "bearssl"
#Include "tls_wrapper_v3.bi"

Sub on_connect Cdecl (ByVal id As Long)
    Print "[SERVER] Client connected: "; id
End Sub

Sub on_disconnect Cdecl (ByVal id As Long)
    Print "[SERVER] Client disconnected: "; id
End Sub

Sub on_json Cdecl (ByVal id As Long, ByVal json As ZString Ptr)
    Dim As String msg = *json
    Print "[SERVER] Received: "; msg

    Dim As String reply = "{""msg"":""hello from server""}"
    tlsv2_send_json(id, StrPtr(reply), Len(reply))
End Sub


Dim cfg As tlsv2_server_config_t

cfg.port = 8443
cfg.cert_file = StrPtr("cert.der")
cfg.key_file  = StrPtr("key.der")

' On enregistre les callbacks FB dans le wrapper C
tlsv2_set_callbacks(@on_connect, @on_disconnect, @on_json)

Print "[SERVER] Running..."
tlsv2_server_run(@cfg)
