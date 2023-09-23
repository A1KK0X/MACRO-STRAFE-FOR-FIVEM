;=============================================
; Author: Toady (Josh Bolton)
; Email: itoady@gmail.com
; Website: http://www.itoady.com
; Language: Autoit3
; Version: 2.7.5
; Date Created: Jan. 25, 2007
; Last Updated: Jun. 22, 2007
; Requirements:
;	  OS:  Win2000 / WinXP / Vista
;     CPU: 800Mhz Processor
;     Standard Keyboard US/UK (QWERTY)
; Purpose and Use: 
;     This application is a keystroke simulator.
;	  It is geared torward the gaming industry.
;     Some games block this application from sending
;     key strokes to them. 
; Terms of Use: 
;     Source code is open to use.
;     Please give credit where its due.
;     Code is provided "As is", any alteration
;     will void ANY warranty.
;==============================================

#include <GuiConstants.au3>
#include <GuiList.au3>
#include <GuiListView.au3>
#include <Array.au3>
#Include <GuiStatusBar.au3>
#Include <GuiCombo.au3>
#include <File.au3>
#Include <Constants.au3>
#include <INet.au3>
#Include <A3LString.au3> ;Library provided by Paul Campbell (PaulIA)
#include <A3LListbox.au3> ;Library provided by Paul Campbell (PaulIA)

$g_szVersion = "MacroGamer"   
If _Singleton($g_szVersion, 1) = 0 Then
    MsgBox(64, "MacroGamer", "MacroGamer Already running.", 2)
    Exit
EndIf

;====================================================
; MacroGamer only works on OS's of win 2000 or newer.
;====================================================
If StringRegExp(@OSVersion,"(98)|(95)|(ME)") = 1 Then
	MsgBox(0,"Unable to run","MacroGamer is only compatible with Windows 2000, XP, and Vista")
	Exit
EndIf

