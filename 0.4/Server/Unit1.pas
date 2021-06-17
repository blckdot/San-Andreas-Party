unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdAntiFreezeBase, IdAntiFreeze, IdBaseComponent, IdComponent,
  IdUDPBase, IdUDPServer, StdCtrls, IdSocketHandle, MD5, ExtCtrls, INIFiles,
  JvSimpleXml, uPSComponent, JvTimerList, IdTCPConnection, IdTCPClient,
  IdIRC, IdTCPServer;

type
  PClient = ^TClient;
  TClient = record
    IP : String;
    Thread : Pointer;
    Port : Integer;
  end;
  TPlayer = record
    PlayerID,
    Interior,
    Ping,
    Port,
    Skin,
    Flags,
    Money,
    Vehicle,
    VehicleLast,
    Seat,
    Handle : Integer;
    Connected,
    PingReceived,
    Ping2Received,
    Ingame : Boolean;
    Name,
    IP : String;
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
    Script,
    IRCServer : String;
    HardcodedMaxPlayers,
    PlayersConnected,
    LastPingCheck,
    MaxPlayers,
    StartCount,
    Hour,
    Minute,
    IRCPort,
    Weather : Integer;
    Gravity : Single;
    IRCEnabled,
    WaterWalk,
    Fly : Boolean;
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
  TVehicle = record
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
  TCheckpoint = record
    InUse : Boolean;
    PosX,
    PosY,
    PosZ,
    Radius : Single;
  end;
  TSplitArray = array of String;
  TfrmMain = class(TForm)
    udpAntiFreeze: TIdAntiFreeze;
    memoLog: TMemo;
    tmrPingCheck: TTimer;
    PScript: TPSScript;
    tmrClock: TTimer;
    udpServer: TIdTCPServer;
    procedure OnFormCreate(Sender: TObject);
    procedure SendDataToAll(Buffer : String);
    procedure SendDataToAllExceptPlayer(PlayerID : integer; Buffer : String);
    procedure SendDataToPlayer(PlayerID : Integer; Buffer : String);
    procedure OnPingCheck(Sender: TObject);
    procedure Err(Str : String);
    procedure AddToConsole(Str : String);
    procedure OnScriptCompile(Sender: TPSScript);
    function  GetPlayerName(PlayerID : Integer): String;
    function  GetPlayerPing(PlayerID : Integer): Integer;
    function  IsInteger(Str: String): Boolean;
    function  IsFloat(Str: String): Boolean;
    procedure SendMessageToPlayer(PlayerID : Integer; Buffer : String);
    procedure SendMessageToAllExceptPlayer(PlayerID : Integer; Buffer : String);
    procedure SendMessageToAll(Buffer : String);
    function  GetTickCountFromServer(): Integer;
    function  Split(const Source, Delimiter: String): TSplitArray;
    procedure OnFormClose(Sender: TObject; var Action: TCloseAction);
    function  IsPlayerIngame(PlayerID : Integer): Boolean;
    function  IsPlayerConnected(PlayerID : Integer): Boolean;
    procedure SetPlayerSkin(PlayerID, SkinID : Integer);
    function  GetPlayerRotation(PlayerID : Integer): Single;
    function  GetPlayerPosZ(PlayerID : Integer): Single;
    function  GetPlayerPosY(PlayerID : Integer): Single;
    function  GetPlayerPosX(PlayerID : Integer): Single;
    function  GetPlayerSkin(PlayerID : Integer): Integer;
    procedure GivePlayerWeapon(PlayerID, WeaponID, Ammo : Integer);
    procedure SetPlayerPos(PlayerID : Integer; X, Y, Z : Single);
    procedure SetPlayerRotation(PlayerID : Integer; Value : Single);
    procedure SetPlayerArmor(PlayerID : Integer; Value : Single);
    procedure SetPlayerHealth(PlayerID : Integer; Value : Single);
    procedure OnClockTimer(Sender: TObject);
    procedure SetGameTime(Hour, Minute : Integer);
    procedure SetGameWeather(WeatherID : Integer);
    procedure SetGravity(Value : Single);
    procedure SetWaterWalk(Value : Boolean);
    function StrToFloatFix(Str: String): Single;
    procedure SetPlayerFlags(PlayerID : Integer; Value : Integer);
    function GetPlayerFlags(PlayerID : Integer): Integer;
    procedure SetPlayerMoney(PlayerID : Integer; Value : Integer);
    function GetPlayerMoney(PlayerID : Integer): Integer;
    function CopyBetween(Source, bs, es : String): String;
    function CopyAfter(Source, bs : String): String;
    function CopyBefore(Source, bs : String): String;
    procedure AddObject(ModelID : Integer; PosX, PosY, PosZ, RotX, RotY, RotZ : Single);
    function AddObjectEx(ModelID : Integer; PosX, PosY, PosZ, RotX, RotY, RotZ : Single): Integer;
    procedure CreateSparks(PosX, PosY, PosZ, RotX, RotY, RotZ : Single; Density : Integer);
    procedure PointCameraAt(PlayerID : Integer; X, Y, Z : Single);
    procedure SetCamera(PlayerID : Integer; X, Y, Z : Single);
    procedure PlaySound(PlayerID, SoundID : Integer);
    procedure RestoreCamera(PlayerID: Integer);
    procedure CreateExplosion(X, Y, Z : Single);
    procedure FreezePlayer(PlayerID : Integer; Toggle : Boolean);
    procedure AllowPlayerToShoot(PlayerID : Integer; Toggle : Boolean);
    procedure AllowPlayerToChangeWeapon(PlayerID : Integer; Toggle : Boolean);
    procedure SetPlayerCrouch(PlayerID : Integer; Toggle : Boolean);
    procedure UndoLastWeaponDamage(PlayerID : Integer);
    procedure SetPlayerArmedWeapon(PlayerID, WeaponID : Integer);
    procedure SetPlayerHUD(PlayerID : Integer; Enabled : Boolean);
    procedure SetPlayerHUDGrey(PlayerID : Integer; Enabled : Boolean);
    procedure SetPlayerRadar(PlayerID : Integer; Enabled : Boolean);
    procedure SetPlayerWidescreen(PlayerID : Integer; Enabled : Boolean);
    procedure SetPlayerColor(PlayerID, Color : Integer);
    procedure AllowPlayerToCrouch(PlayerID : Integer; Toggle : Boolean);
    procedure AllowPlayerToJump(PlayerID : Integer; Toggle : Boolean);
    procedure DeleteObject(ObjectID : Integer);
    procedure SetObjectPosition(ObjectID : Integer; X, Y, Z : Single);
    procedure SetObjectMove(ObjectID : Integer; X, Y, Z : Single);
    procedure Timer(Seconds : Integer; Execute : String);
    function  GetDeathReason(ReasonID : Integer): String;
    procedure SetPlayerMoneyFormat(PlayerID : Integer; Format : String);
    procedure SetPlayerFadeScreen(PlayerID : Integer; Enabled : Boolean; Time : Integer);
    function GetVehicleName(Car : Integer): String;
    procedure AddVehicle(ModelID: Integer; PosX, PosY, PosZ, Rotation : Single;Color1, Color2 : Integer);
    function  AddVehicleEx(ModelID: Integer; PosX, PosY, PosZ, Rotation : Single;Color1, Color2 : Integer): Integer;
    procedure SetFly(Enabled : Boolean);
    function GetObjectPosX(ObjectID : Integer): Single;
    function GetObjectPosY(ObjectID : Integer): Single;
    function GetObjectPosZ(ObjectID : Integer): Single;
    function GetObjectRotX(ObjectID : Integer): Single;
    function GetObjectRotY(ObjectID : Integer): Single;
    function GetObjectRotZ(ObjectID : Integer): Single;
    function GetObjectModel(ObjectID : Integer): Integer;
    function GetVehicleModel(VehicleID : Integer): Integer;
    procedure CreateCheckpoint(PlayerID : Integer; PosX, PosY, PosZ, Size : Single);
    function CreateCheckpointEx(PlayerID : Integer; PosX, PosY, PosZ, Size : Single): Integer;
    procedure udpServerDisconnect(AThread: TIdPeerThread);
    procedure udpServerExecute(AThread: TIdPeerThread);
    procedure udpServerConnect(AThread: TIdPeerThread);
    //function  AddTimer(): Integer;
    //procedure OnScriptTimer();
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;
  Player : Array [1..32] of TPlayer;
  Server : TServer;
  lstTimers : TStrings;
  Objects : Array [0..1000] of TtObject;
  Vehicles : Array [0..5000] of TVehicle;
  Checkpoints : Array[1..(100 * 32)] of TCheckpoint; // Elke speler 100 checkpoints \o/
  gSpawnedObjects, gSpawnedVehicles : Integer;
  Clients : TThreadList;


