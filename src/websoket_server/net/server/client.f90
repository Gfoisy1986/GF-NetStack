module ws_clients
    use websocket
    implicit none

    integer, parameter :: MAX_CLIENTS = 128

    type :: client_t
        integer :: socket = -1
        logical :: active = .false.
    end type client_t

    type(client_t), save :: clients(MAX_CLIENTS)

contains

    function add_client(sock) result(id)
        integer, intent(in) :: sock
        integer :: id, i

        id = -1
        do i = 1, MAX_CLIENTS
            if (.not. clients(i)%active) then
                clients(i)%socket = sock
                clients(i)%active = .true.
                id = i
                return
            end if
        end do
    end function add_client

    subroutine remove_client(id)
        integer, intent(in) :: id
        if (id < 1 .or. id > MAX_CLIENTS) return
        if (.not. clients(id)%active) return

        ! close socket here if you have a close_socket() wrapper
        ! call close_socket(clients(id)%socket)

        clients(id)%socket = -1
        clients(id)%active = .false.
    end subroutine remove_client

    subroutine broadcast(msg)
        character(len=*), intent(in) :: msg
        integer :: i

        do i = 1, MAX_CLIENTS
            if (clients(i)%active) then
                call ws_send(clients(i)%socket, msg)
            end if
        end do
    end subroutine broadcast

end module ws_clients
