unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdBaseComponent, IdComponent, Math, StdCtrls, IdSocketHandle, MD5,
  ExtCtrls, INIFiles, untScripting, uPSComponent, IdTCPConnection, IdTCPClient,
  IdTCPServer, IdIRC, DCPCAST256, DCPSHA1;

type
  PClient = ^TClient;
  TClient = record
    IP : String;
    Thread : Pointer;
    Port : Integer;
  end;
  TModels = record
    Active : Boolean;
    ModelID : Integer;
    PosX,
    PosY,
    PosZ,
    RotX,
    RotY,
    RotZ : Single;
  end;
  TPlayer = record
    Handle,
    Ping,
    Port,
    PingChecks,
    Skin,
    Interior : Integer;
    Name,
    IP : String;
    Connected,
    Ingame,
    GotSoftDisconnect,
    Alive,
    Crouched : Boolean;
    PosX,
    PosY,
    PosZ,
    Rotation,
    Health,
    Armor : Single;
  end;
  TServer = record
    VersionHash,
    Password,
    Name,
    Version,
    Script : String;
    HardcodedMaxPlayers,
    PlayersConnected,
    LastPingCheck,
    MaxPlayers,
    StartCount,
    Hour,
    Minute,
    Weather : Integer;
  end;
  TSplitArray = array of String;
  TfrmMain = class(TForm)
    memoLog: TMemo;
    tmrPingCheck: TTimer;
    PScript: TPSScript;
    udpServer: TIdTCPServer;
    tmrSecond: TTimer;
    IRC: TIdIRC;
    procedure OnFormCreate(Sender: TObject);
    procedure SendDataToAll(Buffer : String);
    procedure SendDataToAllExceptPlayer(PlayerID : integer; Buffer : String);
    procedure SendDataToPlayer(PlayerID : Integer; Buffer : String);
    procedure OnPingCheck(Sender: TObject);
    procedure Err(Str : String);
    procedure OnScriptCompile(Sender: TPSScript);
    function  IsInteger(Str: String): Boolean;
    function  IsFloat(Str: String): Boolean;
    function  Split(const Source, Delimiter: String): TSplitArray;
    procedure OnFormClose(Sender: TObject; var Action: TCloseAction);
    function StrToFloatFix(Str: String): Single;
    function CopyBetween(Source, bs, es : String): String;
    function CopyAfter(Source, bs : String): String;
    function CopyBefore(Source, bs : String): String;
    procedure udpServerDisconnect(AThread: TIdPeerThread);
    procedure udpServerExecute(AThread: TIdPeerThread);
    procedure udpServerConnect(AThread: TIdPeerThread);
    procedure Log(Str : String);
    function GetWeaponName(WeaponID : Integer): String;
    function GetPlayerName(PlayerID : Integer): String;
    procedure SendMessageToPlayer(PlayerID : Integer; Buffer : String);
    procedure SendMessageToAllExceptPlayer(PlayerID : Integer; Buffer : String);
    procedure SendMessageToAll(Buffer : String);
    function calcMD5(Buffer : String): String;
    function GetPlayerPing(PlayerID : Integer): Integer;
    procedure SetPlayerSkin(PlayerID, SkinID : Integer);
    function  Distance(x1, y1, x2, y2: Integer): Integer;
    function  iAbsVal(I: Integer): Integer;
    function  Rndm(I: Integer): Integer;
    function  RndmRange(iFrom, iTo: Integer): Integer;
    function  iMaximum(N1, N2: Integer): Integer;
    function  iMinimum(N1, N2: Integer): Integer;
    function  Replace(Text, FindStr, ReplaceStr: string): string;
    function  GetNumbers(Text: string): string;
    function  GetLetters(Text: String): String;
    function  GetOthers(Text: String): String;
    function  TrimNumbers(Text: String): String;
    function  TrimLetters(Text: String): String;
    function  TrimOthers(Text: String): String;
    function  Capitalize(S: String): String;
    function  IsInCube(px, py, x1, y1, x2, y2 : Integer): Boolean;
    procedure CreateObject(ModelID : Integer;PosX, PosY, PosZ, RotX, RotY, RotZ : Single);
    procedure SendTimeWeatherToPlayer(PlayerID : Integer);
    procedure OnSecondTimer(Sender: TObject);
    procedure SetTime(Hour, Minutes : Integer);
    procedure SetWeather(WeatherID : Integer);
    procedure SetPlayerHealth(PlayerID : Integer; Health : Single);
    procedure KillPlayer(PlayerID : Integer);
    procedure SetPlayerArmor(PlayerID : Integer; Armor : Single);
    procedure SetPlayerPosition(PlayerID : Integer; PosX, PosY, PosZ : Single);
    procedure SetPlayerRotation(PlayerID : Integer; Rotation : Single);
    function  IsValidSkin(SkinID : Integer) : Boolean;
    function  GetPlayerPosX(PlayerID : integer): Single;
    function  GetPlayerPosY(PlayerID : integer): Single;
    function  GetPlayerRotation(PlayerID : integer): Single;
    function  GetPlayerPosZ(PlayerID : integer): Single;
    function  GetPlayerHealth(PlayerID : integer): Single;
    function  GetPlayerArmor(PlayerID : integer): Single;
    function  GetPlayerSkin(PlayerID : integer): Integer;
    function  GetWeather(): Integer;
    function  GetTime(): String;
    procedure SetPlayerInterior(PlayerID, Interior : Integer);
    function  GetPlayerInterior(PlayerID : Integer): Integer;
    procedure IRC_Part(Channel : String);
    procedure IRC_Join(Channel : String);
    procedure IRC_Disconnect();
    procedure IRC_Action(Target, Mssg : String);
    procedure IRC_Notice(Target, Mssg : String);
    procedure IRC_Message(Target, Mssg : String);
    procedure IRC_SendRaw(Data : String);
    procedure IRC_Connect();
    procedure IRC_Server(Address : String; Port : Integer);
    procedure IRC_SetNames(Name, AltNick : String);
    procedure OnIRCMessage(Sender: TObject; AUser: TIdIRCUser;
      AChannel: TIdIRCChannel; Content: String);
    procedure OnNickChange(Sender: TObject; AUser: TIdIRCUser;
      ANewNick: String);
    procedure OnIRCPartChannel(Sender: TObject; AUser: TIdIRCUser;
      AChannel: TIdIRCChannel);
    procedure OnIRCJoinChannel(Sender: TObject; AUser: TIdIRCUser;
      AChannel: TIdIRCChannel);
    procedure OnIRCQuit(Sender: TObject; AUser: TIdIRCUser);
    procedure IRCAction(Sender: TObject; AUser: TIdIRCUser;
      AChannel: TIdIRCChannel; Content: String);
    procedure OnIRCInvite(Sender: TObject; ANick, AChannel: String);
    function  IRCUserHost(Nickname : String): String;
    procedure Evaluate(Params : array of Variant; ProcName : String);
    function  DecryptThis(anEncryptedString : string) : string;
    function  EncryptThis(aString : string) : string;
    procedure IRCConnected(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;
  Player : Array [1..32] of TPlayer;
  Objects : Array [1..999] of TModels;
  Server : TServer;
  Clients : TThreadList;
  NumOfObjects : Integer;

const
  PACKET_HEADER = chr(0); // All packets start with this char or whatever
  VERSION_HASH = 'P52@YWA-LOL';
  PACKET_SEPARATOR = chr(1); // Separates parameters
  PACKET_SYNC = chr(2); // Sync packet
  PACKET_PING = chr(3); // Ping?
  PACKET_PONG = chr(4); // Pong!
  PACKET_CONN = chr(5); // "Mag ik overvaren?", oftewel: Mag ik joinen lieve server?
  PACKET_INFO = chr(7); // Client asks the server for the info (passworded etc.)
  PACKET_PLAYERS = chr(9); // Client asks the server for the player list that are connected
  PACKET_CHAT = chr(11); // Chat packet (so people can flame each other while playing this party-mod)
  PACKET_PLAYER_JOIN = chr(12); // There is a new player that just joined... so the server sends the info of this player to the client
  PACKET_GAME_CLOSED = chr(14); // Game closed
  PACKET_GAME_STARTED = chr(15); // Game started
  PACKET_PLAYER_PART = chr(16); // Some player disconnected
  PACKET_GOOD_BYE = chr(17); // The server disconnects us.
  PACKET_SPAWNED = chr(18); // We should let the server know we spawned... (client->server)
  PACKET_RICKROLLED = chr(19); // WE DIED! So let the server know we got Rick rolled! (client->server)
  PACKET_DISCONNECT = chr(20); // We are disconnecting... (client->server)
  PACKET_TIMEWEATHER = chr(22); // Time and Weather syncronisation
  PACKET_MAPDATA = chr(23); // Wut mut juh?!

  PACKET_PLAYERCHANGE = chr(13); // Property of player changed
  PACKET_PLAYERCHANGE_HEALTH = chr(2);
  PACKET_PLAYERCHANGE_ARMOR = chr(3);
  PACKET_PLAYERCHANGE_POS = chr(4);
  PACKET_PLAYERCHANGE_ROTATION = chr(5);
  PACKET_PLAYERCHANGE_SKIN = chr(6);
  PACKET_PLAYERCHANGE_INTERIOR = chr(7);

implementation

{$R *.dfm}

procedure TfrmMain.Log(Str : String);
begin
  memoLog.lines.add(Str);
end;

function TFrmMain.EncryptThis(aString : string) : string;
var
  Cipher: TDCP_cast256;
  KeyStr: string;
begin
  KeyStr:= 'sdfjI$s_#@`sd';
  Cipher:= TDCP_cast256.Create(Self);
  Cipher.InitStr(KeyStr,TDCP_sha1);
  result := Cipher.EncryptString(aString);
  Cipher.Burn;
  Cipher.Free;
end;

function TFrmMain.DecryptThis(anEncryptedString : string) : string;
var
  Cipher: TDCP_cast256;
  KeyStr: string;
begin
  KeyStr:= 'sdfjI$s_#@`sd';
  Cipher:= TDCP_cast256.Create(Self);
  Cipher.InitStr(KeyStr,TDCP_sha1);
  result := Cipher.DecryptString(anEncryptedString);
  Cipher.Burn;
  Cipher.Free;
end;

function TfrmMain.GetWeaponName(WeaponID : Integer): String;
begin
  If (WeaponID = 0) Then
    Result := 'Fist'
  Else If (WeaponID = 1) Then
    Result := 'Brass Knuckles'
  Else If (WeaponID = 2) Then
    Result := 'Golf Club'
  Else If (WeaponID = 3) Then
    Result := 'Nite Stick'
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
  Else If (WeaponID = 10) Then
    Result := 'Purple Dildo'
  Else If (WeaponID = 11) Then
    Result := 'Small White Vibrator'
  Else If (WeaponID = 12) Then
    Result := 'Large White Vibrator'
  Else If (WeaponID = 13) Then
    Result := 'Silver Vibrator'
  Else If (WeaponID = 14) Then
    Result := 'Flowers'
  Else If (WeaponID = 15) Then
    Result := 'Cane'
  Else If (WeaponID = 22) Then
    Result := '9mm Pistol'
  Else If (WeaponID = 23) Then
    Result := 'Silenced 9mm Pistol'
  Else If (WeaponID = 24) Then
    Result := 'Desert Eagle'
  Else If (WeaponID = 25) Then
    Result := 'Shotgun'
  Else If (WeaponID = 26) Then
    Result := 'Sawnoff Shotgun'
  Else If (WeaponID = 27) Then
    Result := 'Combat Shotgun'
  Else If (WeaponID = 28) Then
    Result := 'Micro SMG'
  Else If (WeaponID = 29) Then
    Result := 'SMG'
  Else If (WeaponID = 32) Then
    Result := 'Tec9'
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
    Result := 'Heat Seaking Rocket Launcher'
  Else If (WeaponID = 37) Then
    Result := 'Flame Thrower'
  Else If (WeaponID = 38) Then
    Result := 'Minigun'
  Else If (WeaponID = 39) Then
    Result := 'Satchel Charge'
  Else If (WeaponID = 40) Then
    Result := 'Detonator'
  Else If (WeaponID = 16) Then
    Result := 'Grenade'
  Else If (WeaponID = 17) Then
    Result := 'Tear Gas'
  Else If (WeaponID = 18) Then
    Result := 'Molotov Cocktail'
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
  Else If (WeaponID = 47) Then
    Result := 'Fake Pistol'
  Else If (WeaponID = 40) Then
    Result := 'Detonator'
  Else If (WeaponID = 41) Then
    Result := 'Spray Can'
  Else If (WeaponID = 44) Then
    Result := 'Nightvision Goggles'
  Else If (WeaponID = 45) Then
    Result := 'Infrared Vision'
  Else If (WeaponID = 46) Then
    Result := 'Parachute'
  Else If (WeaponID = 51) Then
    Result := 'Explosion'
  Else If (WeaponID = 49) Then
    Result := 'Vehicle'
  Else If (WeaponID = 53) Then
    Result := 'Drowned'
  Else If (WeaponID = 54) Then
    Result := 'Collision'
  Else
    Result := 'Unknown';
end;

function TfrmMain.GetPlayerName(PlayerID : Integer): String;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := ''
  Else
    result := Player[PlayerID].Name;
end;

procedure TfrmMain.SetPlayerSkin(PlayerID, SkinID : Integer);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  if (IsValidSkin(SkinID)) then
    SendDataToPlayer(PlayerID, PACKET_PLAYERCHANGE + PACKET_SEPARATOR + PACKET_PLAYERCHANGE_SKIN + PACKET_SEPARATOR + IntToStr(SkinID))
  else
    Exit;
end;

function TfrmMain.IsValidSkin(SkinID : Integer) : Boolean;
begin
  if (SkinID = 0) OR (SkinID = 7) OR
      (SkinID > 8) AND (SkinID < 42) OR
      (SkinID > 42) AND (SkinID < 65) OR
      (SkinID > 65) AND (SkinID < 74) OR
      (SkinID > 74) AND (SkinID < 86) OR
      (SkinID > 86) AND (SkinID < 208) AND
      not (SkinID = 149) AND not (SkinID = 119) OR
      (SkinID > 208) AND (SkinID < 264) OR
      (SkinID > 273) AND (SkinID < 289) then
    result := True
  else
    result := False;
end;

function TfrmMain.GetPlayerPing(PlayerID : Integer): Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0
  Else
    result := Player[PlayerID].Ping;
end;

procedure TfrmMain.SendMessageToPlayer(PlayerID : Integer; Buffer : String);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  frmMain.SendDataToPlayer(PlayerID, PACKET_CHAT+ PACKET_SEPARATOR +'0'+ PACKET_SEPARATOR +StringReplace(Buffer, PACKET_SEPARATOR, '.',[rfReplaceAll, rfIgnoreCase]));
end;

procedure TfrmMain.SendMessageToAllExceptPlayer(PlayerID : Integer; Buffer : String);
begin
   frmMain.SendDataToAllExceptPlayer(PlayerID, PACKET_CHAT+ PACKET_SEPARATOR +'0'+ PACKET_SEPARATOR +StringReplace(Buffer, PACKET_SEPARATOR, '.',[rfReplaceAll, rfIgnoreCase]));
end;

procedure TfrmMain.SendMessageToAll(Buffer : String);
begin
   frmMain.SendDataToAll(PACKET_CHAT+ PACKET_SEPARATOR +'0'+ PACKET_SEPARATOR +StringReplace(Buffer, PACKET_SEPARATOR, '.',[rfReplaceAll, rfIgnoreCase]));
end;

function TfrmMain.Distance(x1, y1, x2, y2: Integer): Integer;
begin
  Result:= Round(Sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)));
