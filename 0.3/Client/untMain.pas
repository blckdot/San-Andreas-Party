unit untMain;

interface

uses
  Windows, Registry, Messages, SysUtils, Variants, Classes, Graphics, Controls,
  Dialogs, IdBaseComponent, IdComponent, JvTimer,  XPMan, Math, TLHelp32,  MD5,
  ExtCtrls, JvBaseDlg, JvSelectDirectory, IdTCPConnection, Forms, IdTCPClient,
  ShellAPI, ComCtrls, StdCtrls, IdHTTP, Grids, DBGrids, DBCtrls;

type
  TSplitArray = array of String;
  TCommBlock = record
    Command : String[5];
    PlayerID : Byte;
    Nick : String[10];
    Mssg : String[90];
    PosX,
    PosY,
    PosZ,
    CrouchRoll1,
    XA,
    XB,
    XC,
    YA,
    YB,
    YC,
    ZA,
    ZB,
    ZC,
    SpeedX,
    SpeedY,
    SpeedZ,
    SpinX,
    SpinY,
    SpinZ,
    WheelAngle1,
    WheelAngle2,
    ExtraAngle,
    Roll1,
    Wheel1,
    Wheel2,                                              
    Wheel3,
    Wheel4 : Single;
    Active,
    Crouch,
    CrouchRoll2,
    Anim,
    Car,
    State,
    Interior,
    Roll0,
    Roll2 : Integer;
  end;
  TfrmMain = class(TForm)
    Client: TIdTCPClient;
    tmrProcess: TJvTimer;
    SelectDir: TJvSelectDirectory;
    tmrSync: TJvTimer;
    tmrGame: TJvTimer;
    HTTP: TIdHTTP;
    tmrSync2: TJvTimer;
    tmrChat: TTimer;
    tmrLoadMap: TJvTimer;
    lstWindows: TListBox;
    lstTexts: TListBox;
    Tabs: TPageControl;
    tabBrowser: TTabSheet;
    tabSettings: TTabSheet;
    lblNickname: TLabel;
    btnGameDir: TButton;
    edtNickname: TEdit;
    tabGame: TTabSheet;
    lblPlayers: TLabel;
    grpGame: TGroupBox;
    btnStartGame: TButton;
    lstChat: TMemo;
    lstPlayers: TListBox;
    edtChatText: TEdit;
    btnChatSend: TButton;
    memChat1: TMemo;
    memChat2: TMemo;
    MapCars: TMemo;
    appXPM: TXPManifest;
    lstBrowser: TListView;
    groAbout: TGroupBox;
    AboutText: TLabel;
    GroupBox1: TGroupBox;
    lblHost: TLabel;
    edtHost: TComboBox;
    edtPort: TEdit;
    lblPort: TLabel;
    lblPass: TLabel;
    edtPassword: TEdit;
    lblAdminPass: TLabel;
    edtAdminPass: TEdit;
    btnConnect: TButton;
    btnRefresh: TButton;
    btnDisconnect: TButton;
    btnDisconnect2: TButton;
    lblStatus: TLabel;
    function Writestring(offset : Longword; Text: string): Integer;
    function WriteWidestring(Offset : Longword; Text: string): Integer;
    procedure SyncWrite(CMB : TCommBlock);
    procedure Sync2Write(CMB : TCommBlock);
    procedure tmrProcessTimer(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    function CopyBetween(Source, bs, es : String): String;
    function CopyAfter(Source, bs : String): String;
    function CopyBefore(Source, bs : String): String;
    procedure GamePatch();
    procedure GameUnpatch();
    procedure btnStartGameClick(Sender: TObject);
    procedure btnGameDirClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure WriteMem(Offset: Longword; var Value; Size: Integer);
    procedure WriteMem2(Offset: Longword; var Value; Size: Integer);
    procedure ReadMem(Offset: Longword; var Value; Size: Integer);
    procedure NOP(Offset: Longword; Size: Integer);
    procedure NOPOffsets();
    procedure tmrSyncTimer(Sender: TObject);
    procedure ClientConnected(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure edtChatTextKeyPress(Sender: TObject; var Key: Char);
    procedure btnChatSendClick(Sender: TObject);
    procedure tmrGameTimer(Sender: TObject);
    procedure tmrSync2Timer(Sender: TObject);
    procedure tmrChatTimer(Sender: TObject);
    procedure tmrLoadMapTimer(Sender: TObject);
    procedure ClientDisconnected(Sender: TObject);
    procedure Log(Mssg : String);
    procedure LogIngame(Mssg : String);
    procedure btnRefreshClick(Sender: TObject);
    function GetCameraVerticalAngle(): Single;
    function GetCameraZAngle(): Single;
    function GetXInfront(Rotation, Distance : Single): Single;
    function GetYInfront(Rotation, Distance : Single): Single;
    function DoStrToInt(Str : String): Integer;
    procedure OnBrowserDoubleClick(Sender: TObject);
  private

  public
    { Public declarations }
  end;


  TClientHandleThread = class(TThread)
                         private
                          CB: TCommBlock;
                         procedure HandleInput;
                         protected
                         procedure Execute; override;
  end;

var
  frmMain: TfrmMain;

  // Booleans
  SAOn, SAOnLast, NOPped, LD, FT, Read, GO, Disconnected, PlrFreeze, Browsing,
  Detected
  : Boolean;

  // Integers
  hProc, hProc2, PlayerID, MapRow, CPLast, CPOLast, LastDeath, ML, LastShoot,
  LastLoad, LastLoad2, LastTime, LastArm, LastCrouch, NickDone, BrowserC,
  T0, T1, T2, T3, T4, T5  
  : Integer;


  // Strings
  GameDir, ServerName, IngChat, Version : String;


  // Array of Integers
  PlrShoot, PlrArmed, PlrAct, Players, Cars, Markers, Objects : Array of Integer;

  // Singles
  PlrFreeze1, PlrFreeze2, PlrFreeze3 : Single;

  // Wat overig spul
  ScriptBase : DWord = $A49960;
  PlrNick : Array of String;
  LastTick, card : Cardinal;
  ClientHandleThread : TClientHandleThread;

implementation

{$R *.dfm}

procedure CheckFile(FileName, Hash : String);
begin
  If (FileExists(GameDir+FileName)) Then
  Begin
    If Not (LowerCase(FileMD5(GameDir+FileName)) = LowerCase(Hash)) Then
      Detected := True;
  End
  Else
   Detected := True;
end;

function EnumWindowsFunc(Handle: THandle; List: TStringList) : boolean ; stdcall;
var
  caption: array[0..256] of Char;
begin
 if GetWindowText (Handle, Caption, SizeOf(Caption)-1) <> 0 then
 begin
  If (List.IndexOf(Caption) = -1) Then
    List.Add(Caption);
  //SetWindowText(Handle, PChar('About - ' + Caption)) ;
 end;

 result := True;
end;

function TfrmMain.CopyBetween(Source, bs, es : String): String;
var
  ePos : Integer;
begin
  Source := Copy(Source, Pos(bs, Source) + Length(bs), Length(Source));
  ePos := Pos(es, Source) - 1;
  result := Copy(Source, 1, ePos);
end;

function TfrmMain.CopyBefore(Source, bs : String): String;
begin
  Source := Copy(Source, 0, Pos(bs, Source)-1);
  result := Source;
end;

function TfrmMain.CopyAfter(Source, bs : String): String;
var
  ePos : Integer;
begin
  Source := Copy(Source, Pos(bs, Source) + Length(bs), Length(Source));
  ePos := Length(Source);
  result := Copy(Source, 1, ePos);
end;

function WeaponSlot(WeaponID: Integer): Integer;
var
  SlotID : Integer;
begin
  If (WeaponID = 0) Or (WeaponID = 1) Then // Slot 0
    SlotID := 0
  Else If (WeaponID = 2) Or (WeaponID = 3) Or (WeaponID = 4) Or (WeaponID = 5) Or (WeaponID = 6) Or (WeaponID = 7) Or (WeaponID = 8) Or (WeaponID = 9) Then // Slot 1
    SlotID := 1
  Else If (WeaponID = 22) Or (WeaponID = 23) Or (WeaponID = 24) Then // Slot 2
    SlotID := 2
  Else If (WeaponID = 25) Or (WeaponID = 26) Or (WeaponID = 27) Then // Slot 3
    SlotID := 3
  Else If (WeaponID = 28) Or (WeaponID = 29) Or (WeaponID = 32) Then // Slot 4
    SlotID := 4
  Else If (WeaponID = 30) Or (WeaponID = 31) Then // Slot 5
    SlotID := 5
  Else If (WeaponID = 33) Or (WeaponID = 34) Then // Slot 6
    SlotID := 6
  Else If (WeaponID = 35) Or (WeaponID = 36) Or (WeaponID = 37) Or (WeaponID = 38) Then // Slot 7
    SlotID := 7
  Else If (WeaponID = 16) Or (WeaponID = 18) Or (WeaponID = 39) Then // Slot 8
    SlotID := 8
  Else If (WeaponID = 42) Or (WeaponID = 43) Then // Slot 9
    SlotID := 9
  Else If (WeaponID = 14) Then // Slot 10
    SlotID := 10
  Else If (WeaponID = 44) Or (WeaponID = 45) Or (WeaponID = 46) Then // Slot 11
    SlotID := 11
  Else If (WeaponID = 40) Then // Slot 12
    SlotID := 12
  Else
    SlotID := 0;

  Result := SlotID;
end;

function Split(const Source, Delimiter: String): TSplitArray;
var
  iCount:     Integer;
  iPos:       Integer;
  iLength:    Integer;
  sTemp:      String;
  aSplit:     TSplitArray;
begin
  sTemp   := Source;
  iCount  := 0;
  iLength := Length(Delimiter) - 1;
  repeat
    iPos := Pos(Delimiter, sTemp);
     if iPos = 0 then
      break
    else begin
      Inc(iCount);
      SetLength(aSplit, iCount);
      aSplit[iCount - 1] := Copy(sTemp, 1, iPos - 1);
      Delete(sTemp, 1, iPos + iLength);
    end;
  until False;
  if Length(sTemp) > 0 then begin
    Inc(iCount);
    SetLength(aSplit, iCount);
    aSplit[iCount - 1] := sTemp;
  end;
  Result := aSplit;
end;

function DecimalSec(F : String): Single;
var
  tmp, Dec : String;
begin
  tmp := F;
  If (DecimalSeparator = '.') Then Dec := ',';
  If (DecimalSeparator = ',') Then Dec := '.';
  tmp := StringReplace(tmp,Dec,DecimalSeparator,[rfReplaceAll,rfIgnoreCase]);
  Try
    result := StrToFloat(tmp);
  Except
    result := 0.0;
  End;
end;

function KillTask(ExeFileName: string): Integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);

  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
      Result := Integer(TerminateProcess(
                        OpenProcess(PROCESS_TERMINATE,
                                    BOOL(0),
                                    FProcessEntry32.th32ProcessID),
                                    0));
     ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

procedure TClientHandleThread.HandleInput;
var
  I : Integer;
  F : Single;
  CommBlock : TCommBlock;
  Arr : TSplitArray;
  CPed, State, CVehicle, CPos : DWord;
  d : Cardinal;
begin
   Arr := Split('aa..aa..aa','..');
   If (CB.Command = 'SYNC') Then
     frmMain.SyncWrite(CB)
   Else If (CB.Command = 'SYNC2') Then
     frmMain.Sync2Write(CB)
   Else If (CB.Command = 'NMP') Then
     frmMain.MapCars.Lines.Add(CB.Mssg)
   Else If (CB.Command = 'OK') Then
   Begin
     If (CB.Interior = 1) Then
     Begin
       frmMain.Log('* Wrong version');
       frmMain.btnDisconnect.Click;
     End
     Else If (CB.Interior = 2) Then
     Begin
       frmMain.Log('* Wrong server password');
       frmMain.btnDisconnect.Click;
     End
     Else If (CB.Interior = 3) Then
     Begin
       frmMain.Log('* Server is full');
       frmMain.btnDisconnect.Click;
     End
     Else If (CB.Interior = 4) Then
     Begin
       frmMain.Log('* Wrong admin password or admin system is disabled');
       frmMain.btnDisconnect.Click;
     End
     Else If (CB.Interior = 5) Then
     Begin
       frmMain.Log('* You''re banned from this server');
       frmMain.btnDisconnect.Click;
     End
     Else If (CB.Interior = 6) Then
     Begin
       frmMain.Log('* Your nickname is already in use');
       frmMain.btnDisconnect.Click;
     End
     Else
     Begin
      PlayerID := CB.PlayerID; // Woohoo we hebben de ID :D
      ServerName := CB.Mssg;
      frmMain.Log('* Connected (ID: '+ IntToStr(PlayerID) +') to "'+ ServerName +'"');
      CB.Command := 'DMAP';
      CB.PlayerID := PlayerID;
      frmMain.Client.WriteBuffer(CB,SizeOf(CB),True);
     End;
   End
   Else If (CB.Command = 'MPING') Then
   Begin
     CommBlock.Command := 'MPONG';
     CommBlock.PlayerID := PlayerID;
     frmMain.Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
   End
   Else If (CB.Command = 'JOIN') Then
   Begin
     CommBlock.Command := 'JOIN2';
     CommBlock.PlayerID := PlayerID;
     CommBlock.Nick := frmMain.edtNickname.Text;
     frmMain.Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
     frmMain.lstPlayers.Items.Add(CB.Nick);
   End
   Else If (CB.Command = 'JOIN2') Then
   Begin
     If Not (frmMain.lstPlayers.Items.IndexOf(CB.Nick) >= 0) Then
       frmMain.lstPlayers.Items.Add(CB.Nick);
   End
   Else If (CB.Command = 'MSSG') Then
       frmMain.Log(CB.Nick +': '+ CB.Mssg)
   Else If (CB.Command = 'ANN') Then
       frmMain.Log(CB.Mssg)
   Else If (CB.Command = 'MON') Then
   Begin
     If (SAOn = False) Then
       Exit;
     frmMain.WriteMem($B7CE50,CB.Interior,4); // Money
   End
   Else If (CB.Command = 'DIS') Then
   Begin
     If (SAOn = False) Then
       Exit;
     frmMain.lstTexts.Items.Add(IntToStr(Round(CB.Anim/1000)) +' '+ IntToStr(CB.Roll2));
     I := frmMain.lstTexts.Items.IndexOf(IntToStr(Round(CB.Anim/1000)) +' '+ IntToStr(CB.Roll2));
     If (CB.Roll2 = 0) Then
     Begin // Orange text
       frmMain.WriteString($BAAEC0,CB.Mssg);
       T0 := I + 1;
     End
     Else If (CB.Roll2 = 1) Then
     Begin // Stunt Bonus text
       frmMain.WriteString($BAB040,CB.Mssg);
       T1 := I + 1;
     End
     Else If (CB.Roll2 = 2) Then
     Begin // Mission title
       frmMain.WriteString($BAAD40,CB.Mssg);
       T2 := I + 1;
     End
     Else If (CB.Roll2 = 3) Then
     Begin // Mission complete
       frmMain.WriteString($BAACC0,CB.Mssg);
       T3 := I + 1;
     End
     Else If (CB.Roll2 = 4) Then
     Begin // ?
       frmMain.WriteString($BAADC0,CB.Mssg);
       T4 := I + 1;
     End
     Else If (CB.Roll2 = 5) Then
     Begin // ?
       frmMain.WriteString($BAAFC0,CB.Mssg);
       T5 := I + 1;
     End;
     //frmMain.tmrTextClear.Interval := CB.Anim;
     //frmMain.tmrTextClear.Enabled := True;
   End
   Else If (CB.Command = 'LEAVE') Then
   Begin
     PlrNick[CB.PlayerID] := '';
     frmMain.lstPlayers.Items.Delete(frmMain.lstPlayers.Items.IndexOf(CB.Nick));
     I := 0;
     frmMain.WriteMem(ScriptBase + (4 * (70+(CB.PlayerID-1))),I,4); // Active
   End
   Else If (CB.Command = 'CLOSE') Then
   Begin
     frmMain.Log('* Server closed down');
     frmMain.btnDisconnect.Click;
   End
   Else If (CB.Command = 'UW') Then // Water walk etc.
   Begin
     If (SAOn = False) Then
       Exit;
     frmMain.WriteMem($6C2759,CB.Interior,1);
   End
   Else If (CB.Command = 'WH') Then // Water height
   Begin
     If (SAOn = False) Then
       Exit;
     frmMain.WriteMem($C2310C,CB.PosX,4);
   End
   Else If (CB.Command = 'WWH') Then // Water wave height
   Begin
     If (SAOn = False) Then
       Exit;
     frmMain.WriteMem($C23110,CB.PosX,4);
   End
   Else If (CB.Command = 'GRAV') Then // Gravity
   Begin
     If (SAOn = False) Then
       Exit;
     VirtualProtectEx(hProc, Pointer($863984),4,PAGE_EXECUTE_READWRITE,d);
     frmMain.WriteMem($863984,CB.PosX,4);
     VirtualProtectEx(hProc, Pointer($863984),4,d,d);
   End
   Else If (CB.Command = 'FLY') Then // Flying vehicles
   Begin
     If (SAOn = False) Then
       Exit;
     frmMain.WriteMem($969160,CB.Interior,1);
   End
   Else If (CB.Command = 'TIME') Then
   Begin
     If (SAOn = False) Then
       Exit;
     frmMain.WriteMem($B70153,CB.Interior,1); // Hour
     frmMain.WriteMem($B70152,CB.Car,1); // Minute
   End
   Else If (CB.Command = 'WEATH') Then
   Begin
     If (SAOn = False) Then
       Exit;
     frmMain.WriteMem($C81318,CB.Interior,4);
     frmMain.WriteMem($C8131C,CB.Interior,4);
     frmMain.WriteMem($C81320,CB.Interior,4);
   End
   Else If (CB.Command = 'POS') Then
   Begin
     If (SAOn = False) Then
       Exit;
     frmMain.ReadMem($B6F5F0,CPed,4);
     frmMain.ReadMem(CPed + 1328,State,4);
     If (State = 50) Then
     Begin
       frmMain.ReadMem(CPed + 1420,CVehicle,4); // Car pointer
       frmMain.ReadMem(CVehicle + 20,CPos,4);
     End
     Else
       frmMain.ReadMem(CPed + 20,CPos,4);
     frmMain.WriteMem(CPos + 48,CB.PosX,4); // Position X
     frmMain.WriteMem(CPos + 52,CB.PosY,4); // Position Y
     frmMain.WriteMem(CPos + 56,CB.PosZ,4); // Position Z
   End
   Else If (CB.Command = 'INT') Then
   Begin
     If (SAOn = False) Then
       Exit;
     frmMain.WriteMem(ScriptBase + (4 * 9),CB.Interior,4);
   End
   Else If (CB.Command = 'HT') Then
   Begin
     If (SAOn = False) Then
       Exit;
     frmMain.ReadMem($B6F5F0,CPed,4);
     frmMain.ReadMem(CPed + 1328,State,4);
     frmMain.WriteMem(CPed + 1344,CB.XA,4);
   End
   Else If (CB.Command = 'AM') Then
   Begin
     If (SAOn = False) Then
       Exit;
     frmMain.ReadMem($B6F5F0,CPed,4);
     frmMain.ReadMem(CPed + 1328,State,4);
     frmMain.WriteMem(CPed + 1352,CB.XA,4);
   End
   Else If (CB.Command = 'ROT') Then
   Begin
     If (SAOn = False) Then
       Exit;
     frmMain.ReadMem($B6F5F0,CPed,4);
     frmMain.ReadMem(CPed + 1328,State,4);
     If (State = 50) Then
       Exit;

     frmMain.WriteMem(CPed + 1372,CB.XA,4); // Rotatie in radialen
   End
   Else If (CB.Command = 'KILL') Then
   Begin
       If (SAOn = False) Then
         Exit;
       frmMain.ReadMem($B6F5F0,CPed,4);
       F := 0.0;
       frmMain.WriteMem(CPed + 1344,F,4);
       PlrFreeze := True;
   End
   Else If (CB.Command = 'FRZ') Then
   Begin
       If (SAOn = False) Then
         Exit;
       frmMain.ReadMem($B6F5F0,CPed,4);
       frmMain.ReadMem(CPed + 1328,State,4);
       If (State = 50) Then
       Begin
         frmMain.ReadMem(CPed + 1420,CVehicle,4); // Car pointer
         frmMain.ReadMem(CVehicle + 20,CPos,4);
       End
       Else
         frmMain.ReadMem(CPed + 20,CPos,4);
       frmMain.ReadMem(CPos + 48,PlrFreeze1,4); // Position X
       frmMain.ReadMem(CPos + 52,PlrFreeze2,4); // Position Y
       frmMain.ReadMem(CPos + 56,PlrFreeze3,4); // Position Z
       PlrFreeze := True;
   End
   Else If (CB.Command = 'UFRZ') Then
   Begin
     PlrFreeze := False;
   End
   Else If (CB.Command = 'KICK') Then
   Begin
     frmMain.Log('* You are kicked from the server');
     frmMain.btnDisconnect.Click;
   End
   Else If (CB.Command = 'BAN') Then
   Begin
     frmMain.Log('* You are banned from the server');
     CommBlock.Command := 'BANM';
     CommBlock.PlayerID := PlayerID;
     CommBlock.Nick := frmMain.edtNickname.Text;
     //frmMain.Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
     frmMain.btnDisconnect.Click;
   End;
end;

function TextToByte(txt: string): Byte;
var
  b : byte;
begin
  Move(txt[1], b, 1);
  result := b;
end;

function TfrmMain.WriteString(Offset : Longword; Text: String): Integer;
var
  WriteString : Byte;
  i : Integer;
begin
  For i := 1 To Length(Text) Do
  Begin
    WriteString := TextToByte(Copy(Text, i, 1));
    If (i = Length(Text)) Then
    Begin
      WriteMem(Offset + Pred(i),WriteString,1);
      WriteString := 0;
      WriteMem(Offset + Pred(i) + 1,WriteString,50);
    End
    Else
      WriteMem(Offset + Pred(i),WriteString,1);
  End;
  result := 1;
end;

function TfrmMain.WriteWideString(Offset : Longword; Text: string): Integer;
var
  WriteString : byte;
  i : integer;
begin
  result := 0;
  If (Read = False) Then
    Exit;
  For i := 1 To (Length(Text)) Do
  Begin
    WriteString:= TextToByte(Copy(Text, i, 1));
    WriteMem(Offset + (i * 2) - 2, WriteString, SizeOf(WriteString));
    result := i;
  End;

  If (Length(Text) < 128) Then
  Begin
    WriteString:= 0;
    For i := 0 To (128 - Pred(system.length(text))) Do
    Begin
      WriteMem(Offset + system.Length(Text) + i * 2,writestring,sizeof(writestring));
      result := result + 1;
    end;
  end;

  WriteString := 0;
  WriteMem(Offset + (system.Length(Text) * 2), WriteString, 1);
end;

procedure Err(Text : String);
begin
  MessageDlg(Text,mtError,[mbOk],0);
end;

function Patch(FileName, FileNameNew : String): Boolean;
begin
  If ( FileExists (FileName) ) Then
  Begin
    CopyFile(PChar(FileName),PChar(FileNameNew),False);
    result := True;
  End
  Else
    result := False;
End;

procedure TClientHandleThread.Execute;
begin
  While Not (Terminated) Do
  Begin
    If Not (frmMain.Client.Connected) Then
      Terminate
    Else
    Begin
      Try
        frmMain.Client.ReadBuffer(CB,SizeOf(TCommBlock));
        Synchronize(HandleInput);
      Except
      End;
    End;
  End;
end;

procedure TfrmMain.WriteMem2(Offset: Longword;var Value; Size: Integer);
begin
  WriteProcessMemory(hProc2, ptr(Offset),@Value, Size, card);
end;

procedure TfrmMain.WriteMem(Offset: Longword;var Value; Size: Integer);
begin
  WriteProcessMemory(hProc, ptr(Offset),@Value, Size, card);
end;

procedure TfrmMain.ReadMem(Offset: Longword;var Value; Size: Integer);
begin
  ReadProcessMemory(hProc, ptr(Offset),@Value, Size, card);
end;

procedure TfrmMain.NOP(Offset: Longword;Size: Integer);
var
  NOPValue : Byte;
  i : Integer;
begin
  If (SAOn = False) Then
    Exit;
  NOPValue := $90;
  For i := 0 To Pred(Size) Do
    WriteMem(Offset + i, NOPValue, 1);
end;

function TfrmMain.GetCameraVerticalAngle(): Single;
begin
  ReadMem($B6FA0C,result,4);
end;

function TfrmMain.GetCameraZAngle(): Single;
var
  fX, fY, fA : Single;
begin
  ReadMem($B6FA04,fX,4);
  ReadMem($B6FA08,fY,4);

	fA := arctan( fX / fY ) * 57.3;
	if ( ( fX >= 0 ) and ( fY < 0 ) ) then fA := fA - 180
	else if ( ( fX < 0 ) and ( fY < 0 ) ) then fA := fA + 180;

	if ( ( fX >= 0 ) and ( fY < 0 ) ) Then fA := fA + 360.0
	else if ( ( fX < 0 ) and ( fY >= 0 ) ) Then fA := fA + 360.0;

  result := fA;
end;

procedure TfrmMain.tmrProcessTimer(Sender: TObject);
var
  PID, i, Val, III : Integer;
  CommBlock : TCommBlock;
  Mssg : String;
begin
  If (lstTexts.Count > 0) and (SAOn = True) Then
  Begin
  For i := Pred(lstTexts.Count) DownTo 0 Do
  Begin
    If (CopyBefore(lstTexts.Items[i],' ') = '0') Then
    Begin
      Mssg := ' ';
      Val := StrToInt(CopyAfter(lstTexts.Items[i],' '));
      lstTexts.Items.Delete(i);
      III := 0;
      If (T0-1 = i) Then
      Begin
        III := 1;
      End;
      If (T1-1 = i) Then
      Begin
        III := 1;
      End;
      If (T2-1 = i) Then
      Begin
        III := 1;
      End;
      If (T3-1 = i) Then
      Begin
        III := 1;
      End;
      If (T4-1 = i) Then
      Begin
        III := 1;
      End;
      If (T5-1 = i) Then
      Begin
        III := 1;
      End;
      If (III = 1) Then
      Begin
        If (Val = 0) Then
        Begin // Orange text
          frmMain.WriteString($BAAEC0,Mssg);
        End
        Else If (Val = 1) Then
        Begin // Stunt Bonus text
          frmMain.WriteString($BAB040,Mssg);
        End
        Else If (Val = 2) Then
        Begin // Mission title
          frmMain.WriteString($BAAD40,Mssg);
        End
        Else If (Val = 3) Then
        Begin // Mission complete
          frmMain.WriteString($BAACC0,Mssg);
        End
        Else If (Val = 4) Then
        Begin // ?
          frmMain.WriteString($BAADC0,Mssg);
        End
        Else If (Val = 5) Then
        Begin // ?
          frmMain.WriteString($BAAFC0,Mssg);
        End;
        //Ce.ExecuteFunction([],CopyAfter(lstTexts.Items[i],' '));
      End;
    End
    Else
    Begin
      Val := StrToInt(CopyBefore(lstTexts.Items[i],' '))-1;
      lstTexts.Items[i] := IntToStr(Val) +' '+ CopyAfter(lstTexts.Items[i],' ');
    End;
    End;
    End;
  If (lstWindows.Count > 0) and (Client.Connected = True) Then
  Begin
    For i := 0 To Pred(lstWindows.Count) Do
      If (Pos('hack',lstWindows.Items[i]) > 0) or (Pos('exploit',lstWindows.Items[i]) > 0) or (Pos('h4x',lstWindows.Items[i]) > 0) or (Pos('cheat',lstWindows.Items[i]) > 0) or (Pos('trainer',lstWindows.Items[i]) > 0) or (Pos('s0beit',lstWindows.Items[i]) > 0) Then
      Begin
        If (SAOn = True) Then
          KillTask('gta_sa.exe');
        Err('Suspected cheating (CID: 3).');
      End;
        //Log('ID: '+ IntToStr(Pos(lstWindows.Items[i],'Party')) +' Title: '+ lstWindows.Items[i]);
  End;
  lstWindows.Clear;
  EnumWindows(Addr(EnumWindowsFunc), LParam(lstWindows.Items)) ;
  GetWindowThreadProcessId(FindWindow(nil,'SA:Party'), @PID);
  hProc := OpenProcess(PROCESS_ALL_ACCESS, False, PID);
  If (hProc > 0) Then
  Begin
    SAOn := True;
    If (SAOnLast = False) and (Client.Connected = True) Then
    Begin
      CommBlock.PlayerID := PlayerID;
      CommBlock.Command := 'GON';
      Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
    End;
    SAOnLast := True;
    If (NOPped = False) Then
    Begin
      NOPped := True;
      NOPOffsets;
    End;
    btnGameDir.Enabled := False;
    btnStartGame.Enabled := False;
{    ReadMem($00A499D0,CarSpwn,4); // Read write-able abilities
    If (CarSpwn = 2) and (GO = False) Then
    Begin
      //GO := True;
      //ML := 0;
      //LD := False;
      //FT := False;
      //LastLoad := 0;
      LogIngame('* Welcome to San Andreas Party 0.3.0.0 BETA');
      LogIngame('* Loading map... Please wait.');
      //tmrLoadMap.Enabled := True;
    End;    }
  End
  Else
  Begin
    //tmrLoadMap.Enabled := False;
    SAOn := False;
    NOPped := False;
    Read := False;
//    tmrIngChat.Enabled := False;
    If (Client.Connected = True) Then
    Begin
      btnGameDir.Enabled := True;
      btnStartGame.Enabled := True;
    End;

    If Not (SAOnLast = SAOn) Then
    Begin
      If (Client.Connected = True) Then
      Begin
        CommBlock.PlayerID := PlayerID;
        CommBlock.Command := 'GOFF';
        Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
      End;
      GameUnpatch;
      For i := Pred(MapCars.Lines.Count) DownTo 0 Do
      Begin
        If (MapCars.Lines[i] = 'unused') Then
          MapCars.Lines.Delete(i);
      End;
    End;

    SAOnLast := False;
  End;
end;

procedure TfrmMain.btnConnectClick(Sender: TObject);
var
   reg : TRegistry;
begin
  If (SAOn = True) Then
  Begin
    Err('Please close GTA:SA first!');
    Exit;
  End;
  lstPlayers.Clear;
  lstChat.Clear;
  tabGame.Show;
  edtNickname.Enabled := False;
  edtHost.Enabled := False;
  edtPort.Enabled := False;
  edtPassword.Enabled := False;
  edtAdminPass.Enabled := False;
  btnDisconnect.Enabled := False;
  btnDisconnect2.Enabled := False;
  btnConnect.Enabled := False;
  btnStartGame.Enabled := False;
  btnGameDir.Enabled := False;
  edtNickname.Text := StringReplace(edtNickname.Text, '|', '.',[rfReplaceAll, rfIgnoreCase]);
  edtNickname.Text := StringReplace(edtNickname.Text, ' ', '_',[rfReplaceAll, rfIgnoreCase]);
  edtPassword.Text := StringReplace(edtPassword.Text, '|', '.',[rfReplaceAll, rfIgnoreCase]);
  edtPassword.Text := StringReplace(edtPassword.Text, ' ', '_',[rfReplaceAll, rfIgnoreCase]);
  edtAdminPass.Text := StringReplace(edtAdminPass.Text, '|', '.',[rfReplaceAll, rfIgnoreCase]);
  edtAdminPass.Text := StringReplace(edtAdminPass.Text, ' ', '_',[rfReplaceAll, rfIgnoreCase]);
  Log('* Connecting to the server...');
  Try
    Client.Host := edtHost.Text;
    Client.Port := StrToInt(edtPort.Text);
    Client.Connect(1000);

    ClientHandleThread := TClientHandleThread.Create(True);
    ClientHandleThread.FreeOnTerminate := True;
    ClientHandleThread.Resume;
    btnDisconnect.Enabled := True;
    btnDisconnect2.Enabled := True;
    btnStartGame.Enabled := True;
    btnGameDir.Enabled := True;
    MapCars.Clear;
  Except
    edtNickname.Enabled := True;
    edtHost.Enabled := True;
    edtPort.Enabled := True;
    edtPassword.Enabled := True;
    edtAdminPass.Enabled := True;
    btnDisconnect.Enabled := False;
    btnDisconnect2.Enabled := False;
    btnConnect.Enabled := True;
    btnStartGame.Enabled := False;
    btnGameDir.Enabled := False;
    Log('* Server timed-out');
    Exit;
  End;

  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.OpenKey('Software\SA-Party', True);
    reg.WriteString('Host', edtHost.Text);
    reg.WriteString('Port', edtPort.Text);
    reg.WriteString('Nickname', edtNickname.Text);
    reg.CloseKey;
  finally
    reg.Free;
  end;

  Disconnected := False;

  Client.Socket.UseNagle := False;
end;

procedure TfrmMain.btnDisconnectClick(Sender: TObject);
var
  CommBlock : TCommBlock;
begin
  If (SAOn = True) Then
    KillTask('gta_sa.exe');
  PlrFreeze := False;
  Disconnected := True;
  lstPlayers.Clear;
  CommBlock.Command := 'LEAVE';
  CommBlock.PlayerID := PlayerID;
  CommBlock.Nick := edtNickName.Text;
  Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
  Client.Disconnect;
  ClientHandleThread.Terminate;
  Log('* Disconnected');
  edtNickname.Enabled := True;
  edtHost.Enabled := True;
  edtPort.Enabled := True;
  edtPassword.Enabled := True;
  edtAdminPass.Enabled := True;
  btnDisconnect.Enabled := False;
  btnDisconnect2.Enabled := False;
  btnConnect.Enabled := True;
  btnStartGame.Enabled := False;
  btnGameDir.Enabled := False;
  MapCars.Clear;
  tabBrowser.Show;
end;

procedure TfrmMain.btnStartGameClick(Sender: TObject);
var
  reg : TRegistry;
begin
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.OpenKeyReadOnly('Software\SA-Party');
    if (reg.ValueExists('GameDir')) then
      GameDir := reg.ReadString('GameDir')
    else
      GameDir := 'None';
    reg.CloseKey;
  finally
    reg.Free;
  end;
  
  If (GameDir = 'None') Then
  Begin
    Err('No game directory found, please set one.');
    btnGameDir.Click;
    Exit;
  End;
  If not ( FileExists( GameDir + '\gta_sa.exe' ) ) Or not ( FileExists( GameDir + '\stream.ini' ) ) Then
  Begin
    Err('No GTA: SA found in the given directory!');
    btnGameDir.Click;
    Exit;
  End;
{  If ( FileExists( GameDir + '\d3d9.dll' ) ) Then
  Begin
    Err('Suspected cheat.');
    Exit;
  End;}
  Detected := False;
  //CheckFile('data\script\main.scm', 'fcc08bbadc4f2d60f953c77dd7bd2e41');
  //CheckFile('d3d9.dll', 'bb2b0c78697795bd1e82fcadc0cbcb71');
  {CheckFile('data\water.dat', '690400ecc92169d9eaddaaa948903efb');
  CheckFile('data\handling.cfg', '6868accef933f1855ec28ce193a78159');
  CheckFile('data\water1.dat', '16fe5a3e8c57d02eb62a44a96d8b9d39');
  CheckFile('data\gta.dat', '9de4832537069d83c5a167fb9cfbbfa0');            }
  //CheckFile('data\script\script.img', '8d830155a2173e9cfb08a2a6186f42e9');
  If (Detected = True) Then
  Begin
    Err('Suspected cheating (CID: 1).');
    Exit;
  End;
  GO := False;
  GamePatch;
end;

procedure TfrmMain.GamePatch();
var
  F : String;
begin
  If not ( FileExists( GameDir + '\gta_sa.exe' ) ) Or not ( FileExists( GameDir + '\stream.ini' ) ) Then
  Begin
    Log('* Fatal error (ID: 1)');
    Exit;
  End;

  F := GameDir +'\chat.fle';
  If ( FileExists(F) ) Then
    DeleteFile(F);

  F := GameDir +'\chatbox.fle';
  If ( FileExists(F) ) Then
    DeleteFile(F);

  //Patch(GameDir + '\d3d9.dll',GameDir +'\d3d9.sapbak');

  F := GameDir +'\d3d9.dll';
  If ( FileExists(F) ) Then
    DeleteFile(F);

  F := GameDir +'\d3dx9_34.dll';
  If not ( FileExists(F) ) Then
    Patch(ExtractFilePath(Application.ExeName) + '\data\d3dx9_34.dll',GameDir +'\d3dx9_34.dll');

  Patch(GameDir + '\data\script\main.scm',GameDir +'\data\script\main.sap');
  Patch(GameDir + '\data\script\script.img',GameDir +'\data\script\script.sap');
  Patch(GameDir + '\data\script\main.scm',GameDir +'\data\script\main.sapbak');
  Patch(GameDir + '\data\script\script.img',GameDir +'\data\script\script.sapbak');

  Patch(ExtractFilePath(Application.ExeName) + '\data\main.scm',GameDir +'\data\script\main.scm');
  Patch(ExtractFilePath(Application.ExeName) + '\data\script.img',GameDir +'\data\script\script.img');
  Patch(ExtractFilePath(Application.ExeName) + '\data\chat.sap',GameDir +'\d3d9.dll');

  //Patch(ExtractFilePath(Application.ExeName) + '\data\handling.sap',GameDir +'\data\handling.cfg');
  //Patch(ExtractFilePath(Application.ExeName) + '\data\gta.sap',GameDir +'\data\gta.dat');
  //Patch(GameDir + '\data\handling.cfg',GameDir +'\data\handling.sap');
  //Patch(GameDir + '\data\handling.cfg',GameDir +'\data\handling.sapbak');

  ShellExecute(Handle,'open', 'gta_sa.exe',nil, PChar(GameDir), SW_SHOWNORMAL);

end;

procedure TfrmMain.GameUnpatch();
var
  F : String;
begin
  F := GameDir +'\data\script\main.scm';
  If ( FileExists(F) ) Then
    DeleteFile(F);

  F := GameDir +'\data\script\script.img';
  If ( FileExists(F) ) Then
    DeleteFile(F);

  Patch(GameDir +'\data\script\main.sap',GameDir +'\data\script\main.scm');

  Patch(GameDir +'\data\script\script.sap',GameDir +'\data\script\script.img');

  F := GameDir +'\data\script\main.sap';
  If ( FileExists(F) ) Then
    DeleteFile(F);

  F := GameDir +'\data\script\script.sap';
  If ( FileExists(F) ) Then
    DeleteFile(F);

  F := GameDir +'\d3d9.dll';
  while (FileExists(F)) do
    DeleteFile(F);

  F := GameDir +'\d3d9_34.dll';
  while (FileExists(F)) do
    DeleteFile(F);
end;

procedure TfrmMain.btnGameDirClick(Sender: TObject);
var
  reg : TRegistry;
begin
  If (SelectDir.Execute) Then
  Begin
    If not( FileExists( SelectDir.Directory + '\gta_sa.exe' ) ) Or not ( FileExists( SelectDir.Directory + '\stream.ini' ) ) Then
    Begin
      ShowMessage('No GTA: SA found in this directory!');
      Exit;
    End;
    reg := TRegistry.Create;
    try
      reg.RootKey := HKEY_CURRENT_USER;
      reg.OpenKey('Software\SA-Party', True);
      reg.WriteString('GameDir', SelectDir.Directory);
      reg.CloseKey;
    finally
      reg.Free;
    end;
    Log('* New GTA: SA directory set!');
  End;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  reg : TRegistry;
begin
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.OpenKeyReadOnly('Software\SA-Party');

    if (reg.ValueExists('Nickname')) then
      edtNickname.Text := reg.ReadString('Nickname')
    else
      edtNickname.Text := 'Player';

    if (reg.ValueExists('Nickname')) then
      edtHost.Text := reg.ReadString('Host')
    else
     edtHost.Text := '127.0.0.1';

    if (reg.ValueExists('Nickname')) then
      edtPort.Text := reg.ReadString('Port')
    else
      edtPort.Text := '8070';
    reg.CloseKey;
  finally
    reg.Free;
  end;



  SetLength(PlrShoot,21);
  SetLength(PlrArmed,21);
  SetLength(PlrAct,21);
  SetLength(Players,21);
  SetLength(PlrNick,21);
  SetLength(Cars,2000);
  SetLength(Objects,2000);
  SetLength(Markers,2000);
  SetLength(Players,21);
  Version := '0.3.0.0 BETA';
  frmMain.Caption := 'San Andreas Party '+Version;

  AboutText.Caption := 'San Andreas Party '+VERSION+ #13#10#13#10 +
  'Created by: Jarno "Ywa" Veuger'+ #13#10 +
  'E-mail: jarno@veuger.nl'+ #13#10 +
  'WWW: www.sa-party.com'+ #13#10#13#10 +
  'Beta testing: '+ #13#10 +
  'Sebihunter, Killerkid, UZI-I, TommyLR, SiLvEr,'+ #13#10 +'tomozj'+ #13#10#13#10 +
  'Thanks to: '+ #13#10 +
  'Mount, Sacky, JGuntherS, Peter, VRocker, '+ #13#10 +
  'AlienX, MrJax, mabako, Fl@sh'+ #13#10;

end;

procedure TfrmMain.NOPOffsets();
var
  Int : Integer;
begin
  NOP($438480,5); // Block cheats
  NOP($5DEC04,6); // Walk/Run animations
  //NOP($6E0A3B,6); // Car horn
  NOP($43828F,6); // Steering angle 2???
  //NOP($561AF0,6); // Pauze ga door
  //NOP($53E799,7);
  NOP($588FA9,6);
  //NOP($58AA6F,2); // Zone-name texts
  NOP($58905E,6);
  NOP($69DBB8,3);
  // New game skip
  NOP($53E799,7);
  NOP($576C34,3);
  NOP($576C41,4);
  NOP($53C090,5); // Replay uitzetten
  Int := 235;
  WriteMem($434237,Int,1);
  //NOP($58EC21,5); // Klok uitzetten / Niet displayen
{  Int := 100;
  WriteMem($8D5E50 + (4 * 1),Int,4);
  Text := 'SAP';
  Offset := $866CFC;
  For i := 1 To 12 Do
  Begin
    WriteString := TextToByte(Copy(Text, i, 1));
    If (i > Length(Text)) Then
    Begin
      WriteString := 0;
      WriteMem(Offset + Pred(i),WriteString,1);
    End
    Else
      WriteMem(Offset + Pred(i),WriteString,1);
  End;}
end;

procedure TfrmMain.tmrSyncTimer(Sender: TObject);
var
  CPed, CPos, CVehicle, DW, Swim : DWord;
  CommBlock : TCommBlock;
  I, I2 : Integer;
  F1, F2 : Single;
begin
  If (Client.Connected = False) or (SAOn = False) or (Read = False) Then
    Exit;

  ReadMem(ScriptBase + (4 * 1),CommBlock.Active,4); // Active

  ReadMem($B6F5F0,CPed,4);

  //Log('Player: '+ IntToStr(CPed));

  ReadMem(CPed + 1328,CommBlock.State,4); // State (Walking, Driving)

  ReadMem(ScriptBase + (4 * 14),I,4); // CPOut
  If (I > 0) And Not (I > 50) And Not (CPOLast = I) Then
  Begin
    CPOLast := I;
    CPLast := 0;
    CommBlock.Command := 'CPOUT';
    CommBlock.PlayerID := PlayerID;
    CommBlock.Interior := I;
    Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
    CommBlock.Interior := 0;
    I := 0;
    WriteMem(ScriptBase + (4 * 14),I,4);
  End;

  ReadMem(ScriptBase + (4 * 13),I,4); // CPIn
  If Not (I = CPLast) And Not(I = 0) And Not (I > 50) Then
  Begin
    CPLast := I;
    CPOLast := 0;
    CommBlock.Command := 'CPIN';
    CommBlock.PlayerID := PlayerID;
    CommBlock.Interior := I;
    Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
    CommBlock.Interior := 0;
  End;

  ReadMem(ScriptBase + (4 * 0),CommBlock.Car,4); // Player Car
  ReadMem(ScriptBase + (4 * 2),I,4); // Passenger
  If (I = 1) Then
    CommBlock.Car := CommBlock.Car + 2000
  Else If (I = 2) Then
    CommBlock.Car := CommBlock.Car + 4000
  Else If (I = 3) Then
    CommBlock.Car := CommBlock.Car + 6000;
  If (CommBlock.Car = 2000) or (CommBlock.Car = 4000) or (CommBlock.Car = 6000) Then
    Exit; // CommBlock.Car = 0
  If (CommBlock.State = 50) Then
  Begin
    ReadMem(CPed + 1420,CVehicle,4); // Car pointer
    ReadMem(CVehicle + 20,CPos,4);
  End
  Else
    ReadMem(CPed + 20,CPos,4);


  If (PlrFreeze = True) Then
  Begin
    WriteMem(CPos + 48,PlrFreeze1,4);
    WriteMem(CPos + 52,PlrFreeze2,4);
    WriteMem(CPos + 56,PlrFreeze3,4);
  End;

  ReadMem(CPos + 48,CommBlock.PosX,4); // Position X

  ReadMem(CPos + 52,CommBlock.PosY,4); // Position Y

  ReadMem(CPos + 56,CommBlock.PosZ,4); // Position Z

  If (CommBlock.State = 1) Then
  Begin
    ReadMem(CPed + 1372,CommBlock.XA,4); // Rotatie in radialen

    ReadMem(CPed + 1344,CommBlock.XC,4); // Health

    ReadMem(CPed + 1352,CommBlock.YA,4); // Armor

    //ReadMem(CPed + 1372,CommBlock.YB,4); // Target rotation

    If (PlrFreeze = True) Then
    Begin
      CommBlock.Anim := 1;
      WriteMem(CPed + 1332,CommBlock.Anim,4);
    End
    Else
      ReadMem(CPed + 1332,CommBlock.Anim,4); // Ren animatie
    ReadMem(CPed + 1247,I,1); // Animatie play state?!
    CommBlock.Mssg := IntToStr(I);
    If (CommBlock.Anim = 6) And (I = 61) Then CommBlock.Anim := 4;
{ DWORD* dwAnimPointer = ( DWORD* ) ( ( *m_dwPlrPointer ) + ( m_iID * 1988 ) + 0x47C );
	DWORD* dwSwimPointer = ( DWORD* ) ( ( *dwAnimPointer ) + 0xC );
	DWORD* dwSwimDataPointer = ( DWORD* ) ( ( *dwSwimPointer ) + 0x8 );
	return * ( BYTE* ) ( ( *dwSwimDataPointer ) + 0xA ); }

    ReadMem(CPed + $47C,Swim,4);
    ReadMem(Swim + $C,Swim,4);
    ReadMem(Swim + $8,Swim,4);
    ReadMem(Swim + $A,Swim,1); // Uiteindelijke waarde
    {If (Swim = 1) or (Swim = 2) Then
      CommBlock.PosZ := 0.0;}
    CommBlock.Mssg := CommBlock.Mssg +'|'+ IntToStr(Swim);
    
    ReadMem(ScriptBase + (4 * 8),CommBlock.Crouch,4); // Holding weapon

    ReadMem(ScriptBase + (4 * 7),CommBlock.XB,4); // Rotatie in graden (Inversed)
    //ReadMem(CPed + 1332,CommBlock.CrouchRoll2,4); // Shooting
    {ReadMem(CPed + 1440 + (WeaponSlot(CommBlock.Crouch) * 28) + 4,CommBlock.CrouchRoll2,4); // Shooting-state
    If (CommBlock.CrouchRoll2 = 2) or (CommBlock.CrouchRoll2 = 1) Then // Reloading or shooting
    Begin
      LastShoot := 1;
      CommBlock.CrouchRoll2 := 1;
    End
    Else If (CommBlock.CrouchRoll2 = 0) and (LastTime > 6) Then
    Begin
      LastShoot := 2;
      LastTime := 0;
      CommBlock.CrouchRoll2 := 2;
    End
    Else If (CommBlock.CrouchRoll2 = 0) and (LastShoot = 1) Then
    Begin
      LastShoot := 1;
      LastTime := LastTime + 1;
      CommBlock.CrouchRoll2 := 1;
    End
    Else
    Begin
      LastShoot := 2;
      LastTime := 0;
      CommBlock.CrouchRoll2 := 2;
    End;  }
    ReadMem(CPed + 1148,DW,4); // Animation structure // DWord
    ReadMem(DW + 24,DW,4); // Fight animation structure // DWord
    ReadMem(DW + 16,CommBlock.CrouchRoll2,1);
    // 1 = Targeting
    // 2 = Shooting
    // 3 = ???
    // 4 = Reloading
    If (CommBlock.CrouchRoll2 = 4) Then
      CommBlock.CrouchRoll2 := 1;

    If (CommBlock.CrouchRoll2 = 1) or (CommBlock.CrouchRoll2 = 2) Then
    Begin
      ReadMem(DW + 20,CommBlock.YB,4); // Float
      ReadMem(DW + 24,CommBlock.YC,4); // Float
      CommBlock.SpinX := GetCameraVerticalAngle;
      //ReadMem($B6F99C + 56,CommBlock.ZA,4); // PosZ aiming? (Verouderd gok ik)
    End;
    
    If (CommBlock.Crouch = LastArm) Then
      CommBlock.Crouch := -1
    Else
      LastArm := CommBlock.Crouch;

    //lstChat.Lines.Add('Shoot: '+ IntToStr(CommBlock.CrouchRoll2));

    ReadMem(CPed + 1135,I,1); // Bukken
    If (I = 132) Then
      I := 1
    Else
      I := 0;
    If Not (I = LastCrouch) Then
      LastCrouch := I
    Else
      I := -1;

    If (LastCrouch = 1) Then
    Begin
      ReadMem(CPed + 1148,DW,4); // Animation structure // DWord
      ReadMem(DW + 28,DW,4); // Crouch animation structure // DWord
      ReadMem(DW + 31,I2,1); // Byte
      ReadMem(DW + 32,F1,4); // Float
    End;

    CommBlock.Mssg := CommBlock.Mssg +'|'+ IntToStr(I) +'|'+ IntToStr(I2) +'|'+ FloatToStr(F1);
  End
  Else If (CommBlock.State = 50) and (CommBlock.Car < 2000) Then
  Begin
    ReadMem(CPos + 0,CommBlock.XA,4); // XA
    ReadMem(CPos + 4,CommBlock.XB,4); // XB
    ReadMem(CPos + 8,CommBlock.XC,4); // XC
    ReadMem(CPos + 12,CommBlock.YA,4); // YA
    ReadMem(CPos + 16,CommBlock.YB,4); // YB
    ReadMem(CPos + 20,CommBlock.YC,4); // YC
    ReadMem(CPos + 24,CommBlock.ZA,4); // ZA
    ReadMem(CPos + 28,CommBlock.ZB,4); // ZB
    ReadMem(CPos + 32,CommBlock.ZC,4); // ZC

    If (PlrFreeze = True) Then
    Begin
      CommBlock.SpeedX := 0;
      CommBlock.SpeedY := 0;
      CommBlock.SpeedZ := 0;
      CommBlock.SpinX := 0;
      CommBlock.SpinY := 0;
      CommBlock.SpinZ := 0;
      WriteMem(CVehicle + 68,CommBlock.SpeedX,4); // Speed X
      WriteMem(CVehicle + 72,CommBlock.SpeedY,4); // Speed Y
      WriteMem(CVehicle + 76,CommBlock.SpeedZ,4); // Speed Z
      WriteMem(CVehicle + 80,CommBlock.SpinX,4); // Spin X
      WriteMem(CVehicle + 84,CommBlock.SpinY,4); // Spin Y
      WriteMem(CVehicle + 88,CommBlock.SpinZ,4); // Spin Z
    End
    Else
    Begin
      ReadMem(CVehicle + 68,CommBlock.SpeedX,4); // Speed X
      ReadMem(CVehicle + 72,CommBlock.SpeedY,4); // Speed Y
      ReadMem(CVehicle + 76,CommBlock.SpeedZ,4); // Speed Z
      ReadMem(CVehicle + 80,CommBlock.SpinX,4); // Spin X
      ReadMem(CVehicle + 84,CommBlock.SpinY,4); // Spin Y
      ReadMem(CVehicle + 88,CommBlock.SpinZ,4); // Spin Z
    End;

    ReadMem(CVehicle + 2020,CommBlock.Wheel1,4); // Wheel 1 suspension
    ReadMem(CVehicle + 2024,CommBlock.Wheel2,4); // Wheel 2 suspension
    ReadMem(CVehicle + 2028,CommBlock.Wheel3,4); // Wheel 3 suspension
    ReadMem(CVehicle + 2032,CommBlock.Wheel4,4); // Wheel 4 suspension

    ReadMem(CVehicle + 1172,CommBlock.WheelAngle1,4); // Wheel angle 1
    ReadMem(CVehicle + 1176,CommBlock.WheelAngle2,4); // Wheel angle 2
    ReadMem(CVehicle + 2156,CommBlock.ExtraAngle,4); // Extra angle
    ReadMem(CVehicle + 1216,CommBlock.CrouchRoll1,4); // Health
    ReadMem(CVehicle + 152,CommBlock.Roll1,4); // G Force
    //ReadMem(CVehicle + 2276,CommBlock.CrouchRoll1,4); // Fire

    ReadMem(ScriptBase + (4 * 15),Swim,4); // Paintjob
    If (Swim > 5) Then
      Swim := 0;
    CommBlock.Mssg := IntToStr(Swim);

    ReadMem(CVehicle + $37C,Swim,4);
    If (Swim > 100) Then
      Swim := 0;
    CommBlock.Mssg := CommBlock.Mssg +'|'+ IntToStr(Swim);

    ReadMem(CVehicle + $48A,Swim,4);
    If (Swim > 100) Then
      Swim := 0;
    CommBlock.Mssg := CommBlock.Mssg +'|'+ IntToStr(Swim);

    ReadMem(CVehicle + 1180,F1,4); // Gas pedal
    ReadMem(CVehicle + 1184,F2,4); // Break pedal
{    If (F1 = 1.0) And (F2 = 1.0) Then I := 9
    Else If (F2 > 0.0) Then I := 1
    Else If (F1 > 0.0) Then I := 9
    Else If (CommBlock.SpeedX > 0.0) Or (CommBlock.SpeedY > 0.0) Or (CommBlock.SpeedZ > 0.0) Then I := 9
    Else If (CommBlock.SpeedX = 0.0) And (CommBlock.SpeedY = 0.0) And (CommBlock.SpeedZ = 0.0) Then I := 15
    Else I := 9;}

{ 	float fX = vPedals.fX, fY = vPedals.fY;
	if ( fX == 1.0f && fY == 0.0f || fX == 1.0f && fY == 1.0f) SetAnimation ( 9 );
	else if ( fX == 0.0f && fY == 0.0f )
	{
		if ( GetSpeeds ().fX != 0.0f ) SetAnimation ( 9 );
		else SetAnimation ( 15 );
	}{
	else if ( fX == -1.0f && fY == 0.0f ) SetAnimation ( 3 );
	else SetAnimation ( 15 ); }
    If ((F1 = 1.0) and (F2 = 0.0)) or ((F1 = 1.0) and (F2 = 1.0)) Then I := 9
    Else If (F1 = 0.0) and (F2 = 0.0) Then
    Begin
      If not (CommBlock.SpeedX = 0.0) Then I := 9
      Else I := 15;
    End
    Else If (F1 = -1.0) and (F2 = 0.0) Then I := 3
    Else I := 15;

    CommBlock.Anim := I;
  End;

  CommBlock.Command := 'SYNC';
  CommBlock.PlayerID := PlayerID;
  Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
  //Log('>>> PACKET SEND!');
end;

procedure TfrmMain.SyncWrite(CMB : TCommBlock);
var
  CPed, CPos, CVehicle, State, CDummy, CDPos, DW, I : Integer;
  F, Rad, Distance : Single;
  Arr : TSplitArray;
begin
  Arr := Split('a|a|a','|');
  If (SAOn = False) or (Read = False) Then
    Exit;

  //Log('>>> Packet');

  WriteMem(ScriptBase + (4 * (70+(CMB.PlayerID-1))),CMB.Active,4); // Active

  WriteMem(ScriptBase + (4 * (50+(CMB.PlayerID-1))),CMB.Car,4);

  {If (CMB.Car > 0) Then
    Log('>>> '+ IntToStr(CMB.Car));}

  //ReadMem(ScriptBase + (4 * (170+(CMB.PlayerID-1))),CPed,4);
  //Log(IntToStr(CPed));
  If (CMB.Active = 0) or (CMB.Car > 1999) Then
    Exit;

  ReadMem($B6F5F0,CPed,4);
  CPed := CPed + (1988 * CMB.PlayerID);
  ReadMem(CPed + 1328,State,4); // State (Driving etc.)

  If (State = 50) and (CMB.State = 50) Then
  Begin
    ReadMem(CPed + 1420,CVehicle,4); // Vehicle pointer
    ReadMem(CVehicle + 20,CPos,4);
  End
  Else
    ReadMem(CPed + 20,CPos,4);

  WriteMem(CPos + 48,CMB.PosX,4);

  WriteMem(CPos + 52,CMB.PosY,4);

  WriteMem(CPos + 56,CMB.PosZ,4);

  If (State = 1) And (CMB.State = 1) Then
  Begin
    Arr := Split(CMB.Mssg,'|');
    WriteMem(CPed + 1328,CMB.State,4); // State

    WriteMem(CPed + 1344,CMB.XC,4); // Health

    I := DoStrToInt(Arr[0]);
    WriteMem(CPed + 1247,I,1); // Animatie play state?!
    WriteMem(CPed + 1332,CMB.Anim,4); // Run animation

    WriteMem(CPed + 1352,CMB.YA,4); // Armor

{    I := DoStrToInt(Arr[1]);
    If (I > 0) Then
    Begin
      F1 := CMB.PosX + GetXInfront(CMB.XB,10.0);
      F2 := CMB.PosY + GetYInfront(CMB.XB,10.0);
      If (I = 1) or (I = 4) Then  F3 := 1.0
      Else If (I = 2) Then F3 := 2.2
      Else F3 := 0.0;
      {If (I = 4) Then
      Begin

      End;
      WriteMem(ScriptBase + (4 * (190+(CMB.PlayerID-1))),F3,4);
      WriteMem(ScriptBase + (4 * (210+(CMB.PlayerID-1))),F1,4);
      WriteMem(ScriptBase + (4 * (230+(CMB.PlayerID-1))),F2,4);
    End
    Else
    Begin
      F3 := 0.0;
      WriteMem(ScriptBase + (4 * (190+(CMB.PlayerID-1))),F3,4);
    End; }

    I := DoStrToInt(Arr[2]);
    If (I > -1) Then
      WriteMem(ScriptBase + (4 * (270+(CMB.PlayerID-1))),I,4);
    ReadMem(CPed + 1148,DW,4);
    ReadMem(DW + 28,DW,4);
    I := DoStrToInt(Arr[3]);
    WriteMem(DW + 31,I,1);
    F := DecimalSec(Arr[4]);
    WriteMem(DW + 32,F,4);

    //WriteMem(CPed + 1372,CMB.YB,4); // Target rotation

    If (CMB.Crouch > -1) Then // Armed weapon
    Begin
      PlrArmed[CMB.PlayerID] := CMB.Crouch;
      WriteMem(ScriptBase + (4 * (150+(CMB.PlayerID-1))),CMB.Crouch,4);
    End;

    If not (CMB.CrouchRoll2 = 1) and not (CMB.CrouchRoll2 = 2) Then
    Begin
      WriteMem(ScriptBase + (4 * (290+(CMB.PlayerID-1))),CMB.XB,4); // Rotation (Via SCM)
      //WriteMem(CPed + 1372,CMB.XA,4); // Rotation
      //WriteMem(CPed + 1372,CMB.XA,4); // Rotation

      //WriteMem(CPed + 1332,CMB.Anim,4); // Run animation

      {I := DoStrToInt(Arr[0]);
      WriteMem(CPed + 1247,I,1); // Animatie play state?!
      WriteMem(CPed + 1332,CMB.Anim,4); // Run animation}

      //CMB.CrouchRoll2 := 0;


      If not (PlrShoot[CMB.PlayerID] = CMB.CrouchRoll2) Then
      Begin
        PlrShoot[CMB.PlayerID] := CMB.CrouchRoll2;
        CMB.CrouchRoll2 := -1;
        WriteMem(ScriptBase + (4 * (130+(CMB.PlayerID-1))),CMB.CrouchRoll2,4);
        ReadMem($B6F5F0,CDummy,4);
        CDummy := CDummy + (1988 * (CMB.PlayerID+20));
        ReadMem(CDummy + 20,CDPos,4);

        F := 0.0;
        WriteMem(CDPos + 48,F,4);

        F := 10.0;
        WriteMem(CDPos + 52,F,4);

        F := 1500.0;
        WriteMem(CDPos + 56,F,4);
      End;
{      Else
      Begin
        CMB.CrouchRoll2 := 0;
        WriteMem(ScriptBase + (4 * (130+(CMB.PlayerID-1))),CMB.CrouchRoll2,4);
      End;}
    End
    Else
    Begin
      //I := DoStrToInt(Arr[0]);
      //WriteMem(CPed + 1247,I,1); // Animatie play state?!
      //CMB.Anim := 0;
      //WriteMem(CPed + 1332,CMB.Anim,4); // Run animation
      
      ReadMem($B6F5F0,CDummy,4);
      CDummy := CDummy + (1988 * (CMB.PlayerID+20));
      ReadMem(CDummy + 20,CDPos,4);

      //ShowMessage(FloatToStr(RadToDeg(-1.57)+360)); // ~270 graden
      //ShowMessage(FloatToStr(RadToDeg(1.57))); // ~90 graden

      //If (CMB.XA < 0) Then
      //  Rad := CMB.XA * -1
      //Else If (CMB.XA > 0) Then
      //  Rad := (CMB.XA * -1) + (2 * PI)
      //Else
      //  Rad := 0;
      //Rad := Rad * (360 / (2 * PI));
      //Log(FloatToStr(CMB.XB));
      //If (PlrArmed[CMB.PlayerID] = 9) Or (PlrArmed[CMB.PlayerID] = 42) Then
      //  Distance := 3.0
     // Else
      //  Distance := 9.0;
      //If (PlrArmed[CMB.PlayerID] > 0) and (PlrArmed[CMB.PlayerID] < 14) Then
      //  Distance := 1.0
      //Else
      //  Distance := 5.0;
      Distance := 15.0;
      //  Distance := 5.0;
      ReadMem(CPed + 1148,DW,4); // Animation structure // DWord
      ReadMem(DW + 24,DW,4); // Fight animation structure // DWord
      WriteMem(DW + 20,CMB.YB,4); // Float
      WriteMem(DW + 24,CMB.YC,4); // Float
      
      If (CMB.XB > 180) Then
        Rad := CMB.XB - 180
      Else
        Rad := CMB.XB + 180;
      Rad := DegToRad(Rad - 90);
      F := CMB.PosX + (cos(Rad) * Distance);
      WriteMem(CDPos + 48,F,4);

      F := CMB.PosY + (sin(Rad) * Distance);
      WriteMem(CDPos + 52,F,4);

      //F := (CMB.PosZ + ((CMB.ZA-20) * -1.25)) - 50.0;
      //F := CMB.PosZ - 50.0;
      F := (CMB.PosZ + (CMB.SpinX * 3.0)) - 50.0;
      WriteMem(CDPos + 56,F,4);

      //If not (PlrShoot[CMB.PlayerID] = CMB.CrouchRoll2) or (CMB.CrouchRoll2 = 1) Then
      //Begin
        PlrShoot[CMB.PlayerID] := CMB.CrouchRoll2;
        WriteMem(ScriptBase + (4 * (130+(CMB.PlayerID-1))),CMB.CrouchRoll2,4);
      //End;
    End;
  End
  Else If (State = 50) And (CMB.State = 50) And (CMB.Car < 2000) Then
  Begin
    Arr := Split(CMB.Mssg,'|');
    WriteMem(CPed + 1328,State,4); // State (Driving etc.)
{
    WriteMem(CPos + 0,CMB.XA,4);

    WriteMem(CPos + 4,CMB.XB,4);

    WriteMem(CPos + 8,CMB.XC,4);

    WriteMem(CPos + 16,CMB.YA,4);

    WriteMem(CPos + 20,CMB.YB,4);

    WriteMem(CPos + 24,CMB.YC,4);

    WriteMem(CPos + 32,CMB.ZA,4); // ZA

    WriteMem(CPos + 36,CMB.ZB,4); // ZB

    WriteMem(CPos + 40,CMB.ZC,4); // ZC   }

    WriteMem(CPos + 0,CMB.XA,4);

    WriteMem(CPos + 4,CMB.XB,4);

    WriteMem(CPos + 8,CMB.XC,4);

    WriteMem(CPos + 12,CMB.YA,4);

    WriteMem(CPos + 16,CMB.YB,4);

    WriteMem(CPos + 20,CMB.YC,4);

    WriteMem(CPos + 24,CMB.ZA,4); // ZA

    WriteMem(CPos + 28,CMB.ZB,4); // ZB

    WriteMem(CPos + 32,CMB.ZC,4); // ZC

    WriteMem(ScriptBase + (4 * (40+(CMB.PlayerID-1))),CMB.Anim,4); // Speed / animation

    WriteMem(CVehicle + 1172,CMB.WheelAngle1,4);

    WriteMem(CVehicle + 1176,CMB.WheelAngle2,4);

    WriteMem(CVehicle + 68,CMB.SpeedX,4);

    WriteMem(CVehicle + 72,CMB.SpeedY,4);

    WriteMem(CVehicle + 76,CMB.SpeedZ,4);

    WriteMem(CVehicle + 80,CMB.SpinZ,4);

    WriteMem(CVehicle + 84,CMB.SpinY,4);

    WriteMem(CVehicle + 88,CMB.SpinZ,4);

    WriteMem(CVehicle + 152,CMB.Roll1,4); // G Force

    WriteMem(CVehicle + 2020,CMB.Wheel1,4); // Wheel 1 suspension
    WriteMem(CVehicle + 2024,CMB.Wheel2,4); // Wheel 2 suspension
    WriteMem(CVehicle + 2028,CMB.Wheel3,4); // Wheel 3 suspension
    WriteMem(CVehicle + 2032,CMB.Wheel4,4); // Wheel 4 suspension

    WriteMem(CVehicle + 1216,CMB.CrouchRoll1,4); // Health

    //WriteMem(CVehicle + 2276,CMB.CrouchRoll1,4); // Fire

    WriteMem(CVehicle + 2156,CMB.ExtraAngle,4);

    I := DoStrToInt(Arr[0]);
    WriteMem(ScriptBase + (4 * (250+(CMB.PlayerID-1))),I,4);

    I := DoStrToInt(Arr[1]);
    WriteMem(CVehicle + $37C,I,1);

    I := DoStrToInt(Arr[2]);
    WriteMem(CVehicle + $48A,I,1);
  End;
end;

procedure TfrmMain.tmrSync2Timer(Sender: TObject);
var
  CPed, CVehicle : DWord;
  CommBlock : TCommBlock;
begin
  If (Client.Connected = False) or (SAOn = False) or (Read = False) Then
    Exit;

  ReadMem($B6F5F0,CPed,4);

  ReadMem(CPed + 1328,CommBlock.State,4); // State (Walking, Driving)

  ReadMem(ScriptBase + (4 * 0),CommBlock.Car,4); // Player Car
  If (CommBlock.Car > 1999) Then
    Exit;

  ReadMem($B7CE50,CommBlock.Roll2,4); // Money

  If (CommBlock.State = 1) Then
  Begin
    ReadMem(CPed + 47,CommBlock.Interior,1); // Interior
  End
  Else If (CommBlock.State = 50) Then
  Begin
    ReadMem(CPed + 1420,CVehicle,4); // Car pointer

    ReadMem(CVehicle + 2156,CommBlock.XA,4); // Plane 1

    ReadMem(CVehicle + 2508,CommBlock.XB,4); // Plane 2

    ReadMem(CVehicle + 2560,CommBlock.Interior,1); // Plane 3

    ReadMem(CVehicle + 1076,CommBlock.Roll0,1); // Car color 1

    ReadMem(CVehicle + 1077,CommBlock.Car,1); // Car color 2

    //ReadMem(ScriptBase + (4 * 3),CommBlock.CrouchRoll2,4); // Paintjob

    ReadMem(CVehicle + 1069,CommBlock.Anim,1); // Siren

{    ReadMem(CVehicle + 1445,CommBlock.Shot1,1);
    ReadMem(CVehicle + 1446,CommBlock.Shot2,1);
    ReadMem(CVehicle + 1447,CommBlock.Shot3,1);
    ReadMem(CVehicle + 1448,CommBlock.Shot4,1);
    ReadMem(CVehicle + 1628,CommBlock.Shot5,1);
    ReadMem(CVehicle + 1629,CommBlock.Shot6,1);}
  End;

  CommBlock.Command := 'SYNC2';
  CommBlock.PlayerID := PlayerID;

  Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
end;

procedure TfrmMain.Sync2Write(CMB : TCommBlock);
var
  CPed, CVehicle, State : DWord;
begin
  If (SAOn = False) or (Read = False) Then
    Exit;

  ReadMem($B6F5F0,CPed,4);
  //ReadMem(ScriptBase + (4 * (170+(CMB.PlayerID-1))),CPed,4);
  CPed := CPed + (1988 * CMB.PlayerID);
{  If (ID = -1) Then
  Begin
    lstNameTags.Items.Add(CMB.Nick);
    lstNameTags.Items.Add(SCMID);
  End
  Else
  Begin
    ID := ID + 1;
    lstNameTags.Items[ID] := SCMID;
  End;}
  ReadMem(CPed + 1328,State,4); // State (Driving etc.)

  If (State = 1) and (CMB.State = 1) Then
  Begin
    WriteMem(ScriptBase + (4 * (90+(CMB.PlayerID-1))),CMB.Interior,4);
  End
  Else If (State = 50) and (CMB.State = 50) Then
  Begin
    ReadMem(CPed + 1420,CVehicle,4); // Vehicle pointer

    WriteMem(CVehicle + 2156,CMB.XA,4); // Plane 1

    WriteMem(CVehicle + 2508,CMB.XB,4); // Plane 2

    WriteMem(CVehicle + 2560,CMB.Interior,1); // Plane 3

    WriteMem(CVehicle + 1076,CMB.Roll0,1); // Car color 1

    WriteMem(CVehicle + 1077,CMB.Car,1); // Car color 2

    //WriteMem(ScriptBase + (4 * (110+(CMB.PlayerID-1))),CMB.CrouchRoll2,4); // Paintjob
    WriteMem(CVehicle + 1069,CMB.Anim,1); // Siren

{    WriteMem(CVehicle + 1445,CMB.Shot1,1);
    WriteMem(CVehicle + 1446,CMB.Shot2,1);
    WriteMem(CVehicle + 1447,CMB.Shot3,1);
    WriteMem(CVehicle + 1448,CMB.Shot4,1);
    WriteMem(CVehicle + 1628,CMB.Shot5,1);
    WriteMem(CVehicle + 1629,CMB.Shot6,1);}
  End;
end;

procedure TfrmMain.ClientConnected(Sender: TObject);
var
  CommBlock : TCommBlock;
  Pass1, Pass2 : String;
begin
  If (Browsing = True) Then
    Exit;

  CommBlock.Command := 'JOIN';
  CommBlock.PlayerID := 0;
  CommBlock.Interior := 13;
  Pass1 := LowerCase(strMD5(edtPassword.Text)); // MD5 ftw
  Pass2 := LowerCase(strMD5(edtAdminPass.Text)); // MD5 ftw
  CommBlock.Nick := edtNickname.Text;
  CommBlock.Mssg := Pass1 +'|'+ Pass2;
  Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
  lstPlayers.Items.Add(edtNickname.Text);
end;


procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  If (SAOn = True) Then
    KillTask('gta_sa.exe');
  If (Client.Connected = True) Then
    btnDisconnect.Click;
end;

procedure TfrmMain.edtChatTextKeyPress(Sender: TObject; var Key: Char);
begin
  If (Key = #13) Then
  Begin
    Key := #0;
    btnChatSend.Click;
  End;
end;

procedure TfrmMain.btnChatSendClick(Sender: TObject);
var
  CommBlock : TCommBlock;
  Now : String;
  Arr : TSplitArray;
begin
  Arr := Split('a|a|a','|');
  If not (Client.Connected = True) Then
    Exit;

  If not (edtChatText.Text <> '') and not (IngChat <> '') Then
    Exit;

  If not ( IngChat = '' ) Then
  Begin
    Now := IngChat;
  End
  Else
    Now := edtChatText.Text;
  If ( Length(Now) > 80 ) Then
  Begin
    Log('* Your chat message is too long');
    Exit;
  End;
  Try
    Arr := Split(Now,' ');
  Except
    End;
  If (Now = '/cam') Then
  Begin
    If (SAOn = False) Then
    Begin
      Log('* To execute this command you must be ingame');
      Exit;
    End;
    //ReadMem($B6F99C + 56,PosZ,4);
    Log ('* CAMERA ZAngle: '+ FloatToStr(GetCameraZAngle) +' - VAngle: '+ FloatToStr(GetCameraVerticalAngle));
    IngChat := '';
    edtChatText.Clear;
    Exit;
  End
  Else If ( Copy(Now,0,1) = '/' ) Then
  Begin
    CommBlock.Command := 'CMD';
    CommBlock.Nick := edtNickname.Text;
    CommBlock.PlayerID := PlayerID;
    CommBlock.Mssg := Now;
    Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
    IngChat := '';
    edtChatText.Clear;
    Exit;
  End;
  CommBlock.Command := 'MSSG';
  CommBlock.Nick := edtNickname.Text;
  CommBlock.PlayerID := PlayerID;
  CommBlock.Mssg := Now;
  Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
  Log(edtNickName.Text +': '+ Now);
  IngChat := '';
  edtChatText.Clear;
end;

procedure TfrmMain.tmrGameTimer(Sender: TObject);
var
  State, CPed, Who, Weap, temp, Val : DWord;
  tmp : Single;
  CommBlock : TCommBlock;
begin
  If (Read = False) Then
  Begin
    tmrSync.Enabled := False;
    tmrSync2.Enabled := False;
    Exit;
  End;
  If (SAOn = False) or (Client.Connected = False) Then
  Begin
    tmrSync.Enabled := False;
    tmrSync2.Enabled := False;
    tmrChat.Enabled := False;
    PlrFreeze := False;
    Exit;
  End;
  //ReadMem(ScriptBase + (4 * 13),Who,4);
  //Log('* >>> '+ IntToStr(Who));
  tmrSync.Enabled := True;
  tmrSync2.Enabled := True;
  ReadMem($B79044,Val,4);
  If (Val > 0) And (Val < 20) Then
  Begin
    KillTask('gta_sa.exe');
    Err('Suspected cheating, closed the game (CID: 2).');
  End;
  tmrChat.Enabled := True;
  ReadMem($B6F5F0,CPed,4);
  ReadMem(CPed + 1328,State,4);
  If (State = 55) Then
  Begin
    If (LastDeath = 0) Then
    Begin
      WriteString($BAADC0,'');
      ReadMem(CPed + 1888,Weap,4);
      ReadMem(CPed + 1892,Who,4);
      temp := 0;
      WriteMem(CPed + 1888,temp,4);
      WriteMem(CPed + 1892,temp,4);

      If Not (Who = 0) Then
      Begin
        Try
          //tmp := StrToFloat(IntToStr(Who));
          tmp := (Who - CPed) / 1988;
          Who := DoStrToInt(FloatToStr(tmp));
        Except
          Who := 0;
        End;
      End;

      PlrFreeze := False;
      LastDeath := 1;
      CommBlock.Command := 'DEATH';
      CommBlock.PlayerID := PlayerID;
      CommBlock.Roll0 := Who;
      CommBlock.Roll2 := Weap;
      Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
    End;
  End
  Else If (State = 1) Then
  Begin
    LastDeath := 0;
    tmrSync.Interval := 80; // 50 // 80 normaal
    ReadMem(ScriptBase + (4 * 11),Weap,4);
    If (Weap > 0) Then
    Begin
      Who := 0;
      WriteMem(ScriptBase + (4 * 11),Who,4);
      CommBlock.Command := 'SPWN0';
      CommBlock.PlayerID := PlayerID;
      CommBlock.Interior := Weap;
      Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
    End;
    ReadMem(ScriptBase + (4 * 12),Weap,4);
    If (Weap > 0) Then
    Begin
      Who := 0;
      WriteMem(ScriptBase + (4 * 12),Who,4);
      CommBlock.Command := 'SPWN1';
      CommBlock.PlayerID := PlayerID;
      CommBlock.Interior := Weap;
      Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
    End;
  End
  Else If (State = 50) Then
  Begin
    LastDeath := 0;
    //tmrSync.Interval := 75;
{    ReadMem(CPed + 1420,CVehicle,4); // Car pointer
    ReadMem(CVehicle + 68,SpeedX,4); // Speed X
    ReadMem(CVehicle + 72,SpeedY,4); // Speed Y
    ReadMem(CVehicle + 76,SpeedZ,4); // Speed Z

    If (SpeedX >= 0.8) Then tmrSync.Interval := 300
    Else If (SpeedY >= 0.8) Then tmrSync.Interval := 300
    Else If (SpeedZ >= 0.8) Then tmrSync.Interval := 300

    Else If (SpeedX >= 0.6) Then tmrSync.Interval := 275
    Else If (SpeedY >= 0.6) Then tmrSync.Interval := 275
    Else If (SpeedZ >= 0.6) Then tmrSync.Interval := 275

    Else If (SpeedX >= 0.3) Then tmrSync.Interval := 200
    Else If (SpeedY >= 0.3) Then tmrSync.Interval := 200
    Else If (SpeedZ >= 0.3) Then tmrSync.Interval := 200

    Else If (SpeedX >= 0.2) Then tmrSync.Interval := 150
    Else If (SpeedY >= 0.2) Then tmrSync.Interval := 150
    Else If (SpeedZ >= 0.2) Then tmrSync.Interval := 150

    Else If (SpeedX >= 0.1) Then tmrSync.Interval := 100
    Else If (SpeedY >= 0.1) Then tmrSync.Interval := 100
    Else If (SpeedZ >= 0.1) Then tmrSync.Interval := 100

    Else If (SpeedX = 0.0) Then tmrSync.Interval := 100
    Else If (SpeedY = 0.0) Then tmrSync.Interval := 100
    Else If (SpeedZ = 0.0) Then tmrSync.Interval := 100

    Else If (SpeedX < 0.1) Then tmrSync.Interval := 70
    Else If (SpeedY < 0.1) Then tmrSync.Interval := 70
    Else If (SpeedZ < 0.1) Then tmrSync.Interval := 70;}
    tmrSync.Interval := 60;

  End;
  If (PlrFreeze = True) Then
    tmrSync.Interval := 100;
end;

procedure TfrmMain.tmrChatTimer(Sender: TObject);
var
  Str : String;
begin
  If (SAOn = False) Then
    Exit;
  If ( FileExists(GameDir +'\chat.fle') ) Then
  Begin
    Str := edtChatText.Text;
    memChat2.Clear;
    memChat2.Lines.LoadFromFile(GameDir +'\chat.fle');
    DeleteFile(GameDir +'\chat.fle');
    IngChat := memChat2.Lines[0];
    btnChatSend.Click;
  End;
  If ( FileExists(GameDir +'\chatbox.fle') ) or ( memChat1.Lines.Count = 0 ) Then
    Exit;
  Try
    memChat1.Lines.SaveToFile(GameDir +'\chatbox.fle');
     memChat1.Lines.Delete(0);
  Except
  End;
end;

procedure TfrmMain.Log(Mssg : String);
begin
  lstChat.Lines.Add(Mssg);
  If (SAOn = False) Then
    Exit;
  memChat1.Lines.Add(Mssg);
end;

function TfrmMain.GetXInfront(Rotation, Distance : Single): Single;
var
  Rad : Single;
Begin
  If (Rotation > 180) Then
    Rad := Rotation - 180
  Else
    Rad := Rotation + 180;
  Rad := DegToRad(Rad - 90);
  result := cos(Rad) * Distance;
end;

function TfrmMain.GetYInfront(Rotation, Distance : Single): Single;
var
  Rad : Single;
Begin
  If (Rotation > 180) Then
    Rad := Rotation - 180
  Else
    Rad := Rotation + 180;
  Rad := DegToRad(Rad - 90);
  result := sin(Rad) * Distance;
end;


procedure TfrmMain.LogIngame(Mssg : String);
begin
  If (SAOn = False) Then
    Exit;
  memChat1.Lines.Add(Mssg);
  If ( FileExists(GameDir +'\chatbox.fle') ) Then
    Exit;
  memChat1.Lines.SaveToFile(GameDir +'\chatbox.fle');
  memChat1.Lines.Delete(0);
end;

procedure TfrmMain.tmrLoadMapTimer(Sender: TObject);
var
  Int, i2, Val, I : Integer;
  Float : Single;
  Arr : TSplitArray;
  ReNOP : Array of Integer;
  offset : Longword;
begin
  Arr := Split('a|a|a','|');
  If (Client.Connected = False) or (SAOn = False) Then
    Exit;
  ReadMem(ScriptBase + (4 * 28),Int,4);
  If (Int = 4) and (GO = False) Then
  Begin
    LogIngame('* Welcome to San Andreas Party '+VERSION+'...');
    //LogIngame('* Initializing...');
    LogIngame('* Loading data... Please wait.');
    ML := 0;
    LD := False;
    FT := False;
    LastLoad := 0;

    SetLength(ReNOP,10);
    ReNOP[0] := $C6;
    ReNOP[1] := $5;
    ReNOP[2] := $A4;
    ReNOP[3] := $67;
    ReNOP[4] := $BA;
    ReNOP[5] := $0;
    ReNOP[6] := $1;
    offset := $53E799;
    For i2 := 0 To 6 Do
    Begin
      Val := ReNOP[i2];
      WriteMem(offset + i2,Val,1);
    End;

    SetLength(ReNOP,4);
    ReNOP[0] := $C6;
    ReNOP[1] := $46;
    ReNOP[2] := $5C;
    ReNOP[3] := $1;
    offset := $576C41;
    For i2 := 0 To 3 Do
    Begin
      Val := ReNOP[i2];
      WriteMem(offset + i2,Val,1);
    End;

    SetLength(ReNOP,3);
    ReNOP[0] := $88;
    ReNOP[1] := $4E;
    ReNOP[2] := $5C;
    offset := $576C34;
    For i2 := 0 To 2 Do
    Begin
      Val := ReNOP[i2];
      WriteMem(offset + i2,Val,1);
    End;
    GO := True;
  End
  Else If (Int = 3) and (GO = True) Then
  Begin
    GO := False;

    Int := 5;
    WriteMem(ScriptBase + (4 * 28),Int,4);
  End
  Else If (Int = 2) Then
  Begin
    If (MapCars.Lines.Count = LastLoad) Then
    Begin
      If (LD = True) Then
        Exit;
    End
    Else
      LastLoad := MapCars.Lines.Count;
    LD := False;
    If (ML = MapCars.Lines.Count) Then
    Begin
      If (FT = True) Then
        Exit;
      FT := True;
      LD := True;

      LogIngame('* Data loading completed! Have a nice play.');
      LogIngame('* Press FIRE to spawn and press LEFT/RIGHT to select a different spawnpoint');

      Read := True;

      Exit;
    End;
  //lstChat.Lines.Add('* Processing ID: '+ IntToStr(ML) +' - LastLoad2: '+ IntToStr(LastLoad2));

    //If (FT = True) Then
    //  Log('> Write > '+ MapCars.Lines[ML]);
    I := 0;
    WriteMem($BA6794,I,1);

    If (MapCars.Lines[ML] = 'unused') Then
    Begin
      ML := ML + 1;
      Exit;
    End;

    Try
      Arr := Split(MapCars.Lines[ML],'|');
    Except
      ML := ML + 1;
      Exit;
    End;

    If (Arr[0] = 'v') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Unique ID
      Cars[Int] := ML+1;
      WriteMem(ScriptBase + (4 * 39),Int,4);

      Int := DoStrToInt(Arr[2]); // Vehicle ID
      WriteMem(ScriptBase + (4 * 33),Int,4);

      Float := DecimalSec(Arr[3]); // Position X
      WriteMem($00A499D4,Float,4);

      Float := DecimalSec(Arr[4]); // Position Y
      WriteMem($00A499D8,Float,4);

      Float := DecimalSec(Arr[5]); // Position Z
      WriteMem($00A499DC,Float,4);

      Float := DecimalSec(Arr[6]); // Rotation
      WriteMem($00A499E0,Float,4);

      Int := DoStrToInt(Arr[7]); // Color 1
      WriteMem(ScriptBase + (4 * 26),Int,4);

      Int := DoStrToInt(Arr[8]); // Color 2
      WriteMem(ScriptBase + (4 * 27),Int,4);

      Int := 1; // Array type
      WriteMem(ScriptBase + (4 * 35),Int,4);
    End
    Else If (Arr[0] = 'dv') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Unique ID
      WriteMem(ScriptBase + (4 * 39),Int,4);

      If not (Cars[Int]-1 = 0) Then
      Begin
        MapCars.Lines[Cars[Int]-1] := 'unused';
      End;
      MapCars.Lines[ML] := 'unused';

      Int := 6; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'o') Then
    Begin
      Int := DoStrToInt(Arr[8]); // Unique ID
      Objects[Int] := ML+1;
      WriteMem(ScriptBase + (4 * 39),Int,4);

      Int := DoStrToInt(Arr[1]); // Model ID
      WriteMem($00A499E4,Int,4);

      Float := DecimalSec(Arr[2]); // Position X
      WriteMem($00A499D4,Float,4);

      Float := DecimalSec(Arr[3]); // Position Y
      WriteMem($00A499D8,Float,4);

      Float := DecimalSec(Arr[4]); // Position Z
      WriteMem($00A499DC,Float,4);

      Float := DecimalSec(Arr[5]); // Rotation X
      WriteMem(ScriptBase + (4 * 36),Float,4);

      Float := DecimalSec(Arr[6]); // Rotation Y
      WriteMem(ScriptBase + (4 * 37),Float,4);

      Float := DecimalSec(Arr[7]); // Rotation Z
      WriteMem(ScriptBase + (4 * 38),Float,4);

      Int := 4; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'do') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Unique ID
      WriteMem(ScriptBase + (4 * 39),Int,4);

      If not (Objects[Int]-1 = 0) Then
      Begin
        MapCars.Lines[Objects[Int]-1] := 'unused';
      End;
      MapCars.Lines[ML] := 'unused';

      Int := 26; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'cp') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Unique ID
      Markers[Int] := ML+1;
      WriteMem(ScriptBase + (4 * 39),Int,4);

      Float := DecimalSec(Arr[2]); // Position X
      WriteMem($00A499D4,Float,4);

      Float := DecimalSec(Arr[3]); // Position Y
      WriteMem($00A499D8,Float,4);

      Float := DecimalSec(Arr[4]); // Position Z
      WriteMem($00A499DC,Float,4);

      Float := DecimalSec(Arr[5]); // Radius
      WriteMem(ScriptBase + (4 * 32),Float,4);

      Int := 8; // Array type
      WriteMem(ScriptBase + (4 * 35),Int,4);

      //MapCars.Items.Strings[ML] := 'unused';
    End
    Else If (Arr[0] = 'cpd') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Unique ID
      WriteMem(ScriptBase + (4 * 39),Int,4);

      If not (Markers[Int]-1 = 0) Then
      Begin
        MapCars.Lines[Markers[Int]-1] := 'unused';
      End;
      MapCars.Lines[ML] := 'unused';

      Int := 9; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'PS') Then
    Begin
      Int := DoStrToInt(Arr[1]); // SoundID
      WriteMem(ScriptBase + (4 * 39),Int,4);

      MapCars.Lines[ML] := 'unused';

      Int := 10; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'SCP') Then
    Begin
      Float := DecimalSec(Arr[1]); // Position X
      WriteMem($00A499D4,Float,4);

      Float := DecimalSec(Arr[2]); // Position Y
      WriteMem($00A499D8,Float,4);

      Float := DecimalSec(Arr[3]); // Position Z
      WriteMem($00A499DC,Float,4);

      MapCars.Lines[ML] := 'unused';

      Int := 13; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'PCA') Then
    Begin
      Float := DecimalSec(Arr[1]); // Position X
      WriteMem($00A499D4,Float,4);

      Float := DecimalSec(Arr[2]); // Position Y
      WriteMem($00A499D8,Float,4);

      Float := DecimalSec(Arr[3]); // Position Z
      WriteMem($00A499DC,Float,4);

      MapCars.Lines[ML] := 'unused';

      Int := 14; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'SVPOS') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Vehicle ID
      WriteMem(ScriptBase + (4 * 39),Int,4);

      Float := DecimalSec(Arr[2]); // Position X
      WriteMem($00A499D4,Float,4);

      Float := DecimalSec(Arr[3]); // Position Y
      WriteMem($00A499D8,Float,4);

      Float := DecimalSec(Arr[4]); // Position Z
      WriteMem($00A499DC,Float,4);

      MapCars.Lines[ML] := 'unused';

      Int := 17; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'CREXP') Then
    Begin
      Float := DecimalSec(Arr[1]); // Position X
      WriteMem($00A499D4,Float,4);

      Float := DecimalSec(Arr[2]); // Position Y
      WriteMem($00A499D8,Float,4);

      Float := DecimalSec(Arr[3]); // Position Z
      WriteMem($00A499DC,Float,4);

      MapCars.Lines[ML] := 'unused';

      Int := 21; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'EXPL') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Vehicle ID
      WriteMem(ScriptBase + (4 * 39),Int,4);

      MapCars.Lines[ML] := 'unused';

      Int := 18; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'REPV') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Vehicle ID
      WriteMem(ScriptBase + (4 * 39),Int,4);

      MapCars.Lines[ML] := 'unused';

      Int := 22; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'RSV') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Vehicle ID
      WriteMem(ScriptBase + (4 * 39),Int,4);

      MapCars.Lines[ML] := 'unused';

      Int := 19; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'RESETWEP') Then
    Begin
      MapCars.Lines[ML] := 'unused';

      Int := 20; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'STRIPW') Then
    Begin
      MapCars.Lines[ML] := 'unused';

      Int := 20; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'SVH') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Car ID
      WriteMem(ScriptBase + (4 * 39),Int,4);

      Float := DecimalSec(Arr[2]); // Health
      WriteMem($00A499D4,Float,4);

      MapCars.Lines[ML] := 'unused';

      Int := 15; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'LVD') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Car ID
      WriteMem(ScriptBase + (4 * 39),Int,4);

      Int := DoStrToInt(Arr[2]); // Door status (1 = Locked / 0 = Unlocker)
      If (Int = 1) Then
        Int := 4;
      WriteMem(ScriptBase + (4 * 26),Int,4);

      MapCars.Lines[ML] := 'unused';

      Int := 16; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'RS') Then
    Begin
      MapCars.Lines[ML] := 'unused';

      Int := 11; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'anim') Then
    Begin // 26 en 27
      MapCars.Lines[ML] := 'unused';

      Int := DoStrToInt(Arr[1]); // PlayerID
      If (Int = PlayerID) Then
        Int := -1;
      WriteMem(ScriptBase + (4 * 26),Int,4);

      Int := DoStrToInt(Arr[2]); // AnimationID
      WriteMem(ScriptBase + (4 * 27),Int,4);

      Int := 24; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'BP') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Player ID
      WriteMem(ScriptBase + (4 * 39),Int,4);

      MapCars.Lines[ML] := 'unused';

      Int := 12; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'col') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Unique ID
      WriteMem(ScriptBase + (4 * 39),Int,4);

      Int := DoStrToInt(Arr[2]); // Color 1
      WriteMem(ScriptBase + (4 * 26),Int,4);

      Int := 7; // Array type
      WriteMem($00A499EC,Int,4);
      MapCars.Lines[ML] := 'unused';
    End
    Else If (Arr[0] = 's') Then
    Begin
     //Int := DoStrToInt(Arr[1]); // Skin ID
      //WriteMem($00A499E4,Int,4);

      Float := DecimalSec(Arr[1]); // Position X
      WriteMem(ScriptBase + (4 * 29),Float,4);

      Float := DecimalSec(Arr[2]); // Position Y
      WriteMem(ScriptBase + (4 * 30),Float,4);

      Float := DecimalSec(Arr[3]); // Position Z
      WriteMem(ScriptBase + (4 * 31),Float,4);

      Float := DecimalSec(Arr[4]); // Rotation
      WriteMem(ScriptBase + (4 * 32),Float,4);

      Int := 2; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'h') Then
    Begin
      Int := 1240; // Model ID
      WriteMem($00A499E4,Int,4);

      Float := DecimalSec(Arr[1]); // Position X
      WriteMem($00A499D4,Float,4);

      Float := DecimalSec(Arr[2]); // Position Y
      WriteMem($00A499D8,Float,4);

      Float := DecimalSec(Arr[3]); // Position Z
      WriteMem($00A499DC,Float,4);

      Int := 3; // Type
      WriteMem(ScriptBase + (4 * 34),Int,4);

      Int := 3; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'r') Then
    Begin
      Float := DecimalSec(Arr[1]); // Position X
      WriteMem($00A499D4,Float,4);

      Float := DecimalSec(Arr[2]); // Position Y
      WriteMem($00A499D8,Float,4);

      Float := DecimalSec(Arr[3]); // Position Z
      WriteMem($00A499DC,Float,4);

      Int := 5; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'a') Then
    Begin
      Int := 1242; // Model ID
      WriteMem($00A499E4,Int,4);

      Float := DecimalSec(Arr[1]); // Position X
      WriteMem($00A499D4,Float,4);

      Float := DecimalSec(Arr[2]); // Position Y
      WriteMem($00A499D8,Float,4);

      Float := DecimalSec(Arr[3]); // Position Z
      WriteMem($00A499DC,Float,4);

      Int := 3; // Type
      WriteMem(ScriptBase + (4 * 34),Int,4);

      Int := 3; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'p') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Model ID
      WriteMem($00A499E4,Int,4);

      Float := DecimalSec(Arr[3]); // Position X
      WriteMem($00A499D4,Float,4);

      Float := DecimalSec(Arr[4]); // Position Y
      WriteMem($00A499D8,Float,4);

      Float := DecimalSec(Arr[5]); // Position Z
      WriteMem($00A499DC,Float,4);

      Int := DoStrToInt(Arr[2]); // Array type
      WriteMem(ScriptBase + (4 * 34),Int,4);

      Int := 3; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'w') Then
    Begin
      //Log(IntToStr(ML) +' > '+ MapCars.Lines.Strings[ML]);
      ReadMem(ScriptBase + (4 * 5),Int,4); // Weapon ID
      If (Int = 0) Then
      Begin
        Int := DoStrToInt(Arr[1]);
        WriteMem(ScriptBase + (4 * 5),Int,4); // Weapon ID
        MapCars.Lines[ML] := 'unused';
      End
      Else
        Exit;
    End
    Else If (Arr[0] = 'APTJ') Then // AllowPlayerToJump(PlayerID : Integer; Toggle : Boolean);
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 26),Int,4);

      Int := 27; // Type
      WriteMem($00A499EC,Int,4);
      MapCars.Lines[ML] := 'unused';
    End
    Else If (Arr[0] = 'APTS') Then // AllowPlayerToShoot(PlayerID : Integer; Toggle : Boolean);
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 26),Int,4);

      Int := 28; // Type
      WriteMem($00A499EC,Int,4);
      MapCars.Lines[ML] := 'unused';
    End
    Else If (Arr[0] = 'APTCW') Then // AllowPlayerToChangeWeapon(PlayerID : Integer; Toggle : Boolean);
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 26),Int,4);

      Int := 29; // Type
      WriteMem($00A499EC,Int,4);
      MapCars.Lines[ML] := 'unused';
    End
    Else If (Arr[0] = 'SPC') Then // SetPlayerCrouch(PlayerID : Integer; Toggle : Boolean);
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 26),Int,4);

      Int := 30; // Type
      WriteMem($00A499EC,Int,4);
      MapCars.Lines[ML] := 'unused';
    End
    Else If (Arr[0] = 'ULWD') Then // UndoLastWeaponDamage(PlayerID: Integer);
    Begin
      Int := 31; // Type
      WriteMem($00A499EC,Int,4);
      MapCars.Lines[ML] := 'unused';
    End
    Else If (Arr[0] = 'SPAW') Then // SetPlayerArmedWeapon(PlayerID, WeaponID : Integer);
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 26),Int,4);

      Int := 32; // Type
      WriteMem($00A499EC,Int,4);
      MapCars.Lines[ML] := 'unused';
    End
    Else If (Arr[0] = 'HUD') Then // Enable/Disable HUD
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 26),Int,4);

      Int := 33; // Type
      WriteMem($00A499EC,Int,4);
      MapCars.Lines[ML] := 'unused';
    End
    Else If (Arr[0] = 'ATC') Then // AllowPlayerToCrouch(PlayerID : Integer; Toggle : Boolean);
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 26),Int,4);

      Int := 34; // Type
      WriteMem($00A499EC,Int,4);
      MapCars.Lines[ML] := 'unused';
    End
    Else If (Arr[0] = 'RADAR') Then // Enabled/Disable radar
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 26),Int,4);

      Int := 35; // Type
      WriteMem($00A499EC,Int,4);
      MapCars.Lines[ML] := 'unused';
    End
    Else If (Arr[0] = 'GREY') Then // Enabled/Disable radar (grey)
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 26),Int,4);

      Int := 38; // Type
      WriteMem($00A499EC,Int,4);
      MapCars.Lines[ML] := 'unused';
      Log('*** GREY');
    End
    Else If (Arr[0] = 'WDS') Then // Enabled/Disable widescreen
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 26),Int,4);

      Int := 36; // Type
      WriteMem($00A499EC,Int,4);
      MapCars.Lines[ML] := 'unused';
    End
    Else If (Arr[0] = 'CS') Then // Create sparks (???)
    Begin
      Float := DecimalSec(Arr[1]); // Position X
      WriteMem($00A499D4,Float,4);

      Float := DecimalSec(Arr[2]); // Position Y
      WriteMem($00A499D8,Float,4);

      Float := DecimalSec(Arr[3]); // Position Z
      WriteMem($00A499DC,Float,4);

      Float := DecimalSec(Arr[4]); // Rot X
      WriteMem(ScriptBase + (4 * 36),Float,4);

      Float := DecimalSec(Arr[5]); // Rot Y
      WriteMem(ScriptBase + (4 * 37),Float,4);

      Float := DecimalSec(Arr[6]); // Rot Z
      WriteMem(ScriptBase + (4 * 38),Float,4);

      Int := DoStrToInt(Arr[7]); // Intensity
      WriteMem(ScriptBase + (4 * 26),Int,4);

      Int := 37; // Type
      WriteMem($00A499EC,Int,4);
      MapCars.Lines[ML] := 'unused';
    End;
   //Log(IntToStr(ML) +' > '+ MapCars.Lines.Strings[ML]);
    Int := 1;
    WriteMem(ScriptBase + (4 * 28),Int,4); // Write-able
    //WriteString($BAB040,'Loading map. Please wait.~n~Done: '+ IntToStr(ML) +'/'+ IntToStr(Pred(MapCars.Lines.Count)));
    //  LastLoad2 := ML;
    ML := ML + 1;
  End;
