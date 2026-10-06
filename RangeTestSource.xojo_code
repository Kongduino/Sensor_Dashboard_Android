#tag Class
Protected Class RangeTestSource
	#tag Note, Name = About
		A range test between the gateway node (the Node card's address, over TCP) and a test device carried around, which
		uploads what it hears to MQTT through the phone's Meshtastic app (MQTT client proxy).
		- gateway -> device: the gateway's packets the device reports (its uploads, <root>/2/e/+/!<device>), among them
		  the test messages Send makes the gateway broadcast with hop limit 0 ("Message from !<gateway> #<n>"). A test
		  message nobody reports within kMissSeconds is "missed".
		- device -> gateway: the device's packets the gateway hears (the TCP link).
		Every reading is placed where the phone is (MobileLocation), else at the device's last reported position.
		Rows go to the rangetest table (SensorData.LogRange); Down and Up hold them for the map.
		The gateway takes one TCP client at a time: the Node card is turned off while this runs (HomeScreen).
	#tag EndNote


	#tag Method, Flags = &h0
		Sub Constructor()
		  Down = New RangeSpots
		  Up = New RangeSpots
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Describe() As String
		  // The card's second line: gateway and device
		  Dim device As String = Hub.Setting("range_device").Lowercase
		  If Not device.BeginsWith("!") Then device = "!" + device
		  If mGatewayNum <> 0 Then Return Hub.NodeText(mGatewayNum) + " ↔ " + device
		  Return Hub.Setting("device_host") + " ↔ " + device
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsConfigured() As Boolean
		  // The gateway's address (Node card), the broker (MQTT card) and the test device
		  Return Hub.Setting("device_host") <> "" And Hub.Setting("mqtt_broker") <> "" And Hub.Setting("mqtt_root_topic") <> "" And _
		  Hub.IsHexID(Hub.Setting("range_device"), 8)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsOn() As Boolean
		  Return mOn
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Resume()
		  // Back in the foreground: a dropped gateway link is opened again now; the MQTT client reconnects on its own
		  If Not mOn Then Return
		  LogEvents("Range", "Back in the foreground")
		  If mLink = Nil Then
		    If mRetry <> Nil Then mRetry.RunMode = Timer.RunModes.Off
		    CreateLink()
		  End If
		  StartLocation()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Send() As String
		  // Makes the gateway broadcast the next test message on the test channel, hop limit 0; "" when sent, else why not
		  If Not mOn Or mLink = Nil Or mGatewayNum = 0 Then Return "the gateway isn't connected"
		  If Hub.SameNode(mGatewayNum, mDeviceNum) Then Return "the test device is the gateway itself"
		  // The firmware refuses texts a client sends too close together (ROUTING NAK RATE_LIMIT_EXCEEDED, seen 1 s apart)
		  Dim sendTime As Integer = DateTime.Now().SecondsFrom1970
		  If mLastSendTime > 0 And sendTime - mLastSendTime < kMinSendSeconds Then Return "wait a few seconds between messages"
		  Dim seq As Integer = Val(Hub.Setting("range_counter")) + 1
		  Dim channelIndex As Integer = Val(Hub.Setting("range_channel"))
		  Dim text As String = "Message from " + Hub.NodeText(mGatewayNum) + " #" + Str(seq)
		  Dim id As UInt32 = mLink.SendText(text, channelIndex, 0)
		  If id = 0 Then Return "not sent"
		  mLastSendTime = sendTime
		  Hub.SetSetting("range_counter", Str(seq))
		  Hub.SaveSettings()
		  Dim lat, lon As Double
		  Dim alt As Integer
		  Dim source As String = Position(lat, lon, alt)
		  Dim rtID As Int64 = LogRange(NodeNumber(mGatewayNum), NodeNumber(mDeviceNum), 1, "sent", "tcp", id, seq, "#" + Str(seq), _
		  -255, -255, -1, 0, 0, False, lat, lon, alt, source)
		  Dim key As String = Hub.IDText(id)
		  mPendingRow.Value(key) = rtID
		  mPendingTime.Value(key) = DateTime.Now().SecondsFrom1970
		  mPendingSeq.Value(key) = seq
		  If source <> "" Then Down.Add(DateTime.Now().SecondsFrom1970, lat, lon, RangeSpots.kPending, -255, -255, -1, id, "#" + Str(seq))
		  SentCount = SentCount + 1
		  AddLog("→ device  #" + Str(seq) + " sent" + If(source = "", " (no position)", ""))
		  If mMissTimer = Nil Then
		    mMissTimer = New Timer
		    AddHandler mMissTimer.Run, WeakAddressOf CheckMissed
		  End If
		  mMissTimer.Period = 10000
		  mMissTimer.RunMode = Timer.RunModes.Multiple
		  RaiseEvent Changed
		  Return ""
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SharePrefix() As String
		  Dim device As String = Hub.Setting("range_device").Lowercase
		  If device.BeginsWith("!") Then device = device.Middle(1)
		  Return "RANGE_" + device
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ExportRows() As RowSet
		  Return RangeRows(NodeNumber(mGatewayNum), NodeNumber(mDeviceNum))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Start()
		  If mOn Or Not IsConfigured() Then Return
		  mOn = True
		  LogEvents("Range", "Start")
		  Dim device As String = Hub.Setting("range_device").Lowercase
		  If device.BeginsWith("!") Then device = device.Middle(1)
		  Dim deviceNum As UInt32 = HexValue(device)
		  mDeviceNum = deviceNum
		  mGatewayNum = 0
		  mConfigTime = 0
		  mKeptSet(1) = False
		  mKeptSet(2) = False
		  mPendingRow = New Dictionary
		  mPendingTime = New Dictionary
		  mPendingSeq = New Dictionary
		  mSeen = New Dictionary
		  SentCount = 0
		  HeardDownCount = 0
		  HeardUpCount = 0
		  MissedCount = 0
		  LogLines.RemoveAll()
		  Down.Clear()
		  Up.Clear()
		  CreateLink()
		  StartMQTT(device)
		  StartLocation()
		  SetStatus("connecting")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Stop()
		  If Not mOn Then Return
		  mOn = False
		  If mRetry <> Nil Then mRetry.RunMode = Timer.RunModes.Off
		  If mMissTimer <> Nil Then mMissTimer.RunMode = Timer.RunModes.Off
		  DropLink()
		  If mClient <> Nil Then
		    mClient.Disconnect()
		    mClient = Nil
		  End If
		  If mLocation <> Nil Then mLocation.Stop()
		  SetStatus("off")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub AddLog(text As String)
		  // The Log tab: newest first, at most 200 lines
		  Dim stamp As String = TimeLabel(DateTime.Now().SecondsFrom1970, False)
		  LogLines.AddAt(0, stamp + "  " + text)
		  While LogLines.Count > 200
		    LogLines.RemoveAt(LogLines.LastIndex)
		  Wend
		  Latest = text
		  LogEvents("Range", text)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub CheckMissed(sender As Timer)
		  // Test messages nobody reported within kMissSeconds: missed
		  Dim now As Integer = DateTime.Now().SecondsFrom1970
		  Dim gone() As String
		  For Each k As Variant In mPendingTime.Keys()
		    Dim sentAt As Integer = mPendingTime.Value(k).IntegerValue
		    If now - sentAt >= kMissSeconds Then gone.Add(k.StringValue)
		  Next
		  For Each key As String In gone
		    Dim rtID As Int64 = mPendingRow.Value(key).Int64Value
		    Dim seq As Integer = mPendingSeq.Value(key).IntegerValue
		    UpdateRange(rtID, "missed", -255, -255, -1, 0, 0, False)
		    Dim idNum As Int64 = Val(key)
		    Dim id As UInt32 = idNum
		    Dim i As Integer = Down.IndexOfPacket(id)
		    If i >= 0 Then Down.SetKind(i, RangeSpots.kMissed, -255, -255, -1)
		    mPendingRow.Remove(key)
		    mPendingTime.Remove(key)
		    mPendingSeq.Remove(key)
		    MissedCount = MissedCount + 1
		    AddLog("→ device  #" + Str(seq) + " missed")
		  Next
		  If mPendingTime.KeyCount = 0 Then sender.RunMode = Timer.RunModes.Off
		  If gone.Count > 0 Then RaiseEvent Changed
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ClientConnected(sender As MQTTClient, sessionPresent As Boolean)
		  If Not (sender Is mClient) Then Return // an earlier client (see StartMQTT)
		  Dim packetID As Integer = sender.Subscribe(mTopic)
		  LogEvents("Range", "MQTT connected, subscribing to " + mTopic + " (" + Str(packetID) + ")")
		  UpdateStatus()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ClientMessage(sender As MQTTClient, topic As String, payload As String, qos As Integer, retained As Boolean)
		  // An upload of the test device: a packet it heard (gateway -> device), or one of its own (its position)
		  If Not (sender Is mClient) Then Return
		  Dim parts() As String = topic.Split("/")
		  If parts.Count >= 2 Then
		    Dim channelName As String = parts(parts.LastIndex - 1)
		    MeshEnsureChannels()
		    If channelName <> "PKI" And MeshChannelIndex(channelName) < 0 Then Call MeshAddChannel(channelName, mFallbackPSK)
		  End If
		  Dim jsonText, packetKey As String
		  Dim summary As String = MeshPacketSummary(payload, jsonText, packetKey)
		  If summary = "" Then
		    LogEvents("Range", "Upload on " + topic + ": not a Meshtastic packet (" + Str(payload.Bytes) + " bytes)")
		    Return
		  End If
		  LogEvents("Range", "Upload: " + summary)
		  If TakeRouting() Then Return
		  Dim fromNode, packetID As UInt32
		  Dim rssi As Integer
		  Dim snr As Double
		  MeshLastPacketSignal(fromNode, packetID, rssi, snr)
		  Dim hops, hopStart, relayNode As Integer
		  Dim viaMQTT As Boolean
		  MeshLastPacketRadio(hops, hopStart, relayNode, viaMQTT)
		  LogEvents("Range", "  id " + Hub.IDText(packetID) + ", hops " + Str(hops) + ", hop_start " + Str(hopStart) + If(viaMQTT, ", via MQTT", "") + _
		  ", rssi " + Str(rssi) + ", snr " + FormatValue(snr, "-0.00") + If(mPendingRow.HasKey(Hub.IDText(packetID)), ", a test message", ""))
		  If Hub.SameNode(fromNode, mDeviceNum) Then
		    NoteDevicePosition(jsonText)
		    // The same packet uploaded again: the device sent it a second time because it heard no node rebroadcast it
		    // (Meshtastic's implicit ACK for broadcasts): a sign of a marginal link
		    If Not FirstTime("o" + packetKey) Then AddLog("→ gateway  " + PacketLabel(jsonText) + " repeated by the device (no rebroadcast heard in time)")
		    Return
		  End If
		  If Not Hub.SameNode(fromNode, mGatewayNum) Or mGatewayNum = 0 Then Return
		  If Not FirstTime("d" + packetKey) Then Return
		  If rssi = 0 And snr = 0 Then
		    rssi = -255
		    snr = -255
		  End If
		  Dim key As String = Hub.IDText(packetID)
		  If mPendingRow.HasKey(key) Then
		    // One of our test messages: sent with hop limit 0, so heard directly (it arrives with hop_start 0, which alone
		    // would read as "unknown")
		    Dim rtID As Int64 = mPendingRow.Value(key).Int64Value
		    Dim seq As Integer = mPendingSeq.Value(key).IntegerValue
		    Dim testHops As Integer = If(viaMQTT, -1, 0)
		    UpdateRange(rtID, If(viaMQTT, "via mqtt", "heard"), rssi, snr, testHops, hopStart, relayNode, viaMQTT)
		    Dim i As Integer = Down.IndexOfPacket(packetID)
		    Dim kind As Integer = If(viaMQTT, RangeSpots.kUnknownHops, RangeSpots.kHeard)
		    If i >= 0 Then
		      Down.SetKind(i, kind, rssi, snr, testHops)
		    Else
		      Dim lat, lon As Double
		      Dim alt As Integer
		      Dim source As String = Position(lat, lon, alt)
		      If source <> "" Then Down.Add(DateTime.Now().SecondsFrom1970, lat, lon, kind, rssi, snr, testHops, packetID, "#" + Str(seq))
		    End If
		    mPendingRow.Remove(key)
		    mPendingTime.Remove(key)
		    mPendingSeq.Remove(key)
		    HeardDownCount = HeardDownCount + 1
		    Dim signal As String = SignalText(rssi, snr)
		    LastDown = signal
		    AddLog("→ device  #" + Str(seq) + " heard  " + signal)
		    RaiseEvent Changed
		    Return
		  End If
		  // Another packet of the gateway that the device heard
		  RecordReading(1, "mqtt", packetID, PacketLabel(jsonText), rssi, snr, hops, hopStart, relayNode, viaMQTT)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ClientState(sender As MQTTClient)
		  If Not (sender Is mClient) Then Return
		  UpdateStatus()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub CreateLink()
		  DropLink()
		  mConfigTime = 0 // see LinkClosed
		  mLink = New MeshDeviceLink
		  AddHandler mLink.ConfigComplete, WeakAddressOf LinkConfigComplete
		  AddHandler mLink.LinkClosed, WeakAddressOf LinkClosed
		  AddHandler mLink.PacketReceived, WeakAddressOf LinkPacketReceived
		  Dim port As Integer = Val(Hub.Setting("device_port"))
		  If port <= 0 Then port = 4403
		  mLink.ConnectTCP(Hub.Setting("device_host"), port)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DropLink()
		  If mLink = Nil Then Return
		  mLink.Close()
		  mLink = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function FirstTime(key As String) As Boolean
		  // False for a packet already counted (the gateway replays packets at each connection; uploads can repeat)
		  If mSeen.HasKey(key) Then Return False
		  mSeen.Value(key) = True
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LinkClosed(sender As MeshDeviceLink, reason As String)
		  // Still on: try again every 30 s (the gateway rebooting, or another app holding its single TCP client slot)
		  If Not (sender Is mLink) Then Return // an earlier link: the current one is still up (see LinkConfigComplete)
		  LogEvents("Range", "Gateway connection closed: " + reason)
		  mLink = Nil
		  mConfigTime = 0 // the next link replays old packets until its configuration is complete: not readings
		  If Not mOn Then Return
		  If mRetry = Nil Then
		    mRetry = New Timer
		    AddHandler mRetry.Run, WeakAddressOf RetryNow
		  End If
		  mRetry.Period = 30000
		  mRetry.RunMode = Timer.RunModes.Single
		  UpdateStatus()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LinkConfigComplete(sender As MeshDeviceLink)
		  // The gateway is known: its earlier range tests with this device go on the map.
		  // A link that isn't the current one is closed: the gateway takes one client, so two links of ours would take turns
		  // pushing each other off (each closing link used to clear mLink and orphan the other)
		  If Not (sender Is mLink) Then
		    sender.Close()
		    Return
		  End If
		  Dim myNum As UInt32 = sender.MyNodeNum()
		  Dim isNewGateway As Boolean = (mGatewayNum <> myNum)
		  mGatewayNum = myNum
		  mConfigTime = DateTime.Now().SecondsFrom1970
		  LogEvents("Range", "Gateway " + Hub.NodeText(mGatewayNum) + " connected")
		  If Hub.SameNode(mGatewayNum, mDeviceNum) Then
		    SetStatus("the test device is the gateway itself: pick another device in Settings")
		    Return
		  End If
		  If isNewGateway Then LoadHistory()
		  UpdateStatus()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LinkPacketReceived(sender As MeshDeviceLink, envelope As String)
		  // A packet the gateway heard: device -> gateway when it's from the test device
		  If Not (sender Is mLink) Then Return
		  Dim jsonText, packetKey As String
		  Dim summary As String = MeshPacketSummary(envelope, jsonText, packetKey)
		  If summary = "" Then Return
		  If TakeRouting() Then Return
		  Dim fromNode, packetID As UInt32
		  Dim rssi As Integer
		  Dim snr As Double
		  MeshLastPacketSignal(fromNode, packetID, rssi, snr)
		  If Not Hub.SameNode(fromNode, mDeviceNum) Or Hub.SameNode(fromNode, mGatewayNum) Then Return // the gateway's own packets aren't readings
		  LogEvents("Range", "Gateway heard: " + summary)
		  Dim hops, hopStart, relayNode As Integer
		  Dim viaMQTT As Boolean
		  MeshLastPacketRadio(hops, hopStart, relayNode, viaMQTT)
		  NoteDevicePosition(jsonText)
		  // The gateway replays the last packet of each node when the link opens: those are old, not readings
		  If mConfigTime = 0 Or DateTime.Now().SecondsFrom1970 - mConfigTime < 5 Then Return
		  If Not FirstTime("u" + packetKey) Then Return
		  If rssi = 0 And snr = 0 Then
		    rssi = -255
		    snr = -255
		  End If
		  RecordReading(2, "tcp", packetID, PacketLabel(jsonText), rssi, snr, hops, hopStart, relayNode, viaMQTT)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LoadHistory()
		  // Earlier readings between this gateway and device (every session) for the map. Test messages still "sent" from an
		  // earlier run were never reported: missed
		  Try
		    MySensordb.ExecuteSQL("UPDATE rangetest SET status='missed' WHERE status='sent' AND sessionID<>" + Str(MySessionNum) + ";")
		  Catch e As DatabaseException
		    LogEvents("Range", "Database error: " + e.Message)
		  End Try
		  Down.Clear()
		  Up.Clear()
		  Dim rs As RowSet = RangeRows(NodeNumber(mGatewayNum), NodeNumber(mDeviceNum))
		  If rs = Nil Then Return
		  While Not rs.AfterLastRow
		    If Not rs.Column("latitude").Value.IsNull And rs.Column("status").StringValue <> "failed" Then // failed: never transmitted
		      Dim status As String = rs.Column("status").StringValue
		      Dim hopCount As Integer = -1
		      If Not rs.Column("hops").Value.IsNull Then hopCount = rs.Column("hops").IntegerValue
		      Dim kind As Integer = SpotKind(hopCount, rs.Column("viaMQTT").IntegerValue = 1)
		      If status = "missed" Then kind = RangeSpots.kMissed
		      If status = "sent" Then kind = RangeSpots.kPending
		      Dim id As UInt32 = rs.Column("packetID").Int64Value
		      Dim spots As RangeSpots = Up
		      If rs.Column("direction").IntegerValue = 1 Then spots = Down
		      spots.Add(rs.Column("timestamp").IntegerValue, rs.Column("latitude").DoubleValue, rs.Column("longitude").DoubleValue, kind, _
		      rs.Column("rssi").IntegerValue, rs.Column("snr").DoubleValue, hopCount, id, rs.Column("label").StringValue)
		    End If
		    rs.MoveToNextRow()
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub NoteDevicePosition(jsonText As String)
		  // The test device's own position (from its uploads or as the gateway heard it): the fallback when the phone has none
		  If jsonText = "" Then Return
		  Dim js As JSONItem
		  Try
		    js = New JSONItem(jsonText)
		  Catch e As RuntimeException
		    Return
		  End Try
		  If js.Lookup("type", "").StringValue <> "position" Then Return
		  Dim ts, alt, precision, sats As Integer
		  Dim lat, lon As Double
		  If Not ParsePosition(js, ts, lat, lon, alt, precision, sats) Then Return
		  // Dated by the position's own time when it has one: the gateway replays the device's last position at each
		  // connection, which can be days old (seen: a position from the day before, used as the current one)
		  Dim now As Integer = DateTime.Now().SecondsFrom1970
		  Dim fixTime As Integer = now
		  If ts > 0 And ts < now Then fixTime = ts
		  If now - fixTime > kDeviceFixSeconds Then Return
		  If fixTime < mDeviceFixTime Then Return // older than the one we have
		  mDeviceLat = lat
		  mDeviceLon = lon
		  mDeviceAlt = alt
		  mDeviceFixTime = fixTime
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function PacketLabel(jsonText As String) As String
		  // What a packet was, for the log and the map: its converter type ("position", "text"...), else "packet"
		  If jsonText = "" Then Return "packet"
		  Try
		    Dim js As New JSONItem(jsonText)
		    Dim t As String = js.Lookup("type", "packet").StringValue
		    Return t
		  Catch e As RuntimeException
		    Return "packet"
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub PhoneAuthorization(sender As MobileLocation, state As MobileLocation.AuthorizationStates)
		  If state = MobileLocation.AuthorizationStates.AuthorizedAppInUse Or state = MobileLocation.AuthorizationStates.AuthorizedAlways Then
		    sender.Start()
		  Else
		    // On Android the state can be wrong (see StartLocation), so this is only a note: a fix may still arrive
		    LogEvents("Range", "Location state says not allowed: if no fix arrives, positions come from the device")
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub PhoneLocation(sender As MobileLocation, latitude As Double, longitude As Double, accuracy As Double, altitude As Double, altitudeAccuracy As Double, course As Double, speed As Double, timeStamp As DateTime)
		  mPhoneLat = latitude
		  mPhoneLon = longitude
		  mPhoneAlt = altitude
		  mPhoneFixTime = DateTime.Now().SecondsFrom1970
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Position(ByRef lat As Double, ByRef lon As Double, ByRef alt As Integer) As String
		  // Where the test device is now: the phone's fix (at most kPhoneFixSeconds old), else the device's last position
		  // (at most kDeviceFixSeconds old). Returns "phone", "device", or "" when neither is known
		  Dim now As Integer = DateTime.Now().SecondsFrom1970
		  If mPhoneFixTime > 0 And now - mPhoneFixTime <= kPhoneFixSeconds Then
		    lat = mPhoneLat
		    lon = mPhoneLon
		    alt = mPhoneAlt
		    Return "phone"
		  End If
		  If mDeviceFixTime > 0 And now - mDeviceFixTime <= kDeviceFixSeconds Then
		    lat = mDeviceLat
		    lon = mDeviceLon
		    alt = mDeviceAlt
		    Return "device"
		  End If
		  Return ""
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RecordReading(direction As Integer, method As String, packetID As UInt32, label As String, rssi As Integer, snr As Double, hops As Integer, hopStart As Integer, relayNode As Integer, viaMQTT As Boolean)
		  // A packet heard: one row, and a spot on the map of its direction when there is a position
		  Dim lat, lon As Double
		  Dim alt As Integer
		  Dim source As String = Position(lat, lon, alt)
		  // Automatic packets (positions, telemetry, nodeinfo...) taken where an earlier one of this direction was kept
		  // add nothing to the map: dropped. Texts (replies) are always kept
		  If label <> "text" And source <> "" Then
		    If mKeptSet(direction) Then
		      Dim metres As Double = MetresBetween(mKeptLat(direction), mKeptLon(direction), lat, lon)
		      If metres < kMinSpotMetres Then
		        LogEvents("Range", If(direction = 1, "→ device  ", "→ gateway  ") + label + " dropped: " + Format(metres, "0") + " m from the previous one")
		        Return
		      End If
		    End If
		    mKeptSet(direction) = True
		    mKeptLat(direction) = lat
		    mKeptLon(direction) = lon
		  End If
		  Call LogRange(NodeNumber(mGatewayNum), NodeNumber(mDeviceNum), direction, "heard", method, packetID, 0, label, _
		  rssi, snr, hops, hopStart, relayNode, viaMQTT, lat, lon, alt, source)
		  Dim kind As Integer = SpotKind(hops, viaMQTT)
		  Dim spots As RangeSpots = Up
		  If direction = 1 Then spots = Down
		  If source <> "" Then spots.Add(DateTime.Now().SecondsFrom1970, lat, lon, kind, rssi, snr, hops, packetID, label)
		  Dim how As String
		  Select Case kind
		  Case RangeSpots.kHeard
		    Dim signal As String = SignalText(rssi, snr)
		    how = signal
		  Case RangeSpots.kRelayed
		    how = "relayed, " + Str(hops) + If(hops = 1, " hop", " hops")
		  Else
		    how = If(viaMQTT, "via MQTT", "hops unknown")
		  End Select
		  If direction = 1 Then
		    HeardDownCount = HeardDownCount + 1
		    If kind = RangeSpots.kHeard Then LastDown = how
		    AddLog("→ device  " + label + "  " + how)
		  Else
		    HeardUpCount = HeardUpCount + 1
		    If kind = RangeSpots.kHeard Then LastUp = how
		    AddLog("→ gateway  " + label + "  " + how)
		  End If
		  RaiseEvent Changed
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RetryNow(sender As Timer)
		  If Not mOn Then Return
		  If mLink <> Nil Then Return // a link is already being opened (the retry timer was once seen firing twice at once)
		  CreateLink()
		  UpdateStatus()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SetStatus(text As String)
		  Status = text
		  RaiseEvent Changed
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function MetresBetween(lat1 As Double, lon1 As Double, lat2 As Double, lon2 As Double) As Double
		  // Distance on the ground, flat-earth approximation (fine for the tens of metres it's used for)
		  Const kEarthMetres = 6371000.0
		  Const kRadians = 0.017453292519943295
		  Dim midLat As Double = (lat1 + lat2) / 2 * kRadians
		  Dim dx As Double = (lon2 - lon1) * kRadians * Cos(midLat) * kEarthMetres
		  Dim dy As Double = (lat2 - lat1) * kRadians * kEarthMetres
		  Return Sqrt(dx * dx + dy * dy)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SignalText(rssi As Integer, snr As Double) As String
		  Dim t As String
		  If snr <> -255 Then t = "SNR " + FormatValue(snr, "-0.0") + " dB"
		  If rssi <> -255 Then t = t + If(t = "", "", "  ·  ") + "RSSI " + Str(rssi) + " dBm"
		  If t = "" Then t = "heard directly"
		  Return t
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SpotKind(hops As Integer, viaMQTT As Boolean) As Integer
		  If viaMQTT Or hops < 0 Then Return RangeSpots.kUnknownHops
		  If hops > 0 Then Return RangeSpots.kRelayed
		  Return RangeSpots.kHeard
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub StartLocation()
		  // The phone's position (asked once for permission; without it, positions come from the device)
		  If mLocation = Nil Then
		    mLocation = New MobileLocation
		    AddHandler mLocation.LocationChanged, WeakAddressOf PhoneLocation
		    AddHandler mLocation.AuthorizationStateChanged, WeakAddressOf PhoneAuthorization
		  End If
		  Try
		    Dim state As MobileLocation.AuthorizationStates = mLocation.AuthorizationState
		    If state = MobileLocation.AuthorizationStates.AuthorizedAppInUse Or state = MobileLocation.AuthorizationStates.AuthorizedAlways Then
		      mLocation.Start()
		    Else
		      mLocation.RequestUsageAuthorization(MobileLocation.UsageTypes.AppInUse)
		      // On Android, AuthorizationState says 0 even when the permission is granted: start anyway (it throws if
		      // the permission really is missing)
		      #If TargetAndroid Then
		        mLocation.Start()
		      #EndIf
		    End If
		  Catch e As RuntimeException
		    LogEvents("Range", "Location unavailable: " + e.Message)
		  End Try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub StartMQTT(device As String)
		  // The test device's uploads, with the MQTT card's broker, account and channel keys
		  Dim names(), psks() As String
		  Dim fallback, problem As String
		  mFallbackPSK = "AQ=="
		  If ParseChannelKeys(Hub.Setting("mqtt_keys"), names, psks, fallback, problem) Then
		    mFallbackPSK = fallback
		    For i As Integer = 0 To names.LastIndex
		      MeshEnsureChannels()
		      Call MeshAddChannel(names(i), psks(i))
		    Next
		  End If
		  Dim root As String = Hub.Setting("mqtt_root_topic")
		  While root.EndsWith("/")
		    root = root.Left(root.Length - 1)
		  Wend
		  mTopic = root + "/2/e/+/!" + device
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
		  Dim clientID As String = "SDashR-" + device.Left(8) + "-" + Format(System.Random.InRange(0, 999999), "000000")
		  LogEvents("Range", "Connecting to " + host + ":" + Str(port) + ", topic " + mTopic)
		  // Only one client: an earlier one is closed first (two were seen starting together; the status then followed the one
		  // that never connected)
		  If mClient <> Nil Then
		    mClient.Disconnect()
		    mClient = Nil
		  End If
		  mClient = New MQTTClient
		  AddHandler mClient.MQTTConnected, WeakAddressOf ClientConnected
		  AddHandler mClient.MessageReceived, WeakAddressOf ClientMessage
		  AddHandler mClient.MQTTDisconnected, WeakAddressOf ClientState
		  mClient.SetCredentials(Hub.Setting("mqtt_username"), Hub.Setting("mqtt_password"))
		  mClient.SetTLS(tls)
		  mClient.SetAutoReconnect(True, 60, 86400)
		  mClient.Connect(host, port, clientID)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function TakeRouting() As Boolean
		  // After MeshPacketSummary: True when the packet was a ROUTING ACK / NAK, which is never a reading. A NAK for one of
		  // our test messages (RATE_LIMIT_EXCEEDED...) means the gateway never transmitted it: failed at once, off the map
		  Dim requestID, routeFrom, routeTo As UInt32
		  Dim errorCode As Integer
		  If Not MeshTakeRouting(requestID, routeFrom, routeTo, errorCode) Then Return False
		  If errorCode = 0 Then Return True
		  Dim key As String = Hub.IDText(requestID)
		  If Not mPendingRow.HasKey(key) Then Return True
		  Dim rtID As Int64 = mPendingRow.Value(key).Int64Value
		  Dim seq As Integer = mPendingSeq.Value(key).IntegerValue
		  UpdateRange(rtID, "failed", -255, -255, -1, 0, 0, False)
		  Dim i As Integer = Down.IndexOfPacket(requestID)
		  If i >= 0 Then Down.RemoveAt(i)
		  mPendingRow.Remove(key)
		  mPendingTime.Remove(key)
		  mPendingSeq.Remove(key)
		  SentCount = SentCount - 1
		  AddLog("→ device  #" + Str(seq) + " not sent by the gateway: " + MeshRoutingErrorName(errorCode))
		  RaiseEvent Changed
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub UpdateStatus()
		  // "connected" when both the gateway and the broker are; otherwise what is missing
		  If Not mOn Then
		    SetStatus("off")
		    Return
		  End If
		  If mGatewayNum <> 0 And Hub.SameNode(mGatewayNum, mDeviceNum) Then
		    SetStatus("the test device is the gateway itself: pick another device in Settings")
		    Return
		  End If
		  Dim gatewayUp As Boolean = (mLink <> Nil And mGatewayNum <> 0)
		  Dim brokerUp As Boolean = False
		  If mClient <> Nil Then
		    Dim connected As Boolean = mClient.IsMQTTConnected()
		    brokerUp = connected
		  End If
		  If gatewayUp And brokerUp Then
		    SetStatus("connected")
		  ElseIf gatewayUp Then
		    SetStatus("waiting for the broker")
		  ElseIf brokerUp Then
		    SetStatus("waiting for the gateway")
		  Else
		    SetStatus("connecting")
		  End If
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Changed()
	#tag EndHook


	#tag Property, Flags = &h0
		Down As RangeSpots
	#tag EndProperty

	#tag Property, Flags = &h0
		HeardDownCount As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		HeardUpCount As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		LastDown As String
	#tag EndProperty

	#tag Property, Flags = &h0
		LastUp As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Latest As String
	#tag EndProperty

	#tag Property, Flags = &h0
		LogLines() As String
	#tag EndProperty

	#tag Property, Flags = &h0
		MissedCount As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mClient As MQTTClient
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mConfigTime As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDeviceAlt As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDeviceFixTime As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDeviceLat As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDeviceLon As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDeviceNum As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mFallbackPSK As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mGatewayNum As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLink As MeshDeviceLink
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLocation As MobileLocation
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mMissTimer As Timer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mOn As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPendingRow As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPendingSeq As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mKeptLat(2) As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mKeptLon(2) As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mKeptSet(2) As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastSendTime As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPendingTime As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPhoneAlt As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPhoneFixTime As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPhoneLat As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPhoneLon As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRetry As Timer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSeen As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTopic As String
	#tag EndProperty

	#tag Property, Flags = &h0
		SentCount As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		Status As String = "off"
	#tag EndProperty

	#tag Property, Flags = &h0
		Up As RangeSpots
	#tag EndProperty


	#tag Constant, Name = kDeviceFixSeconds, Type = Double, Dynamic = False, Default = \"900", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kMinSpotMetres, Type = Double, Dynamic = False, Default = \"30", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kMinSendSeconds, Type = Double, Dynamic = False, Default = \"5", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kMissSeconds, Type = Double, Dynamic = False, Default = \"120", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kPhoneFixSeconds, Type = Double, Dynamic = False, Default = \"120", Scope = Private
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
