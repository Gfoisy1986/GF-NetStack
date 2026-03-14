module websocket
    use iso_c_binding
    use tls_module
    use crypto_wrapper
    implicit none
    private

    integer, parameter :: BUF_LEN = 8192

    public :: ws_handle_upgrade
    public :: ws_recv_text
    public :: ws_send_text

contains

    !------------------------------------------------------------
    ! sha1_base64
    !   - Pure Fortran helper using crypto_wrapper
    !   - key: plain text key
    !   - accept_key: base64(SHA1(key))
    !------------------------------------------------------------
    subroutine sha1_base64(key, accept_key)
        character(len=*), intent(in)  :: key
        character(len=*), intent(out) :: accept_key

        character(len=20) :: digest
        character(len=:), allocatable :: b64
        integer :: n

        digest = sha1_hash_f(trim(key))
        b64    = base64_encode_f(digest)

        accept_key = ' '
        n = min(len(accept_key), len(b64))
        if (n > 0) accept_key(1:n) = b64(1:n)
    end subroutine sha1_base64

    !------------------------------------------------------------
    ! ws_handle_upgrade
    !   - Parses HTTP Upgrade request
    !   - Extracts Sec-WebSocket-Key
    !   - Sends HTTP 101 Switching Protocols
    !------------------------------------------------------------
    logical function ws_handle_upgrade(sock, request) result(ok)
        integer, intent(in) :: sock
        character(len=*), intent(in) :: request

        character(len=:), allocatable :: key_line, ws_key, response
        character(len=256) :: accept_key_c
        integer :: p1, p2, n

        ok = .false.

        ! Find "Sec-WebSocket-Key:" line
        p1 = index(request, "Sec-WebSocket-Key:")
        if (p1 == 0) return

        p2 = index(request(p1:), new_line('a'))
        if (p2 == 0) then
            key_line = adjustl(request(p1+len("Sec-WebSocket-Key:"):))
        else
            key_line = adjustl(request(p1+len("Sec-WebSocket-Key:"):p1+p2-2))
        end if

        ws_key = trim(key_line)

        call sha1_base64(ws_key, accept_key_c)

        response = "HTTP/1.1 101 Switching Protocols"//char(13)//char(10)// &
                   "Upgrade: websocket"//char(13)//char(10)// &
                   "Connection: Upgrade"//char(13)//char(10)// &
                   "Sec-WebSocket-Accept: "//trim(accept_key_c)//char(13)//char(10)// &
                   char(13)//char(10)

        call ws_send_raw(sock, response, len_trim(response), n)
        if (n /= len_trim(response)) return

        ok = .true.
    end function ws_handle_upgrade

    !------------------------------------------------------------
    ! ws_recv_text
    !   - Receives a single text frame
    !   - Handles masking
    !   - Returns message as allocatable character
    !------------------------------------------------------------
    logical function ws_recv_text(sock, msg) result(ok)
        integer, intent(in) :: sock
        character(len=:), allocatable, intent(out) :: msg

        integer :: n, payload_len, i
        integer :: b1, b2, opcode
        logical :: fin, masked
        integer(kind=1), dimension(4) :: mask
        integer(kind=1), dimension(:), allocatable :: payload
        character(len=BUF_LEN) :: buf

        ok = .false.
        msg = ""

        ! Read first 2 bytes
        call ws_recv_raw(sock, buf, 2, n)
        if (n /= 2) return

        b1 = iachar(buf(1:1))
        b2 = iachar(buf(2:2))

        fin    = iand(b1, int(Z'80')) /= 0
        opcode = iand(b1, int(Z'0F'))
        masked = iand(b2, int(Z'80')) /= 0
        payload_len = iand(b2, int(Z'7F'))

        if (opcode == int(Z'08')) then
            ! Close frame
            ok = .false.
            return
        end if

        ! Extended payload lengths
        if (payload_len == 126) then
            call ws_recv_raw(sock, buf, 2, n)
            if (n /= 2) return
            payload_len = iachar(buf(1:1))*256 + iachar(buf(2:2))
        else if (payload_len == 127) then
            call ws_recv_raw(sock, buf, 8, n)
            if (n /= 8) return
            payload_len = iachar(buf(5:5))*256**3 + iachar(buf(6:6))*256**2 + &
                          iachar(buf(7:7))*256    + iachar(buf(8:8))
        end if

        ! Read mask if present
        if (masked) then
            call ws_recv_raw(sock, buf, 4, n)
            if (n /= 4) return
            do i = 1, 4
                mask(i) = int(iachar(buf(i:i)), kind=1)
            end do
        end if

        if (payload_len < 0 .or. payload_len > BUF_LEN) return

        allocate(payload(payload_len))

        call ws_recv_raw(sock, buf, payload_len, n)
        if (n /= payload_len) then
            deallocate(payload)
            return
        end if

        do i = 1, payload_len
            payload(i) = int(iachar(buf(i:i)), kind=1)
        end do

        if (masked) then
            do i = 1, payload_len
                payload(i) = ieor(payload(i), mask(mod(i-1,4)+1))
            end do
        end if

        msg = ""
        if (payload_len > 0) then
            msg = repeat(" ", payload_len)
            do i = 1, payload_len
                msg(i:i) = achar(mod(int(payload(i)), 256))
            end do
        end if

        deallocate(payload)
        ok = .true.
    end function ws_recv_text

    !------------------------------------------------------------
    ! ws_send_text
    !   - Sends a single unmasked text frame
    !------------------------------------------------------------
    subroutine ws_send_text(sock, msg)
        integer, intent(in) :: sock
        character(len=*), intent(in) :: msg

        integer :: payload_len, n, i, hdr_len
        character(len=BUF_LEN) :: frame
        integer :: b

        payload_len = len_trim(msg)

        ! FIN + text opcode = 0x81
        b = int(Z'81')
        frame(1:1) = achar(mod(b, 256))

        if (payload_len <= 125) then
            frame(2:2) = achar(payload_len)
            hdr_len = 2
        else if (payload_len <= 65535) then
            frame(2:2) = achar(126)
            frame(3:3) = achar(iand(ishft(payload_len, -8), int(Z'FF')))
            frame(4:4) = achar(iand(payload_len,              int(Z'FF')))
            hdr_len = 4
        else
            frame(2:2) = achar(127)
            frame(3:3) = achar(0)
            frame(4:4) = achar(0)
            frame(5:5) = achar(0)
            frame(6:6) = achar(0)
            frame(7:7)  = achar(iand(ishft(payload_len, -24), int(Z'FF')))
            frame(8:8)  = achar(iand(ishft(payload_len, -16), int(Z'FF')))
            frame(9:9)  = achar(iand(ishft(payload_len, -8),  int(Z'FF')))
            frame(10:10)= achar(iand(payload_len,              int(Z'FF')))
            hdr_len = 10
        end if

        do i = 1, payload_len
            frame(hdr_len+i:hdr_len+i) = msg(i:i)
        end do

        call ws_send_raw(sock, frame, hdr_len + payload_len, n)
    end subroutine ws_send_text

    !------------------------------------------------------------
    ! Low-level raw send/recv hooks
    !   - Mapped to tls_send / tls_recv from tls_module
    !------------------------------------------------------------
    subroutine ws_send_raw(sock, buf, nbytes, sent)
        integer, intent(in) :: sock
        character(len=*), intent(in) :: buf
        integer, intent(in) :: nbytes
        integer, intent(out) :: sent

        integer(c_int) :: res

        res = tls_send(sock, buf, nbytes)
        sent = res
    end subroutine ws_send_raw

    subroutine ws_recv_raw(sock, buf, nbytes, recvd)
        integer, intent(in) :: sock
        character(len=*), intent(out) :: buf
        integer, intent(in) :: nbytes
        integer, intent(out) :: recvd

        integer(c_int) :: res

        res = tls_recv(sock, buf, nbytes)
        recvd = res
    end subroutine ws_recv_raw

end module websocket
