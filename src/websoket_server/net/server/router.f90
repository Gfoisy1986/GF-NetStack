module router
    implicit none

contains

    subroutine route_message(msg)
        character(len=*), intent(in) :: msg

        if (index(msg, "PING") > 0) then
            print *, "Received PING"
        else
            print *, "Unknown command:", trim(msg)
        end if
    end subroutine route_message

end module router


module ws_router
    use ws_clients
    use router, only: route_message
    implicit none

contains

    subroutine ws_route(msg, client_id)
        character(len=*), intent(in) :: msg
        integer, intent(in) :: client_id

        ! Internal routing / logging
        call route_message(msg)

        ! WebSocket-level commands
        if (len_trim(msg) >= 5 .and. msg(1:5) == "ECHO:") then
            call ws_send(clients(client_id)%socket, trim(msg(6:)))
        else if (len_trim(msg) >= 5 .and. msg(1:5) == "ALL: ") then
            call broadcast(trim(msg(6:)))
        else
            call ws_send(clients(client_id)%socket, "Unknown command")
        end if
    end subroutine ws_route

end module ws_router
