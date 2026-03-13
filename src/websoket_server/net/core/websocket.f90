module websocket
  !!
  !! Minimal WebSocket server-side support on top of TLS.
  !! - Handshake (HTTP Upgrade)
  !! - Text frame send
  !! - Text frame receive (masked client frames, len < 126)
  !!
  use iso_c_binding
  implicit none
  private

  public :: ws_handle_upgrade
  public :: ws_send_text
  public :: ws_recv_text
  public :: ws_is_close

  interface
     ! You will bind these to your existing crypto/base64 C wrappers (LibreSSL/OpenSSL).
     function sha1_hash_bin(input, in_len, out_buf, out_len) bind(C, name="ws_sha1_hash_bin")
       import :: c_char, c_int
       character(kind=c_char), dimension(*), intent(in)  :: input
       integer(c_int),                      value        :: in_len
       character(kind=c_char), dimension(*), intent(out) :: out_buf
       integer(c_int),                      intent(out)  :: out_len
       integer(c_int)                                     :: sha1_hash_bin
     end function

     function base64_encode_bin(input, in_len, out_buf, out_len) bind(C, name="ws_base64_encode_bin")
       import :: c_char, c_int
       character(kind=c_char), dimension(*), intent(in)  :: input
       integer(c_int),                      value        :: in_len
       character(kind=c_char), dimension(*), intent(out) :: out_buf
       integer(c_int),                      intent(out)  :: out_len
       integer(c_int)                                     :: base64_encode_bin
     end function
  end interface

