module wss_server_mod
    use ws_clients
    use ws_router
    use websocket
    use select_wrapper
    use websocket_handshake
    use ws_tls_shim
    implicit none

    integer, parameter :: OP_CONTINUATION = 0
    integer, parameter :: OP_BINARY       = 2
    integer, parameter :: OP_PING         = 9
    integer, parameter :: OP_PONG         = 10

contains

    subroutine run_wss_server()
        integer :: listen_sock
        integer :: newsock, cid
        logical :: ready_listen
        logical :: ready_clients(MAX_CLIENTS)
        integer :: i, opcode
        character(len=2048) :: payload
        logical :: running

        ! Création du socket d’écoute (TLS ou non, selon ton wrapper)
        call create_listen_socket(listen_sock)   ! <-- ton wrapper existant

        running = .true.
        do while (running)

            ! NOTE : signature corrigée, conforme à select_wrapper.f90
            call wait_for_activity(listen_sock, ready_listen, ready_clients)

            ! Nouvelle connexion
            if (ready_listen) then
                call accept_client(listen_sock, newsock)  ! <-- ton wrapper existant
                cid = add_client(newsock)
                if (cid < 0) then
                    print *, "Server full, rejecting client"
                    ! call close_socket(newsock)
                else
                    print *, "New client connected, id=", cid, " sock=", newsock
                end if
            end if

            ! Activité des clients existants
            do i = 1, MAX_CLIENTS
                if (.not. clients(i)%active) cycle
                if (.not. ready_clients(i)) cycle

                call ws_read_frame(clients(i)%socket, opcode, payload)

                select case (opcode)
                case (OP_TEXT)
                    call ws_route(trim(payload), i)

                case (OP_CLOSE)
                    print *, "Client", i, "requested close"
                    call remove_client(i)

                case (OP_PING)
                    ! ici tu peux répondre avec un PONG si tu as ws_send_pong()

                case default
                    ! ignorer ou logger
                end select
            end do

        end do

        ! TODO : fermer tous les sockets proprement ici

    end subroutine run_wss_server

end module wss_server_mod
