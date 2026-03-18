; This is the GF-NetStack CLI application...
; By Guillaume Foisy
; https://github.com/Gfoisy1986/GF-NetStack
; https://guillaumefoisy.ca/

; ============================================
;  PureBasic CLI Tool Template
; ============================================

EnableExplicit


Enumeration
  #PB_Compiler_System
EndEnumeration




Procedure.s Exec(script$, run$)
  Protected p, shPath$, line$, out$
  
  shPath$ = GetPathPart(ProgramFilename()) + "script/linux/"
  p = RunProgram(script$ , run$, shPath$, #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If p
   While ProgramRunning(p)
     Define line$ = ReadProgramString(p)
      PrintN(line$)
      out$ + line$ + #LF$
   Wend
    
  EndIf
  Debug "prog never start"
  ProcedureReturn(out$)
EndProcedure


If OpenConsole()
  EnableGraphicalConsole(1)

  PrintN("GF-Tool v1.0")
  PrintN("------------------------------")
  PrintN("")
  PrintN("write 'close' to exit terminal...")
  PrintN("")

  Define cmd$

  Repeat
    Print("> ")              ; prompt
    cmd$ = Input()           ; read user command

    Select LCase(cmd$)
      Case "close"
        Break

      Case ""
        ; ignore empty lines
        
        Case "gf hello"
          
          Define script$ = "lua"
          Define run$ = "hello.lua"
          Define out$ = ""
              Exec(script$, run$)
              PrintN(out$)
      Default
        PrintN("Unknown command: " + cmd$)
    EndSelect

  ForEver

EndIf
; IDE Options = PureBasic 6.30 (Linux - x64)
; ExecutableFormat = Console
; CursorPosition = 22
; FirstLine = 9
; Folding = -
; EnableXP
; DPIAware
; Executable = bin/GF-CLI.sh