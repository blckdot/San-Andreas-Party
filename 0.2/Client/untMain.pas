unit untMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ComCtrls, StdCtrls, XPMan, IdBaseComponent, IdComponent,
  JvCreateProcess, JvComponent, JvAppHotKey, ExtCtrls, IdHTTP, JvBaseDlg,
  JvSelectDirectory, JvTimer, IdTCPConnection, IdTCPClient, INIFiles, TLHelp32, Math;

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
    Shot1,
    Shot2,
    Shot3,
    Shot4,
    Shot5,
    Shot6 : Byte;
  end;
  TfrmMain = class(TForm)
    pagBrowser: TPageControl;
    grpLobby: TGroupBox;
    appXPM: TXPManifest;
    grpGame: TGroupBox;
    lstPlayers: TListBox;
    lblPlayers: TLabel;
    btnChatSend: TButton;
    edtChatText: TEdit;
    btnStartGame: TButton;
    btnDisconnect: TButton;
    Client: TIdTCPClient;
    tabQuickConnect: TTabSheet;
    lblHost: TLabel;
    lblPort: TLabel;
    edtPort: TEdit;
    btnConnect: TButton;
    tmrProcess: TJvTimer;
    lblNickname: TLabel;
    edtNickname: TEdit;
    btnGameDir: TButton;
    SelectDir: TJvSelectDirectory;
    tmrSync: TJvTimer;
    edtHost: TComboBox;
    MapCars: TListBox;
    tmrGame: TJvTimer;
    HTTP: TIdHTTP;
    lblPass: TLabel;
    edtPassword: TEdit;
    lblInfo: TLabel;
    lblAdminPass: TLabel;
    edtAdminPass: TEdit;
    lstChat: TMemo;
    btnAbout: TButton;
    tmrSync2: TJvTimer;
    tabBrowser: TTabSheet;
    lstBrowser: TListBox;
    btnRefresh: TButton;
    tmrChat: TTimer;
    tmrLoadMap: TJvTimer;
    procSA: TJvCreateProcess;
    memChat2: TMemo;
    memChat1: TMemo;
    lblStatus: TLabel;
    btnBrowserConnect: TButton;
    lstNameTags: TListBox;
    tmrTextClear: TTimer;
    function Writestring(offset : Longword; Text: string): Integer;
    function WriteWidestring(Offset : Longword; Text: string): Integer;
    procedure SyncWrite(CMB : TCommBlock);
    procedure Sync2Write(CMB : TCommBlock);
    procedure tmrProcessTimer(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure GamePatch();
    procedure GameUnpatch();
    procedure btnStartGameClick(Sender: TObject);
    procedure btnGameDirClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure WriteMem(Offset: Longword; var Value; Size: Integer);
    procedure ReadMem(Offset: Longword; var Value; Size: Integer);
    procedure NOP(Offset: Longword; Size: Integer);
    procedure NOPOffsets();
    procedure tmrSyncTimer(Sender: TObject);
    procedure ClientConnected(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure edtChatTextKeyPress(Sender: TObject; var Key: Char);
    procedure btnChatSendClick(Sender: TObject);
    procedure tmrGameTimer(Sender: TObject);
    procedure btnAboutClick(Sender: TObject);
    procedure tmrSync2Timer(Sender: TObject);
    procedure tmrChatTimer(Sender: TObject);
    procedure tmrLoadMapTimer(Sender: TObject);
    procedure procSATerminate(Sender: TObject; ExitCode: Cardinal);
    procedure ClientDisconnected(Sender: TObject);
    procedure Log(Mssg : String);
    procedure LogIngame(Mssg : String);
    procedure btnRefreshClick(Sender: TObject);
    procedure tabBrowserShow(Sender: TObject);
    procedure tabBrowserHide(Sender: TObject);
    procedure btnBrowserConnectClick(Sender: TObject);
    procedure tmrTextClearTimer(Sender: TObject);
  private
    { Private declarations }
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
  SAOn, SAOnLast, NOPped, MapDL, LD, FT, Read, GO, Disconnected, PlrFreeze, Browsing : Boolean;
  hProc, PlayerID, MapRow, GameHours, GameMinutes, LastDeath, ML, LastShoot, LastLoad, LastTime, GotLast, LastArm, LastCrouch, NickDone : Integer;
  card : Cardinal;
  ClientHandleThread : TClientHandleThread;
  GameDir, ServerName, IngChat : String;
  INI : TINIFile;
  ScriptBase : DWord = $A49960;
  PlrShoot, PlrArmed, PlrAct, Players : Array of Integer;
  PlrFreeze1, PlrFreeze2, PlrFreeze3 : Single;
  PlrNick : Array of String;
  LastTick : Cardinal;

implementation

{$R *.dfm}

function GetWeaponName(WeaponID : Integer): String;
begin
  If (WeaponID = 0) Then
    Result := 'Fist'
  Else If (WeaponID = 1) Then
    Result := 'Brass Knuckles'
  Else If (WeaponID = 2) Then
    Result := 'Golf club'
  Else If (WeaponID = 3) Then
    Result := 'Nitestick'
  Else If (WeaponID = 4) Then
    Result := 'Knife'
  Else If (WeaponID = 5) Then
    Result := 'Baseball Bat'
  Else If (WeaponID = 6) Then
    Result := 'Shovel'
  Else If (WeaponID = 7) Then
    Result := 'Pool Cue'
  Else If (WeaponID = 8) Then
    Result := 'Katana'
  Else If (WeaponID = 9) Then
    Result := 'Chainsaw'
  Else If (WeaponID = 22) Then
    Result := 'Pistol'
  Else If (WeaponID = 23) Then
    Result := 'Silenced Pistol'
  Else If (WeaponID = 24) Then
    Result := 'Desert Eagle'
  Else If (WeaponID = 25) Then
    Result := 'Shotgun'
  Else If (WeaponID = 26) Then
    Result := 'Sawn-Off Shotgun'
  Else If (WeaponID = 27) Then
    Result := 'SPAS-12'
  Else If (WeaponID = 28) Then
    Result := 'Micro Uzi'
  Else If (WeaponID = 29) Then
    Result := 'MP5'
  Else If (WeaponID = 32) Then
    Result := 'TEC-9'
  Else If (WeaponID = 30) Then
    Result := 'AK47'
  Else If (WeaponID = 31) Then
    Result := 'M4'
  Else If (WeaponID = 33) Then
    Result := 'Country Rifle'
  Else If (WeaponID = 34) Then
    Result := 'Sniper Rifle'
  Else If (WeaponID = 35) Then
    Result := 'Rocket Launcher'
  Else If (WeaponID = 36) Then
    Result := 'Heat Seaking RPG'
  Else If (WeaponID = 37) Then
    Result := 'Fire' // Flame thrower
  Else If (WeaponID = 38) Then
    Result := 'Minigun'
  Else If (WeaponID = 16) Then
    Result := 'Grenade'
  Else If (WeaponID = 18) Then
    Result := 'Fire' // Molotov Cocktail
  Else If (WeaponID = 39) Then
    Result := 'Remote Explosives'
  Else If (WeaponID = 14) Then
    Result := 'Flowers'
  Else If (WeaponID = 42) Then
    Result := 'Fire Extinguisher'
  Else If (WeaponID = 43) Then
    Result := 'Camera'
  Else If (WeaponID = 46) Then
    Result := 'Parachute'
  Else If (WeaponID = 40) Then
    Result := 'Detonator'
  Else If (WeaponID = 44) Then
    Result := 'NV Goggles'
  Else If (WeaponID = 45) Then
    Result := 'IR Goggles'
  Else If (WeaponID = 51) Then
    Result := 'Explosion' // Not sure
  Else
    Result := 'Unknown weapon - ID: '+ IntToStr(WeaponID);
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
  tmp : String;
begin
  tmp := F;
  tmp := StringReplace(tmp,'.',DecimalSeparator,[rfReplaceAll]);
  tmp := StringReplace(tmp,',',DecimalSeparator,[rfReplaceAll]);
  result := StrToFloat(tmp);
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
begin
   If (CB.Command = 'SYNC') Then
     frmMain.SyncWrite(CB)
   Else If (CB.Command = 'SYNC2') Then
     frmMain.Sync2Write(CB)
   Else If (CB.Command = 'M4P') Then
   Begin
     frmMain.MapCars.Items.Add(CB.Mssg);
     If (CB.State = 1) Then
     Begin
      MapDL := False;
      frmMain.btnStartGame.Caption := 'Start game';
      //frmMain.Log('* Map succesfully received');
      //frmMain.GamePatch;
     End
     Else
     Begin
       //frmMain.btnStartGame.Caption := 'Downloading map: '+ IntToStr(MapRow);
       CommBlock.Command := 'DMAP';
       CommBlock.Nick := 'Server';
       CommBlock.PlayerID := PlayerID;
       CommBlock.Nick := frmMain.edtNickname.Text;
       MapRow := MapRow + 1;
       CommBlock.Anim := MapRow;
       frmMain.Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
     End;
   End
   Else If (CB.Command = 'OK') Then
   Begin
     If (CB.Interior = 1) Then
     Begin
       frmMain.Log('*** Wrong version');
       frmMain.btnDisconnect.Click;
     End
     Else If (CB.Interior = 2) Then
     Begin
       frmMain.Log('*** Wrong server password');
       frmMain.btnDisconnect.Click;
     End
     Else If (CB.Interior = 3) Then
     Begin
       frmMain.Log('*** Server is full');
       frmMain.btnDisconnect.Click;
     End
     Else If (CB.Interior = 4) Then
     Begin
       frmMain.Log('*** Wrong admin password or admin system is disabled');
       frmMain.btnDisconnect.Click;
     End
     Else If (CB.Interior = 5) Then
     Begin
       frmMain.Log('*** You''re banned from this server');
       frmMain.btnDisconnect.Click;
     End
     Else If (CB.Interior = 6) Then
     Begin
       frmMain.Log('*** NickName already in usage');
       frmMain.btnDisconnect.Click;
     End
     Else
     Begin
      GameHours := CB.Crouch;
      GameMinutes := CB.CrouchRoll2;
      PlayerID := CB.PlayerID; // Woohoo we hebben de ID :D
      ServerName := CB.Mssg;
      frmMain.Log('* Connected (ID: '+ IntToStr(PlayerID) +') to "'+ ServerName +'"');
     End;
   End
   Else If (CB.Command = 'JOIN') Then
   Begin
     CommBlock.Command := 'JOIN2';
     CommBlock.PlayerID := PlayerID;
     CommBlock.Nick := frmMain.edtNickname.Text;
     frmMain.Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
     //frmMain.Log('* '+ CB.Nick +' joined the server');
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
     If (CB.Roll2 = 0) Then
     Begin // Orange text
       frmMain.WriteString($BAAEC0,CB.Mssg);
     End
     Else If (CB.Roll2 = 1) Then
     Begin // Stunt Bonus text
       frmMain.WriteString($BAB040,CB.Mssg);
     End
     Else If (CB.Roll2 = 2) Then
     Begin // Mission title
       frmMain.WriteString($BAAD40,CB.Mssg);
     End
     Else If (CB.Roll2 = 3) Then
     Begin // Mission complete
       frmMain.WriteString($BAACC0,CB.Mssg);
     End
     Else If (CB.Roll2 = 4) Then
     Begin // ?
       frmMain.WriteString($BAADC0,CB.Mssg);
     End
     Else If (CB.Roll2 = 5) Then
     Begin // ?
       frmMain.WriteString($BAAFC0,CB.Mssg);
     End;
     frmMain.tmrTextClear.Interval := CB.Anim;
     frmMain.tmrTextClear.Enabled := True;
   End
   Else If (CB.Command = 'LEAVE') Then
   Begin
     //frmMain.Log('* '+ CB.Nick +' left the server');
     PlrNick[CB.PlayerID] := '';
     frmMain.lstPlayers.Items.Delete(frmMain.lstPlayers.Items.IndexOf(CB.Nick));
     I := 0;
     frmMain.WriteMem(ScriptBase + (4 * (70+(CB.PlayerID-1))),I,4); // Active
   End
   Else If (CB.Command = 'CLOSE') Then
   Begin
     frmMain.Log('* Server shutting down');
     frmMain.btnDisconnect.Click;
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
   Else If (CB.Command = 'NMP') Then
   Begin
     frmMain.MapCars.Items.Add(CB.Mssg);
   End
   Else If (CB.Command = 'PONG') Then
   Begin
     Try
       Arr := Split(CB.Mssg,'_____');
     Except
       Exit;
     End;
     I := frmMain.lstBrowser.Items.IndexOf(Arr[1]);
     frmMain.lstBrowser.Items[I] := Arr[0] +' - Players: '+ IntToStr(CB.Roll0) +'/'+ IntToStr(CB.Roll2) +' - Host: '+ Arr[1];
     frmMain.Client.Disconnect;
   End
   Else If (CB.Command = 'PENG') Then
   Begin
     frmMain.Log('PING: '+ IntToStr((GetTickCount-LastTick) div 1000) +'s');
     LastTick := 0;
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
     frmMain.Log('*** You''re kicked from the server');
     frmMain.btnDisconnect.Click;
   End
   Else If (CB.Command = 'BAN') Then
   Begin
     frmMain.Log('* You''re banned from the server');
     CommBlock.Command := 'BANM';
     CommBlock.PlayerID := PlayerID;
     CommBlock.Nick := frmMain.edtNickname.Text;
     frmMain.Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
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
  Txt : String;
begin
  result := 0;
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

procedure TfrmMain.WriteMem(Offset: Longword;var Value; Size: Integer);
begin
  If (SAOn = True) Then
    WriteProcessMemory(hProc, ptr(Offset),@Value, Size, card);
end;

procedure TfrmMain.ReadMem(Offset: Longword;var Value; Size: Integer);
begin
  If (SAOn = True) Then
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

procedure TfrmMain.tmrProcessTimer(Sender: TObject);
var
  PID, CarSpwn : Integer;
  CommBlock : TCommBlock;
begin
  GetWindowThreadProcessId(FindWindow(nil,'GTA: San Andreas'), @PID);
  hProc := OpenProcess(PROCESS_ALL_ACCESS, False, PID);
{  If (Client.Connected = True) Then
  Begin
    CommBlock.Command := 'PANG';
    CommBlock.PlayerID := PlayerID;
    CommBlock.Nick := edtNickname.Text;
    LastTick := 0;
    Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
  End;}
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
    ReadMem($00A499D0,CarSpwn,4); // Read write-able abilities
    If (CarSpwn = 2) and (GO = False) Then
    Begin
      GO := True;
      ML := 0;
      LD := False;
      FT := False;
      LastLoad := 0;
      LogIngame('*** Welcome to San Andreas Party 0.2.0.0 BETA');
      LogIngame('*** Loading map... Please wait!');
      tmrLoadMap.Enabled := True;
    End;
  End
  Else
  Begin
    LD := False;
    LastLoad := 0;
    FT := False;
    tmrLoadMap.Enabled := False;
    SAOn := False;
    NOPped := False;
    Read := False;
//    tmrIngChat.Enabled := False;
    If (Client.Connected = True) and (MapDL = False) Then
    Begin
      btnGameDir.Enabled := True;
      btnStartGame.Enabled := True;
    End;

    If Not (SAOnLast = SAOn) Then
    Begin
      GameUnpatch;
      If (Client.Connected = True) Then
      Begin
        CommBlock.PlayerID := PlayerID;
        CommBlock.Command := 'GOFF';
        Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
      End;
    End;

    SAOnLast := False;
  End;
end;

procedure TfrmMain.btnConnectClick(Sender: TObject);
begin
  If (SAOn = True) Then
  Begin
    Err('Please close GTA:SA first!');
    Exit;
  End;
  lstPlayers.Clear;
  lstChat.Clear;
  edtNickname.Enabled := False;
  edtHost.Enabled := False;
  edtPort.Enabled := False;
  edtPassword.Enabled := False;
  edtAdminPass.Enabled := False;
  btnDisconnect.Enabled := False;
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
    Client.Connect(2000);

    ClientHandleThread := TClientHandleThread.Create(True);
    ClientHandleThread.FreeOnTerminate := True;
    ClientHandleThread.Resume;
    btnDisconnect.Enabled := True;
    btnStartGame.Enabled := True;
    btnGameDir.Enabled := True;
    MapCars.Clear;
    GO := False;
  Except
    edtNickname.Enabled := True;
    edtHost.Enabled := True;
    edtPort.Enabled := True;
    edtPassword.Enabled := True;
    edtAdminPass.Enabled := True;
    btnDisconnect.Enabled := False;
    btnConnect.Enabled := True;
    btnStartGame.Enabled := False;
    btnGameDir.Enabled := False;
    Log('* Server timed-out');
    Exit;
  End;
  INI.WriteString('Lobby','Nickname',edtNickname.Text);
  INI.WriteString('Lobby','Host',edtHost.Text);
  INI.WriteString('Lobby','Port',edtPort.Text);
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
  GO := False;
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
  btnConnect.Enabled := True;
  btnStartGame.Enabled := False;
  btnGameDir.Enabled := False;
  MapCars.Clear;
end;

procedure TfrmMain.btnStartGameClick(Sender: TObject);
var
  CommBlock : TCommBlock;
begin
  GameDir := INI.ReadString('Game','GameDir','None');
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
  If (MapCars.Count = 0) Then
  Begin
    MapCars.Clear;
    MapDL := True;
    CommBlock.Command := 'DMAP';
    CommBlock.Nick := 'Server';
    CommBlock.PlayerID := PlayerID;
    CommBlock.Nick := edtNickname.Text;
    MapRow := 0;
    CommBlock.Anim := MapRow;
    Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
    //Log('* Map download request is send.');
    btnStartGame.Enabled := False;
    //btnStartGame.Caption := 'Downloading map: 0';
    GamePatch();
    LD := False;
    FT := False;
    Exit;
  End;
  LD := False;
  FT := False;
  GamePatch();
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

  CreateDir(GameDir +'\SAP');

  F := GameDir +'\chat.fle';
  If ( FileExists(F) ) Then
    DeleteFile(F);

  F := GameDir +'\chatbox.fle';
  If ( FileExists(F) ) Then
    DeleteFile(F);

  Patch(GameDir + '\d3d9.dll',GameDir +'\d3d9.sapbak');

  F := GameDir +'\d3d9.dll';
  If ( FileExists(F) ) Then
    DeleteFile(F);

  Patch(GameDir + '\data\script\main.scm',GameDir +'\data\script\main.sap');

  Patch(GameDir + '\data\script\script.img',GameDir +'\data\script\script.sap');

  Patch(GameDir + '\data\handling.cfg',GameDir +'\data\handling.sap');

  Patch(GameDir + '\data\handling.cfg',GameDir +'\data\handling.sapbak');

  Patch(GameDir + '\data\script\main.scm',GameDir +'\data\script\main.sapbak');

  Patch(GameDir + '\data\script\script.img',GameDir +'\data\script\script.sapbak');

  //Patch(ExtractFilePath(Application.ExeName) + '\data\main.scm',GameDir +'\SAP\main.scm');

  //Patch(ExtractFilePath(Application.ExeName) + '\data\script.img',GameDir +'\SAP\script.img');

  //Patch(ExtractFilePath(Application.ExeName) + '\data\main.scm',GameDir +'\data\script\main.scm');

  //Patch(ExtractFilePath(Application.ExeName) + '\data\script.img',GameDir +'\data\script\script.img');

  Patch(ExtractFilePath(Application.ExeName) + '\data\handling.sap',GameDir +'\data\handling.cfg');

  Patch(ExtractFilePath(Application.ExeName) + '\data\gta.sap',GameDir +'\data\gta.dat');

  Patch(ExtractFilePath(Application.ExeName) + '\data\launcher.sap',GameDir +'\saplauncher.exe');

  Patch(ExtractFilePath(Application.ExeName) + '\data\chat.sap',GameDir +'\d3d9.dll');

  procSA.ApplicationName := GameDir + '\saplauncher.exe';
  procSA.Run;
end;

procedure TfrmMain.GameUnpatch();
var
  F : String;
begin
  F := GameDir +'\data\script\main.scm';
  If ( FileExists(F) ) Then
    DeleteFile(F);

  Patch(GameDir +'\data\handling.sap',GameDir +'\data\handling.cfg');  

  Patch(GameDir +'\data\script\main.sap',GameDir +'\data\script\main.scm');

  Patch(GameDir +'\data\script\script.sap',GameDir +'\data\script\script.img');

  F := GameDir +'\data\script\main.sap';
  If ( FileExists(F) ) Then
    DeleteFile(F);

  F := GameDir +'\data\script\script.sap';
  If ( FileExists(F) ) Then
    DeleteFile(F);

  F := GameDir +'\data\handling.sap';
  If ( FileExists(F) ) Then
    DeleteFile(F);

  F := GameDir +'\saplauncher.exe';
  If ( FileExists(F) ) Then
    DeleteFile(F);

  F := GameDir +'\d3d9.dll';
  If ( FileExists(F) ) Then
    DeleteFile(F);    
end;

procedure TfrmMain.btnGameDirClick(Sender: TObject);
begin
  If (SelectDir.Execute) Then
  Begin
    If not( FileExists( SelectDir.Directory + '\gta_sa.exe' ) ) Or not ( FileExists( SelectDir.Directory + '\stream.ini' ) ) Then
    Begin
      ShowMessage('No GTA: SA found in this directory!');
      Exit;
    End;
    INI.WriteString('Game','GameDir',SelectDir.Directory);
    Log('* New GTA: SA directory set!');
  End;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  INI := TINIFile.Create(GetCurrentDir + '\settings.ini');
  edtNickname.Text := INI.ReadString('Lobby','Nickname','Player');
  edtHost.Text := INI.ReadString('Lobby','Host','home.xoti.net');
  edtPort.Text := INI.ReadString('Lobby','Port','8070');
  SetLength(PlrShoot,21);
  SetLength(PlrArmed,21);
  SetLength(PlrAct,21);
  SetLength(Players,21);
  SetLength(PlrNick,21);
end;

procedure TfrmMain.NOPOffsets();
var
  Int, i : Integer;
  WriteString : Byte;
  Text : String;
  Offset : LongInt;
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
  NOP($58EC21,5); // Klok uitzetten / Niet displayen
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
  CPed, CPos, CVehicle, DW : DWord;
  CommBlock : TCommBlock;
  I : Integer;
  F1, F2 : Single;
begin
  If (Client.Connected = False) or (SAOn = False)  Then // or (Read = False)
    Exit;

  ReadMem(ScriptBase + (4 * 1),CommBlock.Active,4); // Active

  ReadMem($B6F5F0,CPed,4);

  //Log('Player: '+ IntToStr(CPed));

  ReadMem(CPed + 1328,CommBlock.State,4); // State (Walking, Driving)

  ReadMem(ScriptBase + (4 * 0),CommBlock.Car,4); // Player Car
  ReadMem(ScriptBase + (4 * 2),I,4); // Passenger
  If (I = 1) Then
    CommBlock.Car := CommBlock.Car + 2000
  Else If (I = 2) Then
    CommBlock.Car := CommBlock.Car + 4000
  Else If (I = 3) Then
    CommBlock.Car := CommBlock.Car + 6000;
    
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

    ReadMem(ScriptBase + (4 * 8),CommBlock.Crouch,4); // Holding weapon

    ReadMem(ScriptBase + (4 * 7),CommBlock.XB,4); // Rotatie in graden (Inversed)
    ReadMem(CPed + 1332,CommBlock.CrouchRoll2,4); // Shooting
    ReadMem(CPed + 1440 + (WeaponSlot(CommBlock.Crouch) * 28) + 4,CommBlock.CrouchRoll2,4); // Shooting-state
    If (CommBlock.CrouchRoll2 = 2) or (CommBlock.CrouchRoll2 = 1) Then // Reloading or shooting
    Begin
      LastShoot := 1;
      CommBlock.CrouchRoll2 := 1;
    End
    Else If (CommBlock.CrouchRoll2 = 0) and (LastTime > 4) Then
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
    End;
    If (CommBlock.CrouchRoll2 = 1) Then
    Begin
      ReadMem(CPed + 1148,DW,4); // Animation structure // DWord
      ReadMem(DW + 24,DW,4); // Fight animation structure // DWord
      ReadMem(DW + 20,CommBlock.YB,4); // Float
      ReadMem(DW + 24,CommBlock.YC,4); // Float
      ReadMem($B6F99C + 56,CommBlock.ZA,4);
    End;
    
    If (CommBlock.Crouch = LastArm) Then
      CommBlock.Crouch := -1
    Else
      LastArm := CommBlock.Crouch;

    //lstChat.Lines.Add('Shoot: '+ IntToStr(CommBlock.CrouchRoll2));

    {ReadMem(CPed + 1135,CommBlock.Roll0,1); // Bukken
    If (CommBlock.Roll0 = 132) Then
      CommBlock.Roll0 := 1
    Else
      CommBlock.Roll0 := 0;
    If Not (CommBlock.Roll0 = LastCrouch) Then
      LastCrouch := CommBlock.Roll0
    Else
      CommBlock.Roll0 := -1;

    If (LastCrouch = 1) Then
    Begin
      ReadMem(CPed + 1148,DW,4); // Animation structure // DWord
      ReadMem(DW + 28,DW,4); // Crouch animation structure // DWord
      ReadMem(DW + 31,CommBlock.Roll2,1); // Byte
      ReadMem(DW + 32,CommBlock.Roll1,4); // Float
    End;}
  End
  Else If (CommBlock.State = 50) and (CommBlock.Car < 2000) Then
  Begin
    ReadMem(CPos + 0,CommBlock.XA,4); // XA

    ReadMem(CPos + 4,CommBlock.XB,4); // XB

    ReadMem(CPos + 8,CommBlock.XC,4); // XC

    ReadMem(CPos + 16,CommBlock.YA,4); // YA

    ReadMem(CPos + 20,CommBlock.YB,4); // YB

    ReadMem(CPos + 24,CommBlock.YC,4); // YC

    ReadMem(CPos + 32,CommBlock.ZA,4); // ZA

    ReadMem(CPos + 36,CommBlock.ZB,4); // ZB

    ReadMem(CPos + 40,CommBlock.ZC,4); // ZC

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

    ReadMem(CVehicle + 1180,F1,4); // Gas pedal
    ReadMem(CVehicle + 1184,F2,4); // Break pedal
    If (F1 = 1.0) And (F2 = 1.0) Then I := 9
    Else If (F2 > 0.0) Then I := 1
    Else If (F1 > 0.0) Then I := 9
    Else If (CommBlock.SpeedX > 0.0) Or (CommBlock.SpeedY > 0.0) Or (CommBlock.SpeedZ > 0.0) Then I := 9
    Else If (CommBlock.SpeedX = 0.0) And (CommBlock.SpeedY = 0.0) And (CommBlock.SpeedZ = 0.0) Then I := 15
    Else I := 9;
    CommBlock.Anim := I;
  End;

  CommBlock.Command := 'SYNC';
  CommBlock.PlayerID := PlayerID;
  Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
end;

procedure TfrmMain.SyncWrite(CMB : TCommBlock);
var
  CPed, CPed0, CPos, CVehicle, State, CDummy, CDPos, DW : DWord;
  F, Rad, Distance : Single;
begin
  If (SAOn = False) or (Read = False) Then
    Exit;

  WriteMem(ScriptBase + (4 * (70+(CMB.PlayerID-1))),CMB.Active,4); // Active

  WriteMem(ScriptBase + (4 * (50+(CMB.PlayerID-1))),CMB.Car,4);

  //ReadMem(ScriptBase + (4 * (170+(CMB.PlayerID-1))),CPed,4);
  //Log(IntToStr(CPed));
  If (CMB.Car > 999) or (CMB.Active = 0) or (CPed = 0) Then
    Exit;

  ReadMem($B6F5F0,CPed0,4);
  CPed := CPed0 + (1988 * CMB.PlayerID);
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
    WriteMem(CPed + 1328,CMB.State,4); // State

    WriteMem(CPed + 1332,CMB.Anim,4); // Run animation

    WriteMem(CPed + 1344,CMB.XC,4); // Health

    WriteMem(CPed + 1352,CMB.YA,4); // Armor

    {If (CMB.Roll0 > -1) Then
      WriteMem(ScriptBase + (4 * (110+(CMB.PlayerID-1))),CMB.Roll0,4);
    ReadMem(CPed + 1148,DW,4);
    ReadMem(DW + 28,DW,4);
    WriteMem(DW + 31,CMB.Roll2,1);
    WriteMem(DW + 32,CMB.Roll1,4);}

    //WriteMem(CPed + 1372,CMB.YB,4); // Target rotation

    If (CMB.Crouch > -1) Then
    Begin
      PlrArmed[CMB.PlayerID] := CMB.Crouch;
      WriteMem(ScriptBase + (4 * (150+(CMB.PlayerID-1))),CMB.Crouch,4);
    End;

    If not (CMB.CrouchRoll2 = 1) Then
    Begin
      WriteMem(CPed + 1372,CMB.XA,4); // Rotation
      //WriteMem(CPed + 1372,CMB.XA,4); // Rotation

      //WriteMem(CPed + 1332,CMB.Anim,4); // Run animation

      If (CMB.CrouchRoll2 = 2) and not (PlrShoot[CMB.PlayerID] = CMB.CrouchRoll2) Then
      Begin
        PlrShoot[CMB.PlayerID] := CMB.CrouchRoll2;
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
    End
    Else
    Begin
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
      Distance := 5.0;
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

      F := (CMB.PosZ + ((CMB.ZA-20) * -1.25)) - 50.0;
      WriteMem(CDPos + 56,F,4);

      //If not (PlrShoot[CMB.PlayerID] = CMB.CrouchRoll2) or (CMB.CrouchRoll2 = 1) Then
      //Begin
        PlrShoot[CMB.PlayerID] := CMB.CrouchRoll2;
        WriteMem(ScriptBase + (4 * (130+(CMB.PlayerID-1))),CMB.CrouchRoll2,4);
      //End;
    End;
  End
  Else If (State = 50) And (CMB.State = 50) Then
  Begin
    WriteMem(CPed + 1328,State,4); // State (Driving etc.)

    WriteMem(CPos + 0,CMB.XA,4);

    WriteMem(CPos + 4,CMB.XB,4);

    WriteMem(CPos + 8,CMB.XC,4);

    WriteMem(CPos + 16,CMB.YA,4);

    WriteMem(CPos + 20,CMB.YB,4);

    WriteMem(CPos + 24,CMB.YC,4);

    WriteMem(CPos + 32,CMB.ZA,4); // ZA

    WriteMem(CPos + 36,CMB.ZB,4); // ZB

    WriteMem(CPos + 40,CMB.ZC,4); // ZC

    WriteMem(ScriptBase + (4 * (40+(CMB.PlayerID-1))),CMB.Anim,4);

    WriteMem(CVehicle + 68,CMB.SpeedX,4);

    WriteMem(CVehicle + 72,CMB.SpeedY,4);

    WriteMem(CVehicle + 76,CMB.SpeedZ,4);

    WriteMem(CVehicle + 80,CMB.SpinZ,4);

    WriteMem(CVehicle + 84,CMB.SpinY,4);

    WriteMem(CVehicle + 88,CMB.SpinZ,4);

    WriteMem(CVehicle + 1172,CMB.WheelAngle1,4);

    WriteMem(CVehicle + 1176,CMB.WheelAngle2,4);

    WriteMem(CVehicle + 2020,CMB.Wheel1,4); // Wheel 1 suspension
    WriteMem(CVehicle + 2024,CMB.Wheel2,4); // Wheel 2 suspension
    WriteMem(CVehicle + 2028,CMB.Wheel3,4); // Wheel 3 suspension
    WriteMem(CVehicle + 2032,CMB.Wheel4,4); // Wheel 4 suspension

    WriteMem(CVehicle + 1216,CMB.CrouchRoll1,4); // Health

    //WriteMem(CVehicle + 2276,CMB.CrouchRoll1,4); // Fire

    WriteMem(CVehicle + 152,CMB.Roll1,4); // G Force

    WriteMem(CVehicle + 2156,CMB.ExtraAngle,4);
  End;
end;

procedure TfrmMain.tmrSync2Timer(Sender: TObject);
var
  CPed, CVehicle : DWord;
  CommBlock : TCommBlock;
  I : Integer;
begin
  If (Client.Connected = False) or (SAOn = False) or (Read = False) Then
    Exit;

  ReadMem($B6F5F0,CPed,4);

  ReadMem(CPed + 1328,CommBlock.State,4); // State (Walking, Driving)

  ReadMem(ScriptBase + (4 * 0),CommBlock.Car,4); // Player Car
  ReadMem(ScriptBase + (4 * 2),I,4); // Passenger
  If (I = 1) Then
    CommBlock.Car := CommBlock.Car + 2000
  Else If (I = 2) Then
    CommBlock.Car := CommBlock.Car + 4000
  Else If (I = 3) Then
    CommBlock.Car := CommBlock.Car + 6000;

  ReadMem($B7CE50,CommBlock.Roll2,4); // Money

  If (CommBlock.State = 1) Then
  Begin
    ReadMem(CPed + 47,CommBlock.Interior,1); // Interior
  End
  Else If (CommBlock.State = 50) and (CommBlock.Car < 2000) Then
  Begin
    ReadMem(CPed + 1420,CVehicle,4); // Car pointer

    ReadMem(CVehicle + 2156,CommBlock.XA,4); // Plane 1

    ReadMem(CVehicle + 2508,CommBlock.XB,4); // Plane 2

    ReadMem(CVehicle + 2560,CommBlock.Interior,1); // Plane 3

    ReadMem(CVehicle + 1076,CommBlock.Active,1); // Car color 1

    ReadMem(CVehicle + 1077,CommBlock.Crouch,1); // Car color 2

    ReadMem(ScriptBase + (4 * 3),CommBlock.CrouchRoll2,4); // Paintjob

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
  CPed, CPed0, CVehicle, State : DWord;
  SCMID : String;
  ID : Integer;
begin
  If (SAOn = False) or (Read = False) Then
    Exit;

  ReadMem($B6F5F0,CPed0,4);
  //ReadMem(ScriptBase + (4 * (170+(CMB.PlayerID-1))),CPed,4);
  If (CPed = 0) Then
    Exit;
  CPed := CPed + (1988 * CMB.PlayerID);
  If (ID = -1) Then
  Begin
    lstNameTags.Items.Add(CMB.Nick);
    lstNameTags.Items.Add(SCMID);
  End
  Else
  Begin
    ID := ID + 1;
    lstNameTags.Items[ID] := SCMID;
  End;
  If (CMB.Car > 1000) Then
    Exit;
    
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

    WriteMem(CVehicle + 1076,CMB.Active,1); // Car color 1

    WriteMem(CVehicle + 1077,CMB.Crouch,1); // Car color 2

    WriteMem(ScriptBase + (4 * (110+(CMB.PlayerID-1))),CMB.CrouchRoll2,4); // Paintjob

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
  Begin
    CommBlock.Command := 'PING';
    CommBlock.Mssg := Client.Host +':'+ IntToStr(Client.Port);
    Client.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
    //Client.Disconnect;
    Exit;  
  End;
  CommBlock.Command := 'JOIN';
  CommBlock.PlayerID := 0;
  CommBlock.Interior := 13;
  Pass1 := edtPassword.Text;
  Pass2 := edtAdminPass.Text;
  If (Pass1 = '') Then
    Pass1 := '0';
  If (Pass2 = '') Then
    Pass2 := '0';
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
    btnChatSend.Click;
end;

procedure TfrmMain.btnChatSendClick(Sender: TObject);
var
  CommBlock : TCommBlock;
  Now, Temp : String;
  CPed, CPos, DW, CVehicle : DWord;
  PosX, PosY, PosZ : Single;
  i : Integer;
  Arr : TSplitArray;
  F : Single;
begin
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
    Log('* Your chat message too long');
    Exit;
  End;
  Try
    Arr := Split(Now,' ');
  Except
  End;
  If (Now = '/position') Then
  Begin
    If (SAOn = False) Then
    Begin
      Log('*** To execute this command you must be ingame');
      Exit;
    End;
    ReadMem($B6F5F0,CPed,4);
    ReadMem(CPed + 1328,DW,4);
    If (DW = 50) Then
    Begin
      ReadMem(CPed + 1420,CVehicle,4);
      ReadMem(CVehicle + 20,CPos,4);
    End
    Else
      ReadMem(CPed + 20,CPos,4);
    ReadMem(CPos + 48,PosX,4);
    ReadMem(CPos + 52,PosY,4);
    ReadMem(CPos + 56,PosZ,4);
    Log('*** Your position: '+ FloatToStr(PosX) +' '+ FloatToStr(PosY) +' '+ FloatToStr(PosZ));
    IngChat := '';
    edtChatText.Clear;
    Exit;
  End
  Else If (Now = '/rotz') Then
  Begin
    If (SAOn = False) Then
    Begin
      Log('*** To execute this command you must be ingame');
      Exit;
    End;
    ReadMem($B6F99C + 56,PosZ,4);
    Log('*** Z cam: '+ FloatToStr(PosZ));
    IngChat := '';
    edtChatText.Clear;
    Exit;
  End
  Else If (Now = '/kill') Then
  Begin
    If (SAOn = False) Then
    Begin
      Log('*** To execute this command you must be ingame');
      Exit;
    End;
    ReadMem($B6F5F0,CPed,4);
    //DW := 55;
    //WriteMem(CPed + 1328,DW,4);
    F := 0.0;
    WriteMem(CPed + 1344,F,4);
    IngChat := '';
    edtChatText.Clear;
    Exit;
  End
  Else If (Now = '/players') Then
  Begin
    For i := 0 To Pred(lstPlayers.Count) Do
    Begin
      If (Temp = '') Then
        Temp := lstPlayers.Items[i]
      Else
        Temp := Temp +' , '+ lstPlayers.Items[i];
    End;
    Log('*** Players: '+ Temp);
    IngChat := '';
    edtChatText.Clear;
    Exit;
  End
  Else If ( Copy(Now,0,1) = '/' ) Then
  Begin
    //Log('*** Command not recognized');
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
  End;
  If (SAOn = False) or (Client.Connected = False) Then
  Begin
    tmrSync.Interval := 5000;
    tmrSync2.Interval := 5000;
    tmrSync.Enabled := False;
    tmrSync2.Enabled := False;
    tmrChat.Enabled := False;
    PlrFreeze := False;
    GO := False;
    Exit;
  End;
  If (Read = True) Then
  Begin
    tmrSync.Enabled := True;
    tmrSync2.Enabled := True;
  End;
  ReadMem($B79044,Val,4);
  If (Val > 0) Then
  Begin
    KillTask('gta_sa.exe');
    Err('Suspected cheating');
  End;
  tmrChat.Enabled := True;
  ReadMem($B6F5F0,CPed,4);
  ReadMem(CPed + 1328,State,4);
  tmrSync2.Interval := 750;
  If (State = 55) Then
  Begin
    If (LastDeath = 0) Then
    Begin
      ReadMem(CPed + 1888,Weap,4);
      ReadMem(CPed + 1892,Who,4);
      temp := 0;
      WriteMem(CPed + 1888,temp,4);
      WriteMem(CPed + 1892,temp,4);

      If Not (Who = 0) Then
      Begin
        Try
          tmp := StrToFloat(IntToStr(Who));
          tmp := (Who - CPed) / 1988;
          Who := StrToInt(FloatToStr(tmp));
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
    tmrSync.Interval := 75;
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
    tmrSync.Interval := 60;
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

    Else If (SpeedX < 0.1) Then tmrSync.Interval := 70
    Else If (SpeedY < 0.1) Then tmrSync.Interval := 70
    Else If (SpeedZ < 0.1) Then tmrSync.Interval := 70;}

  End;
  If (PlrFreeze = True) Then
    tmrSync.Interval := 200;
end;

procedure TfrmMain.btnAboutClick(Sender: TObject);
begin
  ShowMessage(
  'San Andreas Party 0.2.0.0 BETA'+ #13#10#13#10 +
  'Created by: Ywa*NL'+ #13#10 +
  'E-mail: team@sa-party.com'+ #13#10 +
  'WWW: www.sa-party.com'+ #13#10#13#10 +
  'Thanks to: Mount, mabako, Peter, CookieMonster'+ #13#10 +'AlienX, VRocker, MrJax, JGuntherS'+ #13#10
  );
end;

procedure TfrmMain.tmrChatTimer(Sender: TObject);
var
  Str : String;
begin
  If (SAOn = False) Then
    Exit;
  lstNameTags.Items.SaveToFile(GameDir +'\playerlist.fle');
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
  memChat1.Lines.SaveToFile(GameDir +'\chatbox.fle');
  memChat1.Lines.Delete(0);
end;

procedure TfrmMain.Log(Mssg : String);
begin
  lstChat.Lines.Add(Mssg);
  If (SAOn = False) Then
    Exit;
  memChat1.Lines.Add(Mssg);
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
  W, Int, i2, Val : Integer;
  Float : Single;
  Arr : TSplitArray;
  ReNOP : Array of Integer;
  offset : Longword;
begin
  If (MapCars.Count = LastLoad) Then
  Begin
    If (LD = True) Then
      Exit;
  End
  Else
  Begin
    LastLoad := MapCars.Count;
  End;
  LD := False;
  If (Pred(ML) = Pred(MapCars.Count)) Then
  Begin
    If (FT = True) Then
      Exit;
    FT := True;
    LD := True;
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

    WriteString($BAB040,' ');
    //Int := -1;
    //WriteMem(ScriptBase + (4 * 28),Int,4); // We are done!

    LogIngame('*** Press FIRE to spawn and press LEFT/RIGHT to select a different spawnpoint');
    //WriteString($BAB040,'~r~San ~g~Andreas ~b~Party~n~~w~Press ~p~FIRE ~w~to spawn~n~Press ~p~LEFT/RIGHT ~w~to select a different spawnpoint');

    //MapCars.Clear;

    Read := True;
    Exit;
  End;
  ReadMem(ScriptBase + (4 * 28),W,4);
  If Not (W = 2) Then
    Exit;

  Try
    Arr := Split(MapCars.Items.Strings[ML],'|');
  Except
    ML := ML + 1;                                       
    Exit;
  End;

    If (Arr[0] = 'v') Then
    Begin
      Int := StrToInt(Arr[1]); // Vehicle ID
      WriteMem($00A499E4,Int,4);

      Float := DecimalSec(Arr[2]); // Position X
      WriteMem($00A499D4,Float,4);

      Float := DecimalSec(Arr[3]); // Position Y
      WriteMem($00A499D8,Float,4);

      Float := DecimalSec(Arr[4]); // Position Z
      WriteMem($00A499DC,Float,4);

      Float := DecimalSec(Arr[5]); // Rotation
      WriteMem($00A499E0,Float,4);

      Int := 1; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'o') Then
    Begin
      Int := StrToInt(Arr[1]); // Model ID
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
    Else If (Arr[0] = 's') Then
    Begin
     //Int := StrToInt(Arr[1]); // Skin ID
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
      Int := StrToInt(Arr[1]); // Model ID
      WriteMem($00A499E4,Int,4);

      Float := DecimalSec(Arr[3]); // Position X
      WriteMem($00A499D4,Float,4);

      Float := DecimalSec(Arr[4]); // Position Y
      WriteMem($00A499D8,Float,4);

      Float := DecimalSec(Arr[5]); // Position Z
      WriteMem($00A499DC,Float,4);

      Int := StrToInt(Arr[2]); // Array type
      WriteMem(ScriptBase + (4 * 34),Int,4);

      Int := 3; // Array type
      WriteMem($00A499EC,Int,4);
    End
    Else If (Arr[0] = 'w') Then
    Begin
      ReadMem(ScriptBase + (4 * 5),Int,4); // Weapon ID
      If (Int = 0) Then
      Begin
        Int := StrToInt(Arr[2]);
        WriteMem(ScriptBase + (4 * 10),Int,4); // Weapon model ID
        Int := StrToInt(Arr[1]);
        WriteMem(ScriptBase + (4 * 5),Int,4); // Weapon ID
      End
      Else
        Exit;
    End;
    Int := 1;
    WriteMem(ScriptBase + (4 * 28),Int,4); // Write-able

    //WriteString($BAB040,'Loading map. Please wait.~n~Done: '+ IntToStr(ML) +'/'+ IntToStr(Pred(MapCars.Count)));
    ML := ML + 1;
