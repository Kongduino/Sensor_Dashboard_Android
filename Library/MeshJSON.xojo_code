#tag Module
Protected Module MeshJSON
	#tag Method, Flags = &h0
		Function MeshSameText(a As String, b As String) As Boolean
		  // Case-sensitive equality on every platform (StrComp doesn't exist on Android)
		  If a.Bytes <> b.Bytes Then Return False
		  Return a.Compare(b, ComparisonOptions.CaseSensitive) = 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshExactDigits(d As Double, ByRef digits As String, ByRef pointPos As Integer, ByRef negative As Boolean) As Boolean
		  // Exact decimal expansion of a Double (finite, since it is mantissa * 2^e2): value = 0.digits * 10^pointPos,
		  // first digit non-zero, digits = "" for zero. False if it doesn't fit in 64-bit arithmetic (|d| < ~1e-11 or > 9e18)
		  Dim bits As New MemoryBlock(8)
		  bits.LittleEndian = True
		  bits.DoubleValue(0) = d
		  Dim raw As UInt64 = bits.UInt64Value(0)
		  negative = (Bitwise.ShiftRight(raw, 63) = 1)
		  Dim expRaw As UInt64 = Bitwise.ShiftRight(raw, 52) // not inside CType: Android's translation loses the argument
		  Dim expBits As Integer = CType(expRaw And 2047, Integer)
		  Dim mantissa As UInt64 = raw - Bitwise.ShiftLeft(Bitwise.ShiftRight(raw, 52), 52)
		  digits = ""
		  pointPos = 0
		  Dim e2 As Integer
		  If expBits = 0 Then
		    If mantissa = 0 Then Return True
		    e2 = -1074
		  Else
		    mantissa = mantissa + Bitwise.ShiftLeft(1, 52)
		    e2 = expBits - 1075
		  End If
		  While (mantissa And 1) = 0
		    mantissa = Bitwise.ShiftRight(mantissa, 1)
		    e2 = e2 + 1
		  Wend
		  Dim bitLength As Integer = 0
		  Dim m As UInt64 = mantissa
		  While m > 0
		    m = Bitwise.ShiftRight(m, 1)
		    bitLength = bitLength + 1
		  Wend
		  Dim intPart As UInt64
		  Dim frac As String
		  If e2 >= 0 Then
		    If bitLength + e2 > 63 Then Return False
		    intPart = Bitwise.ShiftLeft(mantissa, e2)
		  Else
		    Dim k As Integer = -e2
		    If k > 59 Then Return False
		    intPart = Bitwise.ShiftRight(mantissa, k)
		    Dim r As UInt64 = mantissa - Bitwise.ShiftLeft(intPart, k)
		    Dim fracDigits() As String
		    While r > 0
		      r = r * 10
		      Dim digit As UInt64 = Bitwise.ShiftRight(r, k)
		      fracDigits.Add(digit.ToString)
		      r = r - Bitwise.ShiftLeft(digit, k)
		    Wend
		    frac = String.FromArray(fracDigits, "")
		  End If
		  Dim intDigits As String
		  If intPart > 0 Then intDigits = intPart.ToString
		  digits = intDigits + frac
		  pointPos = intDigits.Length
		  While digits.Left(1) = "0"
		    digits = digits.Middle(1, digits.Length - 1)
		    pointPos = pointPos - 1
		  Wend
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshHardwareJSON(payload As String, ByRef typeName As String) As String
		  // REMOTE_HARDWARE_APP: only GPIOS_CHANGED (3) and READ_GPIOS_REPLY (5) are converted
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
		  If r.Failed Then Return ""
		  Dim keys(), values() As String
		  If msgType = 3 Then
		    typeName = "gpios_changed"
		    MeshJSONAdd(keys, values, "gpio_value", gpioValue.ToString)
		  ElseIf msgType = 5 Then
		    typeName = "gpios_read_reply"
		    MeshJSONAdd(keys, values, "gpio_value", gpioValue.ToString)
		    MeshJSONAdd(keys, values, "gpio_mask", mask.ToString)
		  Else
		    Return ""
		  End If
		  Return MeshJSONObject(keys, values)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub MeshJSONAdd(keys() As String, values() As String, key As String, value As String)
		  // Adds one member to a JSON object under construction (value is already JSON)
		  keys.Add(key)
		  values.Add(value)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshJSONArray(values() As String) As String
		  Return "[" + String.FromArray(values, ",") + "]"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshJSONDefault(kind As String) As String
		  // JSON for a proto3 field that is absent (default value)
		  Select Case kind
		  Case "f", "c"
		    Return "0.0"
		  Case "t"
		    Return """"""
		  Else
		    Return "0"
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshJSONEscape(codeUnit As Integer) As String
		  // \uxxxx with lowercase hex, as Python writes it
		  Dim h As String = "000" + Hex(codeUnit)
		  h = h.Right(4).Lowercase
		  Return "\u" + h
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshJSONFloat(d As Double) As String
		  // A float as Python's repr() / json.dumps writes it: the shortest digits that read back to the same Double
		  If d.IsNotANumber Then Return "NaN"
		  If d.IsInfinite Then
		    If d > 0 Then Return "Infinity"
		    Return "-Infinity"
		  End If
		  Dim best As String
		  Dim bestExp As Integer
		  Dim negative As Boolean
		  If Not MeshShortestDigits(d, False, best, bestExp, negative) Then Return d.ToString(Locale.Raw)
		  If best = "" Then
		    If negative Then Return "-0.0"
		    Return "0.0"
		  End If
		  Return MeshReprFormat(best, bestExp, negative)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshJSONFromItem(item As JSONItem) As String
		  // A parsed JSONItem (object or array) back to JSON in Python's format (sorted keys, compact)
		  If item.IsArray Then
		    Dim elements() As String
		    For i As Integer = 0 To item.Count - 1
		      elements.Add(MeshJSONFromVariant(item.ValueAt(i)))
		    Next
		    Return MeshJSONArray(elements)
		  End If
		  Dim keys(), values() As String
		  For Each key As String In item.Keys
		    MeshJSONAdd(keys, values, key, MeshJSONFromVariant(item.Value(key)))
		  Next
		  Return MeshJSONObject(keys, values)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshJSONFromVariant(v As Variant) As String
		  // A value from a parsed JSONItem, back to JSON in Python's format
		  If v.IsNull Then Return "null"
		  Select Case v.Type
		  Case Variant.TypeBoolean
		    If v.BooleanValue Then Return "true"
		    Return "false"
		  Case Variant.TypeInt32, Variant.TypeInt64
		    Return v.Int64Value.ToString
		  Case Variant.TypeDouble, Variant.TypeSingle
		    Return MeshJSONFloat(v.DoubleValue)
		  Case Variant.TypeObject
		    If v.ObjectValue IsA JSONItem Then Return MeshJSONFromItem(JSONItem(v.ObjectValue))
		  End Select
		  Return MeshJSONString(v.StringValue)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshJSONObject(keys() As String, values() As String) As String
		  // {"key":value,...} compact, keys sorted by code point like Python's sort_keys
		  // (sorting the hex of the UTF-8 bytes gives byte order, independent of case and locale)
		  Dim sortKeys() As String
		  For Each k As String In keys
		    sortKeys.Add(EncodeHex(k))
		  Next
		  sortKeys.SortWith(keys, values)
		  Dim members() As String
		  For i As Integer = 0 To keys.LastIndex
		    members.Add(MeshJSONString(keys(i)) + ":" + values(i))
		  Next
		  Return "{" + String.FromArray(members, ",") + "}"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshJSONSelfTest() As String
		  // Float formatting checked against Python's repr() (expected values generated with Python),
		  // plus the Val() round trip it relies on
		  Dim cases() As String = Array("4081999a=4.050000190734863", "3eb33333=0.3499999940395355", "4274cccd=61.20000076293945", "447d1333=1012.2999877929688", "3727c5ac=9.999999747378752e-06", "47f1205a=123456.703125", "c0e80000=-7.25", "43af0000=350.0", "4149999a=12.600000381469727", "40a0a3d7=5.019999980926514", "38d1b717=9.999999747378752e-05", "2edbe6ff=1.000000013351432e-10", "80000000=-0.0", "40c00000=6.0", "3ff851eb851eb852=1.52", "3fef5c28f5c28f5c=0.98", "3f847ae147ae147b=0.01", "3fe8000000000000=0.75", "4341c37937e08000=1e+16", "434aa535d3d0c000=1.5e+16", "4341c37937e07fff=9999999999999998.0", "3fb999999999999a=0.1", "3fd3333333333334=0.30000000000000004", "4019000000000000=6.25", "c040000000000000=-32.0", "430c6bf526340000=1000000000000000.0", "419d6f3454800000=123456789.125")
		  Dim failures() As String
		  For Each c As String In cases
		    Dim cols() As String = c.Split("=")
		    Dim bits As MemoryBlock = DecodeHex(cols(0))
		    Dim d As Double
		    If bits.Size = 4 Then
		      bits.LittleEndian = False
		      d = bits.SingleValue(0)
		    Else
		      bits.LittleEndian = False
		      d = bits.DoubleValue(0)
		    End If
		    Dim got As String = MeshJSONFloat(d)
		    If Not MeshSameText(got, cols(1)) Then failures.Add(cols(1) + " gave " + got)
		  Next
		  If failures.Count = 0 Then Return "JSON float self-test OK (" + cases.Count.ToString + " values)"
		  Return "JSON float self-test FAILED: " + String.FromArray(failures, "; ")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshJSONString(s As String) As String
		  // JSON string as Python's json.dumps writes it (ensure_ascii): only printable ASCII as is,
		  // everything else as \uxxxx (surrogate pairs above U+FFFF). Invalid UTF-8 bytes are dropped
		  Dim pieces() As String
		  pieces.Add("""")
		  If s.Bytes > 0 Then
		    Dim mb As MemoryBlock = s
		    Dim pos, cp, startPos, length As Integer
		    While MeshUTF8Next(mb, pos, cp, startPos, length)
		      Select Case cp
		      Case 34
		        pieces.Add("\""")
		      Case 92
		        pieces.Add("\\")
		      Case 8
		        pieces.Add("\b")
		      Case 12
		        pieces.Add("\f")
		      Case 10
		        pieces.Add("\n")
		      Case 13
		        pieces.Add("\r")
		      Case 9
		        pieces.Add("\t")
		      Else
		        If cp >= 32 And cp <= 126 Then
		          pieces.Add(mb.StringValue(startPos, 1))
		        ElseIf cp < &h10000 Then
		          pieces.Add(MeshJSONEscape(cp))
		        Else
		          Dim v As Integer = cp - &h10000
		          pieces.Add(MeshJSONEscape(&hD800 + Bitwise.ShiftRight(v, 10)))
		          pieces.Add(MeshJSONEscape(&hDC00 + (v And &h3FF)))
		        End If
		      End Select
		    Wend
		  End If
		  pieces.Add("""")
		  Dim result As String = String.FromArray(pieces, "")
		  Return result.DefineEncoding(Encodings.ASCII)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshMessageJSON(r As ProtoReader, spec As String) As String
		  // Decodes a message into a JSON object using a spec "number:name:type:gate,..."
		  // type: f float, u unsigned varint, i int32 varint, x fixed32, s sfixed32, t string, c hundredths (varint / 100)
		  // gate: a = always (default value if absent), p = only if present, n = only if present and non-zero
		  // Returns "" if malformed. Fields not in the spec are skipped
		  If r = Nil Then Return ""
		  Dim nums() As Integer
		  Dim names(), kinds(), gates(), values() As String
		  Dim present(), nonZero() As Boolean
		  If spec <> "" Then
		    For Each entry As String In spec.Split(",")
		      Dim cols() As String = entry.Split(":")
		      nums.Add(cols(0).ToInteger())
		      names.Add(cols(1))
		      kinds.Add(cols(2))
		      gates.Add(cols(3))
		      values.Add("")
		      present.Add(False)
		      nonZero.Add(False)
		    Next
		  End If
		  Dim field, wireType As Integer
		  While r.ReadTag(field, wireType)
		    Dim idx As Integer = nums.IndexOf(field)
		    If idx < 0 Then
		      r.Skip(wireType)
		      Continue
		    End If
		    Select Case kinds(idx)
		    Case "f"
		      If wireType <> 5 Then Return ""
		      Dim fv As Double = r.ReadFloat
		      values(idx) = MeshJSONFloat(fv)
		      nonZero(idx) = (fv <> 0)
		    Case "u", "c"
		      If wireType <> 0 Then Return ""
		      Dim uv As UInt64 = r.ReadVarint()
		      If kinds(idx) = "c" Then
		        Dim hv As Double = uv / 100
		        values(idx) = MeshJSONFloat(hv)
		      Else
		        values(idx) = uv.ToString
		      End If
		      nonZero(idx) = (uv <> 0)
		    Case "i"
		      If wireType <> 0 Then Return ""
		      Dim iv As Int32 = r.ReadInt32
		      values(idx) = iv.ToString
		      nonZero(idx) = (iv <> 0)
		    Case "x"
		      If wireType <> 5 Then Return ""
		      Dim xv As UInt32 = r.ReadFixed32
		      values(idx) = xv.ToString
		      nonZero(idx) = (xv <> 0)
		    Case "s"
		      If wireType <> 5 Then Return ""
		      Dim sv As Int32 = r.ReadSFixed32
		      values(idx) = sv.ToString
		      nonZero(idx) = (sv <> 0)
		    Case "t"
		      If wireType <> 2 Then Return ""
		      Dim tv As String = r.ReadString
		      values(idx) = MeshJSONString(tv)
		      nonZero(idx) = (tv.Bytes > 0)
		    End Select
		    present(idx) = True
		  Wend
		  If r.Failed Then Return ""
		  Dim keys(), jsonValues() As String
		  For i As Integer = 0 To nums.LastIndex
		    Select Case gates(i)
		    Case "a"
		      If present(i) Then
		        MeshJSONAdd(keys, jsonValues, names(i), values(i))
		      Else
		        MeshJSONAdd(keys, jsonValues, names(i), MeshJSONDefault(kinds(i)))
		      End If
		    Case "p"
		      If present(i) Then MeshJSONAdd(keys, jsonValues, names(i), values(i))
		    Case "n"
		      If present(i) And nonZero(i) Then MeshJSONAdd(keys, jsonValues, names(i), values(i))
		    End Select
		  Next
		  Return MeshJSONObject(keys, jsonValues)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshNeighborInfoJSON(payload As String) As String
		  // NEIGHBORINFO_APP: neighbors as {"node_id", "snr"} with snr truncated to an integer, like int() in Python
		  Dim mb As MemoryBlock = payload
		  Dim r As New ProtoReader(mb)
		  Dim field, wireType As Integer
		  Dim nodeID, lastSentBy, interval As UInt32
		  Dim neighbors() As String
		  While r.ReadTag(field, wireType)
		    Select Case field
		    Case 1, 2, 3
		      If wireType <> 0 Then Return ""
		      Dim v As UInt32 = CType(r.ReadVarint(), UInt32)
		      If field = 1 Then
		        nodeID = v
		      ElseIf field = 2 Then
		        lastSentBy = v
		      Else
		        interval = v
		      End If
		    Case 4
		      If wireType <> 2 Then Return ""
		      Dim n As ProtoReader = r.ReadMessage
		      If n = Nil Then Return ""
		      Dim neighborID As UInt32
		      Dim snr As Double
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
		      If n.Failed Then Return ""
		      Dim snrInt As Int64
		      If snr >= 0 Then
		        snrInt = CType(Floor(snr), Int64)
		      Else
		        snrInt = CType(Ceiling(snr), Int64)
		      End If
		      Dim nKeys(), nValues() As String
		      MeshJSONAdd(nKeys, nValues, "node_id", neighborID.ToString)
		      MeshJSONAdd(nKeys, nValues, "snr", snrInt.ToString)
		      neighbors.Add(MeshJSONObject(nKeys, nValues))
		    Else
		      r.Skip(wireType)
		    End Select
		  Wend
		  If r.Failed Then Return ""
		  Dim keys(), values() As String
		  MeshJSONAdd(keys, values, "node_id", nodeID.ToString)
		  MeshJSONAdd(keys, values, "node_broadcast_interval_secs", interval.ToString)
		  MeshJSONAdd(keys, values, "last_sent_by_id", lastSentBy.ToString)
		  MeshJSONAdd(keys, values, "neighbors_count", neighbors.Count.ToString)
		  MeshJSONAdd(keys, values, "neighbors", MeshJSONArray(neighbors))
		  Return MeshJSONObject(keys, values)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPacketJSON(packetID As UInt32, fromNode As UInt32, toNode As UInt32, channel As UInt32, rxTime As UInt32, rxSnr As Single, rxRssi As Int32, hopLimit As UInt32, hopStart As UInt32, gatewayID As String, portnum As Integer, payload As String, requestID As UInt32) As String
		  // The JSON mqtt-converter's convert_to_json() publishes (the former firmware JSON format). "" when it publishes nothing
		  Dim typeName As String
		  Dim payloadJSON As String = MeshPayloadJSON(portnum, payload, fromNode, toNode, requestID, typeName)
		  If payloadJSON = "" Or typeName = "" Then Return ""
		  Dim keys(), values() As String
		  MeshJSONAdd(keys, values, "id", packetID.ToString)
		  MeshJSONAdd(keys, values, "timestamp", rxTime.ToString)
		  MeshJSONAdd(keys, values, "to", toNode.ToString)
		  MeshJSONAdd(keys, values, "from", fromNode.ToString)
		  MeshJSONAdd(keys, values, "channel", channel.ToString)
		  If gatewayID <> "" Then
		    MeshJSONAdd(keys, values, "sender", MeshJSONString(gatewayID))
		  Else
		    MeshJSONAdd(keys, values, "sender", MeshJSONString(MeshHexID(fromNode)))
		  End If
		  MeshJSONAdd(keys, values, "type", MeshJSONString(typeName))
		  If rxRssi <> 0 Then MeshJSONAdd(keys, values, "rssi", rxRssi.ToString)
		  If rxSnr <> 0 Then MeshJSONAdd(keys, values, "snr", MeshJSONFloat(rxSnr))
		  If hopStart <> 0 And hopLimit <= hopStart Then
		    Dim hopsAway As UInt32 = hopStart - hopLimit
		    MeshJSONAdd(keys, values, "hops_away", hopsAway.ToString)
		    MeshJSONAdd(keys, values, "hop_start", hopStart.ToString)
		  End If
		  MeshJSONAdd(keys, values, "payload", payloadJSON)
		  Return MeshJSONObject(keys, values)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshPayloadJSON(portnum As Integer, payload As String, fromNode As UInt32, toNode As UInt32, requestID As UInt32, ByRef typeName As String) As String
		  // The "payload" part of the converter's JSON and its "type". "" when the converter publishes nothing
		  typeName = ""
		  Dim mb As MemoryBlock
		  Select Case portnum
		  Case 1
		    typeName = "text"
		    Return MeshTextJSON(payload)
		  Case 3
		    typeName = "position"
		    mb = payload
		    Dim positionJSON As String = MeshMessageJSON(New ProtoReader(mb), "4:time:x:n,7:timestamp:x:n,1:latitude_i:s:a,2:longitude_i:s:a,3:altitude:i:n,15:ground_speed:u:n,16:ground_track:u:n,19:sats_in_view:u:n,11:PDOP:u:n,12:HDOP:u:n,13:VDOP:u:n,23:precision_bits:u:n")
		    If positionJSON = "" Then Return "{}"
		    Return positionJSON
		  Case 4
		    typeName = "nodeinfo"
		    mb = payload
		    Return MeshMessageJSON(New ProtoReader(mb), "1:id:t:a,2:longname:t:a,3:shortname:t:a,5:hardware:u:a,7:role:u:a")
		  Case 67
		    typeName = "telemetry"
		    Return MeshTelemetryJSON(payload)
		  Case 8
		    typeName = "waypoint"
		    mb = payload
		    Return MeshMessageJSON(New ProtoReader(mb), "1:id:u:a,6:name:t:a,7:description:t:a,4:expire:u:a,5:locked_to:u:a,2:latitude_i:s:a,3:longitude_i:s:a")
		  Case 71
		    typeName = "neighborinfo"
		    Return MeshNeighborInfoJSON(payload)
		  Case 70
		    // only replies are converted
		    If requestID = 0 Then Return ""
		    typeName = "traceroute"
		    Return MeshTracerouteJSON(payload, fromNode, toNode)
		  Case 10
		    typeName = "detection"
		    Dim keys(), values() As String
		    MeshJSONAdd(keys, values, "text", MeshJSONString(payload))
		    Return MeshJSONObject(keys, values)
		  Case 34
		    typeName = "paxcounter"
		    mb = payload
		    Return MeshMessageJSON(New ProtoReader(mb), "1:wifi_count:u:a,2:ble_count:u:a,3:uptime:u:a")
		  Case 2
		    Return MeshHardwareJSON(payload, typeName)
		  Else
		    Return ""
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshReprFormat(best As String, bestExp As Integer, negative As Boolean) As String
		  // Python repr() layout: fixed notation when -4 <= exponent < 16 ("350.0", "0.35"), otherwise "1e-05", "1.5e+16"
		  Dim n As Integer = best.Length
		  Dim result As String
		  If bestExp >= -4 And bestExp < 16 Then
		    If bestExp >= 0 Then
		      If n <= bestExp + 1 Then
		        result = best + MeshZeros(bestExp + 1 - n) + ".0"
		      Else
		        result = best.Left(bestExp + 1) + "." + best.Middle(bestExp + 1, n - bestExp - 1)
		      End If
		    Else
		      result = "0." + MeshZeros(-bestExp - 1) + best
		    End If
		  Else
		    result = best.Left(1)
		    If n > 1 Then result = result + "." + best.Middle(1, n - 1)
		    Dim expDigits As String = Str(Abs(bestExp))
		    If expDigits.Length < 2 Then expDigits = "0" + expDigits
		    If bestExp < 0 Then
		      result = result + "e-" + expDigits
		    Else
		      result = result + "e+" + expDigits
		    End If
		  End If
		  If negative Then result = "-" + result
		  Return result
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshRoundDigits(digits As String, p As Integer, up As Boolean, ByRef exp10 As Integer) As String
		  // First p digits, plus one in the last place if up. A carry (999 -> 1000) moves exp10 up by one
		  Dim headDigits As String = digits.Left(p)
		  Dim v As Int64 = headDigits.ToInt64
		  If up Then v = v + 1
		  Dim s As String = v.ToString
		  If s.Length > p Then
		    s = s.Left(p)
		    exp10 = exp10 + 1
		  End If
		  Return s
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshShortestDigits(d As Double, asSingle As Boolean, ByRef best As String, ByRef bestExp As Integer, ByRef negative As Boolean) As Boolean
		  // The shortest digits that read back to the same value: value = best[0].best[1..] * 10^bestExp.
		  // asSingle: the same Single (float32) instead of the same Double. Nearest digits first, ties to even, then the
		  // other neighbour, as Python's repr() does. best = "" for zero. False if outside MeshExactDigits' range
		  Dim digits As String
		  Dim pointPos As Integer
		  If Not MeshExactDigits(d, digits, pointPos, negative) Then Return False
		  best = digits
		  bestExp = pointPos - 1
		  If digits = "" Then Return True
		  Dim target As Double = Abs(d)
		  Dim targetSingle As Single = target
		  Dim maxP As Integer = 17
		  If asSingle Then maxP = 9
		  maxP = Min(maxP, digits.Length)
		  For p As Integer = 1 To maxP
		    Dim nearestUp As Boolean = False
		    If digits.Length > p Then
		      Dim nextDigit As Integer = digits.Middle(p, 1).ToInteger()
		      If nextDigit > 5 Then
		        nearestUp = True
		      ElseIf nextDigit = 5 Then
		        Dim rest As String = digits.Middle(p + 1, digits.Length - p - 1)
		        Dim restZero As Boolean = True
		        For i As Integer = 0 To rest.Length - 1
		          If rest.Middle(i, 1) <> "0" Then
		            restZero = False
		            Exit For
		          End If
		        Next
		        If restZero Then
		          nearestUp = (digits.Middle(p - 1, 1).ToInteger() Mod 2 = 1)
		        Else
		          nearestUp = True
		        End If
		      End If
		    End If
		    For attempt As Integer = 0 To 1
		      If attempt = 1 And digits.Length <= p Then Exit For
		      Dim up As Boolean = nearestUp
		      If attempt = 1 Then up = Not nearestUp
		      Dim candExp As Integer = pointPos - 1
		      Dim candidate As String = MeshRoundDigits(digits, p, up, candExp)
		      Dim back As Double = Val("0." + candidate + "e" + Str(candExp + 1))
		      Dim backSingle As Single = back
		      If (asSingle And backSingle = targetSingle) Or (Not asSingle And back = target) Then
		        best = candidate
		        bestExp = candExp
		        While best.Length > 1 And best.Right(1) = "0"
		          best = best.Left(best.Length - 1)
		        Wend
		        Return True
		      End If
		    Next
		  Next
		  While best.Length > 1 And best.Right(1) = "0"
		    best = best.Left(best.Length - 1)
		  Wend
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshTelemetryJSON(payload As String) As String
		  // TELEMETRY_APP. "" if malformed (the converter then publishes nothing), {} if no known variant
		  Dim mb As MemoryBlock = payload
		  Dim r As New ProtoReader(mb)
		  Dim field, wireType As Integer
		  Dim result As String = "{}"
		  While r.ReadTag(field, wireType)
		    If field >= 2 And field <= 8 And wireType = 2 Then
		      Dim metrics As ProtoReader = r.ReadMessage
		      result = MeshMessageJSON(metrics, MeshTelemetryJSONSpec(field))
		      If result = "" Then Return ""
		    Else
		      r.Skip(wireType)
		    End If
		  Wend
		  If r.Failed Then Return ""
		  Return result
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshTelemetryJSONSpec(variant As Integer) As String
		  // The fields convert_telemetry() emits per variant, in MeshMessageJSON spec format.
		  // device: battery_level only if present, the rest always; environment, air quality, power: only if present;
		  // host: only if non-zero, loads / 100. local_stats and health are not converted (empty payload)
		  Select Case variant
		  Case 2 // DeviceMetrics
		    Return "1:battery_level:u:p,2:voltage:f:a,3:channel_utilization:f:a,4:air_util_tx:f:a,5:uptime_seconds:u:a"
		  Case 3 // EnvironmentMetrics
		    Return "1:temperature:f:p,2:relative_humidity:f:p,3:barometric_pressure:f:p,4:gas_resistance:f:p,5:voltage:f:p,6:current:f:p,7:iaq:u:p,8:distance:f:p,9:lux:f:p,10:white_lux:f:p,11:ir_lux:f:p,12:uv_lux:f:p,13:wind_direction:u:p,14:wind_speed:f:p,15:weight:f:p,16:wind_gust:f:p,17:wind_lull:f:p,18:radiation:f:p,19:rainfall_1h:f:p,20:rainfall_24h:f:p,21:soil_moisture:u:p,22:soil_temperature:f:p"
		  Case 4 // AirQualityMetrics
		    Return "1:pm10:u:p,2:pm25:u:p,3:pm100:u:p,13:co2:u:p,14:co2_temperature:f:p,15:co2_humidity:f:p,16:form_formaldehyde:f:p,17:form_humidity:f:p,18:form_temperature:f:p"
		  Case 5 // PowerMetrics
		    Return "1:voltage_ch1:f:p,2:current_ch1:f:p,3:voltage_ch2:f:p,4:current_ch2:f:p,5:voltage_ch3:f:p,6:current_ch3:f:p"
		  Case 8 // HostMetrics
		    Return "1:uptime_seconds:u:n,2:freemem_bytes:u:n,3:diskfree1_bytes:u:n,4:diskfree2_bytes:u:n,5:diskfree3_bytes:u:n,6:load1:c:n,7:load5:c:n,8:load15:c:n"
		  Else
		    Return ""
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshTextJSON(payload As String) As String
		  // TEXT_MESSAGE_APP: the converter passes text that is valid JSON through, otherwise {"text": ...}
		  // (JSON strings like "\"abc\"" are not detected and stay text)
		  Dim text As String = MeshUTF8Clean(payload)
		  Dim trimmed As String = text.Trim
		  If trimmed.BeginsWith("{") Or trimmed.BeginsWith("[") Then
		    Try
		      Dim item As New JSONItem(trimmed)
		      Return MeshJSONFromItem(item)
		    Catch err As JSONException
		    End Try
		  ElseIf MeshSameText(trimmed, "true") Or MeshSameText(trimmed, "false") Or MeshSameText(trimmed, "null") Then
		    Return trimmed
		  Else
		    Dim re As New RegEx
		    re.SearchPattern = "^-?(0|[1-9][0-9]*)(\.[0-9]+)?([eE][+-]?[0-9]+)?$"
		    If re.Search(trimmed) <> Nil Then
		      If trimmed.IndexOf(".") < 0 And trimmed.IndexOf("e") < 0 Then
		        If trimmed = "-0" Then Return "0"
		        Return trimmed
		      End If
		      Return MeshJSONFloat(Val(trimmed))
		    End If
		  End If
		  Dim keys(), values() As String
		  MeshJSONAdd(keys, values, "text", MeshJSONString(text))
		  Return MeshJSONObject(keys, values)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshTracerouteJSON(payload As String, fromNode As UInt32, toNode As UInt32) As String
		  // TRACEROUTE_APP reply: route = [to] + route + [from], route_back = [from] + route_back + [to], SNR / 4
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
		  If r.Failed Then Return ""
		  Dim towardsNames(), backNames(), towardsSNR(), backSNR() As String
		  towardsNames.Add(MeshJSONString(MeshHexID(toNode)))
		  For Each hop As UInt32 In route
		    towardsNames.Add(MeshJSONString(MeshHexID(hop)))
		  Next
		  towardsNames.Add(MeshJSONString(MeshHexID(fromNode)))
		  backNames.Add(MeshJSONString(MeshHexID(fromNode)))
		  For Each backHop As UInt32 In routeBack
		    backNames.Add(MeshJSONString(MeshHexID(backHop)))
		  Next
		  backNames.Add(MeshJSONString(MeshHexID(toNode)))
		  For Each q As Int32 In snrTowards
		    Dim db As Double = q / 4
		    towardsSNR.Add(MeshJSONFloat(db))
		  Next
		  For Each backQ As Int32 In snrBack
		    Dim backDB As Double = backQ / 4
		    backSNR.Add(MeshJSONFloat(backDB))
		  Next
		  Dim keys(), values() As String
		  MeshJSONAdd(keys, values, "route", MeshJSONArray(towardsNames))
		  MeshJSONAdd(keys, values, "route_back", MeshJSONArray(backNames))
		  MeshJSONAdd(keys, values, "snr_back", MeshJSONArray(backSNR))
		  MeshJSONAdd(keys, values, "snr_towards", MeshJSONArray(towardsSNR))
		  Return MeshJSONObject(keys, values)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshUTF8Clean(s As String) As String
		  // Drops invalid UTF-8 bytes, like Python's decode("utf-8", errors="ignore")
		  If s.Bytes = 0 Then Return ""
		  Dim mb As MemoryBlock = s
		  Dim pieces() As String
		  Dim pos, codePoint, startPos, length As Integer
		  While MeshUTF8Next(mb, pos, codePoint, startPos, length)
		    pieces.Add(mb.StringValue(startPos, length))
		  Wend
		  Dim result As String = String.FromArray(pieces, "")
		  Return MeshUTF8Text(result)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshUTF8Next(mb As MemoryBlock, ByRef pos As Integer, ByRef codePoint As Integer, ByRef startPos As Integer, ByRef length As Integer) As Boolean
		  // Next valid UTF-8 sequence at or after pos. Invalid bytes are skipped, like Python's errors="ignore"
		  While pos < mb.Size
		    Dim b0 As Integer = mb.UInt8Value(pos)
		    Dim n As Integer = 0
		    Dim cp As Integer = 0
		    If b0 < &h80 Then
		      n = 1
		      cp = b0
		    ElseIf b0 >= &hC2 And b0 <= &hDF Then
		      n = 2
		      cp = b0 And &h1F
		    ElseIf b0 >= &hE0 And b0 <= &hEF Then
		      n = 3
		      cp = b0 And &h0F
		    ElseIf b0 >= &hF0 And b0 <= &hF4 Then
		      n = 4
		      cp = b0 And &h07
		    End If
		    Dim ok As Boolean = (n > 0) And (pos + n <= mb.Size)
		    If ok Then
		      For j As Integer = 1 To n - 1
		        Dim b As Integer = mb.UInt8Value(pos + j)
		        If (b And &hC0) <> &h80 Then
		          ok = False
		          Exit For
		        End If
		        cp = cp * 64 + (b And &h3F)
		      Next
		    End If
		    If ok And n = 3 And (cp < &h800 Or (cp >= &hD800 And cp <= &hDFFF)) Then ok = False
		    If ok And n = 4 And (cp < &h10000 Or cp > &h10FFFF) Then ok = False
		    If ok Then
		      startPos = pos
		      length = n
		      codePoint = cp
		      pos = pos + n
		      Return True
		    End If
		    pos = pos + 1
		  Wend
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeshZeros(count As Integer) As String
		  Dim s As String
		  For i As Integer = 1 To count
		    s = s + "0"
		  Next
		  Return s
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
