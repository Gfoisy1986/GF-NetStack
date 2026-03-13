module tls_module
    use iso_c_binding
    implicit none

    interface
        subroutine tls_init() bind(C)
        end subroutine

        function tls_connect(host, port) bind(C)
            import :: c_char, c_int
            character(kind=c_char), dimension(*) :: host
            integer(c_int), value :: port
            integer(c_int) :: tls_connect
        end function

        function tls_send(handle, buf, len) bind(C)
            import :: c_int, c_char
            integer(c_int), value :: handle
            character(kind=c_char), dimension(*) :: buf
            integer(c_int), value :: len
            integer(c_int) :: tls_send
        end function

        function tls_recv(handle, buf, maxlen) bind(C)
            import :: c_int, c_char
            integer(c_int), value :: handle
            character(kind=c_char), dimension(*) :: buf
            integer(c_int), value :: maxlen
            integer(c_int) :: tls_recv
        end function

        subroutine tls_close(handle) bind(C)
            import :: c_int
            integer(c_int), value :: handle
        end subroutine
    end interface

end module tls_module
