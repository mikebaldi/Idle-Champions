;-----------------------------------
;  Macro Recorder v2.1+  By FeiYue  (modified by Speedmaster, further modified by antilectual)
;  Original: https://www.autohotkey.com/boards/viewtopic.php?t=34184
;  
;  Description: This script records the mouse
;  and keyboard actions and then plays back.
;
;  F1  -->  Record(Screen) (CoordMode, Mouse, Screen)
;  F2  -->  Record(Window) (CoordMode, Mouse, Window)
;  F3  -->  Stop   Record/Play
;  F4  -->  Play   LogFile
;  F5  -->  Edit   LogFile
;  F6  -->  Pause  Record/Play
;  F9  -->  More Options
;  F10  --> Hide/Show Panel Buttons
;
;  Note:
;  1. press the Ctrl button individually
;     to record the movement of the mouse.
;  2. Shake the mouse on the Pause button,
;     you can pause recording or playback.
;-----------------------------------

#SingleInstance force
#NoEnv
SetBatchLines, -1
Thread, NoTimers
CoordMode, ToolTip
SetTitleMatchMode, 2
DetectHiddenWindows, On
; fix for wrong coords on multi-monitor setups
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")

;--------------------------
logkeys:=""
LoopCount:=1                           ; Set default number of loops to play recording
Playspeed:=2                           ; Set default playing speed here
EditorPath:="Notepad.exe"              ; set default editor path here
;~ EditorPath:=StrReplace(a_ahkpath, "autohotkey.exe") . "SciTE\SciTE.exe"     ; actvate if you have installed SciTE
LogFile:=A_Temp . "\~Record.ahk"
UsedKeys:="F1,F2,F3,F4,F5,F6,F9"
Play_Title:=RegExReplace(LogFile,".*\\") " ahk_class AutoHotkey"
global tlogmouse,tlogkey, Playspeed, LoopCount
;--------------------------
Gui 1: +AlwaysOnTop -Caption +ToolWindow +E0x08000000 +Hwndgui_id
Gui 1: Margin, 0, 0
Gui 1: Font, s11
s:="[F1]Rec (Scr),[F2]Rec (Win),"
  . "[F3]Stop,[F4]Play,[F5]Edit,[F6]Pause,[F9]Options "
For i,v in StrSplit(s, ",")
{
  j:=i=1 ? "":"x+0", j.=InStr(v,"Pause") ? " vPause":""
  Gui, Add, Button, %j% gRun, %v%
}
Gui 1: Add, Button, x+0 w0 Hidden vMyText
Gui 1: Show, NA y0, Macro Recorder

gui 2: add, groupbox, r3,Record
Gui 2: Add, Checkbox, y25 xp+10 Checked1 ghcheck vTLogkey, Log keys
Gui 2: Add, Checkbox, Checked1 ghcheck vTLogmouse, Log mouse
Gui 2: Add, Checkbox, Checked1 ghcheck vTLogWindow, Log window
Gui 2: Add, Text, , Play Speed:
Gui 2: Add, Edit, w40 ghcheck vPlayspeed Number, %Playspeed%
Gui 2: Add, Text, , Loop Count:
Gui 2: Add, Edit, w40 ghcheck vLoopCount Number, %LoopCount%
Gui 2: Add, Checkbox, Checked0 ghcheck vRepeatForever, Repeat Forever


Gui 2:add, button, vTbuttons ghidebuttons y+20 w130, Hide Panel Buttons F10
Gui 2:add, button, gopen wp, Import Macro
Gui 2:add, button, gFileSaveAs wp, Export Macro
Gui 2:add, button, gexit wp, Exit Macro Recorder
gui 2: submit

if !InStr(FileExist("Macros"), "D")
   FileCreateDir, Macros

OnMessage(0x200,"WM_MOUSEMOVE")
;--------------------------
SetTimer, OnTop, 2000
OnTop:
Gui, +AlwaysOnTop
return

hcheck:
gui 2: submit, nohide
if(RepeatForever)
    GuiControl, 2:Disable, LoopCount
else
    GuiControl, 2:Enable, LoopCount
return

