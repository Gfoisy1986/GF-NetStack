program ws_client
    use iso_c_binding
    use tls_module
    implicit none

    integer(c_int) :: sock, n
    integer :: i
    character(len=:), allocatable :: handshake, response
    character(len=4096) :: buf
    character(len=:), allocatable :: msg, reply

    ! Host as C-style char array
    character(kind=c_char), dimension(:), allocatable :: host
    character(len=*), parameter :: host_str = "127.0.0.1"

    print *, "WSS client starting..."

    ! ---------------------------------------------------------
    ! 1. Build C-string host  (i must be declared BEFORE this)
    ! ---------------------------------------------------------
    host = [(host_str(i:i), i=1,len_trim(host_str)), c_null_char]

    ! ---------------------------------------------------------
    ! 2. TLS init + connect
    ! ---------------------------------------------------------
    call tls_init_client()
    sock = tls_connect(host, 4433_c_int)

    if (sock < 0) then
        print *, "ERROR: tls_connect failed"
        stop
    end if

    print *, "Connected to TLS server."

    ! ---------------------------------------------------------
    ! 3. Send WebSocket handshake
    ! ---------------------------------------------------------
    handshake = &
        "GET / HTTP/1.1"//char(13)//char(10)// &
        "Host: 127.0.0.1"//char(13)//char(10)// &
        "Upgrade: websocket"//char(13)//char(10)// &
        "Connection: Upgrade"//char(13)//char(10)// &
        "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ=="//char(13)//char(10)// &
        "Sec-WebSocket-Version: 13"//char(13)//char(10)// &
        char(13)//char(10)

    n = tls_send(sock, handshake, len_trim(handshake))
    print *, "Handshake sent."

    ! Read server handshake reply
    n = tls_recv(sock, buf, len(buf))
    if (n <= 0) then
        print *, "Handshake failed."
        stop
    end if

    response = buf(1:n)
    print *, "Server handshake reply:"
    print *, trim(response)

    ! ---------------------------------------------------------
    ! 4. Send a WebSocket text frame
    ! ---------------------------------------------------------
    msg = "Hello from Fortran WebSocket client!"
    call ws_send_frame(sock, msg)
    print *, "Sent:", trim(msg)

    ! ---------------------------------------------------------
    ! 5. Receive echo from server
    ! ---------------------------------------------------------
    call ws_recv_frame(sock, reply)
    print *, "Received:", trim(reply)

    ! ---------------------------------------------------------
    ! 6. Close TLS
    ! ---------------------------------------------------------
    call tls_close(sock)
    print *, "Connection closed."

contains

    ! ============================================================
    ! Send masked WebSocket text frame (client → server)
    ! ============================================================
    subroutine ws_send_frame(sock, text)
        integer(c_int), intent(in) :: sock
        character(len=*), intent(in) :: text

        integer :: lenp, i, n, hdr_len
        character(len=4096) :: frame
        real :: r(4)
        integer(kind=1), dimension(4) :: mask
        integer(kind=1) :: b

        lenp = len_trim(text)

        ! FIN + text opcode (0x81)
        frame(1:1) = char(129)

        ! Mask bit set (client MUST mask)
        if (lenp <= 125) then
            frame(2:2) = char(128 + lenp)
            hdr_len = 2
        else
            print *, "Payload too large."
            return
        end if

        ! Generate random mask
        call random_number(r)
        do i = 1, 4
            mask(i) = int(r(i) * 255.0, kind=1)
            frame(hdr_len+i:hdr_len+i) = achar(mask(i))
        end do

        ! Masked payload
        do i = 1, lenp
            b = ieor(int(iachar(text(i:i)),kind=1), mask(mod(i-1,4)+1))
            frame(hdr_len+4+i:hdr_len+4+i) = achar(b)
        end do

        n = tls_send(sock, frame, hdr_len+4+lenp)
    end subroutine ws_send_frame

    ! ============================================================
    ! Receive unmasked WebSocket text frame (server → client)
    ! ============================================================
    subroutine ws_recv_frame(sock, text)
        integer(c_int), intent(in) :: sock
        character(len=:), allocatable, intent(out) :: text

        character(len=4096) :: buf
        integer :: n, lenp

        ! Read header
        n = tls_recv(sock, buf, 2)
        if (n /= 2) then
            text = ""
            return
        end if

        lenp = iachar(buf(2:2))   ! server never masks

        ! Read payload
        n = tls_recv(sock, buf, lenp)
        if (n /= lenp) then
            text = ""
            return
        end if

        text = buf(1:lenp)
    end subroutine ws_recv_frame

end program ws_client