contains

  !==========================
  ! High-level entry point
  !==========================
  logical function ws_handle_upgrade(client, request_raw) result(ok)
    !!
    !! Parse HTTP Upgrade request and send WebSocket handshake response.
    !!
    integer,               intent(in) :: client
    character(len=*),      intent(in) :: request_raw

    character(len=:), allocatable :: key, accept, response

    ok = .false.

    if (.not. is_websocket_upgrade(request_raw)) return

    key = extract_sec_websocket_key(request_raw)
    if (len_trim(key) == 0) return

    accept = compute_accept_key(trim(key))

    response = &
      "HTTP/1.1 101 Switching Protocols" // crlf() // &
      "Upgrade: websocket"               // crlf() // &
      "Connection: Upgrade"              // crlf() // &
      "Sec-WebSocket-Accept: " // trim(accept) // crlf() // crlf()

    call tls_send_f(client, response)

    ok = .true.
  end function ws_handle_upgrade

  !==========================
  ! Send text frame (server → client)
  !==========================
  subroutine ws_send_text(client, msg)
    integer,          intent(in) :: client
    character(len=*), intent(in) :: msg

    integer :: plen
    character(len=:), allocatable :: frame

    plen = len_trim(msg)
    if (plen > 125) then
       ! For now, keep it simple: only small frames.
       ! You can extend to 126/127 lengths later.
       return
    end if

    allocate(character(len=2+plen) :: frame)

    ! FIN=1, opcode=1 (text)
    frame(1:1) = achar(int(Z'81'))
    ! No mask bit for server->client, payload length only
    frame(2:2) = achar(plen)
    if (plen > 0) frame(3:2+plen) = msg(1:plen)

    call tls_send_f(client, frame)
  end subroutine ws_send_text

  !==========================
  ! Receive text frame (client → server, masked, len < 126)
  !==========================
  logical function ws_recv_text(client, msg) result(ok)
    integer,               intent(in)  :: client
    character(len=:), allocatable, intent(out) :: msg

    character(len=2048) :: buf
    integer :: n, plen, i
    integer :: b1, b2, masked
    integer :: pstart
    character(len=4) :: mask
    character(len=:), allocatable :: payload

    ok = .false.
    msg = ""

    call tls_recv_f(client, buf, n)
    if (n < 6) return  ! minimal frame size

    b1 = iachar(buf(1:1))
    b2 = iachar(buf(2:2))

    ! Close frame?
    if (iand(b1, Z'0F') == Z'08') then
       ok = .false.
       return
    end if

    masked = iand(b2, Z'80')
    plen   = iand(b2, Z'7F')

    if (masked == 0) then
       ! Client frames MUST be masked
       return
    end if

    if (plen > 125) then
       ! Keep it simple for now
       return
    end if

    ! Mask key starts at byte 3
    mask = buf(3:6)
    pstart = 7

    if (n < pstart + plen - 1) return

    allocate(character(len=plen) :: payload)

    do i = 1, plen
       payload(i:i) = achar(ieor(iachar(buf(pstart + i - 1:pstart + i - 1)), iachar(mask(mod(i-1,4)+1:mod(i-1,4)+1))))
    end do

    allocate(character(len=plen) :: msg)
    msg = payload

    ok = .true.
  end function ws_recv_text

  !==========================
  ! Check if frame is close (optional helper)
  !==========================
  logical function ws_is_close(frame) result(is_close)
    character(len=*), intent(in) :: frame
    integer :: b1
    is_close = .false.
    if (len(frame) < 2) return
    b1 = iachar(frame(1:1))
    if (iand(b1, Z'0F') == Z'08') is_close = .true.
  end function ws_is_close

  !==========================
  ! Internal helpers
  !==========================
  logical function is_websocket_upgrade(req) result(is_ws)
    character(len=*), intent(in) :: req
    character(len=:), allocatable :: lower
    integer :: i

    lower = to_lower(req)
    is_ws = index(lower, "upgrade: websocket") > 0 .and. &
            index(lower, "connection: upgrade") > 0 .and. &
            index(lower, "sec-websocket-key:") > 0
  end function is_websocket_upgrade

  function extract_sec_websocket_key(req) result(key)
    character(len=*), intent(in) :: req
    character(len=:), allocatable :: key
    character(len=:), allocatable :: lower, line
    integer :: p, eol, start

    lower = to_lower(req)
    p = index(lower, "sec-websocket-key:")
    if (p == 0) then
       allocate(character(len=0) :: key)
       return
    end if

    eol = index(req(p:), crlf())
    if (eol == 0) eol = len(req) - p + 1

    line = req(p:p+eol-1)
    start = index(line, ":")
    if (start == 0) then
       allocate(character(len=0) :: key)
       return
    end if

    line = adjustl(line(start+1:))
    ! strip trailing CR/LF/spaces
    line = trim(line)

    allocate(character(len=len_trim(line)) :: key)
    key = trim(line)
  end function extract_sec_websocket_key

  function compute_accept_key(key) result(out)
    character(len=*), intent(in) :: key
    character(len=:), allocatable :: out

    character(len=*), parameter :: guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

    character(kind=c_char), dimension(0:255) :: inbuf
    character(kind=c_char), dimension(0:255) :: sha1buf
    character(kind=c_char), dimension(0:255) :: b64buf
    integer(c_int) :: in_len, sha1_len, b64_len, rc
    integer :: i

    in_len = len_trim(key) + len(guid)
    if (in_len > 256) in_len = 256

    do i = 1, len_trim(key)
       inbuf(i-1) = key(i:i)
    end do
    do i = 1, len(guid)
       inbuf(len_trim(key)+i-1) = guid(i:i)
    end do

    rc = sha1_hash_bin(inbuf, in_len, sha1buf, sha1_len)
    if (rc /= 0) then
       allocate(character(len=0) :: out)
       return
    end if

    rc = base64_encode_bin(sha1buf, sha1_len, b64buf, b64_len)
    if (rc /= 0) then
       allocate(character(len=0) :: out)
       return
    end if

    allocate(character(len=b64_len) :: out)
    do i = 1, b64_len
       out(i:i) = b64buf(i-1)
    end do
  end function compute_accept_key

  pure function crlf() result(s)
    character(len=2) :: s
    s = char(13)//char(10)
  end function crlf

  pure function to_lower(s) result(t)
    character(len=*), intent(in) :: s
    character(len=len(s)) :: t
    integer :: i, c
    do i = 1, len(s)
       c = iachar(s(i:i))
       if (c >= iachar('A') .and. c <= iachar('Z')) then
          t(i:i) = achar(c + 32)
       else
          t(i:i) = s(i:i)
       end if
    end do
  end function to_lower

end module websocket