end;
  
function TfrmMain.iAbsVal(I: Integer): Integer;
begin
  Result:= Abs(I);
end;

function TfrmMain.Rndm(I: Integer): Integer;
begin
  Result:= Random(I);
end;

function TfrmMain.RndmRange(iFrom, iTo: Integer): Integer;
begin
  Result:= RandomRange(iFrom, iTo);
end;

function TfrmMain.iMaximum(N1, N2: Integer): Integer;
begin
  Result:= Max(N1, N2);
end;

function TfrmMain.iMinimum(N1, N2: Integer): Integer;
begin
  Result:= Min(N1, N2);
end;

function TfrmMain.Replace(Text, FindStr, ReplaceStr: string): string;
begin
  result := StringReplace(Text, FindStr, ReplaceStr, [rfReplaceAll]);
end;

function TfrmMain.GetNumbers(Text: string): string;
var
  I: Integer;
begin
  for I:= 1 to Length(Text) do
    if(Text[I] in ['0'..'9'])then
      Result:= Result + Text[I];
end;

function TfrmMain.GetLetters(Text: String): String;
var
  I: Integer;
begin
  for I:= 1 to Length(Text) do
    if(Text[I] in ['a'..'z'] + ['A'..'Z'])then
      Result:= Result + Text[I];
