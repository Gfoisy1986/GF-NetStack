program tls_server
    use iso_c_binding
    use tls_module
    implicit none

    integer(c_int) :: server, client, nbytes
    character(kind=c_char), dimension(4096) :: buffer
    character(len=:), allocatable :: msg, json_reply
    integer :: i

    print *, "Starting TLS JSON server on port 4433..."

    call tls_init_server_f()

    server = tls_listen_f(4433)
    if (server < 0) then
        print *, "ERROR: tls_listen_f failed, code=", server
        stop
    endif

    print *, "Server listening..."

    do
        print *, "Waiting for client..."
        client = tls_accept_f(server)

        if (client < 0) then
            print *, "ERROR: tls_accept_f failed, code=", client
            cycle
        endif

        print *, "Client connected."

        ! ---------------------------
        ! Handle client session
        ! ---------------------------
        do
            nbytes = tls_recv_f(client, buffer, size(buffer))

            if (nbytes <= 0) then
                print *, "Client disconnected."
                exit
            endif

            msg = transfer(buffer(1:nbytes), "")
            print *, "Received JSON:", '"'//trim(msg)//'"'

            ! ---------------------------
            ! Build JSON response
            ! ---------------------------
            json_reply = '{"status":"ok","echo": "'//trim(msg)//'"}'

            call tls_send_f(client, &
                trim(json_reply)//c_null_char, &
                len_trim(json_reply))

            print *, "Sent JSON reply:", '"'//trim(json_reply)//'"'
        end do

        call tls_close_f(client)
    end do

    call tls_close_f(server)
end program tls_server