implementation

{$R *.dfm}

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

function GetWeaponName(WeaponID : Integer): String;
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
    Result := 'Unknown > ID '+ IntToStr(WeaponID);
end;

function TfrmMain.GetDeathReason(ReasonID : Integer): String;
begin
  result := GetWeaponName(ReasonID);
end;

function calcMD5(Buffer : String): String;
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
    {if (Player[PlayerID].Connected = True) then
      udpServer.SendBuffer(Player[PlayerID].IP, Player[PlayerID].Port, Buffer[1], Length(Buffer)); }
end;

procedure TfrmMain.SendMessageToPlayer(PlayerID : Integer; Buffer : String);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  SendDataToPlayer(PlayerID, 'CHAT|0|'+StringReplace(Buffer, '|', '.',[rfReplaceAll, rfIgnoreCase]));
end;

procedure TfrmMain.SendMessageToAllExceptPlayer(PlayerID : Integer; Buffer : String);
begin
   SendDataToAllExceptPlayer(PlayerID, 'CHAT|0|'+StringReplace(Buffer, '|', '.',[rfReplaceAll, rfIgnoreCase]));
end;

procedure TfrmMain.SendMessageToAll(Buffer : String);
begin
   SendDataToAll('CHAT|0|'+StringReplace(Buffer, '|', '.',[rfReplaceAll, rfIgnoreCase]));
end;

procedure ClearPlayerSlot(PlayerID : Integer);
begin
      Player[PlayerID].Connected := False;
      Player[PlayerID].Money := 0;
      Player[PlayerID].Ping := 0;
      Player[PlayerID].Vehicle := 0;
      Player[PlayerID].VehicleLast := 0;
      Player[PlayerID].Seat := 0;
      //Player[PlayerID].Admin := False;
      Player[PlayerID].Interior := 0;
      //Player[PlayerID].Frozen := False;
      Player[PlayerID].PingReceived := True;
      Player[PlayerID].Ping2Received := True;
      Player[PlayerID].PlayerID := 0;
      //Player[PlayerID].Vehicle := 0;
      Player[PlayerID].Ingame := False;
      Player[PlayerID].Name := '';
      Player[PlayerID].PosX := 0.0;
      Player[PlayerID].PosY := 0.0;
      Player[PlayerID].PosZ := 0.0;
      Player[PlayerID].Rotation := 0.0;
      Player[PlayerID].IP := '0.0.0.0';
      Player[PlayerID].Port := 0;
      Player[PlayerID].Flags := 0;
      Player[PlayerID].Handle := 0;
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

procedure TfrmMain.AddToConsole(Str : String);
begin
  memoLog.lines.add(Str);
end;

function TfrmMain.GetPlayerName(PlayerID : Integer): String;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := ''
  Else
    result := Player[PlayerID].Name;
end;

function TfrmMain.IsPlayerConnected(PlayerID : Integer): Boolean;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := False
  Else
    result := Player[PlayerID].Connected;
end;

function TfrmMain.IsPlayerIngame(PlayerID : Integer): Boolean;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := False
  Else
    result := Player[PlayerID].Ingame;
end;


function TfrmMain.GetPlayerPing(PlayerID : Integer): Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0
  Else
    result := Player[PlayerID].Ping;
end;

function TfrmMain.GetTickCountFromServer(): Integer;
begin
  result := GetTickCount()-Server.StartCount;
end;

procedure TfrmMain.SetPlayerSkin(PlayerID, SkinID : Integer);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  if (SkinID = 0) OR (SkinID = 7) OR                 // 1 and 7
      (SkinID > 8) AND (SkinID < 42) OR              // 9 - 41
      (SkinID > 42) AND (SkinID < 65) OR             // 43 - 64
      (SkinID > 65) AND (SkinID < 74) OR             // 66 - 73
      (SkinID > 74) AND (SkinID < 86) OR             // 75 - 85
      (SkinID > 86) AND (SkinID < 208) AND           // 87 - 207
      not (SkinID = 149) AND not (SkinID = 119) OR   // Without 149 and 119
      (SkinID > 208) AND (SkinID < 264) OR           // 209 - 263
      (SkinID > 273) AND (SkinID < 289) then         // 274 - 288
    SendDataToPlayer(PlayerID, 'SETSKIN|'+IntToStr(SkinID))
  else
    Exit;
end;

procedure TfrmMain.GivePlayerWeapon(PlayerID, WeaponID, Ammo : Integer);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  SendDataToPlayer(PlayerID, 'RMAP|weapon|'+IntToStr(WeaponID)+'|'+IntToStr(Ammo));
end;

procedure TfrmMain.SetGameWeather(WeatherID : Integer);
begin
  //SendDataToPlayer(PlayerID, 'SETWEATHER|'+IntToStr(WeatherID));
  SendDataToAll('SETWEATHER|'+IntToStr(WeatherID));
  Server.Weather := WeatherID;
end;

procedure TfrmMain.SetPlayerFadeScreen(PlayerID : Integer; Enabled : Boolean; Time : Integer);
var
  i : Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  If (Enabled = True) Then
    i := 1
  Else
    i := 0;

  SendDataToPlayer(PlayerID, 'RMAP|fade|'+IntToStr(i)+'|'+IntToStr(Time));
end;

procedure TfrmMain.SetPlayerMoneyFormat(PlayerID : Integer; Format : String);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;

  SendDataToPlayer(PlayerID, 'SETMONFOR|'+ Format);
end;

procedure TfrmMain.SetGameTime(Hour, Minute : Integer);
begin
  SendDataToAll('SETTIME|'+IntToStr(Hour)+'|'+IntToStr(Minute));
  Server.Minute := Minute;
  Server.Hour := Hour;
end;

procedure TfrmMain.SetPlayerPos(PlayerID : Integer; X, Y, Z : Single);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  SendDataToPlayer(PlayerID, 'SETPOSITION|'+FloatToStr(X)+'|'+FloatToStr(Y)+'|'+FloatToStr(Z));
end;

procedure TfrmMain.SetPlayerHealth(PlayerID : Integer; Value : Single);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  SendDataToPlayer(PlayerID, 'SETHEALTH|'+FloatToStr(Value));
end;

procedure TfrmMain.SetPlayerArmor(PlayerID : Integer; Value : Single);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  SendDataToPlayer(PlayerID, 'SETARMOR|'+FloatToStr(Value));
end;

procedure TfrmMain.SetGravity(Value : Single);
begin
  SendDataToAll('SETGRAVITY|'+FloatToStr(Value));
  Server.Gravity := Value;
end;

procedure TfrmMain.SetWaterWalk(Value : Boolean);
begin
  if (Value = True) then
  begin
    Server.WaterWalk := True;
    SendDataToAll('SETWATERWALK|1');
  end
  else
  begin
    Server.WaterWalk := False;
    SendDataToAll('SETWATERWALK|0');
  end;
end;

procedure TfrmMain.SetFly(Enabled : Boolean);
begin
  if (Enabled = True) then
  begin
    Server.Fly := True;
    SendDataToAll('SETFLY|1');
  end
  else
  begin
    Server.Fly := False;
    SendDataToAll('SETFLY|0');
  end;
end;

procedure TfrmMain.SetPlayerRotation(PlayerID : Integer; Value : Single);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  SendDataToPlayer(PlayerID, 'RMAP|setrotation|'+FloatToStr(Value));
end;

procedure TfrmMain.SetPlayerFlags(PlayerID : Integer; Value : Integer);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  SendDataToPlayer(PlayerID, 'SETFLAGS|'+IntToStr(Value));
  Player[PlayerID].Flags := Value;
