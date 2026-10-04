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
      Alignment       =   0
      Enabled         =   True
      Height          =   40
      Left            =   20
      LineBreakMode   =   0
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      Scope           =   2
      Text            =   ""
      TextColor       =   &c00000000
      Top             =   12
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField BrokerField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      Enabled         =   True
      Height          =   52
      Hint            =   "Broker (host or host:port)"
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField TopicField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      Enabled         =   True
      Height          =   52
      Hint            =   "Root topic (e.g. msh/EU_868)"
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField GatewayField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      Enabled         =   True
      Height          =   52
      Hint            =   "Gateway node ID (!aabbccdd)"
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField UserField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      Enabled         =   True
      Height          =   52
      Hint            =   "User"
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField PasswordField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      Enabled         =   True
      Height          =   52
      Hint            =   "Password"
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      MaximumCharactersAllowed=   0
      Password        =   True
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField KeysField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      Enabled         =   True
      Height          =   52
      Hint            =   "Channel keys (Name=base64; …)"
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField FilterField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      Enabled         =   True
      Height          =   52
      Hint            =   "Only this node (!aabbccdd, optional)"
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileLabel TLSLabel
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      Enabled         =   True
      Height          =   30
      Left            =   20
      LineBreakMode   =   0
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      Scope           =   2
      Text            =   "TLS (usually port 8883)"
      TextColor       =   &c00000000
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
      LockLeft        =   False
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      Scope           =   2
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
      Enabled         =   True
      Height          =   52
      Hint            =   "Node IP address or host name"
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField PortField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      Enabled         =   True
      Height          =   52
      Hint            =   "TCP port (4403)"
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileTextField DeviceField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      Enabled         =   True
      Height          =   52
      Hint            =   "M5Stack device ID (12 hex digits)"
      InputType       =   0
      Left            =   20
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      MaximumCharactersAllowed=   0
      Password        =   False
      ReadOnly        =   False
      Scope           =   2
      SelectedText    =   ""
      SelectionLength =   0
      SelectionStart  =   0
      Text            =   ""
      TextColor       =   &c00000000
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileButton SaveButton
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Caption         =   "Save"
      CaptionColor    =   &c00000000
      Enabled         =   True
      Height          =   48
      Left            =   20
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      Scope           =   2
      Top             =   0
      Visible         =   True
      Width           =   320
   End
   Begin MobileLabel ProblemLabel
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      Enabled         =   True
      Height          =   60
      Left            =   20
      LineBreakMode   =   0
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      Scope           =   2
      Text            =   ""
      TextColor       =   &c00000000
      Top             =   0
      Visible         =   True
      Width           =   320
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
		  Case "device"
		    Self.Title = "Meshtastic node"
		    HelpLabel.Text = "A node on your network (TCP). Close the Meshtastic app first: a node takes one client at a time."
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
		  End If
		  SaveButton.Top = y + 8
		  ProblemLabel.Top = y + 64
		  ProblemLabel.Text = ""
		End Sub
	#tag EndEvent

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
		  Case "aqi"
		    If Not Hub.IsHexID(DeviceField.Text, 12) Then Return "The device ID is 12 hex digits."
		  End Select
		  Return ""
		End Function
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

#tag EndScreenCode

#tag Events SaveButton
	#tag Event
		Sub Pressed()
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
#tag EndViewBehavior
