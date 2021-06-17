object frmMain: TfrmMain
  Left = 458
  Top = 138
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'San Andreas Party'
  ClientHeight = 479
  ClientWidth = 734
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
  object grpLobby: TGroupBox
    Left = 8
    Top = 8
    Width = 225
    Height = 433
    Caption = 'Lobby'
    TabOrder = 0
    object pagBrowser: TPageControl
      Left = 16
      Top = 24
      Width = 201
      Height = 393
      ActivePage = tabQuickConnect
      TabOrder = 0
      object tabQuickConnect: TTabSheet
        Caption = 'Quick-connect'
        ImageIndex = 2
        object lblHost: TLabel
          Left = 8
          Top = 64
          Width = 25
          Height = 13
          Caption = 'Host:'
        end
        object lblPort: TLabel
          Left = 8
          Top = 104
          Width = 22
          Height = 13
          Caption = 'Port:'
        end
        object lblNickname: TLabel
          Left = 8
          Top = 24
          Width = 51
          Height = 13
          Caption = 'Nickname:'
        end
        object lblPass: TLabel
          Left = 8
          Top = 144
          Width = 56
          Height = 13
          Caption = 'Password *:'
        end
        object lblInfo: TLabel
          Left = 8
          Top = 344
          Width = 157
          Height = 13
          Caption = '* Only when server has password'
        end
        object lblAdminPass: TLabel
          Left = 8
          Top = 184
          Width = 80
          Height = 13
          Caption = 'Admin password:'
        end
        object edtPort: TEdit
          Left = 8
          Top = 120
          Width = 41
          Height = 21
          TabOrder = 2
          Text = '8070'
        end
        object btnConnect: TButton
          Left = 8
          Top = 232
          Width = 75
          Height = 25
          Caption = 'Connect'
          TabOrder = 5
          OnClick = btnConnectClick
        end
        object edtNickname: TEdit
          Left = 8
          Top = 40
          Width = 177
          Height = 21
          MaxLength = 10
          TabOrder = 0
          Text = 'Player'
        end
        object edtHost: TComboBox
          Left = 8
          Top = 80
          Width = 177
          Height = 21
          ItemHeight = 13
          TabOrder = 1
          Text = 'home.xoti.net'
          Items.Strings = (
            'home.xoti.net')
        end
        object edtPassword: TEdit
          Left = 8
          Top = 160
          Width = 129
          Height = 21
          MaxLength = 10
          PasswordChar = '*'
          TabOrder = 3
        end
        object edtAdminPass: TEdit
          Left = 8
          Top = 200
          Width = 129
          Height = 21
          MaxLength = 10
          PasswordChar = '*'
          TabOrder = 4
        end
      end
      object tabBrowser: TTabSheet
        Caption = 'Browser'
        ImageIndex = 1
        OnHide = tabBrowserHide
        OnShow = tabBrowserShow
        object lblStatus: TLabel
          Left = 4
          Top = 320
          Width = 3
          Height = 13
        end
        object lstBrowser: TListBox
          Left = 4
          Top = 8
          Width = 185
          Height = 297
          ItemHeight = 13
          TabOrder = 0
        end
        object btnRefresh: TButton
          Left = 112
          Top = 336
          Width = 75
          Height = 25
          Caption = 'Refresh'
          TabOrder = 1
          OnClick = btnRefreshClick
        end
        object btnBrowserConnect: TButton
          Left = 4
          Top = 336
          Width = 75
          Height = 25
          Caption = 'Connect'
          TabOrder = 2
          OnClick = btnBrowserConnectClick
        end
      end
    end
  end
  object grpGame: TGroupBox
    Left = 240
    Top = 8
    Width = 489
    Height = 433
    Caption = 'Game'
    TabOrder = 1
    object lblPlayers: TLabel
      Left = 344
      Top = 24
      Width = 34
      Height = 13
      Caption = 'Players'
    end
    object lstPlayers: TListBox
      Left = 344
      Top = 48
      Width = 137
      Height = 345
      ItemHeight = 13
      TabOrder = 0
    end
    object btnChatSend: TButton
      Left = 434
      Top = 400
      Width = 49
      Height = 21
      Caption = 'Send'
      TabOrder = 2
      OnClick = btnChatSendClick
    end
    object edtChatText: TEdit
      Left = 8
      Top = 400
      Width = 425
      Height = 21
      MaxLength = 80
      TabOrder = 1
      OnKeyPress = edtChatTextKeyPress
    end
    object btnStartGame: TButton
      Left = 88
      Top = 16
      Width = 137
      Height = 25
      Caption = 'Start game'
      Enabled = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
      OnClick = btnStartGameClick
    end
    object btnDisconnect: TButton
      Left = 8
      Top = 16
      Width = 75
      Height = 25
      Caption = 'Disconnect'
      Enabled = False
      TabOrder = 4
      OnClick = btnDisconnectClick
    end
    object btnGameDir: TButton
      Left = 232
      Top = 16
      Width = 105
      Height = 25
      Caption = 'Set game directory'
      Enabled = False
      TabOrder = 6
      OnClick = btnGameDirClick
    end
    object lstChat: TMemo
      Left = 8
      Top = 48
      Width = 329
      Height = 345
      TabStop = False
      ReadOnly = True
      ScrollBars = ssBoth
      TabOrder = 3
    end
    object memChat2: TMemo
      Left = 56
      Top = 0
      Width = 25
      Height = 25
      TabOrder = 7
      Visible = False
      WordWrap = False
    end
    object memChat1: TMemo
      Left = 88
      Top = 0
      Width = 25
      Height = 25
      TabOrder = 8
      Visible = False
      WordWrap = False
    end
  end
  object MapCars: TListBox
    Left = 264
    Top = 8
    Width = 25
    Height = 25
    ItemHeight = 13
    TabOrder = 2
    Visible = False
  end
  object btnAbout: TButton
    Left = 648
    Top = 448
    Width = 75
    Height = 25
    Caption = 'About'
    TabOrder = 3
    OnClick = btnAboutClick
  end
  object lstNameTags: TListBox
    Left = 360
    Top = 8
    Width = 25
    Height = 25
    ItemHeight = 13
    TabOrder = 4
    Visible = False
  end
  object appXPM: TXPManifest
    Left = 8
    Top = 8
  end
  object Client: TIdTCPClient
    MaxLineAction = maException
    ReadTimeout = 0
    OnDisconnected = ClientDisconnected
    OnConnected = ClientConnected
    Port = 0
    Left = 136
    Top = 8
  end
  object tmrProcess: TJvTimer
    Interval = 3000
    ThreadPriority = tpLower
    OnTimer = tmrProcessTimer
    Left = 648
    Top = 8
  end
  object SelectDir: TJvSelectDirectory
    ClassicDialog = False
    Title = 'Please locate your GTA: SA directory'
    Left = 104
    Top = 8
  end
  object tmrSync: TJvTimer
    Enabled = False
    Interval = 5000
    ThreadPriority = tpHigher
    OnTimer = tmrSyncTimer
    Left = 568
    Top = 8
  end
  object tmrGame: TJvTimer
    Interval = 2500
    OnTimer = tmrGameTimer
    Left = 680
    Top = 8
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
    Left = 200
    Top = 8
  end
  object tmrSync2: TJvTimer
    Enabled = False
    Interval = 5000
    OnTimer = tmrSync2Timer
    Left = 600
    Top = 8
  end
  object tmrChat: TTimer
    Enabled = False
    Interval = 250
    OnTimer = tmrChatTimer
    Left = 432
    Top = 8
  end
  object tmrLoadMap: TJvTimer
    Enabled = False
    Interval = 15
    ThreadPriority = tpHigher
    OnTimer = tmrLoadMapTimer
    Left = 520
    Top = 8
  end
  object procSA: TJvCreateProcess
    OnTerminate = procSATerminate
    Left = 72
    Top = 8
  end
  object tmrTextClear: TTimer
    Enabled = False
    Interval = 5000
    OnTimer = tmrTextClearTimer
    Left = 464
    Top = 8
  end
end