end;

procedure TfrmMain.CreateExplosion(X, Y, Z : Single);
begin
  SendDataToAll('RMAP|explos|'+ FloatToStr(X) +'|'+ FloatToStr(Y) +'|'+ FloatToStr(Z));
end;

procedure TfrmMain.CreateSparks(PosX, PosY, PosZ, RotX, RotY, RotZ : Single; Density : Integer);
begin
  SendDataToAll('RMAP|sparks|'+ FloatToStr(PosX) +'|'+ FloatToStr(PosY) +'|'+ FloatToStr(PosZ) +'|'+ FloatToStr(RotX) +'|'+ FloatToStr(RotY) +'|'+ FloatToStr(RotZ) +'|'+ IntToStr(Density));
end;

procedure TfrmMain.PointCameraAt(PlayerID : Integer; X, Y, Z : Single);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  SendDataToPlayer(PlayerID,'RMAP|setcamaim|'+ FloatToStr(X) +'|'+ FloatToStr(Y) +'|'+ FloatToStr(Z));
end;

procedure TfrmMain.SetCamera(PlayerID : Integer; X, Y, Z : Single);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  SendDataToPlayer(PlayerID,'RMAP|setcamera|'+ FloatToStr(X) +'|'+ FloatToStr(Y) +'|'+ FloatToStr(Z));
end;

procedure TfrmMain.PlaySound(PlayerID, SoundID : Integer);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  SendDataToPlayer(PlayerID,'RMAP|playsound|'+ IntToStr(SoundID));
end;

procedure TfrmMain.RestoreCamera(PlayerID: Integer);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  SendDataToPlayer(PlayerID,'RMAP|setrescam|1337');
end;

procedure TfrmMain.FreezePlayer(PlayerID : Integer; Toggle : Boolean);
var
  i : Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  If (Toggle = True) Then
    i := 1
  Else
    i := 0;
  //SendDataToAll('RMAP|freeze|'+ IntToStr(PlayerID) +'|'+ IntToStr(i));
  SendDataToPlayer(PlayerID,'RMAP|freeze|'+ IntToStr(PlayerID) +'|'+ IntToStr(i));
end;

procedure TfrmMain.AllowPlayerToJump(PlayerID : Integer; Toggle : Boolean);
var
  i : Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  If (Toggle = True) Then
    i := 1
  Else
    i := 0;
  SendDataToPlayer(PlayerID,'RMAP|allowjump|'+ IntToStr(i));
end;

procedure TfrmMain.AllowPlayerToShoot(PlayerID : Integer; Toggle : Boolean);
var
  i : Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  If (Toggle = True) Then
    i := 1
  Else
    i := 0;
  SendDataToPlayer(PlayerID,'RMAP|allowshoot|'+ IntToStr(i));
end;

procedure TfrmMain.AllowPlayerToChangeWeapon(PlayerID : Integer; Toggle : Boolean);
var
  i : Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  If (Toggle = True) Then
    i := 1
  Else
    i := 0;
  SendDataToPlayer(PlayerID,'RMAP|allowscroll|'+ IntToStr(i));
end;

procedure TfrmMain.SetPlayerCrouch(PlayerID : Integer; Toggle : Boolean);
var
  i : Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  If (Toggle = True) Then
    i := 1
  Else
    i := 0;
  SendDataToPlayer(PlayerID,'RMAP|setcrouch|'+ IntToStr(i));
end;

procedure TfrmMain.UndoLastWeaponDamage(PlayerID : Integer);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  SendDataToPlayer(PlayerID,'RMAP|cleardamage|1337');
end;

procedure TfrmMain.SetPlayerArmedWeapon(PlayerID, WeaponID : Integer);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) Or (WeaponID > 70) then
    Exit;
  SendDataToPlayer(PlayerID,'RMAP|setarmedweapon|'+ IntToStr(WeaponID));
end;

procedure TfrmMain.SetPlayerHUD(PlayerID : Integer; Enabled : Boolean);
var
  i : Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  If (Enabled = True) Then
    i := 1
  Else
    i := 0;
  SendDataToPlayer(PlayerID,'RMAP|sethud|'+ IntToStr(i));
end;

procedure TfrmMain.SetPlayerHUDGrey(PlayerID : Integer; Enabled : Boolean); // Radar grey
var
  i : Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  If (Enabled = True) Then
    i := 1
  Else
    i := 0;
  SendDataToPlayer(PlayerID,'RMAP|setradargrey|'+ IntToStr(i));
end;

procedure TfrmMain.SetPlayerRadar(PlayerID : Integer; Enabled : Boolean);
var
  i : Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  If (Enabled = True) Then
    i := 1
  Else
    i := 0;
  SendDataToPlayer(PlayerID,'RMAP|setradar|'+ IntToStr(i));
end;

procedure TfrmMain.SetPlayerWidescreen(PlayerID : Integer; Enabled : Boolean);
var
  i : Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  If (Enabled = True) Then
    i := 1
  Else
    i := 0;
  SendDataToPlayer(PlayerID,'RMAP|setwidescreen|'+ IntToStr(i));
end;

procedure TfrmMain.SetPlayerColor(PlayerID, Color : Integer);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) or (Color > 99) or (Color < -1) then
    Exit;
  SendDataToPlayer(PlayerID,'RMAP|setcolor|'+ IntToStr(Color));
end;

procedure TfrmMain.AllowPlayerToCrouch(PlayerID : Integer; Toggle : Boolean);
var
  i : Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  If (Toggle = True) Then
    i := 1
  Else
    i := 0;
  SendDataToPlayer(PlayerID,'RMAP|allowcrouch|'+ IntToStr(i));
end;

function TfrmMain.GetPlayerFlags(PlayerID : Integer): Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0
  Else
    result := Player[PlayerID].Flags;
end;

procedure TfrmMain.SetPlayerMoney(PlayerID : Integer; Value : Integer);
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    Exit;
  SendDataToPlayer(PlayerID, 'SETMONEY|'+IntToStr(Value));
  Player[PlayerID].Money := Value;
end;

function TfrmMain.GetPlayerMoney(PlayerID : Integer): Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0
  Else
    result := Player[PlayerID].Money;
end;

function TfrmMain.GetPlayerSkin(PlayerID : Integer): Integer;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0
  Else
    result := Player[PlayerID].Skin;
end;

function TfrmMain.GetPlayerPosX(PlayerID : Integer): Single;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0.0
  Else
    result := Player[PlayerID].PosX;
end;

function TfrmMain.GetPlayerPosY(PlayerID : Integer): Single;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0.0
  Else
    result := Player[PlayerID].PosY;
end;

function TfrmMain.GetPlayerPosZ(PlayerID : Integer): Single;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0.0
  Else
    result := Player[PlayerID].PosZ;
end;

function TfrmMain.GetPlayerRotation(PlayerID : Integer): Single;
begin
  if (PlayerID >= Server.HardcodedMaxPlayers) OR (PlayerID < 1) then
    result := 0.0
  Else
    result := Player[PlayerID].Rotation;
end;
               {
function TfrmMain.AddTimer(): Integer;
begin
  result := JvTimers.Add('OnScriptTimer', 1000, True);
end;

procedure TfrmMain.OnScriptTimer();
begin
    // echo moo
end;
}

procedure TfrmMain.Timer(Seconds : Integer; Execute : String);
begin
  lstTimers.Add(IntToStr(Seconds) +' '+ Execute);
end;