end;

function TfrmMain.GetOthers(Text: String): String;
var
  I: Integer;
begin
  for I:= 1 to Length(Text) do
    if(not(Text[I] in ['a'..'z'] + ['A'..'Z'] + ['0'..'9']))then
      Result:= Result + Text[I];
end;

function TfrmMain.TrimNumbers(Text: String): String;
var
  I: Integer;
begin
  for I:= 1 to Length(Text) do
    if(not(Text[I] in ['0'..'9']))then
      Result:= Result + Text[I];
end;

function TfrmMain.TrimLetters(Text: String): String;
var
  I: Integer;
begin
  for I:= 1 to Length(Text) do
    if(not(Text[I] in ['a'..'z'] + ['A'..'Z']))then
      Result:= Result + Text[I];
end;

function TfrmMain.TrimOthers(Text: String): String;
var
  I: Integer;
begin
  for I:= 1 to Length(Text) do
    if(Text[I] in ['a'..'z'] + ['A'..'Z'] + ['0'..'9'])then
      Result:= Result + Text[I];
end;

function TfrmMain.Capitalize(S: String): String;
var
  I: Integer;
  CapNext: Boolean;
begin
  CapNext:= True;
  for I:= 1 to Length(S) do
    if(CapNext)then
    begin
      if(S[I] in ['a'..'z'] + ['A'..'Z'] + ['0'..'9'])then
      begin
        S[I]:= UpCase(S[I]);
        CapNext:= False;
      end;
    end else if(S[I] = ' ')then CapNext:= True;
  Result:= S;
end;

function TfrmMain.IsInCube(px, py, x1, y1, x2, y2 : Integer): Boolean;
var
  xPass, yPass : Boolean;
begin
  xPass := False;
  yPass := False;
  result := False;

  if (px <= x1) then
    if (px >= x2) then
      xPass := True;

  if (px >= x1) then
    if (px <= x2) then
      xPass := True;

  if (py <= y1) then
    if (py >= y2) then
      yPass := True;

  if (py >= y1) then
    if (py <= y2) then
      yPass := True;

  if (xPass) then
    if (yPass) then
      result := True;
end;

procedure TfrmMain.SetWeather(WeatherID : Integer);
begin
  Server.Weather := WeatherID;
  SendTimeWeatherToPlayer(-1);
end;

procedure TfrmMain.SetTime(Hour, Minutes : Integer);
begin
  if (Hour < 24) AND (Hour >=0) AND (Minutes < 60) AND (Minutes >= 0) then
  begin
    Server.Hour := Hour;
    Server.Minute := Minutes;
    SendTimeWeatherToPlayer(-1);
  end;
end;

procedure TfrmMain.SetPlayerHealth(PlayerID : Integer; Health : Single);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;

  if (Player[PlayerID].Ingame) then
  begin
    Player[PlayerID].Health := Health;
    SendDataToPlayer(PlayerID, PACKET_PLAYERCHANGE + PACKET_SEPARATOR + PACKET_PLAYERCHANGE_HEALTH + PACKET_SEPARATOR + FloatToStr(Health));
  end;
end;

procedure TfrmMain.SetPlayerInterior(PlayerID, Interior : Integer);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;

  if (Player[PlayerID].Ingame) then
  begin
    Player[PlayerID].Interior := Interior;
    SendDataToPlayer(PlayerID, PACKET_PLAYERCHANGE + PACKET_SEPARATOR + PACKET_PLAYERCHANGE_INTERIOR + PACKET_SEPARATOR + IntToStr(Interior));
  end;
end;

procedure TfrmMain.KillPlayer(PlayerID : Integer);
begin
  SetPlayerHealth(PlayerID, 0.0);
end;

procedure TfrmMain.SetPlayerArmor(PlayerID : Integer; Armor : Single);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;

  if (Player[PlayerID].Ingame) then
  begin
    Player[PlayerID].Armor := Armor;
    SendDataToPlayer(PlayerID, PACKET_PLAYERCHANGE + PACKET_SEPARATOR + PACKET_PLAYERCHANGE_ARMOR + PACKET_SEPARATOR + FloatToStr(Armor));
  end;
end;

procedure TfrmMain.SetPlayerPosition(PlayerID : Integer; PosX, PosY, PosZ : Single);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;

  if (Player[PlayerID].Ingame) then
  begin
    Player[PlayerID].PosX := PosX;
    Player[PlayerID].PosY := PosY;
    Player[PlayerID].PosZ := PosZ;
    SendDataToPlayer(PlayerID, PACKET_PLAYERCHANGE + PACKET_SEPARATOR + PACKET_PLAYERCHANGE_POS + PACKET_SEPARATOR + FloatToStr(PosX) + PACKET_SEPARATOR + FloatToStr(PosY) + PACKET_SEPARATOR + FloatToStr(PosZ));
  end;
end;

procedure TfrmMain.SetPlayerRotation(PlayerID : Integer; Rotation : Single);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;

  if (Player[PlayerID].Ingame) then
  begin
    Player[PlayerID].Rotation := Rotation;
    SendDataToPlayer(PlayerID, PACKET_PLAYERCHANGE + PACKET_SEPARATOR + PACKET_PLAYERCHANGE_ROTATION + PACKET_SEPARATOR + FloatToStr(Rotation));
  end;
end;

function TfrmMain.GetPlayerPosX(PlayerID : integer): Single;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0.0
  else
    result := Player[PlayerID].PosX;
end;

function TfrmMain.GetPlayerPosY(PlayerID : integer): Single;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0.0
  else
    result := Player[PlayerID].PosY;
