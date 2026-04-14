;===========================================================
;  gfns_ws.pbi
;  Combined PureBasic FFI + High-Level WebSocket Wrapper
;  for GF‑NetStack WebSocket module
;===========================================================

;-----------------------------------------------------------
; 1. Low-level C struct placeholder
;-----------------------------------------------------------
Structure GFNS_WS
  _opaque.l[4]   ; not accessed by PB
EndStructure

;-----------------------------------------------------------
; 2. WebSocket opcodes (RFC6455)
;-----------------------------------------------------------
Enumeration GFNS_WS_OPCODE
  #GFNS_WS_OP_CONT   = $0
  #GFNS_WS_OP_TEXT   = $1
  #GFNS_WS_OP_BINARY = $2
  #GFNS_WS_OP_CLOSE  = $8
  #GFNS_WS_OP_PING   = $9
  #GFNS_WS_OP_PONG   = $A
EndEnumeration

;-----------------------------------------------------------
; 3. Import C functions from gfns_ws.c
;-----------------------------------------------------------
ImportC "gfns_ws.lib"
  gfns_ws_open_url(url.p-ascii) As "_gfns_ws_open_url"
  gfns_ws_send(*ws.GFNS_WS, opcode.l, *data, len.i) As "_gfns_ws_send"
  gfns_ws_recv(*ws.GFNS_WS, *opcode_out.l, *buf, buf_size.i, *len_out.i) As "_gfns_ws_recv"
  gfns_ws_close(*ws.GFNS_WS, code.w, reason.p-ascii) As "_gfns_ws_close"
  gfns_ws_free(*ws.GFNS_WS) As "_gfns_ws_free"
EndImport

;-----------------------------------------------------------
; 4. High-level PB wrapper (user-friendly API)
;-----------------------------------------------------------
Structure GF_WS_HANDLE
  *ws.GFNS_WS
EndStructure

Global NewMap GF_WS.GF_WS_HANDLE()

;-----------------------------------------------------------
; gf_ws(#PB_Any, "wss://echo.websocket.events/")
;-----------------------------------------------------------
Procedure.i gf_ws(id.i, url.s)
  Protected *ws.GFNS_WS = gfns_ws_open_url(url)
  If *ws = 0
    ProcedureReturn 0
  EndIf

  If id = #PB_Any
    id = MapSize(GF_WS()) + 1
  EndIf

  AddMapElement(GF_WS(), Str(id))
  GF_WS()\ws = *ws

  ProcedureReturn id
EndProcedure

;-----------------------------------------------------------
; Send text frame
;-----------------------------------------------------------
Procedure gf_ws_send_text(id.i, text.s)
  If FindMapElement(GF_WS(), Str(id)) = 0 : ProcedureReturn : EndIf

  Protected *ws.GFNS_WS = GF_WS()\ws
  Protected *p.ASCII = AllocateMemory(Len(text) + 1)
  PokeS(*p, text, -1, #PB_Ascii)

  gfns_ws_send(*ws, #GFNS_WS_OP_TEXT, *p, MemoryStringLength(*p, #PB_Ascii))
  FreeMemory(*p)
EndProcedure

;-----------------------------------------------------------
; Receive text frame
;-----------------------------------------------------------
Procedure.s gf_ws_recv_text(id.i)
  If FindMapElement(GF_WS(), Str(id)) = 0 : ProcedureReturn "" : EndIf

  Protected *ws.GFNS_WS = GF_WS()\ws
  Protected opcode.l
  Protected bufSize = 4096
  Protected *buf = AllocateMemory(bufSize)
  Protected len.i

  If gfns_ws_recv(*ws, @opcode, *buf, bufSize, @len) < 0
    FreeMemory(*buf)
    ProcedureReturn ""
  EndIf

  If opcode <> #GFNS_WS_OP_TEXT
    FreeMemory(*buf)
    ProcedureReturn ""
  EndIf

  Protected result.s = PeekS(*buf, len, #PB_Ascii)
  FreeMemory(*buf)
  ProcedureReturn result
EndProcedure

;-----------------------------------------------------------
; Close WebSocket
;-----------------------------------------------------------
Procedure gf_ws_close(id.i)
  If FindMapElement(GF_WS(), Str(id)) = 0 : ProcedureReturn : EndIf

  Protected *ws.GFNS_WS = GF_WS()\ws
  gfns_ws_close(*ws, 1000, #Null$)
  gfns_ws_free(*ws)
  DeleteMapElement(GF_WS())
EndProcedure
