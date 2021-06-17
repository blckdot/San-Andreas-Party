object frmMain: TfrmMain
  Left = 549
  Top = 370
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsDialog
  Caption = 'SA-Party Server'
  ClientHeight = 282
  ClientWidth = 489
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = OnFormClose
  OnCreate = OnFormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object memoLog: TMemo
    Left = 0
    Top = 0
    Width = 489
    Height = 257
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object tmrPingCheck: TTimer
    Enabled = False
    Interval = 3000
    OnTimer = OnPingCheck
    Left = 40
    Top = 8
  end
  object PScript: TPSScript
    CompilerOptions = []
    OnCompile = OnScriptCompile
    Plugins = <>
    UsePreProcessor = False
    Left = 8
    Top = 8
  end
  object udpServer: TIdTCPServer
    Bindings = <>
    CommandHandlers = <>
    DefaultPort = 0
    Greeting.NumericCode = 0
    MaxConnectionReply.NumericCode = 0
    OnConnect = udpServerConnect
    OnExecute = udpServerExecute
    OnDisconnect = udpServerDisconnect
    ReplyExceptionCode = 0
    ReplyTexts = <>
    ReplyUnknownCommand.NumericCode = 0
    Left = 8
    Top = 40
  end
  object tmrSecond: TTimer
    OnTimer = OnSecondTimer
    Left = 40
    Top = 40
  end
  object IRC: TIdIRC
    MaxLineAction = maException
    ReadTimeout = 0
    OnConnected = IRCConnected
    Nick = 'Nick'
    AltNick = 'SAPServer'
    Username = 'sa-party'
    RealName = 'San Andreas Party Server'
    Replies.Version = 'TIdIRC 1.061 by Steve Williams'
    Replies.ClientInfo = 
      'TIdIRC 1.061 by Steve Williams Non-visual component for 32-bit D' +
      'elphi.'
    UserMode = []
    OnMessage = OnIRCMessage
    OnAction = IRCAction
    OnJoin = OnIRCJoinChannel
    OnPart = OnIRCPartChannel
    OnNickChange = OnNickChange
    OnQuit = OnIRCQuit
    OnInviting = OnIRCInvite
    Left = 72
    Top = 8
  end
end
