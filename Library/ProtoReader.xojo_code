#tag Class
Protected Class ProtoReader
	#tag Method, Flags = &h0
		Function AtEnd() As Boolean
		  Return mFailed Or mPos >= mEnd
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(data As MemoryBlock, start As Integer = 0, length As Integer = -1)
		  // Reads protobuf wire format from data, starting at start, for length bytes (-1 = to the end).
		  // Nil is read as an empty message (converting "" to a MemoryBlock may give Nil)
		  If data = Nil Then
		    mData = New MemoryBlock(0)
		    Return
		  End If
		  mData = data
		  mData.LittleEndian = True
		  mPos = start
		  If length < 0 Then
		    mEnd = data.Size
		  Else
		    mEnd = start + length
		  End If
		  If mPos < 0 Or mEnd > data.Size Or mPos > mEnd Then
		    mFailed = True
		    mPos = 0
		    mEnd = 0
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Failed() As Boolean
		  Return mFailed
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadBytes() As String
		  // Raw bytes, no encoding
		  Dim start, length As Integer
		  If Not ReadLengthDelimited(start, length) Then Return ""
		  If length = 0 Then Return ""
		  Return mData.StringValue(start, length)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadFixed32() As UInt32
		  If mFailed Or mPos + 4 > mEnd Then
		    mFailed = True
		    Return 0
		  End If
		  Dim v As UInt32 = mData.UInt32Value(mPos)
		  mPos = mPos + 4
		  Return v
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadFloat() As Single
		  If mFailed Or mPos + 4 > mEnd Then
		    mFailed = True
		    Return 0
		  End If
		  Dim v As Single = mData.SingleValue(mPos)
		  mPos = mPos + 4
		  Return v
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadInt32() As Int32
		  // int32 fields: negative values arrive as 10-byte varints, keep the low 32 bits
		  Dim v As UInt64 = ReadVarint()
		  Dim m As New MemoryBlock(8)
		  m.LittleEndian = True
		  m.UInt64Value(0) = v
		  Return m.Int32Value(0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadLengthDelimited(ByRef start As Integer, ByRef length As Integer) As Boolean
		  // Reads the length prefix, returns the slice position and moves past it
		  Dim n As UInt64 = ReadVarint()
		  If mFailed Then Return False
		  If n > CType(mEnd - mPos, UInt64) Then
		    mFailed = True
		    Return False
		  End If
		  start = mPos
		  length = CType(n, Integer)
		  mPos = mPos + length
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadMessage() As ProtoReader
		  // Returns a reader over an embedded message, or Nil if malformed
		  Dim start, length As Integer
		  If Not ReadLengthDelimited(start, length) Then Return Nil
		  Return New ProtoReader(mData, start, length)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ReadRepeatedFixed32(wireType As Integer, values() As UInt32)
		  // Repeated fixed32: packed (wire type 2, proto3 default) or one value per tag (wire type 5)
		  If wireType = 5 Then
		    values.Add(ReadFixed32())
		  ElseIf wireType = 2 Then
		    Dim packed As ProtoReader = ReadMessage()
		    If packed = Nil Then Return
		    While Not packed.AtEnd
		      values.Add(packed.ReadFixed32())
		    Wend
		    If packed.Failed Then mFailed = True
		  Else
		    mFailed = True
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub ReadRepeatedInt32(wireType As Integer, values() As Int32)
		  // Repeated int32: packed (wire type 2, proto3 default) or one value per tag (wire type 0)
		  If wireType = 0 Then
		    values.Add(ReadInt32())
		  ElseIf wireType = 2 Then
		    Dim packed As ProtoReader = ReadMessage()
		    If packed = Nil Then Return
		    While Not packed.AtEnd
		      values.Add(packed.ReadInt32())
		    Wend
		    If packed.Failed Then mFailed = True
		  Else
		    mFailed = True
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadSFixed32() As Int32
		  If mFailed Or mPos + 4 > mEnd Then
		    mFailed = True
		    Return 0
		  End If
		  Dim v As Int32 = mData.Int32Value(mPos)
		  mPos = mPos + 4
		  Return v
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadString() As String
		  Return MeshUTF8Text(ReadBytes())
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadTag(ByRef field As Integer, ByRef wireType As Integer) As Boolean
		  // Returns False at the end of the message or on malformed data (check Failed)
		  If mFailed Or mPos >= mEnd Then Return False
		  Dim tag As UInt64 = ReadVarint()
		  If mFailed Then Return False
		  wireType = CType(tag And 7, Integer)
		  Dim shifted As UInt64 = Bitwise.ShiftRight(tag, 3) // not inside CType: Android's translation loses the argument
		  field = CType(shifted, Integer)
		  If field <= 0 Or field > 536870911 Then
		    mFailed = True
		    Return False
		  End If
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ReadVarint() As UInt64
		  // Up to 10 bytes, 7 bits each, least significant group first
		  Dim result As UInt64 = 0
		  Dim shift As Integer = 0
		  While mPos < mEnd And shift < 64
		    Dim b As UInt64 = mData.UInt8Value(mPos)
		    mPos = mPos + 1
		    result = result Or Bitwise.ShiftLeft(b And &h7F, shift)
		    If (b And &h80) = 0 Then Return result
		    shift = shift + 7
		  Wend
		  mFailed = True
		  Return 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Skip(wireType As Integer)
		  // Skips the value of an unknown field
		  Select Case wireType
		  Case 0
		    Call ReadVarint()
		  Case 1
		    If mPos + 8 > mEnd Then
		      mFailed = True
		    Else
		      mPos = mPos + 8
		    End If
		  Case 2
		    Dim start, length As Integer
		    Call ReadLengthDelimited(start, length)
		  Case 5
		    Call ReadFixed32()
		  Else
		    // Groups (3, 4) are not used by Meshtastic
		    mFailed = True
		  End Select
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mData As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mEnd As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mFailed As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPos As Integer
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
End Class
#tag EndClass
