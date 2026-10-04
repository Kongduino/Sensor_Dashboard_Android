#tag Module
Protected Module MeshSend
	#tag Method, Flags = &h0
		Function MeshBuildAck(channelName As String, gatewayID As String, fromNode As UInt32, toNode As UInt32, requestID As UInt32, ByRef envelope As String) As String
		  // A ROUTING ACK (error_reason NONE) for packet requestID, as a node sends it (MeshModule::allocAckNak):
		  // to the original sender, request_id = its packet id, channel-encrypted (ROUTING is never PKI). "" when OK
		  Dim routing As String = ProtoFieldVarint(3, 0) // Routing.error_reason = NONE (oneof, so encoded even when 0)
		  Return MeshBuildEnvelope(channelName, gatewayID, fromNode, toNode, MeshNewPacketID(), 3, 5, routing, envelope, False, requestID)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshBuildEnvelope(channelName As String, gatewayID As String, fromNode As UInt32, toNode As UInt32, packetID As UInt32, hopLimit As Integer, portnum As Integer, payload As String, ByRef envelope As String, wantAck As Boolean = False, requestID As UInt32 = 0) As String
		  // A ServiceEnvelope for downlink, as a gateway accepts it (firmware MQTT::onReceiveProto): encrypted with
		  // the channel key when the channel has one (a gateway with MQTT encryption on ignores decoded packets),
		  // with the channel hash in MeshPacket.channel so the gateway finds the key, and the same nonce as decryption.
		  // Returns "" when OK, otherwise the problem
		  Dim idx As Integer = MeshChannelIndex(channelName)
		  If idx < 0 Then Return "channel """ + channelName + """ is not in the configuration"
		  Dim key As String = MeshChannelKey(idx)
		  Dim data As String = ProtoFieldVarint(1, portnum) + ProtoFieldBytes(2, payload)
		  If requestID <> 0 Then data = data + ProtoFieldFixed32(6, requestID) // Data.request_id, e.g. in an ACK
		  data = MeshBin(data)
		  Dim packet As String = ProtoFieldFixed32(1, fromNode) + ProtoFieldFixed32(2, toNode)
		  If key.Bytes > 0 Then
		    Dim cipher As String = MeshDecrypt(key, packetID, fromNode, data) // AES-CTR: encrypting is the same operation
		    If cipher.Bytes <> data.Bytes Then Return "encryption failed"
		    packet = packet + ProtoFieldVarint(3, MeshChannelHash(channelName, key)) + ProtoFieldBytes(5, cipher)
		  Else
		    packet = packet + ProtoFieldBytes(4, data)
		  End If
		  packet = packet + ProtoFieldFixed32(6, packetID) + ProtoFieldVarint(9, hopLimit)
		  If wantAck Then packet = packet + ProtoFieldVarint(10, 1) // want_ack: the destination answers with a ROUTING ACK
		  packet = packet + ProtoFieldVarint(15, hopLimit)
		  envelope = MeshBin(ProtoFieldBytes(1, MeshBin(packet)) + ProtoFieldBytes(2, channelName) + ProtoFieldBytes(3, gatewayID))
		  Return ""
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshBuildPKIEnvelope(gatewayID As String, fromNode As UInt32, toNode As UInt32, packetID As UInt32, hopLimit As Integer, portnum As Integer, payload As String, ByRef envelope As String, wantAck As Boolean = False) As String
		  // A PKI direct message for downlink: Data encrypted with AES-256-CCM under SHA-256(X25519(our private key,
		  // their public key)), ciphertext | tag | extraNonce in MeshPacket.encrypted, channel 0, pki_encrypted, and the
		  // envelope's channel_id "PKI" (topic <root>/2/e/PKI/<gateway>). Returns "" when OK, otherwise the problem
		  If Not MeshPKIReady() Or fromNode <> MeshPKINodeNum() Then Return "PKI needs our own node as sender and node.private_key in the configuration"
		  Dim theirKey As String = MeshPublicKeyFor(toNode)
		  If theirKey.Bytes <> 32 Then Return "no public key known for " + MeshNodeID(toNode)
		  Dim data As String = MeshBin(ProtoFieldVarint(1, portnum) + ProtoFieldBytes(2, payload))
		  Dim sealed As String = MeshPKISeal(theirKey, packetID, fromNode, data)
		  If sealed = "" Then Return "PKI encryption failed"
		  Dim packet As String = ProtoFieldFixed32(1, fromNode) + ProtoFieldFixed32(2, toNode) + ProtoFieldBytes(5, sealed)
		  packet = packet + ProtoFieldFixed32(6, packetID) + ProtoFieldVarint(9, hopLimit)
		  If wantAck Then packet = packet + ProtoFieldVarint(10, 1)
		  packet = packet + ProtoFieldVarint(15, hopLimit) + ProtoFieldVarint(17, 1)
		  envelope = MeshBin(ProtoFieldBytes(1, MeshBin(packet)) + ProtoFieldBytes(2, "PKI") + ProtoFieldBytes(3, gatewayID))
		  Return ""
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshDegreesToI(degrees As Double) As Int32
		  // Degrees to the integer form (1e-7 degrees), truncated toward zero like int() in the converter
		  Dim scaled As Double = degrees * 10000000.0
		  If scaled >= 0 Then Return CType(Floor(scaled), Int32)
		  Return CType(Ceiling(scaled), Int32)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshDownlink(topic As String, jsonText As String, defaultFrom As UInt32, gatewayID As String, ByRef outTopic As String, ByRef outPayload As String, ByRef info As String, ByRef sentID As UInt32, ByRef sentTo As UInt32, ByRef ackRequested As Boolean) As Boolean
		  // mqtt-converter's JSON downlink: {"type": "sendtext" | "sendposition", "payload": ..., optional "from", "to",
		  // "id", "hopLimit" / "hop_limit", "channel_id", "gateway_id"} received on <root>/2/json/<channel>/...
		  // becomes a protobuf ServiceEnvelope for <root>/2/e/<channel>/<gateway id>.
		  // True: outTopic / outPayload are ready, info describes them. False: info is the error, or "" when
		  // the message is not a "send..." request (e.g. our own uplink JSON), which is ignored
		  info = ""
		  sentID = 0
		  sentTo = 0
		  ackRequested = False
		  Dim pos As Integer = topic.IndexOf("/2/json/")
		  If pos < 0 Then Return False
		  Dim json As JSONItem
		  Try
		    json = New JSONItem(jsonText)
		  Catch err As JSONException
		    Return False
		  End Try
		  If json.IsArray Or Not json.HasKey("type") Then Return False
		  Dim msgType As String = json.Value("type").StringValue
		  If Not msgType.BeginsWith("send", ComparisonOptions.CaseSensitive) Then Return False
		  
		  Dim root As String = topic.Left(pos)
		  Dim rest As String = topic.Middle(pos + 8)
		  Dim channelName As String = rest.NthField("/", 1)
		  If channelName = "" Then channelName = "LongFast"
		  Dim gateway As String = gatewayID
		  Dim fromNode As UInt32 = defaultFrom
		  Dim toNode As UInt32 = 4294967295
		  Dim packetID As UInt32 = 0
		  Dim hopLimit As Integer = 3
		  Try
		    If json.HasKey("channel_id") Then channelName = json.Value("channel_id").StringValue
		    If json.HasKey("gateway_id") Then gateway = json.Value("gateway_id").StringValue
		    If json.HasKey("from") And Not MeshJSONNodeNum(json.Value("from"), fromNode) Then
		      info = "invalid ""from"""
		      Return False
		    End If
		    If json.HasKey("to") And Not MeshJSONNodeNum(json.Value("to"), toNode) Then
		      info = "invalid ""to"""
		      Return False
		    End If
		    If json.HasKey("id") And Not MeshJSONNodeNum(json.Value("id"), packetID) Then
		      info = "invalid ""id"""
		      Return False
		    End If
		    If json.HasKey("hopLimit") Then
		      hopLimit = json.Value("hopLimit").IntegerValue
		    ElseIf json.HasKey("hop_limit") Then
		      hopLimit = json.Value("hop_limit").IntegerValue
		    End If
		  Catch err As RuntimeException
		    info = "invalid field (" + err.Message + ")"
		    Return False
		  End Try
		  If fromNode = 0 Then
		    info = "no sender: set ""from"" or the node id in the configuration"
		    Return False
		  End If
		  If hopLimit < 0 Or hopLimit > 7 Then
		    info = "hopLimit must be 0..7 (gateways drop larger values)"
		    Return False
		  End If
		  If packetID = 0 Then packetID = MeshNewPacketID()
		  // Direct messages go PKI-encrypted when possible: current firmware rejects channel-encrypted ("legacy") DMs.
		  // "pki": false forces the channel key, "pki": true fails when PKI isn't possible
		  Dim canPKI As Boolean = (toNode <> 4294967295) And (fromNode = MeshPKINodeNum()) And MeshPKIReady() And (MeshPublicKeyFor(toNode) <> "")
		  Dim usePKI As Boolean = canPKI
		  Try
		    If json.HasKey("pki") Then usePKI = json.Value("pki").BooleanValue
		  Catch err As RuntimeException
		    info = "invalid ""pki"" (true or false)"
		    Return False
		  End Try
		  // want_ack: direct messages ask the destination for a ROUTING ACK ("want_ack": false to skip).
		  // Broadcasts never do: nodes don't answer them with an ACK packet
		  Dim wantAck As Boolean = (toNode <> 4294967295)
		  Try
		    If json.HasKey("want_ack") Then wantAck = json.Value("want_ack").BooleanValue And (toNode <> 4294967295)
		  Catch err As RuntimeException
		    info = "invalid ""want_ack"" (true or false)"
		    Return False
		  End Try
		  If usePKI And Not canPKI Then
		    info = "PKI not possible for " + MeshNodeID(toNode) + ": needs a direct message from our node, node.private_key, and the recipient's public key (public_keys in the configuration, or a NodeInfo seen)"
		    Return False
		  End If
		  
		  Dim portnum As Integer
		  Dim dataPayload As String
		  Dim what As String
		  If MeshSameText(msgType, "sendtext") Then
		    Dim text As String
		    If json.HasKey("payload") Then
		      Dim p As Variant = json.Value("payload")
		      If p.Type = Variant.TypeObject And p.ObjectValue IsA JSONItem Then
		        Dim po As JSONItem = JSONItem(p.ObjectValue)
		        If po.HasKey("text") Then text = po.Value("text").StringValue
		      Else
		        text = p.StringValue
		      End If
		    End If
		    If text = "" Then
		      info = "sendtext without text"
		      Return False
		    End If
		    portnum = 1
		    dataPayload = text.ConvertEncoding(Encodings.UTF8)
		    what = "text " + MeshTextSummary(dataPayload)
		  ElseIf MeshSameText(msgType, "sendposition") Then
		    If Not json.HasKey("payload") Then
		      info = "sendposition without payload"
		      Return False
		    End If
		    Dim pv As Variant = json.Value("payload")
		    If pv.Type <> Variant.TypeObject Or Not (pv.ObjectValue IsA JSONItem) Then
		      info = "sendposition payload must be an object"
		      Return False
		    End If
		    Dim position As JSONItem = JSONItem(pv.ObjectValue)
		    Dim fields As String
		    Try
		      // latitude_i / longitude_i (degrees * 1e7) take precedence over decimal latitude / longitude
		      If position.HasKey("latitude_i") Then
		        fields = fields + ProtoFieldSFixed32(1, CType(position.Value("latitude_i").Int64Value, Int32))
		      ElseIf position.HasKey("latitude") Then
		        fields = fields + ProtoFieldSFixed32(1, MeshDegreesToI(position.Value("latitude").DoubleValue))
		      End If
		      If position.HasKey("longitude_i") Then
		        fields = fields + ProtoFieldSFixed32(2, CType(position.Value("longitude_i").Int64Value, Int32))
		      ElseIf position.HasKey("longitude") Then
		        fields = fields + ProtoFieldSFixed32(2, MeshDegreesToI(position.Value("longitude").DoubleValue))
		      End If
		      If position.HasKey("altitude") Then fields = fields + ProtoFieldInt32(3, CType(position.Value("altitude").Int64Value, Int32))
		      If position.HasKey("time") Then fields = fields + ProtoFieldFixed32(4, CType(position.Value("time").Int64Value, UInt32))
		    Catch err As RuntimeException
		      info = "invalid position field (" + err.Message + ")"
		      Return False
		    End Try
		    portnum = 3
		    dataPayload = fields
		    what = "position " + MeshPositionSummary(dataPayload)
		  Else
		    info = "unsupported type """ + msgType + """ (sendtext and sendposition are)"
		    Return False
		  End If
		  
		  Dim envelope As String
		  Dim problem As String
		  If usePKI Then
		    problem = MeshBuildPKIEnvelope(gateway, fromNode, toNode, packetID, hopLimit, portnum, dataPayload, envelope, wantAck)
		    channelName = "PKI"
		  Else
		    problem = MeshBuildEnvelope(channelName, gateway, fromNode, toNode, packetID, hopLimit, portnum, dataPayload, envelope, wantAck)
		  End If
		  If problem <> "" Then
		    info = problem
		    Return False
		  End If
		  outTopic = root + "/2/e/" + channelName + "/" + gateway
		  outPayload = envelope
		  sentID = packetID
		  sentTo = toNode
		  ackRequested = wantAck
		  info = MeshNodeID(fromNode) + " -> " + MeshNodeID(toNode) + "  " + what + "  (id " + packetID.ToString
		  If wantAck Then info = info + ", ACK requested"
		  If usePKI Then
		    info = info + ", PKI)"
		  Else
		    If toNode <> 4294967295 Then info = info + ", channel key: the recipient may reject it as a legacy DM"
		    info = info + ")"
		  End If
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshJSONNodeNum(v As Variant, ByRef num As UInt32) As Boolean
		  // A node number from JSON: an integer, or a string like "!aabbccdd"
		  If v.Type = Variant.TypeString Then Return MeshParseNodeID(v.StringValue, num)
		  If v.Type <> Variant.TypeInt32 And v.Type <> Variant.TypeInt64 And v.Type <> Variant.TypeDouble Then Return False
		  Dim n As Int64 = v.Int64Value
		  If n < 0 Or n > 4294967295 Then Return False
		  num = CType(n, UInt32)
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshNewPacketID() As UInt32
		  // Random non-zero packet id, as the firmware generates them (it is also part of the encryption nonce)
		  Dim id As UInt32 = 0
		  While id = 0
		    Dim mb As MemoryBlock = Crypto.GenerateRandomBytes(4)
		    id = mb.UInt32Value(0)
		  Wend
		  Return id
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshNodeInfoPayload(nodeID As String, longName As String, shortName As String) As String
		  // User message for NODEINFO_APP: 1 id, 2 long_name, 3 short_name, 5 hw_model (255 = PRIVATE_HW), 8 public_key
		  Dim user As String = ProtoFieldBytes(1, nodeID) + ProtoFieldBytes(2, longName) + ProtoFieldBytes(3, shortName) + ProtoFieldVarint(5, 255)
		  If MeshPKIPublicKey().Bytes = 32 Then user = user + ProtoFieldBytes(8, MeshPKIPublicKey()) // public_key, so nodes can decrypt our DMs
		  Return MeshBin(user)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshParseNodeID(s As String, ByRef num As UInt32) As Boolean
		  // "!aabbccdd" (Meshtastic notation) or a decimal node number
		  Dim t As String = s.Trim
		  Dim re As New RegEx
		  re.SearchPattern = "^![0-9a-fA-F]{1,8}$"
		  If re.Search(t) <> Nil Then
		    Dim padded As String = "0000000" + t.Middle(1)
		    padded = padded.Right(8)
		    Dim mb As MemoryBlock = DecodeHex(padded)
		    mb.LittleEndian = False
		    num = mb.UInt32Value(0)
		    Return True
		  End If
		  re.SearchPattern = "^[0-9]{1,10}$"
		  If re.Search(t) <> Nil Then
		    Dim v As Int64 = t.ToInt64
		    If v > 4294967295 Then Return False
		    num = CType(v, UInt32)
		    Return True
		  End If
		  Return False
		End Function
	#tag EndMethod


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
