PROGRAM tls_server
  USE ISO_C_BINDING
  USE tls_v2
  IMPLICIT NONE

  TYPE(tlsv2_server_config_t) :: cfg

  INTERFACE
     SUBROUTINE on_connect(id) BIND(C)
       USE ISO_C_BINDING
       INTEGER(C_INT), VALUE :: id
     END SUBROUTINE on_connect

     SUBROUTINE on_disconnect(id) BIND(C)
       USE ISO_C_BINDING
       INTEGER(C_INT), VALUE :: id
     END SUBROUTINE on_disconnect

     SUBROUTINE on_json(id, json, len) BIND(C)
       USE ISO_C_BINDING
       INTEGER(C_INT), VALUE :: id
       TYPE(C_PTR), VALUE    :: json
       INTEGER(C_SIZE_T), VALUE :: len
     END SUBROUTINE on_json
  END INTERFACE

  !-------------------------------------------------------------
  ! Assign config
  !-------------------------------------------------------------
  cfg%port = 8443
  cfg%cert_file = to_c_string("server.pem")
  cfg%key_file  = to_c_string("server.key")

  cfg%on_client_connected    = C_FUNLOC(on_connect)
  cfg%on_client_disconnected = C_FUNLOC(on_disconnect)
  cfg%on_json_received       = C_FUNLOC(on_json)

  PRINT *, "Starting TLS server on port 8443..."
  CALL tlsv2_server_run(cfg)

END PROGRAM tls_server
