 Connection = OpenNetworkConnection("127.0.0.1", 9090, #PB_Network_TCP | #PB_Network_IPv4)
  If Connection
    
    ; Send some string to the server to test
    SendNetworkString(Connection, "GET / HTTP/1.1" + #CRLF$ + "Host: www.purebasic.fr" + #CRLF$ + #CRLF$)
    
    Repeat
      Select NetworkClientEvent(Connection)
        Case #PB_NetworkEvent_Data
          *Buffer = AllocateMemory($FFFF)
          If *Buffer
            Length = ReceiveNetworkData(Connection, *Buffer, MemorySize(*Buffer))
            Received$ + PeekS(*Buffer, Length, #PB_UTF8 | #PB_ByteLength)
            Debug "Recieved string: "+ Received$
            FreeMemory(*Buffer)
          EndIf
          
        Case #PB_NetworkEvent_Disconnect
          Debug "Disconnected"
          Break
          
        Case #PB_NetworkEvent_None
          Delay(100)
          Timeout - 100
          
      EndSelect
    forever
    
    CloseNetworkConnection(Connection)
  Else
    Debug "Can't open the connection on 127.0.0.1:9090"
  EndIf
; IDE Options = PureBasic 6.30 (Linux - x64)
; CursorPosition = 26
; EnableXP
; DPIAware