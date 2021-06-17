unit untMain;

interface                                                                                                       

uses INIFiles, ExtCtrls, uPSComponent, IdHTTP, IdTCPConnection, Windows,
  IdTCPClient, IdIRC, IdBaseComponent, IdComponent, IdTCPServer, StdCtrls,
  Forms, MD5, Controls, Classes, uPSComponent_Default, Dialogs, SysUtils;



type
  TSplitArray = array of String;
  PClient = ^TClient;
  TClient = record
    DNS : String[250];
    IP : String[250];
    Connected, LastAction  : TDateTime;
    Thread : Pointer;
  end;

  TtObject = record
    InUse : Boolean;
    Model : Integer;
    PosX,
    PosY,
    PosZ,
    RotX,
    RotY,
    RotZ : Single;
  end;

  TPickup = record
    InUse : Boolean;
    model : Integer;
    PosX,
    PosY,
    PosZ : Single;
  end;

  TSTimer = record
    InUse : Boolean;
    Time : Integer;
    Command : String;
  end;

  TSpawn = record
    InUse : Boolean;
    PosX,
    PosY,
    PosZ,
    Rot : Single;
  end;

  TCar = record
    InUse : Boolean;
    Model : Integer;
    sPosX,
    sPosY,
    sPosZ,
    PosX,
    PosY,
    PosZ,
    Rot : Single;
    Color1,
    Color2 : Integer;
    Plate : String[9];
  end;

  TMarker = record
    InUse : Boolean;
    PosX,
    PosY,
    PosZ : Single;
  end;

  TMsgBlock = record
    Command : String[4];
    Mssg : String[100];
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
  end;
  TfrmMain = class(TForm)
    Server: TIdTCPServer;
    lblInfo: TLabel;
    lstBans: TListBox;
    lstLog: TMemo;
    IRC: TIdIRC;
    edtLogText: TEdit;
    btnLogSend: TButton;
    HTTP: TIdHTTP;
    Ce: TPSScript;
    Query: TIdTCPServer;
    tmrTimeSync: TTimer;
    tmrMasterServer: TTimer;

    procedure FormCreate(Sender: TObject);
    procedure ServerConnect(AThread: TIdPeerThread);
    procedure ServerDisconnect(AThread: TIdPeerThread);
    procedure ServerExecute(AThread: TIdPeerThread);
    procedure DisconnectPlayer(PlayerID : Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnLogSendClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure edtLogTextKeyPress(Sender: TObject; var Key: Char);
    procedure Log(Mssg : String);
    procedure CeCompile(Sender: TPSScript);
    procedure AddSpawn(PosX, PosY, PosZ, Rotation : Single);
    procedure AddObject(ModelID : Integer; PosX, PosY, PosZ, RotX, RotY, RotZ : Single);
    procedure AddVehicle(ModelID: Integer; PosX, PosY, PosZ, Rotation : Single;Color1, Color2 : Integer);
    procedure AddCheckpoint(PlayerID : Integer;PosX, PosY, PosZ, Radius : Single);
    procedure DeleteCheckpoint(PlayerID, i: Integer);
    function  AddCheckpointEx(PlayerID : Integer;PosX, PosY, PosZ, Radius : Single): Integer;
    procedure DeleteVehicle(i: Integer);
    function  AddVehicleEx(ModelID: Integer; PosX, PosY, PosZ, Rotation : Single;Color1, Color2 : Integer): Integer;
    function  IsPlayerAdmin(PlayerID : Integer): Boolean;
    function  IsPlayerConnected(PlayerID : Integer): Boolean;
    function  GetPlayerNick(PlayerID : Integer): String;
    function  GetHour(): Integer;
    function  GetMinute(): Integer;
    function  GetWeather(): Integer;
    function  GetPlayerInterior(PlayerID : Integer): Integer;
    function  GetPlayerAngle(PlayerID : Integer): Single;
    procedure SetPlayerAngle(PlayerID : Integer;Angle : Single);
    function  GetPlayerHealth(PlayerID : Integer): Single;
    procedure SetPlayerHealth(PlayerID : Integer;Health : Single);
    procedure SetPlayerInterior(PlayerID, InteriorID : Integer);
    function  GetPlayerPosX(PlayerID : Integer): Single;
    function  GetVehicleName(Car : Integer): String;
    function  GetPlayerPosY(PlayerID : Integer): Single;
    function  GetPlayerPosZ(PlayerID : Integer): Single;
    procedure SetPlayerPos(PlayerID : Integer; PosX, PosY, PosZ : Single);
    procedure SetPlayerFreeze(PlayerID : Integer;State : Boolean);
    function  GetPlayerFreeze(PlayerID : Integer): Boolean;
    procedure AddHealthPickup(PosX, PosY, PosZ : Single);
    procedure AddArmorPickup(PosX, PosY, PosZ : Single);
    procedure SetPlayerColor(PlayerID, Color : Integer);
    procedure SendTextToAll(Mssg : String);
    procedure SendTextToAllExceptPlayer(PlayerID : Integer; Mssg : String);
    procedure SendTextToPlayer(PlayerID : Integer; Mssg : String);
    //procedure AddVehicleRepair(PosX, PosY, PosZ : Single);
    procedure DisplayTextPlayer(PlayerID, Style: Integer; Mssg : String; Time : Integer);
    procedure DisplayTextAll(Style : Integer; Mssg : String; Time : Integer);
    procedure SetPlayerMoney(PlayerID, Money : Integer);
    function  GetPlayerMoney(PlayerID : Integer): Integer;
    procedure SetTime(Hour, Minute : Integer);
    procedure SetWeather(WeatherID : Integer);
    function  GetPlayerID(Nick : String): Integer;
    function  GetDeathReason(ReasonID : Integer): String;
    function  StrSplit(const Source, Delimiter: String): TSplitArray;
    procedure SendDataToPlayer(PlayerID : Integer;CommBlock : TCommBlock);
    procedure SendDataToAllExceptPlayer(PlayerID : Integer;CommBlock : TCommBlock);
    procedure SendDataToAll(CommBlock : TCommBlock);
    procedure SetWeapon(WeaponID : Integer);
    procedure SetPlayerWeapon(PlayerID, WeaponID : Integer);
    procedure KillPlayer(PlayerID : Integer);
    procedure BanPlayer(PlayerID : Integer);
    procedure KickPlayer(PlayerID : Integer);
    procedure SetPlayerAnimation(PlayerID, AnimationID : Integer);
    function  IsPlayerIngame(PlayerID : Integer): Boolean;
    function  GetMaxSlots(): Integer;
    function  GetPlayerIP(PlayerID : Integer): String;
    function  CopyBetween(Source, bs, es : String): String;
    function  CopyAfter(Source, bs : String): String;
    function  CopyBefore(Source, bs : String): String;
    procedure Timer(Seconds : Integer; Execute : String);
    procedure OnQueryExecute(AThread: TIdPeerThread);
    procedure IRCSay(Mssg : String);
    procedure IRCJoin(Sender: TObject; AUser: TIdIRCUser;
      AChannel: TIdIRCChannel);
    procedure IRCPart(Sender: TObject; AUser: TIdIRCUser;
      AChannel: TIdIRCChannel);
    procedure IRCNotice(Sender: TObject; AUser: TIdIRCUser;
      AChannel: TIdIRCChannel; Content: String);
    procedure OnIRCMessage(Sender: TObject; AUser: TIdIRCUser;
      AChannel: TIdIRCChannel; Content: String);
    procedure OnTimeSync(Sender: TObject);
    procedure SetGravity(Grav : Integer);
    procedure SetFly(Enabled : Boolean);
    procedure SetWaterWaveHeight(Height : Single);
    procedure SetWaterHeight(Height : Single);
    procedure SyncOnSpawn(PlayerID : Integer);
    procedure UnderWaterWalk(Switch : Boolean);
    procedure SetVehicleHealth(VehicleID : Integer; Health : Single);
    procedure SetVehicleDoorsLocked(PlayerID, Vehicle : Integer; Locked : Boolean);
    procedure ResetCamera(PlayerID: Integer);
    procedure PointCameraAt(PlayerID : Integer; X, Y, Z : Single);
    procedure SetCamera(PlayerID : Integer; X, Y, Z : Single);
    procedure BurnPlayer(PlayerID : Integer);
    procedure PlaySound(PlayerID, SoundID : Integer);
    procedure SetVehiclePosition(VehicleID : Integer; X, Y, Z : Single);
    procedure ExplodeVehicle(VehicleID : Integer);
    procedure RespawnVehicle(VehicleID : Integer);
    procedure ResetPlayerWeapons(PlayerID : Integer);
    procedure CreateExplosion(X, Y, Z : Single);
    procedure RepairVehicle(VehicleID : Integer);
    function  calcMD5(Buffer : String): String;
    function  INIRead(FileName, Section, Ident, Default : String): String;
    procedure INIWrite(FileName, Section, Ident, Value : String);
    function  ScriptFileExists(FileName : String): Boolean;
    function  GetTicks(): Integer;
    procedure SetPlayerAdmin(PlayerID : Integer; Value : Boolean);
    function  GetPlayerArmor(PlayerID : Integer): Single;
    procedure SetPlayerArmor(PlayerID : Integer; Armor : Single);
    function  IsInteger(s: string): boolean;
    function  IsFloat(S: String): Boolean;
    procedure AllowPlayerToJump(PlayerID : Integer; Toggle : Boolean);
    procedure AllowPlayerToShoot(PlayerID : Integer; Toggle : Boolean);
    procedure AllowPlayerToChangeWeapon(PlayerID : Integer; Toggle : Boolean);
    procedure SetPlayerCrouch(PlayerID : Integer; Toggle : Boolean);
    procedure UndoLastWeaponDamage(PlayerID : Integer);
    procedure SetPlayerArmedWeapon(PlayerID, WeaponID : Integer);
    procedure OnMasterServerHeartbeat(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;
  Clients : TThreadList;
  Version, MasterServerIP, VersionHash, IRCChannel, IRCChanPass,
  ServerPass, AdminPass, ServerName : String;
  INI : TINIFile;
  ID, Port, PInterior, PMoney, PCar, PCar2 : Array of Integer;
  PFreeze : Array of Boolean;
  Slot, SyncSpawn, IsAdmin, IsIngame, IsIngameL : Array of Boolean;
  Nick, IP : Array of String;
  PPosX, PPosY, PPosZ, PRotation, PHealth, PArmor : Array of Single;
  Hdl : Array of Cardinal;
  gWaterWaveHeight, gWaterHeight : Single;
  Cars : Array of TCar;
  Spawns : Array of TSpawn;
  Objects : Array of TtObject;
  Pickups : Array of TPickup;
  Markers : Array of TMarker;
  Timers : Array of TSTimer;
  Ticks : Array of Integer;
  ScriptFile : TextFile;

  UniqueObjectID, PlayersConnected, HARDCODED_MAX_PLAYERS, HARDCODED_MIN_PLAYERS,
  Slots, MasterserverH, Admins, Players, StartTicks,
  gHour, gGravity, gFly, gUnderWater, gMinute, gPickups, gWeather, gSpawnedVehicles,
  gSpawns, gSpawnedObjects, gPlayers, BansTimer : Integer;

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
  Else If (WeaponID = 10) Then
    Result := 'Purple Dildo'
  Else If (WeaponID = 11) Then
    Result := 'White Dildo'
  Else If (WeaponID = 12) Then
    Result := 'Vibrator 1'
  Else If (WeaponID = 13) Then
    Result := 'Vibrator 2'
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
    Result := 'Nightvision Goggles'
  Else If (WeaponID = 45) Then
    Result := 'Infrared Goggles'
  Else
    Result := 'Unknown - ID '+ IntToStr(WeaponID);
end;

function TfrmMain.GetVehicleName(Car : Integer): String;
begin
  If (Car = 400) Then
    result := 'Landstalker'
  Else If (Car = 401) Then
    result := 'Bravura'
  Else If (Car = 402) Then
    result := 'Buffalo'
  Else If (Car = 403) Then
    result := 'Linerunner'
  Else If (Car = 404) Then
    result := 'Perennial'
  Else If (Car = 405) Then
    result := 'Sentinel'
  Else If (Car = 406) Then
    result := 'Dumper'
  Else If (Car = 407) Then
    result := 'Fire Truck'
  Else If (Car = 408) Then
    result := 'Trashmaster'
  Else If (Car = 409) Then
    result := 'Stretch'
  Else If (Car = 410) Then
    result := 'Manana'
  Else If (Car = 411) Then
    result := 'Infernus'
  Else If (Car = 412) Then
    result := 'Voodoo'
  Else If (Car = 413) Then
    result := 'Pony'
  Else If (Car = 414) Then
    result := 'Mule'
  Else If (Car = 415) Then
    result := 'Cheetah '
  Else If (Car = 416) Then
    result := 'Ambulance'
  Else If (Car = 417) Then
    result := 'Leviathan'
  Else If (Car = 418) Then
    result := 'Moonbeam'
  Else If (Car = 419) Then
    result := 'Esperanto'
  Else If (Car = 420) Then
    result := 'Taxi'
  Else If (Car = 421) Then
    result := 'Washington'
  Else If (Car = 422) Then
    result := 'Bobcat'
  Else If (Car = 423) Then
    result := 'Mr. Whoopee'
  Else If (Car = 424) Then
    result := 'BF Injection'
  Else If (Car = 425) Then
    result := 'Hunter'
  Else If (Car = 426) Then
    result := 'Premier'
  Else If (Car = 427) Then
    result := 'Enforcer'
  Else If (Car = 428) Then
    result := 'Securicar'
  Else If (Car = 429) Then
    result := 'Banshee'
  Else If (Car = 430) Then
    result := 'Predator '
  Else If (Car = 431) Then
    result := 'Bus'
  Else If (Car = 432) Then
    result := 'Rhino'
  Else If (Car = 433) Then
    result := 'Barracks'
  Else If (Car = 434) Then
    result := 'Hotknife'
  Else If (Car = 435) Then
    result := 'ARTICT1'
  Else If (Car = 436) Then
    result := 'Previon'
  Else If (Car = 437) Then
    result := 'Coach'
  Else If (Car = 438) Then
    result := 'Cabbie'
  Else If (Car = 439) Then
    result := 'Stallion'
  Else If (Car = 440) Then
    result := 'Rumpo'
  Else If (Car = 441) Then
    result := 'RC Bandit'
  Else If (Car = 442) Then
    result := 'Romero'
  Else If (Car = 443) Then
    result := 'Packer'
  Else If (Car = 444) Then
    result := 'Monster'
  Else If (Car = 445) Then
    result := 'Admiral'
  Else If (Car = 446) Then
    result := 'Squalo'
  Else If (Car = 447) Then
    result := 'Seasparrow'
  Else If (Car = 448) Then
    result := 'Pizza Boy'
  Else If (Car = 449) Then
    result := 'Trolly'
  Else If (Car = 450) Then
    result := 'ARTICT2'
  Else If (Car = 451) Then
    result := 'Turismo'
  Else If (Car = 452) Then
    result := 'Speeder'
  Else If (Car = 453) Then
    result := 'Reefer'
  Else If (Car = 454) Then
    result := 'Tropic'
  Else If (Car = 455) Then
    result := 'Flatbed'
  Else If (Car = 456) Then
    result := 'Yankee'
  Else If (Car = 457) Then
    result := 'Caddy'
  Else If (Car = 458) Then
    result := 'Solair'
  Else If (Car = 459) Then
    result := 'Berkley''s RC Van'
  Else If (Car = 460) Then
    result := 'Skimmer'
  Else If (Car = 461) Then
    result := 'PCJ600'
  Else If (Car = 462) Then
    result := 'Faggio'
  Else If (Car = 463) Then
    result := 'Freeway'
  Else If (Car = 464) Then
    result := 'RC Baron'
  Else If (Car = 465) Then
    result := 'RC Raider'
  Else If (Car = 466) Then
    result := 'Glendale'
  Else If (Car = 467) Then
    result := 'Oceanic'
  Else If (Car = 468) Then
    result := 'Sanchez'
  Else If (Car = 469) Then
    result := 'Sparrow'
  Else If (Car = 470) Then
    result := 'Patriot'
  Else If (Car = 471) Then
    result := 'Quadbike'
  Else If (Car = 472) Then
    result := 'Coastguard'
  Else If (Car = 473) Then
    result := 'Dinghy'
  Else If (Car = 474) Then
    result := 'Hermes'
  Else If (Car = 475) Then
    result := 'Sabre'
  Else If (Car = 476) Then
    result := 'Rustler'
  Else If (Car = 477) Then
    result := 'ZR-350'
  Else If (Car = 478) Then
    result := 'Walton'
  Else If (Car = 479) Then
    result := 'Regina '
  Else If (Car = 480) Then
    result := 'Comet'
  Else If (Car = 481) Then
    result := 'Bmx'
  Else If (Car = 482) Then
    result := 'Burrito'
  Else If (Car = 483) Then
    result := 'Camper'
  Else If (Car = 484) Then
    result := 'Marquis'
  Else If (Car = 485) Then
    result := 'Baggage'
  Else If (Car = 486) Then
    result := 'Dozer'
  Else If (Car = 487) Then
    result := 'Maverick'
  Else If (Car = 488) Then
    result := 'News Chopper'
  Else If (Car = 489) Then
    result := 'Rancher'
  Else If (Car = 490) Then
    result := 'FBI Rancher'
  Else If (Car = 491) Then
    result := 'Virgo'
  Else If (Car = 492) Then
    result := 'Greenwood'
  Else If (Car = 493) Then
    result := 'Jetmax'
  Else If (Car = 494) Then
    result := 'Hotring Racer'
  Else If (Car = 495) Then
    result := 'Sandking'
  Else If (Car = 496) Then
    result := 'Blista Compact'
  Else If (Car = 497) Then
    result := 'Police Maverick'
  Else If (Car = 498) Then
    result := 'Boxville'
  Else If (Car = 499) Then
    result := 'Benson'
  Else If (Car = 500) Then
    result := 'MESAA'
  Else If (Car = 501) Then
    result := 'RC Goblin'
  Else If (Car = 502) Then
    result := 'Hotring Racer'
  Else If (Car = 503) Then
    result := 'Hotring Racer'
  Else If (Car = 504) Then
    result := 'Bloodring Banger'
  Else If (Car = 505) Then
    result := 'Rancher'
  Else If (Car = 506) Then
    result := 'Super GT'
  Else If (Car = 507) Then
    result := 'Elegant'
  Else If (Car = 508) Then
    result := 'Journey'
  Else If (Car = 509) Then
    result := 'Bike'
  Else If (Car = 510) Then
    result := 'Mountain Bike'
  Else If (Car = 511) Then
    result := 'Beagle'
  Else If (Car = 512) Then
    result := 'Cropduster'
  Else If (Car = 513) Then
    result := 'Stuntplane'
  Else If (Car = 514) Then
    result := 'Linerunner'
  Else If (Car = 515) Then
    result := 'Roadtrain'
  Else If (Car = 516) Then
    result := 'NEBULA'
  Else If (Car = 517) Then
    result := 'Majestic'
  Else If (Car = 518) Then
    result := 'Buccaneer'
  Else If (Car = 519) Then
    result := 'Shamal'
  Else If (Car = 520) Then
    result := 'Hydra'
  Else If (Car = 521) Then
    result := 'FCR-900'
  Else If (Car = 522) Then
    result := 'NRG-500'
  Else If (Car = 523) Then
    result := 'HPV1000'
  Else If (Car = 524) Then
    result := 'Cement Truck'
  Else If (Car = 525) Then
    result := 'Towtruck'
  Else If (Car = 526) Then
    result := 'Fortune'
  Else If (Car = 527) Then
    result := 'Cadrona'
  Else If (Car = 528) Then
    result := 'FBI Truck'
  Else If (Car = 529) Then
    result := 'Willard'
  Else If (Car = 530) Then
    result := 'Forklift'
  Else If (Car = 531) Then
    result := 'Tractor'
  Else If (Car = 532) Then
    result := 'Combine Harvester'
  Else If (Car = 533) Then
    result := 'Feltzer'
  Else If (Car = 534) Then
    result := 'Remington'
  Else If (Car = 535) Then
    result := 'Slamvan'
  Else If (Car = 536) Then
    result := 'Blade'
  Else If (Car = 537) Then
    result := 'Freight'
  Else If (Car = 538) Then
    result := 'Brown Streak Engine'
  Else If (Car = 539) Then
    result := 'Vortex'
  Else If (Car = 540) Then
    result := 'Vincent'
  Else If (Car = 541) Then
    result := 'Bullet'
  Else If (Car = 542) Then
    result := 'Clover '
  Else If (Car = 543) Then
    result := 'Sadler'
  Else If (Car = 544) Then
    result := 'Fire Truck'
  Else If (Car = 545) Then
    result := 'Hustler'
  Else If (Car = 546) Then
    result := 'Intruder'
  Else If (Car = 547) Then
    result := 'Primo'
  Else If (Car = 548) Then
    result := 'Cargobob'
  Else If (Car = 549) Then
    result := 'Tampa'
  Else If (Car = 550) Then
    result := 'Sunrise'
  Else If (Car = 551) Then
    result := 'Merit'
  Else If (Car = 552) Then
    result := 'Utility Van'
  Else If (Car = 553) Then
    result := 'Nevada'
  Else If (Car = 554) Then
    result := 'Yosemite'
  Else If (Car = 555) Then
    result := 'Windsor'
  Else If (Car = 556) Then
    result := 'MONSTA'
  Else If (Car = 557) Then
    result := 'Monster'
  Else If (Car = 558) Then
    result := 'Uranus'
  Else If (Car = 559) Then
    result := 'Jester'
  Else If (Car = 560) Then
    result := 'Sultan'
  Else If (Car = 561) Then
    result := 'Stratum'
  Else If (Car = 562) Then
    result := 'Elegy'
  Else If (Car = 563) Then
    result := 'Raindance'
  Else If (Car = 564) Then
    result := 'RC Tiger'
  Else If (Car = 565) Then
    result := 'Flash'
  Else If (Car = 566) Then
    result := 'Tahoma'
  Else If (Car = 567) Then
    result := 'Savanna'
  Else If (Car = 568) Then
    result := 'Bandito'
  Else If (Car = 569) Then
    result := 'FRFLAT'
  Else If (Car = 570) Then
    result := 'streakc'
  Else If (Car = 571) Then
    result := 'Kart'
  Else If (Car = 572) Then
    result := 'Mower'
  Else If (Car = 573) Then
    result := 'Dune'
  Else If (Car = 574) Then
    result := 'Sweeper'
  Else If (Car = 575) Then
    result := 'Broadway'
  Else If (Car = 576) Then
    result := 'Tornado'
  Else If (Car = 577) Then
    result := 'AT-400'
  Else If (Car = 578) Then
    result := 'DFT-30'
  Else If (Car = 579) Then
    result := 'Huntley'
  Else If (Car = 580) Then
    result := 'Stafford'
  Else If (Car = 581) Then
    result := 'BF-400'
  Else If (Car = 582) Then
    result := 'News Van'
  Else If (Car = 583) Then
    result := 'Tug'
  Else If (Car = 584) Then
    result := 'PETROTR'
  Else If (Car = 585) Then
    result := 'Emperor'
  Else If (Car = 586) Then
    result := 'Wayfarer'
  Else If (Car = 587) Then
    result := 'Euros'
  Else If (Car = 588) Then
    result := 'Hotdog'
  Else If (Car = 589) Then
    result := 'Club'
  Else If (Car = 590) Then
    result := 'FRBOX'
  Else If (Car = 591) Then
    result := 'ARTICT3'
  Else If (Car = 592) Then
    result := 'Andromada'
  Else If (Car = 593) Then
    result := 'Dodo'
  Else If (Car = 594) Then
    result := 'RC Cam'
  Else If (Car = 595) Then
    result := 'Launch'
  Else If (Car = 596) Then
    result := 'Police Car'
  Else If (Car = 597) Then
    result := 'Police Car'
  Else If (Car = 598) Then
    result := 'Police Car'
  Else If (Car = 599) Then
    result := 'Police Ranger'
  Else If (Car = 600) Then
    result := 'Picador'
  Else If (Car = 601) Then
    result := 'S.W.A.T.'
  Else If (Car = 602) Then
    result := 'Alpha'
  Else If (Car = 603) Then
    result := 'Phoenix'
  Else If (Car = 604) Then
    result := 'Glendale'
  Else If (Car = 605) Then
    result := 'Sadler'
  Else If (Car = 606) Then
    result := 'BAGBOXA'
  Else If (Car = 607) Then
    result := 'BAGBOXB'
  Else If (Car = 608) Then
    result := 'TUGSTAI'
  Else If (Car = 609) Then
    result := 'Boxville'
  Else If (Car = 610) Then
    result := 'FARMTR1'
  Else If (Car = 611) Then
    result := 'UTILTR1'
  Else
    result := 'Unknown';
end;

procedure TfrmMain.Log(Mssg : String);
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

const
  c1 = 52845;
  c2 = 22719;


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
  HARDCODED_MAX_PLAYERS := 33;     // max players +1
  HARDCODED_MIN_PLAYERS := 0;      // gewoon 0 houden
  Version := '0.3.0.0';
  MasterServerIP := '84.16.249.242';
  gHour := 12;
  gMinute := 0;
  gGravity := 100;
  gFly := 0;
  gUnderWater := 0;
  gWaterWaveHeight := 10.0;
  gWaterHeight := 5.0;
  frmMain.Caption := 'San Andreas Party '+Version+' Server';
  INI := TINIFile.Create(GetCurrentDir + '\settings.ini');

  ServerName := INI.ReadString('SERVER','servername','Unnamed SAP server');
  If (Length(ServerName) > 65) Then
  Begin
    Err('Server name too long, limit is 65 characters.');
    Application.Terminate;
    Exit;
  End;

  ServerPass := INI.ReadString('SERVER','password','');

  Admins := INI.ReadInteger('ADMIN','enabled',0);
  If not (Admins = 1) and not (Admins = 0) Then
  Begin
    Err('Admin system must be 1 for ON and 0 for OFF.');
    Application.Terminate;
    Exit;
  End;

  AdminPass := INI.ReadString('ADMIN','password','changeme');
  AdminPass := StringReplace(AdminPass, '|', '.',[rfReplaceAll, rfIgnoreCase]);
  If not (Length(AdminPass) = 32) Then
  Begin
    AdminPass := calcMD5(AdminPass);
    INI.WriteString('ADMIN','password',AdminPass);
  End;

  Slots := INI.ReadInteger('SERVER','slots',HARDCODED_MAX_PLAYERS-1);
  If (Slots > HARDCODED_MAX_PLAYERS-1) or (Slots < 2) Then
  Begin
    Err('Minimum: 2 slots - Maximum '+IntToStr(HARDCODED_MAX_PLAYERS-1)+' slots (Currently: '+ IntToStr(Slots) +').');
    Application.Terminate;
    Exit;
  End;

  If ( FileExists(GetCurrentDir + '\bans.lst') ) Then
    lstBans.Items.LoadFromFile(GetCurrentDir + '\bans.lst');

  Server.DefaultPort := INI.ReadInteger('SERVER','port',8070);
  Query.DefaultPort := Server.DefaultPort+1;
  SetLength(Slot,HARDCODED_MAX_PLAYERS);
  SetLength(Nick,HARDCODED_MAX_PLAYERS);
  SetLength(ID,HARDCODED_MAX_PLAYERS);
  SetLength(Port,HARDCODED_MAX_PLAYERS);
  SetLength(IP,HARDCODED_MAX_PLAYERS);
  SetLength(SyncSpawn,HARDCODED_MAX_PLAYERS);
  SetLength(Hdl,HARDCODED_MAX_PLAYERS);
  SetLength(IsAdmin,HARDCODED_MAX_PLAYERS);
  SetLength(IsIngame,HARDCODED_MAX_PLAYERS);
  SetLength(IsIngameL,HARDCODED_MAX_PLAYERS);
  SetLength(PPosX,HARDCODED_MAX_PLAYERS);
  SetLength(PPosY,HARDCODED_MAX_PLAYERS);
  SetLength(PPosZ,HARDCODED_MAX_PLAYERS);
  SetLength(PRotation,HARDCODED_MAX_PLAYERS);
  SetLength(PInterior,HARDCODED_MAX_PLAYERS);
  SetLength(PMoney,HARDCODED_MAX_PLAYERS);
  SetLength(PCar,HARDCODED_MAX_PLAYERS);
  SetLength(PCar2,HARDCODED_MAX_PLAYERS);
  SetLength(PFreeze,HARDCODED_MAX_PLAYERS);
  SetLength(PHealth,HARDCODED_MAX_PLAYERS);
  SetLength(PArmor,HARDCODED_MAX_PLAYERS);

  SetLength(Cars,2000);
  SetLength(Spawns,1000);
  SetLength(Objects,1000);
  SetLength(Markers,1000);
  SetLength(Timers,50);
  SetLength(Ticks,450); // 400 eigenlijk

  For i := 1 To HARDCODED_MAX_PLAYERS-1 Do
  Begin
    Slot[i] := False;
    Nick[i] := '';
    SyncSpawn[i] := True;
  End;

  Try
    Server.Active := True;
  Except
    Err('Port '+IntToStr(Server.DefaultPort)+' already used.');
    Application.Terminate;
    Exit;
  End;
  Try
    Query.Active := True;
  Except
    Err('Port '+IntToStr(Query.DefaultPort)+' already used.');
    Application.Terminate;
    Exit;
  End;

  // IRC echo
  IRC.Host := INI.ReadString('IRC','host','irc.gtanet.com');
  IRC.Port := INI.ReadInteger('IRC','port',6667);
  IRC.Nick := INI.ReadString('IRC','nick','SAP-Server');
  IRC.AltNick := INI.ReadString('IRC','nick','SAPServer');
  IRC.RealName := 'San Andreas Party Server '+Version;
  IRCChannel := INI.ReadString('IRC','channel','#bots');
  IRCChanPass := INI.ReadString('IRC', 'channelpassword', '');
  Clients := TThreadList.Create;
  tmrTimeSync.Enabled := True;

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
  For i := 1 To HARDCODED_MAX_PLAYERS-1 Do
  Begin
    If (AThread.Handle = Hdl[i]) and (Slot[i] = True) Then
    Begin
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
        For i2 := 1 To HARDCODED_MAX_PLAYERS-1 Do
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
        If (RecThread.Handle = Hdl[PlayerID]) Then
        Begin
          RecThread.Connection.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
        End;
      End;
    Finally
      Clients.UnlockList;
    End;
  End;
end;

procedure TfrmMain.DisconnectPlayer(PlayerID : Integer);
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
        If (RecThread.Handle = Hdl[PlayerID]) Then
        Begin
          RecThread.Connection.Destroy;
        End;
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
          If not (RecThread.Handle = Hdl[PlayerID]) Then
          Begin
            RecThread.Connection.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
          End;
      End;
    Finally
      Clients.UnlockList;
    End;
  End;
end;

procedure TfrmMain.SyncOnSpawn(PlayerID : Integer);
var
  CB : TCommBlock;
begin
    CB.Command := 'TIME';
    CB.Nick := 'Server';
    CB.Interior := gHour;
    CB.Car := gMinute;
    SendDataToPlayer(PlayerID, CB); // tijd
    CB.Command := 'WEATH';
    CB.Nick := 'Server';
    CB.Interior := gWeather;
    SendDataToPlayer(PlayerID, CB); //weer
    CB.Command := 'GRAV';
    CB.Nick := 'Server';
    CB.PosX := gGravity * 0.00008;
    SendDataToPlayer(PlayerID, CB); // gravity
    CB.Command := 'FLY';
    CB.Nick := 'Server';
    CB.Interior := gFly;
    SendDataToPlayer(PlayerID, CB); // flying cars
    CB.Command := 'UW';
    CB.Nick := 'Server';
    CB.Interior := gUnderWater;
    SendDataToPlayer(PlayerID, CB); // under water sync
    {
    CB.Command := 'WH';
    CB.Nick := 'Server';
    CB.PosX := gWaterHeight;
    SendDataToPlayer(PlayerID, CB); // water height
    CB.Command := 'WWH';
    CB.Nick := 'Server';
    CB.PosX := gWaterWaveHeight;
    SendDataToPlayer(PlayerID, CB); // water waves height
    }

end;

procedure TfrmMain.ServerExecute(AThread: TIdPeerThread);
var
  RecClient, ActClient : PClient;
  CommBlock, CommBlock2 : TCommBlock;
  RecThread : TIdPeerThread;
  i, i2, PlayID, Done, Int : Integer;
  Arr : TSplitArray;
begin
  Arr := Split('test|aap','|');
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
    begin
      PHealth[CommBlock.PlayerID] := CommBlock.XC;
      PArmor[CommBlock.PlayerID] := CommBlock.YA;
    end;
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
    Exit;
  End
  Else If (CommBlock.Command = 'SYNC2') Then
  Begin
    PMoney[CommBlock.PlayerID] := CommBlock.Roll2;
    Exit;
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
    Exit;
  End
  Else If (CommBlock.Command = 'CPIN') Then
  Begin
    Ce.ExecuteFunction([CommBlock.PlayerID,CommBlock.Interior],'OnPlayerEnterCheckpoint');
    Exit;
  End
  Else If (CommBlock.Command = 'CPOUT') Then
  Begin
    Ce.ExecuteFunction([CommBlock.PlayerID,CommBlock.Interior],'OnPlayerLeaveCheckpoint');
    Exit;
  End
  Else If (CommBlock.Command = 'DMAP') Then
  Begin
      CommBlock2.Command := 'NMP';

      // Spawnpoints
      For i := 1 To High(Spawns) Do
      Begin
        If (Spawns[i].InUse = True) Then
        begin
          CommBlock2.Mssg := 's|'+ FormatFloat('0.000',Spawns[i].PosX) +'|'+ FormatFloat('0.000',Spawns[i].PosY) +'|'+ FormatFloat('0.000',Spawns[i].PosZ) +'|'+ FormatFloat('0.000',Spawns[i].Rot);
          AThread.Connection.WriteBuffer(CommBlock2,SizeOf(CommBlock2),True);
        end;
        Application.ProcessMessages;
      end;

      // objects
      For i := 1 To High(Objects) Do
      Begin
        If (Objects[i].InUse = True) Then
        begin
          CommBlock2.Mssg := 'o|'+ IntToStr(Objects[i].Model) +'|'+ FormatFloat('0.000',Objects[i].PosX) +'|'+ FormatFloat('0.000',Objects[i].PosY) +'|'+ FormatFloat('0.000',Objects[i].PosZ) +'|'+ FormatFloat('0.000',Objects[i].RotX) +'|'+ FormatFloat('0.000',Objects[i].RotY) +'|'+ FormatFloat('0.000',Objects[i].RotZ);
          AThread.Connection.WriteBuffer(CommBlock2,SizeOf(CommBlock2),True);
        end;
        Application.ProcessMessages;
      end;

      // cars
      For i := 1 To High(Cars) Do
      Begin
        If (Cars[i].InUse = True) Then
        begin
          CommBlock2.Mssg := 'v|'+IntToStr(i)+'|'+IntToStr(Cars[i].Model)+'|'+FormatFloat('0.000',Cars[i].PosX)+'|'+FormatFloat('0.000',Cars[i].PosY)+'|'+FormatFloat('0.000',Cars[i].PosZ)+'|'+ FormatFloat('0.000',Cars[i].Rot) +'|'+ IntToStr(Cars[i].Color1) +'|'+ IntToStr(Cars[i].Color1);
          AThread.Connection.WriteBuffer(CommBlock2,SizeOf(CommBlock2),True);
        end;
        Application.ProcessMessages;
      end;

      // pickups
      For i := 1 To High(Pickups) Do
      Begin
        If (Pickups[i].InUse = True) Then
        begin
          if (Pickups[i].model = 1) Then
            CommBlock2.Mssg := 'h|'+ FormatFloat('0.000',Pickups[i].PosX) +'|'+ FormatFloat('0.000',Pickups[i].PosY) +'|'+ FormatFloat('0.000',Pickups[i].PosZ)
          Else if (Pickups[i].model = 2) Then
            CommBlock2.Mssg := 'r|'+ FormatFloat('0.000',Pickups[i].PosX) +'|'+ FormatFloat('0.000',Pickups[i].PosY) +'|'+ FormatFloat('0.000',Pickups[i].PosZ)
          Else if (Pickups[i].model = 3) Then
            CommBlock2.Mssg := 'a|'+ FormatFloat('0.000',Pickups[i].PosX) +'|'+ FormatFloat('0.000',Pickups[i].PosY) +'|'+ FormatFloat('0.000',Pickups[i].PosZ);
          AThread.Connection.WriteBuffer(CommBlock2,SizeOf(CommBlock2),True);
        end;
      end;
      
      Exit;
  End
  Else If (CommBlock.Command = 'JOIN') Then
  Begin
      Try
      begin
        Arr := Split(CommBlock.Mssg,'|');
      Done := 0;
      PlayID := 0;
      For i := 1 To Slots Do
      Begin
         If (Nick[i] = CommBlock.Nick) Then
           CommBlock2.Interior := 6;
         If (Slot[i] = False) and (Done = 0) Then
         Begin
          Nick[i] := CommBlock.Nick;
          Slot[i] := True;
          Port[i] := AThread.Connection.Socket.Binding.Port;
          IP[i] := AThread.Connection.Socket.Binding.PeerIP;
          ID[i] := i;
          Hdl[i] := AThread.Handle;
          PlayID := i;
          //Done := 1;
          PPosX[i] := 0.0;
          PPosY[i] := 0.0;
          PPosZ[i] := 0.0;
          PRotation[i] := 0.0;
          IsAdmin[i] := False;
          IsIngame[i] := False;
          IsIngameL[i] := False;
          PInterior[i] := 0;
          Break;
         End;
       End;
       If (PlayID = 0) Then
         CommBlock2.Interior := 3 // Server vol full
       Else If Not (CommBlock.Interior = 13) Then
         CommBlock2.Interior := 1 // Verkeerde versie
       Else If Not (LowerCase(calcMD5(ServerPass)) = Arr[0]) and (Length(ServerPass) > 0) Then
         CommBlock2.Interior := 2 // Wachtwoord fout
       Else If Not (AdminPass = Arr[1]) And Not (Arr[1] = 'd41d8cd98f00b204e9800998ecf8427e') And (Length(AdminPass) > 0) and (Length(Arr[1]) > 0) and (Admins = 1) Then
         CommBlock2.Interior := 4; // Admin wachtwoord fout
       For i2 := 0 To Pred(lstBans.Count) Do
       Begin
         If (AThread.Connection.Socket.Binding.PeerIP = lstBans.Items[i2]) Then
            CommBlock2.Interior := 5; // Gebant
        End;
        If Not (Arr[1] = 'd41d8cd98f00b204e9800998ecf8427e') And (AdminPass = Arr[1]) And (Admins = 1) And (Length(Arr[1]) = 32) Then
           IsAdmin[PlayID] := True;
        CommBlock2.Command := 'OK';
        CommBlock2.Mssg := ServerName;
        CommBlock2.PlayerID := PlayID;
        AThread.Connection.WriteBuffer(CommBlock2,SizeOf(CommBlock2),True);
        If (CommBlock2.Interior > 0) Then
         Exit
        Else
          Ce.ExecuteFunction([PlayID],'OnPlayerJoin');
      end
      Except
      End;
  End
  Else If (CommBlock.Command = 'SPWN0') Then
  Begin
    if (SyncSpawn[CommBlock.PlayerID] = True) Then
    begin
      SyncOnSpawn(CommBlock.PlayerID);
      SyncSpawn[CommBlock.PlayerID] := False;
    end;
    Ce.ExecuteFunction([CommBlock.PlayerID,CommBlock.Interior],'OnPlayerChangeSpawn');
    Exit;
  End
  Else If (CommBlock.Command = 'SPWN1') Then
  Begin
    SyncSpawn[CommBlock.PlayerID] := True;
    Ce.ExecuteFunction([CommBlock.PlayerID,CommBlock.Interior],'OnPlayerSpawn');
    Exit;
  End
  Else If (CommBlock.Command = 'PING') Then
  Begin
    CommBlock2.Command := 'PONG';
    CommBlock2.Roll0 := Players-1;
    CommBlock2.Roll2 := Slots;
    CommBlock2.Mssg := ServerName+'_____'+CommBlock.Mssg;
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
    Exit;
  End
  Else If (CommBlock.Command = 'GOFF') Then
  Begin
    IsIngame[CommBlock.PlayerID] := False;
    If not (IsIngame[CommBlock.PlayerID] = IsIngameL[CommBlock.PlayerID]) Then
    Begin
      IsIngameL[CommBlock.PlayerID] := IsIngame[CommBlock.PlayerID];
      Ce.ExecuteFunction([CommBlock.PlayerID],'OnPlayerExitGame');
    End;
    Exit;
  End;

{  If (CommBlock.Command = 'SYNC') Then
  Begin
    If (Ticks[CommBlock.PlayerID] > 4) Then
    Begin
      Ticks := 0; // Reset
    End
    Else
    Begin
      Inc(Ticks[CommBlock.PlayerID]); // Increase
    End;
  End; }

  With Clients.LockList Do
  Try
    For i := 0 To Pred(Count) Do
    Begin
      RecClient := Items[i];
      RecThread := RecClient.Thread;
{      If (CommBlock.Command = 'SYNC') and (Ticks = 0) Then
      Begin
        For i2 := 1 To
      End;}
      If Not (RecThread.Handle = AThread.Handle) And (RecThread.Connection.Connected = True) Then
        RecThread.Connection.WriteBuffer(CommBlock,SizeOf(CommBlock),True);
    End;
  Finally
    Clients.UnlockList;
  End;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Try
    If (IRC.Connected) Then
     IRC.Quit('San Andreas Party '+Version+' Server Shutting down');
    Server.MaxConnections := 0;
    Server.Active := False;
    Query.MaxConnections := 0;
    Query.Active := False;
    INI.Free;
  Except
    Application.Terminate;
  End;
end;

procedure TfrmMain.btnLogSendClick(Sender: TObject);
begin
  Ce.ExecuteFunction([edtLogText.Text],'OnConsoleMessage');
  edtLogText.Clear;
end;

procedure TfrmMain.FormActivate(Sender: TObject);
var
  Val, i : Integer;
  Mssg : String;
  Messages : TSplitArray;
begin
  HTTP.Request.UserAgent := 'SAP/'+Version;
  SetLength(Messages,100);
  StartTicks := GetTickCount();
  If not (FileExists('scripts\'+ INI.ReadString('GAME','script','main') +'.script')) Then
  Begin
    Err('Couldn''t find script: ''scripts\'+ INI.ReadString('GAME','script','main') +'.script''.');
    Application.Terminate;
    Exit;
  End;
  Ce.Script.LoadFromFile('scripts\'+ INI.ReadString('GAME','script','main') +'.script');

  If Not (Ce.Compile) Then
  Begin
    Err('Error while compiling main.script');
    For i := 0 To Pred(Ce.CompilerMessageCount) Do
    Begin
      Err(Ce.CompilerMessages[i].MessageToString);
    End;
    Application.Terminate;
    Exit;
  End
  Else
  Begin
    If Not (Ce.Execute) Then
    Begin
      Err('Error while executing script: '+ Ce.ExecErrorToString);
      Application.Terminate;
      Exit;
    End;
  End;
  Log('*** San Andreas Party '+Version+' Server started');
  Log('*** Current server name: '''+ ServerName +'''');
  Val := INI.ReadInteger('SERVER','port',1);
  Log('*** Listening on ports '+IntToStr(Val)+' and '+IntToStr(Val+1));
  Val := INI.ReadInteger('SERVER','masterlist',1);
  If (Val = 1) Then
  begin
    try
      Mssg := HTTP.Get('http://www.sa-party.com/03masterlist/announcer.php?port='+ IntToStr(Server.DefaultPort)+'&ver='+Version);
    except
      Mssg := '0';
    end;
    If not (Mssg = '1') Then
      Log('*** Server couldn''t be added to the serverlist')
    Else
    begin
      tmrMasterServer.Enabled := True;
      Log('*** Server has been added to the masterlist');
    end;
  end;
  Val := INI.ReadInteger('IRC','enabled',0);
  If (Val = 1) Then
  Begin
    IRC.Connect();
    If (IRC.Connected) Then
    begin
      IRC.Join(IRCChannel, IRCChanPass);
      IRC.Say(IRCChannel,'*** San Andreas Party '+Version+' Server started');
      Log('*** Connected To IRC');
    end
    Else
      Log('Error while connecting to IRC');
  End;

  Ce.ExecuteFunction([],'OnStart'); // Server started
end;

procedure TfrmMain.Timer(Seconds : Integer; Execute : String);
var
  i : integer;
begin
  For i := 0 to High(Timers) Do
  Begin
    If (Timers[i].InUse = False) Then
    begin
      Timers[i].Time := Seconds;
      Timers[i].Command := Execute;
      Timers[i].InUse := True;
      Exit;
    End;
  End;
end;

procedure TfrmMain.edtLogTextKeyPress(Sender: TObject; var Key: Char);
begin
  If (Key = #13) Then
    btnLogSend.Click;
end;

procedure TfrmMain.AddSpawn(PosX, PosY, PosZ, Rotation : Single);
var
  CB : TCommBlock;
  Mssg : String;
  i : Integer;
begin
  For i := 1 To High(Spawns) Do
  Begin
    If (Spawns[i].InUse = False) Then
    begin
      Spawns[i].PosX := PosX;
      Spawns[i].PosY := PosY;
      Spawns[i].PosZ := PosZ;
      Spawns[i].Rot := Rotation;
      Spawns[i].InUse := True;
      CB.Command := 'NMP';
      Mssg := 's|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ) +'|'+ FormatFloat('0.000',Rotation);
      CB.Mssg := Mssg;
      SendDataToAll(CB);
      gSpawns := gSpawns + 1;
      Exit;
    end;
  end;
end;

procedure TfrmMain.AddVehicle(ModelID: Integer; PosX, PosY, PosZ, Rotation : Single;Color1, Color2 : Integer);
var
  CB : TCommBlock;
  Mssg : String;
  i : Integer;
begin
  if (ModelID < 400) or (ModelID > 611) Then
    Exit;

  For i := 1 To High(Cars) Do
  Begin
    If (Cars[i].InUse = False) Then
    begin
      Cars[i].Model := ModelID;
      Cars[i].sPosX := PosX;
      Cars[i].sPosY := PosY;
      Cars[i].sPosZ := PosZ;
      Cars[i].PosX := PosX;
      Cars[i].PosY := PosY;
      Cars[i].PosZ := PosZ;
      Cars[i].Rot := Rotation;
      Cars[i].Color1 := Color1;
      Cars[i].Color2 := Color2;
      Cars[i].Plate := 'SA_PARTY';
      Cars[i].InUse := True;
      CB.Command := 'NMP';
      Mssg := 'v|'+ IntToStr(i) +'|'+ IntToStr(ModelID) +'|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ) +'|'+ FormatFloat('0.000',Rotation) +'|'+ IntToStr(Color1) +'|'+ IntToStr(Color2);
      CB.Mssg := Mssg;
      SendDataToAll(CB);
      gSpawnedVehicles := gSpawnedVehicles+1;
      Break;
      Exit;
    end;
  end;
end;

function TfrmMain.AddCheckpointEx(PlayerID : Integer;PosX, PosY, PosZ, Radius : Single): Integer;
var
  CB : TCommBlock;
  i, i2, Start, Limit : Integer;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
  begin
    Result := -1;
    Exit;
  end;
  Start := 50 * PlayerID - 49;
  Limit := 50 * PlayerID - 1;
  For i := Start To Limit Do
  Begin
    If (Markers[i].InUse = False) Then
    begin
      Markers[i].InUse := True;
      Markers[i].PosX := PosX;
      Markers[i].PosY := PosY;
      Markers[i].PosZ := PosZ;
      i2 := i - ( PlayerID * 50 ) + 50;
      CB.Command := 'NMP';
      CB.Mssg := 'cp|'+ IntToStr(i2) +'|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ)+'|'+ FormatFloat('0.000',Radius);
      SendDataToPlayer(PlayerID,CB);
      result := i2;
      Exit;
    end;
  end;
  result := -1;
end;

procedure TfrmMain.AddCheckpoint(PlayerID : Integer;PosX, PosY, PosZ, Radius : Single);
var
  CB : TCommBlock;
  i, i2, Start, Limit : Integer;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  Start := 50 * PlayerID - 49;
  Limit := 50 * PlayerID - 1;
  For i := Start To Limit Do
  Begin
    If (Markers[i].InUse = False) Then
    begin
      Markers[i].InUse := True;
      Markers[i].PosX := PosX;
      Markers[i].PosY := PosY;
      Markers[i].PosZ := PosZ;
      i2 := i - ( PlayerID * 50 ) + 50;
      CB.Command := 'NMP';
      CB.Mssg := 'cp|'+ IntToStr(i2) +'|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ)+'|'+ FormatFloat('0.000',Radius);
      SendDataToPlayer(PlayerID,CB);
      Break;
      Exit;
    end;
  end;
end;

procedure TfrmMain.DeleteCheckpoint(PlayerID, i: Integer);
var
  CB : TCommBlock;
  i2 : Integer;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  i2 := i + (50 * PlayerID) - 50;
  if (Markers[i2].InUse = False) Then
    Exit;

  Markers[i2].InUse := False;
  CB.Command := 'NMP';
  CB.Mssg := 'cpd|'+ IntToStr(i);
  SendDataToPlayer(PlayerID,CB);
end;

procedure TfrmMain.DeleteVehicle(i: Integer);
var
  CB : TCommBlock;
  Mssg : String;
begin
  if (Cars[i].InUse = False) Then
    Exit;
    
  Cars[i].InUse := False;
  CB.Command := 'NMP';
  CB.Nick := 'Server';
  Mssg := 'dv|'+ IntToStr(i);
  CB.Mssg := Mssg;
  SendDataToAll(CB);
  gSpawnedVehicles := gSpawnedVehicles-1;
end;

function TfrmMain.AddVehicleEx(ModelID: Integer; PosX, PosY, PosZ, Rotation : Single;Color1, Color2 : Integer): Integer;
var
  CB : TCommBlock;
  Mssg : String;
  i : Integer;
begin
  if (ModelID < 400) OR (ModelID > 611) Then
  begin
    result := -1;
    Exit;
  end;

  For i := 1 To 1000 Do
  Begin
    If (Cars[i].InUse = False) Then
    begin
      Cars[i].InUse := True;
      Cars[i].Model := ModelID;
      Cars[i].sPosX := PosX;
      Cars[i].sPosY := PosY;
      Cars[i].sPosZ := PosZ;
      Cars[i].PosX := PosX;
      Cars[i].PosY := PosY;
      Cars[i].PosZ := PosZ;
      Cars[i].Color1 := Color1;
      Cars[i].Color2 := Color2;
      Cars[i].Plate := '__SAP__';
      CB.Command := 'NMP';
      Mssg := 'v|'+ IntToStr(i) +'|'+ IntToStr(ModelID) +'|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ) +'|'+ FormatFloat('0.000',Rotation) +'|'+ IntToStr(Color1) +'|'+ IntToStr(Color2);
      CB.Mssg := Mssg;
      SendDataToAll(CB);
      gSpawnedVehicles := gSpawnedVehicles+1;
      result := i;
      Exit;
    end;
  end;
  result := -1;
end;

procedure TfrmMain.AddObject(ModelID : Integer; PosX, PosY, PosZ, RotX, RotY, RotZ : Single);
var
  CB : TCommBlock;
  Mssg : String;
  i : integer;
begin
  For i := 1 To 1000 Do
  Begin
    If (Objects[i].InUse = False) Then
    begin
      Objects[i].Model := ModelID;
      Objects[i].PosX := PosX;
      Objects[i].PosY := PosY;
      Objects[i].PosZ := PosZ;
      Objects[i].RotX := RotX;
      Objects[i].RotY := RotY;
      Objects[i].RotZ := RotZ;
      Objects[i].InUse := True;
      CB.Command := 'NMP';
      Mssg := 'o|'+ IntToStr(ModelID) +'|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ) +'|'+ FormatFloat('0.000',RotX) +'|'+ FormatFloat('0.000',RotY) +'|'+ FormatFloat('0.000',RotZ);
      CB.Mssg := Mssg;
      gSpawnedObjects := gSpawnedObjects+1;
      SendDataToAll(CB);
      Break;
      Exit;
    end;
  end;
end;

function TfrmMain.IsPlayerAdmin(PlayerID : Integer): Boolean;
begin
  If (PlayerID < HARDCODED_MAX_PLAYERS) Then
    result := IsAdmin[PlayerID]
  Else
    result := False;
end;

function TfrmMain.IsPlayerConnected(PlayerID : Integer): Boolean;
begin
  If (PlayerID < HARDCODED_MAX_PLAYERS) Then
    result := Slot[PlayerID]
  Else
    result := False;
end;

function TfrmMain.IsPlayerIngame(PlayerID : Integer): Boolean;
begin
  If (PlayerID < HARDCODED_MAX_PLAYERS) Then
    result := IsIngame[PlayerID]
  Else
    result := False;
end;

function TfrmMain.GetPlayerNick(PlayerID: Integer): String;
begin
 If (PlayerID < HARDCODED_MAX_PLAYERS) Then
    result := Nick[PlayerID]
  Else
    result := '';
end;

function TfrmMain.GetPlayerID(Nick : String): Integer;
var
  i, i2 : Integer;
begin
  i2 := 0;
  For i := 1 To HARDCODED_MAX_PLAYERS-1 Do
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
  If (PlayerID < HARDCODED_MAX_PLAYERS) Then
    result := PPosX[PlayerID]
  Else
    result := 0.0;
end;

function TfrmMain.GetPlayerPosY(PlayerID : Integer): Single;
begin
  If (PlayerID < HARDCODED_MAX_PLAYERS) Then
    result := PPosY[PlayerID]
  Else
    result := 0.0;
end;

function TfrmMain.GetPlayerPosZ(PlayerID : Integer): Single;
begin
  If (PlayerID < HARDCODED_MAX_PLAYERS) Then
    result := PPosZ[PlayerID]
  Else
    result := 0.0;
end;

procedure TfrmMain.SetPlayerColor(PlayerID, Color : Integer);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'NMP';
  CB.Mssg := 'col|'+ IntToStr(PlayerID) +'|'+ IntToStr(Color);
  SendDataToAllExceptPlayer(PlayerID, CB);
end;

procedure TfrmMain.SetPlayerPos(PlayerID : Integer;PosX, PosY, PosZ : Single);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'POS';
  CB.PlayerID := PlayerID;
  CB.PosX := PosX;
  CB.PosY := PosY;
  CB.PosZ := PosZ;
  SendDataToPlayer(PlayerID,CB);
end;

function TfrmMain.GetPlayerInterior(PlayerID : Integer): Integer;
begin
  If (PlayerID < HARDCODED_MAX_PLAYERS) Then
    result := PInterior[PlayerID]
  Else
    result := 0;
end;

procedure TfrmMain.SetPlayerInterior(PlayerID, InteriorID : Integer);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'INT';
  CB.Interior := InteriorID;
  SendDataToPlayer(PlayerID,CB);
end;

procedure TfrmMain.SetPlayerAnimation(PlayerID, AnimationID : Integer);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) or (AnimationID > 15) Then
    Exit;
  CB.Command := 'NMP';
  CB.Mssg := 'anim|'+ IntToStr(PlayerID) +'|'+ IntToStr(AnimationID);
  SendDataToAll(CB);

{  CB.Command := 'ANIM';
  CB.PlayerID := PlayerID;
  CB.Interior := AnimationID;
  SendDataToAll(CB);}
end;

function TfrmMain.GetPlayerAngle(PlayerID : Integer): Single;
begin
  If (PlayerID < HARDCODED_MAX_PLAYERS) Then
    result := PRotation[PlayerID]
  Else
    result := 0.0;
end;

procedure TfrmMain.SetPlayerAngle(PlayerID : Integer;Angle : Single);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'ROT';
  CB.XA := Angle;
  SendDataToPlayer(PlayerID,CB);
end;


function TfrmMain.GetPlayerHealth(PlayerID : Integer): Single;
begin
  If (PlayerID < HARDCODED_MAX_PLAYERS) Then
    result := PHealth[PlayerID]
  Else
    result := 0.0;
end;

procedure TfrmMain.KickPlayer(PlayerID : Integer);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'KICK';
  SendDataToPlayer(PlayerID,CB);
  DisconnectPlayer(PlayerID);
end;

procedure TfrmMain.KillPlayer(PlayerID : Integer);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'KILL';
  SendDataToPlayer(PlayerID,CB);
end;

procedure TfrmMain.BanPlayer(PlayerID : Integer);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'BAN';
  SendDataToPlayer(PlayerID,CB);
  lstBans.Items.Add(GetPlayerIP(PlayerID));
  DisconnectPlayer(PlayerID);
end;

procedure TfrmMain.SetPlayerHealth(PlayerID : Integer;Health : Single);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'HT';
  CB.XA := Health;
  SendDataToPlayer(PlayerID,CB);
end;


procedure TfrmMain.AddHealthPickup(PosX, PosY, PosZ : Single);
var
  CB : TCommBlock;
  Mssg : String;
  I : Integer;
begin
  For i := 1 To 1000 Do
  Begin
    If (Pickups[i].InUse = False) Then
    begin
      Pickups[i].InUse := True;
      Pickups[i].Model := 1;
      Pickups[i].PosX := PosX;
      Pickups[i].PosY := PosY;
      Pickups[i].PosZ := PosZ;
      CB.Command := 'NMP';
      Mssg := 'health|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ);
      CB.Mssg := Mssg;
      SendDataToAll(CB);
      gPickups := gPickups + 1;
      Exit;
    end;
  end;
end;

{procedure TfrmMain.AddVehicleRepair(PosX, PosY, PosZ : Single);
var
  CB : TCommBlock;
  Mssg : String;
  I : Integer;
begin
  For i := 1 To 1000 Do
  Begin
    If (Pickups[i].InUse = False) Then
    begin
      Pickups[i].InUse := True;
      Pickups[i].Model := 2;
      Pickups[i].PosX := PosX;
      Pickups[i].PosY := PosY;
      Pickups[i].PosZ := PosZ;
      CB.Command := 'NMP';
      Mssg := 'r|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ);
      CB.Mssg := Mssg;
      SendDataToAll(CB);
      gPickups := gPickups + 1;
      Exit;
    end;
  end;
end;
}

procedure TfrmMain.AddArmorPickup(PosX, PosY, PosZ : Single);
var
  CB : TCommBlock;
  Mssg : String;
  I : Integer;
begin
  For i := 1 To 1000 Do
  Begin
    If (Pickups[i].InUse = False) Then
    begin
      Pickups[i].InUse := True;
      Pickups[i].Model := 2;
      Pickups[i].PosX := PosX;
      Pickups[i].PosY := PosY;
      Pickups[i].PosZ := PosZ;
      CB.Command := 'NMP';
      Mssg := 'a|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ);
      CB.Mssg := Mssg;
      SendDataToAll(CB);
      gPickups := gPickups + 1;
      Exit;
    End;
  End;
end;

function TfrmMain.GetHour(): Integer;
begin
    result := gHour;
end;

function TfrmMain.GetMinute(): Integer;
begin
    result := gMinute;
end;

function TfrmMain.GetWeather(): Integer;
begin
    result := gWeather;
end;

procedure TfrmMain.SetTime(Hour, Minute : Integer);
var
  CB : TCommBlock;
begin
  CB.Command := 'TIME';
  CB.Interior := Hour;
  CB.Car := Minute;
  SendDataToAll(CB);
  gHour := Hour;
  gMinute := Minute;
end;

procedure TfrmMain.SetWeather(WeatherID : Integer);
var
  CB : TCommBlock;
begin
  If (WeatherID > 300) Or (WeatherID < 0) Then // 39 normaal
    Exit;
  CB.Command := 'WEATH';
  CB.Interior := WeatherID;
  SendDataToAll(CB);
  gWeather := WeatherID;
end;

procedure TfrmMain.SetWeapon(WeaponID : Integer);
var
  CB : TCommBlock;
  Mssg : String;
begin
  CB.Command := 'NMP';
  Mssg := 'w|'+ IntToStr(WeaponID);
  CB.Mssg := Mssg;
  SendDataToAll(CB);
end;

procedure TfrmMain.SendTextToAllExceptPlayer(PlayerID : Integer; Mssg : String);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  If (Length(Mssg) > 85) Then
    Exit;
  CB.Command := 'ANN';
  CB.Mssg := Mssg;
  SendDataToAllExceptPlayer(PlayerID,CB);
end;

procedure TfrmMain.SendTextToPlayer(PlayerID : Integer; Mssg : String);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  If (Length(Mssg) > 85) Then
    Exit;
  CB.Command := 'ANN';
  CB.Mssg := Mssg;
  SendDataToPlayer(PlayerID,CB);
end;

procedure TfrmMain.SetPlayerWeapon(PlayerID, WeaponID : Integer);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'NMP';
  CB.Mssg := 'w|'+ IntToStr(WeaponID);
  SendDataToPlayer(PlayerID, CB);
end;

procedure TfrmMain.SendTextToAll(Mssg : String);
var
  CB : TCommBlock;
begin
  If (Length(Mssg) > 85) Then
    Exit;
  CB.Command := 'ANN';
  CB.Mssg := Mssg;
  SendDataToAll(CB);
  Log(Mssg);
end;

procedure TfrmMain.DisplayTextPlayer(PlayerID, Style: Integer; Mssg : String; Time : Integer);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  If (Length(Mssg) > 85) Then
    Exit;
  CB.Command := 'DIS';
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
  CB.Roll2 := Style;
  CB.Mssg := Mssg;
  CB.Anim := Time;
  SendDataToAll(CB);
end;

procedure TfrmMain.SetPlayerMoney(PlayerID, Money : Integer);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'MON';
  CB.Interior := Money;
  SendDataToPlayer(PlayerID,CB);
end;

function TfrmMain.GetPlayerMoney(PlayerID : Integer): Integer;
begin
  If (PlayerID < HARDCODED_MAX_PLAYERS) Then
    result := PMoney[PlayerID]
  Else
    result := 0;
end;

procedure TfrmMain.SetPlayerFreeze(PlayerID : Integer;State : Boolean);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
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
  CB.PlayerID := PlayerID;
  SendDataToPlayer(PlayerID,CB);
end;

function TfrmMain.GetPlayerFreeze(PlayerID : Integer): Boolean;
begin
  If (PlayerID < HARDCODED_MAX_PLAYERS) Then
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

procedure TfrmMain.IRCSay(Mssg : String);
begin
  If (IRC.Connected) Then
    IRC.Say(IRCChannel,Mssg);
end;

procedure TfrmMain.OnIRCMessage(Sender: TObject; AUser: TIdIRCUser;
  AChannel: TIdIRCChannel; Content: String);
begin
  if (Content = '!about') Then
    IRC.Say(IRCChannel,'San Andreas Party '+Version+' Server by Ywa*NL and Mount - Visit www.sa-party.com');
  Ce.ExecuteFunction([AUser.Nick,Content],'OnIRCMessage');
end;

procedure TfrmMain.IRCJoin(Sender: TObject; AUser: TIdIRCUser;
  AChannel: TIdIRCChannel);
begin
  Ce.ExecuteFunction([AUser.Nick],'OnIRCJoin');
end;

procedure TfrmMain.IRCPart(Sender: TObject; AUser: TIdIRCUser;
  AChannel: TIdIRCChannel);
begin
  Ce.ExecuteFunction([AUser.Nick],'OnIRCPart');
end;

procedure TfrmMain.IRCNotice(Sender: TObject; AUser: TIdIRCUser;
  AChannel: TIdIRCChannel; Content: String);
begin
  Ce.ExecuteFunction([AUser.Nick,Content],'OnIRCNotice');
end;

function TfrmMain.GetMaxSlots(): Integer;
begin
  result := Slots;
end;

function TfrmMain.GetPlayerIP(PlayerID : Integer): String;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  result := IP[PlayerID];
end;

procedure TfrmMain.SetGravity(Grav : Integer);
var
  CB : TCommBlock;
begin
  //if (Grav > 124) OR (Grav < 1) Then
  //  Exit;
  CB.Command := 'GRAV';
  CB.PosX := Grav * 0.00008;
  SendDataToAll(CB);
  gGravity := Grav;
end;

procedure TfrmMain.SetFly(Enabled : Boolean);
var
  CB : TCommBlock;
begin
  CB.Command := 'FLY';
  If (Enabled = True) Then
    CB.Interior := 1
  Else
    CB.Interior := 0;
  SendDataToAll(CB);
  gFly := CB.Interior;
end;

procedure TfrmMain.SetWaterHeight(Height : Single);
var
  CB : TCommBlock;
begin
  CB.Command := 'WH';
  CB.PosX := Height;
  SendDataToAll(CB);
  gWaterHeight := Height;
end;

procedure TfrmMain.SetWaterWaveHeight(Height : Single);
var
  CB : TCommBlock;
begin
  CB.Command := 'WWH';
  CB.PosX := Height;
  SendDataToAll(CB);
  gWaterWaveHeight := Height;
end;

procedure TfrmMain.UnderWaterWalk(Switch : Boolean);
var
  CB : TCommBlock;
begin
  CB.Command := 'UW';
  if (Switch = True) Then
    CB.Interior := 1
  else
    CB.Interior := 0;
  gUnderWater := CB.Interior;
  SendDataToAll(CB);
end;

procedure TfrmMain.BurnPlayer(PlayerID : Integer);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'NMP';
  CB.Mssg := 'BP';
  SendDataToPlayer(PlayerID, CB);
end;

procedure TfrmMain.PlaySound(PlayerID, SoundID : Integer);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'NMP';
  CB.Mssg := 'PS|'+ IntToStr(SoundID);
  SendDataToPlayer(PlayerID, CB);
end;

procedure TfrmMain.SetCamera(PlayerID : Integer; X, Y, Z : Single);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'NMP';
  CB.Mssg := 'SCP|'+ FloatToStr(X) +'|'+ FloatToStr(Y) +'|'+ FloatToStr(Z);
  SendDataToPlayer(PlayerID, CB);
end;

procedure TfrmMain.PointCameraAt(PlayerID : Integer; X, Y, Z : Single);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'NMP';
  CB.Mssg := 'PCA|'+ FloatToStr(X) +'|'+ FloatToStr(Y) +'|'+ FloatToStr(Z);
  SendDataToPlayer(PlayerID, CB);
end;

procedure TfrmMain.ResetCamera(PlayerID : Integer);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'NMP';
  CB.Mssg := 'RC';
  SendDataToPlayer(PlayerID, CB);
end;

procedure TfrmMain.SetVehicleHealth(VehicleID : Integer; Health : Single);
var
  CB : TCommBlock;
begin
  CB.Command := 'NMP';
  CB.Mssg := 'SVH|'+ IntToStr(VehicleID) +'|'+ FloatToStr(Health);
  SendDataToAll(CB);
end;

procedure TfrmMain.SetVehicleDoorsLocked(PlayerID, Vehicle : Integer; Locked : Boolean);
var
  CB : TCommBlock;
begin
  CB.Command := 'NMP';
  if (Locked = True) Then
    CB.Mssg := 'LVD|'+ IntToStr(Vehicle) +'|1'
  else
    CB.Mssg := 'LVD|'+ IntToStr(Vehicle) +'|0';
  SendDataToPlayer(PlayerID, CB);
end;

procedure TfrmMain.ResetPlayerWeapons(PlayerID : Integer);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'NMP';
  CB.Mssg := 'RESETWEP';
  SendDataToPlayer(PlayerID, CB);
end;

procedure TfrmMain.RespawnVehicle(VehicleID : Integer);
var
  CB : TCommBlock;
begin
  CB.Command := 'NMP';
  CB.Mssg := 'RSV|'+IntToStr(VehicleID);
  SendDataToAll(CB);
end;

procedure TfrmMain.ExplodeVehicle(VehicleID : Integer);
var
  CB : TCommBlock;
begin
  CB.Command := 'NMP';
  CB.Mssg := 'EXPLV|'+IntToStr(VehicleID);
  SendDataToAll(CB);
end;

procedure TfrmMain.SetVehiclePosition(VehicleID : Integer; X, Y, Z : Single);
var
  CB : TCommBlock;
begin
  CB.Command := 'NMP';
  CB.Mssg := 'SVPOS|'+IntToStr(VehicleID)+'|'+FloatToStr(X)+'|'+FloatToStr(Y)+'|'+FloatToStr(Z);
  SendDataToAll(CB);
end;

procedure TfrmMain.CreateExplosion(X, Y, Z : Single);
var
  CB : TCommBlock;
begin
  CB.Command := 'NMP';
  CB.Mssg := 'CREXP|'+FloatToStr(X)+'|'+FloatToStr(Y)+'|'+FloatToStr(Z);
  SendDataToAll(CB);
end;


procedure TfrmMain.RepairVehicle(VehicleID : Integer);
var
  CB : TCommBlock;
begin
  CB.Command := 'NMP';
  CB.Mssg := 'REPV|'+IntToStr(VehicleID);
  SendDataToAll(CB);
end;

function TfrmMain.calcMD5(Buffer : String): String;
begin
  Result := LowerCase(GetMD5(@Buffer[1], Length(Buffer)));
end;

function TfrmMain.INIRead(FileName, Section, Ident, Default : String): String;
var
  tINI : TINIFile;
begin
  tINI := TINIFile.Create(GetCurrentDir + '\scriptfiles\'+FileName);
  Result := tINI.ReadString(Section,Ident,Default);
  tINI.Free;
end;

procedure TfrmMain.INIWrite(FileName, Section, Ident, Value : String);
var
  tINI : TINIFile;
begin
  tINI := TINIFile.Create(GetCurrentDir + '\scriptfiles\'+FileName);
  tIni.WriteString(Section, Ident, Value);
  tINI.Free;
end;

function TfrmMain.ScriptFileExists(FileName : String): Boolean;
begin
  Result := FileExists(GetCurrentDir + '\scriptfiles\'+FileName);
end;

function TfrmMain.GetTicks(): Integer;
var
  ttick : Integer;
begin
  ttick := GetTickCount();
  Result := ttick-StartTicks;
end;

procedure TfrmMain.SetPlayerAdmin(PlayerID : Integer; Value : Boolean);
begin
  If (PlayerID < HARDCODED_MAX_PLAYERS) Then
    begin
    IsAdmin[PlayerID] := Value;
    end;
end;

procedure TfrmMain.SetPlayerArmor(PlayerID : Integer; Armor : Single);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'ARMR';
  CB.XA := Armor;
  SendDataToPlayer(PlayerID,CB);
end;

function TfrmMain.GetPlayerArmor(PlayerID : Integer): Single;
begin
  If (PlayerID < HARDCODED_MAX_PLAYERS) Then
    result := PArmor[PlayerID]
  Else
    result := 0.0;
end;

function TfrmMain.IsInteger(S: String): Boolean;
begin
  try
    Result := True;
    StrToInt(S);
  except on E: EConvertError do
    Result := False;
  end;
end;

function TfrmMain.IsFloat(S: String): Boolean;
begin
  try
    Result := True;
    StrToFloat(S);
  except on E: EConvertError do
    Result := False;
  end;
end;

procedure TfrmMain.AllowPlayerToJump(PlayerID : Integer; Toggle : Boolean);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'NMP';
  if (Toggle = True) Then
    CB.Mssg := 'APTJ|1'
  else
    CB.Mssg := 'APTJ|0';
  SendDataToPlayer(PlayerID, CB);
end;

procedure TfrmMain.AllowPlayerToShoot(PlayerID : Integer; Toggle : Boolean);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'NMP';
  if (Toggle = True) Then
    CB.Mssg := 'APTS|1'
  else
    CB.Mssg := 'APTS|0';
  SendDataToPlayer(PlayerID, CB);
end;

procedure TfrmMain.AllowPlayerToChangeWeapon(PlayerID : Integer; Toggle : Boolean);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'NMP';
  if (Toggle = True) Then
    CB.Mssg := 'APTCW|1'
  else
    CB.Mssg := 'APTCW|0';
  SendDataToPlayer(PlayerID, CB);
end;

procedure TfrmMain.SetPlayerCrouch(PlayerID : Integer; Toggle : Boolean);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'NMP';
  if (Toggle = True) Then
    CB.Mssg := 'SPC|1'
  else
    CB.Mssg := 'SPC|0';
  SendDataToPlayer(PlayerID, CB);
end;

procedure TfrmMain.UndoLastWeaponDamage(PlayerID : Integer);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'NMP';
  CB.Mssg := 'ULWD';
  SendDataToPlayer(PlayerID, CB);
end;

procedure TfrmMain.SetPlayerArmedWeapon(PlayerID, WeaponID : Integer);
var
  CB : TCommBlock;
begin
  If (PlayerID > HARDCODED_MAX_PLAYERS) Then
    Exit;
  CB.Command := 'NMP';
  CB.Mssg := 'SPAW|'+IntToStr(WeaponID);
  SendDataToPlayer(PlayerID, CB);
end;

procedure TfrmMain.CeCompile(Sender: TPSScript);
begin
  Sender.AddMethod(Self, @TfrmMain.Log,'procedure Log(const Message: string);');
  Sender.AddMethod(Self, @TfrmMain.AddSpawn,'procedure CreateSpawn(PosX, PosY, PosZ, Rotation : Single);');
  Sender.AddMethod(Self, @TfrmMain.AddObject,'procedure CreateObject(ModelID : Integer; PosX, PosY, PosZ, RotX, RotY, RotZ : Single);');
  Sender.AddMethod(Self, @TfrmMain.AddVehicle,'procedure CreateVehicle(ModelID: Integer; PosX, PosY, PosZ, Rotation : Single;Color1, Color2 : Integer);');
  Sender.AddMethod(Self, @TfrmMain.AddCheckpoint,'procedure CreateCheckpoint(PlayerID : Integer;PosX, PosY, PosZ, Radius: Single);');
  Sender.AddMethod(Self, @TfrmMain.AddCheckpointEx,'function CreateCheckpointEx(PlayerID : Integer;PosX, PosY, PosZ, Radius : Single): Integer;');
  Sender.AddMethod(Self, @TfrmMain.DeleteCheckpoint,'procedure DeleteCheckpoint(PlayerID, i: Integer);');
  Sender.AddMethod(Self, @TfrmMain.AddHealthPickup,'procedure CreateHealthPickup(PosX, PosY, PosZ : Single);');
  Sender.AddMethod(Self, @TfrmMain.AddArmorPickup,'procedure CreateArmorPickup(PosX, PosY, PosZ : Single);');
  Sender.AddMethod(Self, @TfrmMain.IsPlayerAdmin,'function IsPlayerAdmin(PlayerID: Integer): Boolean;');
  Sender.AddMethod(Self, @TfrmMain.IsPlayerConnected,'function IsPlayerConnected(PlayerID: Integer): Boolean;');
  Sender.AddMethod(Self, @TfrmMain.GetPlayerNick,'function GetPlayerNick(PlayerID: Integer): String;');
  Sender.AddMethod(Self, @TfrmMain.GetPlayerID,'function GetPlayerID(Nick : String): Integer;');
  Sender.AddMethod(Self, @TfrmMain.GetPlayerPosX,'function GetPlayerPosX(PlayerID: Integer): Single;');
  Sender.AddMethod(Self, @TfrmMain.GetPlayerPosY,'function GetPlayerPosY(PlayerID: Integer): Single;');
  Sender.AddMethod(Self, @TfrmMain.GetPlayerPosZ,'function GetPlayerPosZ(PlayerID: Integer): Single;');
  Sender.AddMethod(Self, @TfrmMain.SetPlayerPos,'procedure SetPlayerPos(PlayerID: Integer; PosX, PosY, PosZ : Single);');
  Sender.AddMethod(Self, @TfrmMain.SetPlayerColor,'procedure SetPlayerColor(PlayerID, Color : Integer);');
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
  Sender.AddMethod(Self, @TfrmMain.SetWeapon,'procedure SetWeapon(WeaponID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.CopyBetween,'function CopyBetween(Source, bs, es : String): String;');
  Sender.AddMethod(Self, @TfrmMain.CopyAfter,'function CopyAfter(Source, bs : String): String;');
  Sender.AddMethod(Self, @TfrmMain.CopyBefore,'function CopyBefore(Source, bs : String): String;');
  Sender.AddMethod(Self, @TfrmMain.Timer,'procedure Timer(Seconds : Integer; Execute : String);');
  Sender.AddMethod(Self, @TfrmMain.KickPlayer,'procedure KickPlayer(PlayerID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.BanPlayer,'procedure BanPlayer(PlayerID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.IsPlayerIngame,'function IsPlayerIngame(PlayerID : Integer): Boolean;');
  Sender.AddMethod(Self, @TfrmMain.KillPlayer,'procedure KillPlayer(PlayerID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.IRCSay,'procedure IRCSay(Message : String);');
  Sender.AddMethod(Self, @TfrmMain.SetPlayerWeapon,'procedure GivePlayerWeapon(PlayerID, WeaponID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.SetWeather,'procedure SetWeather(WeatherID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.SetTime,'procedure SetTime(Hour, Minute : Integer);');
  Sender.AddMethod(Self, @TfrmMain.GetHour,'procedure GetHour(): Integer;');
  Sender.AddMethod(Self, @TfrmMain.GetMinute,'procedure GetMinute(): Integer;');
  Sender.AddMethod(Self, @TfrmMain.GetWeather,'procedure GetWeather(): Integer;');
  Sender.AddMethod(Self, @TfrmMain.GetVehicleName,'function GetVehicleName(Car : Integer): String;');
  Sender.AddMethod(Self, @TfrmMain.GetMaxSlots,'function GetMaxSlots(): Integer;');
  Sender.AddMethod(Self, @TfrmMain.GetPlayerIP,'function GetPlayerIP(PlayerID : Integer): String;');
  Sender.AddMethod(Self, @TfrmMain.AddVehicleEx,'function CreateVehicleEx(ModelID: Integer; PosX, PosY, PosZ, Rotation : Single;Color1, Color2 : Integer): Integer;');
  Sender.AddMethod(Self, @TfrmMain.UnderWaterWalk,'procedure UnderWaterWalk(Switch : Boolean);');
  Sender.AddMethod(Self, @TfrmMain.DeleteVehicle,'procedure DestroyVehicle(UniqueID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.SetVehicleDoorsLocked,'procedure SetVehicleDoorsLocked(PlayerID, Vehicle : Integer; Locked : Boolean);');
  Sender.AddMethod(Self, @TfrmMain.ResetCamera,'procedure ResetCamera(PlayerID: Integer);');
  Sender.AddMethod(Self, @TfrmMain.PointCameraAt,'procedure PointCameraAt(PlayerID : Integer; X, Y, Z : Single);');
  Sender.AddMethod(Self, @TfrmMain.SetCamera,'procedure SetCamera(PlayerID : Integer; X, Y, Z : Single);');
  Sender.AddMethod(Self, @TfrmMain.PlaySound,'procedure PlaySound(PlayerID, SoundID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.SetVehicleHealth,'procedure SetVehicleHealth(VehicleID : Integer; Health : Single);');
  Sender.AddMethod(Self, @TfrmMain.SetVehiclePosition,'procedure SetVehiclePosition(VehicleID : Integer; X, Y, Z : Single);');
  Sender.AddMethod(Self, @TfrmMain.ExplodeVehicle,'procedure ExplodeVehicle(VehicleID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.RespawnVehicle,'procedure RespawnVehicle(VehicleID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.ResetPlayerWeapons,'procedure ResetPlayerWeapons(PlayerID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.CreateExplosion,'procedure CreateExplosion(X, Y, Z : Single);');
  Sender.AddMethod(Self, @TfrmMain.RepairVehicle,'procedure RepairVehicle(VehicleID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.calcMD5,'function MD5(Buffer : String): String;');
  Sender.AddMethod(Self, @TfrmMain.GetTicks,'function GetTickRate(): Integer;');
  Sender.AddMethod(Self, @TfrmMain.ScriptFileExists,'function ScriptFileExists(FileName : String): Boolean;');
  Sender.AddMethod(Self, @TfrmMain.INIWrite,'procedure INIWrite(FileName, Section, Ident, Value : String);');
  Sender.AddMethod(Self, @TfrmMain.INIRead,'function INIRead(FileName, Section, Ident, Default : String): String;');
  Sender.AddMethod(Self, @TfrmMain.SetPlayerAdmin, 'procedure SetPlayerAdmin(PlayerID : Integer; Value : Boolean);');
  Sender.AddMethod(Self, @TfrmMain.BurnPlayer, 'procedure BurnPlayer(PlayerID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.GetPlayerArmor, 'function GetPlayerArmor(PlayerID : Integer): Single;');
  Sender.AddMethod(Self, @TfrmMain.SetPlayerArmor, 'procedure SetPlayerArmor(PlayerID : Integer; Armor : Single);');
  Sender.AddMethod(Self, @TfrmMain.SetGravity,'procedure SetGravity(Gravity : Integer);');
  Sender.AddMethod(Self, @TfrmMain.SetFly,'procedure SetFlyingVehicles(Enabled : Boolean);');
  Sender.AddMethod(Self, @TfrmMain.SetPlayerAnimation,'procedure SetPlayerAnimation(PlayerID, AnimationID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.IsInteger,'function IsInteger(S : String): Boolean;');
  Sender.AddMethod(Self, @TfrmMain.IsFloat,'function IsFloat(S : String): Boolean;');
  Sender.AddMethod(Self, @TfrmMain.AllowPlayerToJump,'procedure AllowPlayerToJump(PlayerID : Integer; Toggle : Boolean);');
  Sender.AddMethod(Self, @TfrmMain.AllowPlayerToShoot,'procedure AllowPlayerToShoot(PlayerID : Integer; Toggle : Boolean);');
  Sender.AddMethod(Self, @TfrmMain.AllowPlayerToChangeWeapon,'procedure AllowPlayerToChangeWeapon(PlayerID : Integer; Toggle : Boolean);');
  Sender.AddMethod(Self, @TfrmMain.SetPlayerCrouch,'procedure SetPlayerCrouch(PlayerID : Integer; Toggle : Boolean);');
  Sender.AddMethod(Self, @TfrmMain.UndoLastWeaponDamage,'procedure UndoLastWeaponDamage(PlayerID : Integer);');
  Sender.AddMethod(Self, @TfrmMain.SetPlayerArmedWeapon,'procedure SetPlayerArmedWeapon(PlayerID, WeaponID : Integer);');
  {
  Sender.AddMethod(Self, @TfrmMain.SetWaterHeight,'procedure SetWaterHeight(Height : Single);');
  Sender.AddMethod(Self, @TfrmMain.SetWaterWaveHeight,'procedure SetWaterWaveHeight(Height : Single);');
  }
end;



procedure TfrmMain.OnQueryExecute(AThread: TIdPeerThread);
var
  Str, Servname, Mssg : String;
  Passworded, i : Integer;
begin
  Str := AThread.Connection.ReadString(1);
  If (Str = 'Q') Then
  Begin
    Servname :=  StringReplace(ServerName, '|', '.',[rfReplaceAll, rfIgnoreCase]);
    Servname :=  StringReplace(Servname, '~', '.',[rfReplaceAll, rfIgnoreCase]);
    if (Length(ServerPass) > 0) Then
      Passworded := 1
    else
      Passworded := 0;
    AThread.Connection.WriteLn(IntToStr(Players)+'|'+IntToStr(Slots)+'|'+IntToStr(Passworded)+'|'+ServName+'~');
    //Log('* Incoming Query Connection');
    //AThread.Terminate;
    Exit;
  End
  Else If (Str = 'P') Then
  Begin
    Mssg := '';
    For i := 0 To 20 Do
    Begin
      If Not (Nick[i] = '') Then
      Begin
        If (Mssg = '') Then
          Mssg := IntToStr(i)+' '+Nick[i]
        Else
          Mssg := Mssg +'|'+IntToStr(i)+' '+Nick[i];
      End;
    End;
    Mssg := StringReplace(Mssg, '~', '.',[rfReplaceAll, rfIgnoreCase]);
    Mssg := Mssg+'~';
    AThread.Connection.Write(Mssg);
    //Log('* Incoming Query Connection');
    //AThread.Terminate;
    Exit;
  End;
end;

procedure TfrmMain.OnTimeSync(Sender: TObject);
var
    i : integer;
begin

  For i := 0 to High(Timers) Do
  Begin
    If (Timers[i].InUse = True) Then
    begin
      Timers[i].Time := Timers[i].Time-1;
      If (Timers[i].Time = 0) Then
      Begin
        Ce.ExecuteFunction([],Timers[i].Command);
        Timers[i].InUse := False;
      End;
    End;
  End;

  gMinute := gMinute+1;
  if (gMinute = 60) Then
    begin
      gMinute := 0;
      gHour := gHour+1;
      if (gHour = 24) Then
        gHour := 0;
  end;

  BansTimer := BansTimer+1;
  if (BansTimer = 10) Then
  begin
    BansTimer := 0;
    lstBans.Items.SaveToFile(GetCurrentDir + '\bans.lst');
  end;
end;

procedure TfrmMain.OnMasterServerHeartbeat(Sender: TObject);
var
 Mssg: String;
begin

  try
    Mssg := HTTP.Get('http://www2.sa-party.com/announce.sap?port='+ IntToStr(Server.DefaultPort)+'&ver='+Version);
  except
    Mssg := '0';
  end;
  If not (Mssg = '1') Then
    Log('*** Masterlist Heartbeat failed');
end;

end.
