program ws_serveur
    use iso_c_binding
    use tls_module
    use websocket


    integer(c_int) :: listen_sock, client_sock
    logical :: ok
    character(len=:), allocatable :: payload

    print *, "Starting WSS server..."

    ! Global TLS init
    call tls_init_server()


    ! Create TLS listening socket on port 4433
    listen_sock = tls_listen(4433_c_int)
    if (listen_sock < 0_c_int) then
        print *, "ERROR: tls_listen failed, code=", listen_sock
        stop
    end if

    print *, "WSS server listening on port 4433"

    do
        ! Accept a TLS client
        client_sock = tls_accept(listen_sock)
        if (client_sock < 0_c_int) then
            print *, "ERROR: tls_accept failed, code=", client_sock
            cycle
        end if

        print *, "Client connected."

        ! WebSocket handshake
        ok = ws_accept_handshake(client_sock)
        if (.not. ok) then
            print *, "Handshake failed."
            call tls_close(client_sock)
            cycle
        end if

        print *, "Handshake OK — WebSocket session started."

        ! Message loop
        do
            ok = ws_recv_text(client_sock, payload)
            if (.not. ok) then
                print *, "Client disconnected or error."
                exit
            end if

            print *, "TEXT:", trim(payload)

            call ws_route(trim(payload))

            call ws_send_text(client_sock, "echo: "//trim(payload))
        end do

        call tls_close(client_sock)
        print *, "Client disconnected."
    end do

contains

    logical function ws_accept_handshake(sock) result(ok)
        integer(c_int), intent(in) :: sock
        character(len=4096) :: req
        integer(c_int) :: n

        ok = .false.

        n = tls_recv(sock, req, len(req))
        if (n <= 0_c_int) return

        ok = ws_handle_upgrade(sock, req(1:n))
    end function ws_accept_handshake

    subroutine ws_route(msg)
        character(len=*), intent(in) :: msg
        print *, "Routing:", trim(msg)
    end subroutine ws_route

end program ws_serveur
