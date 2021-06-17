object frmMain: TfrmMain
  Left = 378
  Top = 139
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'San Andreas Party Server'
  ClientHeight = 305
  ClientWidth = 508
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lblInfo: TLabel
    Left = 124
    Top = 289
    Width = 260
    Height = 13
    Caption = 'San Andreas Party Server - By: Jarno (Ywa*NL) Veuger'
  end
  object lstBans: TListBox
    Left = 8
    Top = 288
    Width = 25
    Height = 25
    ItemHeight = 13
    TabOrder = 0
    Visible = False
  end
  object grpLog: TGroupBox
    Left = 8
    Top = 8
    Width = 497
    Height = 273
    Caption = 'Log'
    TabOrder = 1
    object lstLog: TMemo
      Left = 8
      Top = 16
      Width = 481
      Height = 225
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object edtLogText: TEdit
      Left = 8
      Top = 240
      Width = 432
      Height = 21
      MaxLength = 80
      TabOrder = 1
      OnKeyPress = edtLogTextKeyPress
    end
    object btnLogSend: TButton
      Left = 440
      Top = 240
      Width = 51
      Height = 21
      Caption = 'Send'
      TabOrder = 2
      OnClick = btnLogSendClick
    end
    object lstTimers: TListBox
      Left = 64
      Top = 64
      Width = 25
      Height = 25
      ItemHeight = 13
      TabOrder = 3
      Visible = False
    end
  end
  object lstMapAll: TListBox
    Left = 40
    Top = 288
    Width = 25
    Height = 25
    ItemHeight = 13
    TabOrder = 2
    Visible = False
  end
  object Server: TIdTCPServer
    Bindings = <>
    CommandHandlers = <>
    CommandHandlersEnabled = False
    DefaultPort = 8090
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
    Left = 40
    Top = 4
  end
  object tmrSaveBans: TTimer
    Enabled = False
    Interval = 10000
    OnTimer = tmrSaveBansTimer
    Left = 8
    Top = 40
  end
  object IRC: TIdIRC
    MaxLineAction = maException
    ReadTimeout = 0
    Host = 'irc.gtanet.com'
    Nick = 'SAP-ECHO'
    AltNick = 'SAP-Echo'
    Username = 'sap'
    RealName = 'SAP_Echo'
    Replies.Version = 'TIdIRC 1.061 by Steve Williams'
    Replies.ClientInfo = 
      'TIdIRC 1.061 by Steve Williams Non-visual component for 32-bit D' +
      'elphi.'
    UserMode = []
    OnMessage = IRCMessage
    Left = 40
    Top = 40
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
    Left = 8
    Top = 8
  end
  object Ce: TPSScript
    CompilerOptions = []
    OnCompile = CeCompile
    Plugins = <>
    UsePreProcessor = False
    Left = 8
    Top = 72
  end
  object tmrTimers: TTimer
    OnTimer = tmrTimersTimer
    Left = 40
    Top = 72
  end
end
