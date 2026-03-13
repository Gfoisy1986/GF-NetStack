module websocket
    use iso_c_binding
    use websocket_handshake      ! pour websocket_send_handshake
    use ws_tls_shim
    implicit none

    integer, parameter :: OP_TEXT   = 1
    integer, parameter :: OP_CLOSE  = 8

contains

    !---------------------------------------------------------
    !  Upgrade HTTP -> WebSocket (handshake)
    !---------------------------------------------------------
    subroutine ws_handle_upgrade(client, key)
        integer, intent(in)        :: client
        character(len=*), intent(in) :: key

        call websocket_send_handshake(client, key)
    end subroutine ws_handle_upgrade

    !---------------------------------------------------------
    !  Envoi d’un message (version minimale)
    !  NOTE : pour l’instant, on envoie juste le texte brut
    !  via TLS. On pourra ajouter le vrai framing WebSocket
    !  plus tard.
    !---------------------------------------------------------
    subroutine ws_send(client, msg)
        integer, intent(in)        :: client
        character(len=*), intent(in) :: msg

        ! TODO : encoder en vrai frame WebSocket (FIN+opcode+len+payload)
        ! Pour l’instant : envoi brut via TLS pour débloquer la build.
        call tls_send_f(client, msg)
    end subroutine ws_send

    !---------------------------------------------------------
    !  Lecture d’un message (version stub)
    !  NOTE : pour l’instant, on ne lit rien de réel.
    !  On met juste opcode=OP_TEXT et payload vide.
    !  Ça permet de compiler et de tester le flux global.
    !---------------------------------------------------------
    subroutine ws_read_frame(client, opcode, payload)
        integer, intent(in)  :: client
        integer, intent(out) :: opcode
        character(len=*), intent(out) :: payload

        ! TODO : implémenter la vraie lecture de frame WebSocket
        opcode  = OP_TEXT
        if (len(payload) > 0) payload = ""
    end subroutine ws_read_frame

end module websocket
