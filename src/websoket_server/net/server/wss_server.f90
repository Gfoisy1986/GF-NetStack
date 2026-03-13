program wss_server
  !!
  !! Minimal WSS server using your TLS layer + websocket.f90
  !! - Listens on 4433
  !! - Accepts WebSocket upgrade
  !! - Echoes back any text message with a prefix
  !!
  use websocket
  use tls_module          ! adjust to your actual module name
  implicit none

  integer :: server, client
  character(len=4096) :: req
  integer :: n
  logical :: ok
  character(len=:), allocatable :: msg

  ! Initialize TLS server (cert/key paths: adapt to your setup)
  call tls_init_server_f("server.pem", "server.key", server)
  call tls_listen_f(server, 4433)

  print *, "WSS server listening on port 4433..."

  do
     call tls_accept_f(server, client)
     print *, "Client connected."

     ! Read initial HTTP Upgrade request
     call tls_recv_f(client, req, n)
     if (n <= 0) then
        call tls_close_f(client)
        cycle
     end if

     ! Handle WebSocket upgrade
     ok = ws_handle_upgrade(client, req(1:n))
     if (.not. ok) then
        print *, "Not a WebSocket upgrade, closing."
        call tls_close_f(client)
        cycle
     end if

     print *, "WebSocket handshake completed."

     ! Simple echo loop
     do
        ok = ws_recv_text(client, msg)
        if (.not. ok) then
           print *, "Client closed or error."
           exit
        end if

        print *, "Received: ", trim(msg)
        call ws_send_text(client, "echo: "//trim(msg))
     end do

     call tls_close_f(client)
     print *, "Client disconnected."
  end do

end program wss_server
