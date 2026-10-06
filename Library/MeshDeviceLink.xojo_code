#tag Class
Protected Class MeshDeviceLink
	#tag Method, Flags = &h0
		Sub Close()
		  // MeshDeviceLink: a Meshtastic device over its client API, by TCP (port 4403) or USB serial, the protocol
		  // the Meshtastic apps and the Python CLI use. Packets arrive already decrypted by the device and are passed on
		  // as ServiceEnvelopes, ready for MeshPacketSummary. Part of MQTT_Xojo (GPL-3.0); needs ProtoReader,
		  // ProtoWriter and MeshDecode
		  
		  // Closes the connection on purpose (no LinkClosed event): tells the device the client is leaving
		  If mOpen Then SendToRadio(ProtoFieldVarint(4, 1)) // ToRadio.disconnect
		  Teardown
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Sub ConnectSerial(device As SerialDevice)
		  // Opens the device's USB serial port (115200 baud, 8N1), then asks it for its configuration
		  Close
		  mSerial = New SerialConnection
		  AddHandler mSerial.DataReceived, WeakAddressOf SerialDataReceived
		  AddHandler mSerial.Error, WeakAddressOf SerialError
		  mSerial.Device = device
		  mSerial.Baud = SerialConnection.Baud115200
		  mSerial.DataTerminalReady = True // some USB serial devices only send while DTR is set
		  RaiseEvent LogLine("Opening " + device.Name)
		  Try
		    mSerial.Connect
		  Catch e As RuntimeException
		    Teardown
		    RaiseEvent LinkClosed("can't open " + device.Name + ": " + e.Message)
		    Return
		  End Try
		  LinkUp
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ConnectUSB(deviceName As String = "")
		  // Android: opens a USB serial device through USBSerial (usb-serial-for-android; deviceName as USBSerial.Devices()
		  // lists it, "" = the first one) at 115200 baud, then asks it for its configuration. Without the user's
		  // permission yet, Android asks for it and LinkClosed says so: connect again once allowed. On desktop and
		  // console, use ConnectSerial
		  Close
		  #If TargetAndroid Then
		    Dim name As String = deviceName
		    If name = "" Then
		      Dim found() As String = USBSerial.Devices()
		      If found.Count = 0 Then
		        RaiseEvent LinkClosed("no USB serial device attached")
		        Return
		      End If
		      Dim tab As String = Chr(9)
		      Dim fields() As String = found(0).Split(tab)
		      name = fields(0)
		    End If
		    If Not USBSerial.HasPermission(name) Then
		      Call USBSerial.RequestPermission(name)
		      RaiseEvent LinkClosed("waiting for permission to use the USB device")
		      Return
		    End If
		    Dim port As New USBSerial
		    AddHandler port.DataAvailable, WeakAddressOf USBDataAvailable
		    AddHandler port.Error, WeakAddressOf USBError
		    RaiseEvent LogLine("Opening " + name)
		    If Not port.Open(name, 115200) Then
		      RaiseEvent LinkClosed(port.LastError())
		      Return
		    End If
		    mUSB = port
		    LinkUp
		  #Else
		    #Pragma Unused deviceName
		    RaiseEvent LinkClosed("ConnectUSB is for Android: use ConnectSerial")
		  #EndIf
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ConnectTCP(host As String, port As Integer = 4403)
		  // Connects to the device's TCP API (WiFi or Ethernet nodes listen on port 4403)
		  Close
		  mTCP = New TCPSocket
		  AddHandler mTCP.Connected, WeakAddressOf TCPConnected
		  AddHandler mTCP.DataAvailable, WeakAddressOf TCPDataAvailable
		  AddHandler mTCP.Error, WeakAddressOf TCPError
		  mTCP.Address = host
		  mTCP.Port = port
		  RaiseEvent LogLine("Connecting to " + host + ":" + Str(port))
		  mTCP.Connect
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandleFromRadio(payload As String)
		  // One FromRadio message: 2 packet, 3 my_info, 4 node_info, 6 log_record, 7 config_complete_id, 8 rebooted
		  payload = MeshBin(payload) // one byte per character on Android (see MeshBin)
		  Dim mb As MemoryBlock = payload
		  Dim r As New ProtoReader(mb)
		  Dim field, wireType As Integer
		  While r.ReadTag(field, wireType)
		    Select Case field
		    Case 2
		      If wireType <> 2 Then Return
		      Dim packet As String = r.ReadBytes
		      // Wrapped as a ServiceEnvelope from this node, so MeshPacketSummary decodes it like an MQTT message
		      RaiseEvent PacketReceived(MeshBin(ProtoFieldBytes(1, packet) + ProtoFieldBytes(3, MeshNodeID(mMyNodeNum))))
		    Case 3
		      If wireType <> 2 Then Return
		      Dim myInfo As ProtoReader = r.ReadMessage
		      If myInfo <> Nil Then ParseMyInfo(myInfo) // Nil: malformed or cut short
		    Case 4
		      If wireType <> 2 Then Return
		      Dim nodeInfo As ProtoReader = r.ReadMessage
		      If nodeInfo <> Nil Then ParseNodeInfo(nodeInfo)
		    Case 6
		      If wireType <> 2 Then Return
		      Dim logRecord As ProtoReader = r.ReadMessage
		      If logRecord = Nil Then Return
		      Dim f2, w2 As Integer
		      While logRecord.ReadTag(f2, w2)
		        If f2 = 1 And w2 = 2 Then
		          RaiseEvent LogLine(logRecord.ReadString)
		        Else
		          logRecord.Skip(w2)
		        End If
		      Wend
		    Case 7
		      Dim doneID As UInt64 = r.ReadVarint()
		      If doneID = mConfigNonce And Not mConfigDone Then
		        mConfigDone = True
		        RaiseEvent ConfigComplete
		      End If
		    Case 8
		      Call r.ReadVarint()
		      RaiseEvent LogLine("The device rebooted: asking for its configuration again")
		      RequestConfig
		    Else
		      r.Skip(wireType)
		    End Select
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HeartbeatAction(sender As Timer)
		  // ToRadio.heartbeat (an empty message) keeps the API connection open
		  If mOpen Then SendToRadio(ProtoFieldBytes(7, ""))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsConfigured() As Boolean
		  Return mConfigDone
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsOpen() As Boolean
		  Return mOpen
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LinkUp()
		  mOpen = True
		  mBuffer = ""
		  mText = ""
		  RaiseEvent LinkOpened
		  // Wake the device and take it out of its text console mode, as the Python API does, then ask for everything
		  Dim wake As String
		  For i As Integer = 1 To 32
		    wake = wake + String.ChrByte(kStart2)
		  Next
		  WriteRaw(wake)
		  RequestConfig
		  If mHeartbeat = Nil Then
		    mHeartbeat = New Timer
		    #If TargetAndroid Then
		      AddHandler mHeartbeat.Run, WeakAddressOf HeartbeatAction
		    #Else
		      AddHandler mHeartbeat.Action, WeakAddressOf HeartbeatAction
		    #EndIf
		  End If
		  mHeartbeat.Period = 60000
		  mHeartbeat.RunMode = Timer.RunModes.Multiple
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LongName() As String
		  Return mLongName
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MyNodeID() As String
		  // !aabbccdd
		  Return MeshNodeID(mMyNodeNum)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MyNodeNum() As UInt32
		  Return mMyNodeNum
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeCount() As Integer
		  // The nodes the device sent with its configuration (its NodeDB), the device itself included
		  Return mNodeNums.Count
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeLongNameAt(i As Integer) As String
		  Return mNodeLongNames(i)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeNumAt(i As Integer) As UInt32
		  Return mNodeNums(i)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeShortNameAt(i As Integer) As String
		  Return mNodeShortNames(i)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function RequestPosition(toNode As UInt32) As UInt32
		  // Asks a node for its GPS position through the device: a POSITION_APP packet (portnum 3) with want_response
		  // and an empty Position. A node with a fix answers with its position (the device passes it on through
		  // PacketReceived); one without, or that doesn't share it, answers NO_RESPONSE. Returns the packet id
		  Return SendRequest(toNode, 3, "")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function RequestTelemetry(toNode As UInt32, kind As Integer = 3) As UInt32
		  // Asks a node for its telemetry through the device: a TELEMETRY_APP packet (portnum 67) with want_response,
		  // holding an empty metrics message of the kind wanted (Telemetry field: 2 device, 3 environment, 4 air
		  // quality, 5 power). The device encrypts and sends it; the answer comes back to the device, which decrypts
		  // it and passes it on (PacketReceived). Returns the request's packet id (0 if not connected)
		  Return SendRequest(toNode, 67, ProtoFieldBytes(kind, ""))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SendText(text As String, channelIndex As Integer = 0, hopLimit As Integer = 0, toNode As UInt32 = &hFFFFFFFF) As UInt32
		  // A text message (TEXT_MESSAGE_APP, portnum 1) the device sends as itself: to everyone (toNode &hFFFFFFFF) or one
		  // node, on its channel channelIndex, without ACK. hopLimit 0: only nodes in direct range get it (the firmware keeps
		  // a client's hop_limit 0 when no ACK is asked; such a packet arrives with hop_start 0). Returns the packet id
		  // (0 if not connected)
		  If Not mOpen Then Return 0
		  Dim packetID As UInt32 = MeshNewPacketID()
		  // Data: 1 portnum, 2 payload
		  Dim data As String = MeshBin(ProtoFieldVarint(1, 1) + ProtoFieldBytes(2, text.ConvertEncoding(Encodings.UTF8)))
		  // MeshPacket: 2 to, 3 channel, 4 decoded, 6 id, 9 hop_limit (the device fills in from)
		  Dim packet As String = MeshBin(ProtoFieldFixed32(2, toNode) + ProtoFieldVarint(3, channelIndex) + ProtoFieldBytes(4, data) + _
		  ProtoFieldFixed32(6, packetID) + ProtoFieldVarint(9, hopLimit))
		  SendToRadio(ProtoFieldBytes(1, packet)) // ToRadio.packet
		  Return packetID
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ParseMyInfo(r As ProtoReader)
		  // MyNodeInfo: 1 my_node_num
		  Dim field, wireType As Integer
		  While r.ReadTag(field, wireType)
		    If field = 1 And wireType = 0 Then
		      mMyNodeNum = r.ReadVarint()
		    Else
		      r.Skip(wireType)
		    End If
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ParseNodeInfo(r As ProtoReader)
		  // NodeInfo: 1 num, 2 user (User: 2 long_name, 3 short_name)
		  Dim field, wireType As Integer
		  Dim num As UInt32
		  Dim longName, shortName As String
		  While r.ReadTag(field, wireType)
		    If field = 1 And wireType = 0 Then
		      num = r.ReadVarint()
		    ElseIf field = 2 And wireType = 2 Then
		      Dim user As ProtoReader = r.ReadMessage
		      If user = Nil Then Return // malformed or cut short
		      Dim f2, w2 As Integer
		      While user.ReadTag(f2, w2)
		        If f2 = 2 And w2 = 2 Then
		          longName = user.ReadString
		        ElseIf f2 = 3 And w2 = 2 Then
		          shortName = user.ReadString
		        Else
		          user.Skip(w2)
		        End If
		      Wend
		    Else
		      r.Skip(wireType)
		    End If
		  Wend
		  If num = 0 Then Return
		  If num = mMyNodeNum Then
		    mLongName = longName
		    mShortName = shortName
		  End If
		  // Every node the device knows (its NodeDB), for NodeCount / NodeNumAt / NodeLongNameAt / NodeShortNameAt
		  Dim idx As Integer = mNodeNums.IndexOf(num)
		  If idx < 0 Then
		    mNodeNums.Add num
		    mNodeLongNames.Add longName
		    mNodeShortNames.Add shortName
		  Else
		    mNodeLongNames(idx) = longName
		    mNodeShortNames(idx) = shortName
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Receive(data As String)
		  // The stream: frames 0x94 0xC3 <length, 2 bytes big-endian> <FromRadio>, with the device's text console
		  // output (when it is not in API mode) in between
		  mBuffer = MeshBin(mBuffer + data) // one byte per character on Android (see MeshBin)
		  Do
		    Dim start As Integer = mBuffer.IndexOfBytes(String.ChrByte(kStart1))
		    If start < 0 Then
		      ReceiveText(mBuffer)
		      mBuffer = ""
		      Return
		    End If
		    If start > 0 Then
		      ReceiveText(mBuffer.LeftBytes(start))
		      mBuffer = mBuffer.MiddleBytes(start)
		    End If
		    If mBuffer.Bytes < 4 Then Return // wait for the rest of the header
		    Dim mb As MemoryBlock = mBuffer
		    Dim length As Integer = mb.UInt8Value(2) * 256 + mb.UInt8Value(3)
		    If mb.UInt8Value(1) <> kStart2 Or length > kMaxFrame Then
		      // Not a frame header: skip this byte and look for the next one
		      ReceiveText(mBuffer.LeftBytes(1))
		      mBuffer = mBuffer.MiddleBytes(1)
		      Continue
		    End If
		    If mBuffer.Bytes < 4 + length Then Return // wait for the rest of the frame
		    Dim payload As String = mBuffer.MiddleBytes(4, length)
		    mBuffer = mBuffer.MiddleBytes(4 + length)
		    HandleFromRadio(payload)
		  Loop
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ReceiveText(s As String)
		  // Console text between frames: passed on line by line
		  mText = MeshBin(mText + s)
		  Do
		    Dim nl As Integer = mText.IndexOfBytes(String.ChrByte(10))
		    If nl < 0 Then Exit
		    Dim line As String = mText.LeftBytes(nl).ReplaceAllBytes(String.ChrByte(13), "")
		    mText = mText.MiddleBytes(nl + 1)
		    If line.Trim <> "" Then RaiseEvent LogLine(MeshUTF8Text(line))
		  Loop
		  If mText.Bytes > 4096 Then mText = "" // not text after all
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RequestConfig()
		  // ToRadio.want_config_id: the device answers with my_info, node_info..., config, channels and
		  // config_complete_id = this nonce (69420 and 69421 are special values: avoided)
		  mConfigDone = False
		  mNodeNums.RemoveAll
		  mNodeLongNames.RemoveAll
		  mNodeShortNames.RemoveAll
		  Do
		    mConfigNonce = System.Random.InRange(1, 2147483647)
		  Loop Until mConfigNonce <> 69420 And mConfigNonce <> 69421
		  SendToRadio(ProtoFieldVarint(3, mConfigNonce))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SendRequest(toNode As UInt32, portnum As Integer, payload As String) As UInt32
		  // A packet with want_response to one node, sent through the device (0 if not connected)
		  If Not mOpen Then Return 0
		  Dim packetID As UInt32 = MeshNewPacketID()
		  // Data: 1 portnum, 2 payload, 3 want_response
		  Dim data As String = MeshBin(ProtoFieldVarint(1, portnum) + ProtoFieldBytes(2, payload) + ProtoFieldVarint(3, 1))
		  // MeshPacket: 2 to, 4 decoded, 6 id, 9 hop_limit, 10 want_ack (the device fills in from and the channel)
		  Dim packet As String = MeshBin(ProtoFieldFixed32(2, toNode) + ProtoFieldBytes(4, data) + ProtoFieldFixed32(6, packetID) + _
		  ProtoFieldVarint(9, 3) + ProtoFieldVarint(10, 1))
		  SendToRadio(ProtoFieldBytes(1, packet)) // ToRadio.packet
		  Return packetID
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SendToRadio(payload As String)
		  // One ToRadio message, framed
		  payload = MeshBin(payload)
		  Dim n As Integer = payload.Bytes
		  WriteRaw(String.ChrByte(kStart1) + String.ChrByte(kStart2) + String.ChrByte(n \ 256) + String.ChrByte(n Mod 256) + payload)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Private Sub SerialDataReceived(sender As SerialConnection)
		  Receive(sender.ReadAll)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Private Sub SerialError(sender As SerialConnection, e As RuntimeException)
		  Dim reason As String = "serial error " + Str(e.ErrorNumber) + ": " + e.Message
		  Teardown
		  RaiseEvent LinkClosed(reason)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ShortName() As String
		  Return mShortName
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub TCPConnected(sender As TCPSocket)
		  LinkUp
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub TCPDataAvailable(sender As TCPSocket)
		  Receive(sender.ReadAll)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub TCPError(sender As TCPSocket, err As RuntimeException)
		  // 102: the device closed the connection (reboot, WiFi loss...); 103: name not resolved; others: see TCPSocket
		  Dim reason As String = "TCP error " + Str(err.ErrorNumber)
		  If err.Message <> "" Then reason = reason + ": " + err.Message
		  Teardown
		  RaiseEvent LinkClosed(reason)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Teardown()
		  // Stops everything without raising events
		  mOpen = False
		  mConfigDone = False
		  If mHeartbeat <> Nil Then mHeartbeat.RunMode = Timer.RunModes.Off
		  If mTCP <> Nil Then
		    RemoveHandler mTCP.Connected, WeakAddressOf TCPConnected
		    RemoveHandler mTCP.DataAvailable, WeakAddressOf TCPDataAvailable
		    RemoveHandler mTCP.Error, WeakAddressOf TCPError
		    mTCP.Close
		    mTCP = Nil
		  End If
		  If mUSB <> Nil Then
		    RemoveHandler mUSB.DataAvailable, WeakAddressOf USBDataAvailable
		    RemoveHandler mUSB.Error, WeakAddressOf USBError
		    mUSB.Close()
		    mUSB = Nil
		  End If
		  #If Not TargetAndroid Then
		    If mSerial <> Nil Then
		      RemoveHandler mSerial.DataReceived, WeakAddressOf SerialDataReceived
		      RemoveHandler mSerial.Error, WeakAddressOf SerialError
		      mSerial.Close
		      mSerial = Nil
		    End If
		  #EndIf
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub USBDataAvailable(sender As USBSerial, data As String)
		  #Pragma Unused sender
		  Receive(data)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub USBError(sender As USBSerial, message As String)
		  // Usually the device unplugged
		  #Pragma Unused sender
		  Teardown
		  RaiseEvent LinkClosed("USB: " + message)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub WriteRaw(s As String)
		  s = MeshBin(s) // on Android the bytes go out one per character only when the String is tagged so (see MeshBin)
		  If mTCP <> Nil Then
		    mTCP.Write(s)
		    Return
		  End If
		  If mUSB <> Nil Then
		    Call mUSB.Write(s)
		    Return
		  End If
		  #If Not TargetAndroid Then
		    If mSerial <> Nil Then mSerial.Write(s)
		  #EndIf
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event ConfigComplete()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event LinkClosed(reason As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event LinkOpened()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event LogLine(text As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event PacketReceived(envelope As String)
	#tag EndHook


	#tag Property, Flags = &h21
		Private mBuffer As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mConfigDone As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mConfigNonce As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mHeartbeat As Timer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLongName As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mMyNodeNum As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mNodeLongNames() As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mNodeNums() As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mNodeShortNames() As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mOpen As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21, CompatibilityFlags = (TargetConsole and (Target32Bit or Target64Bit)) or  (TargetDesktop and (Target32Bit or Target64Bit))
		Private mSerial As SerialConnection
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mShortName As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTCP As TCPSocket
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mUSB As USBSerial
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mText As String
	#tag EndProperty


	#tag Constant, Name = kMaxFrame, Type = Double, Dynamic = False, Default = \"512", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kStart1, Type = Double, Dynamic = False, Default = \"148", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kStart2, Type = Double, Dynamic = False, Default = \"195", Scope = Private
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
