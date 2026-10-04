#tag MobileScreen
Begin MobileScreen HomeScreen
   BackgroundColor =   
   Compatibility   =   ""
   Device          =   1
   HasBackButton   =   False
   HasNavigationBar=   True
   Modal           =   False
   NavigationBarColor=   
   NavigationBarTextColor=   
   Orientation     =   0
   SupportedOrientation=   0
   Title           =   "Sensor Dashboard"
   Begin SourceCard CardMQTT
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Enabled         =   True
      Height          =   100
      Left            =   16
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      Scope           =   2
      Top             =   16
      Visible         =   True
      Width           =   328
   End
   Begin MobileSwitch SwitchMQTT
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Enabled         =   True
      Height          =   30
      Left            =   274
      LockBottom      =   False
      LockLeft        =   False
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      Scope           =   2
      Top             =   30
      Value           =   False
      Visible         =   True
      Width           =   64
   End
   Begin SourceCard CardNode
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Enabled         =   True
      Height          =   100
      Left            =   16
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      Scope           =   2
      Top             =   132
      Visible         =   True
      Width           =   328
   End
   Begin MobileSwitch SwitchNode
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Enabled         =   True
      Height          =   30
      Left            =   274
      LockBottom      =   False
      LockLeft        =   False
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      Scope           =   2
      Top             =   146
      Value           =   False
      Visible         =   True
      Width           =   64
   End
   Begin SourceCard CardAQI
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Enabled         =   True
      Height          =   100
      Left            =   16
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      Scope           =   2
      Top             =   248
      Visible         =   True
      Width           =   328
   End
   Begin MobileSwitch SwitchAQI
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Enabled         =   True
      Height          =   30
      Left            =   274
      LockBottom      =   False
      LockLeft        =   False
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      Scope           =   2
      Top             =   262
      Value           =   False
      Visible         =   True
      Width           =   64
   End
   Begin MobileLabel NoteLabel
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      Enabled         =   True
      Height          =   60
      Left            =   16
      LineBreakMode   =   0
      LockBottom      =   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      Scope           =   2
      Text            =   ""
      TextColor       =   &c00000000
      Top             =   364
      Visible         =   True
      Width           =   328
   End
End
#tag EndMobileScreen

#tag ScreenCode
	#tag Event
		Sub Opening()
		  // The app starts here: the Hub opens the database and the settings, and restarts the sources that were on
		  Hub.Init()
		  CardMQTT.CardTitle = "MQTT feed"
		  CardNode.CardTitle = "Meshtastic node"
		  CardAQI.CardTitle = "M5Stack AQI"
		  AddHandler Hub.MQTT.Changed, WeakAddressOf MQTTChanged
		  AddHandler Hub.Node.Changed, WeakAddressOf NodeChanged
		  AddHandler Hub.AQI.Changed, WeakAddressOf AQIChanged
		  If Hub.DatabaseProblem <> "" Then NoteLabel.Text = "Database problem: " + Hub.DatabaseProblem
		  RefreshCards()
		End Sub
	#tag EndEvent

	#tag Event
		Sub Activated()
		  // Back from a settings screen: show the new state
		  RefreshCards()
		End Sub
	#tag EndEvent

	#tag Method, Flags = &h21
		Private Sub RefreshCards()
		  // Each card: state and latest reading; each switch follows its source (without acting on it)
		  mUpdating = True
		  ShowSource(CardMQTT, SwitchMQTT, Hub.MQTT.IsConfigured(), Hub.MQTT.IsOn(), Hub.MQTT.Status, Hub.MQTT.Describe(), Hub.MQTT.Latest)
		  ShowSource(CardNode, SwitchNode, Hub.Node.IsConfigured(), Hub.Node.IsOn(), Hub.Node.Status, Hub.Node.Describe(), Hub.Node.Latest)
		  ShowSource(CardAQI, SwitchAQI, Hub.AQI.IsConfigured(), Hub.AQI.IsOn(), Hub.AQI.Status, Hub.AQI.Describe(), Hub.AQI.Latest)
		  mUpdating = False
		  Hub.KeepAwake(CardMQTT, Hub.AnyOn())
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ShowSource(card As SourceCard, sw As MobileSwitch, configured As Boolean, isOn As Boolean, state As String, describe As String, latest As String)
		  If Not configured Then
		    card.StatusText = "set up: tap here"
		    card.DetailText = ""
		  Else
		    card.StatusText = state + " · " + describe
		    card.DetailText = latest
		  End If
		  sw.Enabled = configured
		  sw.Value = isOn
		  card.Refresh()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub OpenSettings(kind As String)
		  // Per-source settings (step 1); the source screen with its charts comes in step 2
		  Dim s As New SettingsScreen
		  s.Kind = kind
		  s.Show()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Toggle(kind As String, turnOn As Boolean)
		  // The switch: start or stop the source, and remember it, so it starts again with the app
		  Select Case kind
		  Case "mqtt"
		    If turnOn Then
		      Hub.MQTT.Start()
		    Else
		      Hub.MQTT.Stop()
		    End If
		    Hub.SetSetting("mqtt_on", turnOn)
		  Case "device"
		    If turnOn Then
		      Hub.Node.Start()
		    Else
		      Hub.Node.Stop()
		    End If
		    Hub.SetSetting("device_on", turnOn)
		  Case "aqi"
		    If turnOn Then
		      Hub.AQI.Start()
		    Else
		      Hub.AQI.Stop()
		    End If
		    Hub.SetSetting("aqi_on", turnOn)
		  End Select
		  Hub.SaveSettings()
		  RefreshCards()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub MQTTChanged(sender As MQTTSource)
		  RefreshCards()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub NodeChanged(sender As NodeSource)
		  RefreshCards()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub AQIChanged(sender As AQISource)
		  RefreshCards()
		End Sub
	#tag EndMethod

	#tag Property, Flags = &h21
		Private mUpdating As Boolean
	#tag EndProperty

#tag EndScreenCode

#tag Events CardMQTT
	#tag Event
		Sub Pressed()
		  // Set up: its settings; otherwise its charts
		  If Not Hub.MQTT.IsConfigured() Then
		    OpenSettings("mqtt")
		    Return
		  End If
		  Dim s As New SourceScreen
		  s.Kind = "mqtt"
		  s.Show()
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events CardNode
	#tag Event
		Sub Pressed()
		  // Set up: its settings; otherwise its charts and map
		  If Not Hub.Node.IsConfigured() Then
		    OpenSettings("device")
		    Return
		  End If
		  Dim s As New SourceScreen
		  s.Kind = "device"
		  s.Show()
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events CardAQI
	#tag Event
		Sub Pressed()
		  // Set up: its settings; otherwise its charts
		  If Not Hub.AQI.IsConfigured() Then
		    OpenSettings("aqi")
		    Return
		  End If
		  Dim s As New SourceScreen
		  s.Kind = "aqi"
		  s.Show()
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events SwitchMQTT
	#tag Event
		Sub ValueChanged()
		  If mUpdating Then Return
		  Toggle("mqtt", Me.Value)
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events SwitchNode
	#tag Event
		Sub ValueChanged()
		  If mUpdating Then Return
		  Toggle("device", Me.Value)
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events SwitchAQI
	#tag Event
		Sub ValueChanged()
		  If mUpdating Then Return
		  Toggle("aqi", Me.Value)
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
