Extern "C"

    Declare Function tlsv2_client_init() As Long

    Declare Function tlsv2_client_connect( _
        ByVal host As ZString Ptr, _
        ByVal port As Long _
    ) As Long

    Declare Function tlsv2_client_send_json( _
        ByVal sock As Long, _
        ByVal json As ZString Ptr, _
        ByVal len As Long _
    ) As Long

    Declare Function tlsv2_client_recv_json( _
        ByVal sock As Long, _
        ByVal buf As ZString Ptr, _
        ByVal maxlen As Long _
    ) As Long

    Declare Sub tlsv2_client_close_fd( _
        ByVal sock As Long _
    )

End Extern
