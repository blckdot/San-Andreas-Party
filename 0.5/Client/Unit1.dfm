object frmMain: TfrmMain
  Left = 896
  Top = 501
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'SAP'
  ClientHeight = 458
  ClientWidth = 776
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pagMain: TPageControl
    Left = 0
    Top = 0
    Width = 777
    Height = 457
    ActivePage = tabSettings
    MultiLine = True
    TabOrder = 0
    TabPosition = tpBottom
    TabStop = False
    object tabBrowser: TTabSheet
      Caption = 'Browser'
      object grpConnect: TGroupBox
        Left = 0
        Top = 0
        Width = 167
        Height = 209
        Caption = ' Connect '
        TabOrder = 0
        object lblHost: TLabel
          Left = 11
          Top = 24
          Width = 69
          Height = 13
          Caption = 'Host IP/name:'
        end
        object lblHostPort: TLabel
          Left = 11
          Top = 72
          Width = 46
          Height = 13
          Caption = 'Host port:'
        end
        object lblPassword: TLabel
          Left = 11
          Top = 120
          Width = 49
          Height = 13
          Caption = 'Password:'
        end
        object btnConnect: TButton
          Left = 11
          Top = 168
          Width = 145
          Height = 33
          Caption = 'Connect'
          TabOrder = 3
          OnClick = btnConnectClick
        end
        object edtHost: TEdit
          Left = 11
          Top = 40
          Width = 145
          Height = 21
          MaxLength = 70
          TabOrder = 0
        end
        object edtPort: TEdit
          Left = 11
          Top = 88
          Width = 41
          Height = 21
          MaxLength = 5
          TabOrder = 1
        end
        object edtPassword: TEdit
          Left = 11
          Top = 136
          Width = 145
          Height = 21
          MaxLength = 30
          PasswordChar = '*'
          TabOrder = 2
        end
      end
    end
    object tabGame: TTabSheet
      Caption = 'Game'
      ImageIndex = 1
      object lblPlayers: TLabel
        Left = 608
        Top = 16
        Width = 37
        Height = 13
        Caption = 'Players:'
      end
      object memoChat: TMemo
        Left = 8
        Top = 32
        Width = 593
        Height = 369
        TabStop = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 2
      end
      object edtChat: TEdit
        Left = 8
        Top = 400
        Width = 520
        Height = 21
        MaxLength = 80
        TabOrder = 0
        OnKeyPress = edtChatKeyPress
      end
      object btnChat: TButton
        Left = 528
        Top = 400
        Width = 75
        Height = 21
        Caption = 'Send'
        TabOrder = 1
        OnClick = btnChatClick
      end
      object btnDisconnect: TButton
        Left = 8
        Top = 0
        Width = 75
        Height = 25
        Caption = 'Disconnect'
        TabOrder = 3
        OnClick = btnDisconnectClick
      end
      object btnStartGame: TButton
        Left = 104
        Top = 0
        Width = 97
        Height = 25
        Caption = 'Start game'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 4
        OnClick = btnStartGameClick
      end
      object lstPlayers: TListView
        Left = 608
        Top = 32
        Width = 161
        Height = 369
        Align = alCustom
        Columns = <
          item
            Caption = 'ID'
            Width = 30
          end
          item
            Caption = 'Name'
            Width = 85
          end
          item
            Caption = 'Ping'
            Width = 42
          end>
        GridLines = True
        TabOrder = 5
        ViewStyle = vsReport
      end
    end
    object tabSettings: TTabSheet
      Caption = 'Settings'
      ImageIndex = 2
      object Label2: TLabel
        Left = 8
        Top = 8
        Width = 51
        Height = 13
        Caption = 'Nickname:'
      end
      object edtNickname: TEdit
        Left = 8
        Top = 24
        Width = 145
        Height = 21
        MaxLength = 20
        TabOrder = 0
        Text = 'Player'
      end
      object groAbout: TGroupBox
        Left = 0
        Top = 224
        Width = 233
        Height = 201
        Caption = 'About'
        TabOrder = 1
        object AboutText: TLabel
          Left = 8
          Top = 16
          Width = 49
          Height = 13
          Caption = 'AboutText'
        end
      end
      object btnSetGameDir: TButton
        Left = 8
        Top = 56
        Width = 145
        Height = 25
        Caption = 'Set game directory'
        TabOrder = 2
        OnClick = btnSetGameDirClick
      end
      object cbxDev: TCheckBox
        Left = 8
        Top = 120
        Width = 73
        Height = 17
        Caption = 'Dev. mode'
        TabOrder = 3
      end
      object cbxWindowed: TCheckBox
        Left = 8
        Top = 88
        Width = 137
        Height = 17
        Caption = 'Play in windowed mode'
        Enabled = False
        TabOrder = 4
        OnClick = cbxWindowedClick
      end
      object cbxTimestamps: TCheckBox
        Left = 8
        Top = 104
        Width = 81
        Height = 17
        Caption = 'Timestamps'
        TabOrder = 5
        OnClick = cbxTimestampsClick
      end
    end
  end
  object appXPM: TXPManifest
    Left = 40
    Top = 8
  end
  object SelectDir: TJvSelectDirectory
    ClassicDialog = False
    Title = 'Please locate your GTA: San Andreas directory'
    Left = 76
    Top = 12
  end
  object tmrProcess: TJvTimer
    Interval = 350
    ThreadPriority = tpLower
    OnTimer = tmrProcessTimer
    Left = 704
    Top = 4
  end
  object TCP: TIdTCPClient
    MaxLineAction = maException
    ReadTimeout = 0
    OnConnected = TCPConnected
    Port = 0
    Left = 4
    Top = 12
  end
  object tmrPingPong: TJvTimer
    Interval = 4500
    OnTimer = tmrPingPongTimer
    Left = 740
    Top = 8
  end
  object tmrSync: TJvTimer
    Interval = 50
    OnTimer = tmrSyncTimer
    Left = 196
    Top = 12
  end
  object tmrLoadMap: TJvTimer
    Enabled = False
    Interval = 50
    OnTimer = tmrLoadMapTimer
    Left = 244
    Top = 12
  end
end