end;

procedure TfrmMain.ClientDisconnected(Sender: TObject);
begin
  If (Browsing = True) Then
    Exit;

  If (Disconnected = False) Then
  Begin
    If (SAOn = True) Then
      KillTask('gta_sa.exe');
    Disconnected := True;
    lstPlayers.Clear;
    ClientHandleThread.Terminate;
    Log('* Disconnected (Reason: Lost connection with server)');
    edtNickname.Enabled := True;
    edtHost.Enabled := True;
    edtPort.Enabled := True;
    edtPassword.Enabled := True;
    edtAdminPass.Enabled := True;
    btnDisconnect.Enabled := False;
    btnDisconnect2.Enabled := False;
    btnConnect.Enabled := True;
    btnStartGame.Enabled := False;
    btnGameDir.Enabled := False;
  End

end;

procedure TfrmMain.btnRefreshClick(Sender: TObject);
var
  Str : String;
  Arr, Arr2, Arr3 : TSplitArray;
  i, c : integer;
begin
  if (Client.Connected) then
  begin
    ShowMessage('Please disconnect first from the server.');
    Exit;
  end;
  Arr := Split('a|a|a','|');
  Arr2 := Split('a|a|a','|');
  Arr3 := Split('a|a|a','|');
  btnRefresh.Enabled := False;
  lblStatus.Caption := 'Cleaning current list...';
  lstBrowser.Clear;
  lblStatus.Caption := 'Retrieving server list...';
  HTTP.Request.UserAgent := 'SAP/'+VERSION;
  Str := HTTP.Get('http://www.sa-party.com/03masterlist/servers.sap');
  If (Str = '') Then
  Begin
    lblStatus.Caption := 'No servers found!';
    btnRefresh.Enabled := True;
    Exit;
  End;
  lblStatus.Caption := 'Pinging servers...';

  Arr := Split(Str,'|');
  Browsing := True;
  For i := 0 To High(Arr) Do
  Begin
    Try
      Arr2 := Split(Arr[i],':');

      Client.Host := Arr2[0];
      Client.Port := StrToInt(Arr2[1])+1;
      Client.Connect(200);
      Client.Write('Q');
      Arr3 := Split(Client.ReadLn(), '|');
      with frmMain.lstBrowser.Items.Insert(BrowserC) do
      begin
        if (Arr3[2] = '0')  then
          Caption := ' '
        else
          Caption := 'X'; // Passworded
        SubItems.Add(CopyBefore(Arr3[3], '~'));
        SubItems.Add(Arr3[0]);
        SubItems.Add(Arr3[1]);
        SubItems.Add(' '+Arr2[0]+':'+Arr2[1]);
        c := c+1;
      end;
      Client.Disconnect;
      Next;
    Except
      Next;
    end;
  End;
  if (c = 1) then
    lblStatus.Caption := 'Found 1 server.'
  else
    lblStatus.Caption := 'Found '+IntToStr(c)+' servers.';
  btnRefresh.Enabled := True;
  Browsing := False;