procedure TfrmMain.OnScriptCompile(Sender: TPSScript);
begin
  // Procedures
  PScript.AddMethod(Self, @TfrmMain.AddToConsole,                 'procedure Print(Str : String);');
  PScript.AddMethod(Self, @TfrmMain.SendMessageToPlayer,          'procedure SendMessageToPlayer(PlayerID : Integer; Mssg : String);');
  PScript.AddMethod(Self, @TfrmMain.SendMessageToAll,             'procedure SendMessageToAll(Mssg : String);');
  PScript.AddMethod(Self, @TfrmMain.SendMessageToAllExceptPlayer, 'procedure SendMessageToAllExceptPlayer(PlayerID : Integer; Mssg : String);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerSkin,                'procedure SetPlayerSkin(PlayerID, SkinID : Integer);');
  PScript.AddMethod(Self, @TfrmMain.GivePlayerWeapon,             'procedure GivePlayerWeapon(PlayerID, WeaponID, Ammo : Integer);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerPos,                 'procedure SetPlayerPos(PlayerID : Integer; X, Y, Z : Single);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerRotation,            'procedure SetPlayerRotation(PlayerID : Integer; Value : Single);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerArmor,               'procedure SetPlayerArmour(PlayerID : Integer; Value : Single);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerHealth,              'procedure SetPlayerHealth(PlayerID : Integer; Value : Single);');
  PScript.AddMethod(Self, @TfrmMain.SetGameWeather,             'procedure SetGameWeather(WeatherID : Integer);');
  PScript.AddMethod(Self, @TfrmMain.SetGameTime,                  'procedure SetGameTime(Hour, Minute : Integer);');
  PScript.AddMethod(Self, @TfrmMain.SetGravity,                   'procedure SetGravity(Value : Single);');
  PScript.AddMethod(Self, @TfrmMain.SetWaterWalk,                 'procedure SetWaterWalk(Value : Boolean);');
{  PScript.AddMethod(Self, @TfrmMain.IRCJoin,                 'procedure IRCJoin(Channel, Password : String);');
  PScript.AddMethod(Self, @TfrmMain.IRCPart,                 'procedure IRCPart(Channel, Reason : String);');
  PScript.AddMethod(Self, @TfrmMain.IRCNotice,                 'procedure IRCNotice(Channel, Mssg : String);');
  PScript.AddMethod(Self, @TfrmMain.IRCAction,                 'procedure IRCAction(Channel, Mssg : String);');
  PScript.AddMethod(Self, @TfrmMain.IRCRaw,                 'procedure IRCRaw( Mssg : String);'); }
  PScript.AddMethod(Self, @TfrmMain.SetPlayerFlags,                 'procedure SetPlayerFlags(PlayerID : Integer; Value : Integer);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerMoney,                 'procedure SetPlayerMoney(PlayerID : Integer; Value : Integer);');
  PScript.AddMethod(Self, @TfrmMain.AddObject,'procedure CreateObject(ModelID : Integer; PosX, PosY, PosZ, RotX, RotY, RotZ : Single);');
  PScript.AddMethod(Self, @TfrmMain.AddObjectEx,'function CreateObjectEx(ModelID : Integer; PosX, PosY, PosZ, RotX, RotY, RotZ : Single): Integer;');
  // Functions
  PScript.AddMethod(Self, @TfrmMain.GetPlayerName,                'function GetPlayerName(PlayerID : Integer): String;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerPing,                'function GetPlayerPing(PlayerID : Integer): Integer;');
  PScript.AddMethod(Self, @TfrmMain.IsInteger,                    'function IsInteger(Str: String): Boolean;');
  PScript.AddMethod(Self, @TfrmMain.IsFloat,                      'function IsFloat(Str: String): Boolean;');
  PScript.AddMethod(Self, @TfrmMain.GetTickCountFromServer,       'function GetTickCount(): Integer;');
  PScript.AddMethod(Self, @TfrmMain.IsPlayerIngame,               'function IsPlayerIngame(PlayerID : Integer): Boolean;');
  PScript.AddMethod(Self, @TfrmMain.IsPlayerConnected,            'function IsPlayerConnected(PlayerID : Integer): Boolean;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerSkin,                'function GetPlayerSkin(PlayerID : Integer): Integer;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerPosX,                'function GetPlayerPosX(PlayerID : Integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerPosY,                'function GetPlayerPosY(PlayerID : Integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerPosZ,                'function GetPlayerPosZ(PlayerID : Integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerRotation,            'function GetPlayerRotation(PlayerID : Integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerFlags,            'function GetPlayerFlags(PlayerID : Integer): Integer;');
  PScript.AddMethod(Self, @TfrmMain.GetPlayerMoney,            'function GetPlayerMoney(PlayerID : Integer): Integer;');

//  PScript.AddMethod(Self, @TfrmMain.IRCGetHostname,            'function IRCGetHostname(Nickname : String): String;');
  PScript.AddMethod(Self, @TfrmMain.StrToFloatFix,            'function StrToFloatFix(Str: String): Single;'); // StrToFloatFix houd rekening met , en .
  PScript.AddMethod(Self, @TfrmMain.CopyBetween,            'function CopyBetween(Source, bs, es : String): String;');
  PScript.AddMethod(Self, @TfrmMain.CopyAfter,            'function CopyAfter(Source, bs : String): String;');
  PScript.AddMethod(Self, @TfrmMain.CopyBefore,            'function CopyBefore(Source, bs : String): String;');

  // NEW!
  PScript.AddMethod(Self, @TfrmMain.CreateExplosion,'procedure CreateExplosion(X, Y, Z : Single);');
  PScript.AddMethod(Self, @TfrmMain.CreateSparks,'procedure CreateSparks(PosX, PosY, PosZ, RotX, RotY, RotZ : Single; Density : Integer);');
  PScript.AddMethod(Self, @TfrmMain.PointCameraAt,'procedure PointCameraAt(PlayerID : Integer; X, Y, Z : Single);');
  PScript.AddMethod(Self, @TfrmMain.SetCamera,'procedure SetCamera(PlayerID : Integer; X, Y, Z : Single);');
  PScript.AddMethod(Self, @TfrmMain.PlaySound,'procedure PlaySound(PlayerID, SoundID : Integer);');
  PScript.AddMethod(Self, @TfrmMain.RestoreCamera,'procedure RestoreCamera(PlayerID: Integer);');
  PScript.AddMethod(Self, @TfrmMain.AllowPlayerToJump,'procedure AllowPlayerToJump(PlayerID : Integer; Toggle : Boolean);');
  PScript.AddMethod(Self, @TfrmMain.AllowPlayerToShoot,'procedure AllowPlayerToShoot(PlayerID : Integer; Toggle : Boolean);');
  PScript.AddMethod(Self, @TfrmMain.AllowPlayerToChangeWeapon,'procedure AllowPlayerToChangeWeapon(PlayerID : Integer; Toggle : Boolean);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerCrouch,'procedure SetPlayerCrouch(PlayerID : Integer; Toggle : Boolean);');
  PScript.AddMethod(Self, @TfrmMain.UndoLastWeaponDamage,'procedure UndoLastWeaponDamage(PlayerID : Integer);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerArmedWeapon,'procedure SetPlayerArmedWeapon(PlayerID, WeaponID : Integer);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerHUD,'procedure SetPlayerHUD(PlayerID : Integer; Enabled : Boolean);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerHUDGrey,'procedure SetPlayerRadarGrey(PlayerID : Integer; Enabled : Boolean);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerRadar,'procedure SetPlayerRadar(PlayerID : Integer; Enabled : Boolean);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerWidescreen,'procedure SetPlayerWidescreen(PlayerID : Integer; Enabled : Boolean);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerColor,'procedure SetPlayerColor(PlayerID, Color : Integer);');
  PScript.AddMethod(Self, @TfrmMain.AllowPlayerToCrouch,'procedure AllowPlayerToCrouch(PlayerID : Integer; Toggle : Boolean);');
  PScript.AddMethod(Self, @TfrmMain.DeleteObject,'procedure DestroyObject(UniqueID : Integer);');
  PScript.AddMethod(Self, @TfrmMain.FreezePlayer,'procedure FreezePlayer(PlayerID : Integer; Toggle : Boolean);');
  PScript.AddMethod(Self, @TfrmMain.GetDeathReason,'function GetDeathReason(ReasonID : Integer): String;');
  PScript.AddMethod(Self, @TfrmMain.SetObjectPosition,'procedure SetObjectPos(ObjectID : Integer; X, Y, Z : Single);');
  PScript.AddMethod(Self, @TfrmMain.SetObjectMove,'procedure MoveObject(ObjectID : Integer; X, Y, Z : Single);');
  PScript.AddMethod(Self, @TfrmMain.Timer,'procedure Timer(Seconds : Integer; Execute : String);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerMoneyFormat,'procedure SetPlayerMoneyFormat(PlayerID : Integer; Format : String);');
  PScript.AddMethod(Self, @TfrmMain.SetPlayerFadeScreen,'procedure SetPlayerFadeScreen(PlayerID : Integer; Enabled : Boolean; Time : Integer);');
  PScript.AddMethod(Self, @TfrmMain.GetVehicleName,'function GetVehicleName(ModelID : Integer): String;');
  PScript.AddMethod(Self, @TfrmMain.AddVehicle,'procedure CreateVehicle(ModelID: Integer; PosX, PosY, PosZ, Rotation : Single;Color1, Color2 : Integer);');
  PScript.AddMethod(Self, @TfrmMain.CreateCheckpoint,'procedure CreateCheckpoint(PlayerID : Integer; PosX, PosY, PosZ, Size : Single);');
  PScript.AddMethod(Self, @TfrmMain.CreateCheckpointEx,'function CreateCheckpointEx(PlayerID : Integer; PosX, PosY, PosZ, Size : Single): Integer;');
  PScript.AddMethod(Self, @TfrmMain.AddVehicleEx,'function CreateVehicleEx(ModelID: Integer; PosX, PosY, PosZ, Rotation : Single;Color1, Color2 : Integer): Integer;');
  PScript.AddMethod(Self, @TfrmMain.SetFly,'procedure SetFlyingCars(Enabled : Boolean);');
  PScript.AddMethod(Self, @TfrmMain.GetObjectPosX,'function GetObjectPosX(ObjectID : Integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetObjectPosY,'function GetObjectPosY(ObjectID : Integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetObjectPosZ,'function GetObjectPosZ(ObjectID : Integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetObjectRotX,'function GetObjectRotX(ObjectID : Integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetObjectRotY,'function GetObjectRotY(ObjectID : Integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetObjectRotZ,'function GetObjectRotZ(ObjectID : Integer): Single;');
  PScript.AddMethod(Self, @TfrmMain.GetObjectModel,'function GetObjectModel(ObjectID : Integer): Integer;');
  PScript.AddMethod(Self, @TfrmMain.GetVehicleModel,'function GetVehicleModel(VehicleID : Integer): Integer;');
end;

procedure TfrmMain.OnFormClose(Sender: TObject; var Action: TCloseAction);
begin
  Clients.Free;
  lstTimers.Free;
{  If (IRC.Connected = True) Then
    IRC.Disconnect;}
  SendDataToAll('BAI|4');
  //Sleep(50);
  udpServer.Active := False;
  udpServer.Free;
  PScript.Free;
//  IRC.Free;
  udpAntiFreeze.Free;
  tmrPingCheck.Enabled := false;
  tmrPingCheck.Free;
  tmrClock.Enabled := false;
  tmrClock.Free;
end;

procedure TfrmMain.OnClockTimer(Sender: TObject);
var
  i, Int : Integer;
begin
  Server.Minute := Server.Minute+1;
  If (Server.Minute = 30) Then
    SendDataToAll('SETTIME|'+IntToStr(Server.Hour)+'|'+IntToStr(Server.Minute));
  if (Server.Minute = 60) then
  begin
    Server.Minute := 0;
    Server.Hour := Server.Hour + 1;
    if (Server.Hour = 24) then
      Server.Hour := 0;
    SendDataToAll('SETTIME|'+IntToStr(Server.Hour)+'|'+IntToStr(Server.Minute));
  end;

  If (lstTimers.Count = 0) Then
    Exit;
  For i := Pred(lstTimers.Count) DownTo 0 Do
  Begin
    If (CopyBefore(lstTimers[i],' ') = '0') Then
    Begin
      PScript.ExecuteFunction([],CopyAfter(lstTimers[i],' '));
      lstTimers.Delete(i);
    End
    Else
    Begin
      Int := StrToInt(CopyBefore(lstTimers[i],' '))-1;
      lstTimers[i] := IntToStr(Int) +' '+ CopyAfter(lstTimers[i],' ');
    End;
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
      Player[i].Connected := False;
      //SendToAllExceptPlayer(i, CLIENT_PACKET_HEADER+CLIENT_LEFT+chr(i));
      break;
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
{procedure TfrmMain.OnUDPRead(Sender: TObject; AData: TStream;
  ABinding: TIdSocketHandle);
var
    DataStringStream: TStringStream;
    Arr : TSplitArray;
    Str, Mssg : String;
    i, PlayerID, i2 : integer;
    Found : Boolean;
begin
  DataStringStream := TStringStream.Create('');
  Arr := Split('1|1', '|');
  try
    DataStringStream.CopyFrom(AData, AData.Size);}
  NewClient : PClient;
  RawString, Str, Str1, Str2, Mssg : String;
  Bool1, Found : Boolean;
  i, i1, i2, PlayerID : Integer;
  Arr : TSplitArray;
begin
 RawString := AThread.Connection.ReadLn('');
    // Syntax: INFO
    if (RawString = 'INFO') then
    begin
      // ADD query info here
      Str :=  StringReplace(Server.Name, '|', '.',[rfReplaceAll, rfIgnoreCase]);
      Str :=  StringReplace(Str, '~', '.',[rfReplaceAll, rfIgnoreCase]);
      if (Length(Server.Password) > 0) Then
        i := 1
      else
        i := 0;
      Str := 'INFOB|'+Str+'|'+IntToStr(Server.PlayersConnected)+'|'+IntToStr(Server.MaxPlayers)+'|'+IntToStr(i)+'|~';
      AThread.Connection.WriteLn(Str);
      Exit;
    end
    Else if (RawString = 'PLAYERS') then
    begin
      Str := 'PLAYERSB';
      For i := 0 To High(Player) Do
      Begin
        If (Player[i].Connected = True) Then
            Str := Str +'|'+IntToStr(i)+' '+Player[i].Name;
      End;
      Str := StringReplace(Str, '~', '.',[rfReplaceAll, rfIgnoreCase]);
      Str := Str+'|~';
      AThread.Connection.WriteLn(Str);
      Exit;
    end
    Else If (RawString = 'DMAP') Then
    Begin
      // objects
      For i := 1 To High(Objects) Do
      Begin
        If (Objects[i].InUse = True) Then
        begin
          Mssg := 'RMAP|o|'+ IntToStr(i) +'|'+ IntToStr(Objects[i].Model) +'|'+ FormatFloat('0.000',Objects[i].PosX) +'|'+ FormatFloat('0.000',Objects[i].PosY) +'|'+ FormatFloat('0.000',Objects[i].PosZ) +'|'+ FormatFloat('0.000',Objects[i].RotX) +'|'+ FormatFloat('0.000',Objects[i].RotY) +'|'+ FormatFloat('0.000',Objects[i].RotZ);
          AThread.Connection.WriteLn(Mssg);
        end;
      end;

      // vehicles
      For i := 1 To High(Vehicles) Do
      Begin
        If (Vehicles[i].InUse = True) Then
        begin
          Mssg := 'RMAP|v|'+IntToStr(i)+'|'+IntToStr(Vehicles[i].Model)+'|'+FormatFloat('0.000',Vehicles[i].PosX)+'|'+FormatFloat('0.000',Vehicles[i].PosY)+'|'+FormatFloat('0.000',Vehicles[i].PosZ)+'|'+ FormatFloat('0.000',Vehicles[i].Rot) +'|'+ IntToStr(Vehicles[i].Color1) +'|'+ IntToStr(Vehicles[i].Color1);
          AThread.Connection.WriteLn(Mssg);
        end;
      end;
      Mssg := 'RMAP|dolo|1337';
      AThread.Connection.WriteLn(Mssg);
      Exit;
    End;

    try
      Arr := Split(RawString, '|');
    except
      Exit;
    end;
    If (Arr[0] = 'CAR') Then
    Begin
     PlayerID := StrToInt(Arr[1]);
     if not (Player[PlayerID].Connected = True) OR not (Player[PlayerID].Port = AThread.Connection.Socket.Binding.PeerPort) OR not (Player[PlayerID].IP = AThread.Connection.Socket.Binding.PeerIP) then
        Exit;
     SendDataToAllExceptPlayer(PlayerID, RawString);
     //Player[PlayerID].Skin := StrToInt(Arr[2]);
     Player[PlayerID].Vehicle := StrToInt(Arr[3]);
     Player[PlayerID].Seat := StrToInt(Arr[4]);
     If not (Player[PlayerID].Vehicle = Player[PlayerID].VehicleLast) Then
     Begin
       PScript.ExecuteFunction([PlayerID,Player[PlayerID].Vehicle,Player[PlayerID].Seat],'OnPlayerEnterVehicle');
       Player[PlayerID].VehicleLast := Player[PlayerID].Vehicle;
     End;
     Player[PlayerID].PosX := StrToFloatFix(Arr[5]);
     Player[PlayerID].PosY := StrToFloatFix(Arr[6]);
     Player[PlayerID].PosZ := StrToFloatFix(Arr[7]);
     //memoLog.Lines.Add('Ik krijg CAR van '+ IntToStr(PlayerID));
    End
    Else If (Arr[0] = 'ONFOOT') then
    begin
     memoLog.Lines.Add('Packet (Check 1) from '+ IntToStr(PlayerID));
     PlayerID := StrToInt(Arr[1]);
     if not (Player[PlayerID].Connected = True) OR not (Player[PlayerID].Port = AThread.Connection.Socket.Binding.PeerPort) OR not (Player[PlayerID].IP = AThread.Connection.Socket.Binding.PeerIP) then
        Exit;
     SendDataToAllExceptPlayer(PlayerID, RawString);
     Player[PlayerID].Vehicle := 0;
     If not (Player[PlayerID].Vehicle = Player[PlayerID].VehicleLast) Then
     Begin
       PScript.ExecuteFunction([PlayerID,Player[PlayerID].VehicleLast],'OnPlayerLeaveVehicle');
       Player[PlayerID].VehicleLast := 0;
     End;
     memoLog.Lines.Add('Packet (Check 2) from '+ IntToStr(PlayerID));
     Player[PlayerID].VehicleLast := 0;
     Player[PlayerID].Seat := 0;
     Player[PlayerID].Skin := StrToInt(Arr[2]);
     If (High(Arr) < 6) Then
      Exit;
     Player[PlayerID].PosX := StrToFloatFix(Arr[3]);
     Player[PlayerID].PosY := StrToFloatFix(Arr[4]);
     Player[PlayerID].PosZ := StrToFloatFix(Arr[5]);
     Player[PlayerID].Rotation := StrToFloatFix(Arr[6]);
    end
    Else if (Arr[0] = 'CONN') then
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
                Str := 'CONNB|4|0';
                Break;
              end;
            end;
            if (Found = False) then
            begin
              // He passed all the checks!
              For i := 1 to High(Player) do
              begin
                if (Player[i].Connected = False) then
                begin
                  ClearPlayerSlot(i);
                  Player[i].Connected := True;
                  //Player[i].Admin := False;
                  Player[i].Interior := 0;
                  Player[i].PingReceived := True;
                  Player[i].Ping2Received := True;
                  Player[i].PlayerID := i;
                  Player[i].Name := Arr[2];
                  Player[i].Ingame := False;
                  Player[i].IP := AThread.Connection.Socket.Binding.PeerIP;
                  Player[i].Port := AThread.Connection.Socket.Binding.PeerPort;
                  Player[i].Handle := AThread.Handle;
                  PScript.ExecuteFunction([i],'OnPlayerJoin');
                  Server.PlayersConnected := Server.PlayersConnected+1;
                  Str := 'CONNECTED|'+IntToStr(i)+'|'+Arr[2];
                  SendDataToAllExceptPlayer(i, Str);
                  Str := 'CONNB|0|'+IntToStr(i);
                  Break;
                end;
              end;
            end;
          end
          else
          begin
            Str := 'CONNB|3|0';
          end;
        end
        else
        begin
          Str := 'CONNB|2|0';
        end;
      end
      Else
      begin
        Str := 'CONNB|1|0';
      end;
      AThread.Connection.WriteLn(Str);
      //memoLog.Lines.Add(Str);
    end
    Else if (Arr[0] = 'CHAT') then
    begin
      PlayerID := StrToInt(Arr[1]);
      if not (Player[PlayerID].Connected = True) OR not (Player[PlayerID].Port = AThread.Connection.Socket.Binding.PeerPort) OR not (Player[PlayerID].IP = AThread.Connection.Socket.Binding.PeerIP) then
        Exit;

      If ( Copy(Arr[2],0,1) = '/' ) Then
      Begin
        PScript.ExecuteFunction([PlayerID,Arr[2]],'OnPlayerCommand');
      end
      else
      begin
        i := PScript.ExecuteFunction([PlayerID,Arr[2]],'OnPlayerText');
        if not (i = 0) then
          SendDataToAll(RawString);
      end;
    end
    Else if (Arr[0] = 'DISCONNECT') then
    begin
      PlayerID := StrToInt(Arr[1]);
      if not (Player[PlayerID].Connected = True) OR not (Player[PlayerID].Port = AThread.Connection.Socket.Binding.PeerPort) OR not (Player[PlayerID].IP = AThread.Connection.Socket.Binding.PeerIP) then
        Exit;
      PScript.ExecuteFunction([PlayerID,0],'OnPlayerPart');
      if (Player[PlayerID].Ingame) then
        SendDataToAllExceptPlayer(PlayerID, 'GAMECLOSED|'+IntToStr(PlayerID));
      //AThread.Connection.WriteLn(Str);
      SendDataToPlayer(PlayerID, 'BAI|0');
      Server.PlayersConnected := Server.PlayersConnected-1;
      ClearPlayerSlot(PlayerID);
      SendDataToAllExceptPlayer(PlayerID,'DISCONNECTED|'+IntToStr(PlayerID) +'|0');
    end
    Else if (Arr[0] = 'SPAWNED') then
    begin
      PlayerID := StrToInt(Arr[1]);
      if not (Player[PlayerID].Connected = True) OR not (Player[PlayerID].Port = AThread.Connection.Socket.Binding.PeerPort) OR not (Player[PlayerID].IP = AThread.Connection.Socket.Binding.PeerIP) then
        Exit;
      PScript.ExecuteFunction([PlayerID],'OnPlayerSpawned');
      //SendDataToPlayer(PlayerID, 'SPAWNN|1337');
      SendDataToPlayer(PlayerID, 'SETTIME|'+IntToStr(Server.Hour)+'|'+IntToStr(Server.Minute));
      SendDataToPlayer(PlayerID, 'SETWEATHER|'+IntToStr(Server.Weather));
      SendDataToPlayer(PlayerID, 'SETGRAVITY|'+FloatToStr(Server.Gravity));
      if (Server.WaterWalk = True) then
        SendDataToPlayer(PlayerID, 'SETWATERWALK|1')
      Else
        SendDataToPlayer(PlayerID, 'SETWATERWALK|0');
      if (Server.Fly = True) then
        SendDataToPlayer(PlayerID, 'SETFLY|1')
      Else
        SendDataToPlayer(PlayerID, 'SETFLY|0');
    end
    Else if (Arr[0] = 'GAMESTARTED') then
    begin
      PlayerID := StrToInt(Arr[1]);
      if not (Player[PlayerID].Connected = True) OR not (Player[PlayerID].Port = AThread.Connection.Socket.Binding.PeerPort) OR not (Player[PlayerID].IP = AThread.Connection.Socket.Binding.PeerIP) then
        Exit;
      Player[PlayerID].Ingame := True;
      PScript.ExecuteFunction([PlayerID],'OnPlayerStartedGame');
    end
    Else if (Arr[0] = 'GAMECLOSED') then
    begin
      PlayerID := StrToInt(Arr[1]);
      if not (Player[PlayerID].Connected = True) OR not (Player[PlayerID].Port = AThread.Connection.Socket.Binding.PeerPort) OR not (Player[PlayerID].IP = AThread.Connection.Socket.Binding.PeerIP) then
        Exit;
      Player[PlayerID].Ingame := False;
      SendDataToAllExceptPlayer(PlayerID, 'GAMECLOSED|'+IntToStr(PlayerID));
      PScript.ExecuteFunction([PlayerID],'OnPlayerClosedGame');
    end
    Else If (Arr[0] = 'DEATH') Then
    Begin
      PlayerID := StrToInt(Arr[1]); // Who died?
      i := StrToInt(Arr[2]); // The killer
      i2 := StrToInt(Arr[3]); // The weapon
      PScript.ExecuteFunction([PlayerID,i,i2],'OnPlayerDeath'); // Killer (ID), Player (ID), Reason (ID)
    End
    Else if (Arr[0] = 'PONG') then
    begin
     PlayerID := StrToInt(Arr[1]);
     if not (Player[PlayerID].Connected = True) OR not (Player[PlayerID].Port = AThread.Connection.Socket.Binding.PeerPort) OR not (Player[PlayerID].IP = AThread.Connection.Socket.Binding.PeerIP) then
        Exit;
     Player[PlayerID].PingReceived := True;
     Player[PlayerID].Ping2Received := True;
     Player[PlayerID].Ping := GetTickCount()-Server.LastPingCheck;
    end
    Else if (Arr[0] = 'CPIN') then
    begin
     PlayerID := StrToInt(Arr[1]);
     i := StrToInt(Arr[2]);
     PScript.ExecuteFunction([PlayerID,i],'OnPlayerEnterCheckpoint');
    end
    Else if (Arr[0] = 'CPOUT') then
    begin
     PlayerID := StrToInt(Arr[1]);
     i := StrToInt(Arr[2]);
     PScript.ExecuteFunction([PlayerID,i],'OnPlayerLeaveCheckpoint');
    end;
{  finally
    DataStringStream.Free;
  end;}
end;

procedure TfrmMain.SetObjectPosition(ObjectID : Integer; X, Y, Z : Single);
begin
  if (Objects[ObjectID].InUse = False) Then
    Exit;
  SendDataToAll('RMAP|objpos|'+ IntToStr(ObjectID) +'|'+ FloatToStr(X) +'|'+ FloatToStr(Y) +'|'+ FloatToStr(Z));
  Objects[ObjectID].PosX := X;
  Objects[ObjectID].PosY := Y;
  Objects[ObjectID].PosZ := Z;
end;

procedure TfrmMain.SetObjectMove(ObjectID : Integer; X, Y, Z : Single);
begin
  if (Objects[ObjectID].InUse = False) Then
    Exit;
  SendDataToAll('RMAP|objmove|'+ IntToStr(ObjectID) +'|'+ FloatToStr(X) +'|'+ FloatToStr(Y) +'|'+ FloatToStr(Z));
  Objects[ObjectID].PosX := X;
  Objects[ObjectID].PosY := Y;
  Objects[ObjectID].PosZ := Z;
end;

function TfrmMain.GetObjectPosX(ObjectID : Integer): Single;
begin
  if (Objects[ObjectID].InUse = False) Then
    result := 0.0
  Else
    result := Objects[ObjectID].PosX;
end;

function TfrmMain.GetObjectPosY(ObjectID : Integer): Single;
begin
  if (Objects[ObjectID].InUse = False) Then
    result := 0.0
  Else
    result := Objects[ObjectID].PosY;
end;

function TfrmMain.GetObjectPosZ(ObjectID : Integer): Single;
begin
  if (Objects[ObjectID].InUse = False) Then
    result := 0.0
  Else
    result := Objects[ObjectID].PosZ;
end;

function TfrmMain.GetObjectRotX(ObjectID : Integer): Single;
begin
  if (Objects[ObjectID].InUse = False) Then
    result := 0.0
  Else
    result := Objects[ObjectID].RotX;
end;

function TfrmMain.GetObjectRotY(ObjectID : Integer): Single;
begin
  if (Objects[ObjectID].InUse = False) Then
    result := 0.0
  Else
    result := Objects[ObjectID].RotY;
end;

function TfrmMain.GetObjectRotZ(ObjectID : Integer): Single;
begin
  if (Objects[ObjectID].InUse = False) Then
    result := 0.0
  Else
    result := Objects[ObjectID].RotZ;
end;

function TfrmMain.GetVehicleModel(VehicleID : Integer): Integer;
begin
  if (Vehicles[VehicleID].InUse = False) Then
    result := 0
  Else
    result := Vehicles[VehicleID].Model;
end;


function TfrmMain.GetObjectModel(ObjectID : Integer): Integer;
begin
  if (Objects[ObjectID].InUse = False) Then
    result := 0
  Else
    result := Objects[ObjectID].Model;
end;

procedure TfrmMain.DeleteObject(ObjectID : Integer);
begin
  if (Objects[ObjectID].InUse = False) Then
    Exit;
    
  Objects[ObjectID].InUse := False;
  SendDataToAll('RMAP|do|'+ IntToStr(ObjectID));
  gSpawnedObjects := gSpawnedObjects-1;
end;

procedure TfrmMain.AddObject(ModelID : Integer; PosX, PosY, PosZ, RotX, RotY, RotZ : Single);
var
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
      SendDataToAll('RMAP|o|'+ IntToStr(i) +'|'+ IntToStr(ModelID) +'|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ) +'|'+ FormatFloat('0.000',RotX) +'|'+ FormatFloat('0.000',RotY) +'|'+ FormatFloat('0.000',RotZ));
      gSpawnedObjects := gSpawnedObjects+1;
      Break;
      Exit;
    end;
  end;
end;

function TfrmMain.AddObjectEx(ModelID : Integer; PosX, PosY, PosZ, RotX, RotY, RotZ : Single): Integer;
var
  i : integer;
begin
  result := 0;
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
      result := i;
      SendDataToAll('RMAP|o|'+ IntToStr(i) +'|'+ IntToStr(ModelID) +'|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ) +'|'+ FormatFloat('0.000',RotX) +'|'+ FormatFloat('0.000',RotY) +'|'+ FormatFloat('0.000',RotZ));
      gSpawnedObjects := gSpawnedObjects+1;
      Break;
      Exit;
    end;
  end;
end;

procedure TfrmMain.CreateCheckpoint(PlayerID : Integer;PosX, PosY, PosZ, Size : Single);
var
  PID, i : Integer;
Begin
  If (PlayerID > 32) or (PlayerID < 1) Then
    Exit;
  PID := (100 * (PlayerID-1)) + 1;
  For i := PID To (PID + 99) Do
  Begin
    If (Checkpoints[i].InUse = False) Then
    begin
      Checkpoints[i].PosX := PosX;
      Checkpoints[i].PosY := PosY;
      Checkpoints[i].PosZ := PosZ;
      Checkpoints[i].Radius := Size;
      Checkpoints[i].InUse := True;
      SendDataToPlayer(PlayerID,'RMAP|cp|'+ IntToStr(i) +'|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ) +'|'+ FormatFloat('0.000',Size));
      //blah := i;
      Break;
      Exit;
    end;
  end;
end;

function TfrmMain.CreateCheckpointEx(PlayerID : Integer;PosX, PosY, PosZ, Size : Single): Integer;
var
  PID, i : Integer;
Begin
  If (PlayerID > 32) or (PlayerID < 1) Then
  Begin
    result := -1;
    Exit;
  End;
  result := -1;
  PID := (100 * (PlayerID-1)) + 1;
  For i := PID To (PID + 99) Do
  Begin
    If (Checkpoints[i].InUse = False) Then
    begin
      Checkpoints[i].PosX := PosX;
      Checkpoints[i].PosY := PosY;
      Checkpoints[i].PosZ := PosZ;
      Checkpoints[i].Radius := Size;
      Checkpoints[i].InUse := True;
      SendDataToPlayer(PlayerID,'RMAP|cp|'+ IntToStr(i) +'|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ) +'|'+ FormatFloat('0.000',Size));
      result := i - (100 * (PlayerID-1));
      Exit;
    end;
  end;
end;

procedure TfrmMain.AddVehicle(ModelID: Integer; PosX, PosY, PosZ, Rotation : Single;Color1, Color2 : Integer);
var
  i : Integer;
begin
  if (ModelID < 400) or (ModelID > 611) Then
    Exit;

  For i := 1 To High(Vehicles) Do
  Begin
    If (Vehicles[i].InUse = False) Then
    begin
      Vehicles[i].Model := ModelID;
      Vehicles[i].sPosX := PosX;
      Vehicles[i].sPosY := PosY;
      Vehicles[i].sPosZ := PosZ;
      Vehicles[i].PosX := PosX;
      Vehicles[i].PosY := PosY;
      Vehicles[i].PosZ := PosZ;
      Vehicles[i].Rot := Rotation;
      Vehicles[i].Color1 := Color1;
      Vehicles[i].Color2 := Color2;
      Vehicles[i].Plate := '__SAP__';
      Vehicles[i].InUse := True;
      SendDataToAll('RMAP|v|'+ IntToStr(i) +'|'+ IntToStr(ModelID) +'|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ) +'|'+ FormatFloat('0.000',Rotation) +'|'+ IntToStr(Color1) +'|'+ IntToStr(Color2));
      gSpawnedVehicles := gSpawnedVehicles+1;
      Break;
      Exit;
    end;
  end;
end;

function TfrmMain.AddVehicleEx(ModelID: Integer; PosX, PosY, PosZ, Rotation : Single;Color1, Color2 : Integer): Integer;
var
  i : Integer;
begin
  if (ModelID < 400) OR (ModelID > 611) Then
  begin
    result := -1;
    Exit;
  end;
  For i := 1 To 1000 Do
  Begin
    If (Vehicles[i].InUse = False) Then
    begin
      Vehicles[i].InUse := True;
      Vehicles[i].Model := ModelID;
      Vehicles[i].sPosX := PosX;
      Vehicles[i].sPosY := PosY;
      Vehicles[i].sPosZ := PosZ;
      Vehicles[i].PosX := PosX;
      Vehicles[i].PosY := PosY;
      Vehicles[i].PosZ := PosZ;
      Vehicles[i].Color1 := Color1;
      Vehicles[i].Color2 := Color2;
      Vehicles[i].Plate := '__SAP__';
      SendDataToAll('RMAP|v|'+ IntToStr(i) +'|'+ IntToStr(ModelID) +'|'+ FormatFloat('0.000',PosX) +'|'+ FormatFloat('0.000',PosY) +'|'+ FormatFloat('0.000',PosZ) +'|'+ FormatFloat('0.000',Rotation) +'|'+ IntToStr(Color1) +'|'+ IntToStr(Color2));
      gSpawnedVehicles := gSpawnedVehicles+1;
      result := i;
      Exit;
    end;
  end;
  result := -1;
end;

procedure TfrmMain.OnFormCreate(Sender: TObject);
var
  i : integer;
  INI : TINIFile;
  Tmp : String;
begin
  Server.HardcodedMaxPlayers := 33; // Normaal 33
  Server.VersionHash := 'P21@sa41-Elise';
  Server.Version := '0.4.0.0';
  Server.Gravity := 0.008;
  Server.WaterWalk := False;
  Server.StartCount := GetTickCount();
  Server.Hour := 12;
  Server.Minute := 0;
  frmMain.Caption := 'San Andreas Party Server '+Server.Version;

  INI := TINIFile.Create(GetCurrentDir + '\settings.ini');
  Server.Name := INI.ReadString('SERVER','servername','Unnamed SAP server');
  If (Length(Server.Name) > 80) Then
  Begin
    AddToConsole('Server name is too long, limit is 80 characters.');
    Exit;
  End
  Else  If (Length(Server.Name) < 3) Then
  begin
    AddToConsole('Server name is too short, mininum is 3 characters.');
    Exit;
  end;
  Server.Password := INI.ReadString('SERVER','password','');

  Server.MaxPlayers := INI.ReadInteger('SERVER','slots',Server.HardcodedMaxPlayers-1);
  //Server.MaxPlayers := 2;
  If (Server.MaxPlayers > Server.HardcodedMaxPlayers) or (Server.MaxPlayers < 2) Then
  Begin
    AddToConsole('Minimum 2 slots - Maximum '+IntToStr(Server.HardcodedMaxPlayers-1)+' slot(s)');
    Exit;
  End;
  udpServer.DefaultPort := INI.ReadInteger('SERVER','port',8070);
  //SetLength(Player,Server.HardcodedMaxPlayers);

  For i := 1 to High(Player) do
    Player[i].Connected := False;


  Tmp := INI.ReadString('SERVER','gamemode','main.sap');
  //ShowMessage(ExtractFilePath(Application.ExeName) +'scripts\'+ Tmp);
  If not (FileExists(ExtractFilePath(Application.ExeName) +'scripts\'+ Tmp)) Then
  Begin
    AddToConsole('Gamemode (script) ''scripts\'+ Tmp +''' not found!');
    Exit;
  End;
  PScript.Script.LoadFromFile(ExtractFilePath(Application.ExeName) +'scripts\'+ Tmp);
  If Not (PScript.Compile) Then
  Begin
    AddToConsole('* Error: Unable to compile the script:');
    For i := 0 To Pred(PScript.CompilerMessageCount) Do
    Begin
      AddToConsole(PScript.CompilerMessages[i].MessageToString);
    End;
    Exit;
  End
  Else
  Begin
    If Not (PScript.Execute) Then
    Begin
      AddToConsole('* Error: Unable to execute the script: '+ PScript.ExecErrorToString);
      Exit;
    End;
  End;
  Try
    udpServer.Active := True;
  Except
    AddToConsole('* Error: Port '+IntToStr(udpServer.DefaultPort)+' already in use.');
    Exit;
  End;
  lstTimers := TStringList.Create;
  AddToConsole('*** San Andreas Party '+Server.Version+' Server started');
  udpServer.Active := True;
  AddToConsole('*** Listening on port '+IntToStr(udpServer.DefaultPort));
  tmrPingCheck.Enabled := True;
  tmrClock.Enabled := True;
  Server.IRCEnabled := False;
  Server.IRCEnabled := INI.ReadBool('IRC','enabled', false);
  // DEZE NIET (oud) Server.IRCEnabled := INI.ReadInteger('IRC','enabled', 0);
{  if (Server.IRCEnabled = true) then
  begin
    IRC.Replies.Version := 'San Andreas Party Server '+Server.Version;
    IRC.Replies.Finger := 'Put that finger back in your nose! SAP/'+Server.Version;
    IRC.Replies.ClientInfo := 'San Andreas Party Server '+Server.Version;
    IRC.Replies.UserInfo := 'San Andreas Party Server '+Server.Version;
    IRC.RealName := 'San Andreas Party Server '+Server.Version;
    IRC.Host := INI.ReadString('IRC','Server', 'irc.gtanet.com');
    IRC.Port := INI.ReadInteger('IRC','Port', 6667);
    IRC.Nick := INI.ReadString('IRC','Nickname', 'SAP-Server');
    IRC.AltNick := INI.ReadString('IRC','Nickname','SAP-Server');
    IRC.Connect();
    If (IRC.Connected) Then
      AddToConsole('*** Connected to IRC');
  end;   }

  Clients := TThreadList.Create;

  PScript.ExecuteFunction([],'OnServerStart');
end;

procedure TfrmMain.OnPingCheck(Sender: TObject);
var
  i : integer;
begin
  For i := 1 to High(Player) do
  begin
     if (Player[i].Connected = True) then
     begin
        if (Player[i].PingReceived = False) then
        begin
          if (Player[i].Ping2Received = False) then
          begin
            // player timed out? Disconnect him
            PScript.ExecuteFunction([i,1],'OnPlayerPart');
            if (Player[i].Ingame) then
              SendDataToAllExceptPlayer(i, 'GAMECLOSED|'+IntToStr(i));
            //SendDataToPlayer(i, 'BAI|1');
            Server.PlayersConnected := Server.PlayersConnected-1;
            ClearPlayerSlot(i);
            SendDataToAllExceptPlayer(i, 'DISCONNECTED|'+IntToStr(i)+'|1');
          end
          else
          begin
            Player[i].Ping2Received := False;
          end;
        end
        else
        begin
         Player[i].Ping2Received := True;
        end;
     end;
  end;
  For i := 1 to High(Player) do
  begin
     if (Player[i].Connected = True) then
       Player[i].PingReceived := False;
  end;
  Server.LastPingCheck := GetTickCount();
  SendDataToAll('PING|1');
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

end.
