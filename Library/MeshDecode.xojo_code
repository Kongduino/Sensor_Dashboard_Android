#tag Module
Protected Module MeshDecode
	#tag Method, Flags = &h0
		Function MeshDisplayFloat(v As Single) As String
		  // A protobuf float for the summary line: the shortest digits that read back to the same Single
		  // ("4.05", "61.2", "1e-05", "123456.7"), whole numbers without ".0", zero (also -0) as "0"
		  If v = 0 Then Return "0"
		  Dim d As Double = v
		  If d.IsNotANumber Or d.IsInfinite Then Return d.ToString(Locale.Raw)
		  Dim best As String
		  Dim bestExp As Integer
		  Dim negative As Boolean
		  If Not MeshShortestDigits(d, True, best, bestExp, negative) Then Return d.ToString(Locale.Raw)
		  Dim result As String = MeshReprFormat(best, bestExp, negative)
		  If result.EndsWith(".0") Then result = result.Left(result.Length - 2)
		  Return result
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshHardwareName(model As Integer) As String
		  // Generated from HardwareModel in mesh.proto (116 entries)
		  Select Case model
		  Case 0
		    Return "UNSET"
		  Case 1
		    Return "TLORA_V2"
		  Case 2
		    Return "TLORA_V1"
		  Case 3
		    Return "TLORA_V2_1_1P6"
		  Case 4
		    Return "TBEAM"
		  Case 5
		    Return "HELTEC_V2_0"
		  Case 6
		    Return "TBEAM_V0P7"
		  Case 7
		    Return "T_ECHO"
		  Case 8
		    Return "TLORA_V1_1P3"
		  Case 9
		    Return "RAK4631"
		  Case 10
		    Return "HELTEC_V2_1"
		  Case 11
		    Return "HELTEC_V1"
		  Case 12
		    Return "LILYGO_TBEAM_S3_CORE"
		  Case 13
		    Return "RAK11200"
		  Case 14
		    Return "NANO_G1"
		  Case 15
		    Return "TLORA_V2_1_1P8"
		  Case 16
		    Return "TLORA_T3_S3"
		  Case 17
		    Return "NANO_G1_EXPLORER"
		  Case 18
		    Return "NANO_G2_ULTRA"
		  Case 19
		    Return "LORA_TYPE"
		  Case 20
		    Return "WIPHONE"
		  Case 21
		    Return "WIO_WM1110"
		  Case 22
		    Return "RAK2560"
		  Case 23
		    Return "HELTEC_HRU_3601"
		  Case 24
		    Return "HELTEC_WIRELESS_BRIDGE"
		  Case 25
		    Return "STATION_G1"
		  Case 26
		    Return "RAK11310"
		  Case 27
		    Return "SENSELORA_RP2040"
		  Case 28
		    Return "SENSELORA_S3"
		  Case 29
		    Return "CANARYONE"
		  Case 30
		    Return "RP2040_LORA"
		  Case 31
		    Return "STATION_G2"
		  Case 32
		    Return "LORA_RELAY_V1"
		  Case 33
		    Return "NRF52840DK"
		  Case 34
		    Return "PPR"
		  Case 35
		    Return "GENIEBLOCKS"
		  Case 36
		    Return "NRF52_UNKNOWN"
		  Case 37
		    Return "PORTDUINO"
		  Case 38
		    Return "ANDROID_SIM"
		  Case 39
		    Return "DIY_V1"
		  Case 40
		    Return "NRF52840_PCA10059"
		  Case 41
		    Return "DR_DEV"
		  Case 42
		    Return "M5STACK"
		  Case 43
		    Return "HELTEC_V3"
		  Case 44
		    Return "HELTEC_WSL_V3"
		  Case 45
		    Return "BETAFPV_2400_TX"
		  Case 46
		    Return "BETAFPV_900_NANO_TX"
		  Case 47
		    Return "RPI_PICO"
		  Case 48
		    Return "HELTEC_WIRELESS_TRACKER"
		  Case 49
		    Return "HELTEC_WIRELESS_PAPER"
		  Case 50
		    Return "T_DECK"
		  Case 51
		    Return "T_WATCH_S3"
		  Case 52
		    Return "PICOMPUTER_S3"
		  Case 53
		    Return "HELTEC_HT62"
		  Case 54
		    Return "EBYTE_ESP32_S3"
		  Case 55
		    Return "ESP32_S3_PICO"
		  Case 56
		    Return "CHATTER_2"
		  Case 57
		    Return "HELTEC_WIRELESS_PAPER_V1_0"
		  Case 58
		    Return "HELTEC_WIRELESS_TRACKER_V1_0"
		  Case 59
		    Return "UNPHONE"
		  Case 60
		    Return "TD_LORAC"
		  Case 61
		    Return "CDEBYTE_EORA_S3"
		  Case 62
		    Return "TWC_MESH_V4"
		  Case 63
		    Return "NRF52_PROMICRO_DIY"
		  Case 64
		    Return "RADIOMASTER_900_BANDIT_NANO"
		  Case 65
		    Return "HELTEC_CAPSULE_SENSOR_V3"
		  Case 66
		    Return "HELTEC_VISION_MASTER_T190"
		  Case 67
		    Return "HELTEC_VISION_MASTER_E213"
		  Case 68
		    Return "HELTEC_VISION_MASTER_E290"
		  Case 69
		    Return "HELTEC_MESH_NODE_T114"
		  Case 70
		    Return "SENSECAP_INDICATOR"
		  Case 71
		    Return "TRACKER_T1000_E"
		  Case 72
		    Return "RAK3172"
		  Case 73
		    Return "WIO_E5"
		  Case 74
		    Return "RADIOMASTER_900_BANDIT"
		  Case 75
		    Return "ME25LS01_4Y10TD"
		  Case 76
		    Return "RP2040_FEATHER_RFM95"
		  Case 77
		    Return "M5STACK_COREBASIC"
		  Case 78
		    Return "M5STACK_CORE2"
		  Case 79
		    Return "RPI_PICO2"
		  Case 80
		    Return "M5STACK_CORES3"
		  Case 81
		    Return "SEEED_XIAO_S3"
		  Case 82
		    Return "MS24SF1"
		  Case 83
		    Return "TLORA_C6"
		  Case 84
		    Return "WISMESH_TAP"
		  Case 85
		    Return "ROUTASTIC"
		  Case 86
		    Return "MESH_TAB"
		  Case 87
		    Return "MESHLINK"
		  Case 88
		    Return "XIAO_NRF52_KIT"
		  Case 89
		    Return "THINKNODE_M1"
		  Case 90
		    Return "THINKNODE_M2"
		  Case 91
		    Return "T_ETH_ELITE"
		  Case 92
		    Return "HELTEC_SENSOR_HUB"
		  Case 93
		    Return "RESERVED_FRIED_CHICKEN"
		  Case 94
		    Return "HELTEC_MESH_POCKET"
		  Case 95
		    Return "SEEED_SOLAR_NODE"
		  Case 96
		    Return "NOMADSTAR_METEOR_PRO"
		  Case 97
		    Return "CROWPANEL"
		  Case 98
		    Return "LINK_32"
		  Case 99
		    Return "SEEED_WIO_TRACKER_L1"
		  Case 100
		    Return "SEEED_WIO_TRACKER_L1_EINK"
		  Case 101
		    Return "MUZI_R1_NEO"
		  Case 102
		    Return "T_DECK_PRO"
		  Case 103
		    Return "T_LORA_PAGER"
		  Case 104
		    Return "M5STACK_RESERVED"
		  Case 105
		    Return "WISMESH_TAG"
		  Case 106
		    Return "RAK3312"
		  Case 107
		    Return "THINKNODE_M5"
		  Case 108
		    Return "HELTEC_MESH_SOLAR"
		  Case 109
		    Return "T_ECHO_LITE"
		  Case 110
		    Return "HELTEC_V4"
		  Case 111
		    Return "M5STACK_C6L"
		  Case 112
		    Return "M5STACK_CARDPUTER_ADV"
		  Case 113
		    Return "HELTEC_WIRELESS_TRACKER_V2"
		  Case 114
		    Return "T_WATCH_ULTRA"
		  Case 255
		    Return "PRIVATE_HW"
		  Else
		    Return model.ToString
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshHardwareSummary(payload As String) As String
		  // REMOTE_HARDWARE_APP: HardwareMessage {1 type, 2 gpio_mask, 3 gpio_value (uint64)}
		  Dim mb As MemoryBlock = payload
		  Dim r As New ProtoReader(mb)
		  Dim field, wireType As Integer
		  Dim msgType As Integer
		  Dim mask, gpioValue As UInt64
		  While r.ReadTag(field, wireType)
		    If field >= 1 And field <= 3 And wireType = 0 Then
		      Dim v As UInt64 = r.ReadVarint()
		      If field = 1 Then
		        msgType = CType(v, Integer)
		      ElseIf field = 2 Then
		        mask = v
		      Else
		        gpioValue = v
		      End If
		    Else
		      r.Skip(wireType)
		    End If
		  Wend
		  If r.Failed Then Return "(bad remote hardware)"
		  Dim typeName As String
		  Select Case msgType
		  Case 1
		    typeName = "WRITE_GPIOS"
		  Case 2
		    typeName = "WATCH_GPIOS"
		  Case 3
		    typeName = "GPIOS_CHANGED"
		  Case 4
		    typeName = "READ_GPIOS"
		  Case 5
		    typeName = "READ_GPIOS_REPLY"
		  Else
		    typeName = "UNSET"
		  End Select
		  Return typeName + ", mask &h" + Hex(mask) + ", value &h" + Hex(gpioValue)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshHexID(num As UInt32) As String
		  // !aabbccdd, as the converter writes node ids in JSON (no ^all)
		  Dim s As String = "0000000" + Hex(num)
		  s = s.RightBytes(8).Lowercase
		  Return "!" + s
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshMetricsSummary(r As ProtoReader, spec As String) As String
		  // Decodes a metrics message using a MeshTelemetrySpec table. Fields not in the table are skipped
		  If r = Nil Then Return "(bad metrics)"
		  Dim entries() As String = spec.Split(",")
		  Dim parts() As String
		  Dim field, wireType As Integer
		  Dim name, kind As String
		  While r.ReadTag(field, wireType)
		    name = ""
		    kind = ""
		    For Each entry As String In entries
		      Dim cols() As String = entry.Split(":")
		      If cols(0).ToInteger() = field Then
		        name = cols(1)
		        kind = cols(2)
		        Exit For
		      End If
		    Next
		    Select Case kind
		    Case "f"
		      If wireType <> 5 Then Return "(bad metrics)"
		      Dim v As Single = r.ReadFloat
		      parts.Add(name + " " + MeshDisplayFloat(v))
		    Case "u", "c"
		      If wireType <> 0 Then Return "(bad metrics)"
		      Dim n As UInt64 = r.ReadVarint()
		      If kind = "c" Then
		        Dim hundredths As Double = n / 100
		        parts.Add(name + " " + hundredths.ToString(Locale.Raw, "0.##"))
		      Else
		        parts.Add(name + " " + n.ToString)
		      End If
		    Case "s"
		      If wireType <> 2 Then Return "(bad metrics)"
		      Dim s As String = r.ReadString
		      parts.Add(name + " """ + s + """")
		    Else
		      r.Skip(wireType)
		    End Select
		  Wend
		  If r.Failed Then Return "(bad metrics)"
		  If parts.Count = 0 Then Return "(no values)"
		  Return String.FromArray(parts, ", ")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshNeighborInfoSummary(payload As String) As String
		  // NEIGHBORINFO_APP: NeighborInfo with repeated Neighbor {1 node_id, 2 snr (float)}
		  Dim mb As MemoryBlock = payload
		  Dim r As New ProtoReader(mb)
		  Dim field, wireType As Integer
		  Dim nodeID, lastSentBy, interval As UInt32
		  Dim neighbors() As String
		  While r.ReadTag(field, wireType)
		    Select Case field
		    Case 1, 2, 3 // node_id, last_sent_by_id, node_broadcast_interval_secs
		      If wireType <> 0 Then Return "(bad neighborinfo)"
		      Dim v As UInt32 = CType(r.ReadVarint(), UInt32)
		      If field = 1 Then
		        nodeID = v
		      ElseIf field = 2 Then
		        lastSentBy = v
		      Else
		        interval = v
		      End If
		    Case 4 // neighbors
		      If wireType <> 2 Then Return "(bad neighborinfo)"
		      Dim n As ProtoReader = r.ReadMessage
		      If n = Nil Then Return "(bad neighborinfo)"
		      Dim neighborID As UInt32
		      Dim snr As Single
		      Dim nField, nWireType As Integer
		      While n.ReadTag(nField, nWireType)
		        If nField = 1 And nWireType = 0 Then
		          neighborID = CType(n.ReadVarint(), UInt32)
		        ElseIf nField = 2 And nWireType = 5 Then
		          snr = n.ReadFloat
		        Else
		          n.Skip(nWireType)
		        End If
		      Wend
		      If n.Failed Then Return "(bad neighborinfo)"
		      neighbors.Add(MeshNodeID(neighborID) + " SNR " + MeshDisplayFloat(snr))
		    Else
		      r.Skip(wireType)
		    End Select
		  Wend
		  If r.Failed Then Return "(bad neighborinfo)"
		  
		  Dim result As String = "node " + MeshNodeID(nodeID)
		  If lastSentBy > 0 And lastSentBy <> nodeID Then result = result + " (sent by " + MeshNodeID(lastSentBy) + ")"
		  result = result + ", " + neighbors.Count.ToString + " neighbors"
		  If neighbors.Count > 0 Then result = result + ": " + String.FromArray(neighbors, ", ")
		  If interval > 0 Then result = result + ", every " + interval.ToString + " s"
		  Return result
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshNodeID(num As UInt32) As String
		  // Meshtastic node id notation: !aabbccdd, ^all for broadcast
		  If num = 4294967295 Then Return "^all"
		  Dim s As String = "0000000" + Hex(num)
		  s = s.RightBytes(8).Lowercase
		  Return "!" + s
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPacketSummary(payload As String, ByRef jsonText As String, ByRef packetKey As String) As String
		  // Decodes a ServiceEnvelope (msh/.../2/e/...) into one line:
		  // from -> to  port N NAME (decrypting with the configured channel keys if needed)  [channel via gateway]  contents
		  // jsonText receives the JSON mqtt-converter would publish for it ("" if none), packetKey "sender:id"
		  // for duplicate detection ("" when id is 0). Returns "" if the payload is not a ServiceEnvelope
		  jsonText = ""
		  packetKey = ""
		  mRoutingValid = False
		  mAckRequestValid = False
		  payload = MeshBin(payload) // one byte per character on Android (see MeshBin)
		  If payload.Bytes = 0 Then Return ""
		  Dim mb As MemoryBlock = payload
		  Dim env As New ProtoReader(mb)
		  Dim field, wireType As Integer
		  Dim packet As ProtoReader
		  Dim channelID, gatewayID As String
		  
		  // ServiceEnvelope: 1 packet, 2 channel_id, 3 gateway_id
		  While env.ReadTag(field, wireType)
		    Select Case field
		    Case 1
		      If wireType <> 2 Then Return ""
		      packet = env.ReadMessage
		    Case 2
		      If wireType <> 2 Then Return ""
		      channelID = env.ReadString
		    Case 3
		      If wireType <> 2 Then Return ""
		      gatewayID = env.ReadString
		    Else
		      env.Skip(wireType)
		    End Select
		  Wend
		  If env.Failed Or packet = Nil Then Return ""
		  
		  // MeshPacket: 1 from, 2 to, 6 id, 7 rx_time (fixed32), 3 channel, 9 hop_limit, 15 hop_start (varint),
		  // 8 rx_snr (float), 12 rx_rssi (int32), 4 decoded (Data), 5 encrypted (bytes)
		  Dim fromNode, toNode, packetID As UInt32
		  Dim channel, rxTime, hopLimit, hopStart As UInt32
		  Dim rxSnr As Single
		  Dim rxRssi As Int32
		  Dim pkiEncrypted As Boolean
		  Dim wantAck As Boolean
		  Dim portnum As Integer = -1
		  Dim dataPayload As String
		  Dim requestID As UInt32
		  Dim encrypted As String
		  Dim hasEncrypted As Boolean
		  While packet.ReadTag(field, wireType)
		    Select Case field
		    Case 1
		      If wireType <> 5 Then Return ""
		      fromNode = packet.ReadFixed32
		    Case 2
		      If wireType <> 5 Then Return ""
		      toNode = packet.ReadFixed32
		    Case 4
		      If wireType <> 2 Then Return ""
		      If Not MeshParseData(packet.ReadMessage, portnum, dataPayload, requestID) Then Return ""
		    Case 5
		      If wireType <> 2 Then Return ""
		      encrypted = packet.ReadBytes()
		      hasEncrypted = True
		    Case 6
		      If wireType <> 5 Then Return ""
		      packetID = packet.ReadFixed32
		    Case 7
		      If wireType <> 5 Then Return ""
		      rxTime = packet.ReadFixed32
		    Case 8
		      If wireType <> 5 Then Return ""
		      rxSnr = packet.ReadFloat
		    Case 3, 9, 15
		      If wireType <> 0 Then Return ""
		      Dim v As UInt32 = CType(packet.ReadVarint(), UInt32)
		      If field = 3 Then
		        channel = v
		      ElseIf field = 9 Then
		        hopLimit = v
		      Else
		        hopStart = v
		      End If
		    Case 12
		      If wireType <> 0 Then Return ""
		      rxRssi = packet.ReadInt32
		    Case 17 // pki_encrypted
		      If wireType <> 0 Then Return ""
		      pkiEncrypted = (packet.ReadVarint() <> 0)
		    Case 10 // want_ack
		      If wireType <> 0 Then Return ""
		      wantAck = (packet.ReadVarint() <> 0)
		    Else
		      packet.Skip(wireType)
		    End Select
		  Wend
		  If packet.Failed Then Return ""
		  
		  // Encrypted: try the configured channel keys (see MeshAddChannel)
		  Dim decrypted As Boolean
		  Dim keyName As String
		  Dim pkiDecrypted As Boolean
		  If portnum < 0 And hasEncrypted And MeshPKIReady() And (toNode = MeshPKINodeNum() Or fromNode = MeshPKINodeNum()) And (pkiEncrypted Or MeshSameText(channelID, "PKI")) Then
		    // A PKI direct message to or from our own node: the shared key is the same from both ends,
		    // so it decrypts with our private key and the other node's public key
		    Dim senderKey As String
		    If toNode = MeshPKINodeNum() Then
		      senderKey = MeshPublicKeyFor(fromNode)
		    Else
		      senderKey = MeshPublicKeyFor(toNode)
		    End If
		    Dim pkiPlain As String
		    If senderKey.Bytes = 32 And MeshPKIOpen(senderKey, packetID, fromNode, encrypted, pkiPlain) Then
		      Dim pkiMB As MemoryBlock = pkiPlain
		      Dim pkiPort As Integer
		      Dim pkiPayload As String
		      Dim pkiRequestID As UInt32
		      If MeshParseData(New ProtoReader(pkiMB), pkiPort, pkiPayload, pkiRequestID) And pkiPort > 0 Then
		        portnum = pkiPort
		        dataPayload = pkiPayload
		        requestID = pkiRequestID
		        pkiDecrypted = True
		      End If
		    End If
		  End If
		  If portnum < 0 And hasEncrypted Then
		    decrypted = MeshDecryptPacket(channelID, channel, packetID, fromNode, encrypted, portnum, dataPayload, requestID, keyName)
		  End If
		  If portnum = 4 Then MeshLearnPublicKey(fromNode, dataPayload)
		  
		  Dim line As String = MeshNodeID(fromNode) + " -> " + MeshNodeID(toNode) + "  "
		  If portnum >= 0 Then
		    line = line + "port " + portnum.ToString + " " + MeshPortName(portnum)
		    If pkiDecrypted Then line = line + " (PKI direct message, decrypted)"
		    If decrypted Then
		      If MeshSameText(keyName, channelID) Then
		        line = line + " (decrypted)"
		      Else
		        line = line + " (decrypted with " + keyName + ")"
		      End If
		    End If
		  ElseIf hasEncrypted And (pkiEncrypted Or MeshSameText(channelID, "PKI")) Then
		    line = line + "PKI direct message (" + encrypted.Bytes.ToString + " bytes, needs the recipient's private key)"
		  ElseIf hasEncrypted Then
		    line = line + "encrypted (" + encrypted.Bytes.ToString + " bytes, channel hash " + channel.ToString + ", no matching key)"
		  Else
		    line = line + "no payload"
		  End If
		  If gatewayID <> "" Then
		    line = line + "  [" + channelID + " via " + gatewayID + "]"
		  Else
		    line = line + "  [" + channelID + "]"
		  End If
		  If portnum >= 0 Then
		    Dim contents As String = MeshPayloadSummary(portnum, dataPayload, fromNode, toNode, requestID)
		    If contents <> "" Then line = line + "  " + contents
		    // PKI direct messages are private: shown, but not republished as JSON
		    If Not pkiDecrypted Then jsonText = MeshPacketJSON(packetID, fromNode, toNode, channel, rxTime, rxSnr, rxRssi, hopLimit, hopStart, gatewayID, portnum, dataPayload, requestID)
		  End If
		  If packetID <> 0 Then packetKey = fromNode.ToString + ":" + packetID.ToString
		  // Remembered for the app (MeshTakeRouting / MeshTakeAckRequest): a ROUTING answer to one of our messages,
		  // and a message to our node that asks for an ACK
		  mRoutingValid = False
		  mAckRequestValid = False
		  If portnum = 5 And requestID <> 0 Then
		    Dim routingMB As MemoryBlock = ProtoRawBytes(dataPayload)
		    If routingMB <> Nil Then
		      Dim routingReader As New ProtoReader(routingMB)
		      Dim routingField, routingWire As Integer
		      Dim routingCode As Integer = -1
		      While routingReader.ReadTag(routingField, routingWire)
		        If routingField = 3 And routingWire = 0 Then
		          routingCode = CType(routingReader.ReadVarint(), Integer)
		        Else
		          routingReader.Skip(routingWire)
		        End If
		      Wend
		      If routingCode >= 0 And Not routingReader.Failed Then
		        mRoutingValid = True
		        mRoutingRequestID = requestID
		        mRoutingFrom = fromNode
		        mRoutingTo = toNode
		        mRoutingError = routingCode
		      End If
		    End If
		  End If
		  If wantAck And portnum >= 0 And portnum <> 5 And toNode <> 4294967295 And toNode = MeshPKINodeNum() Then
		    mAckRequestValid = True
		    mAckRequestFrom = fromNode
		    mAckRequestID = packetID
		    If decrypted Then
		      mAckRequestChannel = keyName
		    Else
		      mAckRequestChannel = "" // PKI or decoded: the app answers on its primary channel
		    End If
		  End If
		  Return line
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshParseData(data As ProtoReader, ByRef portnum As Integer, ByRef payload As String, ByRef requestID As UInt32) As Boolean
		  // Data: 1 portnum (absent means 0), 2 payload, 6 request_id. False if malformed
		  portnum = 0
		  payload = ""
		  requestID = 0
		  If data = Nil Then Return False
		  Dim field, wireType As Integer
		  While data.ReadTag(field, wireType)
		    If field = 1 And wireType = 0 Then
		      portnum = CType(data.ReadVarint(), Integer)
		    ElseIf field = 2 And wireType = 2 Then
		      payload = data.ReadBytes()
		    ElseIf field = 6 And wireType = 5 Then
		      requestID = data.ReadFixed32()
		    Else
		      data.Skip(wireType)
		    End If
		  Wend
		  Return (Not data.Failed) And (portnum >= 0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPaxcountSummary(payload As String) As String
		  // PAXCOUNTER_APP: Paxcount {1 wifi, 2 ble, 3 uptime}
		  Dim mb As MemoryBlock = payload
		  Dim r As New ProtoReader(mb)
		  Dim field, wireType As Integer
		  Dim wifi, ble, uptime As UInt32
		  While r.ReadTag(field, wireType)
		    If field >= 1 And field <= 3 And wireType = 0 Then
		      Dim v As UInt32 = CType(r.ReadVarint(), UInt32)
		      If field = 1 Then
		        wifi = v
		      ElseIf field = 2 Then
		        ble = v
		      Else
		        uptime = v
		      End If
		    Else
		      r.Skip(wireType)
		    End If
		  Wend
		  If r.Failed Then Return "(bad paxcount)"
		  Return "wifi " + wifi.ToString + ", ble " + ble.ToString + ", uptime " + uptime.ToString + " s"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPayloadSummary(portnum As Integer, payload As String, fromNode As UInt32, toNode As UInt32, requestID As UInt32) As String
		  // Decoded contents of a Data payload, "" for port numbers not handled
		  Select Case portnum
		  Case 1, 10 // TEXT_MESSAGE_APP, DETECTION_SENSOR_APP
		    Return MeshTextSummary(payload)
		  Case 2
		    Return MeshHardwareSummary(payload)
		  Case 8
		    Return MeshWaypointSummary(payload)
		  Case 34
		    Return MeshPaxcountSummary(payload)
		  Case 70
		    Return MeshTracerouteSummary(payload, fromNode, toNode, requestID)
		  Case 71
		    Return MeshNeighborInfoSummary(payload)
		  Case 5
		    Return MeshRoutingSummary(payload, requestID)
		  Case 3
		    Return MeshPositionSummary(payload)
		  Case 4
		    Return MeshUserSummary(payload)
		  Case 67
		    Return MeshTelemetrySummary(payload)
		  Else
		    Return ""
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPortName(portnum As Integer) As String
		  Select Case portnum
		  Case 0
		    Return "UNKNOWN_APP"
		  Case 1
		    Return "TEXT_MESSAGE_APP"
		  Case 2
		    Return "REMOTE_HARDWARE_APP"
		  Case 3
		    Return "POSITION_APP"
		  Case 4
		    Return "NODEINFO_APP"
		  Case 5
		    Return "ROUTING_APP"
		  Case 6
		    Return "ADMIN_APP"
		  Case 7
		    Return "TEXT_MESSAGE_COMPRESSED_APP"
		  Case 8
		    Return "WAYPOINT_APP"
		  Case 9
		    Return "AUDIO_APP"
		  Case 10
		    Return "DETECTION_SENSOR_APP"
		  Case 11
		    Return "ALERT_APP"
		  Case 12
		    Return "KEY_VERIFICATION_APP"
		  Case 32
		    Return "REPLY_APP"
		  Case 33
		    Return "IP_TUNNEL_APP"
		  Case 34
		    Return "PAXCOUNTER_APP"
		  Case 64
		    Return "SERIAL_APP"
		  Case 65
		    Return "STORE_FORWARD_APP"
		  Case 66
		    Return "RANGE_TEST_APP"
		  Case 67
		    Return "TELEMETRY_APP"
		  Case 68
		    Return "ZPS_APP"
		  Case 69
		    Return "SIMULATOR_APP"
		  Case 70
		    Return "TRACEROUTE_APP"
		  Case 71
		    Return "NEIGHBORINFO_APP"
		  Case 72
		    Return "ATAK_PLUGIN"
		  Case 73
		    Return "MAP_REPORT_APP"
		  Case 74
		    Return "POWERSTRESS_APP"
		  Case 76
		    Return "RETICULUM_TUNNEL_APP"
		  Case 77
		    Return "CAYENNE_APP"
		  Case 256
		    Return "PRIVATE_APP"
		  Case 257
		    Return "ATAK_FORWARDER"
		  Else
		    Return "?"
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPositionSummary(payload As String) As String
		  // POSITION_APP: Position message
		  Dim mb As MemoryBlock = payload
		  Dim r As New ProtoReader(mb)
		  Dim field, wireType As Integer
		  Dim lat, lon, alt As Int32
		  Dim hasLat, hasLon, hasAlt As Boolean
		  Dim posTime, sats, precision As UInt32
		  While r.ReadTag(field, wireType)
		    Select Case field
		    Case 1 // latitude_i, sfixed32, 1e-7 degrees
		      If wireType <> 5 Then Return "(bad position)"
		      lat = r.ReadSFixed32
		      hasLat = True
		    Case 2 // longitude_i
		      If wireType <> 5 Then Return "(bad position)"
		      lon = r.ReadSFixed32
		      hasLon = True
		    Case 3 // altitude, int32, meters
		      If wireType <> 0 Then Return "(bad position)"
		      alt = r.ReadInt32
		      hasAlt = True
		    Case 4 // time, fixed32
		      If wireType <> 5 Then Return "(bad position)"
		      posTime = r.ReadFixed32
		    Case 19 // sats_in_view
		      If wireType <> 0 Then Return "(bad position)"
		      sats = CType(r.ReadVarint(), UInt32)
		    Case 23 // precision_bits
		      If wireType <> 0 Then Return "(bad position)"
		      precision = CType(r.ReadVarint(), UInt32)
		    Else
		      r.Skip(wireType)
		    End Select
		  Wend
		  If r.Failed Then Return "(bad position)"
		  
		  Dim parts() As String
		  If hasLat And hasLon Then
		    Dim latDeg As Double = lat / 10000000.0
		    Dim lonDeg As Double = lon / 10000000.0
		    parts.Add("lat " + latDeg.ToString(Locale.Raw, "0.0000000"))
		    parts.Add("lon " + lonDeg.ToString(Locale.Raw, "0.0000000"))
		  Else
		    parts.Add("no fix")
		  End If
		  If hasAlt Then parts.Add("alt " + alt.ToString + " m")
		  If sats > 0 Then parts.Add(sats.ToString + " sats")
		  If precision > 0 Then parts.Add("precision " + precision.ToString + " bits")
		  If posTime > 0 Then parts.Add(MeshTimeString(posTime))
		  Return String.FromArray(parts, ", ")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshRoleName(role As Integer) As String
		  // Config.DeviceConfig.Role in config.proto
		  Select Case role
		  Case 0
		    Return "CLIENT"
		  Case 1
		    Return "CLIENT_MUTE"
		  Case 2
		    Return "ROUTER"
		  Case 3
		    Return "ROUTER_CLIENT"
		  Case 4
		    Return "REPEATER"
		  Case 5
		    Return "TRACKER"
		  Case 6
		    Return "SENSOR"
		  Case 7
		    Return "TAK"
		  Case 8
		    Return "CLIENT_HIDDEN"
		  Case 9
		    Return "LOST_AND_FOUND"
		  Case 10
		    Return "TAK_TRACKER"
		  Case 11
		    Return "ROUTER_LATE"
		  Case 12
		    Return "CLIENT_BASE"
		  Else
		    Return role.ToString
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshRouteString(firstNode As UInt32, hops() As UInt32, lastNode As UInt32, snrs() As Int32) As String
		  // "!a > !b > !c (SNR 6.25, 5.5)", SNR values are in quarter dB
		  Dim nodes() As String
		  nodes.Add(MeshNodeID(firstNode))
		  For Each hop As UInt32 In hops
		    nodes.Add(MeshNodeID(hop))
		  Next
		  nodes.Add(MeshNodeID(lastNode))
		  Dim result As String = String.FromArray(nodes, " > ")
		  If snrs.Count > 0 Then
		    Dim values() As String
		    For Each q As Int32 In snrs
		      Dim db As Double = q / 4
		      values.Add(db.ToString(Locale.Raw, "0.##"))
		    Next
		    result = result + " (SNR " + String.FromArray(values, ", ") + ")"
		  End If
		  Return result
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshRoutingErrorName(code As Integer) As String
		  // Routing.Error in mesh.proto (firmware 2.8)
		  Select Case code
		  Case 0
		    Return "NONE"
		  Case 1
		    Return "NO_ROUTE"
		  Case 2
		    Return "GOT_NAK"
		  Case 3
		    Return "TIMEOUT"
		  Case 4
		    Return "NO_INTERFACE"
		  Case 5
		    Return "MAX_RETRANSMIT"
		  Case 6
		    Return "NO_CHANNEL"
		  Case 7
		    Return "TOO_LARGE"
		  Case 8
		    Return "NO_RESPONSE"
		  Case 9
		    Return "DUTY_CYCLE_LIMIT"
		  Case 32
		    Return "BAD_REQUEST"
		  Case 33
		    Return "NOT_AUTHORIZED"
		  Case 34
		    Return "PKI_FAILED"
		  Case 35
		    Return "PKI_UNKNOWN_PUBKEY"
		  Case 36
		    Return "ADMIN_BAD_SESSION_KEY"
		  Case 37
		    Return "ADMIN_PUBLIC_KEY_UNAUTHORIZED"
		  Case 38
		    Return "RATE_LIMIT_EXCEEDED"
		  Case 39
		    Return "PKI_SEND_FAIL_PUBLIC_KEY"
		  Else
		    Return "error " + Str(code)
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshRoutingSummary(payload As String, requestID As UInt32) As String
		  // ROUTING_APP: an ACK / NAK (error_reason, field 3) for packet requestID, or route discovery (fields 1, 2)
		  Dim mb As MemoryBlock = ProtoRawBytes(payload)
		  If mb = Nil Then Return ""
		  Dim r As New ProtoReader(mb)
		  Dim field, wireType As Integer
		  Dim code As Integer = -1
		  Dim what As String
		  While r.ReadTag(field, wireType)
		    If field = 3 And wireType = 0 Then
		      code = CType(r.ReadVarint(), Integer)
		    ElseIf field = 1 Then
		      what = "route request"
		      r.Skip(wireType)
		    ElseIf field = 2 Then
		      what = "route reply"
		      r.Skip(wireType)
		    Else
		      r.Skip(wireType)
		    End If
		  Wend
		  If r.Failed Then Return "(bad routing)"
		  If code = 0 Then Return "ACK for packet " + requestID.ToString
		  If code > 0 Then Return "NAK for packet " + requestID.ToString + ": " + MeshRoutingErrorName(code)
		  Return what
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshSeenRecently(packetKey As String) As Boolean
		  // True if the same packet (sender:id) was already seen in the last 10 minutes, otherwise remembers it.
		  // Gateways can publish a packet more than once, and several gateways can upload the same packet
		  If packetKey = "" Then Return False
		  Dim now As Double = System.Microseconds / 1000000
		  If mSeenPackets = Nil Then mSeenPackets = New Dictionary
		  For Each k As Variant In mSeenPackets.Keys
		    If now - mSeenPackets.Value(k).DoubleValue > 600 Then mSeenPackets.Remove(k)
		  Next
		  If mSeenPackets.HasKey(packetKey) Then Return True
		  mSeenPackets.Value(packetKey) = now
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshTakeAckRequest(ByRef fromNode As UInt32, ByRef packetID As UInt32, ByRef channelName As String) As Boolean
		  // After MeshPacketSummary: True (once) when the packet was addressed to our node with want_ack set,
		  // so the app should answer with MeshBuildAck (channelName "" = its primary channel)
		  If Not mAckRequestValid Then Return False
		  mAckRequestValid = False
		  fromNode = mAckRequestFrom
		  packetID = mAckRequestID
		  channelName = mAckRequestChannel
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshTakeRouting(ByRef requestID As UInt32, ByRef fromNode As UInt32, ByRef toNode As UInt32, ByRef errorCode As Integer) As Boolean
		  // After MeshPacketSummary: True (once) when the packet was a ROUTING ACK / NAK for packet requestID
		  If Not mRoutingValid Then Return False
		  mRoutingValid = False
		  requestID = mRoutingRequestID
		  fromNode = mRoutingFrom
		  toNode = mRoutingTo
		  errorCode = mRoutingError
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshTelemetrySpec(variant As Integer) As String
		  // Field tables generated from telemetry.proto, one per Telemetry variant (field number 2..8).
		  // Entries are "number:name:type", type f = float, u = unsigned varint, s = string, c = hundredths (uint32 / 100).
		  // Names follow mqtt-converter's JSON keys (pm10, voltage_ch1, ...), otherwise the proto field name.
		  Select Case variant
		  Case 2 // DeviceMetrics
		    Return "1:battery_level:u,2:voltage:f,3:channel_utilization:f,4:air_util_tx:f,5:uptime_seconds:u"
		  Case 3 // EnvironmentMetrics
		    Return "1:temperature:f,2:relative_humidity:f,3:barometric_pressure:f,4:gas_resistance:f,5:voltage:f,6:current:f,7:iaq:u,8:distance:f,9:lux:f,10:white_lux:f,11:ir_lux:f,12:uv_lux:f,13:wind_direction:u,14:wind_speed:f,15:weight:f,16:wind_gust:f,17:wind_lull:f,18:radiation:f,19:rainfall_1h:f,20:rainfall_24h:f,21:soil_moisture:u,22:soil_temperature:f"
		  Case 4 // AirQualityMetrics
		    Return "1:pm10:u,2:pm25:u,3:pm100:u,4:pm10_environmental:u,5:pm25_environmental:u,6:pm100_environmental:u,7:particles_03um:u,8:particles_05um:u,9:particles_10um:u,10:particles_25um:u,11:particles_50um:u,12:particles_100um:u,13:co2:u,14:co2_temperature:f,15:co2_humidity:f,16:form_formaldehyde:f,17:form_humidity:f,18:form_temperature:f,19:pm40_standard:u,20:particles_40um:u,21:pm_temperature:f,22:pm_humidity:f,23:pm_voc_idx:f,24:pm_nox_idx:f,25:particles_tps:f"
		  Case 5 // PowerMetrics
		    Return "1:voltage_ch1:f,2:current_ch1:f,3:voltage_ch2:f,4:current_ch2:f,5:voltage_ch3:f,6:current_ch3:f,7:voltage_ch4:f,8:current_ch4:f,9:voltage_ch5:f,10:current_ch5:f,11:voltage_ch6:f,12:current_ch6:f,13:voltage_ch7:f,14:current_ch7:f,15:voltage_ch8:f,16:current_ch8:f"
		  Case 6 // LocalStats
		    Return "1:uptime_seconds:u,2:channel_utilization:f,3:air_util_tx:f,4:num_packets_tx:u,5:num_packets_rx:u,6:num_packets_rx_bad:u,7:num_online_nodes:u,8:num_total_nodes:u,9:num_rx_dupe:u,10:num_tx_relay:u,11:num_tx_relay_canceled:u,12:heap_total_bytes:u,13:heap_free_bytes:u,14:num_tx_dropped:u"
		  Case 7 // HealthMetrics
		    Return "1:heart_bpm:u,2:spO2:u,3:temperature:f"
		  Case 8 // HostMetrics
		    Return "1:uptime_seconds:u,2:freemem_bytes:u,3:diskfree1_bytes:u,4:diskfree2_bytes:u,5:diskfree3_bytes:u,6:load1:c,7:load5:c,8:load15:c,9:user_string:s"
		  Else
		    Return ""
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshTelemetrySummary(payload As String) As String
		  // TELEMETRY_APP: Telemetry message, a oneof of metrics messages (fields 2..8)
		  Dim mb As MemoryBlock = payload
		  Dim r As New ProtoReader(mb)
		  Dim field, wireType As Integer
		  Dim result As String
		  While r.ReadTag(field, wireType)
		    If field >= 2 And field <= 8 And wireType = 2 Then
		      Dim metrics As ProtoReader = r.ReadMessage
		      result = MeshTelemetryVariantName(field) + ": " + MeshMetricsSummary(metrics, MeshTelemetrySpec(field))
		    Else
		      r.Skip(wireType)
		    End If
		  Wend
		  If r.Failed Then Return "(bad telemetry)"
		  If result = "" Then Return "(empty telemetry)"
		  Return result
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshTelemetryVariantName(variant As Integer) As String
		  Select Case variant
		  Case 2
		    Return "device"
		  Case 3
		    Return "environment"
		  Case 4
		    Return "air_quality"
		  Case 5
		    Return "power"
		  Case 6
		    Return "local_stats"
		  Case 7
		    Return "health"
		  Case 8
		    Return "host"
		  Else
		    Return variant.ToString
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshTextSummary(payload As String) As String
		  // TEXT_MESSAGE_APP: raw UTF-8, kept on one line
		  Dim s As String = MeshUTF8Text(payload)
		  s = s.ReplaceLineEndings(" ")
		  Return """" + s + """"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshTimeString(secs As UInt32) As String
		  // Unix time as local "YYYY-MM-DD HH:MM:SS"
		  Dim seconds As Double = secs
		  Dim d As New DateTime(seconds, TimeZone.Current)
		  Return d.SQLDateTime
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshTracerouteSummary(payload As String, fromNode As UInt32, toNode As UInt32, requestID As UInt32) As String
		  // TRACEROUTE_APP: RouteDiscovery {1 route, 3 route_back: repeated fixed32; 2 snr_towards, 4 snr_back: repeated int32, quarter dB}
		  // A reply (requestID <> 0) travels from the traced node back to the requester,
		  // so the full route towards is toNode, route..., fromNode
		  Dim mb As MemoryBlock = payload
		  Dim r As New ProtoReader(mb)
		  Dim field, wireType As Integer
		  Dim route(), routeBack() As UInt32
		  Dim snrTowards(), snrBack() As Int32
		  While r.ReadTag(field, wireType)
		    Select Case field
		    Case 1
		      r.ReadRepeatedFixed32(wireType, route)
		    Case 2
		      r.ReadRepeatedInt32(wireType, snrTowards)
		    Case 3
		      r.ReadRepeatedFixed32(wireType, routeBack)
		    Case 4
		      r.ReadRepeatedInt32(wireType, snrBack)
		    Else
		      r.Skip(wireType)
		    End Select
		  Wend
		  If r.Failed Then Return "(bad traceroute)"
		  
		  If requestID = 0 Then
		    If route.Count = 1 Then Return "request, 1 hop so far"
		    Return "request, " + route.Count.ToString + " hops so far"
		  End If
		  Dim result As String = "towards: " + MeshRouteString(toNode, route, fromNode, snrTowards)
		  result = result + " | back: " + MeshRouteString(fromNode, routeBack, toNode, snrBack)
		  Return result
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshUserSummary(payload As String) As String
		  // NODEINFO_APP: User message
		  Dim mb As MemoryBlock = payload
		  Dim r As New ProtoReader(mb)
		  Dim field, wireType As Integer
		  Dim userID, longName, shortName As String
		  Dim hwModel, role As Integer
		  While r.ReadTag(field, wireType)
		    Select Case field
		    Case 1, 2, 3 // id, long_name, short_name
		      If wireType <> 2 Then Return "(bad nodeinfo)"
		      Dim s As String = r.ReadString
		      If field = 1 Then
		        userID = s
		      ElseIf field = 2 Then
		        longName = s
		      Else
		        shortName = s
		      End If
		    Case 5 // hw_model
		      If wireType <> 0 Then Return "(bad nodeinfo)"
		      hwModel = CType(r.ReadVarint(), Integer)
		    Case 7 // role
		      If wireType <> 0 Then Return "(bad nodeinfo)"
		      role = CType(r.ReadVarint(), Integer)
		    Else
		      r.Skip(wireType)
		    End Select
		  Wend
		  If r.Failed Then Return "(bad nodeinfo)"
		  Return """" + longName + """ (" + shortName + ") " + userID + ", " + MeshHardwareName(hwModel) + ", " + MeshRoleName(role)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshWaypointSummary(payload As String) As String
		  // WAYPOINT_APP: Waypoint message
		  Dim mb As MemoryBlock = payload
		  Dim r As New ProtoReader(mb)
		  Dim field, wireType As Integer
		  Dim waypointID, expire, lockedTo, icon As UInt32
		  Dim lat, lon As Int32
		  Dim hasLat, hasLon As Boolean
		  Dim waypointName, description As String
		  While r.ReadTag(field, wireType)
		    Select Case field
		    Case 1 // id
		      If wireType <> 0 Then Return "(bad waypoint)"
		      waypointID = CType(r.ReadVarint(), UInt32)
		    Case 2 // latitude_i, sfixed32
		      If wireType <> 5 Then Return "(bad waypoint)"
		      lat = r.ReadSFixed32
		      hasLat = True
		    Case 3 // longitude_i
		      If wireType <> 5 Then Return "(bad waypoint)"
		      lon = r.ReadSFixed32
		      hasLon = True
		    Case 4 // expire, unix time
		      If wireType <> 0 Then Return "(bad waypoint)"
		      expire = CType(r.ReadVarint(), UInt32)
		    Case 5 // locked_to, node number
		      If wireType <> 0 Then Return "(bad waypoint)"
		      lockedTo = CType(r.ReadVarint(), UInt32)
		    Case 6, 7 // name, description
		      If wireType <> 2 Then Return "(bad waypoint)"
		      Dim s As String = r.ReadString
		      If field = 6 Then
		        waypointName = s
		      Else
		        description = s
		      End If
		    Case 8 // icon, fixed32 unicode code point
		      If wireType <> 5 Then Return "(bad waypoint)"
		      icon = r.ReadFixed32
		    Else
		      r.Skip(wireType)
		    End Select
		  Wend
		  If r.Failed Then Return "(bad waypoint)"
		  
		  Dim parts() As String
		  Dim title As String = """" + waypointName + """"
		  If icon > 0 Then title = Chr(icon) + " " + title
		  parts.Add(title)
		  If description <> "" Then parts.Add("""" + description + """")
		  If hasLat And hasLon Then
		    Dim latDeg As Double = lat / 10000000.0
		    Dim lonDeg As Double = lon / 10000000.0
		    parts.Add("lat " + latDeg.ToString(Locale.Raw, "0.0000000"))
		    parts.Add("lon " + lonDeg.ToString(Locale.Raw, "0.0000000"))
		  End If
		  parts.Add("id " + waypointID.ToString)
		  If expire > 0 Then parts.Add("expires " + MeshTimeString(expire))
		  If lockedTo > 0 Then parts.Add("locked to " + MeshNodeID(lockedTo))
		  Return String.FromArray(parts, ", ")
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mAckRequestChannel As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mAckRequestFrom As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mAckRequestID As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mAckRequestValid As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRoutingError As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRoutingFrom As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRoutingRequestID As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRoutingTo As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRoutingValid As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSeenPackets As Dictionary
	#tag EndProperty


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
End Module
#tag EndModule
