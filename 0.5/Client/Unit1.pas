unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IdBaseComponent, IdComponent, IdUDPBase, IdUDPClient, MD5,
  ComCtrls, XPMan, JvBaseDlg, JvSelectDirectory, Registry, ShellAPI,
  JvTimer, ExtCtrls, math, IdTCPConnection, IdTCPClient, DateUtils;

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
    pagMain: TPageControl;
    tabBrowser: TTabSheet;
    tabGame: TTabSheet;
    tabSettings: TTabSheet;
    grpConnect: TGroupBox;
    appXPM: TXPManifest;
    lblHost: TLabel;
    lblHostPort: TLabel;
    lblPassword: TLabel;
    Label2: TLabel;
    groAbout: TGroupBox;
    AboutText: TLabel;
    lblPlayers: TLabel;
    btnDisconnect: TButton;
    btnSetGameDir: TButton;
    SelectDir: TJvSelectDirectory;
    btnStartGame: TButton;
    tmrProcess: TJvTimer;
    TCP: TIdTCPClient;
    tmrPingPong: TJvTimer;
    tmrSync: TJvTimer;
    cbxDev: TCheckBox;
    cbxWindowed: TCheckBox;
    cbxTimestamps: TCheckBox;
    lstPlayers: TListView;
    tmrLoadMap: TJvTimer;
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
    procedure Disconnect(LogAllowed : Boolean);
    function CopyBetween(Source, bs, es : String): String;
    function CopyAfter(Source, bs : String): String;
    function CopyBefore(Source, bs : String): String;
    procedure ParseMessage(Str : String);
    procedure TCPConnected(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tmrPingPongTimer(Sender: TObject);
    procedure tmrSyncTimer(Sender: TObject);
    procedure ProcessSync(Data : String);
    procedure cbxTimestampsClick(Sender: TObject);
    procedure cbxWindowedClick(Sender: TObject);
    procedure tmrLoadMapTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;
  ReceiveThread : TReceiveThread;
  Chat1, Chat2, lstPlayers2, Map : TStringList;

  // Integers
  PlayerID, hProc, GotPings, SkinID : Integer;

  // Strings
  Version, GameDir : String;

  // Booleans
  Connected, SAOn, SAOnLast, LastDead : Boolean;

  // Overig
  ScriptBase : DWord = $A49960; // Basis van SCM variablen
  card : Cardinal;

  PlayerNick : Array [0..33] of String;
  PlrSCM : Array [0..33] of Integer;

const
  VERSION_HASH = 'P52@YWA-LOL';

  // PACKET HEADERS
  PACKET_SEPARATOR = chr(1); // Separates parameters
  PACKET_SYNC = chr(2); // Sync packet
  PACKET_PING = chr(3); // Ping?
  PACKET_PONG = chr(4); // Pong!
  PACKET_CONN = chr(5); // "Mag ik overvaren?", oftewel: Mag ik joinen lieve server?
  //PACKET_CONN_B = chr(6); // Server accepts or refuses client connection
  PACKET_INFO = chr(7); // Client asks the server for the info (passworded etc.)
  //PACKET_INFO_B = chr(8); // Server replies with the server info :D
  PACKET_PLAYERS = chr(9); // Client asks the server for the player list that are connected
  PACKET_CHAT = chr(11); // Chat packet (so people can flame each other while playing this party-mod)
  PACKET_PLAYER_JOIN = chr(12); // There is a new player that just joined... so the server sends the info of this player to the client
  PACKET_PLAYERCHANGE = chr(13); // Property of player changed
  PACKET_GAME_CLOSED = chr(14); // Game closed
  PACKET_GAME_STARTED = chr(15); // Game started
  PACKET_PLAYER_PART = chr(16); // Some player disconnected
  PACKET_GOOD_BYE = chr(17); // The server disconnects us.
  PACKET_SPAWNED = chr(18); // We should let the server know we spawned... (client->server)
  PACKET_RICKROLLED = chr(19); // WE DIED! So let the server know we got Rick rolled! (client->server)
  PACKET_DISCONNECT = chr(20); // We are disconnecting... (client->server)
  //PACKET_PLAYERS_B = chr(21); // The server replies :D
  PACKET_TIMEWEATHER = chr(22); // Time and Weather synchronisation -- syntax is chr(21) + chr(uren) + chr(minuten) + chr(weer id)
  PACKET_MAPDATA = chr(23);

  // Rest 
  PACKET_PLAYERCHANGE_HEALTH = chr(2);
  PACKET_PLAYERCHANGE_ARMOR = chr(3);
  PACKET_PLAYERCHANGE_POS = chr(4);
  PACKET_PLAYERCHANGE_ROTATION = chr(5);
  PACKET_PLAYERCHANGE_SKIN = chr(6);
  PACKET_PLAYERCHANGE_INTERIOR = chr(7);

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

procedure WriteMem(Offset: Integer;var Value; Size: Integer);
var
  d : Cardinal;
begin
  VirtualProtectEx(hProc, Pointer(Offset),Size,PAGE_EXECUTE_READWRITE,d);
  WriteProcessMemory(hProc, ptr(Offset),@Value, Size, card);
  VirtualProtectEx(hProc, Pointer(Offset),Size,d,d);
end;

procedure WriteVal(Offset: Integer;var Value);
var
  d : Cardinal;
begin
  VirtualProtectEx(hProc, Pointer(Offset),1,PAGE_EXECUTE_READWRITE,d);
  WriteProcessMemory(hProc, ptr(Offset),@Value, 1, card);
  VirtualProtectEx(hProc, Pointer(Offset),1,d,d);
end;


procedure ReadMem(Offset: Integer;var Value; Size: Integer);
begin
  ReadProcessMemory(hProc, ptr(Offset),@Value, Size, card);
end;

procedure NOP(Offset: Integer;Size: Integer);
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
  ReadMem($B6FA0C,result,4); // GetCameraVerticalAngle (ongebruikt nu nog)
  //result := 2.0 + result * 2.0;
end;

function DecimalSec(F : String): Single;
begin
  F := StringReplace(F,',',DecimalSeparator,[rfReplaceAll,rfIgnoreCase]);
  F := StringReplace(F,'.',DecimalSeparator,[rfReplaceAll,rfIgnoreCase]);
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
  Connected := Enabled;
  edtHost.Enabled := not Enabled;
  edtPassword.Enabled := not Enabled;
  edtPort.Enabled := not Enabled;
  edtNickname.Enabled := not Enabled;
  btnConnect.Enabled := not Enabled;
  btnDisconnect.Enabled := Enabled;
  btnStartGame.Enabled := Enabled;
  //tabGame.Enabled := Enabled;
  If (Enabled = True) Then
    tabGame.Show;
//  Else
//    tabBrowser.Show;
  If (Enabled = False) Then
  Begin
    lstPlayers.Clear;
    lstPlayers2.Clear;
  End;
  If (Enabled = False) and (SAOn = True) Then
  Begin
    Val := 1;
    WriteMem($C17050,Val,1);
  End;
end;

procedure LogOut(Str : String);
begin
  frmMain.memoChat.Lines.Add(Str);
end;

procedure Log(Str : String);
begin
  If (frmMain.cbxTimestamps.Checked = True) Then
    Str := '['+ IntToStr(HourOf(Now)) +':'+ IntToStr(MinuteOf(Now)) +':'+ IntToStr(SecondOf(Now)) +'] '+ Str;
  frmMain.memoChat.Lines.Add(Str);
  If (SAOn = False) or (frmMain.TCP.Connected = False) Then
    Exit;
  Chat1.Add(Str);
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

procedure TReceiveThread.Execute;
begin
  While True Do
  Begin
    If (frmMain.TCP.Connected) Then
    Begin
      frmMain.ParseMessage(frmMain.TCP.ReadLn('')); // TODO: Decrypt
    End;
  End;
end;

procedure TfrmMain.ParseMessage(Str : String);
var
  Arr, Arr2 : TSplitArray;
  i, i2, i3, i4 : Integer;
  Sl : Single;
  SkipNext : Boolean;
  Dat : String;
begin
  If (cbxDev.Checked = True) Then
    LogOut('[DEBUG] '+ Str);
  Arr := Split('a'+ PACKET_SEPARATOR +'a',PACKET_SEPARATOR);
  Arr2 := Split('a'+ PACKET_SEPARATOR +'a',PACKET_SEPARATOR);
  If (Str = '') Then
    Exit;
  Try
    Arr := Split(Str,PACKET_SEPARATOR);
  Except
    Arr[0] := Str;
  End;
  If (Arr[0] = PACKET_SYNC) Then // Syncing \o/
    ProcessSync(Str)
  Else If (Arr[0] = PACKET_MAPDATA) Then
    Map.Add(Str)
  Else If (Arr[0] = PACKET_PING) Then // We are pinged by the server!
  Begin
    SkipNext := False;
    i := High(Arr)-1;
    If (i > 0) Then
    Begin
      For i2 := 1 To i Do
      Begin
        If (SkipNext = True) Then
        Begin
          SkipNext := False;
          Continue;
        End;
        Dat := PlayerNick[StrToInt(Arr[i2])];
        i4 := lstPlayers2.IndexOf(Dat);
        If (i4 > -1) Then
           frmMain.lstPlayers.Items.Item[i4].SubItems[1] := Arr[i2+1];
        SkipNext := True;
      End;
    End;
    GotPings := 0;
    frmMain.TCP.WriteLn(PACKET_PONG + PACKET_SEPARATOR + IntToStr(PlayerID)); // Ping? Pong!
  End
  Else If (Arr[0] = PACKET_CONN) Then // Answer from server @ connection
  Begin
    If (StrToInt(Arr[1]) = 0) Then
    Begin
      PlayerID := StrToInt(Arr[2]);
      //SkinID := 200 + PlayerID;
      Log('*** Connected as player '+ Arr[2]);
      frmMain.TCP.WriteLn(PACKET_INFO); // Get server info (Server name)
      frmMain.TCP.WriteLn(PACKET_PLAYERS); // Get connected players
      frmMain.SetConnected(True);
    End
    Else
    Begin
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
  Else If (Arr[0] = PACKET_PLAYER_JOIN) Then // New player connected
  Begin
    with frmMain.lstPlayers.Items.Add() do
    begin
      Caption := Arr[1];
      SubItems.Add(Arr[2]);
      SubItems.Add('?');
    end;
    lstPlayers2.Add(Arr[2]);
    PlayerNick[DoStrToInt(Arr[1])] := Arr[2];
    Log('*** '+ Arr[2] +' has joined the server (ID: '+ Arr[1] +')');
  End
  Else If (Arr[0] = PACKET_PLAYERCHANGE) Then // We're being teleported and other things...
  Begin
      If (SAOn = False) Then
        Exit;

    ReadMem($B6F5F0,i,4);
    If (Arr[1] = PACKET_PLAYERCHANGE_HEALTH) Then
    Begin
      Sl := DecimalSec(Arr[2]);
      WriteMem(i + 1344,Sl,4);
    End
    Else If (Arr[1] = PACKET_PLAYERCHANGE_ARMOR) Then
    Begin
      Sl := DecimalSec(Arr[2]);
      WriteMem(i + 1352,Sl,4);
    End
    Else If (Arr[1] = PACKET_PLAYERCHANGE_POS) Then
    Begin
      ReadMem(i + 20,i2,4);

      Sl := DecimalSec(Arr[2]);
      WriteMem(i2 + 48,Sl,4); // Position X

      Sl := DecimalSec(Arr[3]);
      WriteMem(i2 + 52,Sl,4); // Position Y

      Sl := DecimalSec(Arr[4]);
      WriteMem(i2 + 56,Sl,4); // Position Z
    End
    Else If (Arr[1] = PACKET_PLAYERCHANGE_ROTATION) Then
    Begin
      Sl := DecimalSec(Arr[2]);
      WriteMem(ScriptBase + (4 * 103),Sl,4);
    End
    Else If (Arr[1] = PACKET_PLAYERCHANGE_SKIN) Then
    Begin
      SkinID := DoStrToInt(Arr[2]);
    End
    Else If (Arr[1] = PACKET_PLAYERCHANGE_INTERIOR) Then
    Begin
      i2 := DoStrToInt(Arr[2]);
      WriteMem(ScriptBase + (4 * 105),i2,4);
    End;
  End
  Else If (Arr[0] = PACKET_TIMEWEATHER) Then // Time & Weather
  Begin // syntax is chr(21) + chr(uren) + chr(minuten) + chr(weer id)
    // Weer
    If (SAOn = False) Then
      Exit;
    i := DoStrToInt(Arr[3]);
    WriteMem($C81318,i,4);
    WriteMem($C8131C,i,4);
    WriteMem($C81320,i,4);

    // Tijd
    i := DoStrToInt(Arr[1]);
    i2 := DoStrToInt(Arr[2]);
    WriteMem($B70153,i,1); // Uur
    WriteMem($B70152,i2,1); // Minuut
  End
  Else If (Arr[0] = PACKET_CHAT) Then // Chat
  Begin
    If (DoStrToInt(Arr[1]) < 1) Then
      Log(Arr[2])
    Else
      Log(PlayerNick[DoStrToInt(Arr[1])] +': '+ Arr[2]);
  End
  Else If (Arr[0] = PACKET_INFO) Then // Info B
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
  Else If (Arr[0] = PACKET_GAME_CLOSED) Then // Player closed the game
  Begin
    i2 := DoStrToInt(Arr[1])-1;
    //i3 := 0;
{    WriteMem(ScriptBase + (4 * (1100 + i2)),i3,4); // PlrCar
    WriteMem(ScriptBase + (4 * (1200 + i2)),i3,4); // PlrSeat
    i3 := -1;
    WriteMem(ScriptBase + (4 * (200 + i2)),i3,4);}
  End
  Else If (Arr[0] = PACKET_PLAYER_PART) Then // New player disconnected
  Begin
    i := lstPlayers2.IndexOf(PlayerNick[DoStrToInt(Arr[1])]);
    lstPlayers2.Delete(i);
    frmMain.lstPlayers.Items.Delete(i);
    //frmMain.lstPlayers.Items.
    //frmMain.lstPlayers.Items.IndexOf()
    //frmMain.lstPlayers.Items.Delete(frmMain.lstPlayers.Items.IndexOf(PlayerNick[DoStrToInt(Arr[1])]));
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
  Else If (Arr[0] = PACKET_GOOD_BYE) Then // Server wil client weghebben @_@
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
  Else If (Arr[0] = PACKET_PLAYERS) Then // Connected players
  Begin
    i := High(Arr)-1;
    If (i > 0) Then
    Begin
      For i2 := 1 To i Do
      Begin
        Arr2 := Split(Arr[i2],' ');
        i3 := DoStrToInt(Arr2[0]);
        PlayerNick[i3] := Arr2[1];
        with frmMain.lstPlayers.Items.Add() do
        begin
          Caption := IntToStr(i3);
          SubItems.Add(Arr2[1]);
          SubItems.Add('?');
        end;
        lstPlayers2.Add(Arr2[1]);
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
  End;
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
    edtNickname.Text := StringReplace(edtNickname.Text, PACKET_SEPARATOR, ' ',[rfReplaceAll, rfIgnoreCase]);
    edtPassword.Text := StringReplace(edtPassword.Text, PACKET_SEPARATOR, ' ',[rfReplaceAll, rfIgnoreCase]);
    TCP.Host := edtHost.Text;
    TCP.Port := DoStrToInt(edtPort.Text);
    Try
      TCP.Connect;
    Except
      Log('*** Couldn''t establish a connection');
      Connected := False;
      Disconnect(False);
      SetConnected(False);
      Exit;
    End;

    If (TCP.Connected = False) Then
    Begin
      Log('*** Couldn''t establish a connection');
      Connected := False;
      Disconnect(False);
      SetConnected(False);
      Exit;
    End;
    Connected := True;
    TCP.WriteLn(PACKET_CONN + PACKET_SEPARATOR + VERSION_HASH + PACKET_SEPARATOR + edtNickname.Text + PACKET_SEPARATOR + calcMD5(edtPassword.Text));
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
  CPed, Val : Integer;
  Sl1, Sl2, Sl3 : Single;
begin
  If Not (edtChat.Text <> '') or (TCP.Connected = False) Then
    Exit;
  If ( Length(edtChat.Text) > 150 ) Then
  Begin
    Log('*** Your chat message is too long (Limit: 150 characters)');
    Exit;
  End;
  If (edtChat.Text = '/usuk') Then
  Begin
    ReadMem($B6F5F0,CPed,4); // CPed (basis van de speler pool)
    ReadMem(CPed + $47C,Val,4);
    ReadMem(Val + $10,Val,4);
    ReadMem(Val + $10,Sl1,4);
    ReadMem(Val + $14,Sl2,4);
    ReadMem(Val + $18,Sl3,4);
    Log('Weapons aim >>> '+ FloatToStr(Sl1) +' - '+ FloatToStr(Sl2) +' - '+ FloatToStr(Sl3));
    edtChat.Clear;
    edtChat.SetFocus;
    Exit;
  End;
  Str := StringReplace(edtChat.Text, PACKET_SEPARATOR, ' ',[rfReplaceAll, rfIgnoreCase]);
  TCP.WriteLn(PACKET_CHAT + PACKET_SEPARATOR + IntToStr(PlayerID) + PACKET_SEPARATOR + Str);
  //Log(PACKET_CHAT + PACKET_SEPARATOR + IntToStr(PlayerID) + PACKET_SEPARATOR + Str);
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
  Map := TStringList.Create;
  Chat1 := TStringList.Create;
  Chat2 := TStringList.Create;
  lstPlayers2 := TStringList.Create;
  reg := TRegistry.Create;
  try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.OpenKeyReadOnly('Software\SA-Party');

    if (reg.ValueExists('Timestamps')) then
      cbxTimestamps.Checked := reg.ReadBool('Timestamps')
    else
      cbxTimestamps.Checked := False;

    if (reg.ValueExists('Windowed')) then
      cbxWindowed.Checked := reg.ReadBool('Windowed')
    else
      cbxWindowed.Checked := False;

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
  Version := '0.5.0.0 PRE-BUILD';
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
end;

procedure TfrmMain.Disconnect(LogAllowed : Boolean);
var
  Val : Byte;
begin
  If (TCP.Connected = True) Then
  Begin
    TCP.WriteLn(PACKET_DISCONNECT + PACKET_SEPARATOR + IntToStr(PlayerID));
    TCP.Disconnect;
    SetConnected(False);
    Connected := False;
    If (SAOn = True) Then
    Begin
      Val := 1;
      WriteMem($C17050,Val,1);
    End;
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

  //Patch(GameDir + '\data\script\main.scm',GameDir +'\data\script\main.scm.sapbak');
  //Patch(GameDir + '\data\script\script.img',GameDir +'\data\script\script.img.sapbak');
  F := GameDir +'\d3d9.dll';
  If ( FileExists(F) ) Then
  Begin
    Patch(GameDir + '\d3d9.dll',GameDir +'\d3d9.dll.sapbak');
    DeleteFile(F);
  End;

  F := GameDir +'\d3dx9_34.dll';
  If not ( FileExists(F) ) Then
    Patch(ExtractFilePath(Application.ExeName) + '\data\d3dx9_34.dll',GameDir +'\d3dx9_34.dll');

  Patch(GetCurrentDir + '\data\main.scm',GameDir +'\data\script\saps.scm');
  Patch(GetCurrentDir + '\data\script.img',GameDir +'\data\script\script.img');
  Patch(GetCurrentDir + '\data\d3d9.dll',GameDir +'\d3d9.dll'); // chat.nfo

  If (cbxWindowed.Checked = True) Then
    ShellExecute(Handle,'open', 'gta_sa.exe', '-sap -window', PChar(GameDir), SW_SHOWNORMAL)
  Else
    ShellExecute(Handle,'open', 'gta_sa.exe', '-sap', PChar(GameDir), SW_SHOWNORMAL);

  LastDead := False;
end;

procedure NOPOffsets();
var
  ReNOP, Address : Array of Integer;
  Val, i : Integer;
  offset : Integer;
  Str : PChar;
  Sl : Single;
begin
    //i := $5;
    //WriteMem($C8D4C0,i,1); // Skip loadscreens
    NOP($7474D3,6);
    Val := 210;
    WriteMem($550FF2,Val,1); // PED stuff hoger
    WriteMem($551283,Val,1); // PED stuff hoger
    Val := $05;
    WriteMem($551140,Val,1);
    Val := $01;
    WriteMem($551178,Val,1);


{    SetLength(ReNOP,7);
    ReNOP[0] := chr();
    ReNOP[1] := $00;
    ReNOP[2] := $68;
    ReNOP[3] := 127;
    ReNOP[4] := $00;
    ReNOP[5] := $00;
    ReNOP[6] := $00;
    offset := $5B8FDE;
    For i := 0 To 6 Do
    Begin
      Val := ReNOP[i];
      WriteMem(offset + i,Val,1);
    End;  }
    // ^ I actually don't know what this does

{ Sl := 430.0;
WriteMem($866B70,Sl,4); // Radar position

{Sl := 0.0011;
WriteMem($859520,Sl,4); // Horizontale HUD scale

Sl := 0.00172;
WriteMem($859524,Sl,4); // Vertical HUD scale }

//Str := PChar('title_pc_EU');
//WriteMem($866CD8,Str,11);
//Str := PChar('eax           ');
//WriteMem($866CCC,Str,8);

Val := 134217728;
WriteMem($5B8E6A,Val,4);


   SetLength(ReNOP,7);
    SetLength(Address,7);
    Address[0] := $6F7900;
    ReNOP[0] := $C3;
    Address[1] := $6F7865;
    ReNOP[1] := $EB;
    Address[2] := $6CD2F0;
    ReNOP[2] := $C3;
    Address[3] := $42B7D0;
    ReNOP[3] := $C3;
    Address[4] := $6F3F40;
    ReNOP[4] := $C3;
    Address[5] := $6B0BC2;
    ReNOP[5] := $EB;
    Address[6] := $5B47B0;
    ReNOP[6] := $C3; // Disable pickups
    For i := 0 To 6 Do
    Begin
      Val := ReNOP[i];
      WriteMem(Address[i],Val,1);
    End;

  NOP($438480,5); // Block cheats
  NOP($5DEC04,6); // Walk/Run animations
  //NOP($6E0A3B,6); // Car horn
  //NOP($43828F,6); // Vehicle steers
  //NOP($561AF0,6); // Pauze ga door
  //NOP($53E799,7);
  //NOP($588FA9,6); // Text display 1
  //NOP($58AA6F,2); // Zone-name texts
  //NOP($58905E,6); // Text display 2
  //NOP($69DBB8,3); // Transparant box disabler
  NOP($53E799,7); // New game skip
  NOP($576C34,3); // New game skip
  NOP($576C41,4); // New game skip
  NOP($53C090,5); // Turn replay off
  NOP($53BFB8,5); // CGame::Process - call _processGarages
  //NOP($53BFBD,5); // Freeze clock
  i := $01;
  WriteMem($C0BC15,i,1);
  NOP($53C0B7,5); // Something with garages
  //NOP($72DF08,5); // Drive everywhere fast

//  Int := 0; // $0 // Turn motion blur off
//  WriteMem($8D5104,Int,1);

//  Int := 235; // $EB // Turn vertigo effect off
//  WriteMem($524B3E,Int,1);
  
  //Int := 235; // $EB // Disable traffic
  //WriteMem($434237,Int,1); // Disable traffic
  //NOP($6B52A8,5);
  //NOP($6BCD81,5);
  //NOP($56863F,3);
  //NOP($58EC21,5); // Don't display clock
  //Str := 'sap.scm';
  //WriteMem($859D60,Str,SizeOf(Str)); // SCM 1

  //Str := 'data\\script\\sap.scm';
  //WriteMem($859F64,Str,SizeOf(Str)); // SCM 2
  
  //Str := 'sap.txd';
  //WriteMem($866CF0,Str,SizeOf(Str)); // Load screens


    SetLength(ReNOP,7);
    ReNOP[0] := $6A;
    ReNOP[1] := $00;
    ReNOP[2] := $68;
    ReNOP[3] := 127;
    ReNOP[4] := $00;
    ReNOP[5] := $00;
    ReNOP[6] := $00;
    offset := $5B8FDE;
    For i := 0 To 6 Do
    Begin
      Val := ReNOP[i];
      WriteMem(offset + i,Val,1);
    End;

    SetLength(ReNOP,5);
    ReNOP[0] := $33;
    ReNOP[1] := $C0;
    ReNOP[2] := $C2;
    ReNOP[3] := $04;
    ReNOP[4] := $00;
    offset := $48E970;
    For i := 0 To 4 Do
    Begin
      Val := ReNOP[i];
      WriteMem(offset + i,Val,1);
    End;



    Val := $42;
    WriteMem($551060,Val,1);

    // -BEGIN- raise player limit // Why do we need this? We work with actors :')

    SetLength(ReNOP,6);
    ReNOP[0] := $E9;
    ReNOP[1] := $9D;
    ReNOP[2] := $00;
    ReNOP[3] := $00;
    ReNOP[4] := $00;
    ReNOP[5] := $90;
    offset := $60D64D;
    For i := 0 To 5 Do
    Begin
      Val := ReNOP[i];
      WriteMem(offset + i,Val,1);
    End;
    // -EIND- raise player limit

    {asm
		popad
    mov edx, $60EA90
		call edx // call the original CPlayerPed::ProcessControl
		pushad
    end; }


    NOP($56E5AD,5); // No wasted message
    NOP($53EA08,10); // caused 0x706B2E crash (This seems to be ped shadow rendering)
    Val := 80;
    WriteMem($71162C,Val,1); // Darken the shadows...
    NOP($609C08,39); // Unknown from CPlayerPed::ProcessControl causes crash

    // Fix the drown-in-vehicle crash
    Val := $B0;
    WriteMem($4BC6C1,Val,1);
    Val := $00;
    WriteMem($4BC6C2,Val,1);
    Val := $90;
    WriteMem($4BC6C3,Val,1);

    // Respawn and interior // Lol wut?
    Val := $C3;
    WriteMem($4090A0,Val,1);
    NOP($53C06A,5);

    NOP($434272,5); // SomeCarGenerator (0x41a8b3 crash)

    //Val := $84;
    //WriteMem($60D64E,Val,1); // CPlayerPed_CPlayerPed .. task system corrupts some shit

    //NOP($542485,11); //  CPhysical Destructor (705b3b crash)  
end;

procedure TfrmMain.tmrProcessTimer(Sender: TObject);
var
  PID : Integer;
  F : String;
begin
 //GetWindowThreadProcessId(FindWindow(nil,'GTA: San Andreas'), @PID);
  GetWindowThreadProcessId(FindWindow(nil,'SA:Party'), @PID);
  hProc := OpenProcess(PROCESS_ALL_ACCESS, False, PID);
  If (hProc > 0) Then
  Begin
    SAOn := True;
    If (SAOnLast = False) Then
    Begin
      NOPOffsets;
      If (TCP.Connected = True) Then
      Begin
        TCP.WriteLn(PACKET_GAME_STARTED + PACKET_SEPARATOR + IntToStr(PlayerID));
        TCP.WriteLn(PACKET_MAPDATA);
      End;
      btnStartGame.Enabled := False;
      tmrSync.Enabled := True;
    End;
    SAOnLast := True;
  End
  Else
  Begin
    SAOn := False;
    If (SAOnLast = True) Then
    Begin
      tmrLoadMap.Enabled := False;
      Map.Clear;
      SkinID := 0;
      
      tmrSync.Enabled := False;
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
      If (TCP.Connected = True) Then
        TCP.WriteLn(PACKET_GAME_CLOSED + PACKET_SEPARATOR + IntToStr(PlayerID));
      btnStartGame.Enabled := True;
    End;
    SAOnLast := False;
  End;
  //------------------------------------------------
  //-----------------INGAME CHATBOX-----------------
  //------------------------------------------------
  If (SAOn = False) or (TCP.Connected = False) Then
    Exit;
  If ( FileExists(GameDir +'\chat.fle') ) Then
  Begin
    Try
      Chat2.Clear;
      Chat2.LoadFromFile(GameDir +'\chat.fle');
      DeleteFile(GameDir +'\chat.fle');
      F := StringReplace(Chat2.Strings[0], PACKET_SEPARATOR, ' ',[rfReplaceAll, rfIgnoreCase]);
      TCP.WriteLn(PACKET_CHAT + PACKET_SEPARATOR + IntToStr(PlayerID) + PACKET_SEPARATOR + F);
    Except
    End;
  End;
  If ( FileExists(GameDir +'\chatbox.fle') ) or ( Chat1.Count = 0 ) Then
    Exit;
  Try
    Chat1.SaveToFile(GameDir +'\chatbox.fle');
    Chat1.Delete(0);
  Except
  End;
end;

procedure TfrmMain.TCPConnected(Sender: TObject);
begin
   ReceiveThread := TReceiveThread.Create(False);
  TCP.Socket.UseNagle := False;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Chat2.Free;
  Chat1.Free;
  lstPlayers2.Free;
  Map.Free;
  If (TCP.Connected) Then
  Begin
    ReceiveThread.Suspend;
    Disconnect(False);
  End;
  Application.Terminate;
end;

procedure TfrmMain.tmrPingPongTimer(Sender: TObject);
begin
  If (TCP.Connected = True) Then
  Begin
    GotPings := GotPings + 1;
    If (GotPings > 5) Then // Time out...
    Begin
      GotPings := 0;
      Log('*** Disconnected (Reason: CLIENT Timed Out)');
      frmMain.Disconnect(False);
      frmMain.SetConnected(False);
    End;
  End
  Else
    GotPings := 0;
end;

procedure TfrmMain.tmrSyncTimer(Sender: TObject);
var
  ReNOP : Array of Integer;
  Val, i, CPed, CPos, State, Val2 : Integer;
  offset : Integer;
  Data : String;
  Sl : Single;
  PosX, PosY, PosZ : Single;
begin
  If (SAOn = False) or (TCP.Connected = False) Then
    Exit;
  ReadMem(ScriptBase + (4 * 100),Val,4);
  If (Val = 0) or (Val > 10) Then
    Exit;

  ReadMem($B6F5F0,CPed,4); // CPed (basis van de speler pool)
  ReadMem(CPed + 1328,State,4); // Status van speler (in auto, op de voet, masturberende...)

  If (Val = 1) Then
  Begin
    // BEGIN <> HIERMEE LATEN WE HET MENU WEER WERKEN ZOALS HET HOORT
    SetLength(ReNOP,10);
    ReNOP[0] := $C6;
    ReNOP[1] := $5;
    ReNOP[2] := $A4;
    ReNOP[3] := $67;
    ReNOP[4] := $BA;
    ReNOP[5] := $0;
    ReNOP[6] := $1;
    offset := $53E799;
    For i := 0 To 6 Do
    Begin
      Val := ReNOP[i];
      WriteMem(offset + i,Val,1);
    End;

    SetLength(ReNOP,4);
    ReNOP[0] := $C6;
    ReNOP[1] := $46;
    ReNOP[2] := $5C;
    ReNOP[3] := $1;
    offset := $576C41;
    For i := 0 To 3 Do
    Begin
      Val := ReNOP[i];
      WriteMem(offset + i,Val,1);
    End;

    SetLength(ReNOP,3);
    ReNOP[0] := $88;
    ReNOP[1] := $4E;
    ReNOP[2] := $5C;
    offset := $576C34;
    For i := 0 To 2 Do
    Begin
      Val := ReNOP[i];
      WriteMem(offset + i,Val,1);
    End;
    // EIND <> HIERMEE LATEN WE HET MENU WEER WERKEN ZOALS HET HOORT

    Val := 2;
    WriteMem(ScriptBase + (4 * 100),Val,4);

    If (cbxDev.Checked = True) Then
      Log('[DEBUG] Patching menu.');

    Exit;
  End
  Else If (Val = 3) and (LastDead = False) Then
  Begin
    If (cbxDev.Checked = True) Then
      Log('[DEBUG] Value 3');
    LastDead := True;
    Log('[DEBUG] Spawned 111111');

    Exit;
  End
  Else If (State = 1) and (LastDead = True) and (Val = 3) Then
  Begin
    LastDead := False;
    TCP.WriteLn(PACKET_SPAWNED + PACKET_SEPARATOR + IntToStr(PlayerID));
    Val := 4;
    WriteMem(ScriptBase + (4 * 100),Val,4);
    Log('[DEBUG] Spawned 222222');
    If (cbxDev.Checked = True) Then
      Log('[DEBUG] Local player spawned.');

    Exit;
  End
  Else If (State = 55) and ((Val = 4) or (Val = 5)) Then // Dood
  Begin
    SkinID := -1;
    Data := PACKET_SYNC + PACKET_SEPARATOR + IntToStr(PlayerID) + PACKET_SEPARATOR +'-1';
    TCP.WriteLn(Data);
    If (cbxDev.Checked = True) Then
      LogOut('[DEBUG] Dead');
    If (Val = 4) Then
    Begin
      LastDead := True;
      If (cbxDev.Checked = True) Then
        Log('[DEBUG] Local player died.');
      Data := PACKET_RICKROLLED + PACKET_SEPARATOR + IntToStr(PlayerID) + PACKET_SEPARATOR + '0' + PACKET_SEPARATOR + '0';
      TCP.WriteLn(Data);
      LastDead := True;
    End;
    Val := 3;
    WriteMem(ScriptBase + (4 * 100),Val,4);

    Exit;
    //LogOut('Dead meat...');
  End;
  If not (Val = 4) Then
    Exit;
  //LogOut('Sending (Part 1)...');
  //If (tmrLoadMap.Enabled = False) Then
  //  tmrLoadMap.Enabled := True;

  WriteMem(ScriptBase + (4 * 101),SkinID,4); // Skin van speler veranderen
  If (State = 1) or (State = 12) Then
  Begin
    ReadMem(CPed + 20,CPos,4);
    Data := PACKET_SYNC + PACKET_SEPARATOR + IntToStr(PlayerID) + PACKET_SEPARATOR + IntToStr(SkinID);
    ReadMem(CPos + 48,PosX,4); // Position X
    Data := Data + PACKET_SEPARATOR + FormatFloat('0.000',PosX);

    ReadMem(CPos + 52,PosY,4); // Position Y
    Data := Data + PACKET_SEPARATOR + FormatFloat('0.000',PosY);

    ReadMem(CPos + 56,PosZ,4); // Position Z
    Data := Data + PACKET_SEPARATOR + FormatFloat('0.000',PosZ);

    //ReadMem(ScriptBase + (4 * 102),Sl,4); // Rotation van speler uitlezen
    ReadMem(CPed + 1372,Sl,4);
    //Sl := 0.0;
    Data := Data + PACKET_SEPARATOR + FormatFloat('0.000',Sl);

    ReadMem(CPed + 1344,Sl,4); // Health
    Data := Data + PACKET_SEPARATOR + FormatFloat('0.000',Sl);

    ReadMem(CPed + 1332,Val,1); // Ren animatie
    ReadMem(CPed + 1247,Val2,1); // Animatie play state?!
    If (Val = 6) And (Val2 = 61) Then
      Val := 4;
    Data := Data + PACKET_SEPARATOR + IntToStr(Val);

    ReadMem(CPed + 1135,Val,1); // Bukken
    If (Val = 132) Then
    Begin
      ReadMem(CPed + 1148,Val2,4); // Animation structure // DWord
      ReadMem(Val2 + 28,Val2,4); // Crouch animation structure // DWord
      ReadMem(Val2 + 31,Val,1); // Byte
      ReadMem(Val2 + 32,Sl,4); // Float
      Data := Data + PACKET_SEPARATOR +'1'+ PACKET_SEPARATOR + IntToStr(Val) + PACKET_SEPARATOR + FormatFloat('0.0',Sl);
    End
    Else
    Begin
      Data := Data + PACKET_SEPARATOR +'0'+ PACKET_SEPARATOR +'0.0'+ PACKET_SEPARATOR +'0.0';
    End;

    ReadMem(CPed + 1352,Sl,4); // Armor
    Data := Data + PACKET_SEPARATOR + FormatFloat('0.000',Sl);

    ReadMem(ScriptBase + (4 * 104),Val2,4); // Interior
    Data := Data + PACKET_SEPARATOR + IntToStr(Val2);

    ReadMem(ScriptBase + (4 * 106),Val2,4); // Armed weapon
    Data := Data + PACKET_SEPARATOR + IntToStr(Val2);

    If (Val2 > 0) Then
    Begin
      ReadMem(CPed + 1148,Val,4); // Animation structure // DWord
      ReadMem(Val + 24,Val,4); // Fight animation structure // DWord
      ReadMem(Val + 16,Val2,1);
      { ReadMem(CPed + 1816,Val,1);
      ReadMem(CPed + 1440 + (28 * Val) + 4,Val,4);
      //If (Val = 0) and (State = 12) Then // We're aiming/targetting
      //  Val := 1
      If (Val = 2) Then // Reloading
        Val := 1
      Else If (Val = 1) Then
        Val := 2; }
      // 1 = Targeting
      // 2 = Shooting
      // 3 = ???
      // 4 = Reloading
      If (Val = 4) Then
        Val := 1;
      Data := Data + PACKET_SEPARATOR + IntToStr(Val2); // Schiet status

      ReadMem(ScriptBase + (4 * 107),Sl,4); // Shoot X
      Data := Data + PACKET_SEPARATOR + FormatFloat('0.000',Sl);

      ReadMem(ScriptBase + (4 * 108),Sl,4); // Shoot Y
      Data := Data + PACKET_SEPARATOR + FormatFloat('0.000',Sl);

      ReadMem(ScriptBase + (4 * 109),Sl,4); // Shoot Z
      Data := Data + PACKET_SEPARATOR + FormatFloat('0.000',Sl);

        { ReadMem($B6F32C,Sl,4); // PosX
        Data := Data + PACKET_SEPARATOR + FormatFloat('0.0000',PosX+Sl);
        
        ReadMem($B6F330,Sl,4); // PosY
        Data := Data + PACKET_SEPARATOR + FormatFloat('0.0000',PosY+Sl);

        ReadMem($B6F334,Sl,4); // PosZ
        Data := Data + PACKET_SEPARATOR + FormatFloat('0.0000',PosZ+Sl); }
    End
    Else
    Begin
      Data := Data + PACKET_SEPARATOR + '0';
    End;

	  TCP.WriteLn(Data);
    If (cbxDev.checked) Then
      LogOut('[OUT] '+ Data);
  End;
end;

procedure TfrmMain.ProcessSync(Data : String);
var
  Arr : TSplitArray;
  Sl : Single;
  PID, Val, Val2, SCMVal, CPed, CPos, State : Integer;
begin
  Arr := Split('a'+ PACKET_SEPARATOR +'a',PACKET_SEPARATOR);
  If (SAOn = False) or (TCP.Connected = False) Then
    Exit;
  ReadMem(ScriptBase + (4 * 100),Val,4);
  If not (Val = 4) and not (Val = 5) Then
    Exit;
  Arr := Split(Data,PACKET_SEPARATOR); // Split the string :-)
  
  PID := DoStrToInt(Arr[1]) - 1;

  Val2 := DoStrToInt(Arr[2]);
  WriteMem(ScriptBase + (4 * (200 + PID)),Val2,4); // PlayerActive (creates actor etc.)
  If (Val2 = -1) Then
    Exit;

  SCMVal := 0;

  ReadMem(ScriptBase + (4 * PID),SCMVal,4);
  If (SCMVal > 28161) or (SCMVal <= 0) Then // ( 110 * 256 ) + 1 = 28161
  Begin
    PlrSCM[PID] := 0;
    Exit;
  End;
  PlrSCM[PID] := SCMVal;

  ReadMem($B6F5F0,CPed,4);
  Try
    Val2 := (SCMVal - 1) div 256;
    If (Val2 = 0) Then
      Exit;
  Except
    If (cbxDev.Checked = True) Then
      Log('[DEBUG] Assigning player to actor failed (P'+ IntToStr(PID) +' V'+ IntToStr(SCMVal) +').');
    Exit;
  End;
  CPed := CPed + (1988 * Val2); // CPed
  ReadMem(CPed + 1328,State,4); // Status van speler

  If (Arr[0] = PACKET_SYNC) Then // Onfoot
  Begin
    ReadMem(CPed + 20,CPos,4);

    Sl := DecimalSec(Arr[3]);
    WriteMem(CPos + 48,Sl,4); // Position X

    Sl := DecimalSec(Arr[4]);
    WriteMem(CPos + 52,Sl,4); // Position Y

    Sl := DecimalSec(Arr[5]);
    WriteMem(CPos + 56,Sl,4); // Position Z

    Sl := DecimalSec(Arr[6]);
    Val := DoStrToInt(Arr[15]);
    If (Val = 0) Then
    Begin
    WriteMem(CPed + 1372,Sl,4);
    WriteMem(CPed + 1368,Sl,4);
    End;
    //WriteMem(ScriptBase + (4 * (300 + PID)),Sl,4); // SCM rotatie schrijven

    Val := DoStrToInt(Arr[8]);
    WriteMem(CPed + 1332,Val,1); // Ren animaties

    Sl := DecimalSec(Arr[7]);
    WriteMem(CPed + 1344,Sl,4); // Health

    Val := DoStrToInt(Arr[9]);
    WriteMem(ScriptBase + (4 * (400 + PID)),Val,4);
    If (Val = 1) Then
    Begin
      ReadMem(CPed + 1148,Val2,4); // Animation structure // DWord
      ReadMem(Val2 + 28,Val2,4); // Crouch animation structure // DWord
      Val := DoStrToInt(Arr[10]);
      WriteMem(Val2 + 31,Val,1); // Byte
      Sl := DecimalSec(Arr[11]);
      WriteMem(Val2 + 32,Sl,4); // Float
    End;

    Sl := DecimalSec(Arr[12]);
    WriteMem(CPed + 1352,Sl,4); // Armor

    Val := DoStrToInt(Arr[14]);
    WriteMem(ScriptBase + (4 * (500 + PID)),Val,4); // Armed weapon
    
    If (Val > 0) Then
    Begin
      Val := DoStrToInt(Arr[15]);
      WriteMem(ScriptBase + (4 * (600 + PID)),Val,4); // Schiet status

      Sl := DecimalSec(Arr[16]);
      WriteMem(ScriptBase + (4 * (700 + PID)),Sl,4); // ShootX

      Sl := DecimalSec(Arr[17]);
      WriteMem(ScriptBase + (4 * (800 + PID)),Sl,4); // ShootX

      Sl := DecimalSec(Arr[18]);
      WriteMem(ScriptBase + (4 * (900 + PID)),Sl,4); // ShootX
    End;
  End;
end;

procedure TfrmMain.cbxTimestampsClick(Sender: TObject);
var
  reg : TRegistry;
begin
  reg := TRegistry.Create;
  Try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.OpenKey('Software\SA-Party', True);
    reg.WriteBool('Timestamps',cbxTimestamps.Checked);
    reg.CloseKey;
  Finally
    reg.Free;
  End;
end;

procedure TfrmMain.cbxWindowedClick(Sender: TObject);
var
  reg : TRegistry;
begin
  reg := TRegistry.Create;
  Try
    reg.RootKey := HKEY_CURRENT_USER;
    reg.OpenKey('Software\SA-Party', True);
    reg.WriteBool('Windowed',cbxWindowed.Checked);
    reg.CloseKey;
  Finally
    reg.Free;
  End;
end;

procedure TfrmMain.tmrLoadMapTimer(Sender: TObject);
var
  Str : String;
  Arr : TSplitArray;
  WriteToSCM : Boolean;
  Int, Val : Integer;
  Sl : Single;
begin
  Arr := Split('a'+ PACKET_SEPARATOR +'a',PACKET_SEPARATOR);
  If (TCP.Connected = False) or (SAOn = False) Then
    Exit;
  ReadMem(ScriptBase + (4 * 300),Int,4);
  If (Int = 2) and (Map.Count > 0) Then
  Begin
    Str := Map[0];
    Map.Delete(0);
    WriteToSCM := True;
    Arr := Split(Str,PACKET_SEPARATOR);
    If (Arr[1] = '1') Then // CreateObject
    Begin
      Val := DoStrToInt(Arr[1]);
      WriteMem(ScriptBase + (4 * 301),Val,4); // Command ID

      Val := DoStrToInt(Arr[2]);
      WriteMem(ScriptBase + (4 * 308),Val,4); // ObjectID

      Val := DoStrToInt(Arr[3]);
      WriteMem(ScriptBase + (4 * 309),Val,4); // ModelID

      Sl := DecimalSec(Arr[4]);
      WriteMem(ScriptBase + (4 * 302),Sl,4); // PosX

      Sl := DecimalSec(Arr[5]);
      WriteMem(ScriptBase + (4 * 303),Sl,4); // PosY

      Sl := DecimalSec(Arr[6]);
      WriteMem(ScriptBase + (4 * 304),Sl,4); // PosZ

      Sl := DecimalSec(Arr[7]);
      WriteMem(ScriptBase + (4 * 305),Sl,4); // RotX

      Sl := DecimalSec(Arr[8]);
      WriteMem(ScriptBase + (4 * 306),Sl,4); // RotY

      Sl := DecimalSec(Arr[9]);
      WriteMem(ScriptBase + (4 * 307),Sl,4); // RotZ
    End;

    If (WriteToSCM = True) Then
    Begin
      Log('DONE PLOX ('+ Str +')');
      Int := 3;
      WriteMem(ScriptBase + (4 * 300),Int,4);
    End;
  End;
end;

end.
