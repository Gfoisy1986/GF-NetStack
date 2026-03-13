module tcp
    use iso_c_binding
    implicit none

    interface
        function tcp_listen(port) bind(C)
            import :: c_int
            integer(c_int), value :: port
            integer(c_int) :: tcp_listen
        end function

        function tcp_accept(sock) bind(C)
            import :: c_int
            integer(c_int), value :: sock
            integer(c_int) :: tcp_accept
        end function
    end interface

end module tcp
