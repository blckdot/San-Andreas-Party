unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IdBaseComponent, IdComponent, IdUDPBase, IdUDPClient, MD5,
  ComCtrls, XPMan, JvBaseDlg, JvSelectDirectory, Registry, ShellAPI,
  JvTimer, ExtCtrls, math, IdTCPConnection, IdTCPClient;

type
  TSplitArray = array of String;
  TReceiveThread = Class( TThread )
  Private
    FResultStream: TStream;
  Protected
    Procedure Execute; Override;
  Public
    Property ResultStream: TStream read FResultStream write FResultStream;
  End;
  TfrmMain = class(TForm)
    edtHost: TEdit;
    edtPort: TEdit;
    edtNickname: TEdit;
    btnConnect: TButton;
    edtPassword: TEdit;
    memoChat: TMemo;
    edtChat: TEdit;
    btnChat: TButton;
    lstPlayers: TListBox;
    pagMain: TPageControl;
    tabBrowser: TTabSheet;
    tabGame: TTabSheet;
    tabSettings: TTabSheet;
    grpConnect: TGroupBox;
    appXPM: TXPManifest;
    lblHost: TLabel;
    lblHostPort: TLabel;
    lblPassword: TLabel;
    lstBrowser: TListView;
    Label2: TLabel;
    groAbout: TGroupBox;
    AboutText: TLabel;
    lblPlayers: TLabel;
    btnDisconnect: TButton;
    btnSetGameDir: TButton;
    SelectDir: TJvSelectDirectory;
    btnStartGame: TButton;
    tmrProcess: TJvTimer;
    tmrSync: TJvTimer;
    tmrPingCheck: TTimer;
    tmrLoadMap: TJvTimer;
    tmrNicks: TTimer;
    udpClient: TIdTCPClient;
    procedure btnConnectClick(Sender: TObject);
    procedure btnChatClick(Sender: TObject);
    procedure edtChatKeyPress(Sender: TObject; var Key: Char);
    procedure lstPlayersEnter(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure SetConnected(Enabled : Boolean);
    procedure btnSetGameDirClick(Sender: TObject);
    procedure btnStartGameClick(Sender: TObject);
    procedure tmrProcessTimer(Sender: TObject);
    procedure tmrSyncTimer(Sender: TObject);
    procedure WriteSync(Data : String);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Disconnect(LogAllowed : Boolean);
    procedure tmrPingCheckTimer(Sender: TObject);
    function CopyBetween(Source, bs, es : String): String;
    function CopyAfter(Source, bs : String): String;
    function CopyBefore(Source, bs : String): String;
    procedure tmrLoadMapTimer(Sender: TObject);
    procedure tmrNicksTimer(Sender: TObject);
    procedure ParseMessage(Str : String);
    procedure udpClientConnected(Sender: TObject);
    //procedure Log(Str : String);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;
  ReceiveThread : TReceiveThread;

  // Integers
  PlayerID, hProc, SkinID, LastLoad, LoadID, CPLast, CPOLast : Integer;

  // Strings
  Version, GameDir, IngChat : String;

  // Booleans
  Connected, SAOn, SAOnLast, GotPing, LastD33D : Boolean;

  // Overig
  ScriptBase : DWord = $A49960;
  PlayerNick : Array [0..32] of String;
  PlrSCM, PlrJumping, PlrCount : Array [0..32] of Integer;
  Objects : Array[0..1000] of Integer;
  Vehicles : Array[0..5000] of Integer;
  Checkpoints : Array[0..101] of Integer;
  card : Cardinal;
  Chat1, Chat2, TheMap : TStrings;

implementation

{$R *.dfm}

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

procedure WriteMem(Offset: Longword;var Value; Size: Integer);
var
  d : Cardinal;
begin
  VirtualProtectEx(hProc, Pointer(Offset),Size,PAGE_EXECUTE_READWRITE,d);
  WriteProcessMemory(hProc, ptr(Offset),@Value, Size, card);
  VirtualProtectEx(hProc, Pointer(Offset),Size,d,d);
end;

procedure WriteVal(Offset: Longword;var Value);
var
  d : Cardinal;
begin
  VirtualProtectEx(hProc, Pointer(Offset),1,PAGE_EXECUTE_READWRITE,d);
  WriteProcessMemory(hProc, ptr(Offset),@Value, 1, card);
  VirtualProtectEx(hProc, Pointer(Offset),1,d,d);
end;


procedure ReadMem(Offset: Longword;var Value; Size: Integer);
begin
  ReadProcessMemory(hProc, ptr(Offset),@Value, Size, card);
end;

procedure NOP(Offset: Longword;Size: Integer);
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

function GetCameraVerticalAngle(): Single;
begin
  ReadMem($B6FA0C,result,4);
  //result := 2.0 + result * 2.0;
end;

function DecimalSec(F : String): Single;
var
  Dec : String;
begin
  If (DecimalSeparator = '.') Then Dec := ','
  Else If (DecimalSeparator = ',') Then Dec := '.';
  F := StringReplace(F,Dec,DecimalSeparator,[rfReplaceAll,rfIgnoreCase]);
  Try
    result := StrToFloat(F);
  Except
    result := 0.0;
  End;
end;

function GetCameraZAngle(): Single;
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

procedure Err(Text : String);
begin
  MessageDlg(Text,mtError,[mbOk],0);
end;

procedure TfrmMain.SetConnected(Enabled : Boolean);
var
  Val : Integer;
begin
  If (Enabled = False) Then
    tmrPingCheck.Enabled := False;
  Connected := Enabled;
  edtHost.Enabled := not Enabled;
  edtPassword.Enabled := not Enabled;
  edtPort.Enabled := not Enabled;
  edtNickname.Enabled := not Enabled;
  btnConnect.Enabled := not Enabled;
  btnDisconnect.Enabled := Enabled;
  btnStartGame.Enabled := Enabled;
  tabGame.Enabled := Enabled;
  If (Enabled = True) Then
    tabGame.Show;
//  Else
//    tabBrowser.Show;
  If (Enabled = False) Then
    lstPlayers.Clear;
  If (Enabled = False) and (SAOn = True) Then
  Begin
    Val := 1;
    WriteMem($C17050,Val,1);
  End;
end;

procedure Log(Str : String);
begin
  frmMain.memoChat.Lines.Add(Str);
  If (SAOn = False) Then
    Exit;
  Chat1.Add(Str)
end;

function DoStrToInt(Str : String): Integer;
begin
  Try
    result := StrToInt(Str);
  Except
    result := 0;
  End;
end;

function IntToFloat(Int : Integer): Single;
begin
  Try
    result := StrToFloat(IntToStr(Int));
  Except
    result := 0.0;
  End;
end;

function FloatToInt(Float : Single): Integer;
begin
  Try
    result := StrToInt(FloatToStr(Round(Float)));
  Except
    result := 0;
  End;
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


{ Procedure TMyThread.Execute;
var
  Str : String;
  Arr, Arr2 : TSplitArray;
  i, i2, i3, i4, i5, i6 : Integer;
  Bol : Boolean;
  Data2 : Single;
  d : Cardinal;
  ReNOP : Array of Integer;
begin
  while True do
  begin
     If (Connected = False) Then
      Exit;
     Str := frmMain.udpClient.ReceiveString(); }

procedure TReceiveThread.Execute;
begin
  while True do
    if frmMain.udpClient.Connected then
    begin
      frmMain.ParseMessage(frmMain.udpClient.ReadLn('')); // TODO: Decrypt
    end;
end;

procedure TfrmMain.ParseMessage(Str : String);
var
  Arr, Arr2 : TSplitArray;
  i, i2, i3, i4, i5, i6 : Integer;
  Bol : Boolean;
  Data2 : Single;
  d : Cardinal;
  ReNOP : Array of Integer;
begin
  Arr := Split('a|a|a','|');
  Arr2 := Split('a|a|a','|');
     Bol := False;
     If (Str = '') Then
       Bol := True;
     If (Bol = False) Then
     Begin
       Try
         Arr := Split(Str,'|');
       Except
         Bol := True;
       End;
     End;
     If (Bol = False) Then
     Begin
     If (Arr[0] = 'ONFOOT') or (Arr[0] = 'CAR') Then // Onfoot sync!
       frmMain.WriteSync(Str)
     Else If (Arr[0] = 'PING') Then // Ping? Pong!
     Begin
//        Log('PINGG!');
       GotPing := True;
       frmMain.udpClient.WriteLn('PONG|'+ IntToStr(PlayerID));
     End
     Else If (Arr[0] = 'RMAP') Then // Receive map list
       TheMap.Add(frmMain.CopyAfter(Str,'RMAP|'))
     Else If (Arr[0] = 'CONNB') Then // Answer from server @ connection
     Begin
       If (StrToInt(Arr[1]) = 0) Then
       Begin
         PlayerID := StrToInt(Arr[2]);
         Log('*** Connected as player '+ Arr[2]);
         frmMain.udpClient.WriteLn('INFO'); // Get server info (Server name)
         frmMain.udpClient.WriteLn('PLAYERS'); // Get connected players
         SkinID := 0;
         frmMain.tmrPingCheck.Enabled := True;
         frmMain.SetConnected(True);
         frmMain.tmrPingCheck.Interval := 7500;
       End
       Else
       Begin
         frmMain.tmrPingCheck.Interval := 7500;
         If (DoStrToInt(Arr[1]) = 1) Then
           Log('*** Disconnected (Reason: wrong version)')
         Else If (DoStrToInt(Arr[1]) = 2) Then
           Log('*** Disconnected (Reason: the server is full)')
         Else If (DoStrToInt(Arr[1]) = 3) Then
           Log('*** Disconnected (Reason: wrong server password)')
         Else If (DoStrToInt(Arr[1]) = 4) Then
           Log('*** Disconnected (Reason: nickname is already in usage)');
         frmMain.Disconnect(False);
       End;
     End
     Else If (Arr[0] = 'CONNECTED') Then // New player connected
     Begin
       frmMain.lstPlayers.Items.Add(Arr[2]);
       PlayerNick[DoStrToInt(Arr[1])] := Arr[2];
       Log('*** '+ Arr[2] +' has joined the server (ID: '+ Arr[1] +')');
     End
     Else If (Arr[0] = 'CHAT') Then // Chat
     Begin
       If (DoStrToInt(Arr[1]) < 1) Then
         Log(Arr[2])
       Else
         Log(PlayerNick[DoStrToInt(Arr[1])] +': '+ Arr[2]);
     End                                                  
     Else If (Arr[0] = 'INFOB') Then // Info B
     Begin
       Log('-----------------------------------');
       Log('Servername: '+ Arr[1]);
       Log('Players: '+ Arr[2] +'/'+ Arr[3]);
       If (DoStrToInt(Arr[4]) = 1) Then
         Log('Password: Yes')
       Else
         Log('Password: No');
       Log('-----------------------------------');
     End
     Else If (Arr[0] = 'CONNECTED') Then // New player connected
     Begin
       frmMain.lstPlayers.Items.Add(Arr[2]);
       PlayerNick[DoStrToInt(Arr[1])] := Arr[2];
       Log('*** '+ Arr[2] +' joined the server');
     End
     Else If (Arr[0] = 'GAMECLOSED') Then // Player closed the game
     Begin
       i2 := DoStrToInt(Arr[1])-1;
       i3 := 0;
       WriteMem(ScriptBase + (4 * (1100 + i2)),i3,4); // PlrCar
       WriteMem(ScriptBase + (4 * (1200 + i2)),i3,4); // PlrSeat
       i3 := -1;
       WriteMem(ScriptBase + (4 * (200 + i2)),i3,4);
     End
     Else If (Arr[0] = 'SPAWNN') Then // Done server-side spawn stuff and now load the map :D
     Begin
       i2 := 1;
       WriteMem(ScriptBase + (4 * 109),i2,4);
     End
     Else If (Arr[0] = 'SETPOSITION') Then // Set position
     Begin
       ReadMem($B6F5F0,i2,4);
       If (i2 = 0) Then
         TheMap.Add(Str)
       Else
       Begin
         ReadMem(i2 + 20,i2,4);
         Data2 := DecimalSec(Arr[1]);
         WriteMem(i2 + 48,Data2,4); // Position X
         Data2 := DecimalSec(Arr[2]);
         WriteMem(i2 + 52,Data2,4); // Position Y
         Data2 := DecimalSec(Arr[3]);
         WriteMem(i2 + 56,Data2,4); // Position Z
       End;
     End
     Else If (Arr[0] = 'SETHEALTH') Then // Set health
     Begin
       ReadMem($B6F5F0,i2,4);
       Data2 := DecimalSec(Arr[1]);
       WriteMem(i2 + 1344,Data2,4);
     End
     Else If (Arr[0] = 'SETFLAGS') Then // Set flags
     Begin
       ReadMem($B6F5F0,i2,4);
       i3 := DoStrToInt(Arr[1]);
       WriteMem(i2 + 66,i3,1); // Byte
     End
     Else If (Arr[0] = 'SETMONEY') Then // Set money
     Begin
       i2 := DoStrToInt(Arr[1]);
       WriteMem($B7CE50,i2,4);
     End
     Else If (Arr[0] = 'SETARMOR') Then // Set armor
     Begin
       ReadMem($B6F5F0,i2,4);
       Data2 := DecimalSec(Arr[1]);
       WriteMem(i2 + 1352,Data2,4);
     End
     Else If (Arr[0] = 'SETWEATHER') Then // Set weather
     Begin
       i2 := DoStrToInt(Arr[1]);
       WriteMem($C81318,i2,4);
       WriteMem($C8131C,i2,4);
       WriteMem($C81320,i2,4);
     End
     Else If (Arr[0] = 'SETTIME') Then // Set time
     Begin
       i2 := DoStrToInt(Arr[1]);
       i3 := DoStrToInt(Arr[2]);
       WriteMem($B70153,i2,1); // Hour
       WriteMem($B70152,i3,1); // Minute
     End
     Else If (Arr[0] = 'SETCCOLOR') Then // Set custom color
     Begin
       i2 := DoStrToInt(Arr[1]);
       i3 := DoStrToInt(Arr[2]); // R
       i4 := DoStrToInt(Arr[3]); // G
       i5 := DoStrToInt(Arr[4]); // B
       i6 := DoStrToInt(Arr[5]); // A

       WriteMem($BAB22C + (i2 * 4),i3,1);
       WriteMem($BAB22C + (i2 * 4) + 1,i4,1);
       WriteMem($BAB22C + (i2 * 4) + 2,i5,1);
       WriteMem($BAB22C + (i2 * 4) + 3,i6,1);
     End
     Else If (Arr[0] = 'SETDRAWCLOCK') Then // Set draw clock
     Begin
      i2 := DoStrToInt(Arr[1]);
      If (i2 = 1) Then // Aan
        NOP($58EC21,5)
      Else
      Begin // Uit
        SetLength(ReNOP,5);
        ReNOP[0] := $E8;   // E8 DA BA 18 00
        ReNOP[1] := $DA;
        ReNOP[2] := $BA;
        ReNOP[3] := $18;
        ReNOP[4] := $00;
        For i3 := 0 To 4 Do
        Begin
          i4 := ReNOP[i3];
          WriteMem($53E799 + i3,i4,1);
        End;
      End;
     End
     Else If (Arr[0] = 'SETDRAWHEALTHBAR') Then // Set draw healthbar
     Begin
      i2 := DoStrToInt(Arr[1]);
      If (i2 = 1) Then // Aan
        NOP($58EE75,5)
      Else
      Begin // Uit
        SetLength(ReNOP,5);
        ReNOP[0] := $E8;   // E8 C6 2C 29 00
        ReNOP[1] := $C6;
        ReNOP[2] := $2C;
        ReNOP[3] := $29;
        ReNOP[4] := $00;
        For i3 := 0 To 4 Do
        Begin
          i4 := ReNOP[i3];
          WriteMem($58EE75 + i3,i4,1);
        End;
      End;
     End
     Else If (Arr[0] = 'SETDRAWARMOURBAR') Then // Set draw armourbar
     Begin
      i2 := DoStrToInt(Arr[1]);
      If (i2 = 1) Then // Aan
        NOP($58EF6B,5)
      Else
      Begin // Uit
        SetLength(ReNOP,5);
        ReNOP[0] := $E8;   // E8 30 A1 FF FF
        ReNOP[1] := $30;
        ReNOP[2] := $A1;
        ReNOP[3] := $FF;
        ReNOP[4] := $FF;
        For i3 := 0 To 4 Do
        Begin
          i4 := ReNOP[i3];
          WriteMem($58EE75 + i3,i4,1);
        End;
      End;
     End
     Else If (Arr[0] = 'FREEZETIME') Then // Freeze time
     Begin
      i2 := DoStrToInt(Arr[1]);
      WriteVal($969167,i2);
     End
     Else If (Arr[0] = 'FREEZECLOCK') Then // Set freeze clock
     Begin
      i2 := DoStrToInt(Arr[1]);
      WriteVal($969168,i2);
     End
     Else If (Arr[0] = 'SETGRAVITY') Then // Set gravity
     Begin
       Data2 := DecimalSec(Arr[1]);
       VirtualProtectEx(hProc, Pointer($863984),4,PAGE_EXECUTE_READWRITE,d);
       WriteMem($863984,Data2,4);
       VirtualProtectEx(hProc, Pointer($863984),4,d,d);
     End
     Else If (Arr[0] = 'SETWATERWALK') Then // Set water walk
     Begin
       i2 := DoStrToInt(Arr[1]);
       WriteMem($6C2759,i2,1);
     End
     Else If (Arr[0] = 'SETFLY') Then // Set flying cars
     Begin
       i2 := DoStrToInt(Arr[1]);
       WriteMem($969160,i2,1);
     End
     Else If (Arr[0] = 'SETMONFOR') Then // Set money formatting
     Begin
       WriteMem($866C94,Arr[1],SizeOf(Arr[1]));
     End
     Else If (Arr[0] = 'SETSKIN') Then // Set skin
     Begin
       SkinID := DoStrToInt(Arr[1]);
     End
     Else If (Arr[0] = 'DISCONNECTED') Then // New player disconnected
     Begin
       frmMain.lstPlayers.Items.Delete(frmMain.lstPlayers.Items.IndexOf(PlayerNick[DoStrToInt(Arr[1])]));
       If (DoStrToInt(Arr[2]) = 0) Then
         Log('*** '+ PlayerNick[DoStrToInt(Arr[1])] +' left the server (Reason: Quit)')
       Else If (DoStrToInt(Arr[2]) = 1) Then
         Log('*** '+ PlayerNick[DoStrToInt(Arr[1])] +' left the server (Reason: Timed out)')
       Else If (DoStrToInt(Arr[2]) = 2) Then
         Log('*** '+ PlayerNick[DoStrToInt(Arr[1])] +' left the server (Reason: Kicked)')
       Else If (DoStrToInt(Arr[2]) = 3) Then
         Log('*** '+ PlayerNick[DoStrToInt(Arr[1])] +' left the server (Reason: Banned)');
       PlayerNick[DoStrToInt(Arr[1])] := '';
     End
     Else If (Arr[0] = 'BAI') Then // Server wil client weghebben @_@
     Begin
       If (DoStrToInt(Arr[1]) = 0) Then
         Log('*** Disconnected from the server (Reason: Quit)')
       Else If (DoStrToInt(Arr[1]) = 1) Then
         Log('*** Disconnected from the server (Reason: Serv. Timed out)')
       Else If (DoStrToInt(Arr[1]) = 2) Then
         Log('*** Disconnected from the server (Reason: Kicked)')
       Else If (DoStrToInt(Arr[1]) = 3) Then
         Log('*** Disconnected from the server (Reason: Banned)')
       Else If (DoStrToInt(Arr[1]) = 4) Then
         Log('*** Disconnected from the server (Reason: Server closed)')
       Else
         Log('*** Disconnected from the server (Reason: Unknown '+ Arr[1] +')');
       frmMain.Disconnect(False);
     End
     Else If (Arr[0] = 'PLAYERSB') Then // Connected players
     Begin
       i := High(Arr)-1;
       If (i > 0) Then
       Begin
         For i2 := 1 To i Do
         Begin
           Arr2 := Split(Arr[i2],' ');
           i3 := DoStrToInt(Arr2[0]);
           PlayerNick[i3] := Arr2[1];
           frmMain.lstPlayers.Items.Add(Arr2[1]);
           //Log('*** Connected player: '+ Arr2[1] +' (ID: '+ IntToStr(i3) +')');
         End;
         If (i = 1) Then
           Log('*** You are the first player in this server')
         Else If (i = 2) Then
           Log('*** There is '+ IntToStr(i-1) +' player connected!')
         Else
           Log('*** There are '+ IntToStr(i-1) +' players connected!')
       End
       Else
       Begin
         Log('*** No ingame players');
       End;
     End
     Else
     Begin
       Log('*** Unknown packet received: '+ Str);
     End;
     End;

     // SetFlags
     // SetMoney
//  end;
End;

function calcMD5(Buffer : String): String;
begin
  Result := LowerCase(GetMD5(@Buffer[1], Length(Buffer)));
end;

procedure TfrmMain.btnConnectClick(Sender: TObject);
var
  reg : TRegistry;
begin
    Log('*** Connecting...');
    btnConnect.Enabled := False;
    edtHost.Enabled := False;
    edtPort.Enabled := False;
    edtNickname.Enabled := False;
    edtPassword.Enabled := False;
    tabGame.Show;
    edtNickname.Text := StringReplace(edtNickname.Text, '|', '.',[rfReplaceAll, rfIgnoreCase]);
    edtPassword.Text := StringReplace(edtPassword.Text, '|', '.',[rfReplaceAll, rfIgnoreCase]);
    udpClient.Host := edtHost.Text;
    udpClient.Port := DoStrToInt(edtPort.Text);
    try
      udpClient.Connect;
    except
      Log('*** Couldn''t establish a connection');
      Connected := False;
      Disconnect(False);
      Exit;
    end;

    If (udpClient.Connected = False) Then
    Begin
      Log('*** Couldn''t establish a connection');
      Connected := False;
      Disconnect(False);
      Exit;
    End;
    Connected := True;
    udpClient.WriteLn('CONN|P21@sa41-Elise|'+ edtNickname.Text +'|'+ calcMD5(edtPassword.Text));
    tmrPingCheck.Interval := 5000;
    tmrPingCheck.Enabled := True;
    reg := TRegistry.Create;
    Try
      reg.RootKey := HKEY_CURRENT_USER;
      reg.OpenKey('Software\SA-Party', True);
      reg.WriteString('Host', edtHost.Text);
      reg.WriteString('Port', edtPort.Text);
      reg.WriteString('Nickname', edtNickname.Text);
      reg.CloseKey;
    Finally
      reg.Free;
    End;
end;

procedure TfrmMain.btnChatClick(Sender: TObject);
var
  Str : String;
begin
  If Not (edtChat.Text <> '') or (Connected = False) Then
    Exit;
  If ( Length(edtChat.Text) > 80 ) Then
  Begin
    Log('*** Your chat message is too long (Limit: 80 characters)');
    Exit;
  End;
  If (edtChat.Text = '/cam') Then
  Begin
    If (SAOn = False) Then
    Begin
      Log('>>> To execute this command you must be ingame');
      Exit;
    End;
    //ReadMem($B6F99C + 56,PosZ,4);
    Log ('* CAMERA ZAngle: '+ FloatToStr(GetCameraZAngle) +' - VAngle: '+ FloatToStr(GetCameraVerticalAngle));
    edtChat.Clear;
    edtChat.SetFocus;
    Exit;
  End;
  Str := StringReplace(edtChat.Text, '|', '.',[rfReplaceAll, rfIgnoreCase]);
  udpClient.WriteLn('CHAT|'+ IntToStr(PlayerID) +'|'+ Str);
  edtChat.Clear;
  edtChat.SetFocus;
end;

procedure TfrmMain.edtChatKeyPress(Sender: TObject; var Key: Char);
begin
  If (Key = #13) Then
  Begin
    Key := #0;
    btnChat.Click;
  End;
end;

procedure TfrmMain.lstPlayersEnter(Sender: TObject);
begin
  edtChat.SetFocus;
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
  Version := '0.4.0.0 ALPHA v3';
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

  tabBrowser.Show;

  // Geniaal _O_
  Chat1 := TStringList.Create();
  Chat2 := TStringList.Create();

  TheMap := TStringList.Create;
end;

procedure TfrmMain.Disconnect(LogAllowed : Boolean);
begin
  TheMap.Clear;
  If (udpClient.Connected = True) Then
  Begin
    udpClient.WriteLn('DISCONNECT|'+ IntToStr(PlayerID));
    udpClient.Disconnect;
    SetConnected(False);
    Connected := False;
    tmrPingCheck.Enabled := False;
    If (LogAllowed = True) Then
      Log('*** Disconnected (Reason: exit)');
  End;
end;

procedure TfrmMain.btnDisconnectClick(Sender: TObject);
begin
  Disconnect(True);
end;

procedure TfrmMain.btnSetGameDirClick(Sender: TObject);
var
  reg : TRegistry;
begin
  If (SelectDir.Execute) Then
  Begin
    If not( FileExists( SelectDir.Directory + '\gta_sa.exe' ) ) Or not ( FileExists( SelectDir.Directory + '\stream.ini' ) ) Then
    Begin
      Err('No GTA: SA found in this directory!');
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

procedure TfrmMain.btnStartGameClick(Sender: TObject);
var
  reg : TRegistry;
  F : String;
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
    Log('*** No game directory found, please set one.');
    btnSetGameDir.Click;
    If (GameDir = 'None') Then
      Exit;
  End;
  If not ( FileExists( GameDir + '\gta_sa.exe' ) ) Or not ( FileExists( GameDir + '\stream.ini' ) ) Then
  Begin
    Err('No GTA: San Andreas found in the given directory, please set a new one.');
    btnSetGameDir.Click;
    Exit;
  End;
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

  Patch(GameDir + '\data\script\main.scm',GameDir +'\data\script\main.scm.sapbak');
  Patch(GameDir + '\data\script\script.img',GameDir +'\data\script\script.img.sapbak');
  F := GameDir +'\d3d9.dll';
  If ( FileExists(F) ) Then
  Begin
    Patch(GameDir + '\d3d9.dll',GameDir +'\d3d9.dll.sapbak');
    DeleteFile(F);
  End;

  F := GameDir +'\d3dx9_34.dll';
  If not ( FileExists(F) ) Then
    Patch(ExtractFilePath(Application.ExeName) + '\data\d3dx9_34.dll',GameDir +'\d3dx9_34.dll');

  Patch(ExtractFilePath(Application.ExeName) + '\data\main.scm',GameDir +'\data\script\main.scm');
  Patch(ExtractFilePath(Application.ExeName) + '\data\script.img',GameDir +'\data\script\script.img');
  Patch(ExtractFilePath(Application.ExeName) + '\data\d3d9.dll',GameDir +'\d3d9.dll'); // chat.nfo

  ShellExecute(Handle,'open', 'gta_sa.exe', nil, PChar(GameDir), SW_SHOWNORMAL);

  LoadID := 0;
  LastLoad := -1;

  If (TheMap.Count = 0) Then
    frmMain.udpClient.WriteLn('DMAP');

end;

procedure NOPOffsets();
begin
  NOP($438480,5); // Block cheats
  NOP($5DEC04,6); // Walk/Run animations
  //NOP($6E0A3B,6); // Car horn
  NOP($43828F,6); // Vehicle steers
  //NOP($561AF0,6); // Pauze ga door
  //NOP($53E799,7);
  NOP($588FA9,6); // Text display 1
  //NOP($58AA6F,2); // Zone-name texts
  NOP($58905E,6); // Text display 2
  NOP($69DBB8,3); // Transparant box disabler
  NOP($53E799,7); // New game skip
  NOP($576C34,3); // New game skip
  NOP($576C41,4); // New game skip
  NOP($53C090,5); // Replay uitzetten
  //NOP($72DF08,5); // Drive everywhere fast

//  Int := 0; // $0 // Motion Blur uitzetten
//  WriteMem($8D5104,Int,1);

//  Int := 235; // $EB // Vertigo effect uitzetten
//  WriteMem($524B3E,Int,1);
  
  //Int := 235; // $EB // Disable traffic
  //WriteMem($434237,Int,1); // Disable traffic
  //NOP($6B52A8,5);
  //NOP($6BCD81,5);
  //NOP($56863F,3);
  //NOP($58EC21,5); // Klok uitzetten / Niet displayen
  //Str := 'sap.scm';
  //WriteMem($859D60,Str,SizeOf(Str)); // SCM 1

  //Str := 'data\\script\\sap.scm';
  //WriteMem($859F64,Str,SizeOf(Str)); // SCM 2
  
  //Str := 'sap.txd';
  //WriteMem($866CF0,Str,SizeOf(Str)); // Load screens
end;

procedure TfrmMain.tmrProcessTimer(Sender: TObject);
var
  PID, i : Integer;
  F : String;
begin
  GetWindowThreadProcessId(FindWindow(nil,'SA:Party'), @PID);
  hProc := OpenProcess(PROCESS_ALL_ACCESS, False, PID);
  If (hProc > 0) Then
  Begin
    SAOn := True;
    If (SAOnLast = False) Then
    Begin
      NOPOffsets;
      udpClient.WriteLn('GAMESTARTED|'+ IntToStr(PlayerID));
      btnStartGame.Enabled := False;
    End;
    SAOnLast := True;
    tmrSync.Enabled := True;
    tmrLoadMap.Enabled := True;
{    Mem := TStringList.Create;
    For i := 0 To 31 Do
    Begin
      Mem.Add('Player'+ IntToStr(i));
    End;
    Mem.SaveToFile(GameDir +'\players.fle');
    Mem.Free;  }
  End
  Else
  Begin
    SAOn := False;
    tmrSync.Enabled := False;
    tmrLoadMap.Enabled := False;
    If (SAOnLast = True) Then
    Begin
      For i := 1 To 302 Do
      Begin
        F := GameDir + '\nicks'+ IntToStr(i-1) +'.fle';
        If ( FileExists(F) ) Then
          DeleteFile(F);
        Application.ProcessMessages;
      End;
      F := GameDir +'\data\script\main.scm';
      If ( FileExists(F) ) Then
        DeleteFile(F);

      F := GameDir +'\data\script\script.img';
      If ( FileExists(F) ) Then
        DeleteFile(F);

      Patch(GameDir +'\data\script\main.scm.sapbak',GameDir +'\data\script\main.scm');

      Patch(GameDir +'\data\script\script.scm.sapbak',GameDir +'\data\script\script.img');

      F := GameDir +'\d3d9.dll';
      If (FileExists(F)) Then
      Begin
        DeleteFile(F);
        Patch(GameDir +'\d3d9.dll.sapbak',GameDir +'\d3d9.dll');
      End;
      udpClient.WriteLn('GAMECLOSED|'+ IntToStr(PlayerID));
      btnStartGame.Enabled := True;
    End;
    SAOnLast := False;
  End;
end;

procedure TfrmMain.tmrSyncTimer(Sender: TObject);
var
  Val, Val2, i2, i3, CPed, CPos, CVehicle, State, Dead, Weap, Who : Integer;
  ReNOP : Array of Integer;
  offset : LongWord;
  Data : String;
  Sl, PosZ, F1, F2 : Single;
begin
  If (SAOn = False) or (Connected = False) Then
    Exit;
  ReadMem(ScriptBase + (4 * 100),Val,4);
  If (Val = 2) or (Val = 0) Then
    Exit;
  If (Val = 3) Then
  Begin
    //SkinID := 0;
    Val := 4; // Ga syncen doos
    WriteMem(ScriptBase + (4 * 100),Val,4);
    udpClient.WriteLn('SPAWNED|'+ IntToStr(PlayerID)); // We spawned \o/
    //Log('>>> SPAWN DATA');
    Exit;
  End
  Else If (Val = 1) Then
  Begin
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

    Val := 2;
    WriteMem(ScriptBase + (4 * 100),Val,4);
    
    Exit;
  End
  Else If Not (Val = 4) And Not (Val = 5) Then
    Exit;
  ReadMem($B6F5F0,CPed,4);
  ReadMem(CPed + 1328,State,4);

  WriteMem(ScriptBase + (4 * 101),SkinID,4);
  //ReadMem(ScriptBase + (4 * 107),Dead,4); // Are we dead? 1 = Yes, 0 = No D0000HHH!
  //If (Dead = 1) Then
  //If (State = 55) Then // Wasted
  If (Val = 5) Then
  Begin
    SkinID := -1;
    Data := 'ONFOOT|'+ IntToStr(PlayerID) +'|'+ IntToStr(SkinID);
    udpClient.WriteLn(Data); // Verstuur alles
    If (LastD33D = False) Then
    Begin
      LastD33D := True;
      ReadMem(CPed + 1888,Weap,4);
      ReadMem(CPed + 1892,Who,4);
      i2 := 0;
      WriteMem(CPed + 1888,i2,4);
      WriteMem(CPed + 1892,i2,4);
      i3 := Who;
      If Not (Who = 0) Then
      Begin
        Who := (((Who - CPed) div 1988) * 256) + 1;
//        Log(IntToStr(Who));
        i3 := 0;
        For i2 := 0 To 31 Do
        Begin
//          If (PlrSCM[i2] > 0) Then
//            Log('Player '+ IntToStr(i2) +' > SCM ID: '+ IntToStr(PlrSCM[i2]));
          If (PlrSCM[i2] = Who) Then
            i3 := i2 + 1;
        End;
      End
      Else
        i3 := 0;
      udpClient.WriteLn('DEATH|'+ IntToStr(PlayerID) +'|'+ IntToStr(i3) +'|'+ IntToStr(Weap)); 
    End;
    Exit;
  End;
  LastD33D := False;
  If not (Val = 4) Then
    Exit;


  ReadMem(ScriptBase + (4 * 114),Who,4); // CPOut
  If (Who > 0) And Not (Who > 50) And Not (CPOLast = Who) Then
  Begin
    CPOLast := Who;
    CPLast := 0;
    Data := 'CPOUT|'+ IntToStr(PlayerID) +'|'+ IntToStr(Who);
    udpClient.WriteLn(Data);
    Who := 0;
    WriteMem(ScriptBase + (4 * 114),Who,4);
  End;

  ReadMem(ScriptBase + (4 * 115),Who,4); // CPIn
  If Not (Who = CPLast) And Not(Who = 0) And Not (Who > 50) Then
  Begin
    CPLast := Who;
    CPOLast := 0;
    Data := 'CPIN|'+ IntToStr(PlayerID) +'|'+ IntToStr(Who);
    udpClient.WriteLn(Data);
  End;

  ReadMem(ScriptBase + (4 * 110),Dead,4); // PlrCar
  If (Dead > 0) and (State = 50) Then  // Car sync!
  Begin
    ReadMem(ScriptBase + (4 * 111),i2,4); // PlrSeat
//    If (i2 > 0) Then // Noes! We zijn een passagier, dan niet syncen :o
//      Exit;
    Data := 'CAR|'+ IntToStr(PlayerID) +'|'+ IntToStr(SkinID) +'|'+ IntToStr(Dead) +'|'+ IntToStr(i2);

    ReadMem(CPed + 1420,CVehicle,4); // CVehicle
    ReadMem(CVehicle + 20,CPos,4); // CPos

    If (i2 = 15) Then // Trein/Tram
    Begin
      ReadMem(ScriptBase + (4 * 113),Sl,4); // Speed (float)
      Data := Data +'|'+ FloatToStr(Sl);
    End
    Else
    Begin

    ReadMem(CPos + 48,Sl,4); // Position X
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CPos + 52,Sl,4); // Position Y
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CPos + 56,Sl,4); // Position Z
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    // 0, 4, 8, 12, 16, 20, 24, 28, 32

    ReadMem(CPos + 0,Sl,4); // XA
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CPos + 4,Sl,4); // XB
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CPos + 8,Sl,4); // XC
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CPos + 12,Sl,4); // YA
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CPos + 16,Sl,4); // YB
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CPos + 20,Sl,4); // YC
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CPos + 24,Sl,4); // ZA
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CPos + 28,Sl,4); // ZB
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CPos + 32,Sl,4); // ZC
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CVehicle + 68,PosZ,4); // Speed X
    Data := Data +'|'+ FormatFloat('0.000',PosZ);

    ReadMem(CVehicle + 72,Sl,4); // Speed Y
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CVehicle + 76,Sl,4); // Speed Z
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CVehicle + 80,Sl,4); // Spin X
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CVehicle + 84,Sl,4); // Spin Y
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CVehicle + 88,Sl,4); // Spin Z
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CVehicle + 1172,Sl,4); // Wheels 1
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CVehicle + 1176,Sl,4); // Wheels 2
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CVehicle + 2156,Sl,4); // Extra angle (voor forklift etc.)
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CVehicle + 1216,Sl,4); // Health
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CVehicle + 152,Sl,4); // G-Force
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CVehicle + 1076,i3,1); // Color 1
    Data := Data +'|'+ IntToStr(i3);

    ReadMem(CVehicle + 1077,i3,1); // Color 1
    Data := Data +'|'+ IntToStr(i3);

    ReadMem(CVehicle + 1069,i3,1); // Siren
    Data := Data +'|'+ IntToStr(i3);

    ReadMem(CVehicle + 1180,F1,4); // Gas pedal
    ReadMem(CVehicle + 1184,F2,4); // Break pedal
    //ReadMem(CVehicle + 955,i3,1);
    If ((F1 = 1.0) and (F2 = 0.0)) or ((F1 = 1.0) and (F2 = 1.0)) Then i3 := 9
    Else If (F1 = 0.0) and (F2 = 0.0) Then
    Begin
      If not (PosZ = 0.0) Then i3 := 9
      Else i3 := 15;
    End
    Else If (F1 = -1.0) and (F2 = 0.0) Then i3 := 3
    Else i3 := 15;
    Data := Data +'|'+ IntToStr(i3);

    ReadMem(ScriptBase + (4 * 112),Val2,4); // Paintjob
    Data := Data +'|'+ IntToStr(Val2);

    ReadMem(ScriptBase + (4 * 113),Sl,4); // Speed (float)
    Data := Data +'|'+ FloatToStr(Sl);

    ReadMem(CVehicle + 2560,i3,1); // Plane stuff pt. 1
    Data := Data +'|'+ IntToStr(i3);

    ReadMem(CVehicle + 2156,Sl,4); // Plane stuff pt. 2
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CVehicle + 2508,Sl,4); // Plane stuff pt. 3
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CVehicle + 892,i3,1); // Nitro
    Data := Data +'|'+ IntToStr(i3);

