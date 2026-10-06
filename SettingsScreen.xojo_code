#tag MobileScreen
Begin MobileScreen SettingsScreen
   BackgroundColor =   
   Compatibility   =   ""
   Device          =   1
   HasBackButton   =   True
   HasNavigationBar=   True
   Modal           =   False
   NavigationBarColor=   
   NavigationBarTextColor=   
   Orientation     =   0
   SupportedOrientation=   0
   Title           =   "Settings"
   Begin MobileLabel HelpLabel
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      AdjustTextSizeToFit=   False
      Alignment       =   0
      Enabled         =   True
      Height          =   40
      Left            =   20
      LineBreakMode   =   0
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      MaximumCharactersAllowed=   0
      Scope           =   2
      Text            =   ""
      TextColor       =   &c00000000
      TextFont        =   ""
      TextSize        =   0
      Top             =   12
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField BrokerField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      BorderStyle     =   3
      Enabled         =   True
      Height          =   52
      Hint            =   "Broker (host or host:port)"
      HintColor       =   
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      TextFont        =   ""
      TextSize        =   0
      TintColor       =   
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField TopicField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      BorderStyle     =   3
      Enabled         =   True
      Height          =   52
      Hint            =   "Root topic (e.g. msh/EU_868)"
      HintColor       =   
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      TextFont        =   ""
      TextSize        =   0
      TintColor       =   
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField GatewayField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      BorderStyle     =   3
      Enabled         =   True
      Height          =   52
      Hint            =   "Gateway node ID (!aabbccdd)"
      HintColor       =   
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      TextFont        =   ""
      TextSize        =   0
      TintColor       =   
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField UserField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      BorderStyle     =   3
      Enabled         =   True
      Height          =   52
      Hint            =   "User"
      HintColor       =   
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      TextFont        =   ""
      TextSize        =   0
      TintColor       =   
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField PasswordField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      BorderStyle     =   3
      Enabled         =   True
      Height          =   52
      Hint            =   "Password"
      HintColor       =   
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      MaximumCharactersAllowed=   0
      Password        =   True
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      TextFont        =   ""
      TextSize        =   0
      TintColor       =   
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField KeysField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      BorderStyle     =   3
      Enabled         =   True
      Height          =   52
      Hint            =   "Channel keys (Name=base64; …)"
      HintColor       =   
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      TextFont        =   ""
      TextSize        =   0
      TintColor       =   
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField FilterField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      BorderStyle     =   3
      Enabled         =   True
      Height          =   52
      Hint            =   "Only this node (!aabbccdd, optional)"
      HintColor       =   
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      TextFont        =   ""
      TextSize        =   0
      TintColor       =   
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileLabel TLSLabel
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      AdjustTextSizeToFit=   False
      Alignment       =   0
      Enabled         =   True
      Height          =   30
      Left            =   20
      LineBreakMode   =   0
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      MaximumCharactersAllowed=   0
      Scope           =   2
      Text            =   "TLS (usually port 8883)"
      TextColor       =   &c00000000
      TextFont        =   ""
      TextSize        =   0
      Top             =   0
      Visible         =   True
      Width           =   250
   End
   Begin MobileSwitch TLSSwitch
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Enabled         =   True
      Height          =   30
      Left            =   276
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   False
      LockRight       =   True
      LockTop         =   True
      Scope           =   2
      ThumbColor      =   
      TintColor       =   
      Top             =   0
      Value           =   False
      Visible         =   True
      Width           =   64
   End
   Begin MobileTextField HostField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      BorderStyle     =   3
      Enabled         =   True
      Height          =   52
      Hint            =   "Node IP address or host name"
      HintColor       =   
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      TextFont        =   ""
      TextSize        =   0
      TintColor       =   
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField PortField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      BorderStyle     =   3
      Enabled         =   True
      Height          =   52
      Hint            =   "TCP port (4403)"
      HintColor       =   
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      TextFont        =   ""
      TextSize        =   0
      TintColor       =   
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField DeviceField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      BorderStyle     =   3
      Enabled         =   True
      Height          =   52
      Hint            =   "M5Stack device ID (12 hex digits)"
      HintColor       =   
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      TextFont        =   ""
      TextSize        =   0
      TintColor       =   
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileButton SaveButton
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      AdjustTextSizeToFit=   False
      BackgroundColor =   
      BorderColor     =   
      BorderWidth     =   0
      Caption         =   "Save"
      CaptionColor    =   &c00000000
      CornerSize      =   0
      DisplayMenuAsAction=   False
      Enabled         =   True
      Height          =   48
      Icon            =   0
      Left            =   20
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      Scope           =   2
      TextFont        =   ""
      TextSize        =   0
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileLabel ProblemLabel
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      AdjustTextSizeToFit=   False
      Alignment       =   0
      Enabled         =   True
      Height          =   60
      Left            =   20
      LineBreakMode   =   0
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      MaximumCharactersAllowed=   0
      Scope           =   2
      Text            =   ""
      TextColor       =   &c00000000
      TextFont        =   ""
      TextSize        =   0
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobilePopupMenu ProfileMenu
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Enabled         =   True
      Height          =   40
      InitialValue    =   ""
      LastAddedRowIndex=   0
      LastRowIndex    =   0
      Left            =   20
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      RowCount        =   0
      Scope           =   2
      SelectedRowIndex=   0
      SelectedRowText =   ""
      TextColor       =   
      TintColor       =   
      Top             =   68
      Visible         =   True
      Width           =   210
   End
   Begin MobileButton ForgetButton
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      AdjustTextSizeToFit=   False
      BackgroundColor =   
      BorderColor     =   
      BorderWidth     =   0
      Caption         =   "Forget"
      CaptionColor    =   &cffffff
      CornerSize      =   0
      DisplayMenuAsAction=   False
      Enabled         =   True
      Height          =   44
      Icon            =   0
      Left            =   240
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   False
      LockRight       =   True
      LockTop         =   True
      Scope           =   2
      TextFont        =   ""
      TextSize        =   0
      Top             =   68
      Visible         =   True
      Width           =   100
   End
