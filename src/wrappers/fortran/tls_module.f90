module tls_module
    use iso_c_binding
    implicit none
    private

    public :: tls_init
    public :: tls_init_client
    public :: tls_init_server
    public :: tls_listen
    public :: tls_accept
    public :: tls_connect
    public :: tls_send
    public :: tls_recv
    public :: tls_close


    interface
        subroutine tls_init() bind(C)
        end subroutine tls_init

        subroutine tls_init_client() bind(C)
        end subroutine tls_init_client

        subroutine tls_init_server() bind(C)
        end subroutine tls_init_server

        function tls_listen(port) bind(C) result(sock)
            import :: c_int
            integer(c_int), value :: port
            integer(c_int) :: sock
        end function tls_listen

        function tls_accept(listen_sock) bind(C) result(sock)
            import :: c_int
            integer(c_int), value :: listen_sock
            integer(c_int) :: sock
        end function tls_accept

        function tls_connect(host, port) bind(C) result(sock)
            import :: c_char, c_int
            character(kind=c_char), dimension(*), intent(in) :: host
            integer(c_int), value :: port
            integer(c_int) :: sock
        end function tls_connect

        function tls_send(sock, buf, nbytes) bind(C) result(sent)
            import :: c_char, c_int
            integer(c_int), value :: sock
            character(kind=c_char), dimension(*), intent(in) :: buf
            integer(c_int), value :: nbytes
            integer(c_int) :: sent
        end function tls_send

        function tls_recv(sock, buf, nbytes) bind(C) result(recvd)
            import :: c_char, c_int
            integer(c_int), value :: sock
            character(kind=c_char), dimension(*), intent(out) :: buf
            integer(c_int), value :: nbytes
            integer(c_int) :: recvd
        end function tls_recv



        subroutine tls_close(sock) bind(C)
            import :: c_int
            integer(c_int), value :: sock
        end subroutine tls_close
    end interface

end module tls_module