F10::
hidebuttons:
hidebuttons:=!hidebuttons
if hidebuttons {
	guicontrol,, tbuttons, Show Panel Buttons F10
	Gui 1:Hide
}
else {
	guicontrol,, tbuttons, Hide Panel Buttons F10
	Gui 1:show
}
return


Run:
aguictrl:=A_GuiControl
instr(aguictrl, "scr")&&aguictrl:="[F1]Record(Screen)"
instr(aguictrl, "win")&&aguictrl:="[F2]Record(Window)"
if IsLabel(k:=RegExReplace(RegExReplace(aguictrl,".*]"),"\W")) {
  Goto, %k%
}
return




WM_MOUSEMOVE() {
  static OK_Time
  ListLines, Off
  if (A_Gui=1) and (A_GuiControl="Pause")
    and (t:=A_TickCount)>OK_Time
  {
    OK_Time:=t+500
    Gosub, Pause
  }
}

ShowTip(s:="", pos:="y35", color:="Red|00FFFF") {
  static bak, idx
  if (bak=color "," pos "," s)
    return
  bak:=color "," pos "," s
  SetTimer, ShowTip_ChangeColor, Off
  Gui, ShowTip: Destroy
  if (s="")
    return
  ; WS_EX_NOACTIVATE:=0x08000000, WS_EX_TRANSPARENT:=0x20
  Gui, ShowTip: +LastFound +AlwaysOnTop +ToolWindow -Caption +E0x08000020
  Gui, ShowTip: Color, FFFFF0
  WinSet, TransColor, FFFFF0 150
  Gui, ShowTip: Margin, 10, 5
  Gui, ShowTip: Font, Q3 s20 bold
  Gui, ShowTip: Add, Text,, %s%
  Gui, ShowTip: Show, NA %pos%, ShowTip
  SetTimer, ShowTip_ChangeColor, 1000
  ShowTip_ChangeColor:
  Gui, ShowTip: +AlwaysOnTop
  r:=StrSplit(SubStr(bak,1,InStr(bak,",")-1),"|")
  Gui, ShowTip: Font, % "Q3 c" r[idx:=Mod(Round(idx),r.length())+1]
  GuiControl, ShowTip: Font, Static1
  return
}


;============ Hotkey =============


F1::
Suspend, Permit
Goto, RecordScreen

F2::
Suspend, Permit
Goto, RecordWindow

RecordScreen:
RecordWindow:
if (Recording or Playing)
  return
Coord:=InStr(A_ThisLabel,"Win") ? "Window":"Screen"
LogArr:=[], oldid:="", Log(), Recording:=1, SetHotkey(1)
ShowTip("Recording")
return

;~ F7::
F3::
Stop:
Suspend, Permit
if Recording
{
  if (LogArr.MaxIndex()>0)
  {
    s:="`nPlayspeed:=A_Args[1] ? A_Args[1] : " . Playspeed 
      . "`nLoopCount:= A_Args[2] ? A_Args[2] : " . LoopCount
      . "`nRepeatForever:= A_Args[3] ? A_Args[3] : FALSE " 
      . "`ni:= LoopCount"
      . "`n`nwhile (i > 0)"
      . "`n{`ni:= RepeatForever ? i : i - 1"
      . "`n`nSetTitleMatchMode, 2"
      . "`nCoordMode, Mouse, " . Coord "`n"
      . "DllCall(""SetThreadDpiAwarenessContext"", ""ptr"", -3, ""ptr"")`n"
    For k,v in LogArr
      s.="`n" v "`n"
    ;~ s.="`nSleep, 1000`n`n}`n"
    s.="`n  Sleep, 1000  //PlaySpeed `n`n}`n"
    s:=RegExReplace(s,"\R","`n")
    FileDelete, %LogFile%
    FileAppend, %s%, %LogFile%
    s:=""
  }
  SetHotkey(0), Recording:=0, LogArr:=""
}
else if Playing
{
  WinGet, list, List, %Play_Title%
  Loop, % list
    if WinExist("ahk_id " list%A_Index%)!=A_ScriptHwnd
    {
      WinGet, pid, PID
      WinClose,,, 3
      IfWinExist
        Process, Close, %pid%
    }
  SetTimer, CheckPlay, Off
  Playing:=0
}
ShowTip()
Suspend, Off
Pause, Off
GuiControl,, Pause, % "[F6] Pause "
isPaused:=0
return


