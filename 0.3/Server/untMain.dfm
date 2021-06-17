object frmMain: TfrmMain
  Left = 735
  Top = 122
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Loading...'
  ClientHeight = 261
  ClientWidth = 491
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Visible = True
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lblInfo: TLabel
    Left = 154
    Top = 244
    Width = 183
    Height = 13
    Caption = 'San Andreas Party server 0.3 - By Ywa'
  end
  object lstBans: TListBox
    Left = 448
    Top = 160
    Width = 25
    Height = 25
    ItemHeight = 13
    TabOrder = 0
    Visible = False
  end
  object lstLog: TMemo
    Left = 5
    Top = 2
    Width = 481
    Height = 215
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object edtLogText: TEdit
    Left = 5
    Top = 216
    Width = 424
    Height = 21
    MaxLength = 80
    TabOrder = 2
    OnKeyPress = edtLogTextKeyPress
  end
  object btnLogSend: TButton
    Left = 429
    Top = 216
    Width = 57
    Height = 21
    Caption = 'Send'
    TabOrder = 3
    OnClick = btnLogSendClick
  end
  object Server: TIdTCPServer
    Bindings = <>
    CommandHandlers = <>
    CommandHandlersEnabled = False
    DefaultPort = 8070
    Greeting.NumericCode = 0
    MaxConnectionReply.NumericCode = 0
    MaxConnections = 25
    OnConnect = ServerConnect
    OnExecute = ServerExecute
    OnDisconnect = ServerDisconnect
    ReplyExceptionCode = 0
    ReplyTexts = <>
    ReplyUnknownCommand.NumericCode = 0
    TerminateWaitTime = 1000
    Left = 440
    Top = 40
  end
  object IRC: TIdIRC
    MaxLineAction = maException
    ReadTimeout = 0
    Host = 'irc.gtanet.com'
    Nick = 'SAP-Echo'
    AltNick = 'SAP-Reporter'
    Username = 'SAPServer'
    RealName = 'San Andreas Party Server'
    Replies.Version = 'TIdIRC 1.061 by Steve Williams'
    Replies.ClientInfo = 
      'TIdIRC 1.061 by Steve Williams Non-visual component for 32-bit D' +
      'elphi.'
    UserMode = []
    OnMessage = OnIRCMessage
    OnNotice = IRCNotice
    OnJoin = IRCJoin
    OnPart = IRCPart
    Left = 408
    Top = 72
  end
  object HTTP: TIdHTTP
    MaxLineAction = maException
    ReadTimeout = 0
    AllowCookies = True
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = 0
    Request.ContentRangeStart = 0
    Request.ContentType = 'text/html'
    Request.Accept = 'text/html, */*'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    HTTPOptions = [hoForceEncodeParams]
    Left = 440
    Top = 72
  end
  object Ce: TPSScript
    CompilerOptions = []
    OnCompile = CeCompile
    Plugins = <>
    UsePreProcessor = False
    Left = 440
    Top = 104
  end
  object Query: TIdTCPServer
    Bindings = <>
    CommandHandlers = <>
    CommandHandlersEnabled = False
    DefaultPort = 8071
    Greeting.NumericCode = 0
    MaxConnectionReply.NumericCode = 0
    MaxConnections = 100
    OnExecute = OnQueryExecute
    ReplyExceptionCode = 0
    ReplyTexts = <>
    ReplyUnknownCommand.NumericCode = 0
    TerminateWaitTime = 500
    Left = 440
    Top = 8
  end
  object tmrTimeSync: TTimer
    Enabled = False
    OnTimer = OnTimeSync
    Left = 408
    Top = 40
  end
  object tmrMasterServer: TTimer
    Enabled = False
    Interval = 200000
    OnTimer = OnMasterServerHeartbeat
    Left = 408
    Top = 8
  end
end
