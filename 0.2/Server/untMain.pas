unit untMain;

interface
                                                                                                      
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IdTCPConnection, IdTCPClient, IdIRC, ExtCtrls,
  IdBaseComponent, IdComponent, IdTCPServer, INIFiles, NLDFileSearch,
  uPSComponent, IdHTTP, uPSComponent_Default;

type
  TSplitArray = array of String;
  PClient = ^TClient;
  TClient = record
    DNS : String[250];
    IP : String[250];
    Connected, LastAction  : TDateTime;
    Thread : Pointer;
  end;
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
    Server: TIdTCPServer;
    lblInfo: TLabel;
    lstBans: TListBox;
    tmrSaveBans: TTimer;
    grpLog: TGroupBox;
    lstLog: TMemo;
    IRC: TIdIRC;
    edtLogText: TEdit;
    btnLogSend: TButton;
    HTTP: TIdHTTP;
    Ce: TPSScript;
    lstMapAll: TListBox;
    tmrTimers: TTimer;
    lstTimers: TListBox;
    procedure FormCreate(Sender: TObject);
    procedure ServerConnect(AThread: TIdPeerThread);
    procedure ServerDisconnect(AThread: TIdPeerThread);
    procedure ServerExecute(AThread: TIdPeerThread);
    procedure tmrSaveBansTimer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnLogSendClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure edtLogTextKeyPress(Sender: TObject; var Key: Char);
    procedure IRCMessage(Sender: TObject; AUser: TIdIRCUser;
      AChannel: TIdIRCChannel; Content: String);
    procedure Log(Mssg : String);
    procedure Debug(Mssg : String);
    procedure CeCompile(Sender: TPSScript);
    procedure AddSpawn(PosX, PosY, PosZ, Rotation : Single);
    procedure AddObject(ModelID : Integer; PosX, PosY, PosZ, RotX, RotY, RotZ : Single);
    procedure AddVehicle(ModelID: Integer; PosX, PosY, PosZ, Rotation : Single);
    function IsPlayerAdmin(PlayerID : Integer): Boolean;
    function IsPlayerConnected(PlayerID : Integer): Boolean;
    function GetPlayerNick(PlayerID : Integer): String;
    function GetPlayerInterior(PlayerID : Integer): Integer;
    function GetPlayerAngle(PlayerID : Integer): Single;
    procedure SetPlayerAngle(PlayerID : Integer;Angle : Single);
    function GetPlayerHealth(PlayerID : Integer): Single;
    procedure SetPlayerHealth(PlayerID : Integer;Health : Single);
    procedure SetPlayerInterior(PlayerID, InteriorID : Integer);
    function GetPlayerPosX(PlayerID : Integer): Single;
    function GetPlayerPosY(PlayerID : Integer): Single;
    function GetPlayerPosZ(PlayerID : Integer): Single;
    procedure GetPlayerPos(PlayerID : Integer; PosX, PosY, PosZ : String);
    procedure SetPlayerPos(PlayerID : Integer; PosX, PosY, PosZ : Single);
    procedure SetPlayerFreeze(PlayerID : Integer;State : Boolean);
    function GetPlayerFreeze(PlayerID : Integer): Boolean;
    procedure AddHealthPickup(PosX, PosY, PosZ : Single);
    procedure AddArmorPickup(PosX, PosY, PosZ : Single);
    procedure SendTextToAll(Mssg : String);
    procedure SendTextToAllExceptPlayer(PlayerID : Integer; Mssg : String);
    procedure SendTextToPlayer(PlayerID : Integer; Mssg : String);
    procedure AddVehicleRepair(PosX, PosY, PosZ : Single);
    procedure DisplayTextPlayer(PlayerID, Style: Integer; Mssg : String; Time : Integer);
    procedure DisplayTextAll(Style : Integer; Mssg : String; Time : Integer);
    procedure SetPlayerMoney(PlayerID, Money : Integer);
    function GetPlayerMoney(PlayerID : Integer): Integer;
    function GetPlayerID(Nick : String): Integer;
    function GetDeathReason(ReasonID : Integer): String;
    function StrSplit(const Source, Delimiter: String): TSplitArray;
    procedure SendDataToPlayer(PlayerID : Integer;CommBlock : TCommBlock);
    procedure SendDataToAllExceptPlayer(PlayerID : Integer;CommBlock : TCommBlock);
    procedure SendDataToAll(CommBlock : TCommBlock);
    procedure SetWeapon(WeaponID, WeaponModelID : Integer);
    procedure KillPlayer(PlayerID : Integer);
    procedure BanPlayer(PlayerID : Integer);
    procedure KickPlayer(PlayerID : Integer);
    function IsPlayerIngame(PlayerID : Integer): Boolean;
    function CopyBetween(Source, bs, es : String): String;
    function CopyAfter(Source, bs : String): String;
    function CopyBefore(Source, bs : String): String;
    procedure Timer(Seconds : Integer; Execute : String);
    procedure tmrTimersTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;
  Clients : TThreadList;
  ServerPass, AdminPass, ServerName : String;
  Slots, Admins, GameHours, GameMinutes, Players : Integer;
  INI : TINIFile;
  ID, Port, PInterior, PMoney, PCar, PCar2 : Array of Integer;
  PFreeze : Array of Boolean;
  Slot, IsAdmin, IsIngame, IsIngameL : Array of Boolean;
  Nick, IP : Array of String;
  PPosX, PPosY, PPosZ, PRotation, PHealth : Array of Single;
  Hdl : Array of Cardinal;


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
    Result := 'Flame Thrower'
  Else If (WeaponID = 38) Then
    Result := 'Minigun'
  Else If (WeaponID = 16) Then
    Result := 'Grenade'
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
  Else If (WeaponID = 40) Then
    Result := 'Detonator'
  Else If (WeaponID = 44) Then
    Result := 'NV Goggles'
  Else If (WeaponID = 45) Then
    Result := 'IR Goggles'
  Else
    Result := 'Unknown weapon - ID: '+ IntToStr(WeaponID);
end;

procedure TfrmMain.Log(Mssg : String);
begin
  lstLog.Lines.Add(Mssg);
  If (IRC.Connected) Then
    IRC.Say(INI.ReadString('IRC','channel','#care'),Mssg);
end;

procedure TfrmMain.Debug(Mssg : String);
begin
  lstLog.Lines.Add(Mssg);
end;

