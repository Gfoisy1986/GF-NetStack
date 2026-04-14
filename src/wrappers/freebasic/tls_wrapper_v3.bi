Extern "C"

    Declare Sub tlsv2_set_callbacks( _
        ByVal c1 As Any Ptr, _
        ByVal c2 As Any Ptr, _
        ByVal c3 As Any Ptr )

    Declare Function tlsv2_server_run( _
        ByVal cfg As tlsv2_server_config_t Ptr _
    ) As Long

    Declare Function tlsv2_send_json( _
        ByVal client_id As Long, _
        ByVal json As ZString Ptr, _
        ByVal len As Long _
    ) As Long

End Extern

