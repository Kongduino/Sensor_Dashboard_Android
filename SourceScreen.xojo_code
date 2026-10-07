#tag MobileScreen
Begin MobileScreen SourceScreen
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
   Title           =   "Source"
   Begin MobileTextField FilterField
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Alignment       =   0
      AllowSpellChecking=   False
      BorderStyle     =   3
      Enabled         =   True
      Height          =   48
      Hint            =   "Filter"
      HintColor       =   
      InputType       =   0
      Left            =   16
      LockBottom      =   False
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   False
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
      Top             =   8
      Visible         =   True
      Width           =   110
   End
   Begin MobilePopupMenu NodePicker
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Enabled         =   True
      Height          =   48
      InitialValue    =   ""
      LastAddedRowIndex=   0
      LastRowIndex    =   0
      Left            =   134
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
      Top             =   8
      Visible         =   True
      Width           =   210
   End
   Begin MobileLabel SourceLabel
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      AdjustTextSizeToFit=   False
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
      MaximumCharactersAllowed=   0
      Scope           =   2
      Text            =   ""
      TextColor       =   &c00000000
      TextFont        =   ""
      TextSize        =   0
      Top             =   8
      Visible         =   False
      Width           =   328
   End
   Begin MobileLabel InfoLabel
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      AdjustTextSizeToFit=   False
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
      MaximumCharactersAllowed=   0
      Scope           =   2
      Text            =   ""
      TextColor       =   &c00000000
      TextFont        =   ""
      TextSize        =   0
      Top             =   60
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
      SelectedIndex   =   0
      Top             =   108
      Visible         =   True
      Width           =   328
   End
   Begin MobileSensorChart Chart
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Enabled         =   True
      Height          =   360
      Left            =   8
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      Scope           =   2
      Title           =   ""
      Top             =   156
      Visible         =   True
      Width           =   344
   End
   Begin MobileMapView Map
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      Enabled         =   True
      Height          =   360
      Left            =   8
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   True
      Scope           =   2
      Top             =   156
      Visible         =   False
      Width           =   344
   End
   Begin MobileLabel StatsLabel
      AccessibilityHint=   ""
      AccessibilityLabel=   ""
      AdjustTextSizeToFit=   False
      Alignment       =   0
      Enabled         =   True
      Height          =   44
      Left            =   16
      LineBreakMode   =   0
      LockBottom      =   True
      LockedInPosition=   False
      LockLeft        =   True
      LockRight       =   True
      LockTop         =   False
      MaximumCharactersAllowed=   0
      Scope           =   2
      Text            =   ""
      TextColor       =   &c00000000
      TextFont        =   ""
      TextSize        =   0
      Top             =   520
      Visible         =   True
      Width           =   328
   End
End
#tag EndMobileScreen

