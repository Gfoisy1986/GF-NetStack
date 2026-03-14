! wrappers/fortran/ws_compat.f90
subroutine ws_send(sock, msg)
    use websocket
    implicit none
    integer, intent(in) :: sock
    character(len=*), intent(in) :: msg

    call ws_send_text(sock, msg)
end subroutine ws_send