end;

function TfrmMain.GetPlayerPosZ(PlayerID : integer): Single;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0.0
  else
    result := Player[PlayerID].PosZ;
end;

function TfrmMain.GetPlayerRotation(PlayerID : integer): Single;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0.0
  else
    result := Player[PlayerID].Rotation;
end;

function TfrmMain.GetPlayerHealth(PlayerID : integer): Single;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0.0
  else
    result := Player[PlayerID].Health;
end;

function TfrmMain.GetPlayerArmor(PlayerID : integer): Single;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0.0
  else
    result := Player[PlayerID].Armor;
end;

function TfrmMain.GetPlayerSkin(PlayerID : integer): Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0
  else
    result := Player[PlayerID].Skin;
end;

function TfrmMain.GetWeather(): Integer;
begin
  result := Server.Weather;
end;

function TfrmMain.GetTime(): String;
begin
  //result := IntToStr(Server.Hour)+':'+IntToStr(Server.Minute);
  result := Format('%.2d:%.2d', [Server.Hour, Server.Minute]);
end;

function TfrmMain.GetPlayerInterior(PlayerID : Integer): Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0
  else
    result := Player[PlayerID].Interior;
end;

procedure TfrmMain.IRC_SetNames(Name, AltNick : String);
begin
  IRC.Nick := Name;
  IRC.AltNick := AltNick;
end;

procedure TfrmMain.IRC_Server(Address : String; Port : Integer);
begin
  IRC.Host := Address;
  IRC.Port := Port;
end;

procedure TfrmMain.IRC_Connect();
begin
  IRC.Connect();
end;

procedure TfrmMain.IRC_SendRaw(Data : String);
begin
  IRC.Raw(Data);
end;

procedure TfrmMain.IRC_Message(Target, Mssg : String);
begin
  IRC.Say(Target, Mssg);
end;

procedure TfrmMain.IRC_Notice(Target, Mssg : String);
begin
  IRC.Notice(Target, Mssg);
end;

procedure TfrmMain.IRC_Action(Target, Mssg : String);
begin
  IRC.Action(Target, Mssg);
end;

procedure TfrmMain.IRC_Disconnect();
begin
  IRC.Quit('SAP/'+Server.Version+' | http://www.sa-party.com');
  IRC.Disconnect(True);
end;

procedure TfrmMain.IRC_Join(Channel : String);
begin
  IRC.Raw('JOIN '+Channel);
end;

procedure TfrmMain.IRC_Part(Channel : String);
begin
  IRC.Raw('PART '+Channel);
end;

function TfrmMain.IRCUserHost(Nickname : String): String;
begin
  try
    result := IRC.Users.Get(Nickname).Address;
  except
    result := '';
  end;
end;

procedure TfrmMain.Evaluate(Params : array of Variant; ProcName : String);
begin
  Try
    PScript.ExecuteFunction(Params, ProcName);
  Except
    Exit;
  end;
end;

procedure TfrmMain.CreateObject(ModelID : Integer;PosX, PosY, PosZ, RotX, RotY, RotZ : Single);
var
  i : Integer;
begin
  For i := 1 To (NumOfObjects+1) Do
  Begin
    If (Objects[i].Active = False) Then
    Begin
      Objects[i].ModelID := ModelID;
      Objects[i].PosX := PosX;
      Objects[i].PosY := PosY;
      Objects[i].PosZ := PosZ;
      Objects[i].RotX := RotX;
      Objects[i].RotY := RotY;
      Objects[i].RotZ := RotZ;
      Objects[i].Active := True;
      SendDataToAll(PACKET_MAPDATA + PACKET_SEPARATOR + '1' + PACKET_SEPARATOR + IntToStr(i) + PACKET_SEPARATOR + IntToStr(Objects[i].ModelID) + PACKET_SEPARATOR + FormatFloat('0.000',Objects[i].PosX) + PACKET_SEPARATOR + FormatFloat('0.000',Objects[i].PosY) + PACKET_SEPARATOR + FormatFloat('0.000',Objects[i].PosZ) + PACKET_SEPARATOR + FormatFloat('0.000',Objects[i].RotX) + PACKET_SEPARATOR + FormatFloat('0.000',Objects[i].RotY) + PACKET_SEPARATOR + FormatFloat('0.000',Objects[i].RotZ));
//      Log('Object created');
      Break;
    End;
  End;
  Inc(NumOfObjects);
end;