//    ReadMem(ScriptBase + (4 * 116),i3,4); // MyTrailer
//    Data := Data +'|'+ IntToStr(i3);
   // memoChat.Lines.Add('Trailer: '+ IntToStr(i3));

    ReadMem(ScriptBase + (4 * 117),i3,4); // MyRepair
    If (i3 = 1) Then
    Begin
      i3 := 0;
      WriteMem(ScriptBase + (4 * 117),i3,4);
      udpClient.WriteLn('NR|'+ IntToStr(PlayerID)); // Need repair
    End;
    End;
    //Log('Verzonden: '+ Data);
    udpClient.WriteLn(Data); // Verstuur alles
  End
  Else If (Dead = 0) and ((State = 1) or (State = 12)) Then
  //Else If (Dead = 0) Then
  Begin
    ReadMem(CPed + 20,CPos,4);
    Data := 'ONFOOT|'+ IntToStr(PlayerID) +'|'+ IntToStr(SkinID);
    ReadMem(CPos + 48,Sl,4); // Position X
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CPos + 52,Sl,4); // Position Y
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CPos + 56,PosZ,4); // Position Z
    Data := Data +'|'+ FloatToStr(PosZ);

    //ReadMem(CPed + 1372,Sl,4); // Rotatie in radialen
    ReadMem(ScriptBase + (4 * 102),Sl,4);
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CPed + 1332,Val,1); // Ren animatie
    ReadMem(CPed + 1247,Val2,1); // Animatie play state?!
    If (Val = 6) And (Val2 = 61) Then
      Val := 4;
    Data := Data +'|'+ IntToStr(Val) +'|'+ IntToStr(Val2);

    ReadMem(CPed + 1344,Sl,4); // Health
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CPed + 1352,Sl,4); // Armor
    Data := Data +'|'+ FormatFloat('0.000',Sl);

    ReadMem(CPed + 1135,State,1); // Bukken
    If (State = 132) Then
      State := 1
    Else
      State := 0;

    If (State = 1) Then
    Begin
      ReadMem(CPed + 1148,Val2,4); // Animation structure // DWord
      ReadMem(Val2 + 28,Val2,4); // Crouch animation structure // DWord
      ReadMem(Val2 + 31,Val,1); // Byte
      ReadMem(Val2 + 32,Sl,4); // Float
      Data := Data +'|'+ IntToStr(Val) +'|'+ FloatToStr(Sl);
    End
    Else
      Data := Data +'|0|0.0';

    If (State = 0) Then
    Begin
      ReadMem(ScriptBase + (4 * 107),Val,4); // Springen
      //ReadMem(CPed + 1133,Val,1);
      //If (Val = 34) or (Val = 36) Then
      If (Val = 1) Then
        Val := 2
      Else
        Val := 0;
    End
    Else
      Val := 1;
    Data := Data +'|'+ IntToStr(Val);

    ReadMem(ScriptBase + (4 * 103),Dead,4); // Armed weapon @_@
    Data := Data +'|'+ IntToStr(Dead);

    // SCHIETEN! :o
    If ((Dead >= 0) and (Dead <= 18)) or (Dead = 39) or (Dead = 41) or (Dead = 42) Then
    Begin
      // Fists
      ReadMem(CPed + 1148,Val,4); // Animation structure // DWord
      ReadMem(Val + 24,Val,4); // Fight animation structure // DWord
      ReadMem(ScriptBase + (4 * 108),Val2,4);
      If (Val2 = 1) Then Val2 := 3 // Punching
      Else Val2 := 0;
      //If (Val2 = 3) and (Dead >= 0) and (Dead <= 15) Then Val2 := 0;
      //Val2 := 0;
      Data := Data +'|'+ IntToStr(Val2);
    End
    Else
    Begin
      ReadMem(CPed + 1148,Val,4); // Animation structure // DWord
      ReadMem(Val + 24,Val,4); // Fight animation structure // DWord
      ReadMem(Val + 16,Val2,1);
      // 1 = Targeting
      // 2 = Shooting
      // 3 = ???
      // 4 = Reloading
      If (Val2 = 4) Then
        Val2 := 1;
      Data := Data +'|'+ IntToStr(Val2);
    End;

    If (Val2 = 1) or (Val2 = 2) or (Val2 = 3) Then
    Begin
      ReadMem(Val + 20,Sl,4); // Float
      Data := Data +'|'+ FormatFloat('0.000',Sl);
      ReadMem(Val + 24,Sl,4); // Float
      Data := Data +'|'+ FormatFloat('0.000',Sl);
      Sl := GetCameraVerticalAngle * 65.0;
      Data := Data +'|'+ FormatFloat('0.000',Sl);
    End
    Else
      Data := Data +'|0.0|0.0|0.0';

    udpClient.WriteLn(Data); // Verstuur alles
  End;
