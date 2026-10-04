#tag Class
Protected Class MQTTSource
	#tag Note, Name = About
		The MQTT feed of the Android app: the desktop MQTT window's logic without its window (connection, decoding,
		storage, samples, track). Screens chart its arrays and listen to Changed.
	#tag EndNote


	#tag Method, Flags = &h0
		Function SharePrefix() As String
		  // File names of a share: MQTT_<gateway>, or <node>_via_<gateway>
		  If mNodeFilter <> 0 Then
		    Dim h As String = Hub.NodeText(mNodeFilter)
		    Return "MQTT_" + h.Middle(1) + "_via_" + mFeedID
		  End If
		  Return "MQTT_" + mFeedID
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ExportRows() As RowSet
		  Dim nodeArg As Int64 = -1
		  If mNodeFilter <> 0 Then nodeArg = NodeNumber(mNodeFilter)
		  Dim gatewayArg As Int64 = HexValue(mFeedID)
		  Return TelemetryRows(2, nodeArg, gatewayArg)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Resume()
		  // Back in the foreground: reconnect unless connected or already retrying
		  If Not mOn Then Return
		  If Status = "connected" Or Status = "reconnecting" Then Return
		  Stop()
		  Start()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Start()
		  // Same feed as the desktop MQTT window: <root>/2/e/+/!<gateway>, optionally one node only
		  If mOn Or Not IsConfigured() Then Return
		  mOn = True
		  Dim names(), psks() As String
		  Dim fallback, problem As String
		  mFallbackPSK = "AQ=="
		  If ParseChannelKeys(Hub.Setting("mqtt_keys"), names, psks, fallback, problem) Then
		    mFallbackPSK = fallback
		    For i As Integer = 0 To names.LastIndex
		      MeshEnsureChannels()
		      Call MeshAddChannel(names(i), psks(i))
		    Next
		  Else
		    LogEvents("MQTT", "Keys ignored: " + problem)
		  End If
		  Dim gateway As String = Hub.Setting("mqtt_gateway_id").Lowercase
		  If gateway.BeginsWith("!") Then gateway = gateway.Middle(1)
		  mFeedID = gateway
		  Dim root As String = Hub.Setting("mqtt_root_topic")
		  While root.EndsWith("/")
		    root = root.Left(root.Length - 1)
		  Wend
		  mTopic = root + "/2/e/+/!" + gateway
		  mNodeFilter = 0
		  Dim filter As String = Hub.Setting("mqtt_node_filter")
		  If filter.BeginsWith("!") Then filter = filter.Middle(1)
		  If filter <> "" Then
		    Dim filterNum As UInt32 = HexValue(filter)
		    mNodeFilter = filterNum
		  End If
		  Dim tls As Boolean = Hub.SettingBool("mqtt_tls")
		  Dim broker As String = Hub.Setting("mqtt_broker")
		  Dim host As String = broker
		  Dim port As Integer = If(tls, 8883, 1883)
		  Dim colon As Integer = broker.IndexOf(":")
		  If colon > 0 Then
		    host = broker.Left(colon)
		    Dim givenPort As Integer = Val(broker.Middle(colon + 1))
		    If givenPort > 0 Then port = givenPort
		  End If
		  Dim clientID As String = "SDashA-" + gateway.Left(8) + "-" + Format(System.Random.InRange(0, 999999), "000000")
		  LogEvents("MQTT", "Connecting to " + host + ":" + Str(port) + If(tls, " with TLS", "") + ", topic " + mTopic)
		  ClearData()
		  LoadHistory()
		  mClient = New MQTTClient
		  AddHandler mClient.MQTTConnected, WeakAddressOf ClientConnected
		  AddHandler mClient.MessageReceived, WeakAddressOf ClientMessage
		  AddHandler mClient.MQTTConnectionRefused, WeakAddressOf ClientRefused
		  AddHandler mClient.MQTTDisconnected, WeakAddressOf ClientDisconnected
		  AddHandler mClient.Reconnecting, WeakAddressOf ClientReconnecting
		  AddHandler mClient.ReconnectFailed, WeakAddressOf ClientGaveUp
		  AddHandler mClient.SocketError, WeakAddressOf ClientSocketError
		  mClient.SetCredentials(Hub.Setting("mqtt_username"), Hub.Setting("mqtt_password"))
		  mClient.SetTLS(tls)
		  mClient.SetAutoReconnect(True, 60, 86400)
		  mClient.Connect(host, port, clientID)
		  SetStatus("connecting")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Stop()
		  If Not mOn Then Return
		  mOn = False
		  If mClient <> Nil Then
		    mClient.Disconnect()
		    mClient = Nil
		  End If
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
		  Return Hub.Setting("mqtt_broker") <> "" And Hub.Setting("mqtt_root_topic") <> "" And Hub.IsHexID(Hub.Setting("mqtt_gateway_id"), 8)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Describe() As String
		  // The card's second line: gateway, and the node when one is followed
		  Dim t As String = "gateway !" + mFeedID
		  If Not mOn Then t = "gateway " + Hub.Setting("mqtt_gateway_id")
		  If mNodeFilter <> 0 Then t = Hub.NodeText(mNodeFilter) + " via " + t
		  Return t
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SetStatus(text As String)
		  Status = text
		  RaiseEvent Changed
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ClientConnected(sender As MQTTClient, sessionPresent As Boolean)
		  Dim packetID As Integer = sender.Subscribe(mTopic)
		  LogEvents("MQTT", "Connected, subscribing to " + mTopic + " (" + Str(packetID) + ")")
		  SetStatus("connected")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ClientMessage(sender As MQTTClient, topic As String, payload As String, qos As Integer, retained As Boolean)
		  // <root>/2/e/<channel>/!<gateway>: a channel without a key of its own gets the fallback key
		  Dim parts() As String = topic.Split("/")
		  If parts.Count >= 2 Then
		    Dim channelName As String = parts(parts.LastIndex - 1)
		    MeshEnsureChannels()
		    If channelName <> "PKI" And MeshChannelIndex(channelName) < 0 Then Call MeshAddChannel(channelName, mFallbackPSK)
		  End If
		  Dim jsonText, packetKey As String
		  Dim summary As String = MeshPacketSummary(payload, jsonText, packetKey)
		  If summary = "" Then Return
		  LogEvents("MQTT", summary)
		  If jsonText <> "" Then HandlePacketJSON(jsonText)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ClientRefused(sender As MQTTClient, reasonCode As Integer)
		  Dim reason As String
		  Select Case reasonCode
		  Case 1
		    reason = "unacceptable protocol version"
		  Case 2
		    reason = "client identifier rejected"
		  Case 3
		    reason = "server unavailable"
		  Case 4
		    reason = "bad username or password"
		  Case 5
		    reason = "not authorized"
		  Else
		    reason = "code " + Str(reasonCode)
		  End Select
		  LogEvents("MQTT", "Refused: " + reason)
		  SetStatus("refused: " + reason)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ClientDisconnected(sender As MQTTClient)
		  If sender.IsReconnecting() Then Return
		  SetStatus(If(mOn, "disconnected", "off"))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ClientReconnecting(sender As MQTTClient, attempt As Integer, delaySeconds As Integer, reason As String)
		  LogEvents("MQTT", "Attempt " + Str(attempt) + " in " + Str(delaySeconds) + " s (" + reason + ")")
		  SetStatus("reconnecting")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ClientGaveUp(sender As MQTTClient, reason As String)
		  LogEvents("MQTT", "Gave up reconnecting: " + reason)
		  SetStatus("offline")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ClientSocketError(sender As MQTTClient, err As RuntimeException)
		  If sender.IsReconnecting() Then Return
		  LogEvents("MQTT", "Socket " + sender.ErrorDescription(err))
		  SetStatus("error")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandlePacketJSON(jsonText As String)
		  Dim js As JSONItem
		  Try
		    js = New JSONItem(jsonText)
		  Catch e As RuntimeException
		    Return
		  End Try
		  Dim kind As String = js.Lookup("type", "?").StringValue
		  If kind = "position" Then
		    HandlePosition(js)
		    Return
		  End If
		  If kind <> "telemetry" Then Return
		  Dim fromNum As UInt32 = js.Lookup("from", 0).UInt64Value
		  If mNodeFilter <> 0 And fromNum <> mNodeFilter Then Return
		  Dim payload As JSONItem
		  If Not ChildObject(js, "payload", payload) Then Return
		  If Not payload.HasKey("temperature") Then Return // device metrics, not the sensor
		  Dim rssi As Double = js.Lookup("rssi", -255).DoubleValue
		  Dim snr As Double = js.Lookup("snr", -255).DoubleValue
		  Dim TS As Integer = js.Lookup("timestamp", 0).IntegerValue
		  If TS <= 0 Then
		    Dim nowTS As Integer = DateTime.Now().SecondsFrom1970
		    TS = nowTS
		  End If
		  Dim senderText As String = js.Lookup("sender", "?").StringValue
		  Dim senderID As String = "0"
		  If senderText <> "?" Then senderID = Format(HexValue(senderText), "0")
		  Dim temp As Double = payload.Lookup("temperature", -255).DoubleValue
		  Dim rh As Double = payload.Lookup("relative_humidity", -255).DoubleValue
		  Dim pa As Double = payload.Lookup("barometric_pressure", -255).DoubleValue
		  // Stored as received, with the hops; charted only for a packet the gateway heard directly (see IsDirect)
		  Dim hops, hopStart, relayNode As Integer
		  Dim viaMQTT As Boolean
		  MeshLastPacketRadio(hops, hopStart, relayNode, viaMQTT) // how this packet reached the gateway / node
		  Dim direct As Boolean = IsDirect(hops, viaMQTT)
		  Dim chartRssi As Double = -255
		  Dim chartSnr As Double = -255
		  If direct Then
		    chartRssi = rssi
		    chartSnr = snr
		  End If
		  UpdateData(chartRssi, chartSnr, temp, rh, pa, TS)
		  LogTelemetry(2, Format(NodeNumber(fromNum), "0"), senderID, Str(TS), payload.ToString(), rssi, snr, MySessionNum, hops, hopStart, relayNode, viaMQTT)
		  RaiseEvent Changed
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandlePosition(js As JSONItem)
		  // The followed node's position (the node filter, or the gateway itself)
		  Dim ts, alt, precision, sats As Integer
		  Dim lat, lon As Double
		  If Not ParsePosition(js, ts, lat, lon, alt, precision, sats) Then Return
		  Dim fromNum As UInt32 = js.Lookup("from", 0).UInt64Value
		  If fromNum <> PositionNode() Then Return
		  If ts <= mLastPositionTime Then Return
		  mLastPositionTime = ts
		  Dim gatewayNum As Int64 = HexValue(mFeedID)
		  Dim rssi As Integer = js.Lookup("rssi", -255).IntegerValue
		  Dim snr As Double = js.Lookup("snr", -255).DoubleValue
		  Dim hops, hopStart, relayNode As Integer
		  Dim viaMQTT As Boolean
		  MeshLastPacketRadio(hops, hopStart, relayNode, viaMQTT) // how this packet reached the gateway / node
		  LogPosition(NodeNumber(fromNum), gatewayNum, ts, lat, lon, alt, precision, sats, rssi, snr, hops, hopStart, relayNode, viaMQTT)
		  Track().Add(ts, lat, lon, alt, precision, sats, rssi, snr, hops, viaMQTT)
		  RaiseEvent Changed
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function PositionNode() As UInt32
		  If mNodeFilter <> 0 Then Return mNodeFilter
		  Dim gatewayNum As UInt32 = HexValue(mFeedID)
		  Return gatewayNum
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Track() As PositionTrack
		  If mTrack = Nil Then mTrack = New PositionTrack
		  Return mTrack
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ClearData()
		  Temps.RemoveAll()
		  RHs.RemoveAll()
		  PAs.RemoveAll()
		  Times.RemoveAll()
		  Labels.RemoveAll()
		  RSSIs.RemoveAll()
		  SNRs.RemoveAll()
		  RadioTimes.RemoveAll()
		  RadioLabels.RemoveAll()
		  Track().Clear()
		  mLastPositionTime = 0
		  Latest = ""
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LoadHistory()
		  // Earlier readings and positions of this feed from the database (every session)
		  Dim nodeArg As Int64 = -1
		  If mNodeFilter <> 0 Then nodeArg = NodeNumber(mNodeFilter)
		  Dim gatewayArg As Int64 = HexValue(mFeedID)
		  Dim rs As RowSet = HistoryRows(2, nodeArg, gatewayArg)
		  If rs <> Nil Then
		    While Not rs.AfterLastRow
		      Dim pl As JSONItem
		      Try
		        pl = New JSONItem(rs.Column("payload").StringValue.ReplaceAllBytes("'", """"))
		      Catch e As RuntimeException
		        pl = Nil
		      End Try
		      If pl <> Nil Then
		        If pl.HasKey("temperature") Then
		          UpdateData(rs.Column("rssi").DoubleValue, rs.Column("snr").DoubleValue, pl.Lookup("temperature", -255).DoubleValue, _
		          pl.Lookup("relative_humidity", -255).DoubleValue, pl.Lookup("barometric_pressure", -255).DoubleValue, rs.Column("timestamp").IntegerValue)
		        End If
		      End If
		      rs.MoveToNextRow()
		    Wend
		  End If
		  Call Track().LoadHistory(NodeNumber(PositionNode()))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub UpdateData(rssi As Double, snr As Double, temp As Double, rh As Double, pa As Double, TS As Integer)
		  // One sample (-255: a value the packet didn't have), kept in the arrays the source screen charts
		  Dim label As String = TimeLabel(TS, True)
		  If rh <> -255 And temp <> -255 And pa <> -255 Then
		    Labels.Add(label)
		    Times.Add(TS)
		    Temps.Add(temp)
		    RHs.Add(rh)
		    PAs.Add(pa)
		  End If
		  If snr <> -255 And rssi <> -255 Then
		    RadioLabels.Add(label)
		    RadioTimes.Add(TS)
		    RSSIs.Add(rssi)
		    SNRs.Add(snr)
		  End If
		  While Labels.Count > kMaxSamples
		    Labels.RemoveAt(0)
		    Times.RemoveAt(0)
		    Temps.RemoveAt(0)
		    RHs.RemoveAt(0)
		    PAs.RemoveAt(0)
		  Wend
		  While RadioLabels.Count > kMaxSamples
		    RadioLabels.RemoveAt(0)
		    RadioTimes.RemoveAt(0)
		    RSSIs.RemoveAt(0)
		    SNRs.RemoveAt(0)
		  Wend
		  Dim parts() As String
		  If Temps.Count > 0 Then
		    parts.Add(FormatValue(LastOf(Temps), "-0.0") + " °C")
		    parts.Add(Format(LastOf(RHs), "0") + " %")
		    parts.Add(Format(LastOf(PAs), "0") + " hPa")
		    Latest = String.FromArray(parts, " · ") + "   " + Labels(Labels.LastIndex)
		  End If
		End Sub
	#tag EndMethod

	#tag Hook, Flags = &h0
		Event Changed()
	#tag EndHook

	#tag Property, Flags = &h0
		Labels() As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Latest As String
	#tag EndProperty

	#tag Property, Flags = &h0
		PAs() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		RadioLabels() As String
	#tag EndProperty

	#tag Property, Flags = &h0
		RadioTimes() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		RHs() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		RSSIs() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		SNRs() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		Status As String = "off"
	#tag EndProperty

	#tag Property, Flags = &h0
		Temps() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		Times() As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mClient As MQTTClient
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mFallbackPSK As String = "AQ=="
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mFeedID As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastPositionTime As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mNodeFilter As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mOn As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTopic As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTrack As PositionTrack
	#tag EndProperty

	#tag Constant, Name = kMaxSamples, Type = Double, Dynamic = False, Default = \"100", Scope = Private
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
