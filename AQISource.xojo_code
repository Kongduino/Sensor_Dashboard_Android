#tag Class
Protected Class AQISource
	#tag Note, Name = About
		An M5Stack AQI device for the Android app: the desktop AQI window's logic without its window.
	#tag EndNote


	#tag Method, Flags = &h0
		Function SharePrefix() As String
		  Return "AQI_" + Hub.Setting("aqi_device_id")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ExportRows() As RowSet
		  Dim deviceNum As Int64 = HexValue(Hub.Setting("aqi_device_id"))
		  Return TelemetryRows(1, deviceNum, -1)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Resume()
		  // Back in the foreground: poll now
		  If mOn Then Fetch()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Start()
		  // Polls the M5Stack device's latest data (ezdata), as the desktop AQI window does
		  If mOn Or Not IsConfigured() Then Return
		  mOn = True
		  mStarted = False
		  mLastUpdateTime = ""
		  ClearData()
		  If mConnection = Nil Then
		    mConnection = New URLConnection
		    AddHandler mConnection.ContentReceived, WeakAddressOf HandleContent
		    AddHandler mConnection.Error, WeakAddressOf HandleError
		  End If
		  If mTimer = Nil Then
		    mTimer = New Timer
		    AddHandler mTimer.Run, WeakAddressOf PollNow
		  End If
		  mTimer.Period = 60000
		  mTimer.RunMode = Timer.RunModes.Multiple
		  SetStatus("connecting")
		  Fetch()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Stop()
		  If Not mOn Then Return
		  mOn = False
		  If mTimer <> Nil Then mTimer.RunMode = Timer.RunModes.Off
		  SetStatus("off")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsOn() As Boolean
		  Return mOn
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsConfigured() As Boolean
		  Return Hub.IsHexID(Hub.Setting("aqi_device_id"), 12)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Describe() As String
		  If Nickname <> "" Then Return Nickname + " (" + Hub.Setting("aqi_device_id") + ")"
		  Return Hub.Setting("aqi_device_id")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SetStatus(text As String)
		  Status = text
		  RaiseEvent Changed
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub PollNow(sender As Timer)
		  Fetch()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Fetch()
		  If Not mOn Or mBusy Then Return
		  mBusy = True
		  mConnection.Send("GET", kAQIURL.Replace("$1", Hub.Setting("aqi_device_id")))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandleError(sender As URLConnection, e As RuntimeException)
		  mBusy = False
		  LogEvents("AQI", "Network error: " + e.Message)
		  SetStatus("network error, retrying")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandleContent(sender As URLConnection, URL As String, HTTPStatus As Integer, content As String)
		  mBusy = False
		  If Not mOn Then Return
		  If HTTPStatus <> 200 Then
		    SetStatus("HTTP status " + Str(HTTPStatus))
		    Return
		  End If
		  Dim problem As String
		  Dim values As JSONItem
		  Dim updateTime, nick As String
		  Dim periodicity As Integer
		  If Not ParseAQIResponse(content, values, updateTime, nick, periodicity, problem) Then
		    LogEvents("AQI", problem)
		    SetStatus(problem + ", retrying") // the next poll tries again
		    Return
		  End If
		  Nickname = nick
		  If Not mStarted Then
		    mStarted = True
		    Dim period As Integer = Min(periodicity, 60) * 1000
		    mTimer.Period = period
		    Dim before As Int64 = Val(updateTime)
		    LoadHistory(before)
		  End If
		  If updateTime <> mLastUpdateTime Then UpdateData(values, updateTime, True)
		  SetStatus("connected")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ClearData()
		  Labels.RemoveAll()
		  Times.RemoveAll()
		  Temp55.RemoveAll()
		  Temp40.RemoveAll()
		  RH55.RemoveAll()
		  RH40.RemoveAll()
		  VOC.RemoveAll()
		  CO2.RemoveAll()
		  PM1.RemoveAll()
		  PM25.RemoveAll()
		  PM4.RemoveAll()
		  PM10.RemoveAll()
		  Latest = ""
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LoadHistory(before As Int64)
		  // Earlier readings of the device (older than the current one), stored with flat keys sen55_... / scd40_...
		  Dim deviceNum As Int64 = HexValue(Hub.Setting("aqi_device_id"))
		  Dim rs As RowSet = HistoryRows(1, deviceNum, -1, before)
		  If rs = Nil Then Return
		  While Not rs.AfterLastRow
		    Dim pl As JSONItem
		    Try
		      pl = New JSONItem(rs.Column("payload").StringValue.ReplaceAllBytes("'", """"))
		    Catch e As RuntimeException
		      pl = Nil
		    End Try
		    If pl <> Nil Then
		      Dim sen55 As New JSONItem
		      Dim scd40 As New JSONItem
		      For Each k As String In pl.Keys()
		        If k.BeginsWith("sen55_") Then sen55.Value(k.Middle(6)) = pl.Value(k)
		        If k.BeginsWith("scd40_") Then scd40.Value(k.Middle(6)) = pl.Value(k)
		      Next
		      Dim nested As New JSONItem
		      nested.Value("sen55") = sen55
		      nested.Value("scd40") = scd40
		      UpdateData(nested, rs.Column("timestamp").StringValue, False)
		    End If
		    rs.MoveToNextRow()
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub UpdateData(values As JSONItem, updateTime As String, store As Boolean)
		  // One reading (store = False: from the database, charted but not stored again)
		  Dim sen55, scd40 As JSONItem
		  If Not ChildObject(values, "sen55", sen55) Or Not ChildObject(values, "scd40", scd40) Then Return
		  mLastUpdateTime = updateTime
		  Dim ts As Integer = Val(updateTime)
		  Labels.Add(TimeLabel(ts, False))
		  Times.Add(ts)
		  Temp55.Add(sen55.Lookup("temperature", -255.0).DoubleValue)
		  RH55.Add(sen55.Lookup("humidity", -255.0).DoubleValue)
		  VOC.Add(sen55.Lookup("voc", -255.0).DoubleValue)
		  PM1.Add(sen55.Lookup("pm1.0", -255.0).DoubleValue)
		  PM25.Add(sen55.Lookup("pm2.5", -255.0).DoubleValue)
		  PM4.Add(sen55.Lookup("pm4.0", -255.0).DoubleValue)
		  PM10.Add(sen55.Lookup("pm10.0", -255.0).DoubleValue)
		  Temp40.Add(scd40.Lookup("temperature", -255.0).DoubleValue)
		  RH40.Add(scd40.Lookup("humidity", -255.0).DoubleValue)
		  CO2.Add(scd40.Lookup("co2", -255.0).DoubleValue)
		  While Labels.Count > kMaxSamples
		    Labels.RemoveAt(0)
		    Times.RemoveAt(0)
		    Temp55.RemoveAt(0)
		    Temp40.RemoveAt(0)
		    RH55.RemoveAt(0)
		    RH40.RemoveAt(0)
		    VOC.RemoveAt(0)
		    CO2.RemoveAt(0)
		    PM1.RemoveAt(0)
		    PM25.RemoveAt(0)
		    PM4.RemoveAt(0)
		    PM10.RemoveAt(0)
		  Wend
		  Latest = FormatValue(LastOf(Temp55), "-0.0") + " °C · " + Format(LastOf(RH55), "0") + " % · CO2 " + Format(LastOf(CO2), "0") + " ppm · PM2.5 " + _
		  Format(LastOf(PM25), "0.0") + "   " + Labels(Labels.LastIndex)
		  If Not store Then Return
		  Dim pl As New JSONItem
		  For Each k As String In sen55.Keys()
		    pl.Value("sen55_" + k) = sen55.Value(k)
		  Next
		  For Each k As String In scd40.Keys()
		    pl.Value("scd40_" + k) = scd40.Value(k)
		  Next
		  Dim deviceNum As String = Format(HexValue(Hub.Setting("aqi_device_id")), "0")
		  LogTelemetry(1, deviceNum, deviceNum, updateTime, pl.ToString(), -255, -255, MySessionNum)
		  RaiseEvent Changed
		End Sub
	#tag EndMethod

	#tag Hook, Flags = &h0
		Event Changed()
	#tag EndHook

	#tag Property, Flags = &h0
		CO2() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		Labels() As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Latest As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Nickname As String
	#tag EndProperty

	#tag Property, Flags = &h0
		PM1() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		PM10() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		PM25() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		PM4() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		RH40() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		RH55() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		Status As String = "off"
	#tag EndProperty

	#tag Property, Flags = &h0
		Temp40() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		Temp55() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		Times() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		VOC() As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mBusy As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mConnection As URLConnection
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastUpdateTime As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mOn As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mStarted As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTimer As Timer
	#tag EndProperty

	#tag Constant, Name = kMaxSamples, Type = Double, Dynamic = False, Default = \"100", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kAQIURL, Type = String, Dynamic = False, Default = \"https://ezdata2.m5stack.com/api/v2/$1/dataMacByKey/raw", Scope = Private
	#tag EndConstant

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
	#tag EndViewBehavior
End Class
#tag EndClass
