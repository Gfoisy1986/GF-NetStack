module tls_module
    use iso_c_binding
    implicit none

    private
    public :: tls_init_server_f, tls_init_client_f
    public :: tls_listen_f, tls_accept_f, tls_connect_f
    public :: tls_send_f, tls_recv_f, tls_close_f

    interface
        subroutine tls_init_server() bind(C, name="tls_init_server")
        end subroutine tls_init_server

        subroutine tls_init_client() bind(C, name="tls_init_client")
        end subroutine tls_init_client

        function tls_listen(port) bind(C, name="tls_listen") result(sock)
            import :: c_int
            integer(c_int), value :: port
            integer(c_int) :: sock
        end function tls_listen

        function tls_accept(server) bind(C, name="tls_accept") result(client)
            import :: c_int
            integer(c_int), value :: server
            integer(c_int) :: client
        end function tls_accept

        function tls_connect(host, port) bind(C, name="tls_connect") result(sock)
            import :: c_int, c_char
            character(kind=c_char), dimension(*) :: host
            integer(c_int), value :: port
            integer(c_int) :: sock
        end function tls_connect

        function tls_send(sock, buf, len) bind(C, name="tls_send") result(nsent)
            import :: c_int, c_char
            integer(c_int), value :: sock
            character(kind=c_char), dimension(*) :: buf
            integer(c_int), value :: len
            integer(c_int) :: nsent
        end function tls_send

        function tls_recv(sock, buf, maxlen) bind(C, name="tls_recv") result(nread)
            import :: c_int, c_char
            integer(c_int), value :: sock
            character(kind=c_char), dimension(*) :: buf
            integer(c_int), value :: maxlen
            integer(c_int) :: nread
        end function tls_recv

        subroutine tls_close(sock) bind(C, name="tls_close")
            import :: c_int
            integer(c_int), value :: sock
        end subroutine tls_close
    end interface

contains

    subroutine tls_init_server_f()
        call tls_init_server()
    end subroutine tls_init_server_f

    subroutine tls_init_client_f()
        call tls_init_client()
    end subroutine tls_init_client_f

    function tls_listen_f(port) result(sock)
        integer(c_int), value :: port
        integer(c_int) :: sock
        sock = tls_listen(port)
    end function tls_listen_f

    function tls_accept_f(server) result(client)
        integer(c_int), value :: server
        integer(c_int) :: client
        client = tls_accept(server)
    end function tls_accept_f

    function tls_connect_f(host, port) result(sock)
        character(kind=c_char), dimension(*) :: host
        integer(c_int), value :: port
        integer(c_int) :: sock
        sock = tls_connect(host, port)
    end function tls_connect_f

    subroutine tls_send_f(sock, buf, len)
        integer(c_int), value :: sock
        character(kind=c_char), dimension(*) :: buf
        integer(c_int), value :: len
        integer(c_int) :: nsent
        nsent = tls_send(sock, buf, len)
    end subroutine tls_send_f

    function tls_recv_f(sock, buf, maxlen) result(nread)
        integer(c_int), value :: sock
        character(kind=c_char), dimension(*) :: buf
        integer(c_int), value :: maxlen
        integer(c_int) :: nread
        nread = tls_recv(sock, buf, maxlen)
    end function tls_recv_f

    subroutine tls_close_f(sock)
        integer(c_int), value :: sock
        call tls_close(sock)
    end subroutine tls_close_f

end module tls_module
