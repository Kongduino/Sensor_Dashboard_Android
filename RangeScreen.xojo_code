#tag MobileScreen
Begin MobileScreen RangeScreen
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
   Title           =   "Range test"
   Begin MobileLabel InfoLabel
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      Enabled         =   True
      Height          =   44
      Left            =   16
      LineBreakMode   =   0
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      Scope           =   2
      Text            =   ""
      TextColor       =   &c00000000
      Top             =   8
      Visible         =   True
      Width           =   328
   End
   Begin MobileLabel CountsLabel
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      Enabled         =   True
      Height          =   44
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
      Top             =   56
      Visible         =   True
      Width           =   328
   End
   Begin TabStrip TabBar
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Enabled         =   True
      Height          =   40
      Left            =   16
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      Scope           =   2
      Top             =   108
      Visible         =   True
      Width           =   328
   End
   Begin MobileMapView Map
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Enabled         =   True
      Height          =   360
      Left            =   8
      LockBottom      =   True
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      LockedInPosition=   False
      Scope           =   2
      Top             =   156
      Visible         =   True
      Width           =   344
   End
   Begin MobileLabel LogLabel
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      Enabled         =   True
      Height          =   360
      Left            =   16
      LineBreakMode   =   0
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      Scope           =   2
      Text            =   ""
      TextColor       =   &c00000000
      Top             =   156
      Visible         =   False
      Width           =   328
   End
   Begin MobileLabel StatsLabel
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      Enabled         =   True
      Height          =   44
      Left            =   16
      LineBreakMode   =   0
      LockBottom      =   True
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   False
      LockedInPosition=   False
      Scope           =   2
      Text            =   ""
      TextColor       =   &c00000000
      Top             =   520
      Visible         =   True
      Width           =   328
   End
End
#tag EndMobileScreen

