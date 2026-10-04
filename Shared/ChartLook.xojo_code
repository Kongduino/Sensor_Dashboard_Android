#tag Module
Protected Module ChartLook
	#tag Method, Flags = &h0
		Sub SetTextSize(g As Graphics, size As Double, bold As Boolean)
		  // Text size and weight for the drawing code shared with Android: Graphics.FontSize and Bold on desktop; on
		  // Android, Graphics has no FontSize and its text goes through a Font
		  #If TargetAndroid Then
		    If bold Then
		      g.Font = Font.BoldSystemFont(size)
		    Else
		      g.Font = Font.SystemFont(size)
		    End If
		  #Else
		    g.FontSize = size
		    g.Bold = bold
		  #EndIf
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function TextAscent(g As Graphics) As Double
		  // The ascent of the current text (to place text by its baseline): Graphics.FontAscent on desktop, Font.Ascent on Android
		  #If TargetAndroid Then
		    Return g.Font.Ascent
		  #Else
		    Return g.FontAscent
		  #EndIf
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function FormatValue(value As Double, mask As String) As String
		  // Format with a desktop-style mask: "-0.00" (the "-" asks for the sign of a negative number). On Android, Format is
		  // ICU's DecimalFormat, which writes that "-" literally and adds its own sign (22.3 would show as -22.3, -95 as --95):
		  // there the "-" is dropped. Everything shared formats signed numbers through here
		  #If TargetAndroid Then
		    If mask.BeginsWith("-") Then Return Format(value, mask.Middle(1))
		  #EndIf
		  Return Format(value, mask)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function BarSet(label As String, kind As String, values() As Double, suffix As String) As SensorSeries
		  // A bar series (rounded bars from 0); values is the window's own array
		  Dim s As New SensorSeries
		  s.Label = label
		  s.Kind = kind
		  s.Values = values
		  s.Suffix = suffix
		  s.IsBar = True
		  Return s
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ChartColor(kind As String) As Color
		  // One colour per quantity, the same in every window, with a variant for dark mode
		  Dim dark As Boolean = Color.IsDarkMode
		  Select Case kind
		  Case "temperature" // orange
		    Return If(dark, &cFF922B, &cE8590C)
		  Case "temperature2" // red (second sensor)
		    Return If(dark, &cFF6B6B, &cC92A2A)
		  Case "humidity" // blue
		    Return If(dark, &c4DABF7, &c1971C2)
		  Case "humidity2" // indigo (second sensor)
		    Return If(dark, &c91A7FF, &c3B5BDB)
		  Case "pressure" // teal
		    Return If(dark, &c3BC9DB, &c0C8599)
		  Case "rssi" // green
		    Return If(dark, &c69DB7C, &c2F9E44)
		  Case "snr" // grey
		    Return If(dark, &cCED4DA, &c868E96)
		  Case "co2" // violet
		    Return If(dark, &cB197FC, &c7048E8)
		  Case "voc" // pink
		    Return If(dark, &cF783AC, &cC2255C)
		  Case "pm1" // yellow
		    Return If(dark, &cFFE066, &cFAB005)
		  Case "pm25" // orange
		    Return If(dark, &cFFA94D, &cFD7E14)
		  Case "pm4" // red
		    Return If(dark, &cFF8787, &cE03131)
		  Case "position" // magenta
		    Return If(dark, &cF06595, &cD6336C)
		  Case "pm10" // grape
		    Return If(dark, &cDA77F2, &c862E9C)
		  Else
		    Return If(dark, &cADB5BD, &c495057)
		  End Select
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LineSet(label As String, kind As String, values() As Double, suffix As String, filled As Boolean = True) As SensorSeries
		  // A line series, with a gradient under it unless filled is False; values is the window's own array
		  Dim s As New SensorSeries
		  s.Label = label
		  s.Kind = kind
		  s.Values = values
		  s.Suffix = suffix
		  s.Filled = filled
		  Return s
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastOf(values() As Double) As Double
		  // The latest sample, 0 when there are none yet
		  If values.Count = 0 Then Return 0
		  Return values(values.LastIndex)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MaxOf(values() As Double) As Double
		  If values.Count = 0 Then Return 0
		  Dim m As Double = values(0)
		  For Each v As Double In values
		    If v > m Then m = v
		  Next
		  Return m
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MinOf(values() As Double) As Double
		  If values.Count = 0 Then Return 0
		  Dim m As Double = values(0)
		  For Each v As Double In values
		    If v < m Then m = v
		  Next
		  Return m
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function StatsText(name As String, values() As Double, unit As String, fmt As String) As String
		  // "Temperature: min 24.1 · avg 25.3 · max 26.0 °C" over the samples shown
		  If values.Count = 0 Then Return name + ": no data yet"
		  Return name + ":  min " + FormatValue(MinOf(values), fmt) + "  ·  avg " + FormatValue(MeanOf(values), fmt) + _
		  "  ·  max " + FormatValue(MaxOf(values), fmt) + unit
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SampleCount(n As Integer) As String
		  // "1 sample", "12 samples"
		  If n = 1 Then Return "1 sample"
		  Return Str(n) + " samples"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function TimeLabel(ts As Integer, withSeconds As Boolean) As String
		  // A sample's label: HH:MM[:SS], with the date in front (dd/MM) when it isn't today (readings from earlier sessions)
		  Dim d As New DateTime(ts)
		  Dim t As String = Format(d.Hour, "00") + ":" + Format(d.Minute, "00")
		  If withSeconds Then t = t + ":" + Format(d.Second, "00")
		  Dim today As DateTime = DateTime.Now()
		  If d.Day <> today.Day Or d.Month <> today.Month Or d.Year <> today.Year Then
		    t = Format(d.Day, "00") + "/" + Format(d.Month, "00") + " " + t
		  End If
		  Return t
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
