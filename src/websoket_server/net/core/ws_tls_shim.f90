module ws_tls_shim
    implicit none
contains

    subroutine tls_send_f(sock, msg)
        integer, intent(in)        :: sock
        character(len=*), intent(in) :: msg
        ! TODO: brancher sur ta vraie routine TLS (ex: tls_send)
        print *, "[tls_send_f] stub, sock=", sock, " msg=", trim(msg)
    end subroutine tls_send_f

    subroutine create_listen_socket(sock)
        integer, intent(out) :: sock
        ! TODO: brancher sur ton tcp_listen / tls_listen
        print *, "[create_listen_socket] stub"
        sock = -1
    end subroutine create_listen_socket

    subroutine accept_client(listen_sock, client_sock)
        integer, intent(in)  :: listen_sock
        integer, intent(out) :: client_sock
        ! TODO: brancher sur ton tcp_accept / tls_accept
        print *, "[accept_client] stub, listen_sock=", listen_sock
        client_sock = -1
    end subroutine accept_client

end module ws_tls_shim