procedure Err(Text: String);
begin
  MessageDlg(Text,mtError,[mbOk],0);
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

function TfrmMain.StrSplit(const Source, Delimiter: String): TSplitArray;
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

procedure TfrmMain.FormCreate(Sender: TObject);
var
  i : Integer;
begin
  If ( FileExists(GetCurrentDir + '\bans.lst') ) Then
    lstBans.Items.LoadFromFile(GetCurrentDir + '\bans.lst');
  INI := TINIFile.Create(GetCurrentDir + '\settings.ini');
  ServerName := INI.ReadString('SERVER','servername','Unnamed SAP server');
  If (Length(ServerName) > 65) Then
  Begin
    Err('Server name too long, limit is 65 characters.');
    Application.Terminate;
    Exit;
  End;
  GameHours := INI.ReadInteger('GAME','hours',12);
  GameMinutes := INI.ReadInteger('GAME','minutes',0);
  ServerPass := INI.ReadString('SERVER','password','');
  ServerPass := StringReplace(ServerPass, '|', '.',[rfReplaceAll, rfIgnoreCase]);
  If (Length(ServerPass) > 10) Then
  Begin
    Err('Server password too long, limit is 10 characters.');
    Application.Terminate;
    Exit;
  End;
  Admins := INI.ReadInteger('SERVER','admins',0);
  If not (Admins = 1) and not (Admins = 0) Then
  Begin
    Err('Admin system must be 1 for ON and 0 for OFF.');
    Application.Terminate;
    Exit;
  End;
  AdminPass := INI.ReadString('SERVER','adminpassword','changeme');
  AdminPass := StringReplace(AdminPass, '|', '.',[rfReplaceAll, rfIgnoreCase]);
  If (Length(AdminPass) > 10) Then
  Begin
    Err('Admin password too long, limit is 10 characters.');
    Application.Terminate;
    Exit;
  End;
  Slots := INI.ReadInteger('SERVER','slots',20);
  If (Slots > 20) or (Slots < 2) Then
  Begin
    Err('Minimum: 2 slots - Maximum 20 slots (Currently: '+ IntToStr(Slots) +').');
    Application.Terminate;
    Exit;
  End;
  Server.DefaultPort := INI.ReadInteger('SERVER','port',8070);
{  NLDGetFiles(ExtractFilePath(Application.ExeName)+ 'maps\*.lst',edtChangeMap.Items,[soExcludePath, soNoDirs]);
  For i := 0 To Pred(edtChangeMap.Items.Count) Do
  Begin
    Str := edtChangeMap.Items[i];
    Str := Copy(Str,0,Length(Str)-4);
    edtChangeMap.Items[i] := Str;
  End;
  CurrentMap := edtChangeMap.Items[0];
  lblCurMap.Caption := CurrentMap;
  edtChangeMap.ItemIndex := 0;
  MapCars.Items.LoadFromFile('maps\'+ CurrentMap +'.lst');
  For i := Pred(MapCars.Count) downto 0 Do
  Begin
    If (Copy(MapCars.Items.Strings[i],0,2) = '//') Then
      MapCars.Items.Delete(i);
  End;    }

  SetLength(Slot,21);
  SetLength(Nick,21);
  SetLength(ID,21);
  SetLength(Port,21);
  SetLength(IP,21);
  SetLength(Hdl,21);
  SetLength(IsAdmin,21);
  SetLength(IsIngame,21);
  SetLength(IsIngameL,21);
  SetLength(PPosX,21);
  SetLength(PPosY,21);
  SetLength(PPosZ,21);
  SetLength(PRotation,21);
  SetLength(PInterior,21);
  SetLength(PMoney,21);
  SetLength(PCar,21);
  SetLength(PCar2,21);
  SetLength(PFreeze,21);
  SetLength(PHealth,21);

  For i := 1 To 20 Do
  Begin
    Slot[i] := False;
    Nick[i] := '';
  End;
  
  Try
    Server.Active := True;
  Except
    Err('Port already used.');
    Application.Terminate;
    Exit;
  End;

  // IRC echo
  IRC.Host := INI.ReadString('IRC','host','irc.gtanet.com');
  IRC.Port := INI.ReadInteger('IRC','port',6667);
  IRC.Nick := INI.ReadString('IRC','nick','SAP-Echo');
  IRC.AltNick := INI.ReadString('IRC','nick','SAP[Echo]');
  IRC.RealName := INI.ReadString('IRC','nick','SA-Party.com');

  Clients := TThreadList.Create;

  tmrSaveBans.Enabled := True;
end;

procedure TfrmMain.ServerConnect(AThread: TIdPeerThread);
var
  NewClient : PClient;
begin
  GetMem(NewClient, SizeOf(TClient));

  NewClient.DNS         := AThread.Connection.LocalName;
  NewClient.Connected   := Now;
  NewClient.LastAction  := NewClient.Connected;
  NewClient.Thread      := AThread;
  NewClient.IP          := AThread.Connection.Socket.Binding.PeerIP;

  AThread.Data := TObject(NewClient);

  Try
    Clients.LockList.Add(NewClient);
  Finally
    Clients.UnlockList;
  End;
  Inc(Players,1);
  //lstLog.Lines.Add('* New connection');
end;

procedure TfrmMain.ServerDisconnect(AThread: TIdPeerThread);
var
  ActClient: PClient;
  i, i2 : Integer;
  RecClient : PClient;
  RecThread : TIdPeerThread;
  CommBlock : TCommBlock;
begin
  ActClient := PClient(AThread.Data);
  // Maak ruimte vrij
  For i := 1 To 20 Do
  Begin
    If (AThread.Handle = Hdl[i]) and (Slot[i] = True) Then
    Begin
      //Log('* Player '+ Nick[i] +' left the server');
      CommBlock.Command := 'LEAVE';
      CommBlock.Nick := Nick[i];
      CommBlock.PlayerID := ID[i];
      With Clients.LockList Do
      Begin
        Try
          For i2 := 0 To Pred(Count) Do
          Begin
            RecClient := Items[i2];
            RecThread := RecClient.Thread;
            If not (RecThread.Handle = Hdl[i]) Then
              RecThread.Connection.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
          End;
        Finally
          Clients.UnlockList;
        End;
      End;
      Slot[i] := False;
      Nick[i] := '';
      ID[i] := 0;
      Port[i] := 0;
      IP[i] := '';
      Hdl[i] := 0;
    End;
  End;
  Try
    Clients.LockList.Remove(ActClient);
  Finally
    Clients.UnlockList;
  End;
  FreeMem(ActClient);
  AThread.Data := Nil;
  Dec(Players,1);
  //lstLog.Lines.Add('* Lost connection');
end;

procedure TfrmMain.ServerExecute(AThread: TIdPeerThread);
var
  RecClient, ActClient : PClient;
  CommBlock, CommBlock2 : TCommBlock;
  RecThread : TIdPeerThread;
  i, i2, PlayID, Done, Int : Integer;
  Arr : TSplitArray;
begin
  If (AThread.Terminated) Or (AThread.Connection.Connected = False) Then
    Exit;

  ActClient := PClient(AThread.Data);
  ActClient.LastAction := Now;

  AThread.Connection.ReadBuffer(CommBlock,SizeOf(TCommBlock));

  If (CommBlock.Command = 'SYNC') Then
  Begin
    PPosX[CommBlock.PlayerID] := CommBlock.PosX;
    PPosY[CommBlock.PlayerID] := CommBlock.PosY;
    PPosZ[CommBlock.PlayerID] := CommBlock.PosZ;
    PRotation[CommBlock.PlayerID] := CommBlock.XA;
    PInterior[CommBlock.PlayerID] := CommBlock.Interior;
    PCar[CommBlock.PlayerID] := CommBlock.Car;
    If (CommBlock.State = 1) Then
      PHealth[CommBlock.PlayerID] := CommBlock.XC;
    If not (PCar[CommBlock.PlayerID] = PCar2[CommBlock.PlayerID]) Then
    Begin
      If (CommBlock.Car > 0) Then
        Ce.ExecuteFunction([CommBlock.PlayerID,CommBlock.Car],'OnPlayerEnterVehicle')
      Else
      Begin
        Int := PCar2[CommBlock.PlayerID];
        Ce.ExecuteFunction([CommBlock.PlayerID,Int],'OnPlayerLeaveVehicle');
      End;
      PCar2[CommBlock.PlayerID] := PCar[CommBlock.PlayerID];
    End;
  End
  Else If (CommBlock.Command = 'LEAVE') Then
  Begin
    Ce.ExecuteFunction([CommBlock.PlayerID],'OnPlayerLeft');
    Nick[CommBlock.PlayerID] := '';
    Slot[CommBlock.PlayerID] := False;
    ID[CommBlock.PlayerID] := 0;
    Port[CommBlock.PlayerID] := 0;
    IP[CommBlock.PlayerID] := '';
    Hdl[CommBlock.PlayerID] := 0;
    PPosX[CommBlock.PlayerID] := 0.0;
    PPosY[CommBlock.PlayerID] := 0.0;
    PPosZ[CommBlock.PlayerID] := 0.0;
    PRotation[CommBlock.PlayerID] := 0.0;
    IsAdmin[CommBlock.PlayerID] := False;
  End
  Else If (CommBlock.Command = 'SYNC2') Then
  Begin
    PMoney[CommBlock.PlayerID] := CommBlock.Roll2;
  End
  Else If (CommBlock.Command = 'DMAP') Then
  Begin
      CommBlock2.Command := 'M4P';
      CommBlock2.Mssg := lstMapAll.Items[CommBlock.Anim];
      If (CommBlock.Anim = Pred(lstMapAll.Count)) Then
        CommBlock2.State := 1
      Else
        CommBlock2.State := 0;
      AThread.Connection.WriteBuffer(CommBlock2,SizeOf(CommBlock2),True);
      Exit;
  End
  Else If (CommBlock.Command = 'BANM') Then
    lstBans.Items.Add(AThread.Connection.Socket.Binding.PeerIP)
  Else If (CommBlock.Command = 'KICK') Or (CommBlock.Command = 'BAN') Then
  Begin
      Try
        Arr := Split(CommBlock.Mssg,'|');
      Except
      End;
      If (Nick[1] = Arr[0]) or (Nick[2] = Arr[0]) or (Nick[3] = Arr[0]) or (Nick[4] = Arr[0]) or (Nick[5] = Arr[0]) or (Nick[6] = Arr[0]) or (Nick[7] = Arr[0]) or (Nick[8] = Arr[0]) or (Nick[9] = Arr[0]) or (Nick[10] = Arr[0]) or (Nick[11] = Arr[0]) or (Nick[12] = Arr[0]) or (Nick[13] = Arr[0]) or (Nick[14] = Arr[0]) or (Nick[15] = Arr[0]) or (Nick[16] = Arr[0]) or (Nick[17] = Arr[0]) or (Nick[18] = Arr[0]) or (Nick[19] = Arr[0]) or (Nick[20] = Arr[0]) Then
      Begin
        If (AdminPass = Arr[1]) And (Length(AdminPass) > 0) And (Length(Arr[1]) > 0) And (Admins = 1) Then
          CommBlock.Mssg := Arr[0]
        Else
          Exit;
      End;
      //Log('* Player '+ Arr[0] +' is kicked from the game by '+ CommBlock.Nick);
  End
  Else If (CommBlock.Command = 'JOIN') Then
  Begin
      Try
        Arr := Split(CommBlock.Mssg,'|');
      Except
      End;
      PlayID := 0;
      Done := 0;
      For i := 1 To 20 Do
      Begin
        If (Nick[i] = CommBlock.Nick) Then
          CommBlock2.Interior := 6;
        If (Slot[i] = False) and (Done = 0) Then
        Begin
          Nick[i] := CommBlock.Nick;
          Slot[i] := True;
          Port[i] := AThread.Connection.Socket.Binding.Port;
          IP[i] := AThread.Connection.Socket.Binding.IP;
          ID[i] := i;
          Hdl[i] := AThread.Handle;
          PlayID := i;
          Done := 1;
          PPosX[i] := 0.0;
          PPosY[i] := 0.0;
          PPosZ[i] := 0.0;
          PRotation[i] := 0.0;
          IsAdmin[i] := False;
          IsIngame[i] := False;
          IsIngameL[i] := False;
          PInterior[i] := 0;
        End;
      End;
      If (PlayID = 0) or (PlayID > Slots) Then
        CommBlock2.Interior := 3 // Server vol
      Else If Not (CommBlock.Interior = 13) Then
        CommBlock2.Interior := 1 // Verkeerde versie
      Else If Not (ServerPass = Arr[0]) And (Length(ServerPass) > 0) Then
        CommBlock2.Interior := 2 // Wachtwoord fout
      Else If Not (AdminPass = Arr[1]) And Not (Arr[1] = '0') And (Length(AdminPass) > 0) and (Length(Arr[1]) > 0) and (Admins = 1) Then
        CommBlock2.Interior := 4; // Admin wachtwoord fout
      For i2 := 0 To Pred(lstBans.Count) Do
      Begin
        If (AThread.Connection.Socket.Binding.PeerIP = lstBans.Items[i2]) Then
          CommBlock2.Interior := 5; // Gebant
      End;
      //Log('* Player '+ CommBlock.Nick +' joined the server');
      If Not (Arr[1] = '0') And (AdminPass = Arr[1]) And (Admins = 1) And (Length(Arr[1]) > 0) Then
        IsAdmin[PlayID] := True;
      CommBlock2.Command := 'OK';
      CommBlock2.Mssg := ServerName;
      CommBlock2.PlayerID := PlayID;
      CommBlock2.Nick := CommBlock.Nick;
      CommBlock2.Crouch := GameHours;
      CommBlock2.CrouchRoll2 := GameMinutes;
      AThread.Connection.WriteBuffer(CommBlock2,SizeOf(CommBlock2),True);
      If (CommBlock2.Interior > 0) Then
        Exit
      Else
        Ce.ExecuteFunction([PlayID],'OnPlayerJoin');
  End
  Else If (CommBlock.Command = 'SPWN0') Then
  Begin
    Ce.ExecuteFunction([CommBlock.PlayerID,CommBlock.Interior],'OnPlayerChangeSpawn');
    Exit;
  End
  Else If (CommBlock.Command = 'SPWN1') Then
  Begin
    Ce.ExecuteFunction([CommBlock.PlayerID,CommBlock.Interior],'OnPlayerSpawn');
    Exit;
  End
  Else If (CommBlock.Command = 'PING') Then
  Begin
    CommBlock2.Command := 'PONG';
    CommBlock2.Roll0 := Players-1;
    CommBlock2.Roll2 := Slots;
    CommBlock2.Mssg := ServerName +'_____'+ CommBlock.Mssg;
    AThread.Connection.WriteBuffer(CommBlock2,SizeOf(CommBlock2),True);
    Exit;
  End
  Else If (CommBlock.Command = 'PANG') Then
  Begin
    CommBlock2.Command := 'PENG';
    AThread.Connection.WriteBuffer(CommBlock2,SizeOf(CommBlock2),True);
    Exit;
  End
  Else If (CommBlock.Command = 'MSSG') Then
  Begin
    Log(CommBlock.Nick +': '+ CommBlock.Mssg);
    Ce.ExecuteFunction([CommBlock.PlayerID,CommBlock.Mssg],'OnPlayerText');
  End
  Else If (CommBlock.Command = 'CMD') Then
  Begin
    Ce.ExecuteFunction([CommBlock.PlayerID,CommBlock.Mssg],'OnPlayerCommand');
    Exit;
  End
  Else If (CommBlock.Command = 'DEATH') Then
  Begin
    Ce.ExecuteFunction([CommBlock.Roll0,CommBlock.PlayerID,CommBlock.Roll2],'OnPlayerDeath'); // Killer (ID), Player (ID), Reason (ID)
    Exit;
  End
  Else If (CommBlock.Command = 'GON') Then
  Begin
    IsIngame[CommBlock.PlayerID] := True;
    If not (IsIngame[CommBlock.PlayerID] = IsIngameL[CommBlock.PlayerID]) Then
    Begin
      IsIngameL[CommBlock.PlayerID] := IsIngame[CommBlock.PlayerID];
      Ce.ExecuteFunction([CommBlock.PlayerID],'OnPlayerStartGame');
    End;
  End
  Else If (CommBlock.Command = 'GOFF') Then
  Begin
    IsIngame[CommBlock.PlayerID] := False;
    If not (IsIngame[CommBlock.PlayerID] = IsIngameL[CommBlock.PlayerID]) Then
    Begin
      IsIngameL[CommBlock.PlayerID] := IsIngame[CommBlock.PlayerID];
      Ce.ExecuteFunction([CommBlock.PlayerID],'OnPlayerExitGame');
    End;
  End;

  With Clients.LockList Do
  Try
    For i := 0 To Pred(Count) Do
    Begin
      RecClient := Items[i];
      RecThread := RecClient.Thread;
      If Not (RecThread.Handle = AThread.Handle) And (RecThread.Connection.Connected = True) Then
        RecThread.Connection.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
    End;
  Finally
    Clients.UnlockList;
  End;
end;

procedure TfrmMain.tmrSaveBansTimer(Sender: TObject);
var
  Mssg : String;
begin
  lstBans.Items.SaveToFile(GetCurrentDir + '\bans.lst');
  Mssg := HTTP.Get('http://84.16.249.241/add.php?port='+ IntToStr(Server.DefaultPort));
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Try
    If (IRC.Connected) Then
     IRC.Quit('Server shutting down');

    INI.Free;

    Server.MaxConnections := 0;
    Server.Active := False;
  Except
    Application.Terminate;
  End;

{var
  CommBlock : TCommBlock;
  i : Integer;
  RecClient : PClient;
  RecThread : TIdPeerThread;
begin
  Ce.ExecuteFunction([],'OnShutdown');
  btnExit.Caption := 'Please wait...';
  frmMain.Enabled := False;
  If (Server.Active = True) Then
  Begin
    CommBlock.Command := 'CLOSE';
    CommBlock.Nick := 'Server';
    With Clients.LockList Do
    Begin
      Try
        For i := 0 To Pred(Count) Do
        Begin
          RecClient := Items[i];
          RecThread := RecClient.Thread;
          RecThread.Connection.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
        End;
      Except
      End;
    End;
  End;
  Sleep(100);
  Application.Terminate; }
end;

procedure TfrmMain.btnLogSendClick(Sender: TObject);
var
  i : Integer;
  RecClient : PClient;
  RecThread : TIdPeerThread;
  CommBlock : TCommBlock;
begin
  CommBlock.Command := 'MSSG';
  CommBlock.Nick := 'Server';
  CommBlock.Mssg := edtLogText.Text;
  With Clients.LockList Do
  Begin
    Try
      For i := 0 To Pred(Count) Do
      Begin
        RecClient := Items[i];
        RecThread := RecClient.Thread;
        RecThread.Connection.WriteBuffer(CommBlock,SizeOf(TCommBlock),True);
      End;
    Finally
      Clients.UnlockList;
    End;
  End;
  Log('Server: '+ edtLogText.Text);
  edtLogText.Clear;
end;

procedure TfrmMain.FormActivate(Sender: TObject);
var
  Val, i : Integer;
  Mssg : String;
  Compiled : Boolean;
  Messages : TSplitArray;
begin
  SetLength(Messages,100);
  Ce.Script.LoadFromFile('scripts\main.script');
  Compiled := Ce.Compile;
  If Not (Compiled) Then
  Begin
    Err('Error while compiling script...');
    For i := 0 To Pred(Ce.CompilerMessageCount) Do
    Begin
      Err(Ce.CompilerMessages[i].MessageToString);
    End;
    Application.Terminate;
    Exit;
  End;
  If (Compiled) Then Begin
    If Not (Ce.Execute) Then
    Begin
      Err('Error while executing script: '+ Ce.ExecErrorToString);
      Application.Terminate;
      Exit;
    End;
  End;
  
  Val := INI.ReadInteger('IRC','enabled',0);
  If (Val = 1) Then
  Begin
    IRC.Connect();
    IRC.Join(INI.ReadString('IRC','channel','#care'));
  End;
  Log('*** San Andreas Party 0.2.0.0 BETA Server started');
  Log('*** Current server name: '''+ ServerName +'''');
  Mssg := HTTP.Get('http://84.16.249.241/add.php?port='+ IntToStr(Server.DefaultPort));
  //Mssg := 'ok';
  If (Mssg = 'ok') Then
    Log('*** Server has been added to the masterlist');

  Ce.ExecuteFunction([],'OnStart'); // Server started
end;

procedure TfrmMain.Timer(Seconds : Integer; Execute : String);
begin
  {Seconds := Seconds * 50;
  For i := 0 To Seconds Do
  Begin
    Sleep(20);
    Application.ProcessMessages;
  End;
  Ce.ExecuteFunction([],Execute);}
  //TInterval[Timersss] := Seconds;
  //TExecute[Timersss] := Execute;
  //Inc(Timersss);
  lstTimers.Items.Add(IntToStr(Seconds) +' '+ Execute);
end;

procedure TfrmMain.edtLogTextKeyPress(Sender: TObject; var Key: Char);
begin
  If (Key = #13) Then
    btnLogSend.Click;
end;

procedure TfrmMain.IRCMessage(Sender: TObject; AUser: TIdIRCUser;
  AChannel: TIdIRCChannel; Content: String);
var
  Mssg : String;
  Arr : TSplitArray;
  i, i2 : Integer;
begin
  Try
    Arr := Split(Content,' ');
  Except
    Exit;
  End;
  If (Arr[0] = '!players') Then
  Begin
    If (Players = 0) Then
      IRC.Say(INI.ReadString('IRC','channel','#care'),'2* Players: '+ IntToStr(Players) +'/'+ IntToStr(Slots) +'')
    Else
    Begin
      Mssg := '';
      For i2 := 0 To 20 Do
      Begin
        If Not (Nick[i2] = '') Then
        Begin
          If (Mssg = '') Then
            Mssg := Nick[i2]
          Else
            Mssg := Mssg +' , '+ Nick[i2];
        End;
      End;
      IRC.Say(INI.ReadString('IRC','channel','#care'),'2* Players: '+ IntToStr(Players) +'/'+ IntToStr(Slots) +' - '+ Mssg +'');
    End;
  End
  Else If (Arr[0] = '!commands') or (Arr[0] = '!help') Then
    IRC.Say(INI.ReadString('IRC','channel','#care'),'2* SAP Echo script - Commands: !players , !msg , !commands , !help , !about')
  Else If (Arr[0] = '!about') Then
    IRC.Say(INI.ReadString('IRC','channel','#care'),'2* About: SAP Echo script - By: Ywa*NL - www.sa-party.com')
  Else If (Arr[0] = '!msg') or (Arr[0] = '!say') Then
  Begin
    If (High(Arr) < 1) Then
      Exit;
    For i := 1 To High(Arr) Do
    Begin
      If (Mssg = '') Then
        Mssg := Arr[i]
      Else
        Mssg := Mssg +' '+ Arr[i];
    End;
    edtLogText.Text := AUser.Nick +' (IRC): '+ Mssg;
    If (Length(edtLogText.Text) > 85) Then
    Begin
      IRC.Say(INI.ReadString('IRC','channel','#care'),'Message too long '+ AUser.Nick);
      Exit;
    End;
    btnLogSend.Click;
    edtLogText.Clear;
  End;
end;

procedure TfrmMain.SendDataToAll(CommBlock : TCommBlock);
var
  i, i2 : Integer;
  RecClient : PClient;
  RecThread : TIdPeerThread;
begin
  With Clients.LockList Do
  Begin
    Try
      For i := 0 To Pred(Count) Do
      Begin
        RecClient := Items[i];
        RecThread := RecClient.Thread;
        For i2 := 1 To 20 Do
        Begin
          If (RecThread.Handle = Hdl[i2]) and not (Hdl[i2] = 0) Then
            RecThread.Connection.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
        End;
      End;
    Finally
      Clients.UnlockList;
    End;
  End;
end;

procedure TfrmMain.SendDataToPlayer(PlayerID : Integer;CommBlock : TCommBlock);
var
  i : Integer;
  RecClient : PClient;
  RecThread : TIdPeerThread;
begin
  With Clients.LockList Do
  Begin
    Try
      For i := 0 To Pred(Count) Do
      Begin
        RecClient := Items[i];
        RecThread := RecClient.Thread;
        //For i2 := 1 To 20 Do
        //Begin
          If (RecThread.Handle = Hdl[PlayerID]) Then
          Begin
            RecThread.Connection.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
          End;
        //End;
      End;
    Finally
      Clients.UnlockList;
    End;
  End;
end;

procedure TfrmMain.SendDataToAllExceptPlayer(PlayerID : Integer;CommBlock : TCommBlock);
var
  i : Integer;
  RecClient : PClient;
  RecThread : TIdPeerThread;
begin
  With Clients.LockList Do
  Begin
    Try
      For i := 0 To Pred(Count) Do
      Begin
        RecClient := Items[i];
        RecThread := RecClient.Thread;
        //For i2 := 1 To 20 Do
        //Begin
          If not (RecThread.Handle = Hdl[PlayerID]) Then
          Begin
            RecThread.Connection.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
          End;
        //End;
      End;
    Finally
      Clients.UnlockList;
    End;
  End;
end;

procedure TfrmMain.AddSpawn(PosX, PosY, PosZ, Rotation : Single);
var
  CB : TCommBlock;
  Mssg : String;
begin
  CB.Command := 'NMP';
  CB.Nick := 'Server';
  Mssg := 's|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ) +'|'+ FormatFloat('0.000',Rotation);
  CB.Mssg := Mssg;
  SendDataToAll(CB);
  lstMapAll.Items.Add(Mssg);
end;

procedure TfrmMain.AddVehicle(ModelID: Integer; PosX, PosY, PosZ, Rotation : Single);
var
  CB : TCommBlock;
  Mssg : String;
begin
  CB.Command := 'NMP';
  CB.Nick := 'Server';
  Mssg := 'v|'+ IntToStr(ModelID) +'|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ) +'|'+ FormatFloat('0.000',Rotation);
  CB.Mssg := Mssg;
  SendDataToAll(CB);
  lstMapAll.Items.Add(Mssg);
end;

procedure TfrmMain.AddObject(ModelID : Integer; PosX, PosY, PosZ, RotX, RotY, RotZ : Single);
var
  CB : TCommBlock;
  Mssg : String;
begin
  CB.Command := 'NMP';
  CB.Nick := 'Server';
  Mssg := 'o|'+ IntToStr(ModelID) +'|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ) +'|'+ FormatFloat('0.000',RotX) +'|'+ FormatFloat('0.000',RotY) +'|'+ FormatFloat('0.000',RotZ);
  CB.Mssg := Mssg;
  SendDataToAll(CB);
  lstMapAll.Items.Add(Mssg);
end;

function TfrmMain.IsPlayerAdmin(PlayerID : Integer): Boolean;
begin
  If (PlayerID < 21) and (PlayerID > 0) Then
    result := IsAdmin[PlayerID]
  Else
    result := False;
end;

function TfrmMain.IsPlayerConnected(PlayerID : Integer): Boolean;
begin
  If (PlayerID < 21) and (PlayerID > 0) Then
    result := IsAdmin[PlayerID]
  Else
    result := False;
end;

function TfrmMain.IsPlayerIngame(PlayerID : Integer): Boolean;
begin
  If (PlayerID < 21) and (PlayerID > 0) Then
    result := IsIngame[PlayerID]
  Else
    result := False;
end;

function TfrmMain.GetPlayerNick(PlayerID: Integer): String;
begin
  If (PlayerID < 21) and (PlayerID > 0) Then
    result := Nick[PlayerID]
  Else
    result := '';
end;

function TfrmMain.GetPlayerID(Nick : String): Integer;
var
  i, i2 : Integer;
begin
  i2 := 0;
  For i := 1 To 20 Do
  Begin
    If (Nick[i] = Nick) Then
    Begin
      i2 := i;
    End;
  End;
  If (i2 = 0) Then
    result := 0
  Else
    result := i2;
end;

function TfrmMain.GetPlayerPosX(PlayerID : Integer): Single;
begin
  If (PlayerID < 21) and (PlayerID > 0) Then
    result := PPosX[PlayerID]
  Else
    result := 0.0;
end;

function TfrmMain.GetPlayerPosY(PlayerID : Integer): Single;
begin
  If (PlayerID < 21) and (PlayerID > 0) Then
    result := PPosY[PlayerID]
  Else
    result := 0.0;
end;

function TfrmMain.GetPlayerPosZ(PlayerID : Integer): Single;
begin
  If (PlayerID < 21) and (PlayerID > 0) Then
    result := PPosZ[PlayerID]
  Else
    result := 0.0;
end;


procedure TfrmMain.GetPlayerPos(PlayerID : Integer; PosX, PosY, PosZ : String);
begin
//  Ce.SetVarToInstance(xPosX,FloatToStr(PPosX[PlayerID]));
//  Ce.GetVariable()
end;

procedure TfrmMain.SetPlayerPos(PlayerID : Integer;PosX, PosY, PosZ : Single);
var
  CB : TCommBlock;
begin
  CB.Command := 'POS';
  CB.Nick := 'Server';
  CB.PlayerID := PlayerID;
  CB.PosX := PosX;
  CB.PosY := PosY;
  CB.PosZ := PosZ;
  SendDataToPlayer(PlayerID,CB);
end;

function TfrmMain.GetPlayerInterior(PlayerID : Integer): Integer;
begin
  If (PlayerID < 21) and (PlayerID > 0) Then
    result := PInterior[PlayerID]
  Else
    result := 0;
end;

procedure TfrmMain.SetPlayerInterior(PlayerID, InteriorID : Integer);
var
  CB : TCommBlock;
begin
  CB.Command := 'INT';
  CB.Nick := 'Server';
  CB.Interior := InteriorID;
  SendDataToPlayer(PlayerID,CB);
end;

function TfrmMain.GetPlayerAngle(PlayerID : Integer): Single;
begin
  If (PlayerID < 21) and (PlayerID > 0) Then
    result := PRotation[PlayerID]
  Else
    result := 0.0;
end;

procedure TfrmMain.SetPlayerAngle(PlayerID : Integer;Angle : Single);
var
  CB : TCommBlock;
begin
  CB.Command := 'ROT';
  CB.Nick := 'Server';
  CB.XA := Angle;
  SendDataToPlayer(PlayerID,CB);
end;


function TfrmMain.GetPlayerHealth(PlayerID : Integer): Single;
begin
  If (PlayerID < 21) and (PlayerID > 0) Then
    result := PHealth[PlayerID]
  Else
    result := 0.0;
end;

procedure TfrmMain.KickPlayer(PlayerID : Integer);
var
  CB : TCommBlock;
begin
  CB.Command := 'KICK';
  SendDataToPlayer(PlayerID,CB);
end;

procedure TfrmMain.KillPlayer(PlayerID : Integer);
var
  CB : TCommBlock;
begin
  CB.Command := 'KILL';
  SendDataToPlayer(PlayerID,CB);
end;

procedure TfrmMain.BanPlayer(PlayerID : Integer);
var
  CB : TCommBlock;
begin
  CB.Command := 'BAN';
  SendDataToPlayer(PlayerID,CB);
end;

procedure TfrmMain.SetPlayerHealth(PlayerID : Integer;Health : Single);
var
  CB : TCommBlock;
begin
  CB.Command := 'HT';
  CB.Nick := 'Server';
  CB.XA := Health;
  SendDataToPlayer(PlayerID,CB);
end;


procedure TfrmMain.AddHealthPickup(PosX, PosY, PosZ : Single);
var
  CB : TCommBlock;
  Mssg : String;
begin
  CB.Command := 'NMP';
  CB.Nick := 'Server';
  Mssg := 'health|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ);
  CB.Mssg := Mssg;
  SendDataToAll(CB);
  lstMapAll.Items.Add(Mssg);
end;

procedure TfrmMain.AddVehicleRepair(PosX, PosY, PosZ : Single);
var
  CB : TCommBlock;
  Mssg : String;
begin
  CB.Command := 'NMP';
  CB.Nick := 'Server';
  Mssg := 'r|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ);
  CB.Mssg := Mssg;
  SendDataToAll(CB);
  lstMapAll.Items.Add(Mssg);
end;

procedure TfrmMain.AddArmorPickup(PosX, PosY, PosZ : Single);
var
  CB : TCommBlock;
  Mssg : String;
begin
  CB.Command := 'NMP';
  CB.Nick := 'Server';
  Mssg := 'a|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ);
  CB.Mssg := Mssg;
  SendDataToAll(CB);
  lstMapAll.Items.Add(Mssg);
end;

procedure TfrmMain.SetWeapon(WeaponID, WeaponModelID : Integer);
var
  CB : TCommBlock;
  Mssg : String;
begin
  CB.Command := 'NMP';
  CB.Nick := 'Server';
  Mssg := 'w|'+ IntToStr(WeaponID) +'|'+ IntToStr(WeaponModelID);
  CB.Mssg := Mssg;
  SendDataToAll(CB);
  lstMapAll.Items.Add(Mssg);
end;

procedure TfrmMain.SendTextToAllExceptPlayer(PlayerID : Integer; Mssg : String);
var
  CB : TCommBlock;
begin
  If (Length(Mssg) > 85) Then
    Exit;
  CB.Command := 'ANN';
  CB.Nick := 'Server';
  CB.Mssg := Mssg;
  SendDataToAllExceptPlayer(PlayerID,CB);
end;

procedure TfrmMain.SendTextToPlayer(PlayerID : Integer; Mssg : String);
var
  CB : TCommBlock;
begin
  If (Length(Mssg) > 85) Then
    Exit;
  CB.Command := 'ANN';
  CB.Nick := 'Server';
  CB.Mssg := Mssg;
  SendDataToPlayer(PlayerID,CB);
end;

procedure TfrmMain.SendTextToAll(Mssg : String);
var
  CB : TCommBlock;
begin
  If (Length(Mssg) > 85) Then
    Exit;
  CB.Command := 'ANN';
  CB.Nick := 'Server';
  CB.Mssg := Mssg;
  SendDataToAll(CB);
  Log(Mssg);
end;

procedure TfrmMain.DisplayTextPlayer(PlayerID, Style: Integer; Mssg : String; Time : Integer);
var
  CB : TCommBlock;
begin
  If (Length(Mssg) > 85) Then
    Exit;
  CB.Command := 'DIS';
  CB.Nick := 'Server';
  CB.Roll2 := Style;
  CB.Anim := Time;
  CB.Mssg := Mssg;
  SendDataToPlayer(PlayerID,CB);
end;

procedure TfrmMain.DisplayTextAll(Style: Integer; Mssg : String; Time : Integer);
var
  CB : TCommBlock;
begin
  If (Length(Mssg) > 85) Then
    Exit;
  CB.Command := 'DIS';
  CB.Nick := 'Server';
  CB.Roll2 := Style;
  CB.Mssg := Mssg;
  CB.Anim := Time;
  CB.Mssg := Mssg;
  SendDataToAll(CB);
end;

procedure TfrmMain.SetPlayerMoney(PlayerID, Money : Integer);
var
  CB : TCommBlock;
begin
  CB.Command := 'MON';
  CB.Nick := 'Server';
  CB.Interior := Money;
  SendDataToPlayer(PlayerID,CB);
end;

function TfrmMain.GetPlayerMoney(PlayerID : Integer): Integer;
begin
  If (PlayerID < 21) and (PlayerID > 0) Then
    result := PMoney[PlayerID]
  Else
    result := 0;
end;

procedure TfrmMain.SetPlayerFreeze(PlayerID : Integer;State : Boolean);
var
  CB : TCommBlock;
begin
  If (PlayerID < 1) or (PlayerID > 20) Then
    Exit;
  If (State = True) Then
  Begin
    CB.Command := 'FRZ';
    PFreeze[PlayerID] := True;
  End
  Else
  Begin
    CB.Command := 'UFRZ';
    PFreeze[PlayerID] := False;
  End;
  CB.Nick := 'Server';
  CB.PlayerID := PlayerID;
  SendDataToPlayer(PlayerID,CB);
end;

function TfrmMain.GetPlayerFreeze(PlayerID : Integer): Boolean;
begin
  If (PlayerID < 21) and (PlayerID > 0) Then
    result := PFreeze[PlayerID]
  Else
    result := False;
end;

function TfrmMain.GetDeathReason(ReasonID : Integer): String;
begin
  result := GetWeaponName(ReasonID);
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
var
  ePos : Integer;
begin
//  Source := Copy(Source, Pos(bs, Source) + Length(bs), Length(Source));
  Source := Copy(Source, 0, Pos(bs, Source)-1);
  //ePos := Pos(Source,bs);
  //result := Copy(Source, 0, ePos);
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

procedure TfrmMain.CeCompile(Sender: TPSScript);
begin

  Sender.AddMethod(Self, @TfrmMain.Log,'procedure Log(const Message: string);');
  Sender.AddMethod(Self, @TfrmMain.Debug,'procedure Debug(const Message: string);');

  Sender.AddMethod(Self, @TfrmMain.AddSpawn,'procedure CreateSpawn(PosX, PosY, PosZ, Rotation : Single);');
  Sender.AddMethod(Self, @TfrmMain.AddObject,'procedure CreateObject(ModelID : Integer; PosX, PosY, PosZ, RotX, RotY, RotZ : Single);');
  Sender.AddMethod(Self, @TfrmMain.AddVehicle,'procedure CreateVehicle(ModelID: Integer; PosX, PosY, PosZ, Rotation : Single);');
  Sender.AddMethod(Self, @TfrmMain.AddVehicleRepair,'procedure CreateVehicleRepair(PosX, PosY, PosZ : Single);');
  Sender.AddMethod(Self, @TfrmMain.AddHealthPickup,'procedure CreateHealthPickup(PosX, PosY, PosZ : Single);');
  Sender.AddMethod(Self, @TfrmMain.AddArmorPickup,'procedure CreateArmorPickup(PosX, PosY, PosZ : Single);');


  Sender.AddMethod(Self, @TfrmMain.IsPlayerAdmin,'function IsPlayerAdmin(PlayerID: Integer): Boolean;');
  Sender.AddMethod(Self, @TfrmMain.IsPlayerConnected,'function IsPlayerConnected(PlayerID: Integer): Boolean;');

  Sender.AddMethod(Self, @TfrmMain.GetPlayerNick,'function GetPlayerNick(PlayerID: Integer): String;');
  Sender.AddMethod(Self, @TfrmMain.GetPlayerID,'function GetPlayerID(Nick : String): Integer;');

  Sender.AddMethod(Self, @TfrmMain.GetPlayerPosX,'function GetPlayerPosX(PlayerID: Integer): Single;');
  Sender.AddMethod(Self, @TfrmMain.GetPlayerPosY,'function GetPlayerPosY(PlayerID: Integer): Single;');
  Sender.AddMethod(Self, @TfrmMain.GetPlayerPosZ,'function GetPlayerPosZ(PlayerID: Integer): Single;');

  Sender.AddMethod(Self, @TfrmMain.GetPlayerPos,'procedure GetPlayerPos(PlayerID: Integer; PosX, PosY, PosZ : Single);');
  Sender.AddMethod(Self, @TfrmMain.SetPlayerPos,'procedure SetPlayerPos(PlayerID: Integer; PosX, PosY, PosZ : Single);');
  Sender.AddMethod(Self, @TfrmMain.GetPlayerInterior,'function GetPlayerInterior(PlayerID : Integer): Integer;');
  Sender.AddMethod(Self, @TfrmMain.SetPlayerInterior,'procedure SetPlayerInterior(PlayerID, InteriorID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.GetPlayerAngle,'function GetPlayerAngle(PlayerID : Integer): Single;');
  Sender.AddMethod(Self, @TfrmMain.SetPlayerAngle,'procedure SetPlayerAngle(PlayerID : Integer;Angle : Single);');
  Sender.AddMethod(Self, @TfrmMain.SetPlayerMoney,'procedure SetPlayerMoney(PlayerID, Money : Integer);');
  Sender.AddMethod(Self, @TfrmMain.GetPlayerMoney,'function GetPlayerMoney(PlayerID : Integer): Integer;');
  Sender.AddMethod(Self, @TfrmMain.SetPlayerFreeze,'procedure SetPlayerFreeze(PlayerID : Integer;State : Boolean);');
  Sender.AddMethod(Self, @TfrmMain.GetPlayerFreeze,'function GetPlayerFreeze(PlayerID : Integer): Boolean;');
  Sender.AddMethod(Self, @TfrmMain.SetPlayerHealth,'procedure SetPlayerHealth(PlayerID : Integer;Health : Single);');
  Sender.AddMethod(Self, @TfrmMain.GetPlayerHealth,'function GetPlayerHealth(PlayerID : Integer): Single;');

  Sender.AddMethod(Self, @TfrmMain.SendTextToPlayer,'procedure SendTextToPlayer(PlayerID: Integer; Mssg : String);');
  Sender.AddMethod(Self, @TfrmMain.SendTextToAllExceptPlayer,'procedure SendTextToAllExceptPlayer(PlayerID : Integer; Mssg : String);');
  Sender.AddMethod(Self, @TfrmMain.SendTextToAll,'procedure SendTextToAll(Mssg : String);');


  Sender.AddMethod(Self, @TfrmMain.DisplayTextAll,'procedure DisplayTextAll(Style : Integer; Mssg : String; Time : Integer);');
  Sender.AddMethod(Self, @TfrmMain.DisplayTextPlayer,'procedure DisplayTextPlayer(PlayerID, Style : Integer; Mssg : String; Time : Integer);');

  Sender.AddMethod(Self, @TfrmMain.GetDeathReason,'function GetDeathReason(ReasonID : Integer): String;');

  Sender.AddMethod(Self, @TfrmMain.SetWeapon,'procedure SetWeapon(WeaponID, WeaponModelID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.CopyBetween,'function CopyBetween(Source, bs, es : String): String;');
  Sender.AddMethod(Self, @TfrmMain.CopyAfter,'function CopyAfter(Source, bs : String): String;');
  Sender.AddMethod(Self, @TfrmMain.CopyBefore,'function CopyBefore(Source, bs : String): String;');

  Sender.AddMethod(Self, @TfrmMain.Timer,'procedure Timer(Seconds : Integer; Execute : String);');

  Sender.AddMethod(Self, @TfrmMain.KickPlayer,'procedure KickPlayer(PlayerID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.BanPlayer,'procedure BanPlayer(PlayerID : Integer);');


  Sender.AddMethod(Self, @TfrmMain.IsPlayerIngame,'function IsPlayerIngame(PlayerID : Integer): Boolean;');
  Sender.AddMethod(Self, @TfrmMain.KillPlayer,'procedure KillPlayer(PlayerID : Integer);');



  //Sender.AddMethod(Self, @TfrmMain.StrSplit,'function StrSplit(const Source, Delimiter: String): Array of String;');
end;

procedure TfrmMain.tmrTimersTimer(Sender: TObject);
var
  i, Int : Integer;
begin
  If (lstTimers.Count = 0) Then
    Exit;
  For i := Pred(lstTimers.Count) DownTo 0 Do
  Begin
    If (CopyBefore(lstTimers.Items[i],' ') = '0') Then
    Begin
      Ce.ExecuteFunction([],CopyAfter(lstTimers.Items[i],' '));
      lstTimers.Items.Delete(i);
    End
    Else
    Begin
      Int := StrToInt(CopyBefore(lstTimers.Items[i],' '))-1;
      lstTimers.Items[i] := IntToStr(Int) +' '+ CopyAfter(lstTimers.Items[i],' ');
    End;
  End;
end;

end.
