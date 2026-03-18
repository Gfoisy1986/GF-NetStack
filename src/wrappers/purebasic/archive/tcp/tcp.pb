ImportC "libtcp.so" ; or "tcp.dll" on Windows
    tcp_listen(port.i)
    tcp_accept(sock.i)
    tcp_recv(sock.i, *buffer, length.i)
    tcp_send(sock.i, *buffer, length.i)
    tcp_close(sock.i)
EndImport

sock = tcp_listen(9090)

If sock < 0
  MessageRequester("Error", "Failed to listen on port 8080")
  End
EndIf



ClientID = tcp_accept(sock)

If ClientID >= 0
  Debug "conection up"











Repeat
  
      
        If #PB_NetworkEvent_Data
          
          Debug "Data recieved !"
    
          *Buffer = AllocateMemory(1000)
          
            Debug ReceiveNetworkData(ClientID, *Buffer, 1000)
          
            Debug "String: "+PeekS(*Buffer, -1, #PB_UTF8)
            SendNetworkString(ClientID, "Well received !!!")
            
            FreeMemory(*Buffer)
          
        EndIf
        
       If #PB_NetworkEvent_None
          
     EndIf
          
    ForEver
    
    Debug "Closing server after " + Str(Timeout/1000) + " secs timeout"
    
    CloseNetworkServer(client)
  Else
    Debug "Can't create the TLS server"
  EndIf
; IDE Options = PureBasic 6.30 (Linux - x64)
; CursorPosition = 1
; EnableXP
; DPIAware
; Executable = tcp.so