#tag Module
Protected Module MeshCrypto
	#tag Method, Flags = &h21
		Private Function AESEncryptBlock(w As MemoryBlock, rounds As Integer, blk As MemoryBlock) As Boolean
		  // Encrypts the 16 bytes of blk in place with the round keys w (FIPS-197 5.1). Always True
		  Dim sb As MemoryBlock = AESSBox()
		  Dim s(15) As Integer
		  Dim t(15) As Integer
		  For i As Integer = 0 To 15
		    s(i) = Bitwise.BitXor(blk.UInt8Value(i), w.UInt8Value(i))
		  Next
		  For r As Integer = 1 To rounds
		    // SubBytes and ShiftRows (the state is column by column: row rr of column c comes from column c + rr)
		    For c As Integer = 0 To 3
		      For rr As Integer = 0 To 3
		        Dim src As Integer = ((c + rr) Mod 4) * 4 + rr
		        t(c * 4 + rr) = sb.UInt8Value(s(src))
		      Next
		    Next
		    If r < rounds Then
		      // MixColumns
		      For col As Integer = 0 To 3
		        Dim b As Integer = col * 4
		        Dim a0 As Integer = t(b)
		        Dim a1 As Integer = t(b + 1)
		        Dim a2 As Integer = t(b + 2)
		        Dim a3 As Integer = t(b + 3)
		        Dim x0 As Integer = AESXTime(a0)
		        Dim x1 As Integer = AESXTime(a1)
		        Dim x2 As Integer = AESXTime(a2)
		        Dim x3 As Integer = AESXTime(a3)
		        s(b) = Bitwise.BitXor(Bitwise.BitXor(x0, x1), Bitwise.BitXor(Bitwise.BitXor(a1, a2), a3))
		        s(b + 1) = Bitwise.BitXor(Bitwise.BitXor(a0, x1), Bitwise.BitXor(Bitwise.BitXor(x2, a2), a3))
		        s(b + 2) = Bitwise.BitXor(Bitwise.BitXor(a0, a1), Bitwise.BitXor(Bitwise.BitXor(x2, x3), a3))
		        s(b + 3) = Bitwise.BitXor(Bitwise.BitXor(x0, a0), Bitwise.BitXor(Bitwise.BitXor(a1, a2), x3))
		      Next
		    Else
		      For j As Integer = 0 To 15
		        s(j) = t(j)
		      Next
		    End If
		    // AddRoundKey
		    Dim offset As Integer = r * 16
		    For k As Integer = 0 To 15
		      s(k) = Bitwise.BitXor(s(k), w.UInt8Value(offset + k))
		    Next
		  Next
		  For n As Integer = 0 To 15
		    blk.UInt8Value(n) = s(n)
		  Next
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function AESExpandKey(key As MemoryBlock, ByRef rounds As Integer) As MemoryBlock
		  // AES key schedule (FIPS-197 5.2) for a 16-, 24- or 32-byte key: rounds + 1 round keys of 16 bytes
		  Dim sb As MemoryBlock = AESSBox()
		  Dim nk As Integer = key.Size \ 4
		  rounds = nk + 6
		  Dim total As Integer = 4 * (rounds + 1)
		  Dim w As New MemoryBlock(total * 4)
		  For k As Integer = 0 To key.Size - 1
		    w.UInt8Value(k) = key.UInt8Value(k)
		  Next
		  Dim rcon As Integer = 1
		  For i As Integer = nk To total - 1
		    Dim p As Integer = (i - 1) * 4
		    Dim t0 As Integer = w.UInt8Value(p)
		    Dim t1 As Integer = w.UInt8Value(p + 1)
		    Dim t2 As Integer = w.UInt8Value(p + 2)
		    Dim t3 As Integer = w.UInt8Value(p + 3)
		    If i Mod nk = 0 Then
		      // RotWord, SubWord, Rcon
		      Dim saved As Integer = t0
		      t0 = Bitwise.BitXor(sb.UInt8Value(t1), rcon)
		      t1 = sb.UInt8Value(t2)
		      t2 = sb.UInt8Value(t3)
		      t3 = sb.UInt8Value(saved)
		      rcon = AESXTime(rcon)
		    ElseIf nk > 6 And i Mod nk = 4 Then
		      // SubWord only (256-bit keys)
		      t0 = sb.UInt8Value(t0)
		      t1 = sb.UInt8Value(t1)
		      t2 = sb.UInt8Value(t2)
		      t3 = sb.UInt8Value(t3)
		    End If
		    Dim q As Integer = (i - nk) * 4
		    Dim d As Integer = i * 4
		    w.UInt8Value(d) = Bitwise.BitXor(w.UInt8Value(q), t0)
		    w.UInt8Value(d + 1) = Bitwise.BitXor(w.UInt8Value(q + 1), t1)
		    w.UInt8Value(d + 2) = Bitwise.BitXor(w.UInt8Value(q + 2), t2)
		    w.UInt8Value(d + 3) = Bitwise.BitXor(w.UInt8Value(q + 3), t3)
		  Next
		  Return w
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function AESSBox() As MemoryBlock
		  // The AES S-box (FIPS-197 figure 7), made once
		  If mAESSBox = Nil Then
		    Dim sb As MemoryBlock = DecodeHex(kAESSBox)
		    mAESSBox = sb
		  End If
		  Return mAESSBox
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function AESXTime(x As Integer) As Integer
		  // Multiplication by 2 in GF(2^8)
		  Dim x2 As Integer = x * 2
		  If x2 > 255 Then x2 = Bitwise.BitXor(x2, &h11B)
		  Return x2
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshAESXojoCheck() As String
		  // MeshAESCTRXojo against the AES-128 and AES-256 known answers of MeshCryptoSelfTest and MeshAES256Check.
		  // On desktop this checks the Android code path with the desktop compiler
		  Dim iv As MemoryBlock = DecodeHex("8877665500000000fecaad0b00000000")
		  Dim c128 As MemoryBlock = DecodeHex("3281cb865625d24ce295be2e632db2bee5ce42cc46193924a7c7cd32fddb378289dd4253bc6e39a6")
		  Dim c256 As MemoryBlock = DecodeHex("219127b0bf340c93000c9693b9adf0b4048335400dbcf7e09a9fe39265809817ef2b9b3d25d1ea")
		  Dim k128 As String = DecodeHex("d4f1bb3a20290759f0bcffabcf4e6901")
		  Dim k256 As String = DecodeHex("202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f")
		  Dim p128 As MemoryBlock = MeshAESCTRXojo(k128, c128, iv)
		  Dim p256 As MemoryBlock = MeshAESCTRXojo(k256, c256, iv)
		  If p128.Size <> c128.Size Or p256.Size <> c256.Size Then Return "Xojo AES FAILED (size)"
		  Dim h128 As String = EncodeHex(p128.StringValue(0, p128.Size))
		  Dim h256 As String = EncodeHex(p256.StringValue(0, p256.Size))
		  If h128 <> "4D657368746173746963204145532D4354522073656C662D746573742C203320626C6F636B732121" Then Return "Xojo AES-128 FAILED"
		  If h256 <> "4145532D323536204354522073656C662D746573742C20616C736F203320626C6F636B73212121" Then Return "Xojo AES-256 FAILED"
		  Return "Xojo AES OK"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshAESCTRXojo(key As String, data As MemoryBlock, iv As MemoryBlock) As MemoryBlock
		  // AES-CTR in plain Xojo, for Android, whose Crypto module has no AES. key: 16, 24 or 32 raw bytes; iv: the first
		  // counter block, incremented as one 16-byte big-endian number like Crypto++ does. Checked by the same known-answer
		  // tests as Crypto.AESDecrypt (MeshCryptoSelfTest, MeshAES256Check, MeshPKISelfTest). An empty MemoryBlock on bad input
		  If data = Nil Or iv = Nil Then Return New MemoryBlock(0)
		  If iv.Size < 16 Or data.Size = 0 Then Return New MemoryBlock(0)
		  Dim raw As String = MeshBin(key)
		  If raw.Bytes <> 16 And raw.Bytes <> 24 And raw.Bytes <> 32 Then Return New MemoryBlock(0)
		  Dim kb As MemoryBlock = raw
		  Dim rounds As Integer
		  Dim w As MemoryBlock = AESExpandKey(kb, rounds)
		  Dim n As Integer = data.Size
		  Dim result As New MemoryBlock(n)
		  Dim counter As New MemoryBlock(16)
		  For i As Integer = 0 To 15
		    counter.UInt8Value(i) = iv.UInt8Value(i)
		  Next
		  Dim blk As New MemoryBlock(16)
		  Dim pos As Integer = 0
		  While pos < n
		    For j As Integer = 0 To 15
		      blk.UInt8Value(j) = counter.UInt8Value(j)
		    Next
		    Call AESEncryptBlock(w, rounds, blk)
		    Dim lastByte As Integer = Min(16, n - pos) - 1
		    For k As Integer = 0 To lastByte
		      result.UInt8Value(pos + k) = Bitwise.BitXor(data.UInt8Value(pos + k), blk.UInt8Value(k))
		    Next
		    pos = pos + 16
		    For m As Integer = 15 DownTo 0
		      Dim v As Integer = counter.UInt8Value(m) + 1
		      If v < 256 Then
		        counter.UInt8Value(m) = v
		        Exit For
		      End If
		      counter.UInt8Value(m) = 0
		    Next
		  Wend
		  Return result
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshAES256Check() As String
		  // AES-256 known-answer test (openssl), for channels with 32-byte keys
		  Dim key As String = DecodeHex("202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f")
		  Dim iv As MemoryBlock = DecodeHex("8877665500000000fecaad0b00000000")
		  Dim cipher As MemoryBlock = DecodeHex("219127b0bf340c93000c9693b9adf0b4048335400dbcf7e09a9fe39265809817ef2b9b3d25d1ea")
		  Dim plain As MemoryBlock = MeshAESCTR(MeshAESKeyForm(key), cipher, iv)
		  If plain = Nil Then Return "AES-256 FAILED (exception)"
		  If plain.Size < cipher.Size Then Return "AES-256 FAILED (" + plain.Size.ToString + " bytes)"
		  Dim got As String = EncodeHex(plain.StringValue(0, cipher.Size))
		  If got = "4145532D323536204354522073656C662D746573742C20616C736F203320626C6F636B73212121" Then Return "AES-256 OK"
		  Return "AES-256 FAILED (wrong output)"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshAESBlock(key As String, block As MemoryBlock) As MemoryBlock
		  // One raw AES block encryption E(key, block), done as CTR over 16 zero bytes with the block as the counter
		  // (the CTR mode is the one MeshCryptoSelfTest verified; no padding questions). Nil on failure
		  Dim zeros As New MemoryBlock(16)
		  Dim result As MemoryBlock = MeshAESCTR(MeshAESKeyForm(key), zeros, block)
		  If result = Nil Or result.Size < 16 Then Return New MemoryBlock(0) // not Nil: see MeshAESCTR
		  Return result
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshAESCTR(key As String, data As MemoryBlock, iv As MemoryBlock) As MemoryBlock
		  // AES-CTR through Xojo's Crypto (Crypto++) on desktop, through MeshAESCTRXojo on Android (its Crypto has no AES).
		  // Nil (desktop) or an empty MemoryBlock (Android) on failure: on Android a MemoryBlock function must never return
		  // Nil, its result is converted and Nil throws
		  #If TargetAndroid Then
		    Return MeshAESCTRXojo(key, data, iv)
		  #Else
		    Try
		      Return Crypto.AESDecrypt(key, data, Crypto.BlockModes.CTR, iv)
		    Catch err As RuntimeException
		      Return Nil
		    End Try
		  #EndIf
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshAESKeyForm(key As String) As String
		  // The key in the form Crypto.AESDecrypt wants, as found by MeshCryptoSelfTest
		  key = MeshBin(key)
		  If mAESKeyMode = 2 Then
		    Dim lowerHex As String = EncodeHex(key)
		    Return lowerHex.Lowercase
		  ElseIf mAESKeyMode = 3 Then
		    Return EncodeHex(key)
		  End If
		  Return key
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshCCMDecrypt(key As String, nonce As String, cipherAndTag As String, ByRef plain As String) As Boolean
		  // Inverse of MeshCCMEncrypt: decrypts, recomputes the tag and compares. False if the tag doesn't match
		  plain = ""
		  key = MeshBin(key)
		  nonce = MeshBin(nonce)
		  cipherAndTag = MeshBin(cipherAndTag)
		  If cipherAndTag.Bytes < 8 Or nonce.Bytes <> 13 Then Return False
		  Dim n As Integer = cipherAndTag.Bytes - 8
		  Dim mb As MemoryBlock = ProtoRawBytes(cipherAndTag)
		  Dim candidate As String
		  If n > 0 Then
		    Dim a As New MemoryBlock(16)
		    a.UInt8Value(0) = 1
		    a.StringValue(1, 13) = ProtoRawBytes(nonce)
		    a.UInt8Value(15) = 1
		    Dim cipherPart As MemoryBlock = mb.StringValue(0, n) // a MemoryBlock variable: Android doesn't convert a String argument
		    Dim decrypted As MemoryBlock = MeshAESCTR(MeshAESKeyForm(key), cipherPart, a)
		    If decrypted = Nil Or decrypted.Size < n Then Return False
		    candidate = decrypted.StringValue(0, n)
		  End If
		  Dim check As String = MeshCCMEncrypt(key, nonce, candidate)
		  If check.Bytes <> cipherAndTag.Bytes Then Return False
		  If EncodeHex(check) <> EncodeHex(mb.StringValue(0, mb.Size)) Then Return False
		  plain = candidate
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshCCMEncrypt(key As String, nonce As String, plain As String) As String
		  // AES-CCM as the firmware uses it for PKI (aes-ccm.cpp): 13-byte nonce, L = 2, 8-byte tag, no associated data.
		  // Returns ciphertext + tag, "" on failure
		  key = MeshBin(key)
		  nonce = MeshBin(nonce)
		  plain = MeshBin(plain)
		  If nonce.Bytes <> 13 Or plain.Bytes > 65535 Then Return ""
		  Dim n As Integer = plain.Bytes
		  Dim p As New MemoryBlock(Max(n, 1))
		  If n > 0 Then p.StringValue(0, n) = ProtoRawBytes(plain)
		  // CBC-MAC over B_0 = flags (M' = 3, L' = 1) | nonce | length, then the zero-padded message
		  Dim b0 As New MemoryBlock(16)
		  b0.UInt8Value(0) = &h19
		  b0.StringValue(1, 13) = ProtoRawBytes(nonce)
		  b0.UInt8Value(14) = n \ 256
		  b0.UInt8Value(15) = n Mod 256
		  Dim x As MemoryBlock = MeshAESBlock(key, b0)
		  If x = Nil Or x.Size < 16 Then Return ""
		  Dim blockStart As Integer = 0
		  While blockStart < n
		    For i As Integer = 0 To 15
		      If blockStart + i < n Then x.UInt8Value(i) = Bitwise.BitXor(x.UInt8Value(i), p.UInt8Value(blockStart + i))
		    Next
		    x = MeshAESBlock(key, x)
		    If x = Nil Or x.Size < 16 Then Return ""
		    blockStart = blockStart + 16
		  Wend
		  // Counter blocks A_i = flags (L' = 1) | nonce | i: S_0 masks the tag, S_1... encrypt the message
		  Dim a As New MemoryBlock(16)
		  a.UInt8Value(0) = 1
		  a.StringValue(1, 13) = ProtoRawBytes(nonce)
		  Dim s0 As MemoryBlock = MeshAESBlock(key, a)
		  If s0 = Nil Or s0.Size < 16 Then Return ""
		  Dim cipher As String
		  If n > 0 Then
		    a.UInt8Value(15) = 1
		    Dim plainPart As MemoryBlock = p.StringValue(0, n) // a MemoryBlock variable: Android doesn't convert a String argument
		    Dim encrypted As MemoryBlock = MeshAESCTR(MeshAESKeyForm(key), plainPart, a)
		    If encrypted = Nil Or encrypted.Size < n Then Return ""
		    cipher = encrypted.StringValue(0, n)
		  End If
		  Dim tag As New MemoryBlock(8)
		  For t As Integer = 0 To 7
		    tag.UInt8Value(t) = Bitwise.BitXor(x.UInt8Value(t), s0.UInt8Value(t))
		  Next
		  Return MeshBin(cipher + tag.StringValue(0, 8))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub MeshClearConfigKeys()
		  mConfigKeys = New Dictionary
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshCryptoSelfTest() As String
		  // Known-answer test (made with openssl, 40 bytes = 3 counter blocks).
		  // Also finds out whether Crypto.AESDecrypt wants the key as raw bytes or as hex text.
		  Dim key As String = DecodeHex("d4f1bb3a20290759f0bcffabcf4e6901")
		  Dim iv As MemoryBlock = DecodeHex("8877665500000000fecaad0b00000000")
		  Dim cipher As MemoryBlock = DecodeHex("3281cb865625d24ce295be2e632db2bee5ce42cc46193924a7c7cd32fddb378289dd4253bc6e39a6")
		  Dim expectedHex As String = "4D657368746173746963204145532D4354522073656C662D746573742C203320626C6F636B732121"
		  Dim forms() As String
		  forms.Add(key)
		  Dim hexKey As String = EncodeHex(key)
		  forms.Add(hexKey.Lowercase)
		  forms.Add(hexKey)
		  Dim names() As String = Array("raw key", "lowercase hex key", "uppercase hex key")
		  Dim details As String
		  For i As Integer = 0 To forms.LastIndex
		    Dim plain As MemoryBlock = MeshAESCTR(forms(i), cipher, iv)
		    If plain = Nil Then
		      details = details + " " + names(i) + ": exception;"
		    ElseIf plain.Size < cipher.Size Then
		      details = details + " " + names(i) + ": " + plain.Size.ToString + " bytes;"
		    Else
		      Dim got As String = EncodeHex(plain.StringValue(0, cipher.Size))
		      If got = expectedHex Then
		        mAESKeyMode = i + 1
		        #If TargetAndroid Then
		          Return "AES-CTR self-test OK (" + names(i) + ", output " + plain.Size.ToString + " bytes), " + MeshAES256Check()
		        #Else
		          Return "AES-CTR self-test OK (" + names(i) + ", output " + plain.Size.ToString + " bytes), " + MeshAES256Check() + ", " + MeshAESXojoCheck()
		        #EndIf
		      End If
		      details = details + " " + names(i) + ": wrong output;"
		    End If
		  Next
		  mAESKeyMode = -1
		  Return "AES-CTR self-test FAILED:" + details
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshDecrypt(key As String, packetID As UInt32, fromNode As UInt32, cipher As String) As String
		  // Meshtastic channel decryption: AES-CTR, counter block = packetID (LE, 8 bytes) + fromNode (LE, 4 bytes) + 4 zero bytes
		  key = MeshBin(key)
		  cipher = MeshBin(cipher)
		  If key.Bytes = 0 Or cipher.Bytes = 0 Then Return ""
		  If mAESKeyMode = 0 Then Call MeshCryptoSelfTest()
		  If mAESKeyMode < 0 Then Return ""
		  Dim k As String = MeshAESKeyForm(key)
		  Dim nonce As New MemoryBlock(16)
		  nonce.LittleEndian = True
		  nonce.UInt32Value(0) = packetID
		  nonce.UInt32Value(8) = fromNode
		  Dim data As MemoryBlock = cipher
		  Dim plain As MemoryBlock = MeshAESCTR(k, data, nonce)
		  If plain = Nil Then Return ""
		  Dim n As Integer = Min(plain.Size, data.Size)
		  If n <= 0 Then Return ""
		  Return plain.StringValue(0, n)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshKnownKeyCount() As Integer
		  Dim n As Integer
		  If mConfigKeys <> Nil Then n = mConfigKeys.KeyCount
		  If mLearnedKeys <> Nil Then
		    For Each k As Variant In mLearnedKeys.Keys
		      If mConfigKeys = Nil Or Not mConfigKeys.HasKey(k) Then n = n + 1
		    Next
		  End If
		  Return n
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub MeshLearnPublicKey(nodeNum As UInt32, userPayload As String)
		  // Remembers the public key (User field 8, 32 bytes) of a NodeInfo, keeping the first one seen like the firmware does
		  If nodeNum = mPKINodeNum Then Return
		  Dim mb As MemoryBlock = ProtoRawBytes(MeshBin(userPayload))
		  If mb = Nil Then Return
		  Dim r As New ProtoReader(mb)
		  Dim field, wireType As Integer
		  While r.ReadTag(field, wireType)
		    If field = 8 And wireType = 2 Then
		      Dim key As String = r.ReadBytes()
		      If key.Bytes = 32 Then
		        If mLearnedKeys = Nil Then mLearnedKeys = New Dictionary
		        If Not mLearnedKeys.HasKey(nodeNum.ToString) Then mLearnedKeys.Value(nodeNum.ToString) = key
		      End If
		    Else
		      r.Skip(wireType)
		    End If
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPKIDecrypt(privateKey As String, publicKey As String, packetID As UInt32, fromNode As UInt32, encrypted As String, ByRef data As String) As Boolean
		  // Inverse of MeshPKIEncrypt (CryptoEngine::decryptCurve25519). False if keys or tag don't match
		  data = ""
		  encrypted = MeshBin(encrypted)
		  If encrypted.Bytes < 12 Then Return False
		  Dim key As String = MeshPKISharedKey(privateKey, publicKey)
		  If key = "" Then Return False
		  Dim mb As MemoryBlock = ProtoRawBytes(encrypted)
		  mb.LittleEndian = True
		  Dim extraNonce As UInt32 = mb.UInt32Value(mb.Size - 4)
		  Return MeshCCMDecrypt(key, MeshPKINonce(packetID, fromNode, extraNonce), mb.StringValue(0, mb.Size - 4), data)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPKIEncrypt(privateKey As String, publicKey As String, packetID As UInt32, fromNode As UInt32, extraNonce As UInt32, data As String) As String
		  // PKI direct message encryption (CryptoEngine::encryptCurve25519): AES-256-CCM with the shared key,
		  // result = ciphertext | tag (8) | extraNonce (4, LE). "" on failure
		  Dim key As String = MeshPKISharedKey(privateKey, publicKey)
		  If key = "" Then Return ""
		  Dim sealed As String = MeshCCMEncrypt(key, MeshPKINonce(packetID, fromNode, extraNonce), data)
		  If sealed = "" Then Return ""
		  Dim extra As New MemoryBlock(4)
		  extra.LittleEndian = True
		  extra.UInt32Value(0) = extraNonce
		  Return MeshBin(sealed + extra.StringValue(0, 4))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPKINodeNum() As UInt32
		  // Our own node number for PKI (0 when PKI is off)
		  Return mPKINodeNum
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPKINonce(packetID As UInt32, fromNode As UInt32, extraNonce As UInt32) As String
		  // The firmware's initNonce for PKI: packet id (LE), extraNonce (LE) over the id's upper half, from (LE); CCM uses 13 bytes
		  Dim nonce As New MemoryBlock(16)
		  nonce.LittleEndian = True
		  nonce.UInt32Value(0) = packetID
		  nonce.UInt32Value(4) = extraNonce
		  nonce.UInt32Value(8) = fromNode
		  Return nonce.StringValue(0, 13)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPKIOpen(publicKey As String, packetID As UInt32, fromNode As UInt32, encrypted As String, ByRef data As String) As Boolean
		  // Decrypts a PKI direct message exchanged with the node with publicKey, with our private key
		  data = ""
		  If Not MeshPKIReady() Then Return False
		  Return MeshPKIDecrypt(mPKIPrivateKey, publicKey, packetID, fromNode, encrypted, data)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPKIPublicKey() As String
		  // Our public key ("" when PKI is off), sent in our NodeInfo so that nodes can decrypt our DMs
		  Return mPKIPublicKey
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPKIReady() As Boolean
		  // True when our node has a private key, so PKI direct messages can be sent and read
		  Return mPKIPrivateKey.Bytes = 32
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPKISeal(publicKey As String, packetID As UInt32, fromNode As UInt32, data As String) As String
		  // Encrypts a Data message for the node with publicKey, with our private key (which never leaves this module)
		  // and a random extraNonce. "" on failure
		  If Not MeshPKIReady() Then Return ""
		  Return MeshPKIEncrypt(mPKIPrivateKey, publicKey, packetID, fromNode, MeshNewPacketID(), data)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPKISelfTest() As String
		  // X25519 against RFC 7748 section 6.1, and a full PKI encryption against a vector made with Python's cryptography
		  // (X25519 + SHA-256 + AES-256-CCM, the firmware's nonce), plus the decryption back
		  Dim failures() As String
		  Dim alicePrivate As String = DecodeHex("77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a")
		  Dim bobPublic As String = DecodeHex("de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f")
		  If EncodeHex(X25519PublicKey(alicePrivate)) <> "8520F0098930A754748B7DDCB43EF75A0DBF3A0D26381AF4EBA4A98EAA9B4E6A" Then failures.Add("X25519 public key")
		  If EncodeHex(X25519(alicePrivate, bobPublic)) <> "4A5D9D5BA4CE2DE1728E3BF480350F25E07E21C947D19E3376F09B3C1E161742" Then failures.Add("X25519 shared secret")
		  Dim privA As String = DecodeHex("0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20")
		  Dim pubB As String = DecodeHex("5714769d116bf76436ae74bc793d2c30ad1903c59ac5273805c7e2698b410c36")
		  Dim data As String = DecodeHex("0801120b504b492073656c662d7465")
		  Dim sealed As String = MeshPKIEncrypt(privA, pubB, &h13572468, &h00C0FFEE, &h0A0B0C0D, data)
		  If EncodeHex(sealed) <> "1D7FB42D7FCE5A5AC139D21173904D22EC272A7EE539BF0D0C0B0A" Then failures.Add("PKI encryption")
		  Dim back As String
		  Dim privB As String = DecodeHex("65666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f8081828384") // a String variable: DecodeHex gives a MemoryBlock on Android
		  If Not MeshPKIDecrypt(privB, X25519PublicKey(privA), &h13572468, &h00C0FFEE, sealed, back) Or EncodeHex(back) <> EncodeHex(data) Then failures.Add("PKI decryption")
		  If failures.Count = 0 Then Return "PKI self-test OK (X25519 RFC 7748, AES-256-CCM)"
		  Return "PKI self-test FAILED: " + String.FromArray(failures, ", ")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPKISharedKey(privateKey As String, publicKey As String) As String
		  // SHA-256 of the X25519 shared secret (CryptoEngine::setDHPublicKey + hash). "" on bad keys
		  If privateKey.Bytes <> 32 Or publicKey.Bytes <> 32 Then Return ""
		  Dim sharedSecret As String = X25519(privateKey, publicKey)
		  If sharedSecret.Bytes <> 32 Then Return ""
		  If EncodeHex(sharedSecret) = "0000000000000000000000000000000000000000000000000000000000000000" Then Return ""
		  Dim sharedMB As MemoryBlock = sharedSecret
		  Dim digest As MemoryBlock = Crypto.SHA2_256(sharedMB)
		  Return digest.StringValue(0, 32)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPKIStatus() As String
		  If mPKIPrivateKey = "" Then
		    Dim fresh As MemoryBlock = Crypto.GenerateRandomBytes(32)
		    Return "PKI direct messages off: add ""private_key"": """ + EncodeBase64(fresh.StringValue(0, 32), 0) + """ (a fresh random key) to the node section of MQTT_Xojo.config.json"
		  End If
		  Return "PKI on: public key " + EncodeBase64(mPKIPublicKey, 0) + ", " + MeshKnownKeyCount().ToString + " recipient key(s) known"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPublicKeyFor(nodeNum As UInt32) As String
		  // A node's public key: from the configuration first, otherwise learned from its NodeInfo. "" if unknown
		  Dim k As String = nodeNum.ToString
		  If mConfigKeys <> Nil And mConfigKeys.HasKey(k) Then Return mConfigKeys.Value(k).StringValue
		  If mLearnedKeys <> Nil And mLearnedKeys.HasKey(k) Then Return mLearnedKeys.Value(k).StringValue
		  Return ""
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshSetPKIIdentity(nodeNum As UInt32, privateKey As String) As Boolean
		  // Our (virtual) node's Curve25519 key pair, for PKI direct messages. "" turns PKI off. False on a bad key
		  mPKINodeNum = 0
		  mPKIPrivateKey = ""
		  mPKIPublicKey = ""
		  If privateKey.Bytes = 0 Then Return True
		  If privateKey.Bytes <> 32 Then Return False
		  Dim publicKey As String = X25519PublicKey(privateKey)
		  If publicKey.Bytes <> 32 Then Return False
		  mPKINodeNum = nodeNum
		  mPKIPrivateKey = privateKey
		  mPKIPublicKey = publicKey
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub MeshSetPublicKey(nodeNum As UInt32, publicKey As String)
		  // A recipient's public key from the configuration
		  If mConfigKeys = Nil Then mConfigKeys = New Dictionary
		  mConfigKeys.Value(nodeNum.ToString) = publicKey
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h21
		Private mAESSBox As MemoryBlock
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mAESKeyMode As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mConfigKeys As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLearnedKeys As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPKINodeNum As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPKIPrivateKey As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPKIPublicKey As String
	#tag EndProperty


	#tag Constant, Name = kAESSBox, Type = String, Dynamic = False, Default = \"637c777bf26b6fc53001672bfed7ab76ca82c97dfa5947f0add4a2af9ca472c0b7fd9326363ff7cc34a5e5f171d8311504c723c31896059a071280e2eb27b27509832c1a1b6e5aa0523bd6b329e32f8453d100ed20fcb15b6acbbe394a4c58cfd0efaafb434d338545f9027f503c9fa851a3408f929d38f5bcb6da2110fff3d2cd0c13ec5f974417c4a77e3d645d197360814fdc222a908846eeb814de5e0bdbe0323a0a4906245cc2d3ac629195e479e7c8376d8dd54ea96c56f4ea657aae08ba78252e1ca6b4c6e8dd741f4bbd8b8a703eb5664803f60e613557b986c11d9ee1f8981169d98e949b1e87e9ce5528df8ca1890dbfe6426841992d0fb054bb16", Scope = Private
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
End Module
#tag EndModule