End
#tag EndMobileScreen

#tag ScreenCode
	#tag Event
		Sub Opening()
		  // Only the fields of the source this screen was opened for, one under the other
		  Dim rows() As MobileUIControl
		  Select Case Kind
		  Case "mqtt"
		    Self.Title = "MQTT feed"
		    HelpLabel.Text = "The broker your gateway publishes to, and the gateway's node ID."
		    rows.Add(ProfileMenu)
		    rows.Add(BrokerField)
		    rows.Add(TopicField)
		    rows.Add(GatewayField)
		    rows.Add(UserField)
		    rows.Add(PasswordField)
		    rows.Add(KeysField)
		    rows.Add(FilterField)
		    rows.Add(TLSLabel)
		    BrokerField.Text = Hub.Setting("mqtt_broker")
		    TopicField.Text = Hub.Setting("mqtt_root_topic")
		    GatewayField.Text = Hub.Setting("mqtt_gateway_id")
		    UserField.Text = Hub.Setting("mqtt_username")
		    PasswordField.Text = Hub.Setting("mqtt_password")
		    KeysField.Text = Hub.Setting("mqtt_keys")
		    FilterField.Text = Hub.Setting("mqtt_node_filter")
		    TLSSwitch.Value = Hub.SettingBool("mqtt_tls")
		  Case "range"
		    Self.Title = "Range test"
		    HelpLabel.Text = "The gateway is the Meshtastic node card's node; the broker is the MQTT card's. The test device uploads what it hears through the phone's Meshtastic app (MQTT proxy)."
		    GatewayField.Hint = "Test device ID (!aabbccdd)"
		    PortField.Hint = "Gateway channel for the test message (0 = primary)"
		    rows.Add(GatewayField)
		    rows.Add(PortField)
		    GatewayField.Text = Hub.Setting("range_device")
		    PortField.Text = Hub.Setting("range_channel")
		  Case "device"
		    Self.Title = "Meshtastic node"
		    HelpLabel.Text = "A node on your network (TCP), or usb for a node plugged into this device. Close the Meshtastic app first: a node takes one client at a time."
		    HostField.Hint = "Node IP address, host name, or usb"
		    rows.Add(HostField)
		    rows.Add(PortField)
		    HostField.Text = Hub.Setting("device_host")
		    PortField.Text = Hub.Setting("device_port")
		  Case "aqi"
		    Self.Title = "M5Stack AQI"
		    HelpLabel.Text = "The device ID shown by the M5Stack (its MAC address)."
		    rows.Add(DeviceField)
		    DeviceField.Text = Hub.Setting("aqi_device_id")
		  End Select
		  Dim all() As MobileUIControl
		  all.Add(BrokerField)
		  all.Add(TopicField)
		  all.Add(GatewayField)
		  all.Add(UserField)
		  all.Add(PasswordField)
		  all.Add(KeysField)
		  all.Add(FilterField)
		  all.Add(TLSLabel)
		  all.Add(TLSSwitch)
		  all.Add(HostField)
		  all.Add(PortField)
		  all.Add(DeviceField)
		  all.Add(ProfileMenu)
		  all.Add(ForgetButton)
		  For Each c As MobileUIControl In all
		    c.Visible = False
		  Next
		  Dim y As Double = 60
		  For Each c As MobileUIControl In rows
		    c.Top = y
		    c.Visible = True
		    y = y + 60
		  Next
		  If Kind = "mqtt" Then
		    TLSSwitch.Top = TLSLabel.Top
		    TLSSwitch.Visible = True
		    ForgetButton.Top = ProfileMenu.Top
		    ForgetButton.Visible = True
		    SeedProfiles()
		    LoadProfiles()
		  End If
		  SaveButton.Top = y + 8
		  ProblemLabel.Top = y + 64
		  ProblemLabel.Text = ""
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Sub CleanFields()
		  // No spaces in names and addresses: Android's keyboard can add one after each dot ("mqtt. example. com").
		  // User names and passwords are left as typed (they may contain spaces). Through variables (see SelectionChanged)
		  Dim broker As String = BrokerField.Text.ReplaceAll(" ", "")
		  Dim topic As String = TopicField.Text.ReplaceAll(" ", "")
		  Dim filter As String = FilterField.Text.ReplaceAll(" ", "")
		  Dim host As String = HostField.Text.ReplaceAll(" ", "")
		  BrokerField.Text = broker
		  TopicField.Text = topic
		  FilterField.Text = filter
		  HostField.Text = host
		  // GatewayField is the gateway ID (MQTT) or the test device ID (range): an ID either way
		  Dim gateway As String = GatewayField.Text.ReplaceAll(" ", "")
		  GatewayField.Text = gateway
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LoadProfiles()
		  // The saved MQTT feeds in the popup, most recently used first; row 0 is a title
		  mProfiles.RemoveAll
		  ProfileMenu.RemoveAllRows()
		  Dim rs As RowSet = MQTTProfiles()
		  If rs <> Nil Then
		    While Not rs.AfterLastRow
		      Dim d As New Dictionary
		      d.Value("id") = rs.Column("profileID").Int64Value
		      d.Value("broker") = rs.Column("broker").StringValue
		      d.Value("rootTopic") = rs.Column("rootTopic").StringValue
		      d.Value("gatewayID") = rs.Column("gatewayID").StringValue
		      d.Value("username") = rs.Column("username").StringValue
		      d.Value("password") = rs.Column("password").StringValue
		      d.Value("keys") = rs.Column("keys").StringValue
		      d.Value("nodeFilter") = rs.Column("nodeFilter").StringValue
		      d.Value("tls") = (rs.Column("tls").IntegerValue = 1)
		      mProfiles.Add(d)
		      rs.MoveToNextRow()
		    Wend
		  End If
		  Dim title As String = "Saved feeds (" + Str(mProfiles.Count) + ")"
		  If mProfiles.Count = 0 Then title = "No saved feeds yet"
		  ProfileMenu.AddRow(title)
		  For Each d As Dictionary In mProfiles
		    Dim name As String = MQTTProfileName(d.Value("broker").StringValue, d.Value("rootTopic").StringValue, _
		    d.Value("gatewayID").StringValue, d.Value("username").StringValue)
		    ProfileMenu.AddRow(name)
		  Next
		  ProfileMenu.SelectedRowIndex = 0
		  ForgetButton.Enabled = False
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Problem() As String
		  // What's missing or malformed, "" when the fields can be saved
		  Select Case Kind
		  Case "mqtt"
		    If BrokerField.Text.Trim = "" Then Return "The broker is missing."
		    If TopicField.Text.Trim = "" Then Return "The root topic is missing."
		    If TopicField.Text.IndexOf("#") >= 0 Or TopicField.Text.IndexOf("+") >= 0 Then Return "The root topic is the prefix only, like msh/EU_868: no # or + (the app adds /2/e/+/!<gateway>)."
		    If Not Hub.IsHexID(GatewayField.Text, 8) Then Return "The gateway ID is 8 hex digits, like !aabbccdd."
		    If FilterField.Text.Trim <> "" And Not Hub.IsHexID(FilterField.Text, 8) Then Return "The node filter is 8 hex digits, like !aabbccdd (or empty)."
		  Case "device"
		    If HostField.Text.Trim = "" Then Return "The node's address is missing."
		    If PortField.Text.Trim <> "" And Val(PortField.Text) <= 0 Then Return "The port is a number (4403 by default)."
		  Case "range"
		    If Hub.Setting("device_host") = "" Then Return "Set up the Meshtastic node card first: its node is the gateway."
		    If Hub.Setting("mqtt_broker") = "" Then Return "Set up the MQTT card first: the test device's uploads come through its broker."
		    If Not Hub.IsHexID(GatewayField.Text, 8) Then Return "The test device ID is 8 hex digits, like !aabbccdd."
		    If PortField.Text.Trim <> "" And (Val(PortField.Text) < 0 Or Val(PortField.Text) > 7) Then Return "The channel is a number from 0 to 7."
		  Case "aqi"
		    If Not Hub.IsHexID(DeviceField.Text, 12) Then Return "The device ID is 12 hex digits."
		  End Select
		  Return ""
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SeedProfiles()
		  // Once: the MQTT settings in use before saved feeds existed become the first saved feed
		  If Hub.SettingBool("mqtt_profiles_seeded") Then Return
		  Hub.SetSetting("mqtt_profiles_seeded", True)
		  Hub.SaveSettings()
		  If Hub.Setting("mqtt_broker") = "" Then Return
		  SaveMQTTProfile(Hub.Setting("mqtt_broker"), Hub.Setting("mqtt_root_topic"), Hub.Setting("mqtt_gateway_id"), _
		  Hub.Setting("mqtt_username"), Hub.Setting("mqtt_password"), Hub.Setting("mqtt_keys"), Hub.Setting("mqtt_node_filter"), _
		  Hub.SettingBool("mqtt_tls"))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Save()
		  // Stores the fields; a source that is on restarts with them
		  Select Case Kind
		  Case "mqtt"
		    Hub.SetSetting("mqtt_broker", BrokerField.Text.Trim)
		    Hub.SetSetting("mqtt_root_topic", TopicField.Text.Trim)
		    Hub.SetSetting("mqtt_gateway_id", GatewayField.Text.Trim)
		    Hub.SetSetting("mqtt_username", UserField.Text.Trim)
		    Hub.SetSetting("mqtt_password", PasswordField.Text.Trim)
		    Hub.SetSetting("mqtt_keys", KeysField.Text.Trim)
		    Hub.SetSetting("mqtt_node_filter", FilterField.Text.Trim)
		    Hub.SetSetting("mqtt_tls", TLSSwitch.Value)
		    SaveMQTTProfile(BrokerField.Text.Trim, TopicField.Text.Trim, GatewayField.Text.Trim, UserField.Text.Trim, _
		    PasswordField.Text.Trim, KeysField.Text.Trim, FilterField.Text.Trim, TLSSwitch.Value)
		    If Hub.MQTT.IsOn() Then
		      Hub.MQTT.Stop()
		      Hub.MQTT.Start()
		    End If
		  Case "device"
		    Hub.SetSetting("device_host", HostField.Text.Trim)
		    Hub.SetSetting("device_port", PortField.Text.Trim)
		    If Hub.Node.IsOn() Then
		      Hub.Node.Stop()
		      Hub.Node.Start()
		    End If
		  Case "range"
		    Dim device As String = GatewayField.Text.Trim.Lowercase
		    If Not device.BeginsWith("!") Then device = "!" + device
		    Hub.SetSetting("range_device", device)
		    Dim channelText As String = Str(Val(PortField.Text))
		    Hub.SetSetting("range_channel", channelText)
		    If Hub.Range.IsOn() Then
		      Hub.Range.Stop()
		      Hub.Range.Start()
		    End If
		  Case "aqi"
		    Hub.SetSetting("aqi_device_id", DeviceField.Text.Trim.Uppercase)
		    If Hub.AQI.IsOn() Then
		      Hub.AQI.Stop()
		      Hub.AQI.Start()
		    End If
		  End Select
		  Hub.SaveSettings()
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h0
		Kind As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mProfiles() As Dictionary
	#tag EndProperty


