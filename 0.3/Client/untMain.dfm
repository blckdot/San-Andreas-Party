object frmMain: TfrmMain
  Left = 891
  Top = 142
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'San Andreas Party'
  ClientHeight = 417
  ClientWidth = 776
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lstWindows: TListBox
    Left = 192
    Top = 168
    Width = 25
    Height = 25
    ItemHeight = 13
    TabOrder = 0
    Visible = False
  end
  object lstTexts: TListBox
    Left = 168
    Top = 160
    Width = 25
    Height = 25
    ItemHeight = 13
    TabOrder = 1
    Visible = False
  end
  object Tabs: TPageControl
    Left = 0
    Top = 0
    Width = 953
    Height = 417
    ActivePage = tabBrowser
    Align = alLeft
    BiDiMode = bdLeftToRight
    MultiLine = True
    ParentBiDiMode = False
    TabOrder = 2
    TabPosition = tpBottom
    object tabBrowser: TTabSheet
      Caption = 'Browser'
      ImageIndex = 1
      object lstBrowser: TListView
        Left = 0
        Top = 0
        Width = 593
        Height = 385
        Align = alCustom
        Columns = <
          item
            Caption = '  '
            Width = 20
          end
          item
            Caption = 'Servername'
            Width = 300
          end
          item
            Caption = 'Players'
          end
          item
            AutoSize = True
            Caption = 'Slots'
          end
          item
            Caption = 'IP:Port'
            Width = 140
          end>
        GridLines = True
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        TabStop = False
        ViewStyle = vsReport
        OnDblClick = OnBrowserDoubleClick
      end
      object GroupBox1: TGroupBox
        Left = 600
        Top = 0
        Width = 169
        Height = 385
        Caption = 'Connect'
        TabOrder = 1
        object lblHost: TLabel
          Left = 8
          Top = 16
          Width = 25
          Height = 13
          Caption = 'Host:'
        end
        object lblPort: TLabel
          Left = 8
          Top = 56
          Width = 22
          Height = 13
          Caption = 'Port:'
        end
        object lblPass: TLabel
          Left = 8
          Top = 96
          Width = 49
          Height = 13
          Caption = 'Password:'
        end
        object lblAdminPass: TLabel
          Left = 8
          Top = 136
          Width = 80
          Height = 13
          Caption = 'Admin password:'
        end
        object lblStatus: TLabel
          Left = 4
          Top = 368
          Width = 3
          Height = 13
        end
        object edtHost: TComboBox
          Left = 8
          Top = 32
          Width = 153
          Height = 21
          ItemHeight = 13
          TabOrder = 0
          Text = '127.0.0.1'
          Items.Strings = (
            'localhost'
            'home.xoti.net')
        end
        object edtPort: TEdit
          Left = 8
          Top = 72
          Width = 41
          Height = 21
          TabOrder = 1
          Text = '8070'
        end
        object edtPassword: TEdit
          Left = 8
          Top = 112
          Width = 129
          Height = 21
          PasswordChar = '*'
          TabOrder = 2
        end
        object edtAdminPass: TEdit
          Left = 8
          Top = 152
          Width = 129
          Height = 21
          PasswordChar = '*'
          TabOrder = 3
        end
        object btnConnect: TButton
          Left = 8
          Top = 184
          Width = 73
          Height = 25
          Caption = 'Connect'
          TabOrder = 4
          OnClick = btnConnectClick
        end
        object btnRefresh: TButton
          Left = 8
          Top = 216
          Width = 153
          Height = 25
          Caption = 'Refresh Server Browser'
          TabOrder = 5
          OnClick = btnRefreshClick
        end
        object btnDisconnect: TButton
          Left = 88
          Top = 184
          Width = 73
          Height = 25
          Caption = 'Disconnect'
          Enabled = False
          TabOrder = 6
          OnClick = btnDisconnectClick
        end
      end
    end
    object tabGame: TTabSheet
      Caption = 'Game'
      ImageIndex = 3
      object lblPlayers: TLabel
        Left = 600
        Top = 16
        Width = 37
        Height = 13
        Caption = 'Players:'
      end
      object lstPlayers: TListBox
        Left = 600
        Top = 32
        Width = 169
        Height = 353
        ItemHeight = 13
        TabOrder = 3
      end
      object grpGame: TGroupBox
        Left = 712
        Top = 408
        Width = 25
        Height = 17
        Caption = 'Game'
        TabOrder = 0
        Visible = False
      end
      object btnStartGame: TButton
        Left = 0
        Top = 8
        Width = 473
        Height = 25
        Caption = 'Start game'
        Enabled = False
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'MS Sans Serif'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
        OnClick = btnStartGameClick
      end
      object lstChat: TMemo
        Left = 0
        Top = 36
        Width = 593
        Height = 317
        TabStop = False
        ReadOnly = True
        ScrollBars = ssBoth
        TabOrder = 2
      end
      object edtChatText: TEdit
        Left = 0
        Top = 360
        Width = 505
        Height = 21
        MaxLength = 80
        TabOrder = 4
        OnKeyPress = edtChatTextKeyPress
      end
      object btnChatSend: TButton
        Left = 512
        Top = 360
        Width = 83
        Height = 21
        Caption = 'Send'
        TabOrder = 5
        OnClick = btnChatSendClick
      end
      object btnDisconnect2: TButton
        Left = 472
        Top = 8
        Width = 121
        Height = 25
        Caption = 'Disconnect'
        Enabled = False
        TabOrder = 6
        OnClick = btnDisconnectClick
      end
    end
    object tabSettings: TTabSheet
      Caption = 'Settings'
      ImageIndex = 2
      object lblNickname: TLabel
        Left = 8
        Top = 8
        Width = 51
        Height = 13
        Caption = 'Nickname:'
      end
      object btnGameDir: TButton
        Left = 8
        Top = 56
        Width = 177
        Height = 25
        Caption = 'Set game directory'
        TabOrder = 0
        OnClick = btnGameDirClick
      end
      object edtNickname: TEdit
        Left = 8
        Top = 24
        Width = 177
        Height = 21
        MaxLength = 10
        TabOrder = 1
        Text = 'Player'
      end
      object groAbout: TGroupBox
        Left = 8
        Top = 160
        Width = 233
        Height = 217
        Caption = 'About'
        TabOrder = 2
        object AboutText: TLabel
          Left = 8
          Top = 16
          Width = 49
          Height = 13
          Caption = 'AboutText'
        end
      end
    end
  end
  object memChat1: TMemo
    Left = 440
    Top = 392
    Width = 25
    Height = 25
    ScrollBars = ssBoth
    TabOrder = 3
    Visible = False
    WordWrap = False
  end
  object memChat2: TMemo
    Left = 416
    Top = 392
    Width = 25
    Height = 25
    ScrollBars = ssBoth
    TabOrder = 4
    Visible = False
    WordWrap = False
  end
  object MapCars: TMemo
    Left = 392
    Top = 392
    Width = 25
    Height = 25
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 5
    Visible = False
  end
  object Client: TIdTCPClient
    MaxLineAction = maException
    ReadTimeout = 0
    OnDisconnected = ClientDisconnected
    OnConnected = ClientConnected
    Port = 0
    Left = 528
    Top = 392
  end
  object tmrProcess: TJvTimer
    ThreadPriority = tpLower
    OnTimer = tmrProcessTimer
    Left = 656
    Top = 392
  end
  object SelectDir: TJvSelectDirectory
    ClassicDialog = False
    Title = 'Please locate your GTA: SA directory'
    Left = 560
    Top = 392
  end
  object tmrSync: TJvTimer
    Interval = 5000
    ThreadPriority = tpHigher
    OnTimer = tmrSyncTimer
    Left = 720
    Top = 392
  end
  object tmrGame: TJvTimer
    Interval = 250
    OnTimer = tmrGameTimer
    Left = 624
    Top = 392
  end
  object HTTP: TIdHTTP
    MaxLineAction = maException
    ReadTimeout = 0
    AllowCookies = False
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = 0
    Request.ContentRangeStart = 0
    Request.ContentType = 'text/html'
    Request.Accept = 'text/html, */*'
    Request.BasicAuthentication = False
    Request.UserAgent = 'SAP/0.3.0.0'
    HTTPOptions = [hoForceEncodeParams]
    Left = 464
    Top = 392
  end
  object tmrSync2: TJvTimer
    Interval = 110
    OnTimer = tmrSync2Timer
    Left = 688
    Top = 392
  end
  object tmrChat: TTimer
    Enabled = False
    Interval = 200
    OnTimer = tmrChatTimer
    Left = 752
    Top = 392
  end
  object tmrLoadMap: TJvTimer
    Interval = 50
    ThreadPriority = tpHigher
    OnTimer = tmrLoadMapTimer
    Left = 496
    Top = 392
  end
  object appXPM: TXPManifest
    Left = 592
    Top = 392
  end
end