F4::
Play:
Suspend, Permit
if (Recording or Playing)
  Gosub, Stop
ahk:=A_IsCompiled ? A_ScriptDir "\AutoHotkey.exe" : A_AhkPath
IfNotExist, %ahk%
{
  MsgBox, 4096, Error, Can't Find %ahk% !
  Exit
}
; Loops/Infinite?
; playback speed
;Run, %A_AhkPath% "%scriptLocation%" "%guid%"
LoopCount:=LoopCount + 0
PlaySpeed:=PlaySpeed + 0
Run, %ahk% /r "%LogFile%" "%Playspeed%" "%LoopCount%" "%RepeatForever%"
SetTimer, CheckPlay, 500
Gosub, CheckPlay
return

CheckPlay:
Check_OK:=0
WinGet, list, List, %Play_Title%
Loop, % list
  if (list%A_Index%!=A_ScriptHwnd)
    Check_OK:=1
if Check_OK
  Playing:=1, ShowTip("Playing")
else if Playing
{
  SetTimer, CheckPlay, Off
  Playing:=0, ShowTip()
}
return


;~ F8::
F5::
Edit:
Suspend, Permit
Gosub, Stop
Run, %EditorPath% "%LogFile%"
return


F6::
Pause:
Suspend, Permit
if Recording
{
  Suspend
  Pause, % A_IsSuspended ? "On":"Off", 1
  isPaused:=A_IsSuspended, Log()
}
else if Playing
{
  isPaused:=!isPaused
  WinGet, list, List, %Play_Title%
  Loop, %list%
    if WinExist("ahk_id " list%A_Index%)!=A_ScriptHwnd
      PostMessage, 0x111, 65306
}
else 
return

if isPaused
  GuiControl,, Pause, [F6]<Pause>
else
  GuiControl,, Pause, % "[F6] Pause "
return


Open:
OutputVar:=""
FileSelectFile, OutputVar,, macros, Import File, AHK Macro File (*.ahk; *.txt)
if (OutputVar)
FileCopy, % OutputVar, % LogFile , 1
return

;-------------------------
FileSaveAs:
Gui +OwnDialogs  ; Force the user to dismiss the FileSelectFile dialog before returning to the main window.
FileSelectFile, SelectedFileName, S16, Macros, Save File, AHK File (*.ahk)
if SelectedFileName =  ; No file selected.
    return
CurrentFileName = %SelectedFileName%

IfExist %CurrentFileName%
{
    FileDelete %CurrentFileName%
    if ErrorLevel
    {
        MsgBox The attempt to overwrite "%CurrentFileName%" failed.
        return
    }
}

SplitPath, CurrentFileName,,, OutExtension

if (OutExtension)
  FileCopy, % LogFile, % CurrentFileName , 1
else
  FileCopy, % LogFile, % CurrentFileName ".ahk" , 1
return

F9::
Options:
Gui 2: +AlwaysOntop
Gui 2: Show, y100, Macro Recorder
gui 2: submit, nohide
return