#tag EndScreenCode

#tag Events ProfileMenu
	#tag Event
		Sub SelectionChanged(item As MobileMenuItem)
		  // A saved feed fills the fields; Save uses it
		  #Pragma Unused item
		  Dim idx As Integer = ProfileMenu.SelectedRowIndex
		  ForgetButton.Enabled = (idx > 0)
		  If idx <= 0 Or idx > mProfiles.Count Then Return
		  Dim d As Dictionary = mProfiles(idx - 1)
		  // Through variables: a chained call assigned straight to a control property can fail on Android
		  Dim broker As String = d.Value("broker").StringValue
		  Dim rootTopic As String = d.Value("rootTopic").StringValue
		  Dim gatewayID As String = d.Value("gatewayID").StringValue
		  Dim username As String = d.Value("username").StringValue
		  Dim password As String = d.Value("password").StringValue
		  Dim keys As String = d.Value("keys").StringValue
		  Dim nodeFilter As String = d.Value("nodeFilter").StringValue
		  Dim tls As Boolean = d.Value("tls").BooleanValue
		  BrokerField.Text = broker
		  TopicField.Text = rootTopic
		  GatewayField.Text = gatewayID
		  UserField.Text = username
		  PasswordField.Text = password
		  KeysField.Text = keys
		  FilterField.Text = nodeFilter
		  TLSSwitch.Value = tls
		  ProblemLabel.Text = "Tap Save to use this feed."
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events ForgetButton
	#tag Event
		Sub Pressed()
		  // Deletes the saved feed selected in the popup (the fields stay as they are)
		  Dim idx As Integer = ProfileMenu.SelectedRowIndex
		  If idx <= 0 Or idx > mProfiles.Count Then Return
		  Dim d As Dictionary = mProfiles(idx - 1)
		  Dim id As Int64 = d.Value("id").Int64Value
		  ForgetMQTTProfile(id)
		  LoadProfiles()
		  ProblemLabel.Text = "Saved feed forgotten."
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events SaveButton
	#tag Event
		Sub Pressed()
		  CleanFields()
		  Dim why As String = Problem()
		  If why <> "" Then
		    ProblemLabel.Text = why
		    Return
		  End If
		  Save()
		  Self.Close()
		End Sub
	#tag EndEvent
