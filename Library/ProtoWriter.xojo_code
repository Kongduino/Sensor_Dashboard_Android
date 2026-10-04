#tag Module
Protected Module ProtoWriter
	#tag Method, Flags = &h0
		Function MeshBin(s As String) As String
		  // Binary data, one byte per character. On Android a String made by concatenation, ChrByte or ReadAll is tagged
		  // UTF-8, and its byte view (Bytes, MiddleBytes, AscByte, EncodeHex, TCPSocket.Write, MemoryBlock conversion) then
		  // counts every character from 128 to 255 as two bytes. MeshBin returns a copy tagged ISO-8859-1 (one byte per
		  // character); slices of it (MiddleBytes, LeftBytes) keep the tag, a concatenation loses it.
		  // The library's rule: a binary String is passed between methods only in this form (methods that build one by
		  // concatenation return MeshBin(...), always-binary parameters are passed through MeshBin on entry). Text stays text.
		  // On desktop it returns s unchanged
		  #If TargetAndroid Then
		    Dim t As String = s + "" // a new String: on Android DefineEncoding changes the String object itself
		    Return t.DefineEncoding(Encodings.ISOLatin1)
		  #Else
		    Return s
		  #EndIf
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshUTF8Text(bytes As String) As String
		  // UTF-8 bytes (one byte per character, see MeshBin) as text. On desktop that is only a label (DefineEncoding);
		  // on Android the bytes must really be decoded
		  #If TargetAndroid Then
		    If bytes.Bytes = 0 Then Return ""
		    Dim mb As MemoryBlock = MeshBin(bytes)
		    Return mb.StringValue(0, mb.Size, Encodings.UTF8)
		  #Else
		    Return bytes.DefineEncoding(Encodings.UTF8)
		  #EndIf
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ProtoFieldBytes(field As Integer, data As String) As String
		  // bytes, string (UTF-8) and embedded messages
		  Dim raw As String = ProtoRawBytes(data)
		  Return MeshBin(ProtoKey(field, 2) + ProtoVarint(raw.Bytes) + raw)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ProtoFieldFixed32(field As Integer, value As UInt32) As String
		  Dim m As New MemoryBlock(4)
		  m.LittleEndian = True
		  m.UInt32Value(0) = value
		  Return MeshBin(ProtoKey(field, 5) + m.StringValue(0, 4))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ProtoFieldInt32(field As Integer, value As Int32) As String
		  // int32: negative values are sign-extended to 64 bits (10-byte varint), as protobuf requires
		  Dim m As New MemoryBlock(8)
		  m.LittleEndian = True
		  m.Int64Value(0) = value
		  Return ProtoFieldVarint(field, m.UInt64Value(0))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ProtoFieldSFixed32(field As Integer, value As Int32) As String
		  Dim m As New MemoryBlock(4)
		  m.LittleEndian = True
		  m.Int32Value(0) = value
		  Return MeshBin(ProtoKey(field, 5) + m.StringValue(0, 4))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ProtoFieldVarint(field As Integer, value As UInt64) As String
		  // uint32, uint64, bool, enum
		  Return MeshBin(ProtoKey(field, 0) + ProtoVarint(value))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ProtoKey(field As Integer, wireType As Integer) As String
		  Return ProtoVarint(Bitwise.ShiftLeft(field, 3) Or wireType)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ProtoRawBytes(s As String) As String
		  // The bytes of s without a text encoding, so that concatenating protobuf pieces never converts anything
		  If s.Bytes = 0 Then Return ""
		  Dim mb As MemoryBlock = s
		  Return mb.StringValue(0, mb.Size)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ProtoVarint(value As UInt64) As String
		  // Base-128 varint, least significant group first
		  Dim mb As New MemoryBlock(10)
		  Dim n As Integer = 0
		  Dim v As UInt64 = value
		  Do
		    Dim b As Integer = CType(v And &h7F, Integer)
		    v = Bitwise.ShiftRight(v, 7)
		    If v <> 0 Then b = b Or &h80
		    mb.UInt8Value(n) = b
		    n = n + 1
		  Loop Until v = 0
		  Return mb.StringValue(0, n)
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
