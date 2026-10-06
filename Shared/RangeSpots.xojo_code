#tag Class
Protected Class RangeSpots
	#tag Note, Name = About
		The readings of a range test in one direction (gateway to device, or device to gateway), for the map: one spot
		per packet, where the test device was. Parallel arrays: Times (seconds), Lats / Lons (degrees), Kinds (kHeard: heard
		directly, coloured by SNR; kRelayed; kUnknownHops; kMissed: a test message nobody reported; kPending: sent, not
		reported yet), Rssis (dBm, -255 unknown), Snrs (dB, -255 unknown), Hops (-1 unknown), PacketIDs, Labels (what the
		packet was, e.g. "#12" or "position").
	#tag EndNote


	#tag Method, Flags = &h0
		Sub Add(ts As Integer, lat As Double, lon As Double, kind As Integer, rssi As Integer, snr As Double, hopCount As Integer, packetID As UInt32, label As String)
		  // One spot, kept in time order. Only the latest kMaxSpots are kept
		  Dim i As Integer = Times.Count
		  While i > 0 And Times(i - 1) > ts
		    i = i - 1
		  Wend
		  Times.AddAt(i, ts)
		  Lats.AddAt(i, lat)
		  Lons.AddAt(i, lon)
		  Kinds.AddAt(i, kind)
		  Rssis.AddAt(i, rssi)
		  Snrs.AddAt(i, snr)
		  Hops.AddAt(i, hopCount)
		  PacketIDs.AddAt(i, packetID)
		  Labels.AddAt(i, label)
		  While Times.Count > kMaxSpots
		    Times.RemoveAt(0)
		    Lats.RemoveAt(0)
		    Lons.RemoveAt(0)
		    Kinds.RemoveAt(0)
		    Rssis.RemoveAt(0)
		    Snrs.RemoveAt(0)
		    Hops.RemoveAt(0)
		    PacketIDs.RemoveAt(0)
		    Labels.RemoveAt(0)
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Clear()
		  Times.RemoveAll
		  Lats.RemoveAll
		  Lons.RemoveAll
		  Kinds.RemoveAll
		  Rssis.RemoveAll
		  Snrs.RemoveAll
		  Hops.RemoveAll
		  PacketIDs.RemoveAll
		  Labels.RemoveAll
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemoveAt(i As Integer)
		  // Drops a spot (a test message the gateway never transmitted)
		  If i < 0 Or i > Times.LastIndex Then Return
		  Times.RemoveAt(i)
		  Lats.RemoveAt(i)
		  Lons.RemoveAt(i)
		  Kinds.RemoveAt(i)
		  Rssis.RemoveAt(i)
		  Snrs.RemoveAt(i)
		  Hops.RemoveAt(i)
		  PacketIDs.RemoveAt(i)
		  Labels.RemoveAt(i)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As Integer
		  Return Times.Count
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Describe(i As Integer) As String()
		  // The lines of the map's box for spot i: time, what it was, then the signal or why there is none
		  Dim lines() As String
		  lines.Add(TimeLabel(Times(i), True) + If(Labels(i) <> "", "  ·  " + Labels(i), ""))
		  lines.Add(FormatValue(Lats(i), "-0.000000") + ", " + FormatValue(Lons(i), "-0.000000"))
		  Select Case Kinds(i)
		  Case kHeard
		    Dim radio As String
		    If Rssis(i) <> -255 Then radio = "RSSI " + Str(Rssis(i)) + " dBm"
		    If Snrs(i) <> -255 Then radio = radio + If(radio = "", "", "  ·  ") + "SNR " + FormatValue(Snrs(i), "-0.0") + " dB"
		    lines.Add(If(radio = "", "heard directly", radio))
		  Case kRelayed
		    lines.Add("relayed, " + Str(Hops(i)) + If(Hops(i) = 1, " hop", " hops"))
		  Case kUnknownHops
		    lines.Add("hops unknown")
		  Case kMissed
		    lines.Add("not heard")
		  Case kPending
		    lines.Add("sent, waiting")
		  End Select
		  Return lines
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IndexOfPacket(packetID As UInt32) As Integer
		  // The spot of a packet (a sent test message), -1 if none
		  If packetID = 0 Then Return -1
		  For i As Integer = PacketIDs.LastIndex DownTo 0
		    If NodeNumber(PacketIDs(i)) = NodeNumber(packetID) Then Return i // see NodeNumber: Android sign extension
		  Next
		  Return -1
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Shared Function SnrColor(snr As Double) As Color
		  // Red at -20 dB and below (LongFast decodes down to about -17.5 dB), yellow at -7.5, green at +5 and above
		  Dim t As Double = (snr + 20) / 25
		  If t < 0 Then t = 0
		  If t > 1 Then t = 1
		  If t < 0.5 Then
		    Dim g1 As Integer = 40 + (t / 0.5) * 160
		    Return Color.RGB(220, g1, 40)
		  End If
		  Dim r2 As Integer = 220 - ((t - 0.5) / 0.5) * 180
		  Dim g2 As Integer = 200 - ((t - 0.5) / 0.5) * 40
		  Return Color.RGB(r2, g2, 40)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetKind(i As Integer, kind As Integer, rssi As Integer, snr As Double, hopCount As Integer)
		  // A sent test message reported (heard) or given up on (missed)
		  Kinds(i) = kind
		  Rssis(i) = rssi
		  Snrs(i) = snr
		  Hops(i) = hopCount
		End Sub
	#tag EndMethod


	#tag Property, Flags = &h0
		Hops() As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		Kinds() As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		Labels() As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Lats() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		Lons() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		PacketIDs() As UInt32
	#tag EndProperty

	#tag Property, Flags = &h0
		Rssis() As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		Snrs() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		Times() As Integer
	#tag EndProperty


	#tag Constant, Name = kHeard, Type = Double, Dynamic = False, Default = \"0", Scope = Public
	#tag EndConstant

	#tag Constant, Name = kMaxSpots, Type = Double, Dynamic = False, Default = \"2000", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kMissed, Type = Double, Dynamic = False, Default = \"3", Scope = Public
	#tag EndConstant

	#tag Constant, Name = kPending, Type = Double, Dynamic = False, Default = \"4", Scope = Public
	#tag EndConstant

	#tag Constant, Name = kRelayed, Type = Double, Dynamic = False, Default = \"1", Scope = Public
	#tag EndConstant

	#tag Constant, Name = kUnknownHops, Type = Double, Dynamic = False, Default = \"2", Scope = Public
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
