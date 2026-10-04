#tag Module
Protected Module MeshChannels
	#tag Method, Flags = &h0
		Function MeshAddChannel(name As String, psk As String) As Boolean
		  // Adds a channel, or replaces the key of an existing one. name is the channel name as it appears in the
		  // MQTT topic (e.g. "LongFast"), psk as shown in the Meshtastic app (base64) or any format MeshParsePSK takes.
		  // False if the PSK can't be parsed. Until this is first called, LongFast with the default key is configured
		  Dim pskBytes As String
		  If Not MeshParsePSK(psk, pskBytes) Then Return False
		  If pskBytes.Bytes > 32 Then Return False
		  Dim key As String = MeshKeyFromPSK(pskBytes)
		  mChannelsSet = True
		  Dim idx As Integer = MeshChannelIndex(name)
		  If idx >= 0 Then
		    mChannelKeys(idx) = key
		  Else
		    mChannelNames.Add(name)
		    mChannelKeys.Add(key)
		  End If
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshChannelCount() As Integer
		  MeshEnsureChannels
		  Return mChannelNames.Count
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshChannelHash(name As String, key As String) As Integer
		  // The firmware's channel hash (Channels::generateHash): xor of the name bytes, xor-ed with the xor of the key bytes.
		  // Encrypted packets carry it in MeshPacket.channel
		  Dim h As Integer = 0
		  If name.Bytes > 0 Then
		    Dim nameMB As MemoryBlock = name
		    For i As Integer = 0 To nameMB.Size - 1
		      h = Bitwise.BitXor(h, nameMB.UInt8Value(i))
		    Next
		  End If
		  key = MeshBin(key)
		  If key.Bytes > 0 Then
		    Dim keyMB As MemoryBlock = key
		    For j As Integer = 0 To keyMB.Size - 1
		      h = Bitwise.BitXor(h, keyMB.UInt8Value(j))
		    Next
		  End If
		  Return h
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshChannelIndex(name As String) As Integer
		  // Exact (case-sensitive) match, as channel names are compared in the firmware
		  For i As Integer = 0 To mChannelNames.LastIndex
		    If MeshSameText(mChannelNames(i), name) Then Return i
		  Next
		  Return -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshChannelKey(index As Integer) As String
		  // The AES key of a configured channel ("" = no encryption)
		  Return mChannelKeys(index)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshChannelList() As String
		  // One line per configured channel: name, cipher and channel hash
		  MeshEnsureChannels
		  If mChannelNames.Count = 0 Then Return "Channels: none"
		  Dim lines() As String
		  For i As Integer = 0 To mChannelNames.LastIndex
		    Dim key As String = mChannelKeys(i)
		    Dim cipher As String
		    If key.Bytes = 0 Then
		      cipher = "no encryption"
		    Else
		      cipher = "AES-" + Str(key.Bytes * 8)
		    End If
		    lines.Add("Channel """ + mChannelNames(i) + """: " + cipher + ", hash " + Str(MeshChannelHash(mChannelNames(i), key)))
		  Next
		  Return String.FromArray(lines, EndOfLine)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshChannelName(index As Integer) As String
		  Return mChannelNames(index)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub MeshClearChannels()
		  // Removes all channels, including the default LongFast
		  mChannelNames.RemoveAll
		  mChannelKeys.RemoveAll
		  mChannelsSet = True
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshDecodeBase64Strict(s As String, ByRef bytes As String) As Boolean
		  // Only well-formed base64 (A-Z a-z 0-9 + /, padded to a multiple of 4)
		  Dim re As New RegEx
		  re.SearchPattern = "^[A-Za-z0-9+/]+={0,2}$"
		  If re.Search(s) = Nil Or s.Length Mod 4 <> 0 Then Return False
		  bytes = DecodeBase64(s)
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshDecodeHexStrict(s As String, ByRef bytes As String) As Boolean
		  // Only an even number of hex digits
		  Dim re As New RegEx
		  re.SearchPattern = "^([0-9a-fA-F]{2})+$"
		  If re.Search(s) = Nil Then Return False
		  bytes = DecodeHex(s)
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshDecryptPacket(channelID As String, channelHash As UInt32, packetID As UInt32, fromNode As UInt32, cipher As String, ByRef portnum As Integer, ByRef dataPayload As String, ByRef requestID As UInt32, ByRef keyName As String) As Boolean
		  // Tries the configured channels whose name is channelID and/or whose hash is channelHash
		  // (both first, then name only, then hash only). A wrong key gives random bytes, so a result is
		  // only accepted when it parses cleanly as Data with a known, non-zero portnum
		  MeshEnsureChannels
		  Dim order() As Integer
		  For pass As Integer = 1 To 3
		    For i As Integer = 0 To mChannelNames.LastIndex
		      If mChannelKeys(i).Bytes = 0 Or order.IndexOf(i) >= 0 Then Continue
		      Dim nameMatch As Boolean = (MeshSameText(mChannelNames(i), channelID))
		      Dim hashMatch As Boolean = (MeshChannelHash(mChannelNames(i), mChannelKeys(i)) = channelHash)
		      If (pass = 1 And nameMatch And hashMatch) Or (pass = 2 And nameMatch) Or (pass = 3 And hashMatch) Then order.Add(i)
		    Next
		  Next
		  For Each idx As Integer In order
		    Dim plain As String = MeshDecrypt(mChannelKeys(idx), packetID, fromNode, cipher)
		    If plain.Bytes > 0 Then
		      Dim plainMB As MemoryBlock = plain
		      Dim p As Integer
		      Dim plainPayload As String
		      Dim plainRequestID As UInt32
		      If MeshParseData(New ProtoReader(plainMB), p, plainPayload, plainRequestID) And p > 0 And MeshPortName(p) <> "?" Then
		        portnum = p
		        dataPayload = plainPayload
		        requestID = plainRequestID
		        keyName = mChannelNames(idx)
		        Return True
		      End If
		    End If
		  Next
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub MeshEnsureChannels()
		  // Default configuration: LongFast with the default key, until MeshAddChannel or MeshClearChannels is called
		  If mChannelsSet Then Return
		  Call MeshAddChannel("LongFast", "AQ==")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshKeyFromPSK(psk As String) As String
		  // The AES key for a PSK, as the firmware expands it (Channels::getKey):
		  // 0 bytes = no encryption, 1 byte = default key with the last byte + (index - 1) (index 0 = no encryption),
		  // 16/32 bytes = AES-128/256 key, shorter keys padded with zeros to 16 or 32 bytes
		  psk = MeshBin(psk)
		  Select Case psk.Bytes
		  Case 0
		    Return ""
		  Case 1
		    Dim index As Integer = psk.AscByte
		    If index = 0 Then Return ""
		    Dim k As MemoryBlock = DecodeHex("d4f1bb3a20290759f0bcffabcf4e6901")
		    k.UInt8Value(15) = (k.UInt8Value(15) + index - 1) Mod 256
		    Return k.StringValue(0, 16)
		  Case 16, 32
		    Return psk
		  Else
		    Dim size As Integer = 32
		    If psk.Bytes < 16 Then size = 16
		    Dim padded As New MemoryBlock(size)
		    padded.StringValue(0, psk.Bytes) = psk
		    Return padded.StringValue(0, size)
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshParsePSK(psk As String, ByRef pskBytes As String) As Boolean
		  // The PSK formats mqtt-converter accepts: "AQ==" (base64, as the Meshtastic app shows it), "base64:...",
		  // "0x" + hex, plain hex, "default" or "1" (the default key), "none" or "" (no encryption)
		  pskBytes = ""
		  Dim s As String = psk.Trim
		  If s = "" Or s = "none" Then Return True // case-insensitive, like the converter
		  If MeshSameText(s, "default") Or s = "1" Then
		    pskBytes = MeshBin(String.ChrByte(1))
		    Return True
		  End If
		  If s.BeginsWith("base64:") Then Return MeshDecodeBase64Strict(s.Middle(7), pskBytes)
		  If s.BeginsWith("0x") Then Return MeshDecodeHexStrict(s.Middle(2), pskBytes)
		  If MeshDecodeHexStrict(s, pskBytes) Then Return True
		  Return MeshDecodeBase64Strict(s, pskBytes)
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mChannelKeys() As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mChannelNames() As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mChannelsSet As Boolean
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