;~ F12::
exit:
SplashTextOn,100,70,Macro recorder, `nGoodbye
sleep, 1000
exitapp
return


;============ Functions =============


SetHotkey(f:=0) {
  ; These keys are already used as hotkeys
  global UsedKeys
  f:=f ? "On":"Off"
  Loop, 254
  {
    k:=GetKeyName(vk:=Format("vk{:X}", A_Index))
    if k not in ,Control,Alt,Shift,%UsedKeys%
      Hotkey, ~*%vk%, LogKey, %f% UseErrorLevel
  }
  For i,k in StrSplit("NumpadEnter|Home|End|PgUp"
    . "|PgDn|Left|Right|Up|Down|Delete|Insert", "|")
  {
    sc:=Format("sc{:03X}", GetKeySC(k))
    if k not in ,Control,Alt,Shift,%UsedKeys%
      Hotkey, ~*%sc%, LogKey, %f% UseErrorLevel
  }
  SetTimer, LogWindow, %f%
  if (f="On")
    LogWindow()
}

LogKey:
LogKey()
return

LogKey() {
  Critical
  LogWindow()
  k:=GetKeyName(vksc:=SubStr(A_ThisHotkey,3))
  k:=StrReplace(k,"Control","Ctrl"), r:=SubStr(k,2)
  if r in Alt,Ctrl,Shift,Win
    (tlogkey)&&LogKey_Control(k)
  else if k in LButton,RButton,MButton
    (TlogMouse)&&LogKey_Mouse(k)
  else
  {
    if (!tlogkey)
      return
    if (k="NumpadLeft" or k="NumpadRight") and !GetKeyState(k,"P")
      return
    k:=StrLen(k)>1 ? "{" k "}" : k~="\w" ? k : "{" vksc "}"
    Log(k,1)
  }
}

LogKey_Control(key) {
  global LogArr, Coord
  k:=InStr(key,"Win") ? key : SubStr(key,2)
  if (k="Ctrl")
  {
    CoordMode, Mouse, %Coord%
    MouseGetPos, X, Y
  }
  Log("{" k " Down}",1)
  Critical, Off
  KeyWait, %key%
  Critical
  Log("{" k " Up}",1)
  if (k="Ctrl")
  {
    i:=LogArr.MaxIndex(), r:=LogArr[i]
    if InStr(r,"{Blind}{Ctrl Down}{Ctrl Up}")
      LogArr[i]:="MouseMove, " X ", " Y
  }
}

LogKey_Mouse(key) {
  global gui_id, LogArr, Coord
  k:=SubStr(key,1,1)
  CoordMode, Mouse, %Coord%
  MouseGetPos, X, Y, id
  if (id=gui_id)
    return
  LogWindow()
  Log("MouseClick, " k ", " X ", " Y ",,, D")
  CoordMode, Mouse, Screen
  MouseGetPos, X1, Y1
  t1:=A_TickCount
  Critical, Off
  KeyWait, %key%
  Critical
  t2:=A_TickCount
  if (t2-t1<=200)
    X2:=X1, Y2:=Y1
  else
    MouseGetPos, X2, Y2
  i:=LogArr.MaxIndex(), r:=LogArr[i]
  if InStr(r, ",,, D") and Abs(X2-X1)+Abs(Y2-Y1)<5
    LogArr[i]:=SubStr(r,1,-5), Log()
  else
    Log("MouseClick, " k ", " (X+X2-X1) ", " (Y+Y2-Y1) ",,, U")
}

LogWindow() {
  global oldid, LogArr, TLogWindow
  static oldtitle
  if (!TLogWindow)
    return
  activeHwnd := WinActive()
  id:=WinExist("A")
  WinGetTitle, title
  WinGetClass, class
  if (title="" and class="")
    return
  if (id=oldid and title=oldtitle)
    return
  oldid:=id, oldtitle:=title
  title:=SubStr(title,1,50)
  if (!A_IsUnicode)
  {
    GuiControl,, MyText, %title%
    GuiControlGet, s,, MyText
    if (s!=title)
      title:=SubStr(title,1,-1)
  }
  title.=class ? " ahk_class " class : ""
  title:=RegExReplace(Trim(title), "[``%;]", "``$0")
  ;~ s:="tt = " title "`nWinWait, %tt%"
    ;~ . "`nIfWinNotActive, %tt%,, WinActivate, %tt%"  
  s:="      tt = " title "`n      WinWait, %tt%"
    . "`n      IfWinNotActive, %tt%,, WinActivate, %tt%"    
  i:=LogArr.MaxIndex(), r:=LogArr[i]
  if InStr(r,"tt = ")=1
    LogArr[i]:=s, Log()
  else
    Log(s)
}

Log(str:="", Keyboard:=0) {
  global LogArr
  static LastTime
  t:=A_TickCount, Delay:=(LastTime ? t-LastTime:0), LastTime:=t
  IfEqual, str,, return
  i:=LogArr.MaxIndex(), r:=LogArr[i]
  if (Keyboard and InStr(r,"Send,") and Delay<1000)
  {
    LogArr[i]:=r . str
    return
  }
  if (Delay>200)
    ;~ LogArr.Push("Sleep, " (Delay//2))
    LogArr.Push("  Sleep, `% " (Delay) " //playspeed")
  LogArr.Push(Keyboard ? "Send, {Blind}" str : str)
}

;============ The End ============
