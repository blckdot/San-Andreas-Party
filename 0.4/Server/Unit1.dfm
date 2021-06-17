object frmMain: TfrmMain
  Left = 784
  Top = 647
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsDialog
  Caption = 'SAP'
  ClientHeight = 283
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
  object udpAntiFreeze: TIdAntiFreeze
    IdleTimeOut = 500
    Left = 408
    Top = 40
  end
  object tmrPingCheck: TTimer
    Enabled = False
    Interval = 3000
    OnTimer = OnPingCheck
    Left = 440
    Top = 40
  end
  object PScript: TPSScript
    CompilerOptions = []
    OnCompile = OnScriptCompile
    Plugins = <>
    UsePreProcessor = False
    Left = 376
    Top = 8
  end
  object tmrClock: TTimer
    Enabled = False
    OnTimer = OnClockTimer
    Left = 440
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
    Left = 408
    Top = 8
  end
end
