#tag Class
Protected Class PositionTrack
	#tag Note, Name = About
		The positions of one node, in time order: what the Map tab draws. Parallel arrays: Times (seconds),
		Lats / Lons (degrees), Alts (m, 0 if unknown), Precisions (precision_bits: 32 exact, less = rounded on
		purpose), SatCounts (0 if unknown), Rssis (dBm) and Snrs (dB) as received (-255 if unknown).
	#tag EndNote


	#tag Method, Flags = &h0
		Sub Add(ts As Integer, lat As Double, lon As Double, alt As Integer, precision As Integer, sats As Integer, rssi As Integer = -255, snr As Double = -255)
		  // One position, kept in time order; a position with the same time as one already held is ignored.
		  // Only the latest kMaxPositions are kept
		  Dim i As Integer = Times.Count
		  While i > 0 And Times(i - 1) > ts
		    i = i - 1
		  Wend
		  If i > 0 And Times(i - 1) = ts Then Return
		  Times.AddAt(i, ts)
		  Lats.AddAt(i, lat)
		  Lons.AddAt(i, lon)
		  Alts.AddAt(i, alt)
		  Precisions.AddAt(i, precision)
		  SatCounts.AddAt(i, sats)
		  Rssis.AddAt(i, rssi)
		  Snrs.AddAt(i, snr)
		  While Times.Count > kMaxPositions
		    Times.RemoveAt(0)
		    Lats.RemoveAt(0)
		    Lons.RemoveAt(0)
		    Alts.RemoveAt(0)
		    Precisions.RemoveAt(0)
		    SatCounts.RemoveAt(0)
		    Rssis.RemoveAt(0)
		    Snrs.RemoveAt(0)
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Clear()
		  Times.RemoveAll
		  Lats.RemoveAll
		  Lons.RemoveAll
		  Alts.RemoveAll
		  Precisions.RemoveAll
		  SatCounts.RemoveAll
		  Rssis.RemoveAll
		  Snrs.RemoveAll
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Count() As Integer
		  Return Times.Count
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LoadHistory(fromID As Int64) As Integer
		  // The node's stored positions (every session), oldest first; returns how many were added
		  Dim rs As RowSet = PositionRows(fromID)
		  If rs = Nil Then Return 0
		  Dim n As Integer
		  While Not rs.AfterLastRow
		    Add(rs.Column("timestamp").IntegerValue, rs.Column("latitude").DoubleValue, rs.Column("longitude").DoubleValue, _
		    rs.Column("altitude").IntegerValue, rs.Column("precisionBits").IntegerValue, rs.Column("sats").IntegerValue, _
		    RadioValue(rs, "rssi"), RadioValue(rs, "snr"))
		    n = n + 1
		    rs.MoveToNextRow()
		  Wend
		  Return n
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function RadioValue(rs As RowSet, column As String) As Double
		  // rssi / snr of a stored position: -255 when unknown (NULL in rows stored before these columns existed)
		  If rs.Column(column).Value.IsNull Then Return -255
		  Return rs.Column(column).DoubleValue
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Summary() As String
		  // "14 positions · last 10:42 · 22.4597, 114.0012 · 69 m · 7 sats"
		  If Times.Count = 0 Then Return "No position yet"
		  Dim last As Integer = Times.LastIndex
		  Dim t As String = Str(Times.Count) + If(Times.Count = 1, " position", " positions") + "  ·  last " + TimeLabel(Times(last), False) + _
		  "  ·  " + FormatValue(Lats(last), "-0.0000") + ", " + FormatValue(Lons(last), "-0.0000")
		  If Alts(last) <> 0 Then t = t + "  ·  " + Str(Alts(last)) + " m"
		  If SatCounts(last) > 0 Then t = t + "  ·  " + Str(SatCounts(last)) + " sats"
		  If Rssis(last) <> -255 Then t = t + "  ·  RSSI " + Str(Rssis(last)) + " dBm"
		  If Snrs(last) <> -255 Then t = t + "  ·  SNR " + FormatValue(Snrs(last), "-0.0") + " dB"
		  If Precisions(last) > 0 And Precisions(last) < 32 Then t = t + "  ·  approximate (" + Str(Precisions(last)) + " bits)"
		  Return t
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		Alts() As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		Lats() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		Lons() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		Precisions() As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		Rssis() As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		SatCounts() As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		Snrs() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		Times() As Integer
	#tag EndProperty


	#tag Constant, Name = kMaxPositions, Type = Double, Dynamic = False, Default = \"500", Scope = Private
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