#tag ScreenCode
	#tag Event
		Sub Activated()
		  // Back from the settings: the state may have changed
		  If Kind = "device" Then FillNodeMenu()
		  If Kind = "soil" Then FillSoilMenu()
		  ShowTab(mTab)
		  Hub.KeepAwake(Chart, Hub.AnyOn())
		End Sub
	#tag EndEvent

	#tag Event
		Sub Opening()
		  // The source's charts (and map): Kind is "device" (a Meshtastic node), "mqtt" or "aqi". The data lives in the Hub:
		  // leaving this screen doesn't stop anything
		  // Short tab captions, so that 5 fit on a phone (Android sizes the segments by their text); fileList names the
		  // shared picture of each tab (no ° or % in a file name)
		  Dim tabList, fileList As String
		  Select Case Kind
		  Case "mqtt"
		    Self.Title = "MQTT"
		    tabList = "°C,%,hPa,RSSI,Map"
		    fileList = "Temp,Humidity,Pressure,Radio,Map"
		    AddHandler Hub.MQTT.Changed, WeakAddressOf MQTTChanged
		  Case "aqi"
		    Self.Title = "AQI"
		    tabList = "°C,%,CO₂,VOC,PM"
		    fileList = "Temp,Humidity,CO2,VOC,PM"
		    AddHandler Hub.AQI.Changed, WeakAddressOf AQIChanged
		  Case "soil"
		    // Soil readings of any node, from the MQTT feed and the node link (Shared/SoilData): one tab per metric
		    Self.Title = "Soil"
		    Dim tabs(), files() As String
		    For i As Integer = 0 To SoilMetricCount() - 1
		      tabs.Add(SoilMetricShort(i))
		      files.Add(SoilMetricKey(i))
		    Next
		    Dim comma As String = ","
		    tabList = String.FromArray(tabs, comma)
		    fileList = String.FromArray(files, comma)
		    AddHandler Hub.MQTT.Changed, WeakAddressOf SoilFromMQTT
		    AddHandler Hub.Node.Changed, WeakAddressOf SoilFromNode
		  Else
		    Self.Title = "Node"
		    tabList = "°C,%,hPa,Map"
		    fileList = "Temp,Humidity,Pressure,Map"
		    Self.NavigationToolbar.AddButton(New MobileToolbarButton(MobileToolbarButton.Types.Plain, "Request"))
		    AddHandler Hub.Node.Changed, WeakAddressOf NodeChanged
		  End Select
		  Self.NavigationToolbar.AddButton(New MobileToolbarButton(MobileToolbarButton.Types.Plain, "Share"))
		  If Kind <> "soil" Then Self.NavigationToolbar.AddButton(New MobileToolbarButton(MobileToolbarButton.Types.Plain, "Settings"))
		  For Each tabName As String In tabList.Split(",")
		    TabBar.AddTab(tabName)
		  Next
		  For Each fileName As String In fileList.Split(",")
		    mTabNames.Add(fileName)
		  Next
		  If Kind = "device" Then
		    FillNodeMenu()
		  ElseIf Kind = "soil" Then
		    FilterField.Visible = False // the picker lists only the nodes that sent soil readings: no search needed
		    FillSoilMenu()
		  Else
		    LayoutWithoutPicker() // a Sub: run once the screen's view exists
		  End If
		  // No value-returning method of this screen may be called here: on Android the screen's view isn't ready during Opening
		  // (Subs are deferred, Functions raise an exception). ShowTab, a Sub, gives the map its track
		  ShowTab(0)
		End Sub
	#tag EndEvent

	#tag Event
		Sub ToolbarButtonPressed(button As MobileToolbarButton)
		  Select Case button.Caption
		  Case "Request"
		    // On the Map tab, a position; otherwise the sensor readings
		    Dim why As String = Hub.Node.Request(mTab = MapTab())
		    If why <> "" Then InfoLabel.Text = "Request: " + why
		  Case "Share"
		    ShareNow()
		  Case "Settings"
		    Dim s As New SettingsScreen
		    s.Kind = Kind
		    s.Show()
		  End Select
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Sub AQIChanged(sender As AQISource)
		  ShowTab(mTab)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function CurrentPicture() As Picture
		  // The current tab as a picture (twice the size, as on desktop): the map on the Map tab, else the chart
		  If mTab = MapTab() Then Return Map.ToPicture()
		  Return Chart.ToPicture()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function CurrentTrack() As PositionTrack
		  Select Case Kind
		  Case "mqtt"
		    Return Hub.MQTT.Track()
		  Case "aqi", "soil"
		    Return Nil
		  End Select
		  Return Hub.Node.Track()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ExportRowsFor() As RowSet
		  Select Case Kind
		  Case "mqtt"
		    Return Hub.MQTT.ExportRows()
		  Case "aqi"
		    Return Hub.AQI.ExportRows()
		  Case "soil"
		    Return Nil // WriteSoilCSV writes the soil readings
		  End Select
		  Return Hub.Node.ExportRows()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub FillNodeMenu()
		  // The picker: the connected node's own sensor first, then the nodes matching the filter (name, short name or id).
		  // The charted node stays listed even when it doesn't match, so the selection holds
		  Dim filter As String = FilterField.Text.Trim.Lowercase
		  mUpdating = True
		  NodePicker.RemoveAllRows()
		  mMenuNodes.RemoveAll()
		  NodePicker.AddRow("Own sensor" + If(Hub.Node.Owner <> "", ": " + Hub.Node.Owner, ""))
		  mMenuNodes.Add(Hub.Node.MyNum())
		  For i As Integer = 0 To Hub.Node.NodeNums.LastIndex
		    If filter = "" Or Hub.Node.NodeSearch(i).IndexOf(filter) >= 0 Or Hub.Node.NodeNums(i) = Hub.Node.ChartNode Then
		      NodePicker.AddRow(Hub.Node.NodeLabels(i))
		      mMenuNodes.Add(Hub.Node.NodeNums(i))
		    End If
		  Next
		  Dim selected As Integer = mMenuNodes.IndexOf(Hub.Node.ChartNode)
		  If selected < 0 Then selected = 0
		  NodePicker.SelectedRowIndex = selected
		  mKnownNodes = Hub.Node.NodeNums.Count
		  mUpdating = False
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function InfoText() As String
		  Dim state, latest As String
		  Select Case Kind
		  Case "mqtt"
		    state = Hub.MQTT.Status
		    latest = Hub.MQTT.Latest
		  Case "aqi"
		    state = Hub.AQI.Status
		    latest = Hub.AQI.Latest
		  Case "soil"
		    state = "From the MQTT feed and the node card"
		    latest = SoilSummary(mSoilNode)
		  Else
		    state = Hub.Node.Status
		    latest = Hub.Node.Latest
		  End Select
		  If latest = "" Then Return state
		  Return state + "   " + latest
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LayoutWithoutPicker()
		  // MQTT and AQI have no node picker: its row shows what the screen follows instead. Nothing is moved: on Android,
		  // moving the tab bar hid it, and resizing the chart crashed the graphics driver
		  FilterField.Visible = False
		  NodePicker.Visible = False
		  Select Case Kind
		  Case "mqtt"
		    SourceLabel.Text = Hub.MQTT.Describe()
		  Case "aqi"
		    SourceLabel.Text = Hub.AQI.Describe()
		  End Select
		  SourceLabel.Visible = True
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function MapTab() As Integer
		  // The Map tab's index, -1 without one (AQI)
		  Select Case Kind
		  Case "mqtt"
		    Return 4
		  Case "aqi", "soil"
		    Return -1
		  End Select
		  Return 3
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub MQTTChanged(sender As MQTTSource)
		  ShowTab(mTab)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub NodeChanged(sender As NodeSource)
		  If sender.NodeNums.Count <> mKnownNodes Then FillNodeMenu()
		  ShowTab(mTab)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ShareNow()
		  // The desktop export, through Android's share sheet: every stored reading (CSV), the positions (CSV and GPX) and
		  // the current tab as a picture, written to a temporary folder first. Function results go into Dim lines (the form
		  // Android translates reliably)
		  Try
		    // A folder of its own for each share (prefix and time), zipped below when it holds more than one file
		    Dim prefix As String = SharePrefixFor()
		    // Inside cache/images: the only folder the FileProvider of Xojo's Android template lets other apps read
		    // (its file_paths.xml: <cache-path path="images/">); a file elsewhere crashes ShareFile ("Failed to find configured root")
		    Dim images As FolderItem = SpecialFolder.Temporary.Child("images")
		    If Not images.Exists Then images.CreateFolder()
		    Dim base As FolderItem = images.Child("Sensor_Dashboard_share")
		    If Not base.Exists Then base.CreateFolder()
		    Dim stamp As String = Format(DateTime.Now().SecondsFrom1970, "0")
		    Dim folder As FolderItem = base.Child(prefix + "_" + stamp)
		    If Not folder.Exists Then folder.CreateFolder()
		    Dim files() As FolderItem
		    If Kind = "soil" Then
		      If mSoilNode <> 0 Then
		        Dim soilCSV As FolderItem = folder.Child(prefix + ".csv")
		        WriteSoilCSV(mSoilNode, soilCSV)
		        files.Add(soilCSV)
		      End If
		    End If
		    Dim rs As RowSet = ExportRowsFor() // Nil for soil (its CSV is above)
		    If rs <> Nil Then
		      If rs.RowCount > 0 Then
		        Dim csv As FolderItem = folder.Child(prefix + ".csv")
		        WriteTelemetryCSV(rs, csv, If(Kind = "aqi", "device", "node"), Kind = "mqtt")
		        files.Add(csv)
		      End If
		    End If
		    If Kind <> "aqi" And Kind <> "soil" Then
		      Dim track As PositionTrack = CurrentTrack()
		      If track.Count() > 0 Then
		        Dim posCSV As FolderItem = folder.Child(prefix + "_positions.csv")
		        Dim posGPX As FolderItem = folder.Child(prefix + "_positions.gpx")
		        WritePositionsCSV(track, posCSV)
		        WritePositionsGPX(track, posGPX, prefix)
		        files.Add(posCSV)
		        files.Add(posGPX)
		      End If
		    End If
		    Dim p As Picture = CurrentPicture()
		    Dim tabName As String = "Chart"
		    If mTab >= 0 And mTab <= mTabNames.LastIndex Then tabName = mTabNames(mTab)
		    Dim png As FolderItem = folder.Child(prefix + "_" + tabName + ".png")
		    If png.Exists Then png.Remove()
		    p.Save(png, Picture.Formats.PNG)
		    files.Add(png)
		    // One file: as it is. Several: one zip, since ShareFile(files()) can't be used (Xojo maps it to the single-file
		    // sharefile in Kotlin, while the framework's array method is sharefiles: a type mismatch at the Android build)
		    Dim toShare As FolderItem = files(0)
		    If files.Count > 1 Then
		      Dim zipTarget As FolderItem = base.Child(prefix + "_" + stamp + ".zip")
		      Dim zipped As FolderItem = folder.Zip(zipTarget, True)
		      toShare = zipped
		    End If
		    mSharing = New MobileSharingPanel
		    mSharing.ShareFile(toShare, Self)
		  Catch e As RuntimeException
		    InfoLabel.Text = "Share failed: " + e.Message
		  End Try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SharePrefixFor() As String
		  Select Case Kind
		  Case "mqtt"
		    Return Hub.MQTT.SharePrefix()
		  Case "aqi"
		    Return Hub.AQI.SharePrefix()
		  Case "soil"
		    Dim soilID As UInt32 = mSoilNode
		    Dim nodeText As String = Hub.NodeText(soilID)
		    Return "SOIL_" + nodeText.Middle(1)
		  End Select
		  Return Hub.Node.SharePrefix()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ShowAQIChart(tabIndex As Integer)
		  // As the desktop AQI window: both sensors' temperature and humidity, CO2, VOC, particulate matter as bars
		  Chart.AddLabels(Hub.AQI.Labels)
		  Chart.AddTimes(Hub.AQI.Times)
		  Dim n As String = "  (" + SampleCount(Hub.AQI.Labels.Count) + ")"
		  Select Case tabIndex
		  Case 0
		    Chart.Title = "Temperature" + n
		    Chart.AddDataset(LineSet("SEN55", "temperature", Hub.AQI.Temp55, " °C"))
		    Chart.AddDataset(LineSet("SCD40", "temperature2", Hub.AQI.Temp40, " °C"))
		    StatsLabel.Text = StatsText("SEN55", Hub.AQI.Temp55, " °C", "-0.0") + EndOfLine + StatsText("SCD40", Hub.AQI.Temp40, " °C", "-0.0")
		  Case 1
		    Chart.Title = "Humidity" + n
		    Chart.AddDataset(LineSet("SEN55", "humidity", Hub.AQI.RH55, " %"))
		    Chart.AddDataset(LineSet("SCD40", "humidity2", Hub.AQI.RH40, " %"))
		    StatsLabel.Text = StatsText("SEN55", Hub.AQI.RH55, " %", "0.0") + EndOfLine + StatsText("SCD40", Hub.AQI.RH40, " %", "0.0")
		  Case 2
		    Chart.Title = "CO2" + n
		    Chart.AddDataset(LineSet("CO2 (SCD40)", "co2", Hub.AQI.CO2, " ppm"))
		    StatsLabel.Text = StatsText("CO2", Hub.AQI.CO2, " ppm", "0")
		  Case 3
		    Chart.Title = "VOC index" + n
		    Chart.AddDataset(LineSet("VOC index (SEN55)", "voc", Hub.AQI.VOC, ""))
		    StatsLabel.Text = StatsText("VOC index", Hub.AQI.VOC, "", "0")
		  Case 4
		    Chart.Title = "Particulate matter" + n
		    Chart.AddDataset(BarSet("PM1.0", "pm1", Hub.AQI.PM1, " µg/m³"))
		    Chart.AddDataset(BarSet("PM2.5", "pm25", Hub.AQI.PM25, " µg/m³"))
		    Chart.AddDataset(BarSet("PM4.0", "pm4", Hub.AQI.PM4, " µg/m³"))
		    Chart.AddDataset(BarSet("PM10", "pm10", Hub.AQI.PM10, " µg/m³"))
		    StatsLabel.Text = StatsText("PM2.5", Hub.AQI.PM25, " µg/m³", "0.0")
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ShowMQTTChart(tabIndex As Integer)
		  // As the desktop MQTT window: temperature, humidity, pressure, and the radio (RSSI / SNR) of the readings
		  If tabIndex = 3 Then
		    Chart.AddLabels(Hub.MQTT.RadioLabels)
		    Chart.AddTimes(Hub.MQTT.RadioTimes)
		    Chart.Title = "RSSI / SNR  (" + SampleCount(Hub.MQTT.RSSIs.Count) + ")"
		    Chart.AddDataset(LineSet("RSSI", "rssi", Hub.MQTT.RSSIs, " dBm"))
		    Chart.AddDataset(LineSet("SNR", "snr", Hub.MQTT.SNRs, " dB"))
		    StatsLabel.Text = StatsText("RSSI", Hub.MQTT.RSSIs, " dBm", "-0") + EndOfLine + StatsText("SNR", Hub.MQTT.SNRs, " dB", "-0.0")
		    Return
		  End If
		  Chart.AddLabels(Hub.MQTT.Labels)
		  Chart.AddTimes(Hub.MQTT.Times)
		  Dim n As String = "  (" + SampleCount(Hub.MQTT.Temps.Count) + ")"
		  Select Case tabIndex
		  Case 0
		    Chart.Title = "Temperature" + n
		    Chart.AddDataset(LineSet("Temperature", "temperature", Hub.MQTT.Temps, " °C"))
		    StatsLabel.Text = StatsText("Temperature", Hub.MQTT.Temps, " °C", "-0.0")
		  Case 1
		    Chart.Title = "Humidity" + n
		    Chart.AddDataset(LineSet("Relative humidity", "humidity", Hub.MQTT.RHs, " %"))
		    StatsLabel.Text = StatsText("Humidity", Hub.MQTT.RHs, " %", "0.0")
		  Case 2
		    Chart.Title = "Pressure" + n
		    Chart.AddDataset(LineSet("Pressure", "pressure", Hub.MQTT.PAs, " hPa"))
		    StatsLabel.Text = StatsText("Pressure", Hub.MQTT.PAs, " hPa", "0.0")
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ShowNodeChart(tabIndex As Integer)
		  Chart.AddLabels(Hub.Node.Labels)
		  Chart.AddTimes(Hub.Node.Times)
		  Dim n As String = "  (" + SampleCount(Hub.Node.Temps.Count) + ")"
		  Select Case tabIndex
		  Case 0
		    Chart.Title = "Temperature" + n
		    Chart.AddDataset(LineSet("Temperature", "temperature", Hub.Node.Temps, " °C"))
		    StatsLabel.Text = StatsText("Temperature", Hub.Node.Temps, " °C", "-0.0")
		  Case 1
		    Chart.Title = "Humidity" + n
		    Chart.AddDataset(LineSet("Relative humidity", "humidity", Hub.Node.RHs, " %"))
		    StatsLabel.Text = StatsText("Humidity", Hub.Node.RHs, " %", "0.0")
		  Case 2
		    Chart.Title = "Pressure" + n
		    Chart.AddDataset(LineSet("Pressure", "pressure", Hub.Node.PAs, " hPa"))
		    StatsLabel.Text = StatsText("Pressure", Hub.Node.PAs, " hPa", "0.0")
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub FillSoilMenu()
		  // The picker: the nodes that sent soil readings, the most recent first; the chosen one stays chosen
		  mUpdating = True
		  NodePicker.RemoveAllRows()
		  mSoilNodes.RemoveAll()
		  Dim rs As RowSet = SoilNodes()
		  If rs <> Nil Then
		    While Not rs.AfterLastRow
		      Dim num As Int64 = rs.Column("fromID").Int64Value
		      Dim count As Integer = rs.Column("n").IntegerValue
		      mSoilNodes.Add(num)
		      Dim label As String = SoilNodeLabel(num) + "  (" + SampleCount(count) + ")"
		      NodePicker.AddRow(label)
		      rs.MoveToNextRow()
		    Wend
		  End If
		  If mSoilNodes.Count = 0 Then
		    NodePicker.AddRow("No soil readings yet")
		    mSoilNode = 0
		  Else
		    Dim selected As Integer = mSoilNodes.IndexOf(mSoilNode)
		    If selected < 0 Then
		      selected = 0
		      mSoilNode = mSoilNodes(0)
		    End If
		    NodePicker.SelectedRowIndex = selected
		  End If
		  If mSoilNodes.Count = 0 Then NodePicker.SelectedRowIndex = 0
		  mUpdating = False
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ShowSoilChart(tabIndex As Integer)
		  // One soil metric of the chosen node, from the database (both feeds, every session)
		  Dim times(), values() As Double
		  If mSoilNode <> 0 Then SoilSeries(mSoilNode, tabIndex, times, values)
		  Dim labels() As String
		  For Each t As Double In times
		    Dim ts As Integer = t
		    labels.Add(TimeLabel(ts, True))
		  Next
		  Chart.AddLabels(labels)
		  Chart.AddTimes(times)
		  Dim name As String = SoilMetricName(tabIndex)
		  Dim unit As String = " " + SoilMetricUnit(tabIndex)
		  Chart.Title = name + "  (" + SampleCount(values.Count) + ")"
		  Chart.AddDataset(LineSet(name, SoilMetricColor(tabIndex), values, unit))
		  StatsLabel.Text = StatsText(name, values, unit, SoilMetricFormat(tabIndex))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SoilFromMQTT(sender As MQTTSource)
		  // Something arrived: a soil node may be new, and the chart may have a new reading
		  #Pragma Unused sender
		  FillSoilMenu()
		  ShowTab(mTab)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SoilFromNode(sender As NodeSource)
		  #Pragma Unused sender
		  FillSoilMenu()
		  ShowTab(mTab)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SoilNodeLabel(num As Int64) As String
		  // The node's name when the node card knows it, else its id
		  Dim id As UInt32 = num
		  For i As Integer = 0 To Hub.Node.NodeNums.LastIndex
		    If Hub.SameNode(Hub.Node.NodeNums(i), id) Then Return Hub.Node.NodeLabels(i)
		  Next
		  Return Hub.NodeText(id)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ShowTab(tabIndex As Integer)
		  // The chart with the tab's series, or the map
		  mTab = tabIndex
		  TabBar.SelectTab(tabIndex)
		  If Kind = "mqtt" Or Kind = "aqi" Then
		    // What the screen follows, again: the AQI device's nickname only arrives with its first answer
		    Dim followed As String
		    If Kind = "mqtt" Then
		      followed = Hub.MQTT.Describe()
		    Else
		      followed = Hub.AQI.Describe()
		    End If
		    SourceLabel.Text = followed
		  End If
		  Dim info As String = InfoText()
		  InfoLabel.Text = info
		  If tabIndex = MapTab() Then
		    Chart.Visible = False
		    Map.Visible = True
		    Dim track As PositionTrack = CurrentTrack()
		    Map.Track = track
		    Dim summary As String = track.Summary()
		    StatsLabel.Text = summary
		    Map.Refresh()
		    Return
		  End If
		  Map.Visible = False
		  Chart.Visible = True
		  Chart.RemoveAllDatasets()
		  Chart.RemoveAllLabels()
		  Select Case Kind
		  Case "mqtt"
		    ShowMQTTChart(tabIndex)
		  Case "aqi"
		    ShowAQIChart(tabIndex)
		  Case "soil"
		    ShowSoilChart(tabIndex)
		  Else
		    ShowNodeChart(tabIndex)
		  End Select
		  Chart.Refresh()
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h0
		Kind As String = "device"
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mKnownNodes As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mMenuNodes() As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSharing As MobileSharingPanel
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSoilNode As Int64
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSoilNodes() As Int64
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTab As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTabNames() As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mUpdating As Boolean
	#tag EndProperty


#tag EndScreenCode

#tag Events FilterField
	#tag Event
		Sub TextChanged()
		  FillNodeMenu()
		End Sub
	#tag EndEvent
#tag EndEvents
#tag Events NodePicker
	#tag Event
		Sub SelectionChanged(item As MobileMenuItem)
		  If mUpdating Then Return
		  Dim i As Integer = Me.SelectedRowIndex
		  If Kind = "soil" Then
		    If i >= 0 And i <= mSoilNodes.LastIndex Then mSoilNode = mSoilNodes(i)
		    ShowTab(mTab)
		    Return
		  End If
		  If i < 0 Or i > mMenuNodes.LastIndex Then Return
		  Hub.Node.SetChartNode(mMenuNodes(i))
		  Map.FitView()
		  ShowTab(mTab)
		End Sub
	#tag EndEvent
#tag EndEvents
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
	#tag ViewProperty
		Name="Kind"
		Visible=false
		Group="Behavior"
		InitialValue="device"
		Type="String"
		EditorType=""
	#tag EndViewProperty
#tag EndViewBehavior
