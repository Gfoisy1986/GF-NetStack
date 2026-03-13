module select_wrapper
    use iso_c_binding
    use ws_clients          ! <-- IMPORT ESSENTIEL
    implicit none

    interface
        function gf_select(maxfd, fds, nfds, ready_flags) bind(C, name="gf_select")
            import :: c_int
            integer(c_int), value :: maxfd
            integer(c_int), intent(in)  :: fds(*)
            integer(c_int), value       :: nfds
            integer(c_int), intent(out) :: ready_flags(*)
            integer(c_int) :: gf_select
        end function gf_select
    end interface

contains

    subroutine wait_for_activity(listen_sock, ready_listen, ready_clients)
        integer, intent(in)  :: listen_sock
        logical, intent(out) :: ready_listen
        logical, intent(out) :: ready_clients(MAX_CLIENTS)

        integer(c_int) :: fds(1 + MAX_CLIENTS)
        integer(c_int) :: flags(1 + MAX_CLIENTS)
        integer(c_int) :: maxfd, rc
        integer :: i

        ! Initialisation
        ready_listen = .false.
        ready_clients = .false.

        ! Socket d'écoute
        fds(1) = listen_sock
        maxfd  = listen_sock

        ! Sockets clients
        do i = 1, MAX_CLIENTS
            if (clients(i)%active) then
                fds(1+i) = clients(i)%socket
                if (clients(i)%socket > maxfd) maxfd = clients(i)%socket
            else
                fds(1+i) = -1
            end if
        end do

        ! Appel à select()
        rc = gf_select(maxfd, fds, 1 + MAX_CLIENTS, flags)
        if (rc <= 0) return

        ! Résultats
        ready_listen = (flags(1) == 1)

        do i = 1, MAX_CLIENTS
            ready_clients(i) = (flags(1+i) == 1)
        end do
    end subroutine wait_for_activity

end module select_wrapper
