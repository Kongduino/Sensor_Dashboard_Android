#tag Module
Protected Module Curve25519
	#tag Method, Flags = &h0
		Function X25519(scalar As String, point As String) As String
		  // Curve25519 Diffie-Hellman (RFC 7748): scalar (32 bytes, clamped here) times point (32 bytes, u coordinate).
		  // Montgomery ladder ported from TweetNaCl's crypto_scalarmult. Returns 32 bytes, "" on bad input
		  scalar = MeshBin(scalar)
		  point = MeshBin(point)
		  If scalar.Bytes <> 32 Or point.Bytes <> 32 Then Return ""
		  Dim z As MemoryBlock = scalar
		  Dim zc As New MemoryBlock(32)
		  zc.StringValue(0, 32) = z.StringValue(0, 32)
		  zc.UInt8Value(31) = Bitwise.BitOr(Bitwise.BitAnd(zc.UInt8Value(31), 127), 64)
		  zc.UInt8Value(0) = Bitwise.BitAnd(zc.UInt8Value(0), 248)
		  Dim pointMB As MemoryBlock = point
		  Dim x(15), a(15), b(15), c(15), d(15), e(15), f(15), k121665(15) As Int64
		  X25519Unpack(x, pointMB)
		  k121665(0) = &hDB41
		  k121665(1) = 1
		  X25519Copy(b, x)
		  a(0) = 1
		  d(0) = 1
		  For bit As Integer = 254 DownTo 0
		    Dim r As Integer = Bitwise.BitAnd(Bitwise.ShiftRight(zc.UInt8Value(bit \ 8), bit Mod 8), 1)
		    X25519Swap(a, b, r)
		    X25519Swap(c, d, r)
		    X25519Add(e, a, c)
		    X25519Sub(a, a, c)
		    X25519Add(c, b, d)
		    X25519Sub(b, b, d)
		    X25519Mul(d, e, e)
		    X25519Mul(f, a, a)
		    X25519Mul(a, c, a)
		    X25519Mul(c, b, e)
		    X25519Add(e, a, c)
		    X25519Sub(a, a, c)
		    X25519Mul(b, a, a)
		    X25519Sub(c, d, f)
		    X25519Mul(a, c, k121665)
		    X25519Add(a, a, d)
		    X25519Mul(c, c, a)
		    X25519Mul(a, d, f)
		    X25519Mul(d, b, x)
		    X25519Mul(b, e, e)
		    X25519Swap(a, b, r)
		    X25519Swap(c, d, r)
		  Next
		  X25519Invert(c, c)
		  X25519Mul(a, a, c)
		  Return X25519Pack(a)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub X25519Add(o() As Int64, a() As Int64, b() As Int64)
		  For i As Integer = 0 To 15
		    o(i) = a(i) + b(i)
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub X25519Carry(o() As Int64)
		  // Normalizes limbs to 16 bits (TweetNaCl car25519). The carry out of the top limb wraps around times 38,
		  // since 2^256 = 38 (mod 2^255 - 19). Floor division, as C's arithmetic shift does for negative values
		  For i As Integer = 0 To 15
		    Dim v As Int64 = o(i) + 65536
		    Dim c As Int64
		    If v >= 0 Then
		      c = v \ 65536
		    Else
		      c = -((65535 - v) \ 65536)
		    End If
		    If i < 15 Then
		      o(i + 1) = o(i + 1) + c - 1
		    Else
		      o(0) = o(0) + 38 * (c - 1)
		    End If
		    o(i) = v - c * 65536
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub X25519Copy(o() As Int64, a() As Int64)
		  For i As Integer = 0 To 15
		    o(i) = a(i)
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub X25519Invert(o() As Int64, a() As Int64)
		  // o = a^(p - 2) = 1 / a (Fermat), TweetNaCl inv25519
		  Dim c(15) As Int64
		  X25519Copy(c, a)
		  For k As Integer = 253 DownTo 0
		    X25519Mul(c, c, c)
		    If k <> 2 And k <> 4 Then X25519Mul(c, c, a)
		  Next
		  X25519Copy(o, c)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub X25519Mul(o() As Int64, a() As Int64, b() As Int64)
		  // o = a * b mod 2^255 - 19 (o may be a or b)
		  Dim t(30) As Int64
		  For i As Integer = 0 To 15
		    For j As Integer = 0 To 15
		      t(i + j) = t(i + j) + a(i) * b(j)
		    Next
		  Next
		  For k As Integer = 0 To 14
		    t(k) = t(k) + 38 * t(k + 16)
		  Next
		  For n As Integer = 0 To 15
		    o(n) = t(n)
		  Next
		  X25519Carry(o)
		  X25519Carry(o)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function X25519Pack(n() As Int64) As String
		  // Fully reduces mod 2^255 - 19 and returns 32 little-endian bytes (TweetNaCl pack25519)
		  Dim t(15), m(15) As Int64
		  X25519Copy(t, n)
		  X25519Carry(t)
		  X25519Carry(t)
		  X25519Carry(t)
		  For pass As Integer = 0 To 1
		    m(0) = t(0) - &hFFED
		    For i As Integer = 1 To 14
		      Dim borrow As Int64 = 0
		      If (m(i - 1) And &h10000) <> 0 Then borrow = 1
		      m(i) = t(i) - &hFFFF - borrow
		      m(i - 1) = m(i - 1) And &hFFFF
		    Next
		    Dim borrow14 As Int64 = 0
		    If (m(14) And &h10000) <> 0 Then borrow14 = 1
		    m(15) = t(15) - &h7FFF - borrow14
		    Dim negative As Integer = 0
		    If (m(15) And &h10000) <> 0 Then negative = 1
		    m(14) = m(14) And &hFFFF
		    X25519Swap(t, m, 1 - negative)
		  Next
		  Dim packed As New MemoryBlock(32)
		  For limb As Integer = 0 To 15
		    packed.UInt8Value(2 * limb) = t(limb) Mod 256
		    packed.UInt8Value(2 * limb + 1) = t(limb) \ 256
		  Next
		  Return packed.StringValue(0, 32)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function X25519PublicKey(privateKey As String) As String
		  // The public key for a private key: privateKey times the base point u = 9
		  Dim base As New MemoryBlock(32)
		  base.UInt8Value(0) = 9
		  Return X25519(privateKey, base.StringValue(0, 32))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub X25519Sub(o() As Int64, a() As Int64, b() As Int64)
		  For i As Integer = 0 To 15
		    o(i) = a(i) - b(i)
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub X25519Swap(p() As Int64, q() As Int64, doSwap As Integer)
		  // Swaps two field elements when doSwap = 1 (TweetNaCl sel25519)
		  If doSwap = 0 Then Return
		  For i As Integer = 0 To 15
		    Dim t As Int64 = p(i)
		    p(i) = q(i)
		    q(i) = t
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub X25519Unpack(o() As Int64, bytes As MemoryBlock)
		  // 32 little-endian bytes to 16 limbs, top bit ignored
		  For i As Integer = 0 To 15
		    o(i) = bytes.UInt8Value(2 * i) + 256 * bytes.UInt8Value(2 * i + 1)
		  Next
		  o(15) = o(15) And &h7FFF
		End Sub
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