end;

procedure TfrmMain.WriteSync(Data : String);
var
  Arr : TSplitArray;
  PID, Val, Val2, CPed, CVehicle, CPos, State, Seat : Integer;
  SCMVal : DWord;
  Sl, Rad, PosX, PosY, PosZ, Distance : Single;
begin
  Arr := Split('a|a|a','|');
  If (SAOn = False) or (Connected = False) Then
    Exit;
  ReadMem(ScriptBase + (4 * 100),Val,4);
  If not (Val = 4) Then
    Exit;
  Arr := Split(Data,'|');
  PID := DoStrToInt(Arr[1]) - 1;
  Val2 := DoStrToInt(Arr[2]);
  WriteMem(ScriptBase + (4 * (200 + PID)),Val2,4);
  If (Val2 = -1) Then
    Exit;
  ReadMem(ScriptBase + (4 * PID),SCMVal,4);
  If (SCMVal > 28161) or (SCMVal <= 0) Then // ( 110 * 256 ) + 1 = 28161
  Begin
    PlrSCM[PID] := 0;
    Exit;
  End;
  PlrSCM[PID] := SCMVal;

  ReadMem($B6F5F0,CPed,4);
  Val2 := (SCMVal - 1) div 256;
  If (Val2 = 0) Then
    Exit;
  //memoChat.Lines.Add('Test: '+ IntToStr(CPed));
  CPed := CPed + (1988 * Val2); // Eindelijk... we hebben de goede :P
  ReadMem(CPed + 1328,State,4);

  If (Arr[0] = 'CAR') Then // Car pakketje
  Begin
    Val := DoStrToInt(Arr[3]); // PlrCar
    WriteMem(ScriptBase + (4 * (1100 + PID)),Val,4);

    Seat := DoStrToInt(Arr[4]); // PlrSeat
    WriteMem(ScriptBase + (4 * (1200 + PID)),Seat,4);

    //Val := DoStrToInt(Arr[38]); // PlrTrailer
    //WriteMem(ScriptBase + (4 * (1700 + PID)),Val,4);

    ReadMem(CPed + 1328,State,4);
    If (Seat = 0) and (State = 50) then // We zijn een passagier... dan maar niet writen :o
    Begin
      ReadMem(CPed + 1420,CVehicle,4); // CVehicle
      ReadMem(CVehicle + 20,CPos,4); // CPos

      If (Seat = 15) Then // Trein/Tram
      Begin
        Sl := DecimalSec(Arr[5]);
        WriteMem(ScriptBase + (4 * (1500 + PID)),Sl,4); // Speed
        //memoChat.Lines.Add(Arr[5]);
      End
      Else
      Begin

      Sl := DecimalSec(Arr[5]);
      WriteMem(CPos + 48,Sl,4); // Position X

      Sl := DecimalSec(Arr[6]);
      WriteMem(CPos + 52,Sl,4); // Position Y

      Sl := DecimalSec(Arr[7]);
      WriteMem(CPos + 56,Sl,4); // Position Z

      // 0, 4, 8, 12, 16, 20, 24, 28, 32

      Sl := DecimalSec(Arr[8]);
      WriteMem(CPos + 0,Sl,4); // Rotation

      Sl := DecimalSec(Arr[9]);
      WriteMem(CPos + 4,Sl,4); // Rotation

      Sl := DecimalSec(Arr[10]);
      WriteMem(CPos + 8,Sl,4); // Rotation

      Sl := DecimalSec(Arr[11]);
      WriteMem(CPos + 12,Sl,4); // Rotation

      Sl := DecimalSec(Arr[12]);
      WriteMem(CPos + 16,Sl,4); // Rotation

      Sl := DecimalSec(Arr[13]);
      WriteMem(CPos + 20,Sl,4); // Rotation

      Sl := DecimalSec(Arr[14]);
      WriteMem(CPos + 24,Sl,4); // Rotation

      Sl := DecimalSec(Arr[15]);
      WriteMem(CPos + 28,Sl,4); // Rotation

      Sl := DecimalSec(Arr[16]);
      WriteMem(CPos + 32,Sl,4); // Rotation

      Sl := DecimalSec(Arr[17]);
      WriteMem(CVehicle + 68,Sl,4); // Speed X

      Sl := DecimalSec(Arr[18]);
      WriteMem(CVehicle + 72,Sl,4); // Speed Y

      Sl := DecimalSec(Arr[19]);
      WriteMem(CVehicle + 76,Sl,4); // Speed Z

      Sl := DecimalSec(Arr[20]);
      WriteMem(CVehicle + 80,Sl,4); // Spin X

      Sl := DecimalSec(Arr[21]);
      WriteMem(CVehicle + 84,Sl,4); // Spin Y

      Sl := DecimalSec(Arr[22]);
      WriteMem(CVehicle + 88,Sl,4); // Spin Z

      Sl := DecimalSec(Arr[23]);
      WriteMem(CVehicle + 1172,Sl,4); // Wheels 1

      Sl := DecimalSec(Arr[24]);
      WriteMem(CVehicle + 1176,Sl,4); // Wheels 2

      Sl := DecimalSec(Arr[25]);
      WriteMem(CVehicle + 2156,Sl,4); // Extra angle (voor forklift etc.)

      Sl := DecimalSec(Arr[26]);
      WriteMem(CVehicle + 1216,Sl,4); // Health

      Sl := DecimalSec(Arr[27]);
      WriteMem(CVehicle + 152,Sl,4); // G-Force

      Val := DoStrToInt(Arr[28]);
      WriteMem(CVehicle + 1076,Val,1); // Color 1

      Val := DoStrToInt(Arr[29]);
      WriteMem(CVehicle + 1077,Val,1); // Color 2

      Val := DoStrToInt(Arr[30]);
      WriteMem(CVehicle + 1069,Val,1); // Siren

      Val := DoStrToInt(Arr[31]);
      WriteMem(ScriptBase + (4 * (1300 + PID)),Val,4); // Speed

      Val := DoStrToInt(Arr[32]);
      WriteMem(ScriptBase + (4 * (1400 + PID)),Val,4); // Paintjob

      Sl := DecimalSec(Arr[33]);
      WriteMem(ScriptBase + (4 * (1500 + PID)),Sl,4); // Spaad (Speed in float)

      Val := DoStrToInt(Arr[34]);
      WriteMem(CVehicle + 2560,Val,1); // Plane stuff pt. 1 // Smoke discharger

      Sl := DecimalSec(Arr[35]);
      WriteMem(CVehicle + 2156,Sl,4); // Plane stuff pt. 2

      Sl := DecimalSec(Arr[36]);
      WriteMem(CVehicle + 2508,Sl,4); // Plane stuff pt. 2

      Val := DoStrToInt(Arr[37]);
      WriteMem(ScriptBase + (4 * (1600 + PID)),Sl,4); // Nitro
      //WriteMem(CVehicle + 892,Val,1); // Nitro

      // !!!38 is trailer!!!
      End;
    End;
  End
  Else If (Arr[0] = 'ONFOOT') Then
  Begin
    Val2 := 0;
    WriteMem(ScriptBase + (4 * (1100 + PID)),Val2,4); // PlrCar
    WriteMem(ScriptBase + (4 * (1200 + PID)),Val2,4); // PlrSeat
    //WriteMem(ScriptBase + (4 * (1700 + PID)),Val2,4); // PlrTrailer
    ReadMem(CPed + 1328,State,4);
    If (State = 1) or (State = 12) then
    Begin
      ReadMem(CPed + 20,CPos,4);

      PosX := DecimalSec(Arr[3]);
      WriteMem(CPos + 48,PosX,4); // Position X

      PosY := DecimalSec(Arr[4]);
      WriteMem(CPos + 52,PosY,4); // Position Y

      PosZ := DecimalSec(Arr[5]);
      WriteMem(CPos + 56,PosZ,4); // Position Z

      Rad := DecimalSec(Arr[6]);
      memoChat.Lines.Add('Player '+ IntToStr(PlayerID) +' got rotation: '+ FloatToStr(Rad));

      If (plrCount[PlayerID] = 40) Then
      Begin
        Log('Player '+ IntToStr(PlayerID) +' got rotation: '+ FloatToStr(Rad));
        plrCount[PlayerID] := 0;
      End
      Else
        plrCount[PlayerID] := plrCount[PlayerID]+1;
      WriteMem(ScriptBase + (4 * (300 + PID)),Rad,4); // SCM rotatie
      //WriteMem(CPed + 1372,Sl,4); // Rotatie in radialen

