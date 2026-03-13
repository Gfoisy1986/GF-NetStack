module websocket_handshake
    use iso_c_binding
    use crypto_wrapper
    use ws_tls_shim
    implicit none
contains

    function compute_accept_key(key) result(out)
        character(len=*), intent(in) :: key
        character(len=:), allocatable :: out
        character(len=*), parameter :: guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
        character(len=:), allocatable :: sha1bin, b64

        sha1bin = sha1_hash_f(key // guid)
        b64     = base64_encode_f(sha1bin)


        out = b64
    end function compute_accept_key


    subroutine websocket_send_handshake(client, key)
        integer, intent(in) :: client
        character(len=*), intent(in) :: key
        character(len=:), allocatable :: accept, response

        accept = compute_accept_key(trim(key))

        response = &
          "HTTP/1.1 101 Switching Protocols" // char(13)//char(10) // &
          "Upgrade: websocket" // char(13)//char(10) // &
          "Connection: Upgrade" // char(13)//char(10) // &
          "Sec-WebSocket-Accept: " // trim(accept) // char(13)//char(10)//char(13)//char(10)

        call tls_send_f(client, response)
    end subroutine websocket_send_handshake

end module websocket_handshake