#tag ScreenCode
	#tag Event
		Sub Opening()
		  // The range test (Hub.Range): the gateway -> device and device -> gateway maps, and the log. Send makes the gateway
		  // broadcast the next test message. No value-returning method of this screen is called here (Android: the view
		  // isn't ready during Opening; Subs are deferred)
		  Self.NavigationToolbar.AddButton(New MobileToolbarButton(MobileToolbarButton.Types.Plain, "Send"))
		  Self.NavigationToolbar.AddButton(New MobileToolbarButton(MobileToolbarButton.Types.Plain, "Share"))
		  Self.NavigationToolbar.AddButton(New MobileToolbarButton(MobileToolbarButton.Types.Plain, "Settings"))
		  TabBar.AddTab("→ device")
		  TabBar.AddTab("→ gateway")
		  TabBar.AddTab("Log")
		  AddHandler Hub.Range.Changed, WeakAddressOf RangeChanged
		  ShowTab(0)
		End Sub
	#tag EndEvent

	#tag Event
		Sub Activated()
		  // Back from the settings: the state may have changed
		  ShowTab(mTab)
		  Hub.KeepAwake(Map, Hub.AnyOn())
		End Sub
	#tag EndEvent

	#tag Event
		Sub ToolbarButtonPressed(button As MobileToolbarButton)
		  Select Case button.Caption
		  Case "Send"
		    Dim why As String = Hub.Range.Send()
		    If why <> "" Then InfoLabel.Text = "Send: " + why
		  Case "Share"
		    ShareNow()
		  Case "Settings"
		    Dim s As New SettingsScreen
		    s.Kind = "range"
		    s.Show()
		  End Select
		End Sub
	#tag EndEvent

	#tag Method, Flags = &h21
		Private Sub RangeChanged(sender As RangeTestSource)
		  ShowTab(mTab)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ShareNow()
		  // Every reading of this gateway and device (CSV) and the current map (PNG), as one zip through Android's share
		  // sheet. Files go under cache/images, the only folder Xojo's FileProvider shares (see SourceScreen.ShareNow)
		  Try
		    Dim prefix As String = Hub.Range.SharePrefix()
		    Dim images As FolderItem = SpecialFolder.Temporary.Child("images")
		    If Not images.Exists Then images.CreateFolder()
		    Dim base As FolderItem = images.Child("Sensor_Dashboard_share")
		    If Not base.Exists Then base.CreateFolder()
		    Dim stamp As String = Format(DateTime.Now().SecondsFrom1970, "0")
		    Dim folder As FolderItem = base.Child(prefix + "_" + stamp)
		    If Not folder.Exists Then folder.CreateFolder()
		    Dim files() As FolderItem
		    Dim rs As RowSet = Hub.Range.ExportRows()
		    If rs <> Nil Then
		      If rs.RowCount > 0 Then
		        Dim csv As FolderItem = folder.Child(prefix + ".csv")
		        WriteRangeCSV(rs, csv)
		        files.Add(csv)
		      End If
		    End If
		    If mTab < 2 Then
		      Dim p As Picture = Map.ToPicture()
		      Dim png As FolderItem = folder.Child(prefix + If(mTab = 0, "_to_device", "_to_gateway") + ".png")
		      If png.Exists Then png.Remove()
		      p.Save(png, Picture.Formats.PNG)
		      files.Add(png)
		    End If
		    If files.Count = 0 Then
		      InfoLabel.Text = "Nothing to share yet"
		      Return
		    End If
		    Dim toShare As FolderItem = files(0)
		    If files.Count > 1 Then
		      Dim zipTarget As FolderItem = base.Child(prefix + "_" + stamp + ".zip")
		      Dim zipped As FolderItem = folder.Zip(zipTarget, True)
		      toShare = zipped
		    End If
		    // In the event log, like the desktop exports: what was shared
		    Dim names() As String
		    For Each f As FolderItem In files
		      names.Add(f.Name)
		    Next
		    Dim sep As String = ", "
		    LogEvents("Share", "Sharing " + toShare.Name + ": " + String.FromArray(names, sep))
		    mSharing = New MobileSharingPanel
		    mSharing.ShareFile(toShare, Self)
		  Catch e As RuntimeException
		    LogEvents("Share", "Share failed: " + e.Message)
		    InfoLabel.Text = "Share failed: " + e.Message
		  End Try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ShowTab(tabIndex As Integer)
		  // Tab 0: what the device heard from the gateway; 1: what the gateway heard from the device; 2: the log.
		  // Function results go into Dim lines first (Android)
		  mTab = tabIndex
		  TabBar.SelectTab(tabIndex)
		  Dim status As String = Hub.Range.Status
		  Dim describe As String = Hub.Range.Describe()
		  InfoLabel.Text = status + " · " + describe
		  Dim counts As String = "sent " + Str(Hub.Range.SentCount) + " · device heard " + Str(Hub.Range.HeardDownCount) + _
		  " · missed " + Str(Hub.Range.MissedCount) + " · gateway heard " + Str(Hub.Range.HeardUpCount)
		  CountsLabel.Text = counts
		  Dim nl As String = EndOfLine // a String first: EndOfLine is a class (not accepted in If(), nor as a String argument)
		  Dim last As String
		  If Hub.Range.LastDown <> "" Then last = "→ device: " + Hub.Range.LastDown
		  If Hub.Range.LastUp <> "" Then
		    If last <> "" Then last = last + nl
		    last = last + "→ gateway: " + Hub.Range.LastUp
		  End If
		  StatsLabel.Text = last
		  If tabIndex = 2 Then
		    Map.Visible = False
		    Dim shown() As String
		    For i As Integer = 0 To Min(Hub.Range.LogLines.LastIndex, 24)
		      shown.Add(Hub.Range.LogLines(i))
		    Next
		    Dim logText As String = String.FromArray(shown, nl)
		    If logText = "" Then logText = "Nothing yet. Send asks the gateway to broadcast a test message."
		    LogLabel.Text = logText
		    LogLabel.Visible = True
		    Return
		  End If
		  LogLabel.Visible = False
		  If tabIndex = 0 Then
		    Map.Spots = Hub.Range.Down
		  Else
		    Map.Spots = Hub.Range.Up
		  End If
		  If mShownSpots <> tabIndex Then
		    mShownSpots = tabIndex
		    Map.FitView()
		  End If
		  Map.Visible = True
		  Map.Refresh()
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mSharing As MobileSharingPanel
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mShownSpots As Integer = -1
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTab As Integer
	#tag EndProperty

#tag EndScreenCode

#tag Events TabBar
	#tag Event
		Sub Pressed(tabIndex As Integer)
		  ShowTab(tabIndex)
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