procedure TfrmMain.OnScriptCompile(Sender: TPSScript);
begin
  // IRC
  PScript.AddMethod(Self, @TfrmMain.IRCUserHost,                    'function IRCUserHost(Nickname : String): String;');
  PScript.AddMethod(Self, @TfrmMain.IRC_Part,                       'procedure IRCPart(Channel : String);');
  PScript.AddMethod(Self, @TfrmMain.IRC_Join,                       'procedure IRCJoin(Channel : String);');
  PScript.AddMethod(Self, @TfrmMain.IRC_Disconnect,                 'procedure IRCDisconnect();');
  PScript.AddMethod(Self, @TfrmMain.IRC_Action,                     'procedure IRCAction(Target, Mssg : String);');
  PScript.AddMethod(Self, @TfrmMain.IRC_Notice,                     'procedure IRCNotice(Target, Mssg : String);');
  PScript.AddMethod(Self, @TfrmMain.IRC_Message,                    'procedure IRCMessage(Target, Mssg : String);');
  PScript.AddMethod(Self, @TfrmMain.IRC_SendRaw,                    'procedure IRCSendRaw(Data : String);');
  PScript.AddMethod(Self, @TfrmMain.IRC_Connect,                    'procedure IRCConnect();');
  PScript.AddMethod(Self, @TfrmMain.IRC_Server,                     'procedure IRCServer(Address : String; Port : Integer);');
  PScript.AddMethod(Self, @TfrmMain.IRC_SetNames,                   'procedure IRCSetNames(Name, AltNick : String);');

  // Procedures
  PScript.AddMethod(Self, @TfrmMain.Log,                            'procedure Log(Str : String);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerSkin,                  'procedure SetPlayerSkin(PlayerID, SkinID : Integer);');
  PScript.AddMethod(Self, @TfrmMain.SendMessageToPlayer,            'procedure SendMessageToPlayer(PlayerID : Integer; Mssg : String);');
  PScript.AddMethod(Self, @TfrmMain.SendMessageToAll,               'procedure SendMessageToAll(Mssg : String);');
  PScript.AddMethod(Self, @TfrmMain.SendMessageToAllExceptPlayer,   'procedure SendMessageToAllExceptPlayer(PlayerID : Integer; Mssg : String);');
  PScript.AddMethod(Self, @TfrmMain.SetWeather,                     'procedure SetWeather(WeatherID : Integer);');
  PScript.AddMethod(Self, @TfrmMain.SetTime,                        'procedure SetTime(Hour, Minutes : Integer);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerHealth,                'procedure SetPlayerHealth(PlayerID : Integer; Health : Single);');
  PScript.AddMethod(Self, @TfrmMain.KillPlayer,                     'procedure KillPlayer(PlayerID : Integer);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerArmor,                 'procedure SetPlayerArmor(PlayerID : Integer; Armor : Single);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerArmor,                 'procedure SetPlayerArmour(PlayerID : Integer; Armor : Single);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerPosition,              'procedure SetPlayerPosition(PlayerID : Integer; PosX, PosY, PosZ : Single);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerRotation,              'procedure SetPlayerRotation(PlayerID : Integer; Rotation : Single);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerInterior,              'procedure SetPlayerInterior(PlayerID, Interior : Integer);');
  PScript.AddMethod(Self, @TfrmMain.CreateObject,                   'procedure CreateObject(ModelID : Integer;PosX, PosY, PosZ, RotX, RotY, RotZ : Single);');
  PScript.AddMethod(Self, @TfrmMain.Evaluate,                       'procedure Eval(Params : array of Variant; ProcName : String);');

  // Functions
  PScript.AddMethod(Self, @TfrmMain.GetWeaponName,                  'function GetWeaponName(WeaponID : Integer): String;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerName,                  'function GetPlayerName(PlayerID: Integer): String;');
  PScript.AddMethod(Self, @TfrmMain.calcMD5,                        'function MD5(Input : String): String;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerPing,                  'function GetPlayerPing(PlayerID : Integer): Integer;');
  PScript.AddMethod(Self, @TfrmMain.IsValidSkin,                    'function IsValidSkin(SkinID : Integer): Boolean;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerPosX,                  'function GetPlayerPosX(PlayerID : Integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerPosY,                  'function GetPlayerPosY(PlayerID : Integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerPosZ,                  'function GetPlayerPosZ(PlayerID : Integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerRotation,              'function GetPlayerRotation(PlayerID : Integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerInterior,              'function GetPlayerInterior(PlayerID : Integer): Integer;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerHealth,                'function GetPlayerHealth(PlayerID : integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerArmor,                 'function GetPlayerArmor(PlayerID : integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerArmor,                 'function GetPlayerArmour(PlayerID : integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerSkin,                  'function GetPlayerSkin(PlayerID : integer): Integer;');
  PScript.AddMethod(Self, @TfrmMain.GetWeather,                     'function GetWeather(): Integer;');
  PScript.AddMethod(Self, @TfrmMain.GetTime,                        'function GetTime(): String;');

  // Math functions
  PScript.AddMethod(Self, @TfrmMain.IsInteger,                      'function IsInteger(Str: String): Boolean;');
  PScript.AddMethod(Self, @TfrmMain.IsFloat,                        'function IsFloat(Str: String): Boolean;');
  PScript.AddMethod(Self, @TfrmMain.Rndm,                           'function Random(I: Integer): Integer;');
  PScript.AddMethod(Self, @TfrmMain.RndmRange,                      'function RandomRange(iFrom, iTo: Integer): Integer;');
  PScript.AddMethod(Self, @TfrmMain.iMaximum,                       'function Max(N1, N2: Integer): Integer;');
  PScript.AddMethod(Self, @TfrmMain.iMinimum,                       'function Min(N1, N2: Integer): Integer;');
  PScript.AddMethod(Self, @TfrmMain.iAbsVal,                        'function iAbs(I: Integer): Integer;');
  PScript.AddMethod(Self, @TfrmMain.Distance,                       'function Distance(x1, y1, x2, y2: Integer): Integer;');
  PScript.AddMethod(Self, @TfrmMain.IsInCube,                       'function IsInCube(px, py, x1, y1, x2, y2: Integer): Boolean;');

  // String functions
  PScript.AddMethod(Self, @TfrmMain.Replace,                        'function Replace(Text, FindStr, ReplaceStr: string): string;');
  PScript.AddMethod(Self, @TfrmMain.GetNumbers,                     'function GetNumbers(Text: string): string;');
  PScript.AddMethod(Self, @TfrmMain.GetLetters,                     'function GetLetters(Text: String): String;');
  PScript.AddMethod(Self, @TfrmMain.TrimNumbers,                    'function TrimNumbers(Text: String): String;');
  PScript.AddMethod(Self, @TfrmMain.TrimLetters,                    'function TrimLetters(Text: String): String;');
  PScript.AddMethod(Self, @TfrmMain.GetOthers,                      'function GetOthers(Text: String): String;');
  PScript.AddMethod(Self, @TfrmMain.TrimOthers,                     'function TrimOthers(Text: String): String;');
  PScript.AddMethod(Self, @TfrmMain.StrToFloatFix,                  'function StrToFloat(Str: String): Single;');
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

function TfrmMain.Split(const Source, Delimiter: String): TSplitArray;
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

function TfrmMain.calcMD5(Buffer : String): String;
begin
  Result := LowerCase(GetMD5(@Buffer[1], Length(Buffer)));
end;

procedure TfrmMain.SendDataToAll(Buffer : String);
var
  i, i2 : integer;
  RecClient : PClient;
  RecThread : TIdPeerThread;
begin
  For i := 1 To High(Player) Do
  Begin
    If (Player[i].Connected = False) Then
      Continue;
    With Clients.LockList Do
    Begin
      Try
        For i2 := 0 To Pred(Count) Do
        Begin
          RecClient := Items[i2];
          RecThread := RecClient.Thread;
          //memoLog.Lines.Add('Plr Handle: '+ IntToStr(Player[i].Handle) +' - Thread handle: '+ IntToStr(RecThread.Handle));
          If (RecThread.Handle = Player[i].Handle) Then
            RecThread.Connection.WriteLn(Buffer);
        End;
      Finally
          Clients.UnlockList;
      End;
    End;
  End;
end;

procedure TfrmMain.SendDataToAllExceptPlayer(PlayerID : integer; Buffer : String);
var
  i, i2 : integer;
  RecClient : PClient;
  RecThread : TIdPeerThread;
begin
  For i := 1 To High(Player) Do
  Begin
    If (i = PlayerID) Then
      Continue;
    With Clients.LockList Do
    Begin
      Try
        For i2 := 0 To Pred(Count) Do
        Begin
          RecClient := Items[i2];
          RecThread := RecClient.Thread;
          If (RecThread.Handle = Player[i].Handle) Then
            RecThread.Connection.WriteLn(Buffer);
        End;
      Finally
          Clients.UnlockList;
      End;
    End;
  End;
end;

procedure TfrmMain.SendDataToPlayer(PlayerID : Integer; Buffer : String);
var
  i, i2 : integer;
  RecClient : PClient;
  RecThread : TIdPeerThread;
begin
  For i := 1 To High(Player) Do
  Begin
    If not (i = PlayerID) or (Player[i].Connected = False) Then
      Continue;
    With Clients.LockList Do
    Begin
      Try
        For i2 := 0 To Pred(Count) Do
        Begin
          RecClient := Items[i2];
          RecThread := RecClient.Thread;
          If (RecThread.Handle = Player[i].Handle) Then
            RecThread.Connection.WriteLn(Buffer);
        End;
      Finally
          Clients.UnlockList;
      End;
    End;
  End;
end;

procedure ClearPlayerSlot(PlayerID : Integer);
begin
  Player[PlayerID].GotSoftDisconnect := True;
  Player[PlayerID].Connected := False;
  Player[PlayerID].Ingame := False;
  Player[PlayerID].Name := '';
  Player[PlayerID].IP := '0.0.0.0';
  Player[PlayerID].Port := 0;
  Player[PlayerID].Handle := 0;
  Player[PlayerID].Ping := 0;
  Player[PlayerID].PingChecks := 0;
  Player[PlayerID].Alive := False;
  Player[PlayerID].Skin := 0;
  Player[PlayerID].Rotation := 0.0;
  Player[PlayerID].PosX := 0.0;
  Player[PlayerID].PosY := 0.0;
  Player[PlayerID].PosZ := 0.0;
  Player[PlayerID].Health := 0.0;
  Player[PlayerID].Crouched := False;
  Player[PlayerID].Armor := 0.0;
  Player[PlayerID].Interior := 0;
end;

procedure TfrmMain.Err(Str : String);
begin
  MessageDlg(Str,mtError,[mbOk],0);
end;

function TfrmMain.IsInteger(Str: String): Boolean;
begin
  try
    Result := True;
    StrToInt(Str);
  except on E: EConvertError do
    Result := False;
  end;
end;

function TfrmMain.IsFloat(Str: String): Boolean;
var
  Temp : String;
begin
  try
    Temp := StringReplace(Str, ',',DecimalSeparator,[rfReplaceAll, rfIgnoreCase]);
    Temp := StringReplace(Str, '.',DecimalSeparator,[rfReplaceAll, rfIgnoreCase]);
    Result := True;
    StrToFloat(Temp);
  except on E: EConvertError do
    Result := False;
  end;
end;

function TfrmMain.StrToFloatFix(Str: String): Single;
var
  Temp : String;
begin
  try
    Temp := StringReplace(Str, ',',DecimalSeparator,[rfReplaceAll, rfIgnoreCase]);
    Temp := StringReplace(Str, '.',DecimalSeparator,[rfReplaceAll, rfIgnoreCase]);
    Result := StrToFloat(Temp);
  except on E: EConvertError do
    Result := 0.0;
  end;
end;

procedure TfrmMain.OnFormClose(Sender: TObject; var Action: TCloseAction);
begin
  Try
    if (IRC.Connected) then
    begin
      IRC.Raw('QUIT :SAP/'+Server.Version+' | http://www.sa-party.com');
      IRC.Disconnect();
    end;
    tmrPingCheck.Enabled := false;
    SendDataToAll(PACKET_GOOD_BYE+ PACKET_SEPARATOR +'4');

  Except
    Application.Terminate;
  End;
end;

procedure TfrmMain.udpServerDisconnect(AThread: TIdPeerThread);
var
  ActClient: PClient;
  i : Integer;
begin
  For i := 1 To High(Player) Do
  Begin
    If (Player[i].Handle = AThread.Handle) Then
    begin
      If (Player[i].Connected = True) and (Player[i].GotSoftDisconnect = False) Then
      Begin
        If (Player[i].Ingame) Then
          SendDataToAllExceptPlayer(i, 'GAMECLOSED'+ PACKET_SEPARATOR +IntToStr(i));
        Server.PlayersConnected := Server.PlayersConnected-1;
        SendDataToAllExceptPlayer(i, 'DISCONNECTED'+ PACKET_SEPARATOR +IntToStr(i)+ PACKET_SEPARATOR +'1');
        PScript.ExecuteFunction([i,1],'OnPlayerPart');
      End;
      ClearPlayerSlot(i);
      Break;
    end;
  End;
  ActClient := PClient(AThread.Data);
  Try
    Clients.LockList.Remove(ActClient);
  Finally
    Clients.UnlockList;
  End;

  FreeMem(ActClient);
  AThread.Data := Nil;
end;

procedure TfrmMain.udpServerExecute(AThread: TIdPeerThread);
var
  RawString, Str : String;
  Found : Boolean;
  i, i2, PlayerID : Integer;
  Arr : TSplitArray;
begin
  If (udpServer.Active = false) then
    Exit;
  Arr := Split('a'+ PACKET_SEPARATOR +'a',PACKET_SEPARATOR);
  Try
  If (udpServer.Active = false) then
    Exit;
    RawString := AThread.Connection.ReadLn('');
    If (udpServer.Active = false) then
    Exit;
    Arr := Split(RawString, PACKET_SEPARATOR);
  Except
    Arr := Split('a'+ PACKET_SEPARATOR +'a', PACKET_SEPARATOR);
    Arr[0] := RawString;
  End;
  If (Arr[0] = PACKET_SYNC) Then
  Begin
     PlayerID := StrToInt(Arr[1]);
     if not (Player[PlayerID].Connected = True) OR not (Player[PlayerID].Port = AThread.Connection.Socket.Binding.PeerPort) OR not (Player[PlayerID].IP = AThread.Connection.Socket.Binding.PeerIP) then
        Exit;
     SendDataToAllExceptPlayer(PlayerID, RawString);

     if not (StrToInt(Arr[2]) = -1) then
     begin
       Player[PlayerID].Alive := True;
       Player[PlayerID].PosX := StrToFloatFix(Arr[3]);
       Player[PlayerID].PosY := StrToFloatFix(Arr[4]);
       Player[PlayerID].PosZ := StrToFloatFix(Arr[5]);
       Player[PlayerID].Rotation := StrToFloatFix(Arr[6]);
       Player[PlayerID].Health := StrToFloatFix(Arr[7]);
       // Arr[8] runningstate
       if (Arr[9] = '1') then
        Player[PlayerID].Crouched := True
       else
        Player[PlayerID].Crouched := False;
       // Arr[10] Iets met crouching
       // Arr[11] Iets met crouching
       Player[PlayerID].Armor := StrToFloatFix(Arr[12]);
       Player[PlayerID].Interior := StrToInt(Arr[13]);
     end
     else
     begin
       Player[PlayerID].Alive := False;
       Player[PlayerID].PosX := 0.0;
       Player[PlayerID].PosY := 0.0;
       Player[PlayerID].PosZ := 0.0;
       Player[PlayerID].Rotation := 0.0;
       Player[PlayerID].Health := 0.0;
       Player[PlayerID].Armor := 0.0;
       Player[PlayerID].Crouched := False;
     end;
  End
  Else If (Arr[0] = PACKET_PONG) then
  Begin
    PlayerID := StrToInt(Arr[1]);
    if not (Player[PlayerID].Connected = True) OR not (Player[PlayerID].Port = AThread.Connection.Socket.Binding.PeerPort) OR not (Player[PlayerID].IP = AThread.Connection.Socket.Binding.PeerIP) then
      Exit;
    Player[PlayerID].PingChecks := 0;
    Player[PlayerID].Ping := GetTickCount()-Server.LastPingCheck;
  End
  Else If (Arr[0] = PACKET_MAPDATA) Then
  Begin
    If (NumOfObjects = 0) Then
      Exit;
    For i := 1 To NumOfObjects Do
    Begin
      If (Objects[i].Active = True) Then
      Begin
        AThread.Connection.WriteLn(PACKET_MAPDATA + PACKET_SEPARATOR + '1' + PACKET_SEPARATOR + IntToStr(i) + PACKET_SEPARATOR + IntToStr(Objects[i].ModelID) + PACKET_SEPARATOR + FormatFloat('0.000',Objects[i].PosX) + PACKET_SEPARATOR + FormatFloat('0.000',Objects[i].PosY) + PACKET_SEPARATOR + FormatFloat('0.000',Objects[i].PosZ) + PACKET_SEPARATOR + FormatFloat('0.000',Objects[i].RotX) + PACKET_SEPARATOR + FormatFloat('0.000',Objects[i].RotY) + PACKET_SEPARATOR + FormatFloat('0.000',Objects[i].RotZ));
      End;
    End;
  End
  Else If (Arr[0] = PACKET_INFO) Then
  Begin
    Str :=  StringReplace(Server.Name, PACKET_SEPARATOR, '.',[rfReplaceAll, rfIgnoreCase]);
    Str :=  StringReplace(Str, '~', '.',[rfReplaceAll, rfIgnoreCase]);
    If (Length(Server.Password) > 0) Then
      i := 1
    Else
      i := 0;
    Str := PACKET_INFO + PACKET_SEPARATOR +Str+ PACKET_SEPARATOR +IntToStr(Server.PlayersConnected)+ PACKET_SEPARATOR +IntToStr(Server.MaxPlayers)+ PACKET_SEPARATOR +IntToStr(i)+ PACKET_SEPARATOR +'~';
    AThread.Connection.WriteLn(Str);
  End
  Else If (Arr[0] = PACKET_PLAYERS) Then
  Begin
    Str := PACKET_PLAYERS;
    For i := 0 To High(Player) Do
    Begin
      If (Player[i].Connected = True) Then
          Str := Str + PACKET_SEPARATOR + IntToStr(i)+' '+Player[i].Name;
    End;
    Str := StringReplace(Str, '~', '.',[rfReplaceAll, rfIgnoreCase]);
    Str := Str + PACKET_SEPARATOR +'~';
    AThread.Connection.WriteLn(Str);
  End
  Else If (Arr[0] = PACKET_CONN) then
  begin
    if (Arr[1] = Server.VersionHash) then
    begin
      if not (Server.MaxPlayers = Server.PlayersConnected) then
      begin
          if (Server.Password = '') OR (calcMD5(Server.Password) = Arr[3]) then
          begin
            Found := False;
            For i := 1 to High(Player) do
            begin
              if (Arr[2] = Player[i].Name) then
              begin
                Found := True;
                Str := PACKET_CONN + PACKET_SEPARATOR +'4'+ PACKET_SEPARATOR +'0';
                Break;
              end;
            end;
            if (Found = False) then
            begin
              For i := 1 to High(Player) do
              begin
                if (Player[i].Connected = False) then
                begin
                  ClearPlayerSlot(i);
                  Player[i].Connected := True;
                  Player[i].GotSoftDisconnect := False;
                  Player[i].Name := Arr[2];
                  Player[i].IP := AThread.Connection.Socket.Binding.PeerIP;
                  Player[i].Port := AThread.Connection.Socket.Binding.PeerPort;
                  Player[i].Handle := AThread.Handle;
                  PScript.ExecuteFunction([i],'OnPlayerJoin');
                  Server.PlayersConnected := Server.PlayersConnected+1;
                  Str := PACKET_PLAYER_JOIN + PACKET_SEPARATOR +IntToStr(i)+ PACKET_SEPARATOR +Arr[2];
                  SendDataToAllExceptPlayer(i, Str);
                  Str := PACKET_CONN + PACKET_SEPARATOR +'0'+ PACKET_SEPARATOR +IntToStr(i);
                  Break;
                end;
              end;
            end;
          end
          else
          begin
            Str := PACKET_CONN + PACKET_SEPARATOR +'3'+ PACKET_SEPARATOR +'0';
          end;
        end
        else
        begin
          Str := PACKET_CONN+ PACKET_SEPARATOR +'2'+ PACKET_SEPARATOR +'0';
        end;
      end
      Else
      begin
        Str := PACKET_CONN+ PACKET_SEPARATOR +'1'+ PACKET_SEPARATOR +'0';
      end;
      AThread.Connection.WriteLn(Str);
    end
    Else if (Arr[0] = PACKET_CHAT) then
    begin
      PlayerID := StrToInt(Arr[1]);
      if not (Player[PlayerID].Connected = True) OR not (Player[PlayerID].Port = AThread.Connection.Socket.Binding.PeerPort) OR not (Player[PlayerID].IP = AThread.Connection.Socket.Binding.PeerIP) then
        Exit;

      i := PScript.ExecuteFunction([PlayerID,Arr[2]],'OnPlayerText');
      if not (i = 0) then
        SendDataToAll(RawString);
    end
    Else if (Arr[0] = PACKET_DISCONNECT) then
    begin
      PlayerID := StrToInt(Arr[1]);
      if not (Player[PlayerID].Connected = True) OR not (Player[PlayerID].Port = AThread.Connection.Socket.Binding.PeerPort) OR not (Player[PlayerID].IP = AThread.Connection.Socket.Binding.PeerIP) then
        Exit;
      PScript.ExecuteFunction([PlayerID,0],'OnPlayerPart');
      if (Player[PlayerID].Ingame) then
        SendDataToAllExceptPlayer(PlayerID, PACKET_GAME_CLOSED+ PACKET_SEPARATOR +IntToStr(PlayerID));
      SendDataToAllExceptPlayer(PlayerID,PACKET_SYNC + PACKET_SEPARATOR + IntToStr(PlayerID) + PACKET_SEPARATOR +'-1');
      SendDataToPlayer(PlayerID, PACKET_GOOD_BYE+ PACKET_SEPARATOR +'0');
      Server.PlayersConnected := Server.PlayersConnected-1;
      ClearPlayerSlot(PlayerID);
      SendDataToAllExceptPlayer(PlayerID,PACKET_PLAYER_PART+ PACKET_SEPARATOR +IntToStr(PlayerID) + PACKET_SEPARATOR +'0');
    end
    Else if (Arr[0] = PACKET_SPAWNED) then
    begin
      PlayerID := StrToInt(Arr[1]);
      if not (Player[PlayerID].Connected = True) OR not (Player[PlayerID].Port = AThread.Connection.Socket.Binding.PeerPort) OR not (Player[PlayerID].IP = AThread.Connection.Socket.Binding.PeerIP) then
        Exit;
      SendTimeWeatherToPlayer(PlayerID);
      PScript.ExecuteFunction([PlayerID],'OnPlayerSpawned');
    end
    Else if (Arr[0] = PACKET_GAME_STARTED) then
    begin
      PlayerID := StrToInt(Arr[1]);
      if not (Player[PlayerID].Connected = True) OR not (Player[PlayerID].Port = AThread.Connection.Socket.Binding.PeerPort) OR not (Player[PlayerID].IP = AThread.Connection.Socket.Binding.PeerIP) then
        Exit;
      Player[PlayerID].Ingame := True;
      PScript.ExecuteFunction([PlayerID],'OnPlayerStartedGame');
    end
    Else if (Arr[0] = PACKET_GAME_CLOSED) then
    begin
      PlayerID := StrToInt(Arr[1]);
      if not (Player[PlayerID].Connected = True) OR not (Player[PlayerID].Port = AThread.Connection.Socket.Binding.PeerPort) OR not (Player[PlayerID].IP = AThread.Connection.Socket.Binding.PeerIP) then
        Exit;
      Player[PlayerID].Ingame := False;
      SendDataToAllExceptPlayer(PlayerID,PACKET_SYNC+ PACKET_SEPARATOR + IntToStr(PlayerID) + PACKET_SEPARATOR +'-1');
      SendDataToAllExceptPlayer(PlayerID, PACKET_GAME_CLOSED+ PACKET_SEPARATOR +IntToStr(PlayerID));
      PScript.ExecuteFunction([PlayerID],'OnPlayerClosedGame');
    end
    Else If (Arr[0] = PACKET_RICKROLLED) Then
    Begin
      PlayerID := StrToInt(Arr[1]); // Who died?
      i := StrToInt(Arr[2]); // The killer
      i2 := StrToInt(Arr[3]); // The weapon
      PScript.ExecuteFunction([PlayerID,i,i2],'OnPlayerDeath'); // Killer (ID), Player (ID), Reason (ID)
    End
    Else
    Begin
       Log('Unknown packet received (Raw string: '+ RawString +').');
    end;
end;

procedure TfrmMain.OnFormCreate(Sender: TObject);
var
  i : integer;
  INI : TINIFile;
begin
  Server.HardcodedMaxPlayers := 33; // Normaal 33
  Server.VersionHash := VERSION_HASH;
  Server.Version := '0.5.0.0';
  Server.StartCount := GetTickCount();
  Server.Hour := 12;
  Server.Minute := 0;
  frmMain.Caption := 'San Andreas Party Server '+Server.Version;

  INI := TINIFile.Create(GetCurrentDir + '\settings.ini');
  Server.Name := INI.ReadString('SERVER','servername','Unnamed SAP server');
  If (Length(Server.Name) > 80) Then
  Begin
    Log('Server name is too long, limit is 80 characters.');
    Exit;
  End
  Else  If (Length(Server.Name) < 3) Then
  begin
    Log('Server name is too short, mininum is 3 characters.');
    Exit;
  end;
  Server.Password := INI.ReadString('SERVER','password','');

  Server.MaxPlayers := INI.ReadInteger('SERVER','slots',Server.HardcodedMaxPlayers-1);
  If (Server.MaxPlayers > Server.HardcodedMaxPlayers) or (Server.MaxPlayers < 2) Then
  Begin
    Log('Minimum 2 slots - Maximum '+IntToStr(Server.HardcodedMaxPlayers-1)+' slot(s)');
    Exit;
  End;
  udpServer.DefaultPort := INI.ReadInteger('SERVER','port',8070);

  For i := 1 to High(Player) do
    Player[i].Connected := False;


  Server.Script := INI.ReadString('SERVER','gamemode','main.sap');
  If not (FileExists(ExtractFilePath(Application.ExeName) +'scripts\'+ Server.Script)) Then
  Begin
    Log('Script ''scripts\'+ Server.Script +''' not found!');
    Exit;
  End;
  PScript.Script.LoadFromFile(ExtractFilePath(Application.ExeName) +'scripts\'+ Server.Script);
  If Not (PScript.Compile) Then
  Begin
    Log('* Error: Unable to compile the script:');
    For i := 0 To Pred(PScript.CompilerMessageCount) Do
    Begin
      Log(PScript.CompilerMessages[i].MessageToString);
    End;
    Exit;
  End
  Else
  Begin
    If Not (PScript.Execute) Then
    Begin
      Log('* Error: Unable to execute the script: '+ PScript.ExecErrorToString);
      Exit;
    End;
  End;
  Try
    udpServer.Active := True;
  Except
    Log('* Error: Port '+IntToStr(udpServer.DefaultPort)+' (TCP) already in use.');
    Exit;
  End;
  Log('*** San Andreas Party '+ Server.Version +' server started');
  udpServer.Active := True;
  Log('*** Listening on port '+ IntToStr(udpServer.DefaultPort) +' (TCP)');
  tmrPingCheck.Enabled := True;

  Clients := TThreadList.Create;

  IRC.Replies.Finger := 'SAP/'+Server.Version+' | http://www.sa-party.com';
  IRC.Replies.Version := 'SAP/'+Server.Version+' | http://www.sa-party.com';
  IRC.Replies.ClientInfo := 'SAP/'+Server.Version+' | http://www.sa-party.com';

  Log('Hello world, who are you?: '+EncryptThis('Hello world, who are you?')+' | '+DecryptThis(EncryptThis('Hello world, who are you?')));

  PScript.ExecuteFunction([],'OnServerStart');
end;

procedure TfrmMain.OnPingCheck(Sender: TObject);
var
  i : Integer;
  PingList : String;
begin
  PingList := PACKET_PING;
  For i := 1 To High(Player) Do
  Begin
    If (Player[i].Connected = True) then
    begin
      Player[i].PingChecks := Player[i].PingChecks + 1;
      If (Player[i].PingChecks > 6) Then // Time out
      Begin
        If (Player[i].Ingame) then
          SendDataToAllExceptPlayer(i, PACKET_GAME_CLOSED+ PACKET_SEPARATOR +IntToStr(i));
        Server.PlayersConnected := Server.PlayersConnected-1;
        SendDataToAllExceptPlayer(i, PACKET_PLAYER_PART + PACKET_SEPARATOR + IntToStr(i)+ PACKET_SEPARATOR +'1');
        PScript.ExecuteFunction([i,1],'OnPlayerPart');
        ClearPlayerSlot(i);
      End
      Else
      begin
        PingList := PingList + PACKET_SEPARATOR + IntToStr(i) + PACKET_SEPARATOR + IntToStr(Player[i].Ping);
      end;
    end;
  End;
  Server.LastPingCheck := GetTickCount();
  SendDataToAll(PingList);
end;

procedure TfrmMain.udpServerConnect(AThread: TIdPeerThread);
var
  NewClient : PClient;
begin
  GetMem(NewClient, SizeOf(TClient));
  NewClient.Thread := AThread;
  NewClient.IP := AThread.Connection.Socket.Binding.PeerIP;
  NewClient.Port := AThread.Connection.Socket.Binding.PeerPort;
  AThread.Data := TObject(NewClient);
  Try
    Clients.LockList.Add(NewClient);
  Finally
    Clients.UnlockList;
  End;
end;

procedure TfrmMain.SendTimeWeatherToPlayer(PlayerID : Integer);
var
  Mssg : String;
begin
  Mssg := PACKET_TIMEWEATHER + PACKET_SEPARATOR + IntToStr(Server.Hour) + PACKET_SEPARATOR + IntToStr(Server.Minute) + PACKET_SEPARATOR + IntToStr(Server.Weather);
  if not (PlayerID = -1) then
    SendDataToPlayer(PlayerID, Mssg)
  else
    SendDataToAll(Mssg);
end;

procedure TfrmMain.OnSecondTimer(Sender: TObject);
begin
  Server.Minute := Server.Minute+1;
  if (Server.Minute = 60) then
  begin
    Server.Minute := 0;
    Server.Hour := Server.Hour+1;
    if (Server.Hour = 24) then
      Server.Hour := 0;
    SendTimeWeatherToPlayer(-1);
  end;
end;

procedure TfrmMain.OnIRCMessage(Sender: TObject; AUser: TIdIRCUser;
  AChannel: TIdIRCChannel; Content: String);
begin
  PScript.ExecuteFunction([AUser.Nick, AChannel.Name, Content], 'OnIRCMessage');
end;

procedure TfrmMain.OnNickChange(Sender: TObject; AUser: TIdIRCUser;
  ANewNick: String);
begin
  PScript.ExecuteFunction([AUser.Nick,ANewNick], 'OnIRCNameChange');
end;

procedure TfrmMain.OnIRCPartChannel(Sender: TObject; AUser: TIdIRCUser;
  AChannel: TIdIRCChannel);
begin
  PScript.ExecuteFunction([AUser.Nick, AChannel.Name], 'OnIRCPartChannel');
end;

procedure TfrmMain.OnIRCJoinChannel(Sender: TObject; AUser: TIdIRCUser;
  AChannel: TIdIRCChannel);
begin
  PScript.ExecuteFunction([AUser.Nick, AChannel.Name], 'OnIRCJoinChannel');
end;

procedure TfrmMain.OnIRCQuit(Sender: TObject; AUser: TIdIRCUser);
begin
  PScript.ExecuteFunction([AUser.Nick], 'OnIRCQuit');
end;

procedure TfrmMain.IRCAction(Sender: TObject; AUser: TIdIRCUser;
  AChannel: TIdIRCChannel; Content: String);
begin
  PScript.ExecuteFunction([AUser.Nick,AChannel.Name,Content], 'OnIRCAction');
end;

procedure TfrmMain.OnIRCInvite(Sender: TObject; ANick, AChannel: String);
begin
  PScript.ExecuteFunction([ANick,AChannel], 'OnIRCInvite');
end;

procedure TfrmMain.IRCConnected(Sender: TObject);
begin
  IRC.Join('#ywa');
end;

end.