end;

procedure TfrmMain.procSATerminate(Sender: TObject; ExitCode: Cardinal);
var
  F : String;
begin
  F := GameDir +'\saplauncher.exe';
  If ( FileExists(F) ) Then
    DeleteFile(F);
end;

procedure TfrmMain.ClientDisconnected(Sender: TObject);
begin
  If (Disconnected = False) and (Browsing = False) Then
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
    btnConnect.Enabled := True;
    btnStartGame.Enabled := False;
    btnGameDir.Enabled := False;
  End
  Else If (Browsing = True) Then
  Begin
    ClientHandleThread.Terminate;
    GotLast := 0;
  End;
end;

procedure TfrmMain.btnRefreshClick(Sender: TObject);
var
  Str : String;
  Arr, Arr2 : TSplitArray;
  Skip : Boolean;
  i, Int, FirstConnect : Integer;
begin
  btnRefresh.Enabled := False;
  lblStatus.Caption := 'Cleaning current list...';
  lstBrowser.Clear;
  lblStatus.Caption := 'Retrieving server list...';
  Str := HTTP.Get('http://84.16.249.241/server.lst');
  If (Str = '') Then
  Begin
    lblStatus.Caption := 'No servers found!';
    btnRefresh.Enabled := True;
    Exit;
  End;
  lblStatus.Caption := 'Generating browser list...';
  Try
    Arr := Split(Str,' ');
  Except
    btnRefresh.Enabled := True;
    lstBrowser.Clear;
    lblStatus.Caption := 'Error (ID: B3)';
    Exit;
  End;
  For i := 0 To High(Arr) Do
  Begin
    lstBrowser.Items.Add(Arr[i]);
    Application.ProcessMessages;
  End;
  lblStatus.Caption := 'Pinging servers...';
  Browsing := True;
  Try
    Int := Pred(lstBrowser.Items.Count);
    Arr2 := Split(lstBrowser.Items[Int],':');
    lstBrowser.Items[Int] := Arr2[0] +':'+ Copy(Arr2[1],0,4);
  Except
    lstBrowser.Clear;
    lblStatus.Caption := 'Error (ID: B2)';
    Exit;
  End;
  If (Client.Connected = True) Then
  Begin
    Err('Fatal error (ID: B3)');
    Application.Terminate;
  End;
  For i := Pred(lstBrowser.Items.Count) DownTo 0 Do
  Begin
    Application.ProcessMessages;
    Skip := False;
    GotLast := 1;
    Try
      Arr2 := Split(lstBrowser.Items[i],':');
    Except
      lstBrowser.Items.Delete(i); // Offline
      GotLast := 0;
      Next;
    End;
    Try
      Client.Host := Arr2[0];
      Client.Port := StrToInt(Arr2[1]);
      Client.Connect(1000);
    Except
      lstBrowser.Items.Delete(i); // Offline
      GotLast := 0;
      Next;
    End;
    ClientHandleThread := TClientHandleThread.Create(True);
    ClientHandleThread.FreeOnTerminate := True;
    ClientHandleThread.Resume;
    Client.Socket.UseNagle := False;
    While (GotLast = 1) Do
    Begin
      Sleep(20);
      Application.ProcessMessages;
    End;
  End;
  If (lstBrowser.Items.Count = 0) Then
    lblStatus.Caption := 'No servers found!'
  Else
    lblStatus.Caption := IntToStr(frmMain.lstBrowser.Items.Count) +' online server(s) found!';
  btnRefresh.Enabled := True;
  Browsing := False;
