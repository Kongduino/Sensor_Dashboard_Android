#tag Class
Protected Class MQTTClient
Inherits SSLSocket
	#tag Event
		Sub Connected()
		  Dim how As String = "TCP connection open"
		  If Me.SSLEnabled Then
		    how = "TLS connection open"
		    If Not Me.SSLConnected Then how = how + " (TLS handshake still in progress)"
		  End If
		  RaiseEvent Trace(how + ", sending CONNECT")
		  SendConnectPacket()
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataAvailable()
		  Dim s As String
		  s = MeshBin(Me.ReadAll) // one byte per character on Android (see MeshBin)
		  mLastReceived = NowSeconds() // for the keep-alive watchdog
		  mRxBuffer = MeshBin(mRxBuffer + s)
		  RaiseEvent RawDataReceived(s) // every TCP read, e.g. for a hex dump
		  
		  Do
		    If mRxBuffer.Bytes < 2 Then Exit Do
		    
		    Dim firstByte As Integer = mRxBuffer.MiddleBytes(0, 1).AscByte
		    Dim packetType As Integer = Bitwise.ShiftRight(firstByte, 4)
		    Dim pFlags As Integer = firstByte And &h0F
		    
		    Dim rlBytesUsed As Integer
		    Dim remLen As Integer = DecodeRemainingLength(mRxBuffer, 1, rlBytesUsed)
		    If remLen = -1 Then Exit Do
		    
		    Dim headerLen As Integer = 1 + rlBytesUsed
		    Dim totalLen As Integer = headerLen + remLen
		    If mRxBuffer.Bytes < totalLen Then Exit Do
		    
		    Dim body As String = ""
		    If remLen > 0 Then body = mRxBuffer.MiddleBytes(headerLen, remLen)
		    If totalLen >= mRxBuffer.Bytes Then
		      mRxBuffer = ""
		    Else
		      mRxBuffer = mRxBuffer.MiddleBytes(totalLen, mRxBuffer.Bytes - totalLen)
		    End If
		    
		    HandlePacket(packetType, pFlags, body)
		  Loop
		End Sub
	#tag EndEvent

	#tag Event
		Sub Error(err As RuntimeException)
		  // The parameter is named err on desktop and e on Android (the framework's names are used there)
		  #If TargetAndroid Then
		    HandleSocketError(e)
		  #Else
		    HandleSocketError(err)
		  #EndIf
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Sub HandleSocketError(err As RuntimeException)
		  StopKeepAlive()
		  Dim wasConnected As Boolean = mConnectedMQTT
		  mConnectedMQTT = False
		  mRxBuffer = ""
		  Dim reason As String = ErrorDescription(err)
		  // Reconnect if wanted, except after a failed TLS handshake (303): that is a configuration problem
		  Dim retry, gaveUp As Boolean
		  If err.ErrorNumber = 303 Then
		    mWantConnected = False
		  Else
		    retry = ScheduleReconnect(gaveUp)
		  End If
		  RaiseEvent SocketError(err)
		  If wasConnected Then RaiseEvent MQTTDisconnected
		  If retry Then RaiseEvent Reconnecting(mReconnectAttempt, mReconnectDelay, reason)
		  If gaveUp Then RaiseEvent ReconnectFailed(reason)
		  If Not retry Then FailPending("not delivered: " + reason)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Connect(host As String, brokerPort As Integer = 1883, clientID As String = "", keepAliveSeconds As Integer = 60, cleanSession As Boolean = True)
		  mHost = host
		  mPort = brokerPort
		  mClientID = clientID
		  If mClientID = "" Then mClientID = "XojoMQTT-" + Str(DateTime.Now.SecondsFrom1970)
		  mKeepAlive = keepAliveSeconds
		  mCleanSession = cleanSession
		  mWantConnected = True
		  mReconnectAttempt = 0
		  mReconnectStarted = 0
		  mReconnectTimer.RunMode = Timer.RunModes.Off
		  DoConnect
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ConnectionLost(reason As String)
		  // The connection is dead without a socket error (keep-alive timeout): close it, then reconnect if wanted
		  StopKeepAlive
		  mConnectedMQTT = False
		  mRxBuffer = ""
		  Me.Close
		  Dim gaveUp As Boolean
		  Dim retry As Boolean = ScheduleReconnect(gaveUp)
		  RaiseEvent Trace("Connection lost: " + reason)
		  RaiseEvent MQTTDisconnected
		  If retry Then RaiseEvent Reconnecting(mReconnectAttempt, mReconnectDelay, reason)
		  If gaveUp Then RaiseEvent ReconnectFailed(reason)
		  If Not retry Then FailPending("not delivered: " + reason)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor()
		  mKeepAlive = 60
		  mCleanSession = True
		  mNextPacketID = 1
		  mRxBuffer = ""
		  mConnectedMQTT = False
		  mPendingQoS2Topic = New Dictionary
		  mPendingQoS2Payload = New Dictionary
		  mPendingQoS2Retain = New Dictionary
		  
		  mPingTimer = New Timer
		  mPingTimer.RunMode = Timer.RunModes.Off
		  mPingTimer.Period = 1000
		  #If TargetAndroid Then
		    AddHandler mPingTimer.Run, AddressOf PingTimerAction
		  #Else
		    AddHandler mPingTimer.Action, AddressOf PingTimerAction
		  #EndIf
		  
		  mTLSType = SSLSocket.SSLConnectionTypes.TLSv12
		  mReconnectMaxDelay = 60
		  mReconnectGiveUp = 900
		  mPendingPubs = New Dictionary
		  mReconnectTimer = New Timer
		  mReconnectTimer.RunMode = Timer.RunModes.Off
		  #If TargetAndroid Then
		    AddHandler mReconnectTimer.Run, AddressOf ReconnectTimerAction
		  #Else
		    AddHandler mReconnectTimer.Action, AddressOf ReconnectTimerAction
		  #EndIf
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DecodeRemainingLength(data As String, startPos As Integer, ByRef bytesUsed As Integer) As Integer
		  Dim multiplier As Integer = 1
		  Dim value As Integer = 0
		  Dim pos As Integer = startPos
		  Do
		    If pos >= data.Bytes Then
		      bytesUsed = 0
		      Return -1
		    End If
		    Dim encodedByte As Integer = data.MiddleBytes(pos, 1).AscByte
		    value = value + (encodedByte And &h7F) * multiplier
		    multiplier = multiplier * 128
		    pos = pos + 1
		    If (encodedByte And &h80) = 0 Then
		      bytesUsed = pos - startPos
		      Return value
		    End If
		  Loop
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Destructor()
		  If mPingTimer <> Nil Then
		    mPingTimer.RunMode = Timer.RunModes.Off
		    #If TargetAndroid Then
		      RemoveHandler mPingTimer.Run, AddressOf PingTimerAction
		    #Else
		      RemoveHandler mPingTimer.Action, AddressOf PingTimerAction
		    #EndIf
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Disconnect()
		  // Closes the connection on purpose: also cancels any pending or running reconnection
		  mWantConnected = False
		  mReconnectTimer.RunMode = Timer.RunModes.Off
		  If mConnectedMQTT Then
		    SendRaw(String.ChrByte(&hE0) + String.ChrByte(0))
		    mConnectedMQTT = False
		  End If
		  StopKeepAlive
		  Me.Close
		  FailPending("not delivered: disconnected before the broker confirmed it")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub DoConnect()
		  // (Re)connects with the stored settings. SSLSocket.Close keeps only the address and port, so TLS is set every time
		  mRxBuffer = ""
		  mConnectedMQTT = False
		  Me.SSLEnabled = mTLSEnabled
		  Me.SSLConnectionType = mTLSType
		  Me.Address = mHost
		  Me.Port = mPort
		  Super.Connect
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EncodeRemainingLength(length As Integer) As String
		  Dim result As String
		  Dim x As Integer = length
		  Do
		    Dim encodedByte As Integer = x Mod 128
		    x = x \ 128
		    If x > 0 Then encodedByte = encodedByte Or &h80
		    result = result + String.ChrByte(encodedByte)
		  Loop Until x = 0
		  Return MeshBin(result)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EncodeString(s As String) As String
		  Dim raw As String = UTF8Bytes(s)
		  Return MeshBin(EncodeUInt16(raw.Bytes) + raw)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function EncodeUInt16(n As Integer) As String
		  // The bytes in variables first: inside a ChrByte argument, Android translates And as a Boolean and
		  Dim hi As Integer = Bitwise.ShiftRight(n, 8) And &hFF
		  Dim lo As Integer = n And &hFF
		  Return MeshBin(String.ChrByte(hi) + String.ChrByte(lo))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ErrorDescription(err As RuntimeException) As String
		  // A readable socket error: Xojo's message, or what the code means when it comes without one
		  Dim message As String = err.Message
		  Select Case err.ErrorNumber
		  Case 303 // undocumented: seen when the TLS handshake fails
		    message = "TLS handshake failed (the server refused the secure connection, or doesn't speak TLS on this port)"
		  Case 49 // macOS EADDRNOTAVAIL: no usable network, e.g. Wi-Fi off
		    If message = "" Then message = "network unavailable"
		  End Select
		  If message = "" Then message = "(no message)"
		  Return "error " + Str(err.ErrorNumber) + ": " + message
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub FailPending(reason As String)
		  // The connection has ended for good: the messages the broker hasn't confirmed won't be delivered
		  If mPendingOrder.Count = 0 Then Return
		  Dim failed() As Integer
		  For Each packetID As Integer In mPendingOrder
		    failed.Add(packetID)
		  Next
		  mPendingOrder.RemoveAll
		  mPendingPubs.RemoveAll
		  For Each failedID As Integer In failed
		    RaiseEvent PublishFailed(failedID, reason)
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub HandleConnAck(body As String)
		  Dim sessionPresent As Boolean = (body.MiddleBytes(0, 1).AscByte And &h01) <> 0
		  Dim returnCode As Integer = body.MiddleBytes(1, 1).AscByte
		  
		  If returnCode = 0 Then
		    mConnectedMQTT = True
		    mReconnectAttempt = 0
		    mReconnectStarted = 0
		    StartKeepAlive
		    ResendPending
		    RaiseEvent MQTTConnected(sessionPresent)
		  Else
		    // Only "server unavailable" (3) is worth retrying: protocol, identity and credential problems (1, 2, 4, 5)
		    // won't go away, and retrying bad credentials can get a client banned
		    Dim retry, gaveUp As Boolean
		    If returnCode = 3 Then
		      retry = ScheduleReconnect(gaveUp)
		    Else
		      mWantConnected = False
		    End If
		    RaiseEvent MQTTConnectionRefused(returnCode)
		    Me.Close
		    If retry Then RaiseEvent Reconnecting(mReconnectAttempt, mReconnectDelay, "server unavailable (code 3)")
		    If gaveUp Then RaiseEvent ReconnectFailed("server unavailable (code 3)")
		    If Not retry Then FailPending("not delivered: the broker refused the connection (code " + Str(returnCode) + ")")
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub HandlePacket(packetType As Integer, pFlags As Integer, body As String)
		  // Until the broker has accepted the connection, only a CONNACK (2 bytes) is valid. Anything else means the
		  // server isn't an MQTT broker (e.g. a web server on that port), so stop instead of misreading its data
		  If Not mConnectedMQTT And (packetType <> 2 Or body.Bytes <> 2) Then
		    RaiseEvent Trace("The server did not answer with an MQTT CONNACK (got packet type " + Str(packetType) + ", " + Str(body.Bytes) + " bytes): is it an MQTT broker? Disconnecting")
		    mRxBuffer = ""
		    Disconnect // final: not worth reconnecting
		    RaiseEvent MQTTDisconnected
		    Return
		  End If
		  Select Case packetType
		  Case 2 // CONNACK
		    HandleConnAck(body)
		  Case 4 // PUBACK (our QoS 1 publishes)
		    HandlePubAck(body)
		  Case 3 // PUBLISH
		    HandlePublish(pFlags, body)
		  Case 6 // PUBREL
		    HandlePubRel(body)
		  Case 9 // SUBACK
		    HandleSubAck(body)
		  Case 11 // UNSUBACK
		    HandleUnsubAck(body)
		  Case 13 // PINGRESP
		    // keepalive acknowledged, nothing to do
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub HandlePubAck(body As String)
		  If body.Bytes < 2 Then Return
		  Dim packetID As Integer = Read16(body, 0)
		  If Not mPendingPubs.HasKey(packetID) Then Return
		  mPendingPubs.Remove(packetID)
		  Dim idx As Integer = mPendingOrder.IndexOf(packetID)
		  If idx >= 0 Then mPendingOrder.RemoveAt(idx)
		  RaiseEvent PublishAcknowledged(packetID)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub HandlePublish(pFlags As Integer, body As String)
		  Dim qos As Integer = Bitwise.ShiftRight(pFlags And &h06, 1)
		  Dim retain As Boolean = (pFlags And &h01) <> 0
		  
		  Dim pos As Integer = 0
		  Dim topicLen As Integer = Read16(body, pos)
		  pos = pos + 2
		  Dim topic As String = MeshUTF8Text(body.MiddleBytes(pos, topicLen))
		  pos = pos + topicLen
		  
		  Dim packetID As Integer = 0
		  If qos > 0 Then
		    packetID = Read16(body, pos)
		    pos = pos + 2
		  End If
		  
		  Dim payloadRaw As String = ""
		  If pos < body.Bytes Then payloadRaw = body.MiddleBytes(pos, body.Bytes - pos)
		  #If TargetAndroid Then
		    // Binary on Android (one byte per character, see MeshBin): MeshUTF8Text(payload) gives the text of a text payload
		    Dim payload As String = payloadRaw
		  #Else
		    Dim payload As String = payloadRaw.DefineEncoding(Encodings.UTF8)
		  #EndIf
		  
		  Select Case qos
		  Case 1
		    RaiseEvent MessageReceived(topic, payload, qos, retain)
		    SendPubAck(packetID)
		  Case 2
		    mPendingQoS2Topic.Value(packetID) = topic
		    mPendingQoS2Payload.Value(packetID) = payload
		    mPendingQoS2Retain.Value(packetID) = retain
		    SendPubRec(packetID)
		  Case Else
		    RaiseEvent MessageReceived(topic, payload, qos, retain)
		  End Select
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub HandlePubRel(body As String)
		  Dim packetID As Integer = Read16(body, 0)
		  If mPendingQoS2Topic.HasKey(packetID) Then
		    RaiseEvent MessageReceived(mPendingQoS2Topic.Value(packetID), mPendingQoS2Payload.Value(packetID), 2, mPendingQoS2Retain.Value(packetID))
		    mPendingQoS2Topic.Remove(packetID)
		    mPendingQoS2Payload.Remove(packetID)
		    mPendingQoS2Retain.Remove(packetID)
		  End If
		  SendPubComp(packetID)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub HandleSubAck(body As String)
		  Dim packetID As Integer = Read16(body, 0)
		  Dim codes() As Integer
		  For i As Integer = 2 To body.Bytes - 1
		    codes.Add(body.MiddleBytes(i, 1).AscByte)
		  Next
		  RaiseEvent Subscribed(packetID, codes)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub HandleUnsubAck(body As String)
		  RaiseEvent Unsubscribed(Read16(body, 0))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsMQTTConnected() As Boolean
		  Return mConnectedMQTT
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsReconnecting() As Boolean
		  // True while waiting for the next reconnection attempt
		  Return mReconnectTimer.RunMode <> Timer.RunModes.Off
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NextPacketID() As Integer
		  Dim id As Integer = mNextPacketID
		  mNextPacketID = mNextPacketID + 1
		  If mNextPacketID > 65535 Then mNextPacketID = 1
		  Return id
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NowSeconds() As Double
		  Return System.Microseconds / 1000000
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function PendingCount() As Integer
		  // QoS 1 messages sent but not yet confirmed by the broker
		  Return mPendingOrder.Count
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub PingTimerAction(sender As Timer)
		  // Keep-alive: a PINGREQ every keep-alive period, and the connection counts as lost when nothing at all
		  // has arrived for 1.5 keep-alive periods (the broker answers every PINGREQ), e.g. a silent network drop
		  If Not mConnectedMQTT Then Return
		  Dim t As Double = NowSeconds()
		  If t - mLastReceived > mKeepAlive * 1.5 Then
		    ConnectionLost("no answer from the broker for " + Str(CType(t - mLastReceived, Integer)) + " s (keep-alive timeout)")
		    Return
		  End If
		  If t - mLastPingSent >= mKeepAlive - 1 Then
		    SendPingReq
		    mLastPingSent = t
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Publish(topic As String, payload As String, retain As Boolean = False)
		  // QoS 0 publish. Skipped (with a Trace) while not connected, instead of writing to a closed socket
		  If Not mConnectedMQTT Then
		    RaiseEvent Trace("Not connected: publish to " + topic + " skipped")
		    Return
		  End If
		  Dim body As String = MeshBin(EncodeString(topic) + UTF8Bytes(payload))
		  Dim firstByte As Integer = &h30
		  If retain Then firstByte = firstByte Or &h01
		  SendRaw(String.ChrByte(firstByte) + EncodeRemainingLength(body.Bytes) + body)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function PublishQoS1(topic As String, payload As String, retain As Boolean = False) As Integer
		  // QoS 1 publish: the broker confirms it with PUBACK (event PublishAcknowledged). Messages not yet confirmed are
		  // sent again (DUP) after a reconnection; when the connection ends for good, PublishFailed is raised for them.
		  // At least once: after a reconnection the broker may receive a message twice. Returns the packet ID, 0 if not sent
		  If Not mConnectedMQTT Then
		    RaiseEvent Trace("Not connected: publish to " + topic + " skipped")
		    Return 0
		  End If
		  Dim packetID As Integer = NextPacketID()
		  Dim guard As Integer = 0
		  While mPendingPubs.HasKey(packetID) And guard < 65535
		    packetID = NextPacketID()
		    guard = guard + 1
		  Wend
		  Dim body As String = MeshBin(EncodeString(topic) + EncodeUInt16(packetID) + UTF8Bytes(payload))
		  Dim firstByte As Integer = &h32
		  If retain Then firstByte = firstByte Or &h01
		  mPendingPubs.Value(packetID) = MeshBin(String.ChrByte(firstByte) + body)
		  mPendingOrder.Add(packetID)
		  SendRaw(String.ChrByte(firstByte) + EncodeRemainingLength(body.Bytes) + body)
		  Return packetID
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Read16(s As String, pos As Integer) As Integer
		  Return s.MiddleBytes(pos, 1).AscByte * 256 + s.MiddleBytes(pos + 1, 1).AscByte
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ReconnectTimerAction(sender As Timer)
		  If Not mWantConnected Then Return
		  RaiseEvent Trace("Reconnecting (attempt " + Str(mReconnectAttempt) + ")")
		  DoConnect
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ResendPending()
		  // After a reconnection: the QoS 1 messages the broker never confirmed go out again, with the DUP flag
		  If mPendingOrder.Count = 0 Then Return
		  RaiseEvent Trace("Resending " + Str(mPendingOrder.Count) + " unconfirmed message(s)")
		  For Each packetID As Integer In mPendingOrder
		    Dim stored As String = MeshBin(mPendingPubs.Value(packetID).StringValue)
		    Dim firstByte As Integer = stored.MiddleBytes(0, 1).AscByte Or &h08
		    Dim body As String = stored.MiddleBytes(1, stored.Bytes - 1)
		    SendRaw(String.ChrByte(firstByte) + EncodeRemainingLength(body.Bytes) + body)
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ScheduleReconnect(ByRef gaveUp As Boolean) As Boolean
		  // Plans the next attempt (back-off with jitter). False when reconnecting is off or not wanted;
		  // gaveUp = True when the give-up time has passed since the connection was first lost
		  gaveUp = False
		  If Not mAutoReconnect Or Not mWantConnected Then Return False
		  Dim t As Double = NowSeconds()
		  If mReconnectStarted = 0 Then mReconnectStarted = t
		  If t - mReconnectStarted > mReconnectGiveUp Then
		    mWantConnected = False
		    gaveUp = True
		    Return False
		  End If
		  mReconnectAttempt = mReconnectAttempt + 1
		  Dim delay As Double = 2 ^ Min(mReconnectAttempt, 10)
		  If delay > mReconnectMaxDelay Then delay = mReconnectMaxDelay
		  delay = delay * (0.8 + 0.4 * System.Random.Number)
		  mReconnectDelay = Max(1, CType(Round(delay), Integer))
		  mReconnectTimer.Period = mReconnectDelay * 1000
		  mReconnectTimer.RunMode = Timer.RunModes.Single
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SendRaw(s As String)
		  // Every write to the socket: on Android the bytes go out one per character only when the String is tagged so (see MeshBin)
		  Me.Write(MeshBin(s))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SendConnectPacket()
		  Dim connectFlags As Integer = 0
		  If mCleanSession Then connectFlags = connectFlags Or &h02
		  If mUsername <> "" Then connectFlags = connectFlags Or &h80
		  If mPassword <> "" Then connectFlags = connectFlags Or &h40
		  
		  Dim variableHeader As String = EncodeString("MQTT") + String.ChrByte(4) + String.ChrByte(connectFlags) + EncodeUInt16(mKeepAlive)
		  Dim payload As String = EncodeString(mClientID)
		  If mUsername <> "" Then payload = payload + EncodeString(mUsername)
		  If mPassword <> "" Then payload = payload + EncodeString(mPassword)
		  
		  Dim body As String = MeshBin(variableHeader + payload)
		  SendRaw(String.ChrByte(&h10) + EncodeRemainingLength(body.Bytes) + body)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SendPingReq()
		  SendRaw(String.ChrByte(&hC0) + String.ChrByte(0))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SendPubAck(packetID As Integer)
		  SendRaw(String.ChrByte(&h40) + String.ChrByte(2) + EncodeUInt16(packetID))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SendPubComp(packetID As Integer)
		  SendRaw(String.ChrByte(&h70) + String.ChrByte(2) + EncodeUInt16(packetID))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SendPubRec(packetID As Integer)
		  SendRaw(String.ChrByte(&h50) + String.ChrByte(2) + EncodeUInt16(packetID))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetAutoReconnect(enabled As Boolean, maxDelaySeconds As Integer = 60, giveUpAfterSeconds As Integer = 900)
		  // Reconnect automatically when the connection is lost (also when the first attempt fails): exponential
		  // back-off 2, 4, 8 ... maxDelaySeconds with +/-20% jitter, giving up after giveUpAfterSeconds without success.
		  // Not after a refused login (except code 3, server unavailable), a failed TLS handshake, or Disconnect
		  mAutoReconnect = enabled
		  mReconnectMaxDelay = Max(2, maxDelaySeconds)
		  mReconnectGiveUp = Max(10, giveUpAfterSeconds)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetCredentials(username As String, password As String)
		  mUsername = username
		  mPassword = password
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetTLS(enabled As Boolean, connectionType As SSLSocket.SSLConnectionTypes = SSLSocket.SSLConnectionTypes.TLSv12)
		  // MQTT over TLS (brokers usually listen on port 8883). Call before Connect.
		  // connectionType: TLSv12 (default), TLSv13, or SSLv23 to negotiate the best version both sides support.
		  // Limitation: Xojo's SSLSocket encrypts the connection but does not verify the broker's certificate
		  // (tested: a self-signed certificate is accepted), so TLS protects against eavesdropping, not impersonation.
		  // The settings are kept here and applied at every (re)connection, since SSLSocket.Close resets them
		  mTLSEnabled = enabled
		  mTLSType = connectionType
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub StartKeepAlive()
		  // The timer ticks every half keep-alive period: PingTimerAction sends PINGREQ and watches for silence
		  If mKeepAlive <= 0 Then Return
		  mLastReceived = NowSeconds()
		  mLastPingSent = mLastReceived
		  mPingTimer.Period = mKeepAlive * 500
		  mPingTimer.RunMode = Timer.RunModes.Multiple
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub StopKeepAlive()
		  mPingTimer.RunMode = Timer.RunModes.Off
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Subscribe(topic As String, qos As Integer = 0) As Integer
		  Dim packetID As Integer = NextPacketID
		  Dim qosBits As Integer = qos And 3 // in a variable: inside a ChrByte argument, Android translates And as a Boolean and
		  Dim payload As String = MeshBin(EncodeUInt16(packetID) + EncodeString(topic) + String.ChrByte(qosBits))
		  SendRaw(String.ChrByte(&h82) + EncodeRemainingLength(payload.Bytes) + payload)
		  Return packetID
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Unsubscribe(topic As String) As Integer
		  Dim packetID As Integer = NextPacketID
		  Dim payload As String = MeshBin(EncodeUInt16(packetID) + EncodeString(topic))
		  SendRaw(String.ChrByte(&hA2) + EncodeRemainingLength(payload.Bytes) + payload)
		  Return packetID
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function UTF8Bytes(s As String) As String
		  #If TargetAndroid Then
		    // Text becomes its UTF-8 bytes, binary (see MeshBin) stays as it is: the MemoryBlock conversion follows the tag
		    If s.Bytes = 0 Then Return ""
		    Dim mb As MemoryBlock = s
		    Return mb.StringValue(0, mb.Size)
		  #EndIf
		  Dim t As String = s
		  If t.Encoding <> Nil And t.Encoding <> Encodings.UTF8 Then
		    t = t.ConvertEncoding(Encodings.UTF8)
		  End If
		  Return t.DefineEncoding(Encodings.UTF8)
		End Function
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event MessageReceived(topic As String, payload As String, qos As Integer, retained As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event MQTTConnected(sessionPresent As Boolean)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event MQTTConnectionRefused(reasonCode As Integer)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event MQTTDisconnected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event PublishAcknowledged(packetID As Integer)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event PublishFailed(packetID As Integer, reason As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event RawDataReceived(data As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event ReconnectFailed(reason As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Reconnecting(attempt As Integer, delaySeconds As Integer, reason As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event SocketError(err As RuntimeException)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Subscribed(packetID As Integer, grantedQoS() As Integer)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Trace(message As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Unsubscribed(packetID As Integer)
	#tag EndHook


	#tag Property, Flags = &h21
		Private mAutoReconnect As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCleanSession As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mClientID As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mConnectedMQTT As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mHost As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mKeepAlive As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastPingSent As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastReceived As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mNextPacketID As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPassword As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPendingOrder() As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPendingPubs As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPendingQoS2Payload As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPendingQoS2Retain As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPendingQoS2Topic As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPingTimer As Timer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPort As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mReconnectAttempt As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mReconnectDelay As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mReconnectGiveUp As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mReconnectMaxDelay As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mReconnectStarted As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mReconnectTimer As Timer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRxBuffer As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTLSEnabled As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTLSType As SSLSocket.SSLConnectionTypes
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mUsername As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mWantConnected As Boolean
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="SSLConnectionType"
			Visible=true
			Group="Behavior"
			InitialValue="5"
			Type="SSLConnectionTypes"
			EditorType="Enum"
			#tag EnumValues
				"1 - SSLv23"
				"3 - TLSv1"
				"4 - TLSv11"
				"5 - TLSv12"
				"6 - TLSv13"
			#tag EndEnumValues
		#tag EndViewProperty
		#tag ViewProperty
			Name="CertificatePassword"
			Visible=true
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="SSLEnabled"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="SSLConnected"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="SSLConnecting"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="BytesAvailable"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="BytesLeftToSend"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="LastErrorCode"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
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
			InitialValue=""
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
			Name="Address"
			Visible=true
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Port"
			Visible=true
			Group="Behavior"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
