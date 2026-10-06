#tag Module
Protected Module Hub
	#tag Note, Name = About
		The Android app's state, independent of the screens: the three sources and the range test (connections, samples, tracks), the
		settings (settings.json) and the database. Screens only show it, so closing a screen never drops a connection.
	#tag EndNote


	#tag Method, Flags = &h0
		Sub Resume()
		  // The app is back in the foreground (App.Activated): each source catches up
		  If Not mReady Then Return
		  MQTT.Resume()
		  Node.Resume()
		  AQI.Resume()
		  Range.Resume()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DataFolder() As FolderItem
		  // The app's own folder (settings.json, records.sqlite, Event_Log.txt): ApplicationSupport/Sensor_Dashboard
		  Dim f As FolderItem = SpecialFolder.ApplicationSupport.Child("Sensor_Dashboard")
		  If Not f.Exists Then f.CreateFolder()
		  Return f
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Init()
		  // Once, at the first screen: the event log, the database and a session, the settings, the three sources;
		  // the sources that were on when the app was last used start again
		  If mReady Then Return
		  mReady = True
		  Try
		    Dim logFile As FolderItem = DataFolder().Child("Event_Log.txt")
		    If logFile.Exists Then logFile.Remove()
		    EventLogTOS = TextOutputStream.Create(logFile)
		  Catch e As RuntimeException
		    EventLogTOS = Nil
		  End Try
		  Dim problem As String
		  If OpenDatabase(DataFolder().Child("records.sqlite"), problem) Then
		    StartSession(Random.UUID(False)) // Random.UUID: on Android a shared method of the class
		  Else
		    DatabaseProblem = problem
		  End If
		  LoadSettings()
		  MQTT = New MQTTSource
		  Node = New NodeSource
		  AQI = New AQISource
		  Range = New RangeTestSource
		  If SettingBool("mqtt_on") And MQTT.IsConfigured() Then MQTT.Start()
		  // The node and the range test share the gateway's single TCP client slot: the range test wins
		  If SettingBool("range_on") And Range.IsConfigured() Then
		    Range.Start()
		  ElseIf SettingBool("device_on") And Node.IsConfigured() Then
		    Node.Start()
		  End If
		  If SettingBool("aqi_on") And AQI.IsConfigured() Then AQI.Start()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function AnyOn() As Boolean
		  If MQTT <> Nil And MQTT.IsOn() Then Return True
		  If Node <> Nil And Node.IsOn() Then Return True
		  If AQI <> Nil And AQI.IsOn() Then Return True
		  If Range <> Nil And Range.IsOn() Then Return True
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub KeepAwake(ctrl As MobileUIControl, keep As Boolean)
		  // The screen stays on while a source is on (decision (a): the app logs only in the foreground). View.setKeepScreenOn
		  // applies while the view (any control of the visible screen) is shown
		  #If TargetAndroid Then
		    Declare Sub setKeepScreenOn Lib "android.view.View.instance" (view As Ptr, keepOn As Boolean)
		    setKeepScreenOn(ctrl.Handle, keep)
		  #Else
		    #Pragma Unused ctrl
		    #Pragma Unused keep
		  #EndIf
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub LoadSettings()
		  // settings.json in the app's folder, with the desktop app's keys (mqtt_broker, mqtt_gateway_id, device_host...)
		  Settings = New JSONItem
		  Try
		    Dim f As FolderItem = DataFolder().Child("settings.json")
		    If f.Exists Then
		      Dim tis As TextInputStream = TextInputStream.Open(f)
		      Dim text As String = tis.ReadAll(Encodings.UTF8)
		      tis.Close()
		      Settings = New JSONItem(text)
		    End If
		  Catch e As RuntimeException
		    LogEvents("Settings", "Couldn't read settings.json: " + e.Message)
		    Settings = New JSONItem
		  End Try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SaveSettings()
		  Try
		    Dim f As FolderItem = DataFolder().Child("settings.json")
		    If f.Exists Then f.Remove()
		    Dim tos As TextOutputStream = TextOutputStream.Create(f)
		    tos.Write(Settings.ToString())
		    tos.Close()
		  Catch e As RuntimeException
		    LogEvents("Settings", "Couldn't save settings.json: " + e.Message)
		  End Try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Setting(key As String) As String
		  If Settings = Nil Then Return ""
		  Return Settings.Lookup(key, "").StringValue.Trim
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SettingBool(key As String) As Boolean
		  If Settings = Nil Then Return False
		  Return Settings.Lookup(key, False).BooleanValue
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetSetting(key As String, value As Variant)
		  If Settings = Nil Then Settings = New JSONItem
		  Settings.Value(key) = value
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsHexID(s As String, digits As Integer) As Boolean
		  // digits hex digits, with an optional "!" in front (node and gateway ids: 8; an M5Stack device: 12)
		  Dim t As String = s.Trim
		  If t.BeginsWith("!") Then t = t.Middle(1)
		  If t.Length <> digits Then Return False
		  Dim hexDigits As String = "0123456789abcdefABCDEF"
		  For i As Integer = 0 To t.Length - 1
		    If hexDigits.IndexOf(t.Middle(i, 1)) < 0 Then Return False
		  Next
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeText(num As UInt32) As String
		  // !aabbccdd
		  Dim h As String = "00000000" + Hex(num)
		  Return "!" + h.Right(8).Lowercase
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IDText(id As UInt32) As String
		  // A packet id as an unsigned number: Str of a UInt32 above 2^31 is negative on Android (see SameNode)
		  Return Str(NodeNumber(id))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SameNode(a As UInt32, b As UInt32) As Boolean
		  // Node numbers compared through NodeNumber: on Android a UInt32 above 2^31 from a protobuf is sign-extended while
		  // one made from a hex setting (HexValue) isn't, so a plain = can say !aabbccdd <> !aabbccdd
		  Return NodeNumber(a) = NodeNumber(b)
		End Function
	#tag EndMethod

	#tag Property, Flags = &h0
		AQI As AQISource
	#tag EndProperty

	#tag Property, Flags = &h0
		DatabaseProblem As String
	#tag EndProperty

	#tag Property, Flags = &h0
		MQTT As MQTTSource
	#tag EndProperty

	#tag Property, Flags = &h0
		Node As NodeSource
	#tag EndProperty

	#tag Property, Flags = &h0
		Range As RangeTestSource
	#tag EndProperty

	#tag Property, Flags = &h0
		Settings As JSONItem
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mReady As Boolean
	#tag EndProperty


	#tag ViewBehavior
	#tag EndViewBehavior
End Module
#tag EndModule