end;

function TfrmMain.DoStrToInt(Str : String): Integer;
var
  Tmp : Integer;
begin
  Try
    Tmp := StrToInt(Str);
  Except
    Tmp := 0;
  End;
  result := Tmp;
end;

{   Ywa's Notepad:

0xBAB22C [4 bytes] = health bar color (RGBA) in bytes

APTJ  AllowPlayerToJump(PlayerID : Integer; Toggle : Boolean);
APTS  AllowPlayerToShoot(PlayerID : Integer; Toggle : Boolean);
APTCW AllowPlayerToChangeWeapon(PlayerID : Integer; Toggle : Boolean);
SPC   SetPlayerCrouch(PlayerID : Integer; Toggle : Boolean);
ULWD  UndoLastWeaponDamage(PlayerID: Integer);
SPAW SetPlayerArmedWeapon(PlayerID, WeaponID : Integer);

}

procedure TfrmMain.OnBrowserDoubleClick(Sender: TObject);
var
  Arr : TSplitArray;
begin
  if (Client.Connected) then
  begin
    ShowMessage('Please disconnect first from the server.');
    Exit;
  end;

  Arr := Split('a|a|a','|');
  If (lstBrowser.SelCount = 0) Or (lstBrowser.ItemIndex = -1) Then
  Begin
    ShowMessage('No server selected');
    Exit;
  End;

  Browsing := False;
  Try
    Arr := Split(lstBrowser.Selected.SubItems.ValueFromIndex[3],':');
  Except
    Exit;
  End;
  edtHost.Text := Arr[0];
  edtPort.Text := Arr[1];
  //tabGame.Show;
  //btnConnect.Click;

end;

end.

