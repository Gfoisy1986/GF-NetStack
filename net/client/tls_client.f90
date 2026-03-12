program tls_client
    use iso_c_binding
    use tls_module
    implicit none

    integer(c_int) :: sock, nbytes
    integer :: i
    integer :: j
    character(kind=c_char), dimension(:), allocatable :: host, request
    character(kind=c_char), dimension(4096) :: buffer
    character(len=:), allocatable :: json_msg, reply

    character(len=*), parameter :: host_str = "127.0.0.1"

    host = [(host_str(i:i), i=1,len_trim(host_str)), c_null_char]

    print *, "TLS JSON client starting..."

    call tls_init_client_f()

    sock = tls_connect_f(host, 4433)
    if (sock < 0) then
        print *, "ERROR: tls_connect_f failed, code=", sock
        stop
    endif

    print *, "Connected to TLS server."

    ! ---------------------------
    ! Send multiple JSON messages
    ! ---------------------------
    do i = 1, 3
        json_msg = '{"cmd":"ping","seq":'//trim(adjustl(itoa(i)))//'}'

        request = [(json_msg(j:j), j=1,len_trim(json_msg)), c_null_char]

        call tls_send_f(sock, request, len_trim(json_msg))
        print *, "Sent JSON:", '"'//trim(json_msg)//'"'

        nbytes = tls_recv_f(sock, buffer, size(buffer))

        if (nbytes > 0) then
            reply = transfer(buffer(1:nbytes), "")
            print *, "Received JSON:", '"'//trim(reply)//'"'
        else
            print *, "Server closed connection."
            exit
        endif
    end do

    call tls_close_f(sock)
    print *, "TLS connection closed."

contains

    function itoa(i) result(str)
        integer, intent(in) :: i
        character(len=12) :: str
        write(str,'(I0)') i
    end function itoa

end program tls_client