Opt("TrayMenuMode",1) 
TraySetState()
FileInstall ( "scancodes.dat", @ScriptDir & "\", 1) ;Installs if these dont exist
FileInstall("profile.mgp",@ScriptDir & "\", 0) ; ^^
FileInstall ( "mgconfig.dat", @ScriptDir & "\", 0) ; ^^
;===================================
; Application Config
;===================================
Global $timerit = 0
$exe_name = "MacroGamer2007.au3"
Global $version = "2.7.5"
Global $updateLocation = "http://home.insightbb.com/~theojdude/itoady/check_update.txt"
Global $tempUpdateSaveName = "check_update.txt"
Global $App_Name = "MacroGamer"
Global $MainWidth, $MainHeight
Global $CeWidth, $CeHeight
Global $editflag = 0
Global $time_init = 0
Global $time_between = 0
Global $OptionsW, $OptionsH
Global $ini_file = "profile.mgp"
Global $config = @ScriptDir & "\mgconfig.dat"
Global $scancodes = @ScriptDir & "\scancodes.dat"
Global $AboutStr = "Author: Toady" & @CRLF & @CRLF & "Version " & $version  & @CRLF & @CRLF & "http://www.itoady.com"
Global $keydowndelay = 10
Global $DisplayNotify = 1
Global $DisplayNotifyRecord = 1
Global $runstop_hotkey = "{F3}"
Global $currentOpenMacroIndex = 0
Global $MacroList
Global $Paused = 1
Global $time_init = TimerInit()
Global $downlist = _ArrayCreate(-1)
Global $PlayingMacro = 0
Global $b_runstop_used = 0
Global $first_time_ran = 1
Global $macroOBJ = _ArrayCreate(-1)
Global $MacroIndex = _ArrayCreate(-1) ;Macro Index
$MainWidth = 235
$MainHeight = 250
$CeWidth = 450
$CeHeight = 330
$OptionsW = 340
$OptionsH = 220
$KeybindsW = 250
$KeybindsH = 220
;===================================
; GUI: Main
;===================================
$MainWin = GUICreate($App_Name, $MainWidth, $MainHeight, (@DesktopWidth-$MainWidth)/2, (@DesktopHeight-$MainHeight)/2)
$filemenu = GuiCtrlCreateMenu ("File")
$newitem = GuiCtrlCreateMenuitem ("New Profile",$filemenu)
$fileitem = GuiCtrlCreateMenuitem ("Load Profile...",$filemenu)
$separator1 = GuiCtrlCreateMenuitem ("",$filemenu)
$exititem = GuiCtrlCreateMenuitem ("Exit",$filemenu)
$viewmenu = GuiCtrlCreateMenu ("View")
$optionsitem = GuiCtrlCreateMenuitem ("Settings...",$viewmenu)
$optionsbindedkeys = GuiCtrlCreateMenuitem ("Binded keys",$viewmenu)
$helpmenu = GuiCtrlCreateMenu ("Help")
$helpitem = GuiCtrlCreateMenuitem ("Help",$helpmenu)
$aboutitem = GuiCtrlCreateMenuitem ("About",$helpmenu)
GuiCtrlCreateMenuitem ("",$helpmenu)
$updateitem = GuiCtrlCreateMenuitem ("Check for update",$helpmenu)
$macrolist=GUICtrlCreateList ("", 10,10,120,200)
$b_run = GUICtrlCreateButton ("Run", 140, 150,38,38)
$b_stop = GUICtrlCreateButton ("Stop", 185,150,38,38)
GUICtrlSetState($b_stop,$GUI_DISABLE)
$b_New = GUICtrlCreateButton("Create New",140,20,80,30)
$b_Edit = GUICtrlCreateButton("Edit",140,58,80,30)
$b_Delete = GUICtrlCreateButton("Delete",140,96,80,30)
GUICtrlSetState($b_Edit,$GUI_DISABLE)
GUICtrlSetState($b_Delete,$GUI_DISABLE)
GUICtrlSetState($b_run,$GUI_DISABLE)
Global $a_PartsRightEdge[2] = [160,-1]
Global $a_PartsText[2] = ["Stopped"," Version " & $version ]
$statusbar = _GUICtrlStatusBarCreate($MainWin,$a_PartsRightEdge,$a_PartsText)
GUISetState(@SW_SHOW,$MainWin)
;===================================
; GUI: Create / Edit
;===================================
$CeWin = GUICreate("Macro Editor", $CeWidth, $CeHeight, (@DesktopWidth-$CeWidth)/2, (@DesktopHeight-$CeHeight)/2,$WS_CAPTION,Default,$MainWin)
$l_name = GUICtrlCreateLabel("Name: ",10,15,40,20)
$l_timed = GUICtrlCreateLabel("Events",10,35,40,20)
$in_name = GUICtrlCreateInput("",50,10,120,20)
$Seqlist=GUICtrlCreateList ("", 10,50,180,250,BitOR($WS_BORDER, $WS_VSCROLL, $WS_TABSTOP, $LBS_NOTIFY,$LBS_DISABLENOSCROLL))
$b_startRec = GUICtrlCreateButton("Start Recording",210,10,100,30)
$b_stopRec = GUICtrlCreateButton("Stop Recording",210,45,100,30)
GUICtrlSetState($b_stopRec,$GUI_DISABLE)
$b_Insert = GUICtrlCreateButton("Insert >>",210,85,100,30)
$b_DeleteItem = GUICtrlCreateButton("Delete",210,120,100,30)
$b_MoveUp = GUICtrlCreateButton("Move Up",210,155,100,30)
$b_MoveDown= GUICtrlCreateButton("Move Down",210,190,100,30)
$b_OK = GUICtrlCreateButton("OK",210,270,100,30)
$b_Cancel = GUICtrlCreateButton("Cancel",330,270,100,30)
$in_hidden = GUICtrlCreateInput("",0,0) ;Send all keypresses to this hidden control
GUICtrlSetState($in_hidden,$GUI_HIDE)   ;keeps Windows from making funny noises
GUICtrlSetState($b_DeleteItem,$GUI_DISABLE)
$InsertDummy = GUICtrlCreateDummy()
$InsertContext= GUICtrlCreateContextMenu($InsertDummy)
$m_InsertDelay = GUICtrlCreateMenuItem("Delay", $InsertContext)
GUICtrlCreateMenuItem("", $InsertContext)
$m_InsertKeyUpDown = GUICtrlCreateMenuItem("Key Event", $InsertContext)
$m_InsertMouseEvent = GUICtrlCreateMenuItem("Mouse Event", $InsertContext)
GUICtrlCreateMenuItem("", $InsertContext)
$m_InsertPixelCheck = GUICtrlCreateMenuItem("Pixel Event", $InsertContext)
$l_delay = GUICtrlCreateLabel("Delay: ",215,242,30,20)
$in_delay = GUICtrlCreateInput("0.05",250,240,45,20,BitOR($ES_CENTER,$ES_NUMBER,$ES_READONLY))
$b_up = GUICtrlCreateButton("/\",295,240,15,10)
$b_down = GUICtrlCreateButton("\/",295,250,15,10)
$c_delayrecord = GUICtrlCreateCheckbox("Record delays",330,15)
$c_mousepathrecord = GUICtrlCreateCheckbox("Mouse moves",330,35)
$c_mouseclickrecord = GUICtrlCreateCheckbox("Mouse clicks",330,55)
$c_mouseclickposrecord = GUICtrlCreateCheckbox("Click position",345,75)
GUICtrlSetState($c_mouseclickposrecord,$GUI_DISABLE)
$l_bindkey = GUICtrlCreateLabel("Binded to:",330,110,100,20)
$in_bindkey = GUICtrlCreateInput("No Key",330,130,100,20,BitOR($ES_CENTER,$ES_READONLY))
$b_bindkey = GUICtrlCreateButton("Bind to key",330,155,100,30)
GUICtrlSetTip($b_bindkey,"Press ESC to debind","",0,1)
$r_mtype1 = GuiCtrlCreateRadio("Play only once", 330, 195, 120)
GuiCtrlSetState($r_mtype1, $GUI_CHECKED)
$r_mtype2 = GuiCtrlCreateRadio("Repeat", 330, 217, 55)
$repeat_input = GUICtrlCreateInput("1",390,217,50,20,BitOR($ES_CENTER,$ES_NUMBER))
$r_mtype3 = GuiCtrlCreateRadio("Repeat until stopped", 330, 238, 120)
Global $a_editorEdges[1] = [-1]
Global $a_PartsText[1] = ["Stopped"]
$statusbar2 = _GUICtrlStatusBarCreate($CeWin,$a_editorEdges,$a_PartsText)
GUICtrlSetState($repeat_input,$GUI_DISABLE)
GUICtrlCreateUpdown($repeat_input)
GUICtrlSetLimit($repeat_input,2,1) 
GuiCtrlSetState($c_delayrecord, $GUI_CHECKED)
GUICtrlSetState($b_DeleteItem,$GUI_DISABLE)
GUICtrlSetState($b_MoveUp,$GUI_DISABLE)
GUICtrlSetState($b_MoveDown,$GUI_DISABLE)
;===================================
; GUI: Options
;===================================
$OptionWin = GUICreate("Settings", $OptionsW, $OptionsH, (@DesktopWidth-$OptionsW)/2, (@DesktopHeight-$OptionsH)/2, $WS_CAPTION,Default,$MainWin)
$Option_b_defaultpro = GUICtrlCreateButton("Default Profile",10,25,80,30)
$Option_in_default = GUICtrlCreateInput(@ScriptDir & "\profile.mgp",100,30,220,20,BitOR($GUI_SS_DEFAULT_INPUT, $ES_READONLY,$ES_OEMCONVERT))
$Option_b_ONOFF = GUICtrlCreateButton("Run/Stop Hotkey",10,70,100,30)
$Option_in_ONOFF = GUICtrlCreateInput("{F3}",120,75,100,20,BitOR($ES_CENTER,$ES_READONLY))
$Option_ck_Notify = GUICtrlCreateCheckbox("Notify with sound",230,75)
$Option_b_Record = GUICtrlCreateButton("Start/Stop Record",10,110,100,30)
$Option_in_Record = GUICtrlCreateInput("{F2}",120,115,100,20,BitOR($ES_CENTER,$ES_READONLY))
$Option_ck_Record_Notify = GUICtrlCreateCheckbox("Notify with sound",230,115)
$Option_b_OK = GUICtrlCreateButton("OK",60,170,100,30)
$Option_b_cancel = GUICtrlCreateButton("Cancel",170,170,100,30)
;===================================
; GUI: Insert Keypress (up/down)
;===================================
$KeyUpDownWin = GUICreate("Insert Key Event", 230, 170, (@DesktopWidth-230)/2, (@DesktopHeight-170)/2, $WS_CAPTION,Default,$CeWin)
GuiCtrlCreateGroup("Type of press", 10, 60, 100, 90)
$r_keypress = GuiCtrlCreateRadio("Normal", 20, 80, 80)
GuiCtrlSetState($r_keypress, $GUI_CHECKED)
$r_keydown = GuiCtrlCreateRadio("Hold down", 20, 100, 80)
$r_keyup = GuiCtrlCreateRadio("Release", 20, 120, 80)
GUICtrlCreateGroup ("",-99,-99,1,1) 
$b_InsertOK = GUICtrlCreateButton("OK",120,80,100,30)
$b_InsertCancel = GUICtrlCreateButton("Close",120,120,100,30)
$b_InsertRecord = GUICtrlCreateButton("Record",10,20,100,30)
$in_insert = GUICtrlCreateInput("",120,20,100,20,BitOR($ES_CENTER,$ES_READONLY))
GUICtrlSetState($b_InsertOK,$GUI_DISABLE)
;===================================
; GUI: Insert Mouse button press (up/down)
;===================================
$MouseWin = GUICreate("Insert Mouse Event", 230, 170, (@DesktopWidth-230)/2, (@DesktopHeight-170)/2, $WS_CAPTION,Default,$CeWin)
GuiCtrlCreateGroup("Select Mouse Button", 45, 10, 140, 100)
$r_l_mouse = GuiCtrlCreateRadio("Left", 85, 30, 80)
GuiCtrlSetState($r_l_mouse, $GUI_CHECKED)
$r_m_mouse = GuiCtrlCreateRadio("Middle", 85, 55, 80)
$r_r_mouse = GuiCtrlCreateRadio("Right", 85, 80, 80)
GUICtrlCreateGroup ("",-99,-99,1,1) 
$b_InsertMouseOK = GUICtrlCreateButton("OK",10,120,100,30)
$b_InsertMouseCancel = GUICtrlCreateButton("Close",120,120,100,30)
;===================================
; GUI: Insert Delay
;===================================
$DelayWin = GUICreate("Insert Delay", 230, 190, (@DesktopWidth-230)/2, (@DesktopHeight-190)/2, $WS_CAPTION,Default,$CeWin)
GuiCtrlCreateGroup("In Seconds", 50, 10, 120, 70)
$delay_digit_input = GUICtrlCreateInput("0",65,40,40,20,BitOR($ES_CENTER,$ES_NUMBER))
$delay_decimal_input = GUICtrlCreateInput("05",115,40,40,20,BitOR($ES_CENTER,$ES_NUMBER))
GUICtrlSetLimit($delay_decimal_input,2,1)
GUICtrlCreateGroup (".",-99,-99,1,1)
$b_InsertDelayOK = GUICtrlCreateButton("OK",60,100,100,30)
$b_InsertDelayCancel = GUICtrlCreateButton("Close",60,140,100,30)
;===================================
; GUI: View Keybinds
;===================================
$KeyBindWin = GUICreate("View Binded Keys", $KeybindsW, $KeybindsH, (@DesktopWidth-$KeybindsW)/2, (@DesktopHeight-$KeybindsH)/2, $WS_CAPTION,Default,$MainWin)
GUICtrlCreateLabel("Profile:",10,5)
$profile_keybind_label = GUICtrlCreateLabel("",45,5,100,20)
$listview = GUICtrlCreateListView ("Macro|Key",10,25,$KeybindsW-20,$KeybindsH-65,BitOr($GUI_SS_DEFAULT_LISTVIEW,$LVS_NOSORTHEADER,$LVS_EDITLABELS ))
GUICtrlSetState($listview,$GUI_DROPACCEPTED)
$keybinds_b_close = GUICtrlCreateButton("Close",($KeybindsW-100)/2,$KeybindsH-35,100,30)
;===================================
; GUI: Insert Pixel check
;===================================
$PixelCheckWin = GUICreate("Insert Pixel Event", 260, 260, (@DesktopWidth-260)/2, (@DesktopHeight-260)/2, $WS_CAPTION,Default,$CeWin)
GuiCtrlCreateGroup("Location", 20, 10, 220, 80)
GUICtrlCreateLabel("X",30,35)
$in_PixelX = GUICtrlCreateInput("0",50,30,60,20)
GUICtrlCreateLabel("Y",30,65)
$in_PixelY = GUICtrlCreateInput("0",50,60,60,20)
$b_GetPixelLocation = GUICtrlCreateButton("Pick Location",130,40,100,30)
GuiCtrlCreateGroup("Event", 20, 100, 220, 110)
$PixelCheck_Wait_ck = GUICtrlCreateCheckbox("Wait for color",35,120)
$PixelCheck_hex = GUICtrlCreateLabel("Hex",35,150)
$in_PixelColor = GUICtrlCreateInput("000000",60,145,60,20)
$b_GetPixelColor = GUICtrlCreateButton("Update",80,175,60)
GUICtrlSetState($b_GetPixelColor,$GUI_DISABLE)
GUICtrlSetState($PixelCheck_hex,$GUI_DISABLE)
GUICtrlSetState($in_PixelColor,$GUI_DISABLE)
$PixelCheck_Move_ck = GUICtrlCreateCheckbox("Mouse move",150,120)
$PixelCheck_Click_ck = GUICtrlCreateCheckbox("Mouse click",150,140)
$r_l_mouse_pixel = GuiCtrlCreateRadio("Left", 165, 160,65)
$r_r_mouse_pixel = GuiCtrlCreateRadio("Right", 165, 180,65)
GuiCtrlSetState($r_l_mouse_pixel, $GUI_CHECKED)
GUICtrlSetState($PixelCheck_Click_ck,$GUI_DISABLE)
GUICtrlSetState($r_l_mouse_pixel,$GUI_DISABLE)
GUICtrlSetState($r_r_mouse_pixel,$GUI_DISABLE)
$preview_color = GUICtrlCreateGraphic(30,175,40,25,$SS_BLACKFRAME)
$b_InsertPixelOK = GUICtrlCreateButton("Insert",20,220,100,30)
$b_InsertPixelCancel = GUICtrlCreateButton("Cancel",140,220,100,30)
;===================================
; HotKey config
;===================================
Opt("SendKeyDelay",0)
Opt("SendKeyDownDelay",0)
Opt("MouseClickDelay",0)
Opt("MouseClickDownDelay",0)
Opt("MouseClickDragDelay",0)
Opt("GUICloseOnESC",0)
Opt("GUIOnEventMode",0)
Opt("OnExitFunc", "_ClearKeyboardCache")
;===================================
; Initialize configuration
;===================================
LoadSettings($config) ;Init all user settings
$first_time_ran = 0
LoadMacroList($ini_file) ;Init current macro profile in listbox
LoadKeyBoardLayout($scancodes) ;Init array of keyboard scancodes
;===================================
; Main Loop
;===================================
While 1
	$msg = GUIGetMsg(1)
	Select
		Case $msg[0] = $GUI_EVENT_CLOSE
			If $msg[1] = $MainWin Then
				Exit
			ElseIf $msg[1] = $KeyUpDownWin Then
				GUISetState(@SW_HIDE,$KeyUpDownWin)
				GUISetState(@SW_ENABLE,$CeWin)
				GUISetState(@SW_RESTORE,$CeWin)
			EndIf
		Case $msg[0] = $keybinds_b_close
			GUISetState(@SW_HIDE,$KeyBindWin)
		Case $msg[0] = $helpitem
			If FileExists(@scriptdir & "\help.chm") Then
				ShellExecute("help.chm", "", @ScriptDir, "open")
			Else
				MsgBox(0,"No help file found","Please re-install MacroGamer")
			EndIf
		Case $msg[0] = $optionsbindedkeys
			GUISetState(@SW_SHOW,$KeyBindWin)
			OnClick_ViewKeyBinds()
		Case $msg[0] = $updateitem
			_CheckForUpdate($version,$updateLocation,$tempUpdateSaveName)
		Case $msg[0] = $fileitem ;load profile
			OnClick_LoadProfile()
		Case $msg[0] = $newitem ;make new profile
			OnClick_NewProfile()
		Case $msg[0] = $Option_b_defaultpro
			SetDefaultProfile()
		Case $msg[0] = $Option_b_ONOFF
			DisableCurrentONOFF()
			RecordONOFF_HotKey()
			EnabledCurrentONOFF()
		Case $msg[0] = $Option_b_Record
			RecordStartStop_HotKey()
		Case $msg[0] = $Option_b_OK
			Onclick_SaveSettings()
			GUISetState(@SW_HIDE,$OptionWin)
			GUISetState(@SW_ENABLE,$MainWin)
			GUISetState(@SW_RESTORE,$MainWin)			
		Case $msg[0] = $Option_b_cancel
			EnabledCurrentONOFF()
			GUISetState(@SW_HIDE,$OptionWin)
			GUISetState(@SW_ENABLE,$MainWin)
			GUISetState(@SW_RESTORE,$MainWin)
		Case $msg[0] = $aboutitem
			MsgBox(0,"About",$AboutStr)
		Case $msg[0] = $b_New
			GUISetState(@SW_SHOW,$CeWin)
			GUISetState(@SW_DISABLE,$MainWin)
			DisableCurrentONOFF()
			HotKeySet($runstop_hotkey)
			HotKeySet(_ConvertToHotKeyNotation(GUICtrlRead($Option_in_Record)),"Toggle_Record_Start_Stop")
			$editflag = 0
			ClearEditorWindow()
		Case $msg[0] = $b_Cancel
			EnabledCurrentONOFF()
			HotKeySet($runstop_hotkey,"Toggle_Run_Stop")
			GUISetState(@SW_HIDE,$CeWin)
			GUISetState(@SW_HIDE,$DelayWin)
			GUISetState(@SW_ENABLE,$MainWin)
			GUISetState(@SW_RESTORE,$MainWin)
			HotKeySet(GUICtrlRead($Option_in_Record))
		Case $msg[0] = $optionsitem
			DisableCurrentONOFF()
			Global $curr_defualt_profile = GUICtrlRead($Option_in_default)
			LoadSettings($config)
			GUISetState(@SW_DISABLE,$MainWin)
			GUISetState(@SW_SHOW,$OptionWin)
		Case $msg[0] = $b_Edit
			Interface_EditMacro_Load()
			$editflag = 1
			HotKeySet($runstop_hotkey)
			HotKeySet(_ConvertToHotKeyNotation(GUICtrlRead($Option_in_Record)),"Toggle_Record_Start_Stop")
			DisableCurrentONOFF()
			LoadEditorWindow()
			Interface_EditMacro_Load_Finish()
		Case $msg[0] = $b_Delete
			DeleteMacro($ini_file,_GUICtrlListGetText($macrolist,_GUICtrlListSelectedIndex($macrolist)))
			If _GUICtrlListCount($macrolist) = 0 Then
				GUICtrlSetState($b_run,$GUI_DISABLE)
			Else
				_GUICtrlListSelectIndex($macrolist,0)
			EndIf 
        Case $msg[0] = $b_OK
;~             Local $check = CheckMacroForErrors()
;~             If $check = "OK" Or $check = 6 Then
				GUISetState(@SW_HIDE,$DelayWin)
				_GUICtrlStatusBarSetText($statusbar2,"Saving macro...") 
				_DisableEditorControls()
                CreateMacro()
                LoadMacroList($ini_file)
                HotKeySet($runstop_hotkey,"Toggle_Run_Stop")
                If _GUICtrlListCount($macrolist) > 0 Then
                    _GUICtrlListSelectIndex($macrolist,$currentOpenMacroIndex)
                Else
                    GUICtrlSetState($b_run,$GUI_DISABLE)
                EndIf
				HotKeySet(_ConvertToHotKeyNotation(GUICtrlRead($Option_in_Record)))
				_GUICtrlStatusBarSetText($statusbar2,"Recordng stopped")
				_EnableEditorControls()				
;~             EndIf
		Case $msg[0] = $exititem
			Exit
		Case $msg[0] = $b_startRec
			$downlist = _ArrayCreate(-1)
			_HookKeyBoardMouseRecord($CeWin)
			StartRecording()
			_GUICtrlStatusBarSetText($statusbar2,"Recordng...") 
		Case $msg[0] = $b_stopRec
			StopRecording()
			_UnHookKeyBoardMouseRecord()
			_GUICtrlStatusBarSetText($statusbar2,"Recordng stopped") 
		Case $msg[0] = $b_DeleteItem
			DeleteEventItem()
		Case $msg[0] = $b_bindkey
			BindToKey()
		Case $msg[0] = $b_InsertOK
			InsertRecordedKey(_GUICtrlListSelectedIndex($Seqlist))
		Case $msg[0] = $b_InsertMouseOK
			InsertMouseEvent(_GUICtrlListSelectedIndex($Seqlist))
		Case $msg[0] = $b_InsertPixelOK
			InsertPixelEvent()
		Case $msg[0] = $b_GetPixelLocation
			GUICtrlSetState($b_GetPixelLocation,$GUI_DISABLE)
			GUISetState(@SW_MINIMIZE,$MainWin)
			GUISetState(@SW_HIDE,$PixelCheckWin)
			Sleep(10)
			While Not _IsPressed("01")
				ToolTip("Click a screen location")
				Sleep(50)
			WEnd
			While _IsPressed("01")
				ToolTip("Click a screen location")
				Sleep(50)
			WEnd
			Local $pos = MouseGetPos()
			GUICtrlSetState($b_GetPixelLocation,$GUI_ENABLE)
			GUICtrlSetData($in_PixelX,$pos[0])
			GUICtrlSetData($in_PixelY,$pos[1])
			GUICtrlSetData($in_PixelColor,Hex(PixelGetColor($pos[0],$pos[1]),6))
			GUICtrlSetBkColor($preview_color,"0x" & Hex(PixelGetColor($pos[0],$pos[1]),6))
			GUISetState(@SW_RESTORE,$MainWin)
			GUISetState(@SW_SHOW,$PixelCheckWin)
			ToolTip("")
		Case $msg[0] = $b_GetPixelColor
			Local $hex = Guictrlread($in_PixelColor)
			If StringIsXDigit(GUICtrlRead($in_PixelColor)) <> 1 Or StringLen(GUICtrlRead($in_PixelColor)) <> 6 Then
				MsgBox(0,"Invalid color entered","Please enter a 6 digit hex number for color" & @CRLF & "or use 'Pick Location' button to get the color")
			Else
				GUICtrlSetBkColor($preview_color,"0x" & $hex)
			EndIf
		Case $msg[0] = $PixelCheck_Move_ck
			If BitAND(GUICtrlRead($PixelCheck_Move_ck),$GUI_CHECKED) Then
				GUICtrlSetState($PixelCheck_Click_ck,$GUI_ENABLE)
				If BitAND(GUICtrlRead($PixelCheck_Click_ck),$GUI_CHECKED) Then
					GUICtrlSetState($r_l_mouse_pixel,$GUI_ENABLE)
					GUICtrlSetState($r_r_mouse_pixel,$GUI_ENABLE)
				Else
					GUICtrlSetState($r_l_mouse_pixel,$GUI_DISABLE)
					GUICtrlSetState($r_r_mouse_pixel,$GUI_DISABLE)
				EndIf
			Else
				GUICtrlSetState($PixelCheck_Click_ck,$GUI_DISABLE)
				GUICtrlSetState($r_l_mouse_pixel,$GUI_DISABLE)
				GUICtrlSetState($r_r_mouse_pixel,$GUI_DISABLE)
			EndIf
		Case $msg[0] = $PixelCheck_Click_ck
			If BitAND(GUICtrlRead($PixelCheck_Click_ck),$GUI_CHECKED) Then
				GUICtrlSetState($r_l_mouse_pixel,$GUI_ENABLE)
				GUICtrlSetState($r_r_mouse_pixel,$GUI_ENABLE)
			Else
				GUICtrlSetState($r_l_mouse_pixel,$GUI_DISABLE)
				GUICtrlSetState($r_r_mouse_pixel,$GUI_DISABLE)
			EndIf
		Case $msg[0] = $PixelCheck_Wait_ck
			If BitAND(GUICtrlRead($PixelCheck_Wait_ck),$GUI_CHECKED) Then
				GUICtrlSetState($PixelCheck_hex,$GUI_ENABLE)
				GUICtrlSetState($in_PixelColor,$GUI_ENABLE)
				GUICtrlSetState($b_GetPixelColor,$GUI_ENABLE)
			Else
				GUICtrlSetState($PixelCheck_hex,$GUI_DISABLE)
				GUICtrlSetState($in_PixelColor,$GUI_DISABLE)
				GUICtrlSetState($b_GetPixelColor,$GUI_DISABLE)
			EndIf
		Case $msg[0] = $m_InsertPixelCheck
			GUISetState(@SW_SHOW,$PixelCheckWin)
			GUISetState(@SW_DISABLE,$CeWin)
		Case $msg[0] = $b_InsertPixelCancel
			GUISetState(@SW_HIDE,$PixelCheckWin)
			GUISetState(@SW_ENABLE,$CeWin)
			GUISetState(@SW_RESTORE,$CeWin)
		Case $msg[0] = $m_InsertMouseEvent
			GUISetState(@SW_SHOW,$MouseWin)
			GUISetState(@SW_DISABLE,$CeWin)
			GuiCtrlSetState($r_l_mouse, $GUI_CHECKED)
		Case $msg[0] = $b_InsertCancel
			GUISetState(@SW_HIDE,$KeyUpDownWin)
			GUISetState(@SW_ENABLE,$CeWin)
			GUISetState(@SW_RESTORE,$CeWin)
		Case $msg[0] = $b_InsertMouseCancel
			GUISetState(@SW_HIDE,$MouseWin)
			GUISetState(@SW_ENABLE,$CeWin)
			GUISetState(@SW_RESTORE,$CeWin)
		Case $msg[0] = $b_InsertRecord
			RecordInsert()
		Case $msg[0] = $b_MoveUp
			MoveListItem("up",_GUICtrlListSelectedIndex($Seqlist))
		Case $msg[0] = $b_MoveDown
			MoveListItem("down",_GUICtrlListSelectedIndex($Seqlist))
		Case $msg[0] = $b_Insert
			ShowMenu($CeWin, $msg, $InsertContext)
		Case $msg[0] = $m_InsertKeyUpDown
			GUISetState(@SW_SHOW,$KeyUpDownWin)
			GUISetState(@SW_DISABLE,$CeWin)
			GuiCtrlSetState($r_keypress, $GUI_CHECKED)
		Case $msg[0] = $m_InsertDelay
			GUISetState(@SW_SHOW,$DelayWin)
			GUICtrlSetData($delay_decimal_input,"05")
			GUICtrlSetData($delay_digit_input,"0")
		Case $msg[0] = $b_InsertDelayOK
			InsertDelay(_GUICtrlListSelectedIndex($Seqlist))
		Case $msg[0] = $b_InsertDelayCancel
			GUISetState(@SW_HIDE,$DelayWin)
		Case $msg[0] = $b_up
			ModifyDelay("up")
		Case $msg[0] = $b_down
			ModifyDelay("down")
		Case $msg[0] = $b_run
			AppRun()
		Case $msg[0] = $b_stop
			AppStop()
		Case $msg[0] = $c_mouseclickrecord
			If BitAND(GUICtrlRead($c_mouseclickrecord),$GUI_CHECKED) Then
				GUICtrlSetState($c_mouseclickposrecord,$GUI_ENABLE)
				GUICtrlSetState($c_mouseclickposrecord,$GUI_CHECKED)
			Else
				GUICtrlSetState($c_mouseclickposrecord,$GUI_DISABLE)
				GUICtrlSetState($c_mouseclickposrecord,$GUI_UNCHECKED)
			EndIf
		Case $msg[0] = $r_mtype1
			GUICtrlSetState($repeat_input,$GUI_DISABLE)
			GUICtrlSetData($repeat_input,"")
		Case $msg[0] = $r_mtype2
			GUICtrlSetState($repeat_input,$GUI_ENABLE)
			GUICtrlSetData($repeat_input,"2")
		Case $msg[0] = $r_mtype3
			GUICtrlSetState($repeat_input,$GUI_DISABLE)
			GUICtrlSetData($repeat_input,"")
		Case $msg[0] = $Seqlist
			If StringRight(_GUICtrlListGetText($Seqlist,_GUICtrlListSelectedIndex($Seqlist)),5) = "Delay" Then
				GUICtrlSetState($in_delay,$GUI_ENABLE)
				GUICtrlSetState($b_up,$GUI_ENABLE)
				GUICtrlSetState($b_down,$GUI_ENABLE)
				GUICtrlSetData($in_delay,StringTrimRight(_GUICtrlListGetText($Seqlist,_GUICtrlListSelectedIndex($Seqlist)),6))
			Else
				GUICtrlSetState($b_up,$GUI_DISABLE)
				GUICtrlSetState($b_down,$GUI_DISABLE)
				GUICtrlSetState($in_delay,$GUI_DISABLE)
				GUICtrlSetData($in_delay,"") ;If its not a number then display nothing
			EndIf
		Case $msg[0] = $repeat_input
			If Guictrlread($repeat_input) < 2 Then ;Lowest value of repeat updown is 1
				GUICtrlSetData($repeat_input,"2")
			EndIf
		Case $msg[0] = $in_delay
			ModifyDelay()
	EndSelect
WEnd
;===================================
;===================================
;=========== Functions =============
;===================================
;===================================
;=============================================================================
; Waits for pixel to change to a certain color. 
;=============================================================================
Func WaitOnPixel($x,$y,$color)
	Local $intversion = Int($color)
	While PixelGetColor($x,$y) <> $intversion
		$msg = GUIGetMsg(1)
		If $msg[0] = $b_stop Then AppStop()
		If $paused = 1  Then ExitLoop
	WEnd
EndFunc
;=============================================================================
; Inserts a pixel event into the event list
; The user can make the macro pause until a certain pixel on the screen
; changes to a specified color.
; The user can also allow the mouse cursor to click on that pixel after it
; changes.
;=============================================================================
Func InsertPixelEvent()
	Local $move = BitAND(GUICtrlRead($PixelCheck_Move_ck),$GUI_CHECKED) 
	Local $wait = BitAND(GUICtrlRead($PixelCheck_Wait_ck),$GUI_CHECKED)
	Local $click = BitAND(GUICtrlRead($PixelCheck_Click_ck),$GUI_CHECKED)
	Local $left = BitAND(Guictrlread($r_l_mouse_pixel),$GUI_CHECKED)
	If $move + $wait = 0 Then ;neither are checked
		MsgBox(0,"No event selected","Please choose an event")
	ElseIf StringIsXDigit(GUICtrlRead($in_PixelColor)) <> 1 Or StringLen(GUICtrlRead($in_PixelColor)) <> 6 Then
		MsgBox(0,"Invalid color entered","Please enter a 6 digit hex number for color" & @CRLF & "or use 'Pick Location' button to get the color")
	Else
		Local $insertValue = "<Wait  ("& GUICtrlRead($in_PixelX) &","& GUICtrlRead($in_PixelY) &")  " & GUICtrlRead($in_PixelColor) & ">"
		If $move = 1 Then
			If $click = 1 Then
				If $left = 1 Then
					If $wait Then
						InsertEntry($insertValue,_GUICtrlListSelectedIndex($Seqlist))
					EndIf
					InsertEntry("{LMouse}  Hold  ("& GUICtrlRead($in_PixelX) &","& GUICtrlRead($in_PixelY) &")",_GUICtrlListSelectedIndex($Seqlist))
					InsertEntry("0.05  Delay",_GUICtrlListSelectedIndex($Seqlist))
					InsertEntry("{LMouse}  Release  ("& GUICtrlRead($in_PixelX) &","& GUICtrlRead($in_PixelY) &")",_GUICtrlListSelectedIndex($Seqlist))
				Else
					If $wait Then
						InsertEntry($insertValue,_GUICtrlListSelectedIndex($Seqlist))
					EndIf
					InsertEntry("{RMouse}  Hold  ("& GUICtrlRead($in_PixelX) &","& GUICtrlRead($in_PixelY) &")",_GUICtrlListSelectedIndex($Seqlist))
					InsertEntry("0.05  Delay",_GUICtrlListSelectedIndex($Seqlist))
					InsertEntry("{RMouse}  Release  ("& GUICtrlRead($in_PixelX) &","& GUICtrlRead($in_PixelY) &")",_GUICtrlListSelectedIndex($Seqlist))	
				EndIf
			Else
				If $wait Then
					InsertEntry($insertValue,_GUICtrlListSelectedIndex($Seqlist))
				EndIf
				InsertEntry("Move  ("& GUICtrlRead($in_PixelX) &","& GUICtrlRead($in_PixelY) &")",_GUICtrlListSelectedIndex($Seqlist))	
			Endif
		Else
			InsertEntry($insertValue,_GUICtrlListSelectedIndex($Seqlist))
		EndIf
		GUISetState(@SW_HIDE,$PixelCheckWin)
		GUISetState(@SW_ENABLE,$CeWin)
		GUISetState(@SW_RESTORE,$CeWin)
	EndIf
EndFunc
;=============================================================================
; Notifys the user that a "key down" event does not have a matching "key up" event
; A warning message is displayed with the key events that dont have matching events
;=============================================================================
Func CheckMacroForErrors()
    Local $KeyDownList = _ArrayCreate(-1)
    Local $EventList = EventListToArray()
    For $i = 1 To UBound($EventList) - 1 ;For each event in the macro
        If StringRight($EventList[$i],4) = "Hold" Then ;Store all Hold events in array list
            If _ArraySearch($KeyDownList,$EventList[$i],1) > -1 Then
                ExitLoop ;If key down is already in array then exit
            Else
                _ArrayAdd($KeyDownList,$EventList[$i])
            EndIf
        ElseIf StringRight($EventList[$i],7) = "Release" Then ;If a release event then compare with Hold array list
            Local $index_found = _ArraySearch($KeyDownList,StringReplace($EventList[$i],"Release","Hold"))
            If $index_found > - 1 Then ;If found the romove from stack
                _ArrayDelete($KeyDownList,$index_found)
            EndIf
        EndIf
    Next
    If UBound($KeyDownList) > 1 Then ;If any Hold events remain then there is an unbalance of key presses
        Local $keysdownSTR = "List of unbalanced Hold keys" & @CRLF & "----------------" & @CRLF
        Local $reason = "Do you want to continue saving?"
        For $i = 1 To UBound($KeyDownList) - 1
            $keysdownSTR &= $KeyDownList[$i] & @CRLF
        Next
        Local $yes_or_no = MsgBox(4,"Warning","One or more of the key Hold events do " & @CRLF & "not have a matching key Release event." & @CRLF & @CRLF & $keysdownSTR & "----------------" & @CRLF & @CRLF & $reason)
        Return $yes_or_no ;If = 6 then YES button is clicked, else NO was clicked
    EndIf
    Return "OK" ;No errors found
EndFunc ;CheckMacroForErrors()==>
;=============================================================================
; If a key is in a pressed down state, then clear it before recording
; This is a rare case.
;=============================================================================
Func _ClearKeyboardCache()
	for $i = 8 to 222
		If _IsPressed(hex($i,2)) Then
			Local $key = $keyboardLayout[$i]
			If StringInStr($keyboardLayout[$i],"{") = 1 Then
				Send(StringReplace($keyboardLayout[$i],"}"," up}"))
			Else
				Send($keyboardLayout[$i])
			EndIf
		EndIf
	Next
	If _IsPressed(1) Then 
		MouseDown("left")
		MouseUp("left")
	EndIf
	If _IsPressed(2) Then 
		MouseDown("right")
		MouseUp("right")
	EndIf
	If IsDeclared("$hhKey") Then
		DLLCall("user32.dll","int","UnhookWindowsHookEx","hwnd",$hhKey[0])
		DLLCall("kernel32.dll","int","FreeLibrary","hwnd",$DLLinst[0])
	EndIf
EndFunc ;_ClearKeyboardCache()==>
;=============================================================================
; Displays a message box displaying a message to user that a newer version
; of the application is available
;=============================================================================
Func _CheckForUpdate($version,$location,$tempsave)
	Local $updateCheck = _INetGetSource($location)
	If @error <> 1 Then
		If StringReplace($version,".","") < StringReplace($updateCheck,".","") Then 
			MsgBox(4096, "Update Found", "Version " & $updateCheck & " " & @CRLF & "Download it at www.itoady.com", 10)
		Else
			MsgBox(4096, "No Newer Versions", "Current version is already installed", 10)    
		EndIf
	Else
		MsgBox(0,"Update","Visit http://www.itoady.com for updates")
	EndIf
EndFunc ;_CheckForUpdate()==>
;=============================================================================
; Displays a message box containing all the macros and their keybinds
;=============================================================================
Func OnClick_ViewKeyBinds()
	_GUICtrlListViewSetColumnWidth($listview,0,$KeybindsW-100)
	_GUICtrlListViewSetColumnWidth($listview,1,75)
	_GUICtrlListViewDeleteAllItems($listview)
	GUICtrlSetData($profile_keybind_label,_Str_ExtractFileName($ini_file))
	GUICtrlCreateListViewItem("Run/Stop" & "|" & GUICtrlRead($Option_in_ONOFF),$listview)
	GUICtrlCreateListViewItem("Start/Stop Recording" & "|" & GUICtrlRead($Option_in_Record),$listview)
	Local $ini = ""
	For $i = 0 To _GUICtrlListCount($macrolist) - 1 ;Add each macro name and its key bind to listview
		$ini = IniReadSection($ini_file,_GUICtrlListGetText($macrolist,$i)) 
		If IsArray($ini) Then
			If $ini[1][1] <> "No Key" Then ;Different listview add display if macro has no bind
				GUICtrlCreateListViewItem(_GUICtrlListGetText($macrolist,$i) & "|" & StringReplace($ini[1][1]," Key",""),$listview)
			Else
				GUICtrlCreateListViewItem(_GUICtrlListGetText($macrolist,$i) & "|" & $ini[1][1],$listview)
			EndIf
		EndIf
	Next
	If _GUICtrlListViewGetItemCount($listview) > 9 Then  ;adjust headers for scrollbars
		_GUICtrlListViewSetColumnWidth($listview,0,$KeybindsW-116)
	EndIf
EndFunc ;OnClick_ViewKeyBinds()==>
;=============================================================================
; Displays an open dialog box allowing user to open a existing profile
;=============================================================================
Func OnClick_LoadProfile()
	Local $default_profile_path = FileOpenDialog("Find MacroGamer Profile...",@ScriptDir,"MacroGamer Profile (*.mgp)")
	If $default_profile_path <> "" And StringRight($default_profile_path,4) =".mgp" Then
		If FileExists($default_profile_path) Then
			LoadMacroList($default_profile_path)
			$ini_file = $default_profile_path
		EndIf
	EndIf
EndFunc ;OnClick_LoadProfile()==>
;=============================================================================
; Displays a save dialog box allowing user to create a new profile
;=============================================================================
Func OnClick_NewProfile()
	Local $new_profile_path = FileSaveDialog( "Choose a name.", @ScriptDir, "MacroGamer Profile (*.mgp)", 2,"new_profile.mgp")
	If $new_profile_path <> "" Then
		If FileExists($new_profile_path) Then
			MsgBox(1,"Error","File already exists!" & @LF & "Choose a different name")
			OnClick_NewProfile()
		Else
			FileClose(FileOpen($new_profile_path, 2))
			LoadMacroList($new_profile_path)
			$ini_file = $new_profile_path
		EndIf
	EndIf
EndFunc ;OnClick_NewProfile()==>
;=============================================================================
; Toggles the application recording start and stop
;=============================================================================
Func Toggle_Record_Start_Stop()
	Opt("WinSearchChildren",1)
	If BitAND(WinGetState("Macro Editor", ""),4) Then
		HotKeySet(_ConvertToHotKeyNotation(GUICtrlRead($Option_in_Record)))
		If GUICtrlGetState($b_stopRec) = 80 Then ;enabled
			StopRecording()
			_UnHookKeyBoardMouseRecord()
			If $DisplayNotifyRecord = 1 Then ;Play a sound
				SoundPlay(@ScriptDir & "\RecordingStopped.wav")
			EndIf
			SLeep(100) ;give some time for macros to load
		ElseIf GUICtrlGetState($b_startRec) = 80 Then
			$downlist = _ArrayCreate(-1)
			_HookKeyBoardMouseRecord($CeWin)
			StartRecording()
			If $DisplayNotifyRecord = 1 Then
				SoundPlay(@ScriptDir & "\RecordingStarted.wav")
			EndIf
			SLeep(100) ;give some time for macros to load
		Endif
		HotKeySet(_ConvertToHotKeyNotation(GUICtrlRead($Option_in_Record)),"Toggle_Record_Start_Stop")
	EndIf
	Opt("WinSearchChildren",0)
EndFunc ;Toggle_Run_Stop()==>
;=============================================================================
; Toggles the application macros on and off
;=============================================================================
Func Toggle_Run_Stop()
	If BitAND(WinGetState($App_Name, ""),4) Then ;Only toggle if Main Window is active, not other child gui's are active
		HotKeySet($runstop_hotkey)
		If _GUICtrlListCount($macrolist) > 0 Then ;Only toggle if macros exist
			$Paused = Not $Paused
			If $Paused = 1 Then
				AppStop() ;Disable all keybinds
				If $DisplayNotify = 1 Then ;Play a sound
					SoundPlay(@ScriptDir & "\MacrosDisabled.wav")
				EndIf
				SLeep(200) ;give some time for macros to load
				for $i = 8 to 222 ;addstop must be called before this loop
					If _IsPressed(hex($i,2)) Then
						Send($keyboardLayout[$i])
					EndIf
				Next
				HotKeySet($runstop_hotkey,"Toggle_Run_Stop")
			ElseIf $Paused = 0 Then
				AppRun() ;Parce through macros and set keybinds
				HotKeySet($runstop_hotkey)
				If $DisplayNotify = 1 Then
					SoundPlay(@ScriptDir & "\MacrosEnabled.wav")
				EndIf
				SLeep(200) ;give some time for macros to load
			Endif
		EndIf
		HotKeySet($runstop_hotkey,"Toggle_Run_Stop") ;Keep macros toggle from being spammed
	EndIf
EndFunc ;Toggle_Run_Stop()==>
;=============================================================================
; Saves the settings in the config file
;=============================================================================
Func Onclick_SaveSettings()
	Local $delay_val
	HotKeySet($runstop_hotkey)
	IniWrite($config, "settings", "default", GUICtrlRead($Option_in_default))
	IniWrite($config, "settings", "togglekey", GUICtrlRead($Option_in_ONOFF))
	IniWrite($config, "settings", "notifytoggle", BitAND(GUICtrlRead($Option_ck_Notify),$GUI_CHECKED))
	IniWrite($config, "settings", "togglekeyrecord", GUICtrlRead($Option_in_Record))
	IniWrite($config, "settings", "notifytogglerecord", BitAND(GUICtrlRead($Option_ck_Record_Notify),$GUI_CHECKED))
	HotKeySet(_ConvertToHotKeyNotation(GUICtrlRead($Option_in_ONOFF)),"Toggle_Run_Stop")
	If $curr_defualt_profile <> GUICtrlRead($Option_in_default) Then
		$ini_file = GUICtrlRead($Option_in_default)
	EndIf
	$DisplayNotifyRecord = BitAND(GUICtrlRead($Option_ck_Record_Notify),$GUI_CHECKED)
	$DisplayNotify = BitAND(GUICtrlRead($Option_ck_Notify),$GUI_CHECKED)
	LoadMacroList($ini_file)
	$runstop_hotkey = _ConvertToHotKeyNotation(GUICtrlRead($Option_in_ONOFF))
	$DisplayNotify = BitAND(GUICtrlRead($Option_ck_Notify),$GUI_CHECKED)
EndFunc ;Onclick_SaveSettings()==>
;=============================================================================
; Enable ON/OFF Hotkey
;=============================================================================
Func EnabledCurrentONOFF()
	HotKeySet($runstop_hotkey,"Toggle_Run_Stop")
EndFunc ; EnabledCurrentONOFF()==>
;=============================================================================
; Disable ON/OFF Hotkey
;=============================================================================
Func DisableCurrentONOFF()
	HotKeySet($runstop_hotkey)
EndFunc ;DisableCurrentONOFF()==>
;=============================================================================
; Opens dialog box letting user find and select the defaul profile to use
;=============================================================================
Func SetDefaultProfile()
	Local $default_profile_path = FileOpenDialog("Find MacroGamer Profile...",@ScriptDir,"All (*.mgp)")
	If $default_profile_path <> "" Then
		If FileExists($default_profile_path) Then
			GUICtrlSetData($Option_in_default,$default_profile_path)
		EndIf
	EndIf
EndFunc ;SetDefaultProfile()==>
;=============================================================================
; Sets all the settings back to original values
; NOTE: Not used, maybe in later versions
;=============================================================================
Func ResetToDefaults()
	GUICtrlSetData($Option_in_ONOFF,"{F3}")
	GUICtrlSetState($Option_ck_Notify,$GUI_CHECKED)
	HotKeySet(GUICtrlRead($Option_in_ONOFF),"Toggle_Run_Stop")
EndFunc ;ResetToDefaults()==>
;=============================================================================
; Loads in settings from config file and sets appropriate variables
;=============================================================================
Func LoadSettings($config)
	Local $ini = IniReadSection($config,"settings")
	If $first_time_ran = 1 Then
		If $ini[1][1] <> "" Then
			$ini_file = $ini[1][1] ;type string
			GUICtrlSetData($Option_in_default,$ini_file)
		Else ;Below line only ran on first installation
			$ini_file = @ScriptDir & "\profile.mgp" ;type string
		EndIf
	EndIf
	$runstop_hotkey = $ini[2][1] ;type string
	$DisplayNotify = $ini[3][1] ;type boolean
	$DisplayNotifyRecord = $ini[5][1]
	GUICtrlSetData($Option_in_ONOFF,$runstop_hotkey)
	GUICtrlSetState($Option_ck_Notify,$DisplayNotify)
	GUICtrlSetData($Option_in_Record,$ini[4][1])
	GUICtrlSetState($Option_ck_Record_Notify,$DisplayNotifyRecord)
	HotKeySet(_ConvertToHotKeyNotation(GUICtrlRead($Option_in_ONOFF)),"Toggle_Run_Stop")
EndFunc ;LoadSettings($config)==>
;=============================================================================
; Reads the keyboard layout file OMFG! WTF! HAX! 102 standard keyboard
; Using an external INI file in case scancodes not compatible with keyboard
; This allows updates to scancodes to be simple, even user can modify it.
;=============================================================================
Func LoadKeyBoardLayout($file)
	Local $ini = IniReadSection($file,"keyboard")
	Global $keyboardLayout = _ArrayCreate($ini[1][1])
	For $i = 2 To $ini[0][0]
		_ArrayAdd($keyboardLayout,$ini[$i][1])
	Next
EndFunc ;LoadKeyBoardLayout($file)==>
;=============================================================================
; If a macro is long it will take a short period of time to load macro into
; editor window. 
;=============================================================================
Func Interface_EditMacro_Load()
	_GUICtrlStatusBarSetText($statusbar,"Loading macro...") 
	GUICtrlSetState($b_run,$GUI_DISABLE) ;Disable all controls while loading
	GUICtrlSetState($macrolist,$GUI_DISABLE)
	GUICtrlSetState($b_stop,$GUI_ENABLE)
	GUICtrlSetState($b_new,$GUI_DISABLE)
	GUICtrlSetState($b_edit,$GUI_DISABLE)
	GUICtrlSetState($b_delete,$GUI_DISABLE)
	GUICtrlSetState($optionsitem,$GUI_DISABLE)
	GUICtrlSetState($newitem,$GUI_DISABLE)
	GUICtrlSetState($fileitem,$GUI_DISABLE)
	GUICtrlSetState($b_run,$GUI_DISABLE)
	GUICtrlSetState($b_stop,$GUI_DISABLE) ;^^
EndFunc ;Interface_EditMacro_Load()==>
;=============================================================================
; If a macro is long it will take a short period of time to load macro into
; editor window. This gets called after macro is loaded into editor window.
;=============================================================================
Func Interface_EditMacro_Load_Finish()
	_GUICtrlStatusBarSetText($statusbar,"Stopped") 
	GUICtrlSetState($b_run,$GUI_ENABLE) ;Disable all controls while loading
	GUICtrlSetState($macrolist,$GUI_ENABLE)
	GUICtrlSetState($b_new,$GUI_ENABLE)
	GUICtrlSetState($b_edit,$GUI_ENABLE)
	GUICtrlSetState($b_delete,$GUI_ENABLE)
	GUICtrlSetState($optionsitem,$GUI_ENABLE)
	GUICtrlSetState($newitem,$GUI_ENABLE)
	GUICtrlSetState($fileitem,$GUI_ENABLE)
	GUICtrlSetState($b_run,$GUI_ENABLE)
EndFunc ;Interface_EditMacro_Load_Finish()==>
;=============================================================================
; Takes each macro out of the profile file and stores each into memory.
; Each macro in memory is inserted into an index lookup table.
; The index table is used to quickly return the location of the stored macro.
; Three tables are used to make this work.
;	Table 1: Index table (keybind1,keybind2,keybind3...,keybind64) 
;   Table 2: Macro object (event1,event2,..,eventN)
;   Table 3: Macros table (macro object1,...,macro objectN)
;=============================================================================
Func AppRun()
	If @Compiled Then
		ProcessSetPriority(@ScriptName, 4)
	Else
		ProcessSetPriority("AutoIt3.exe", 4) ;testing purposes
	EndIf
	HotKeySet($runstop_hotkey) ;Keep macros toggle from being spammed
	$paused = 0
	_GUICtrlStatusBarSetText($statusbar,"Loading macros...") ;used if macro objects are large
	GUICtrlSetState($b_run,$GUI_DISABLE) ;Disable all controls while loading
	GUICtrlSetState($macrolist,$GUI_DISABLE)
	GUICtrlSetState($b_stop,$GUI_ENABLE)
	GUICtrlSetState($b_new,$GUI_DISABLE)
	GUICtrlSetState($b_edit,$GUI_DISABLE)
	GUICtrlSetState($b_delete,$GUI_DISABLE)
	GUICtrlSetState($optionsitem,$GUI_DISABLE)
	GUICtrlSetState($newitem,$GUI_DISABLE)
	GUICtrlSetState($fileitem,$GUI_DISABLE)
	GUICtrlSetState($b_stop,$GUI_DISABLE) ;^^
	Global $MacrosArr = _ArrayCreate(-1) ;OMFGHAX!!
	$MacroIndex = _ArrayCreate(-1) ;Macro Index
	For $j = 0 To _GUICtrlListCount($macrolist) - 1 ;For each of the macros
		Local $IniSection = IniReadSection($ini_file,_GUICtrlListGetText($macrolist,$j))
		If IsArray($IniSection) Then ;If its an actual macro
			Local $keybind = StringLower($IniSection[1][1]) ;Get the keybinds and all each to index array
			If $keybind <> "No Key" Then ;if its not supposed to be binded then dont bind it!!!
				_ArrayAdd($MacroIndex,_ConvertToHotKeyNotation($keybind)) ;Add keybind to macro indexing list
				Local $aMacroOBJ = _ArrayCreate($IniSection[2][1]) ;Create a Macro Object
				Local $mytime = TimerInit()
				For $i = 3 To $IniSection[0][0] ;For all the events in current macro read
					_ArrayAdd($aMacroOBJ,$IniSection[$i][1]) ;Add macro events to MacroOBJ
				Next
				_ArrayAdd($MacrosArr,$aMacroOBJ) ;Add Macro object to MacroArrayList
			EndIf
		EndIf
	Next
	_GUICtrlStatusBarSetText($statusbar,"Running",0)
	GUICtrlSetState($b_stop,$GUI_ENABLE)
	HotKeyMacroIndexes()
	HotKeySet($runstop_hotkey,"Toggle_Run_Stop") ;Keep macros toggle from being spammed
EndFunc ;AppRun()==>
;=============================================================================
; Parces through each of the macro objects and disables the corresponding
; hotkey.
;=============================================================================
Func AppStop()
	If @Compiled Then
		ProcessSetPriority(@ScriptName, 2)
	Else
		ProcessSetPriority("AutoIt3.exe", 2) ;testing purposes
	EndIf
	If IsArray($MacroIndex) Then ;Only if there are keybinds
		For $i = 1 To UBound($MacroIndex) - 1
			HotKeySet($MacroIndex[$i]) ;Disable each hotkey
		Next
	EndIf
	$paused = 1
	GUICtrlSetState($b_stop,$GUI_DISABLE)
	GUICtrlSetState($b_run,$GUI_ENABLE)
	GUICtrlSetState($b_new,$GUI_ENABLE)
	GUICtrlSetState($macrolist,$GUI_ENABLE)
	GUICtrlSetState($optionsitem,$GUI_ENABLE)
	GUICtrlSetState($newitem,$GUI_ENABLE)
	GUICtrlSetState($fileitem,$GUI_ENABLE)
	If _GUICtrlListCount($macrolist) > 0 Then ;If macros exist then show edit and delete
		GUICtrlSetState($b_edit,$GUI_ENABLE)
		GUICtrlSetState($b_delete,$GUI_ENABLE)
	EndIf
	_GUICtrlStatusBarSetText($statusbar,"Stopped",0)
EndFunc ;AppStop()==>
;=============================================================================
; Loads the Global MacroIndex table with macro keybinds
; Allows quick return of the macro objects from the MacroArr table
;    MacroIndex table              MacroArr table
;     Index | Key                   Index | MacroOBJ
;         0 | Null                      0 | Null
;         1 | h                         1 | [{key down},25 Delay,{key up}]
;         2 | {numpad6} ------------->  2 | [{key down},{key up},400 Delay]
;         3 | {F3}                      3 | [{Lmouse down},{Lmouse up}]
; If hotkey pressed, this indexing table is searched for a matching Key.
; If found then the index is matched with MacroArr table since they both have a 
; 1 to 1 relationship between them.
;=============================================================================
Func LoadMacroIndexes()
	$MacroIndex = _ArrayCreate(-1) ;Macro Index
	For $j = 0 To _GUICtrlListCount($macrolist) - 1 ;For each of the macros
		Local $IniSection = IniReadSection($ini_file,_GUICtrlListGetText($macrolist,$j))
		If IsArray($IniSection) Then ;If its an actual macro
			Local $keybind = StringLower($IniSection[1][1]) ;Get the keybinds and all each to index array
			If $keybind <> "No Key" Then ;if its not supposed to be binded then dont bind it!!!
				_ArrayAdd($MacroIndex,_ConvertToHotKeyNotation($keybind)) ;Add keybind to macro indexing list
			EndIf
		EndIf
	Next
EndFunc
;=============================================================================
; HotKeys all objects with Playmacro
;=============================================================================
Func HotKeyMacroIndexes()
	For $i = 1 To UBound($MacroIndex) - 1
		HotKeySet($MacroIndex[$i],"PlayMacro")
	Next
EndFunc
;=============================================================================
; When a hotkey is pressed this function is called. The key pressed is searched
; in the index lookup table. The index of the macro object is returned.
; Once macro object is returned, that macro object is then read one-by-one And
; sent as an input or sent as a time delay to the current active window.
;
; Each macro's hotkey is disabled while playing macro to prevent recursive problems
; Mouse support is included and is optimized for speed by using short String
; descriptions and executing the middle mouse keys last.
;
; The active playing macro's key is disabled while the macro is playing, therefor
; the key can be held down and the macro will repeat itself
;
; BlockInput() is only used if the macro being played contains a key that is assigned
; as a keybind.
; At anytime the playing macro can be stopped if user presses ON/OFF hotkey
;=============================================================================
Func PlayMacro()
	Global $currentBindPlay = @HotKeyPressed
	HotKeySet($currentBindPlay,"MakeKeyDoNothing") ;make keybind key do nothing
	$b_runstop_used = 0
	For $i = 1 To UBound($MacroIndex) - 1 ;For each item in macro index
		If $MacroIndex[$i] = $currentBindPlay Then ;If its the key pressed
			$macroOBJ = $MacrosArr[$i] ;Copy macro object from macro list to single entity
		Else
			HotKeySet($MacroIndex[$i]) ;Disable all other hotkeys
		EndIf
	Next
	For $i = 1 To $macroOBJ[0] ;The number of time to repeat macro
		For $j = 1 To UBound($macroOBJ) - 1 ;For each event in the macro object
			Select
			Case $paused = 1 ;stop macro completly if user toggles run stop hotkey
					ExitLoop
			Case StringRegExp($macroOBJ[$j],"( D)") ;If its an Delay then sleep a while
				_MySleep(StringRegExpReplace($macroOBJ[$j],"( D)",""))
			Case IsCurrentHotKey($macroOBJ[$j]) ;Only triggered if macro event key is same as macro bind key
				    BlockInput(1) ;Prevent the default key from playing if key is held down
					HotKeySet($currentBindPlay) ;play normal key
					Send($macroOBJ[$j]) ;Send the refurbished run stop hotkey without it doing its cause
					BlockInput(0)
					HotKeySet($currentBindPlay,"MakeKeyDoNothing") 
			Case IsRunStopHotkey($macroOBJ[$j]) ;If macro event is the run stop hotkey then disable runstop
					BlockInput(1) ;Prevent the default key from playing if key is held down
					HotKeySet($runstop_hotkey)
					Send($macroOBJ[$j]) ;Send the refurbished run stop hotkey without it doing its cause
					BlockInput(0)
					HotKeySet($runstop_hotkey,"Toggle_Run_Stop")
			Case StringRegExp($macroOBJ[$j],"(Mou)|(M )") ; If its a mouse event
				Local $EventOBJ = StringSplit(StringRegExpReplace($macroOBJ[$j],"  "," ")," ")
				If StringRegExp($macroOBJ[$j],"[)]") <> 1 Then ;not a move
					If StringRegExp($macroOBJ[$j],"(down)") Then ;down
						If StringRegExp($macroOBJ[$j],"(LM)") Then ;middlemouse down
							MouseDown("left")
						Elseif StringRegExp($macroOBJ[$j],"(RM)") Then ;rightmouse down
							MouseDown("right")
						Else ;MiddleMouse down
							MouseDown("middle")
						EndIf
					Else ;up 
						If StringRegExp($macroOBJ[$j],"(up)") Then ;up
							If StringRegExp($macroOBJ[$j],"(LM)") Then ;middlemouse up
								MouseUp("left")
							Elseif StringRegExp($macroOBJ[$j],"(RM)") Then ;rightmouse up
								MouseUp("right")
							Else ;MiddleMouse up
								MouseUp("middle")
							EndIf
						EndIf
					EndIf
				Else ;mouse movement coords
					If $EventOBJ[0] = 2 And StringRegExp($macroOBJ[$j],"(M )") Then
						_MouseMoveCursor($EventOBJ[2])
					ElseIf $EventOBJ[0] = 3 Then
						_MouseMoveCursor($EventOBJ[3])
					EndIf
					If StringRegExp($macroOBJ[$j],"(down)") Then ;down
						If StringRegExp($macroOBJ[$j],"(LM)") Then ;middlemouse down
							MouseDown("left")
						Elseif StringRegExp($macroOBJ[$j],"(RM)") Then ;rightmouse down
							MouseDown("right")
						Else ;MiddleMouse down
							MouseDown("middle")
						EndIf
					Else ;up 
						If StringRegExp($macroOBJ[$j],"(up)") Then ;up
							If StringRegExp($macroOBJ[$j],"(LM)") Then ;middlemouse up
								MouseUp("left")
							Elseif StringRegExp($macroOBJ[$j],"(RM)") Then ;rightmouse up
								MouseUp("right")
							Else ;MiddleMouse up
								MouseUp("middle")
							EndIf
						EndIf
					EndIf
				EndIf
			Case StringRegExp($macroOBJ[$j],"(wd)|(wu)")
				If $macroOBJ[$j] = "wd" Then
					MouseWheel("down",1)
				Else
					MouseWheel("up",1)
				EndIf
			Case StringRegExp($macroOBJ[$j],"[<]") ;wait state
				Local $waitOBJ = StringSplit(StringRegExpReplace($macroOBJ[$j],"(  )","|"),"|")
				Local $pos = StringSplit(StringRegExpReplace($waitOBJ[2],"[()]",""),",")
				Local $color = "0x" & StringRegExpReplace($waitOBJ[3],"[>]","")
				WaitOnPixel($pos[1],$pos[2],$color)
			Case Else
				Send($macroOBJ[$j]) ;Send key
			EndSelect
		Next
		If $paused = 1 Then ExitLoop ;Stop macro completely
	Next
	BlockInput(0) ;Insure keys are not blocked
	If $paused = 0 Then ;If RunStop hotkey not been pressed
		For $k = 1 To UBound($MacroIndex) - 1	;Enable keybind back to normal
			HotKeySet($MacroIndex[$k],"PlayMacro")
		Next
	EndIf
EndFunc ;PlayMacro()==>
;=============================================================================
; Moves the mouse to a specified cordinate
;=============================================================================
Func _MouseMoveCursor($coord)
	Local $pos = StringSplit(StringRegExpReplace($coord,"[()]",""),",")
	_MoveMouse($pos[1],$pos[2])
EndFunc
;=============================================================================
; A custom sleep to handle delays within macro.
; This is needed to continuosly check if MacroGamer has stopped running macro
; This prevents the GUI from being inactive after stopping macro with a long delay
;=============================================================================
Func _MySleep($time)
	If $time < 1000 Then ; less than 1 second (common delay is small)
		Sleep($time)
		Return
	Else
;~ 		Local $n = ($time - Mod($time,1000))/250 ;loop every 1/4 second and sleep
;~ 		Sleep(Mod($time,1000))
;~ 		For $i = 1 To $n
;~ 			Sleep(250)
;~ 			If $paused = 1 Then Return ;stop if stop hotkey pressed
;~ 		Next
;~ 	EndIf
		Local $timer = TimerInit()
		While TimerDiff($timer) < $time
			$msg = GUIGetMsg(1)
			If $msg[0] = $b_stop Then 
				AppStop()
				ExitLoop
			EndIf
			If $paused = 1  Then ExitLoop
		WEnd
	EndIf
EndFunc
;=============================================================================
; Stops a key's normal function
;=============================================================================
Func MakeKeyDoNothing()
EndFunc ;MakeKeyDoNothing()==>
;=============================================================================
; Determines if a macro event is the current bind being played
;=============================================================================
Func IsCurrentHotKey($key) ;Regular expressions included in next version
	If StringLower(StringRegExpReplace($currentBindPlay,"[{}]","")) = StringRegExpReplace($key,"( down)|( up)|[{}]","") Then
		Return 1
	EndIf
	return 0
EndFunc ;IsCurrentHotKey($key)==>
;=============================================================================
; Determines if a macro event is the toggle run stop hotkey
;=============================================================================
Func IsRunStopHotkey($key) ;Regular expressions included in next version
	If StringRegExpReplace($runstop_hotkey,"[{}]","") = StringRegExpReplace($key,"( down)|( up)|[{}]","") Then
		Return 1
	EndIf
	return 0
EndFunc ;IsRunStopHotkey($key)==>
;=============================================================================
; Clears Macro Editor window controls
; Used mainly for creating a new macro
;=============================================================================
Func ClearEditorWindow()
	_GUICtrlListClear($Seqlist)
	GUICtrlSetData($in_name,"")
	GUICtrlSetData($in_delay,"")
	GUICtrlSetData($l_bindkey,"Binded to:")
	GUICtrlSetState($b_DeleteItem,$GUI_DISABLE)
	GUICtrlSetState($b_MoveUp,$GUI_DISABLE)
	GUICtrlSetState($b_MoveDown,$GUI_DISABLE)
	GuiCtrlSetState($r_mtype1, $GUI_CHECKED)
	GUICtrlSetState($r_mtype3,$GUI_UNCHECKED)
	GUICtrlSetState($repeat_input,$GUI_DISABLE)
	GUICtrlSetData($repeat_input,"")
	GUICtrlSetData($in_bindkey,"No Key")
EndFunc ;ClearEditorWindow()==>
;=============================================================================
; Refreshes the macro listbox with current macro names in profile file.
;=============================================================================
Func LoadMacroList($file_name)
	Local $MacroNames = IniReadSectionNames($file_name)
	_GUICtrlListClear($macrolist)
	If IsArray($MacroNames) Then ;If there are macros in profile then
		For $i = 1 To $MacroNames[0] ;Add each ini section name to macro listbox
			_GUICtrlListAddItem($macrolist,$MacroNames[$i])
		Next
		GUICtrlSetState($b_run,$GUI_ENABLE)
		GUICtrlSetState($b_edit,$GUI_ENABLE)
		GUICtrlSetState($b_delete,$GUI_ENABLE)
		_GUICtrlListSelectIndex($macrolist,0)
	Else
		GUICtrlSetState($b_run,$GUI_DISABLE)
		GUICtrlSetState($b_edit,$GUI_DISABLE)
		GUICtrlSetState($b_delete,$GUI_DISABLE)
	EndIf
EndFunc ;LoadMacroList($file_name)==>
;=============================================================================
; Reads in Profile macro depending on name of macro. After the event list
; is populated with events from file.
;=============================================================================
Func LoadEditorWindow()
	If _GUICtrlListGetText($macrolist,_GUICtrlListSelectedIndex($macrolist)) > -1 Then
		Global $currentOpenMacro = _GUICtrlListGetText($macrolist,_GUICtrlListSelectedIndex($macrolist))
		$currentOpenMacroIndex = _GUICtrlListSelectedIndex($macrolist)
		ClearEditorWindow() ;Clear unwanted crap
		;Load macro events to the event listbox in macro editor
		ConvertIniFormatToArray($ini_file,_GUICtrlListGetText($macrolist,_GUICtrlListSelectedIndex($macrolist)))
		If _Guictrllistcount($Seqlist) > 1 Then ;Enable all controls if
			GUICtrlSetState($b_Insert,$GUI_ENABLE)
			GUICtrlSetState($b_DeleteItem,$GUI_ENABLE)
			GUICtrlSetState($b_MoveUp,$GUI_ENABLE)
			GUICtrlSetState($b_MoveDown,$GUI_ENABLE)
		Elseif _Guictrllistcount($Seqlist) = 1 Then
			GUICtrlSetState($b_Insert,$GUI_ENABLE)
			GUICtrlSetState($b_DeleteItem,$GUI_ENABLE)
		EndIf
		_GUICtrlListSelectIndex($Seqlist,0)
		GUICtrlSetData($in_name,_GUICtrlListGetText($macrolist,_GUICtrlListSelectedIndex($macrolist)))
		GUISetState(@SW_SHOW,$CeWin)
		GUISetState(@SW_RESTORE,$CeWin)
		GUISetState(@SW_DISABLE,$MainWin)
	Else
		ClearEditorWindow() ;Only load if a macro is selected, else just display clean editor window
	EndIf
EndFunc ;LoadEditorWindow()==>
;=============================================================================
; When user clicks Bind To Key button, all controls are disabled until a key
; is pressed. The binded key is displayed after press.
;=============================================================================
Func BindToKey()
	LoadMacroIndexes()
	_ClearKeyboardCache()
	If $editflag = 1 Then ;If its a macro edit
		Local $ini = IniReadSection($ini_file,$currentOpenMacro)
		If IsArray($ini) Then 
			Local $currentMacroBind = $ini[1][1] ;Key the current keybind for macro
		Else
			Local $currentMacroBind = "No Key" ;If macro is empty
		EndIf
	Else ;If its a new macro
		$currentMacroBind = "No Key"
	EndIf
	GUICtrlSetData($in_hidden,"")
	GUICtrlSetState($in_hidden,$GUI_FOCUS)
	GUICtrlSetState($b_startRec,$GUI_DISABLE)
	GUICtrlSetState($b_bindkey,$GUI_DISABLE)
	GUICtrlSetState($b_OK,$GUI_DISABLE)
	GUICtrlSetState($b_Cancel,$GUI_DISABLE)
	GUICtrlSetState($c_mouseclickposrecord,$GUI_DISABLE)
	GUICtrlSetState($b_Insert,$GUI_DISABLE)
	GUICtrlSetState($in_name,$GUI_DISABLE)
	GUICtrlSetState($b_DeleteItem,$GUI_DISABLE)
	GUICtrlSetState($l_delay,$GUI_DISABLE)
	GUICtrlSetState($c_mousepathrecord,$GUI_DISABLE)
	GUICtrlSetState($c_mouseclickrecord,$GUI_DISABLE)
	GUICtrlSetState($b_MoveUp,$GUI_DISABLE)
	GUICtrlSetState($b_MoveDown,$GUI_DISABLE)
	GUICtrlSetState($r_mtype1,$GUI_DISABLE)
	GUICtrlSetState($r_mtype2,$GUI_DISABLE)
	GUICtrlSetState($r_mtype3,$GUI_DISABLE)
	GUICtrlSetState($repeat_input,$GUI_DISABLE)
	GUICtrlSetState($b_up,$GUI_DISABLE)
	GUICtrlSetState($b_down,$GUI_DISABLE)
	GUICtrlSetState($in_delay,$GUI_DISABLE)
	GUICtrlSetState($c_delayrecord,$GUI_DISABLE)
	GUICtrlSetData($in_bindkey,"Press a key")
	Local $keybind = GetKeyPressed("editor")
	If $keybind = $currentMacroBind And $keybind <> "{ESC}" Then
		GUICtrlSetData($in_bindkey,StringUpper($keybind))
	ElseIf $keybind <> "{ESC}" And Not IsBindTaken($keybind) And GUICtrlRead($Option_in_ONOFF) <> $keybind And GUICtrlRead($Option_in_Record) <> $keybind Then
		GUICtrlSetData($in_bindkey,StringUpper($keybind))
	ElseIf IsBindTaken($keybind) Then
		GUICtrlSetData($in_bindkey,$currentMacroBind)
		MsgBox(0,"Key is reserved","'" & $keybind & "' key used by another macro" & @LF & "  Select a different key")
	ElseIf GUICtrlRead($Option_in_ONOFF) = $keybind Then
		If $currentMacroBind = -1 Then
			GUICtrlSetData($in_bindkey,"No Key")
		Else
			GUICtrlSetData($in_bindkey,$currentMacroBind)
		EndIf
		MsgBox(0,"Key is reserved","'" & $keybind & "' key used by ON/OFF toggle" & @LF & "  Select a different key")
	ElseIf GUICtrlRead($Option_in_Record) = $keybind Then
		If $currentMacroBind = -1 Then
			GUICtrlSetData($in_bindkey,"No Key")
		Else
			GUICtrlSetData($in_bindkey,$currentMacroBind)
		EndIf
		MsgBox(0,"Key is reserved","'" & $keybind & "' key used by Start/Stop toggle" & @LF & "  Select a different key")
	ElseIf $keybind = "{ESC}" Then
		GUICtrlSetData($in_bindkey,"No Key")
	EndIf
	GUICtrlSetState($b_startRec,$GUI_ENABLE)
	GUICtrlSetState($b_OK,$GUI_ENABLE)
	GUICtrlSetState($b_Cancel,$GUI_ENABLE)
	GUICtrlSetState($b_Insert,$GUI_ENABLE)
	GUICtrlSetState($in_name,$GUI_ENABLE)
	GUICtrlSetState($b_DeleteItem,$GUI_ENABLE)
	GUICtrlSetState($b_MoveUp,$GUI_ENABLE)
	GUICtrlSetState($b_MoveDown,$GUI_ENABLE)
	GUICtrlSetState($b_bindkey,$GUI_ENABLE)
	GUICtrlSetState($l_delay,$GUI_ENABLE)
	GUICtrlSetState($r_mtype3,$GUI_ENABLE)
	If BitAND(GUICtrlRead($c_mouseclickrecord),$GUI_CHECKED) Then
		GUICtrlSetState($c_mouseclickposrecord,$GUI_ENABLE)
	Else
		GUICtrlSetState($c_mouseclickposrecord,$GUI_DISABLE)
	EndIf
	GUICtrlSetState($r_mtype1,$GUI_ENABLE)
	GUICtrlSetState($c_mousepathrecord,$GUI_ENABLE)
	GUICtrlSetState($c_mouseclickrecord,$GUI_ENABLE)
	GUICtrlSetState($r_mtype2,$GUI_ENABLE)
	GUICtrlSetState($repeat_input,$GUI_ENABLE)
	GUICtrlSetState($b_up,$GUI_ENABLE)
	GUICtrlSetState($b_down,$GUI_ENABLE)
	GUICtrlSetState($in_delay,$GUI_ENABLE)
	GUICtrlSetState($c_delayrecord,$GUI_ENABLE)
EndFunc ;BindToKey()==>
;=============================================================================
; Returns true if macro bind key is already taken by another macro
;=============================================================================
Func IsBindTaken($key)
	For $i = 1 To UBound($MacroIndex) - 1
		If $key = $MacroIndex[$i] Then 
			return 1
		EndIf
	Next
	return 0
EndFunc ;IsBindTaken($key)==>
;=============================================================================
; Inserts an value into the EventListBox above selected item.
;=============================================================================
Func InsertEntry($value,$index) ;Inserts a value into Event List at desired index
	_GUICtrlListInsertItem($Seqlist,$value,$index)
	If _Guictrllistcount($Seqlist) > 1 Then
		GUICtrlSetState($b_DeleteItem,$GUI_ENABLE)
		GUICtrlSetState($b_MoveUp,$GUI_ENABLE)
		GUICtrlSetState($b_MoveDown,$GUI_ENABLE)
	ElseIf _Guictrllistcount($Seqlist) = 1 Then
		GUICtrlSetState($b_DeleteItem,$GUI_ENABLE)
	EndIf
EndFunc ;InsertEntry($value,$index)==>
;=============================================================================
; During Inserting a recorded key press, the advanced options allow the user
; to supple a key press that is Normal,Release,Or Hold.
;=============================================================================
Func InsertRecordedKey($index)
	GUICtrlSetState($b_InsertOK,$GUI_DISABLE)
	Local $in_keypress = GUICtrlRead($in_insert)
	If $in_keypress <> "" Then
		If BitAND(GUICtrlRead($r_keypress),$GUI_CHECKED) Then
			If _GUICtrlListSelectedIndex($Seqlist) > -1 Then
				InsertEntry($in_keypress & "  Release",$index)
				InsertEntry("0.05 Delay",$index)
				InsertEntry($in_keypress & "  Hold",$index)
			Else
				InsertEntry($in_keypress & "  Hold",$index)
				InsertEntry("0.05 Delay",$index)
				InsertEntry($in_keypress & "  Release",$index)
			EndIf
		ElseIf BitAND(GUICtrlRead($r_keyup),$GUI_CHECKED) Then
			InsertEntry($in_keypress & "  Release",$index)
		ElseIf BitAND(GUICtrlRead($r_keydown),$GUI_CHECKED) Then
			InsertEntry($in_keypress & "  Hold",$index)
		EndIf
	EndIf
	GUICtrlSetData($in_insert,"")
EndFunc ;InsertRecordedKey($index)==>
;=============================================================================
; Inserts a mouse button press event at the specified index of a listbox
; Inserts mouse button down + delay + mouse button up
;=============================================================================
Func InsertMouseEvent($index)
	If BitAND(GUICtrlRead($r_l_mouse),$GUI_CHECKED) Then ;left mouse button
		If _GUICtrlListSelectedIndex($Seqlist) > -1 Then
			InsertEntry("{LMouse}  Release",$index)
			InsertEntry("0.05 Delay",$index) 
			InsertEntry("{LMouse}  Hold",$index)
		Else
			InsertEntry("{LMouse}  Hold",$index)
			InsertEntry("0.05 Delay",$index) 
			InsertEntry("{LMouse}  Release",$index)
		Endif
	ElseIf BitAND(GUICtrlRead($r_m_mouse),$GUI_CHECKED) Then ;middle mouse button
		If _GUICtrlListSelectedIndex($Seqlist) > -1 Then
			InsertEntry("{MMouse}  Release",$index)
			InsertEntry("0.05 Delay",$index)
			InsertEntry("{MMouse}  Hold",$index)
		Else
			InsertEntry("{MMouse}  Hold",$index)
			InsertEntry("0.05 Delay",$index)
			InsertEntry("{MMouse}  Release",$index)
		EndIf
	Else ;right mouse button
		If _GUICtrlListSelectedIndex($Seqlist) > -1 Then
			InsertEntry("{RMouse}  Release",$index) 
			InsertEntry("0.05 Delay",$index)
			InsertEntry("{RMouse}  Hold",$index)
		Else
			InsertEntry("{RMouse}  Hold",$index) 
			InsertEntry("0.05 Delay",$index)
			InsertEntry("{RMouse}  Release",$index)	
		EndIf
	EndIf
EndFunc ;InsertMouseEvent($index)==>
;=============================================================================
; If Insert event window is displayed then disable/enable GUI controls
; depending if user is recording
;=============================================================================
Func RecordInsert()
	_ClearKeyboardCache()
	GUICtrlSetData($in_insert,"Press a key")
	GUICtrlSetState($b_InsertOK,$GUI_DISABLE) ; Disable all GUI controls while recording
	GUICtrlSetState($b_InsertRecord,$GUI_DISABLE)
	GUICtrlSetState($b_InsertCancel,$GUI_DISABLE)
	GUICtrlSetState($r_keypress,$GUI_DISABLE)
	GUICtrlSetState($r_keyup,$GUI_DISABLE)
	GUICtrlSetState($r_keydown,$GUI_DISABLE) ; ^^
	Local $keypressed_insert = GetKeyPressed("insertkey")
	GUICtrlSetData($in_insert,$keypressed_insert)
	GUICtrlSetState($b_InsertOK,$GUI_ENABLE)
	GUICtrlSetState($b_InsertRecord,$GUI_ENABLE)
	GUICtrlSetState($r_keypress,$GUI_ENABLE)
	GUICtrlSetState($r_keyup,$GUI_ENABLE)
	GUICtrlSetState($r_keydown,$GUI_ENABLE)
	GUICtrlSetState($b_InsertCancel,$GUI_ENABLE)
EndFunc ;RecordInsert()==>
;=============================================================================
; When user changes the Macro RUN / STOP hotkey all other controls in settings
; window are disabled until a key has been pressed
;=============================================================================
Func RecordONOFF_HotKey()
	LoadMacroIndexes() ;Init MacroIndex lookup table
	_ClearKeyboardCache() ;Ensure no keys are held down
	GUICtrlSetData($in_hidden,"")
	GUICtrlSetState($in_hidden,$GUI_FOCUS) ;Disable all GUI controls
	Local $curHotkey = GUICtrlRead($Option_in_ONOFF)
	GUICtrlSetData($Option_in_ONOFF,"Press a key")
	GUICtrlSetState($Option_b_defaultpro,$GUI_DISABLE) ; Disable all GUI controls while recording
	GUICtrlSetState($Option_ck_Notify,$GUI_DISABLE)
	GUICtrlSetState($Option_b_ONOFF,$GUI_DISABLE)
	GUICtrlSetState($Option_b_OK,$GUI_DISABLE)
	GUICtrlSetState($Option_b_cancel,$GUI_DISABLE)
	GUICtrlSetState($Option_in_default,$GUI_DISABLE)
	GUICtrlSetState($Option_b_Record,$GUI_DISABLE)
	GUICtrlSetState($Option_in_Record,$GUI_DISABLE)
	GUICtrlSetState($Option_ck_Record_Notify,$GUI_DISABLE)
	Local $keypressed_insert = GetKeyPressed("onoff") ;Wait here until a key is pressed
	If IsBindTaken($keypressed_insert) <> 1 And GUICtrlRead($Option_in_Record) <> $keypressed_insert Then ;If not used by a macro
		GUICtrlSetData($Option_in_ONOFF,$keypressed_insert)
	Else
		GUICtrlSetData($Option_in_ONOFF,$curHotKey)
		MsgBox(0,"Key Reserved","'" & $keypressed_insert & "'" & " is already binded")
	EndIf
	GUICtrlSetState($Option_b_defaultpro,$GUI_ENABLE) ; Enable all GUI controls while recording
	GUICtrlSetState($Option_b_ONOFF,$GUI_ENABLE)
	GUICtrlSetState($Option_ck_Notify,$GUI_ENABLE)
	GUICtrlSetState($Option_b_OK,$GUI_ENABLE)
	GUICtrlSetState($Option_b_cancel,$GUI_ENABLE)
	GUICtrlSetState($Option_in_default,$GUI_ENABLE)
	GUICtrlSetState($Option_b_Record,$GUI_ENABLE)
	GUICtrlSetState($Option_in_Record,$GUI_ENABLE)
	GUICtrlSetState($Option_ck_Record_Notify,$GUI_ENABLE)
EndFunc ;RecordInsert()==>

;=============================================================================
; When user changes the Start / Stop hotkey all other controls in settings
; window are disabled until a key has been pressed
;=============================================================================
Func RecordStartStop_HotKey()
	LoadMacroIndexes() ;Init MacroIndex lookup table
	_ClearKeyboardCache() ;Ensure no keys are held down
	GUICtrlSetData($in_hidden,"")
	GUICtrlSetState($in_hidden,$GUI_FOCUS) ;Disable all GUI controls
	Local $curHotkey = GUICtrlRead($Option_in_Record)
	GUICtrlSetData($Option_in_Record,"Press a key")
	GUICtrlSetState($Option_b_defaultpro,$GUI_DISABLE) ; Disable all GUI controls while recording
	GUICtrlSetState($Option_ck_Notify,$GUI_DISABLE)
	GUICtrlSetState($Option_b_ONOFF,$GUI_DISABLE)
	GUICtrlSetState($Option_in_ONOFF,$GUI_DISABLE)
	GUICtrlSetState($Option_b_OK,$GUI_DISABLE)
	GUICtrlSetState($Option_b_cancel,$GUI_DISABLE)
	GUICtrlSetState($Option_in_default,$GUI_DISABLE)
	GUICtrlSetState($Option_b_Record,$GUI_DISABLE)
	GUICtrlSetState($Option_ck_Record_Notify,$GUI_DISABLE)
	Local $keypressed_insert = GetKeyPressed("recstartstop") ;Wait here until a key is pressed
	If IsBindTaken($keypressed_insert) <> 1 And GUICtrlRead($Option_in_ONOFF) <> $keypressed_insert Then ;If not used by a macro
		GUICtrlSetData($Option_in_Record,$keypressed_insert)
	Else
		GUICtrlSetData($Option_in_Record,$curHotKey)
		MsgBox(0,"Key Reserved","'" & $keypressed_insert & "'" & " is already binded")
	EndIf
	GUICtrlSetState($Option_b_defaultpro,$GUI_ENABLE) ; Enable all GUI controls while recording
	GUICtrlSetState($Option_b_ONOFF,$GUI_ENABLE)
	GUICtrlSetState($Option_ck_Notify,$GUI_ENABLE)
	GUICtrlSetState($Option_b_OK,$GUI_ENABLE)
	GUICtrlSetState($Option_b_cancel,$GUI_ENABLE)
	GUICtrlSetState($Option_in_default,$GUI_ENABLE)
	GUICtrlSetState($Option_in_ONOFF,$GUI_ENABLE)
	GUICtrlSetState($Option_b_Record,$GUI_ENABLE)
	GUICtrlSetState($Option_ck_Record_Notify,$GUI_ENABLE)
EndFunc ;RecordInsert()==>
;=============================================================================
; Load items from array into listbox 1 by 1
;=============================================================================
Func ArrayToEventList($array) ;Stores an array into the listbox
	_GUICtrlListClear($Seqlist)
	For $i = 1 To UBound($array)
		_GUICtrlListAddItem($Seqlist,$array[$i-1])
	Next
EndFunc ;ArrayToEventList($array)==>
;=============================================================================
; Takes in Profile INI macro section and adds each element to event list
;=============================================================================
Func ConvertIniFormatToArray($ini_file,$macro_name)
	$IniSection = IniReadSection($ini_file,$macro_name)
	If IsArray($IniSection) Then ;If its an actual macro
		GUICtrlSetData($in_bindkey,$IniSection[1][1]) 
		If $IniSection[2][1] = "1" Then ;Save the repeat number
			GuiCtrlSetState($r_mtype1, $GUI_CHECKED)
			GuiCtrlSetState($r_mtype3, $GUI_UNCHECKED)
		ElseIf $IniSection[2][1] = "4294967296"  Then;2^32
			GuiCtrlSetState($r_mtype3, $GUI_CHECKED)
			GuiCtrlSetState($r_mtype1, $GUI_UNCHECKED)
			GuiCtrlSetState($repeat_input, $GUI_DISABLE)
		Else
			GuiCtrlSetState($r_mtype2, $GUI_CHECKED)
			GuiCtrlSetState($repeat_input, $GUI_ENABLE)
			GUICtrlSetData($repeat_input,$IniSection[2][1])
		EndIf
		Local $eventsize = $IniSection[0][0] 
		For $i = 3 To $IniSection[0][0] 
			If StringRegExp($IniSection[$i][1],"( D)") Then ;Is a number omfghax!
				$IniSection[$i][1] = StringFormat("%.2f",Round(StringRegExpReplace($IniSection[$i][1],"( Delay)","")/1000,2)) & "  Delay"
			ElseIf StringRegExp($IniSection[$i][1],"(M )") Then
				$IniSection[$i][1] = StringRegExpReplace($IniSection[$i][1],"(M )","Move  ")
			ElseIf StringLen(StringRegExpReplace($IniSection[$i][1],"( down)|( up)|[{}]","")) = 1 Then ;if a single character
				If StringRegExp($IniSection[$i][1],"(down)") Then
					$IniSection[$i][1] = StringRegExpReplace(StringRegExpReplace($IniSection[$i][1],"[{]",""),"( down})","  Hold")
				Else ;up
					$IniSection[$i][1] = StringRegExpReplace(StringRegExpReplace($IniSection[$i][1],"[{]",""),"( up})","  Release")
				EndIf
			Else ;if a special key such as alt ctrl shift..
				If StringRegExp($IniSection[$i][1],"(down)|(DOWN)") Then
					If StringRegExp($IniSection[$i][1],"(SHIFT)|(CTRL)|(WIN)|(ALT)") Then 
						$IniSection[$i][1] = StringRegExpReplace($IniSection[$i][1],"(DOWN})","}  Hold")
					Else
						$IniSection[$i][1] = StringRegExpReplace($IniSection[$i][1],"( down})","}  Hold")
					EndIf
				Else ;up
					If StringRegExp($IniSection[$i][1],"(SHIFT)|(CTRL)|(WIN)|(ALT)") Then 
						$IniSection[$i][1] = StringRegExpReplace($IniSection[$i][1],"(UP})","}  Release")
					ElseIf StringRegExp($IniSection[$i][1],"(wd)|(wu)") Then
						If $IniSection[$i][1] = "wd" Then
							$IniSection[$i][1] = "Mouse Wheel Down"
						Else
							$IniSection[$i][1] = "Mouse Wheel Up"
						EndIf
					Else
						$IniSection[$i][1] = StringRegExpReplace($IniSection[$i][1],"( up})","}  Release")
					EndIf
				EndIf
			EndIf 
			_GUICtrlListAddItem($Seqlist,$IniSection[$i][1])
		Next 
	EndIf 
EndFunc ;ConvertIniFormatToArray($ini_file,$macro_name)==>

;=============================================================================
; Converts Event listbox items into an Array
; Returns: Array or Int(0) if listbox empty
;=============================================================================
Func EventListToArray()
	Local $value
	Local $EventList = _ArrayCreate(-1) ;Note: -1 will create empty array
	If _GUICtrlListCount($Seqlist) > 0 Then
		For $i = 0 To _GUICtrlListCount($Seqlist)
			$value = _GUICtrlListGetText($Seqlist,$i)
			_ArrayAdd($EventList,$value)
		Next
		_ArrayDelete($EventList,_GUICtrlListCount($Seqlist)+1)
		Return $EventList
	Else 
		Return 0 ;Empty EventList
	EndIf
EndFunc ;EventListToArray()==>
;=============================================================================
; Takes all data from Macro Editor window and converts it in a string that
; is compatible with IniWriteSection() function
;=============================================================================
Func ConvertMacroToIniFormat()
	_GUICtrlStatusBarSetText($statusbar2,"Saving macro...")
	Local $temp = EventListToArray() ;return's 0 if no events
	_ArrayDelete($temp,0)
	Local $eventsize = Ubound($temp)
	For $i = 0 To Ubound($temp) - 1 
		If StringRegExp($temp[$i],"[}]") Then
			If StringRegExp($temp[$i],"(Hold)") Then
				If StringRegExp($temp[$i],"[)]") <> 1 Then ;not a mouse movement
					If StringRegExp($temp[$i],"(SHIFT)|(CTRL)|(WIN)|(ALT)") Then 
						$temp[$i] = "e=" & StringTrimRight(StringRegExpReplace($temp[$i],"(})","DOWN}"),6)
					Else
						$temp[$i] = "e=" & StringTrimRight(StringRegExpReplace($temp[$i],"(})"," down}"),6)
					EndIf
				Else
					Local $tempStr = StringSplit(StringRegExpReplace($temp[$i],"(  )"," ")," ")
					$temp[$i] = "e=" & StringRegexpReplace($tempStr[1],"(})"," down}") & "  " & $tempStr[3]
				EndIf
			ElseIf StringRegExp($temp[$i],"(Release)") Then
				If StringRegExp($temp[$i],"[)]") <> 1 Then ;not a mouse movement
					If StringRegExp($temp[$i],"(SHIFT)|(CTRL)|(WIN)|(ALT)") Then 
						$temp[$i] = "e=" & StringTrimRight(StringRegExpReplace($temp[$i],"(})","UP}"),9)
					Else
						$temp[$i] = "e=" & StringTrimRight(StringRegExpReplace($temp[$i],"(})"," up}"),9)
					EndIf
				Else
					Local $tempStr = StringSplit(StringRegExpReplace($temp[$i],"(  )"," ")," ")
					$temp[$i] = "e=" & StringRegExpReplace($tempStr[1],"(})"," up}") & "  " & $tempStr[3]
				EndIf
			EndIf
		ElseIf StringRegExp($temp[$i],"[<]") Then
			$temp[$i] = "e=" & $temp[$i]
		Else
			If StringRegExp($temp[$i],"(Delay)") Then
				$temp[$i] = "e=" & 1000*StringTrimRight($temp[$i],6) & " D"
			ElseIf StringRegExp($temp[$i],"(Hold)") Then
				$temp[$i] = "e={" & StringReplace($temp[$i]," Hold","down}")
			ElseIf StringRegExp($temp[$i],"(Release)") Then
				$temp[$i] = "e={" & StringReplace($temp[$i]," Release","up}")
			ElseIf StringRegExp($temp[$i],"(Move)") Then
				$temp[$i] = "e=" & StringRegExpReplace($temp[$i],"(Move  )","M ")
			ElseIf StringRegExp($temp[$i],"(Wheel)") Then
				If StringRegExp($temp[$i],"(Down)") Then
					$temp[$i] = "e=" & "wd" ;wheel down
				Else
					$temp[$i] = "e=" & "wu" ;wheel up
				EndIf
			EndIf
		EndIf
	Next
	If BitAND(GUICtrlRead($r_mtype1),$GUI_CHECKED) = 1 Then
		_ArrayInsert($temp,0,"repeat=1")
	ElseIf BitAND(GUICtrlRead($r_mtype2),$GUI_CHECKED) = 1 Then
		_ArrayInsert($temp,0,"repeat=" & GUICtrlRead($repeat_input))
	ElseIf BitAND(GUICtrlRead($r_mtype3),$GUI_CHECKED) = 1 Then
		_ArrayInsert($temp,0,"repeat=" & 4294967296)
	EndIf
	_ArrayInsert($temp,0,"bindedkey=" & GUICtrlRead($in_bindkey))
	Local $IniStr = _ArrayToString($temp,@LF)
	Return $IniStr
EndFunc ;ConvertMacroToIniFormat()==>
;=============================================================================
; Writes the macro to Profile INI file
; $file_format (string): Macro array in string format
; $macro_name (string): Section of INI in [name]'s
;=============================================================================
Func SaveMacro($ini_file,$macro_name)
	Local $res = IniWriteSection($ini_file,$macro_name,ConvertMacroToIniFormat())
EndFunc ;SaveMacro($ini_file,$macro_name)==>
;=============================================================================
; Moves selected event listbox item UP or DOWN depending on direction
;=============================================================================
Func MoveListItem($direction,$index)
	If $index > -1 Then
		If $direction = "up" And $index > 0 Then
			_GUICtrlListInsertItem($Seqlist,_GUICtrlListGetText($Seqlist,$index),$index-1)
			_GUICtrlListDeleteItem($Seqlist,$index+1)
			_GUICtrlListSelectIndex($Seqlist,$index-1)
		ElseIf $direction = "down" And _GUICtrlListCount($Seqlist) <> $index+1 Then
			_GUICtrlListInsertItem($Seqlist,_GUICtrlListGetText($Seqlist,$index),$index+2)
			_GUICtrlListDeleteItem($Seqlist,$index)
			_GUICtrlListSelectIndex($Seqlist,$index+1)
		EndIf
	EndIf
EndFunc ;MoveListItem($direction,$index)==>
;=============================================================================
; Deletes the selected item in listbox then selects upper item
;=============================================================================
Func DeleteEventItem()
	If _GUICtrlListSelectedIndex($Seqlist) > -1 Then
		Local $updatedIndex = _GUICtrlListSelectedIndex($Seqlist)
		_GUICtrlListDeleteItem($Seqlist,_GUICtrlListSelectedIndex($Seqlist))
		_GUICtrlListSelectIndex($Seqlist,$updatedIndex-1)
		If StringRegExp(_GUICtrlListGetText($Seqlist,$updatedIndex-1),"Delay") = 1 Then
			GUICtrlSetData($in_delay,StringReplace(_GUICtrlListGetText($Seqlist,$updatedIndex-1)," Delay",""))
			GUICtrlSetState($in_delay,$GUI_ENABLE)
			GUICtrlSetState($b_up,$GUI_ENABLE)
			GUICtrlSetState($b_down,$GUI_ENABLE)
		Else
			GUICtrlSetData($in_delay,"")
			GUICtrlSetState($in_delay,$GUI_DISABLE)
			GUICtrlSetState($b_up,$GUI_DISABLE)
			GUICtrlSetState($b_down,$GUI_DISABLE)
		EndIf
		If _GUICtrlListSelectedIndex($Seqlist) < 0 And _GUICtrlListCount($Seqlist) > 0 Then
			_GUICtrlListSelectIndex($Seqlist,0)
		EndIf
		If _GUICtrlListCount($Seqlist) < 2 Then
			GUICtrlSetState($b_MoveUp,$GUI_DISABLE)
			GUICtrlSetState($b_MoveDown,$GUI_DISABLE)	
		EndIf
	EndIf
	If _GUICtrlListCount($Seqlist) = 0 Then 
		GUICtrlSetState($b_DeleteItem,$GUI_DISABLE)
		GUICtrlSetState($b_MoveUp,$GUI_DISABLE)
		GUICtrlSetState($b_MoveDown,$GUI_DISABLE)
	EndIf
EndFunc ;DeleteEventItem()==>
;=============================================================================
; Inserts the delay input from the user into the listbox.
; $index (integer): index of selected listbox item
;=============================================================================
Func InsertDelay($index)
	Local $number
	If StringLen(GUICtrlRead($delay_digit_input)) > 0 And Stringlen(GUICtrlRead($delay_decimal_input)) > 0 Then
		If Stringlen(GUICtrlRead($delay_decimal_input)) = 1 Then
			$number = (Guictrlread($delay_digit_input) + GUICtrlRead($delay_decimal_input)*10)/100
		Else
			$number = Guictrlread($delay_digit_input) + GUICtrlRead($delay_decimal_input)/100
		EndIf
		If _GUICtrlListSelectedIndex($Seqlist) > -1 Then
			_GUICtrlListInsertItem($Seqlist,StringFormat("%.2f",$number) & "  Delay",$index)
		Else
			_GUICtrlListAddItem($Seqlist,StringFormat("%.2f",$number) & "  Delay")
		EndIf
		If _guictrllistcount($Seqlist) = 1 Then 
			GUICtrlSetState($b_DeleteItem,$GUI_ENABLE)
		ElseIf _Guictrllistcount($Seqlist) = 2 Then
		GUICtrlSetState($b_MoveUp,$GUI_ENABLE)
		GUICtrlSetState($b_MoveDown,$GUI_ENABLE)
		EndIf
	Else
		MsgBox(0,"No delay entered","Please enter a number in each box")
	EndIf
EndFunc ;InsertDelay($index)==>
;=============================================================================
; Takes selected delay listbox item and inserts number in textbox
; $index (integer): index of selected listbox item
;=============================================================================
Func LoadDelayInput($index) ;Puts delay event in updown modify control
	Local $value = _GUICtrlListGetText($Seqlist,_GUICtrlListSelectedIndex($Seqlist))
	If StringRight($value,5) = "Delay" Then
		GUIctrlsetdata($in_delay,StringReplace($value," Delay",""))
	Else
		GUIctrlsetdata($in_delay,"")
	Endif
EndFunc ;LoadDelayInput($index)==>
;=============================================================================
; Takes the value stored in textbox (delay box) and increments/decrements the 
; number the 0.01 then replaces listbox selected item with new value
; $direction (string): UP = +0.01, DOWN = -0.01
;=============================================================================
Func ModifyDelay($direction)
	If _GUICtrlListCount($Seqlist) > 0 And _GUICtrlListSelectedIndex($Seqlist) > -1 Then
		If StringInStr(_GUICtrlListGetText($Seqlist,_GUICtrlListSelectedIndex($Seqlist))," Delay") Then
			Local $value = _GUICtrlListGetText($Seqlist,_GUICtrlListSelectedIndex($Seqlist))
			Local $index = _GUICtrlListSelectedIndex($Seqlist)
			GUICtrlSetData($in_delay,StringReplace($value," Delay",""))
			$value = StringReplace($value," Delay","")
			If $direction = "up" Then
				GUICtrlSetData($in_delay,StringFormat("%.2f",$value+0.01))
				_GUICtrlListReplaceString($Seqlist,$index,StringFormat("%.2f",$value+0.01) & " Delay")
				_GUICtrlListSelectIndex($Seqlist,$index)
			ElseIf $direction = "down" Then
				If GUICtrlRead($in_delay) > 0 Then
				GUICtrlSetData($in_delay,StringFormat("%.2f",$value-0.01))
				_GUICtrlListReplaceString($Seqlist,$index,StringFormat("%.2f",$value-0.01) & " Delay")
				_GUICtrlListSelectIndex($Seqlist,$index)
				EndIf
			EndIf
		EndIf
	EndIf
EndFunc ;ModifyDelay($direction)==>
;=============================================================================
; If macrolist item is selected and delete button pressed, then delete item
; and the macro entry in profile file
;=============================================================================
Func DeleteMacro($file_name,$macro_name)
	If _GUICtrlListCount($macrolist) > -1 Then
		Local $returned = MsgBox(4,"Delete Macro","Are you sure?")
		If $returned = 6 Then
			_GUICtrlListDeleteItem($macrolist,_GUICtrlListSelectedIndex($macrolist))
			IniDelete($file_name,$macro_name)
			If _GUICtrlListCount($macrolist) < 1 Then
				GUICtrlSetState($b_Edit,$GUI_DISABLE)
				GUICtrlSetState($b_Delete,$GUI_DISABLE)
			Else
				_GUICtrlListSelectIndex($macrolist,_GUICtrlListCount($macrolist)-1)
			EndIf
		EndIf
	EndIf
EndFunc ;DeleteMacro()==>
;=============================================================================
; When user clicks OK button in macro editor the macro editor GUI will hide
; and MainWin of app will show with new macro name in list.
; EditFlag is used to determine if a new macro is being created or an existing
; macro is being loaded to being edited
; EditFlag = 0 => Insert new macro in list
; EditFlag = 1 => Update macro with entries from macro editor
;=============================================================================
Func CreateMacro()
	If StringIsASCII(GuiCtrlread($in_name)) And StringIsAlNum(GuiCtrlread($in_name)) Then
		If MacroNameExists(GuiCtrlread($in_name)) And $editflag = 0 Then
			MsgBox(0,"Macro name conflict","Macro name already exists" & @CRLF & "Please change macro name")
		ElseIf MacroNameExists(GuiCtrlread($in_name)) And GuiCtrlread($in_name) <> $currentOpenMacro And $editflag = 1 Then
			MsgBox(0,"Macro name conflict","Macro name already exists" & @CRLF & "Please change macro name")
		Else
			If _GUICtrlListCount($Seqlist) > 0 Then
				If $editflag = 0 Then ;If user is creating a new macr5o
					SaveMacro($ini_file,GuiCtrlread($in_name))
					GUICtrlSetState($b_Delete,$GUI_ENABLE)
					GUICtrlSetState($b_Edit,$GUI_ENABLE)
				Elseif $editflag = 1 Then ;If macro is editing an existing macro
					IniDelete($ini_file,_GUICtrlListGetText($macrolist,$currentOpenMacroIndex)) ;used global here to prevent
					SaveMacro($ini_file,GuiCtrlread($in_name))								;any listbox conflicts
					$editflag = 0
				EndIf
				GUISetState(@SW_HIDE,$CeWin)
				GUISetState(@SW_ENABLE,$MainWin)
				GUISetState(@SW_RESTORE,$MainWin)
				EnabledCurrentONOFF()
				Return 0
			Else
				MsgBox(0,"No events found","Please record a macro")
			EndIf
		EndIf
	Else
		MsgBox(0,"Invalid name","Please enter a valid name" & @CR & "   No spaces allowed")
	EndIf
EndFunc ;CreateMacro()==>
;=============================================================================
; Parces through macro profile and if macro name is found then return true
;=============================================================================
Func MacroNameExists($macroname)
	Local $macroNameList = IniReadSectionNames($ini_file)
	If IsArray($macroNameList) Then
		For $i = 1 To $macroNameList[0]
			If $macroname = $macroNameList[$i] Then 
				Return 1
			EndIf
		Next
	EndIf
	Return 0
EndFunc ;MacroNameExists()==>
;=============================================================================
; Optimizes macro by converting events with HOLD and RELEASE of same key to 
; just a PRESS. This results in half the amount of Sending a keystroke to 
; the application window. Which IS a performance boost. 
; NOTE: Currently not in use, this is not user friendly. Maybe include in Pro version
; ex.  E Hold    ________\  E Press
;      E Release        /
;=============================================================================
Func OptimizeMacro() ;Added to make macros more responsive and quick
	If _GUICtrlListCount($Seqlist) > 0 Then	
		For $i = 0 To _GUICtrlListCount($Seqlist)
			If StringInStr(_GUICtrlListGetText($Seqlist,$i),"Hold") And StringInStr(_GUICtrlListGetText($Seqlist,$i+1),"Release") Then
				If StringReplace(_GUICtrlListGetText($Seqlist,$i),"Hold","") = StringReplace(_GUICtrlListGetText($Seqlist,$i+1),"Release","") Then
					_GUICtrlListReplaceString($Seqlist,$i,StringReplace(_GUICtrlListGetText($Seqlist,$i),"Hold","Press"))
					_GUICtrlListDeleteItem($Seqlist,$i+1)
				EndIf
			EndIf		
		Next
		_GUICtrlListSelectIndex($Seqlist,0) ;Reset selected index back to first item in list
	EndIf
EndFunc ;OptimizeMacro()==>
;=============================================================================
; Disable all editor controls
;=============================================================================
Func _DisableEditorControls()
	GUICtrlSetState($b_bindkey,$GUI_DISABLE) 
	GUICtrlSetState($b_startRec,$GUI_DISABLE)
	GUICtrlSetState($b_stopRec,$GUI_DISABLE)
	GUICtrlSetState($b_OK,$GUI_DISABLE)
	GUICtrlSetState($b_Cancel,$GUI_DISABLE)
	GUICtrlSetState($b_Insert,$GUI_DISABLE)
	GUICtrlSetState($in_name,$GUI_DISABLE)
	GUICtrlSetState($b_DeleteItem,$GUI_DISABLE)
	GUICtrlSetState($l_bindkey,$GUI_DISABLE)
	GUICtrlSetState($r_mtype1,$GUI_DISABLE)
	GUICtrlSetState($r_mtype2,$GUI_DISABLE)
	GUICtrlSetState($r_mtype3,$GUI_DISABLE)
	GUICtrlSetState($l_delay,$GUI_DISABLE)
	GUICtrlSetState($repeat_input,$GUI_DISABLE)
	GUICtrlSetState($l_name,$GUI_DISABLE)
	GUICtrlSetState($l_timed,$GUI_DISABLE)
	GUICtrlSetState($in_bindkey,$GUI_DISABLE)
	GUICtrlSetState($b_up,$GUI_DISABLE)
	GUICtrlSetState($b_down,$GUI_DISABLE)
	GUICtrlSetState($in_delay,$GUI_DISABLE)
	GUICtrlSetState($b_MoveUp,$GUI_DISABLE)
	GUICtrlSetState($c_delayrecord,$GUI_DISABLE)
	GUICtrlSetState($c_mousepathrecord,$GUI_DISABLE)
	GUICtrlSetState($c_mouseclickrecord,$GUI_DISABLE)
	GUICtrlSetState($c_mouseclickposrecord,$GUI_DISABLE)
	GUICtrlSetState($b_MoveDown,$GUI_DISABLE) ; ^^
EndFunc
;=============================================================================
; Enable all editor controls
;=============================================================================
Func _EnableEditorControls()
	GUICtrlSetState($b_startRec,$GUI_ENABLE)
	GUICtrlSetState($b_OK,$GUI_ENABLE)
	GUICtrlSetState($b_Cancel,$GUI_ENABLE)
	GUICtrlSetState($b_Insert,$GUI_ENABLE)
	GUICtrlSetState($in_name,$GUI_ENABLE)
	GUICtrlSetState($b_bindkey,$GUI_ENABLE)
	GUICtrlSetState($l_bindkey,$GUI_ENABLE)
	GUICtrlSetState($r_mtype1,$GUI_ENABLE)
	GUICtrlSetState($r_mtype2,$GUI_ENABLE)
	GUICtrlSetState($c_mouseclickrecord,$GUI_ENABLE)
	If BitAND(GUICtrlRead($c_mouseclickrecord),$GUI_CHECKED) Then
		GUICtrlSetState($c_mouseclickposrecord,$GUI_ENABLE)
	Else
		GUICtrlSetState($c_mouseclickposrecord,$GUI_DISABLE)
	EndIf
	GUICtrlSetState($c_mousepathrecord,$GUI_ENABLE)
	GUICtrlSetState($l_delay,$GUI_ENABLE)
	GUICtrlSetState($repeat_input,$GUI_ENABLE)
	GUICtrlSetState($l_name,$GUI_ENABLE)
	GUICtrlSetState($l_timed,$GUI_ENABLE)
	GUICtrlSetState($in_bindkey,$GUI_ENABLE)
	GUICtrlSetState($r_mtype3,$GUI_ENABLE)
	GUICtrlSetState($b_up,$GUI_ENABLE)
	GUICtrlSetState($b_down,$GUI_ENABLE)
	GUICtrlSetState($in_delay,$GUI_ENABLE)
	GUICtrlSetState($c_delayrecord,$GUI_ENABLE)
	GUICtrlSetState($b_DeleteItem,$GUI_ENABLE)
	GUICtrlSetState($b_MoveUp,$GUI_ENABLE)
	GUICtrlSetState($b_MoveDown,$GUI_ENABLE)
EndFunc
;=============================================================================
; When invoked, all GUI controls in editor window are enabled
;=============================================================================
Func StopRecording()
	GUICtrlSetState($b_startRec,$GUI_ENABLE)
	GUICtrlSetState($b_stopRec,$GUI_DISABLE)
	GUICtrlSetState($b_OK,$GUI_ENABLE)
	GUICtrlSetState($b_Cancel,$GUI_ENABLE)
	GUICtrlSetState($b_Insert,$GUI_ENABLE)
	GUICtrlSetState($in_name,$GUI_ENABLE)
	GUICtrlSetState($b_bindkey,$GUI_ENABLE)
	GUICtrlSetState($l_bindkey,$GUI_ENABLE)
	GUICtrlSetState($r_mtype1,$GUI_ENABLE)
	If BitAND(GUICtrlRead($c_mouseclickrecord),$GUI_CHECKED) Then
		GUICtrlSetState($c_mouseclickposrecord,$GUI_ENABLE)
	Else
		GUICtrlSetState($c_mouseclickposrecord,$GUI_DISABLE)
	EndIf
	GUICtrlSetState($r_mtype2,$GUI_ENABLE)
	GUICtrlSetState($r_mtype3,$GUI_ENABLE)
	GUICtrlSetState($c_mouseclickrecord,$GUI_ENABLE)
	GUICtrlSetState($c_mousepathrecord,$GUI_ENABLE)
	GUICtrlSetState($l_delay,$GUI_ENABLE)
	GUICtrlSetState($repeat_input,$GUI_ENABLE)
	GUICtrlSetState($l_name,$GUI_ENABLE)
	GUICtrlSetState($l_timed,$GUI_ENABLE)
	GUICtrlSetState($in_bindkey,$GUI_ENABLE)
	GUICtrlSetState($b_up,$GUI_ENABLE)
	GUICtrlSetState($b_down,$GUI_ENABLE)
	GUICtrlSetState($in_delay,$GUI_ENABLE)
	GUICtrlSetState($c_delayrecord,$GUI_ENABLE)
	If _GUICtrlListCount($Seqlist) < 1 Then 
		GUICtrlSetState($b_DeleteItem,$GUI_DISABLE)
		GUICtrlSetState($b_MoveUp,$GUI_DISABLE)
		GUICtrlSetState($b_MoveDown,$GUI_DISABLE)
	Else 
		GUICtrlSetState($b_DeleteItem,$GUI_ENABLE)
		GUICtrlSetState($b_MoveUp,$GUI_ENABLE)
		GUICtrlSetState($b_MoveDown,$GUI_ENABLE)
	EndIf
	If @Compiled Then
		ProcessSetPriority(@ScriptName, 2)
	Else
		ProcessSetPriority("AutoIt3.exe", 2) ;testing purposes
	EndIf
EndFunc ;StopRecording()==>
;=============================================================================
; Returns the key that is pressed
; Uses the KeyBoard Layout 
;=============================================================================
Func GetKeyPressed($gui)
	If $gui <> "" Then
		while 1
			for $i = 8 to 222	;Accept 102 Standard KeyBoard Input (US)
				If _IsPressed(hex($i,2)) Then
					If StringRegExp($keyboardLayout[$i],"(CTRL)|(ALT)|(SHIFT)|(WIN)") Then
						Select
						Case $gui = "editor"
							GUICtrlSetData($in_bindkey,$keyboardLayout[$i] & "+")
							Local $key = GetKeyPressed("") ;recursive call
							GUICtrlSetData($in_bindkey,$keyboardLayout[$i] & "+" & $key)
							Return GUICtrlRead($in_bindkey)
						Case $gui = "onoff"
							GUICtrlSetData($Option_in_ONOFF,$keyboardLayout[$i] & "+")
							Local $key = GetKeyPressed("") ;recursive call
							GUICtrlSetData($Option_in_ONOFF,$keyboardLayout[$i] & "+" & $key)
							Return GUICtrlRead($Option_in_ONOFF)
						Case $gui = "recstartstop"
							GUICtrlSetData($Option_in_Record,$keyboardLayout[$i] & "+")
							Local $key = GetKeyPressed("") ;recursive call
							GUICtrlSetData($Option_in_Record,$keyboardLayout[$i] & "+" & $key)
							Return GUICtrlRead($Option_in_Record)
						Case Else
						EndSelect
					EndIf
					Return $keyboardLayout[$i]
				EndIf
			Next
		wend
	Else
		while 1
			for $i = 8 to 222	;Accept 102 Standard KeyBoard Input (US)
				If _IsPressed(hex($i,2)) And StringRegExp($keyboardLayout[$i],"(CTRL)|(ALT)|(WIN)|(SHIFT)") <> 1 Then
					Return $keyboardLayout[$i]
				EndIf
			Next
		wend
	EndIf
EndFunc ;GetKeyPressed()==>
;=============================================================================
; Converts a combination of keys into notation that can be used as a HotKeySet
; ex. {SHIFT}+d => +d
; ex. {ALT}+{F2} => !{F3}
;=============================================================================
Func _ConvertToHotKeyNotation($keycombo)
	Local $combo = StringRegExpReplace(StringLower($keycombo),"(\+)","")
	$combo = StringRegExpReplace($combo,"({alt})","!")
	$combo = StringRegExpReplace($combo,"({shift})","+")
	$combo = StringRegExpReplace($combo,"({ctrl})","^")
	$combo = StringRegExpReplace($combo,"({lwin})|({rwin})","#")
	;MsgBox(0,"convert",$combo)
	Return $combo
EndFunc
;=============================================================================
; Disable all other controls when recording
;=============================================================================
Func StartRecording()
	_GUICtrlListClear($Seqlist)	; Start with clean event list
	If @Compiled Then
		ProcessSetPriority(@ScriptName, 4)
	Else
		ProcessSetPriority("AutoIt3.exe", 4) ;testing purposes
	EndIf
	GUICtrlSetData($in_hidden,"")
	GUICtrlSetState($in_hidden,$GUI_FOCUS) ;Disable all GUI controls
	GUICtrlSetState($b_bindkey,$GUI_DISABLE)
	GUICtrlSetState($c_mouseclickposrecord,$GUI_DISABLE)
	GUICtrlSetState($b_startRec,$GUI_DISABLE)
	GUICtrlSetState($b_stopRec,$GUI_ENABLE)
	GUICtrlSetState($b_OK,$GUI_DISABLE)
	GUICtrlSetState($b_Cancel,$GUI_DISABLE)
	GUICtrlSetState($b_Insert,$GUI_DISABLE)
	GUICtrlSetState($in_name,$GUI_DISABLE)
	GUICtrlSetState($b_DeleteItem,$GUI_DISABLE)
	GUICtrlSetState($l_bindkey,$GUI_DISABLE)
	GUICtrlSetState($r_mtype1,$GUI_DISABLE)
	GUICtrlSetState($r_mtype2,$GUI_DISABLE)
	GUICtrlSetState($r_mtype3,$GUI_DISABLE)
	GUICtrlSetState($l_delay,$GUI_DISABLE)
	GUICtrlSetState($repeat_input,$GUI_DISABLE)
	GUICtrlSetState($l_name,$GUI_DISABLE)
	GUICtrlSetState($l_timed,$GUI_DISABLE)
	GUICtrlSetState($in_bindkey,$GUI_DISABLE)
	GUICtrlSetState($b_up,$GUI_DISABLE)
	GUICtrlSetState($b_down,$GUI_DISABLE)
	GUICtrlSetState($in_delay,$GUI_DISABLE)
	GUICtrlSetState($b_MoveUp,$GUI_DISABLE)
	GUICtrlSetState($c_delayrecord,$GUI_DISABLE)
	GUICtrlSetState($c_mousepathrecord,$GUI_DISABLE)
	GUICtrlSetState($c_mouseclickrecord,$GUI_DISABLE)
	GUICtrlSetState($b_MoveDown,$GUI_DISABLE) ; ^^
EndFunc ;StartRecording()==>
;=============================================================================
; This is the brains of the whole keyboard recording.
; On start record disable all GUI controls and record until ESC key is pressed
; As user presses keys, each keypress is inserted into event listbox with 
; delays inserted between each keypress
;=============================================================================
Func _RecordKeyboardMacro($hWndGUI, $MsgID, $WParam, $LParam)
	Global $IsGetDelays = BitAND(GUICtrlRead($c_delayrecord),$GUI_CHECKED)
	GUICtrlSetState($in_hidden,$GUI_FOCUS)
	If _IsPressed(Hex($WParam,2)) And _ArraySearch($downlist,$WParam) = -1 And UBound($downlist) < 4 Then
		If _GUICtrlListCount($Seqlist) > 0 Then
			Local $time_between = Round(TimerDiff($time_init)/1000,2)
			If $time_between > 0.00 And $IsGetDelays Then _GUICtrlListAddItem($SeqList, $time_between & "  Delay")
		EndIf
		$time_init = TimerInit()
		_ArrayAdd($downlist,$WParam)
		_GUICtrlListAddItem($Seqlist,$keyboardLayout[Int("0x" & Hex($WParam))] & "  Hold")
		_GUICtrlListSelectIndex($Seqlist,_GUICtrlListCount($Seqlist)-1)
	ElseIf _IsPressed(Hex($WParam,2)) = 0 And _ArraySearch($downlist,$WParam) <> -1 Then ;keyboard buttons up
		Local $time_between = Round(TimerDiff($time_init)/1000,2)
		If $time_between > 0.00 And $IsGetDelays Then _GUICtrlListAddItem($SeqList, $time_between & "  Delay") 
		$time_init = TimerInit()
		DeleteArrayItemByValue($downlist, String($WParam))
		_GUICtrlListAddItem($Seqlist,$keyboardLayout[Int("0x" & Hex($WParam))] & "  Release")
		_GUICtrlListSelectIndex($Seqlist,_GUICtrlListCount($Seqlist)-1)
	EndIf
EndFunc
;=============================================================================
; This is the brains of the whole mouse recording.
; This is self explainatory... no?
;=============================================================================
Func _RecordMouseMacro($hWndGUI, $MsgID, $WParam, $LParam)
	If HWNDUnderMouse() = GUICtrlGetHandle($b_stopRec) And $MsgID = 7728  Then
		_UnHookKeyBoardMouseRecord()
		Return
	EndIf
	If $IsGetMouseClick Then
		Local $pressed = "01"
		If $MsgID - 7728 < 4 Then ;mouse button down
			$pressed = $MsgID - 7728 + 1
		ElseIf $MsgID - 7984 < 4 Then;mouse button up
			$pressed = $MsgID - 7984 + 1
		ElseIf $MsgID = 8497  Or $MsgID = 8496  Then ;mouse wheel down
			If _GUICtrlListCount($Seqlist) > 0 Then
				Local $time_between = Round(TimerDiff($time_init)/1000,2)
				If $time_between > 0.00 And $IsGetDelays Then _GUICtrlListAddItem($SeqList, $time_between & "  Delay")
			EndIf
			$time_init = TimerInit()
			If $MsgID = 8497 Then
				_GUICtrlListAddItem($Seqlist,"Mouse Wheel Down")
			ElseIf $MsgID = 8496 Then
				_GUICtrlListAddItem($Seqlist,"Mouse Wheel Up")
			EndIf
			_GUICtrlListSelectIndex($Seqlist,_GUICtrlListCount($Seqlist)-1)
			Return
		EndIf
		Global $IsGetDelays = BitAND(GUICtrlRead($c_delayrecord),$GUI_CHECKED)
		GUICtrlSetState($in_hidden,$GUI_FOCUS)
		If _IsPressed($pressed) And _ArraySearch($downlist,$pressed) = -1 And UBound($downlist) < 4 Then
			If _GUICtrlListCount($Seqlist) > 0 Then
				Local $time_between = Round(TimerDiff($time_init)/1000,2)
				If $time_between > 0.00 And $IsGetDelays Then _GUICtrlListAddItem($SeqList, $time_between & "  Delay")
			EndIf
			$time_init = TimerInit()
			_ArrayAdd($downlist,$pressed)
			If $IsGetMouseClickPos Then
				_GUICtrlListAddItem($Seqlist,$keyboardLayout[$pressed] & "  Hold" & "  (" & BitAND($LParam,0x0000FFFF) & "," & BitShift($LParam,16) & ")")
			Else
				_GUICtrlListAddItem($Seqlist,$keyboardLayout[$pressed] & "  Hold")
			Endif
			_GUICtrlListSelectIndex($Seqlist,_GUICtrlListCount($Seqlist)-1)
		ElseIf _IsPressed($pressed) = 0 And _ArraySearch($downlist,$pressed) <> -1 Then
			Local $time_between = Round(TimerDiff($time_init)/1000,2)
			If $time_between > 0.00 And $IsGetDelays Then _GUICtrlListAddItem($SeqList, $time_between & "  Delay") 
			$time_init = TimerInit()
			DeleteArrayItemByValue($downlist, $pressed)
			If $IsGetMouseClickPos Then
				_GUICtrlListAddItem($Seqlist,$keyboardLayout[$pressed] & "  Release" & "  (" & BitAND($LParam,0x0000FFFF) & "," & BitShift($LParam,16) & ")")
			Else
				_GUICtrlListAddItem($Seqlist,$keyboardLayout[$pressed] & "  Release")
			EndIf
			_GUICtrlListSelectIndex($Seqlist,_GUICtrlListCount($Seqlist)-1)
		EndIf
	EndIf
EndFunc
;=============================================================================
; Continuously inserts the mouse position into event list
;=============================================================================
Func _RecordMousePos($hWndGUI, $MsgID, $WParam, $LParam)
	If $IsGetMousePath Then
		If TimerDiff($mouse_cursor_timer) > 39 Then
			If _GUICtrlListCount($Seqlist) > 0 Then
				If TimerDiff($time_init) > 39 And $IsGetDelays Then 
					_GUICtrlListAddItem($SeqList, Round(TimerDiff($time_init)/1000,2) & "  Delay")
				EndIf
			EndIf
			$time_init = TimerInit()
			_GUICtrlListAddItem($Seqlist,"Move" & "  (" & BitAND($LParam,0x0000FFFF) & "," & BitShift($LParam,16) & ")")
			_GUICtrlListSelectIndex($Seqlist,_GUICtrlListCount($Seqlist)-1)
			$mouse_cursor_timer = TimerInit()
		EndIf
	EndIf
EndFunc
;=============================================================================
; Delete Item from Array by the value
;=============================================================================
Func DeleteArrayItemByValue(ByRef $array, $value)
	Local $count = 0
	For $i = 1 To UBound($array) - 1
		If $array[$i] = $value Then 
			$count = $i
		EndIf
	Next
	_ArrayDelete($array,$count)
EndFunc ;DeleteArrayItemByValue(ByRef $array, $value)==>
;=============================================================================
; Procrastinate until key is released (yes, i know 100% cpu usage! lol)
;=============================================================================
Func WaitTillReleased($i)
	$time_between = Round(TimerDiff($time_init)/1000,2)
	While GetKeyState($i) = 1
	Wend
	$time_init = TimerInit()
EndFunc ;WaitTillReleased($i)==>
;=============================================================================
; DLLcall to user32.dll to return keystate
; Author: Toady
;=============================================================================
Func GetKeyState($VK_Code)
    Local $a_Return = DllCall("user32.dll","short","GetKeyState","int",$VK_Code)
	If $a_Return[0] < -126 Then 
		Return 1	;Key is pressed
	Else
		Return 0 	;Key is released
	EndIf
EndFunc ;GetKeyState($VK_Code)==>
;=============================================================================
; Will return a dropdown list when Insert button of Macro editor window is 
; clicked.
;=============================================================================
Func ShowMenu($hWnd, $CtrlID, $nContextID)
    Local $hMenu = GUICtrlGetHandle($nContextID)
    $arPos = ControlGetPos($hWnd, "", $CtrlID)
    Local $x = $arPos[0]
    Local $y = $arPos[1] + $arPos[3]
    ClientToScreen($hWnd, $x, $y) ;Invoke to render dropdown on screen
    TrackPopupMenu($hWnd, $hMenu, $x, $y) ;Invoke to lock dropdown in place
EndFunc ;ShowMenu($hWnd, $CtrlID, $nContextID)==>
;=============================================================================
; Aggregate of Showmenu
;=============================================================================
Func ClientToScreen($hWnd, ByRef $x, ByRef $y)
    Local $stPoint = DllStructCreate("int;int")
    DllStructSetData($stPoint, 1, $x)
    DllStructSetData($stPoint, 2, $y)
    DllCall("user32.dll", "int", "ClientToScreen", "hwnd", $hWnd, "ptr", DllStructGetPtr($stPoint))
    $x = DllStructGetData($stPoint, 1)
    $y = DllStructGetData($stPoint, 2)
    $stPoint = 0
EndFunc ;ClientToScreen($hWnd, ByRef $x, ByRef $y)==>
;=============================================================================
; Aggregate of Showmenu
;=============================================================================
Func TrackPopupMenu($hWnd, $hMenu, $x, $y)
    DllCall("user32.dll", "int", "TrackPopupMenuEx", "hwnd", $hMenu, "int", 0, "int", $x+100, "int",$y-30, "hwnd", $hWnd, "ptr", 0)
EndFunc ;TrackPopupMenu($hWnd, $hMenu, $x, $y)==>
;=============================================================================
; Hooks keyboard by registering messages with GUI
;=============================================================================
Func _HookKeyBoardMouseRecord($gui)
	Global $IsGetDelays = BitAND(GUICtrlRead($c_delayrecord),$GUI_CHECKED)
	Global $mouse_cursor_timer = TimerInit()
	Global $IsGetMouseClick = BitAND(GUICtrlRead($c_mouseclickrecord),$GUI_CHECKED)
	Global $IsGetMousePath = BitAND(GUICtrlRead($c_mousepathrecord),$GUI_CHECKED)
	Global $IsGetMouseClickPos = BitAND(GUICtrlRead($c_mouseclickposrecord),$GUI_CHECKED)
	Global $DLLinst = DLLCall("kernel32.dll","hwnd","LoadLibrary","str",".\kh.dll")
	Global $keyHOOKproc = DLLCall("kernel32.dll","hwnd","GetProcAddress","hwnd",$DLLInst[0],"str","KeyProc")
	Global $hhKey = DLLCall("user32.dll","hwnd","SetWindowsHookEx","int",2, _
			"hwnd",$keyHOOKproc[0],"hwnd",$DLLinst[0],"int",0)
	If $IsGetMouseClick Or $IsGetMousePath Then
		Global $mouseHOOKproc = DLLCall("kernel32.dll","hwnd","GetProcAddress","hwnd",$DLLInst[0],"str","MouseProc")
		Global $hhMouse = DLLCall("user32.dll","hwnd","SetWindowsHookEx","int",7, _
				"hwnd",$mouseHOOKproc[0],"hwnd",$DLLinst[0],"int",0)
		DLLCall(".\kh.dll","int","SetValuesMouse","hwnd",$gui,"hwnd",$hhMouse[0])
		If $IsGetMouseClick Then
			GUIRegisterMsg(0x1400 + 0x0A30,"_RecordMouseMacro") ;ldown
			GUIRegisterMsg(0x1400 + 0x0A31,"_RecordMouseMacro") ;mouse
			GUIRegisterMsg(0x1400 + 0x0B30,"_RecordMouseMacro") ;mouse
			GUIRegisterMsg(0x1400 + 0x0B31,"_RecordMouseMacro") ;mouse
			GUIRegisterMsg(0x1400 + 0x0A32,"_RecordMouseMacro") ;mouse
			GUIRegisterMsg(0x1400 + 0x0B32,"_RecordMouseMacro") ;mouse
			GUIRegisterMsg(0x1400 + 0x0C30,"_RecordMouseMacro") ;mouse dbc
			GUIRegisterMsg(0x1400 + 0x0C31,"_RecordMouseMacro") ;mouse dbc
			GUIRegisterMsg(0x1400 + 0x0D30, "_RecordMouseMacro") ;mouse wheel up
			GUIRegisterMsg(0x1400 + 0x0D31, "_RecordMouseMacro") ;mouse wheel down
		EndIf
		If $IsGetMousePath Then
			GUIRegisterMsg(0x1400 + 0x0F30,"_RecordMousePos") ;mouse
		EndIf
	EndIf
	DLLCall(".\kh.dll","int","SetValuesKey","hwnd",$gui,"hwnd",$hhKey[0])
	GUIRegisterMsg(0x0400 + 0x0A30,"_RecordKeyboardMacro") ;key down
	GUIRegisterMsg(0x0400 + 0x0A31,"_RecordKeyboardMacro") ;key up
EndFunc
;=============================================================================
; Unhooks keyboard
;=============================================================================
Func _UnHookKeyBoardMouseRecord()
	If IsDeclared("hhMouse") Then
		DLLCall("user32.dll","int","UnhookWindowsHookEx","hwnd",$hhMouse[0])	
	EndIf
    DLLCall("user32.dll","int","UnhookWindowsHookEx","hwnd",$hhKey[0])
    DLLCall("kernel32.dll","int","FreeLibrary","hwnd",$DLLinst[0])
EndFunc
;=============================================================================
; Gets the handle of a control under mouse
;=============================================================================
Func HWNDUnderMouse()
    Local $point, $hwnd
    $point = MouseGetPos()
    If @error Then Return SetError(1,0,0)
    $hwnd = DLLCall("user32.dll", "hwnd", "WindowFromPoint", "int", $point[0], "int", $point[1])
    If Not @error Or $hwnd[0] <> 0 Then Return $hwnd[0]
    Return SetError(2,0,0)
EndFunc
;=============================================================================
; Moves the mouse to x,y coord
;=============================================================================
Func _MoveMouse(ByRef $x, ByRef $y)
	DllCall("user32.dll","int","SetCursorPos","int",$x,"int",$y)
EndFunc