end;

procedure TfrmMain.tabBrowserShow(Sender: TObject);
begin
  If (Client.Connected = True) Then
  Begin
    lstBrowser.Visible := False;
    btnRefresh.Visible := False;
    btnBrowserConnect.Visible := False;
    btnBrowserConnect.Enabled := False;
    btnRefresh.Enabled := False;
    lblStatus.Caption := 'Disconnect first.';
    Exit;
  End;
  grpLobby.Width := 625;
  grpGame.Visible := False;
  pagBrowser.Width := 601;
  lstBrowser.Width := 585;
  btnRefresh.Left := 512;
end;

procedure TfrmMain.tabBrowserHide(Sender: TObject);
begin
  lstBrowser.Visible := True;
  btnRefresh.Visible := True;
  btnBrowserConnect.Visible := True;
  btnBrowserConnect.Enabled := True;
  btnRefresh.Enabled := True;
  lblStatus.Caption := '';
  grpLobby.Width := 225;
  grpGame.Visible := True;
  pagBrowser.Width := 201;
  lstBrowser.Width := 185;
  btnRefresh.Left := 112;
end;

procedure TfrmMain.btnBrowserConnectClick(Sender: TObject);
var
  Arr, Arr2 : TSplitArray;
  I : Integer;
begin
  If (lstBrowser.Count = 0) Or (lstBrowser.ItemIndex = -1) Then
  Begin
    ShowMessage('No server selected');
    Exit;
  End;
  Browsing := False;
  i := lstBrowser.ItemIndex;
  Try
    Arr := Split(lstBrowser.Items[i],' - Host: ');
    Arr2 := Split(Arr[1],':');
  Except
    Exit;
  End;
  edtHost.Text := Arr2[0];
  edtPort.Text := Arr2[1];
  tabQuickConnect.Show;
  btnConnect.Click;

end;

procedure TfrmMain.tmrTextClearTimer(Sender: TObject);
var
  Mssg : String;
begin
  Mssg := ' ';
  WriteString($BAAEC0,Mssg);
  WriteString($BAB040,Mssg);
  WriteString($BAAD40,Mssg);
  WriteString($BAACC0,Mssg);
  WriteString($BAADC0,Mssg);
  WriteString($BAAFC0,Mssg);
  tmrTextClear.Enabled := False;
end;

end.


// 0xBAB22C [4 bytes] = health bar color (RGBA) in bytes
