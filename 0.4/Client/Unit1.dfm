object frmMain: TfrmMain
  Left = 896
  Top = 501
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'SAPz0rs'
  ClientHeight = 455
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
    ActivePage = tabBrowser
    MultiLine = True
    TabOrder = 0
    TabPosition = tpBottom
    TabStop = False
    object tabBrowser: TTabSheet
      Caption = 'Browser'
      object grpConnect: TGroupBox
        Left = 600
        Top = 0
        Width = 167
        Height = 425
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
      object lstBrowser: TListView
        Left = 0
        Top = 0
        Width = 593
        Height = 425
        Align = alCustom
        Columns = <
          item
            Caption = 'X'
            Width = 30
          end
          item
            Caption = 'Servername'
            Width = 269
          end
          item
            Caption = 'Players'
          end
          item
            AutoSize = True
            Caption = 'Slots'
          end
          item
            Caption = 'Ping'
          end
          item
            Caption = 'IP:Port'
            Width = 140
          end>
        GridLines = True
        ReadOnly = True
        RowSelect = True
        TabOrder = 1
        TabStop = False
        ViewStyle = vsReport
      end
    end
    object tabGame: TTabSheet
      Caption = 'Game'
      Enabled = False
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
      object lstPlayers: TListBox
        Left = 608
        Top = 32
        Width = 161
        Height = 393
        TabStop = False
        ItemHeight = 13
        TabOrder = 3
        OnEnter = lstPlayersEnter
      end
      object btnDisconnect: TButton
        Left = 8
        Top = 0
        Width = 75
        Height = 25
        Caption = 'Disconnect'
        TabOrder = 4
        OnClick = btnDisconnectClick
      end
      object btnStartGame: TButton
        Left = 88
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
        TabOrder = 5
        OnClick = btnStartGameClick
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
        Top = 288
        Width = 233
        Height = 137
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
    Interval = 500
    OnTimer = tmrProcessTimer
    Left = 116
    Top = 12
  end
  object tmrSync: TJvTimer
    Enabled = False
    Interval = 90
    ThreadPriority = tpHigher
    OnTimer = tmrSyncTimer
    Left = 148
    Top = 8
  end
  object tmrPingCheck: TTimer
    Enabled = False
    Interval = 15000
    OnTimer = tmrPingCheckTimer
    Left = 180
    Top = 12
  end
  object tmrLoadMap: TJvTimer
    Enabled = False
    Interval = 30
    ThreadPriority = tpHigher
    OnTimer = tmrLoadMapTimer
    Left = 216
    Top = 16
  end
  object tmrNicks: TTimer
    Interval = 10000
    OnTimer = tmrNicksTimer
    Left = 252
    Top = 12
  end
  object udpClient: TIdTCPClient
    MaxLineAction = maException
    ReadTimeout = 0
    OnConnected = udpClientConnected
    Port = 0
    Left = 4
    Top = 12
  end
end