//      Val := DoStrToInt(Arr[8]);
//      WriteMem(CPed + 1247,Val,1); // Animatie play state

      Val := DoStrToInt(Arr[7]);
      WriteMem(CPed + 1332,Val,1); // Run

      Sl := DecimalSec(Arr[9]);
      WriteMem(CPed + 1344,Sl,4); // Health

      Sl := DecimalSec(Arr[10]);
      WriteMem(CPed + 1352,Sl,4); // Armor

      Val := DoStrToInt(Arr[13]);
      If (Val = 2) Then // Springen
    Begin
      Val := 1;
      If not (Val = PlrJumping[PID]) Then
        WriteMem(ScriptBase + (4 * (500 + PID)),Val,4);
      PlrJumping[PID] := Val;
    End
    Else If (Val = 1) Then // Bukken
    Begin
      PlrJumping[PID] := 0;
      WriteMem(ScriptBase + (4 * (400 + PID)),Val,4);
    End
    Else
    Begin // Na bukken gaan staan
      Val := 0;
      PlrJumping[PID] := 0;
      WriteMem(ScriptBase + (4 * (400 + PID)),Val,4);
    End;

    Val := DoStrToInt(Arr[11]);
    Sl := DecimalSec(Arr[12]);
    ReadMem(CPed + 1148,Val2,4); // Animation structure // DWord
    ReadMem(Val2 + 28,Val2,4); // Crouch animation structure // DWord
    WriteMem(Val2 + 31,Val,1); // Byte
    WriteMem(Val2 + 32,Sl,4); // Float

    Val := DoStrToInt(Arr[14]); // Armed weapon
    WriteMem(ScriptBase + (4 * (600 + PID)),Val,4);
    If (DoStrToInt(Arr[15]) = 1) or (DoStrToInt(Arr[15]) = 2) or (DoStrToInt(Arr[15]) = 3) Then
    Begin
      // Bewegen tijdens aimen/schieten
      ReadMem(CPed + 1148,Val2,4); // Animation structure // DWord
      ReadMem(Val2 + 24,Val2,4); // Fight animation structure // DWord
      Sl := DecimalSec(Arr[16]); // Way1 X
      WriteMem(Val2 + 20,Sl,4);
      Sl := DecimalSec(Arr[17]); // Way2 Y
      WriteMem(Val2 + 24,Sl,4);

      // Schiet/aim positie
      If (Rad > 180) Then
        Rad := Rad - 180
      Else
        Rad := Rad + 180;
      Rad := DegToRad(Rad - 90);
      //   If ((Dead >= 0) and (Dead < 18)) or (Dead = 39) or (Dead = 41) or (Dead = 42) Then
      If ((Val >= 0) and (Val <= 15)) or (Val = 39) or (Val = 41) or (Val = 42) Then
        Distance := 1.3
      Else If (Val = 16) or (Val = 17) or (Val = 18) Then
        Distance := 5.0
      Else
        Distance := 8.0;

      Sl := PosX + (cos(Rad) * Distance); // Shoot X
      WriteMem(ScriptBase + (4 * (800 + PID)),Sl,4);

      Sl := PosY + (sin(Rad) * Distance); // Shoot Y
      WriteMem(ScriptBase + (4 * (900 + PID)),Sl,4);
      { If (Distance < 8.0) Then
        Sl := tan(PosZ) * distance // Shoot Z
      Else
        Sl := PosZ + (DecimalSec(Arr[18]) * 5.0); // Shoot Z     }
      Sl := PosZ + (tan(DecimalSec(Arr[18]) / 57.3) * Distance); // Shoot Z
      WriteMem(ScriptBase + (4 * (1000 + PID)),Sl,4);
    End;

    Val := DoStrToInt(Arr[15]); // Schiet status
    WriteMem(ScriptBase + (4 * (700 + PID)),Val,4);
    End;
  End;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if udpClient.Connected then
  begin
    ReceiveThread.Suspend;
    Disconnect(False);
  end;
  TheMap.Free;
end;

procedure TfrmMain.tmrPingCheckTimer(Sender: TObject);
begin
  If (tmrPingCheck.Interval = 5000) Then
  Begin
    Log('*** Couldn''t establish a connection');
    GotPing := True;
    tmrPingCheck.Interval := 6500;
    Disconnect(False);
  End
  Else
  Begin
    If (GotPing = False) Then
    Begin
      Log('*** Disconnected (Reason: Client Time Out)');
      Disconnect(False);
    End
    Else
      GotPing := False;
  End;
end;

procedure TfrmMain.tmrLoadMapTimer(Sender: TObject);
var
  Int : Integer;
  Float : Single;
  Arr : TSplitArray;
begin
  Arr := Split('a|a|a','|');
  If (udpClient.Connected = False) or (SAOn = False) Then
    Exit;
  ReadMem(ScriptBase + (4 * 109),Int,4);
  If (Int = 1) and not (TheMap.Count = LastLoad) Then // Laad iets :o
  Begin
    If ((LoadID+1) = TheMap.Count) Then
      LastLoad := TheMap.Count;

    If (TheMap[LoadID] = 'unused') Then
    Begin
      LoadID := LoadID + 1;
      Exit;
    End;

    Try
      Arr := Split(TheMap[LoadID],'|');
    Except
      LoadID := LoadID + 1;
      Exit;
    End;

    If (Arr[0] = 'o') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Unique ID
      Objects[Int] := LoadID;
      //Log('>>> Object '+ IntToStr(Int));
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := DoStrToInt(Arr[2]); // Model ID
      WriteMem(ScriptBase + (4 * 127),Int,4);

      Float := DecimalSec(Arr[3]); // Position X
      WriteMem(ScriptBase + (4 * 121),Float,4);

      Float := DecimalSec(Arr[4]); // Position Y
      WriteMem(ScriptBase + (4 * 122),Float,4);

      Float := DecimalSec(Arr[5]); // Position Z
      WriteMem(ScriptBase + (4 * 123),Float,4);

      Float := DecimalSec(Arr[6]); // Rotation X
      WriteMem(ScriptBase + (4 * 124),Float,4);

      Float := DecimalSec(Arr[7]); // Rotation Y
      WriteMem(ScriptBase + (4 * 125),Float,4);

      Float := DecimalSec(Arr[8]); // Rotation Z
      WriteMem(ScriptBase + (4 * 126),Float,4);

      Int := 1; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);
    End
    Else If (Arr[0] = 'do') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Unique ID
      WriteMem(ScriptBase + (4 * 120),Int,4);

      If not (Objects[Int] = 0) Then
      Begin
        TheMap[Objects[Int]] := 'unused';
      End;
      TheMap[LoadID] := 'unused';

      Int := 2; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);
    End
    Else If (Arr[0] = 'v') Then
    Begin
      //memoChat.Lines.Add('Vehicle: '+ TheMap[LoadID]);
      Int := DoStrToInt(Arr[1]); // Unique ID
      Vehicles[Int] := LoadID;
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := DoStrToInt(Arr[2]); // Vehicle ID
      WriteMem(ScriptBase + (4 * 127),Int,4);

      Float := DecimalSec(Arr[3]); // Position X
      WriteMem(ScriptBase + (4 * 121),Float,4);

      Float := DecimalSec(Arr[4]); // Position Y
      WriteMem(ScriptBase + (4 * 122),Float,4);

      Float := DecimalSec(Arr[5]); // Position Z
      WriteMem(ScriptBase + (4 * 123),Float,4);

      Float := DecimalSec(Arr[6]); // Rotation
      WriteMem(ScriptBase + (4 * 124),Float,4);

      Int := DoStrToInt(Arr[7]); // Color 1
      WriteMem(ScriptBase + (4 * 129),Int,4);

      Int := DoStrToInt(Arr[8]); // Color 2
      WriteMem(ScriptBase + (4 * 130),Int,4);

      Int := 27; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);
    End
    Else If (Arr[0] = 'dv') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Unique ID
      WriteMem(ScriptBase + (4 * 120),Int,4);

      If not (Vehicles[Int] = 0) Then
      Begin
        TheMap[Vehicles[Int]] := 'unused';
      End;
      TheMap[LoadID] := 'unused';

      Int := 28; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);
    End
    Else If (Arr[0] = 'cp') Then
    Begin // Checkpoint
      Int := DoStrToInt(Arr[1]); // Unique ID
      Checkpoints[Int] := LoadID;
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Float := DecimalSec(Arr[2]); // Position X
      WriteMem(ScriptBase + (4 * 121),Float,4);

      Float := DecimalSec(Arr[3]); // Position Y
      WriteMem(ScriptBase + (4 * 122),Float,4);

      Float := DecimalSec(Arr[4]); // Position Z
      WriteMem(ScriptBase + (4 * 123),Float,4);

      Float := DecimalSec(Arr[5]); // Rotation
      WriteMem(ScriptBase + (4 * 124),Float,4);

      Int := 33; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);
    End
    Else If (Arr[0] = 'dcp') Then
    Begin
      Int := DoStrToInt(Arr[1]); // Unique ID
      WriteMem(ScriptBase + (4 * 120),Int,4);

      If not (Checkpoints[Int] = 0) Then
      Begin
        TheMap[Checkpoints[Int]] := 'unused';
      End;
      TheMap[LoadID] := 'unused';

      Int := 34; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);
    End
    Else If (Arr[0] = 'allowjump') Then // AllowPlayerToJump
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := 3; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'allowshoot') Then // AllowPlayerToShoot
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := 4; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'allowscroll') Then // AllowPlayerToChangeWeapon
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := 5; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'setcrouch') Then // SetPlayerCrouch
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := 6; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'cleardamage') Then // UndoLastWeaponDamage
    Begin
      Int := 7; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'setarmedweapon') Then // SetPlayerArmedWeapon
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := 8; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'sethud') Then // SetPlayerHUD
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := 9; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'allowcrouch') Then // AllowPlayerCrouch
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := 10; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'setradar') Then // SetPlayerRadar
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := 11; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'setwidescreen') Then // SetPlayerWidescreen
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := 12; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'sparks') Then // CreateSparks
    Begin
      Float := DecimalSec(Arr[1]);
      WriteMem(ScriptBase + (4 * 121),Float,4);

      Float := DecimalSec(Arr[2]);
      WriteMem(ScriptBase + (4 * 122),Float,4);

      Float := DecimalSec(Arr[3]);
      WriteMem(ScriptBase + (4 * 123),Float,4);

      Float := DecimalSec(Arr[4]);
      WriteMem(ScriptBase + (4 * 124),Float,4);

      Float := DecimalSec(Arr[5]);
      WriteMem(ScriptBase + (4 * 125),Float,4);

      Float := DecimalSec(Arr[6]);
      WriteMem(ScriptBase + (4 * 126),Float,4);
      
      Int := DoStrToInt(Arr[7]);
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := 13; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'setradargrey') Then // SetPlayerRadarGrey
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := 14; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'explos') Then // CreateExplosion
    Begin
      Float := DecimalSec(Arr[1]);
      WriteMem(ScriptBase + (4 * 121),Float,4);

      Float := DecimalSec(Arr[2]);
      WriteMem(ScriptBase + (4 * 122),Float,4);

      Float := DecimalSec(Arr[3]);
      WriteMem(ScriptBase + (4 * 123),Float,4);

      Int := 15; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'setcamera') Then // SetCameraPosition
    Begin
      Float := DecimalSec(Arr[1]);
      WriteMem(ScriptBase + (4 * 121),Float,4);

      Float := DecimalSec(Arr[2]);
      WriteMem(ScriptBase + (4 * 122),Float,4);

      Float := DecimalSec(Arr[3]);
      WriteMem(ScriptBase + (4 * 123),Float,4);

      Int := 16; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'setcamaim') Then // SetCameraAimPosition
    Begin
      Float := DecimalSec(Arr[1]);
      WriteMem(ScriptBase + (4 * 121),Float,4);

      Float := DecimalSec(Arr[2]);
      WriteMem(ScriptBase + (4 * 122),Float,4);

      Float := DecimalSec(Arr[3]);
      WriteMem(ScriptBase + (4 * 123),Float,4);

      Int := 17; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'setrescam') Then // SetRestoreCamera
    Begin
      Int := 18; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'playsound') Then // SetPlaySound
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := 19; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'setcolor') Then // SetMarkerColor
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := DoStrToInt(Arr[2]);
      WriteMem(ScriptBase + (4 * 127),Int,4);

      Int := 20; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'weapon') Then // Give player weapon
    Begin
      Int := DoStrToInt(Arr[1]); // Weapon ID
      WriteMem(ScriptBase + (4 * 127),Int,4);

      Int := DoStrToInt(Arr[2]); // Ammo
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := 21; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'setrotation') Then // Set rotation
    Begin
      Float := DecimalSec(Arr[1]);
      WriteMem(ScriptBase + (4 * 121),Float,4);

      Int := 22; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'objpos') Then // SetObjectPosition
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Float := DecimalSec(Arr[2]);
      WriteMem(ScriptBase + (4 * 121),Float,4);

      Float := DecimalSec(Arr[3]);
      WriteMem(ScriptBase + (4 * 122),Float,4);

      Float := DecimalSec(Arr[4]);
      WriteMem(ScriptBase + (4 * 123),Float,4);

      Int := 23; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'objmove') Then // MoveObject
    Begin
      Int := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Float := DecimalSec(Arr[2]);
      WriteMem(ScriptBase + (4 * 121),Float,4);

      Float := DecimalSec(Arr[3]);
      WriteMem(ScriptBase + (4 * 122),Float,4);

      Float := DecimalSec(Arr[4]);
      WriteMem(ScriptBase + (4 * 123),Float,4);

      Int := 24; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'freeze') Then // Freeze player
    Begin
      //Log('FREEZE!');
      Int := DoStrToInt(Arr[1]);
      If (Int = PlayerID) Then
        Int := 0;
      WriteMem(ScriptBase + (4 * 120),Int,4);

      Int := DoStrToInt(Arr[2]);
      WriteMem(ScriptBase + (4 * 127),Int,4);

      Int := 25; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'SETPOSITION') Then // SetPlayerPosition
    Begin
      Float := DecimalSec(Arr[1]);
      WriteMem(ScriptBase + (4 * 121),Float,4);

      Float := DecimalSec(Arr[2]);
      WriteMem(ScriptBase + (4 * 122),Float,4);

      Float := DecimalSec(Arr[3]);
      WriteMem(ScriptBase + (4 * 123),Float,4);

      Int := 32; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);

      TheMap[LoadID] := 'unused';
    End
    Else If (Arr[0] = 'dolo') Then
    Begin
//      Int := 5;
//      WriteMem(ScriptBase + (4 * 100),Int,4);

      Log('*** Loading completed');

      Int := 29; // Type of command
      WriteMem(ScriptBase + (4 * 128),Int,4);
    End;
    Int := 2;
    WriteMem(ScriptBase + (4 * 109),Int,4);
    LoadID := LoadID + 1;
  End;
end;

procedure TfrmMain.tmrNicksTimer(Sender: TObject);
var
  i : Integer;
  Strs : TStrings;
begin
  If (SAOn = False) or (Connected = False) Then
    Exit;
  Strs := TStringList.Create;
  For i := 1 To 32 Do
  Begin
    If not (PlayerNick[i] = '') Then
    Begin
      Strs.Clear;
      Strs.Add(PlayerNick[i]);
      Try
        Strs.SaveToFile(GameDir + '\nicks'+ IntToStr(i-1) +'.fle');
      Except
      End;
      Application.ProcessMessages;
    End;
  End;
  Strs.Clear;
  Strs.Free;
end;

procedure TfrmMain.udpClientConnected(Sender: TObject);
begin
   ReceiveThread := TReceiveThread.Create(False);
end;

end.