#tag EndEvents
#tag ViewBehavior
	#tag ViewProperty
		Name="Name"
		Visible=true
		Group="ID"
		InitialValue=""
		Type="String"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="Index"
		Visible=true
		Group="ID"
		InitialValue="-2147483648"
		Type="Integer"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="Super"
		Visible=true
		Group="ID"
		InitialValue=""
		Type="String"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="Left"
		Visible=true
		Group="Position"
		InitialValue="0"
		Type="Integer"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="Top"
		Visible=true
		Group="Position"
		InitialValue="0"
		Type="Integer"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="ControlCount"
		Visible=false
		Group="Behavior"
		InitialValue=""
		Type="Integer"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="Title"
		Visible=true
		Group="Behavior"
		InitialValue="Untitled"
		Type="String"
		EditorType="MultiLineEditor"
	#tag EndViewProperty
	#tag ViewProperty
		Name="HasNavigationBar"
		Visible=true
		Group="Behavior"
		InitialValue="True"
		Type="Boolean"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="Modal"
		Visible=true
		Group="Behavior"
		InitialValue="False"
		Type="Boolean"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="NavigationBarHeight"
		Visible=false
		Group="Behavior"
		InitialValue=""
		Type="Integer"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="HasBackButton"
		Visible=true
		Group="Behavior"
		InitialValue="False"
		Type="Boolean"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="ScaleFactor"
		Visible=false
		Group="Behavior"
		InitialValue=""
		Type="Double"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="LastControlIndex"
		Visible=false
		Group="Behavior"
		InitialValue=""
		Type="Integer"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="BackgroundColor"
		Visible=true
		Group="Behavior"
		InitialValue=""
		Type="ColorGroup"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="NavigationBarColor"
		Visible=true
		Group="Behavior"
		InitialValue=""
		Type="ColorGroup"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="NavigationBarTextColor"
		Visible=true
		Group="Behavior"
		InitialValue=""
		Type="ColorGroup"
		EditorType=""
	#tag EndViewProperty
	#tag ViewProperty
		Name="Kind"
		Visible=false
		Group="Behavior"
		InitialValue=""
		Type="String"
		EditorType=""
	#tag EndViewProperty
#tag EndViewBehavior
