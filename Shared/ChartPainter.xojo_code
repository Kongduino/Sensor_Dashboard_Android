#tag Class
Protected Class ChartPainter
	#tag Note, Name = About
		Sensor_Dashboard's chart, without the control: the series, the time axis, the fitted Y axis with round ticks, the
		gradients and bars, and the inspected sample. Paint(g, w, h) draws it; HoverAt / ClearHover follow the pointer
		or a tap. SensorChart (desktop, a DesktopCanvas) and MobileSensorChart (Android, a MobileCanvas) are thin controls
		around it. Shared with the Android version: keep identical in both repositories.
	#tag EndNote


	#tag Method, Flags = &h0
		Sub AddDataset(s As SensorSeries)
		  mSeries.Add(s)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddLabels(labels() As String)
		  // The window's own label array (one per sample): kept by reference, never modified here
		  mLabels = labels
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddTimes(times() As Double)
		  // The window's own array of sample times (seconds, one per sample): kept by reference, never modified here.
		  // With it, the X axis is a time axis
		  mTimes = times
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ClearHover() As Boolean
		  // No sample inspected any more. True if that changed something (the control then redraws)
		  If mHover < 0 Then Return False
		  mHover = -1
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function HoverAt(x As Double) As Boolean
		  // The sample nearest to x (they aren't evenly spaced on a time axis), shown with a guide line and a box (see
		  // DrawHover); none when x is outside the plot. True if that changed something (the control then redraws)
		  Dim n As Integer = SeriesLength()
		  Dim hoverIndex As Integer = -1
		  If n > 0 And x >= mPlotLeft - 10 And x <= mPlotRight + 10 Then
		    Dim best As Double = 1e9
		    For i As Integer = 0 To n - 1
		      Dim distance As Double = Abs(x - XForIndex(i))
		      If distance < best Then
		        best = distance
		        hoverIndex = i
		      End If
		    Next
		  End If
		  If hoverIndex = mHover Then Return False
		  mHover = hoverIndex
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsHovering() As Boolean
		  Return mHover >= 0
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Paint(g As Graphics, w As Double, h As Double)
		  // The whole chart in a w × h area of g
		  DrawChart(g, w, h)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemoveAllDatasets()
		  Dim none() As SensorSeries
		  mSeries = none
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemoveAllLabels()
		  // Drops the reference only: the window's array is left alone
		  Dim none() As String
		  mLabels = none
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ToPicture(w As Double, h As Double) As Picture
		  // The chart as a picture at twice the size (for exports)
		  Dim p As New Picture(w * 2, h * 2)
		  p.Graphics.ScaleX = 2
		  p.Graphics.ScaleY = 2
		  // Android: GraphicsPath shapes ignore Graphics.ScaleX / ScaleY (dots, lines and text don't), so in an export at
		  // twice the size the paths get their coordinates scaled by hand (mPathScale); 1 everywhere else
		  #If TargetAndroid Then
		    mPathScale = 2
		  #EndIf
		  DrawChart(p.Graphics, w, h)
		  mPathScale = 1
		  Return p
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DrawChart(g As Graphics, w As Double, h As Double)
		  // The whole chart: background, title, legend, axes and grid, the series, the hover box
		  Dim dark As Boolean = Color.IsDarkMode()
		  Dim textColor As Color = If(dark, &cCED4DA, &c495057)
		  Dim gridColor As Color = If(dark, &c3A3A3A, &cE9ECEF)
		  g.AntiAliased = True
		  g.DrawingColor = If(dark, &c1E1E1E, &cFFFFFF)
		  g.FillRectangle(0, 0, w, h)
		  
		  // Title
		  SetTextSize(g, 15, True)
		  g.DrawingColor = If(dark, &cF1F3F5, &c212529)
		  g.DrawText(Title, (w - g.TextWidth(Title)) / 2, 12 + TextAscent(g))
		  
		  // Legend: a coloured dash and the name of each series, centred
		  SetTextSize(g, 12, False)
		  Dim legendY As Double = 44
		  Dim legendWidth As Double
		  For Each s As SensorSeries In mSeries
		    legendWidth = legendWidth + 22 + g.TextWidth(s.Label) + 18
		  Next
		  Dim lx As Double = (w - legendWidth + 18) / 2
		  For Each s As SensorSeries In mSeries
		    g.DrawingColor = ChartColor(s.Kind)
		    g.FillRoundRectangle(lx, legendY + 4, 16, 6, 3, 3)
		    g.DrawingColor = textColor
		    g.DrawText(s.Label, lx + 22, legendY + TextAscent(g))
		    lx = lx + 22 + g.TextWidth(s.Label) + 18
		  Next
		  
		  Dim n As Integer = SeriesLength()
		  If n = 0 Then
		    g.DrawingColor = textColor
		    SetTextSize(g, 13, False)
		    Dim waiting As String = "Waiting for the first reading…"
		    g.DrawText(waiting, (w - g.TextWidth(waiting)) / 2, h / 2)
		    Return
		  End If
		  
		  // Y axis: round ticks covering the data (bars start at 0)
		  Dim lo, hi As Double
		  DataRange(lo, hi)
		  // About 5 ticks, fewer when the plot is short (a phone): at least kMinTickSpacing points between two labels
		  Dim plotHeight As Double = (h - 34) - 76
		  Dim tickCount As Integer = Max(2, Min(5, Floor(plotHeight / kMinTickSpacing)))
		  Dim stepSize As Double = NiceStep((hi - lo) / tickCount)
		  Dim first As Double = Floor(lo / stepSize) * stepSize
		  Dim last As Double = Ceiling(hi / stepSize) * stepSize
		  If last - first < stepSize Then last = first + stepSize
		  mAxisLow = first
		  mAxisHigh = last
		  // As many decimals as the step needs: 0.25 needs 2, 0.2 needs 1, 5 needs 0
		  Dim decimals As Integer
		  While decimals < 6 And Abs(stepSize * 10 ^ decimals - Round(stepSize * 10 ^ decimals)) > 1e-6
		    decimals = decimals + 1
		  Wend
		  Dim fmt As String = "0"
		  If decimals > 0 Then
		    fmt = "0."
		    For d As Integer = 1 To decimals
		      fmt = fmt + "0"
		    Next
		  End If
		  mValueFormat = fmt
		  Dim unit As String
		  If mSeries.Count > 0 Then unit = mSeries(0).Suffix
		  
		  SetTextSize(g, 11, False)
		  Dim labelWidth As Double
		  Dim v As Double = first
		  While v <= last + stepSize / 2
		    labelWidth = Max(labelWidth, g.TextWidth(Format(v, fmt) + unit))
		    v = v + stepSize
		  Wend
		  mPlotLeft = 16 + labelWidth + 8
		  mPlotRight = w - 24
		  mPlotTop = 76
		  mPlotBottom = h - 34
		  
		  // Grid lines and Y labels
		  v = first
		  While v <= last + stepSize / 2
		    Dim y As Double = YForValue(v)
		    g.DrawingColor = gridColor
		    g.DrawLine(mPlotLeft, y, mPlotRight, y)
		    g.DrawingColor = textColor
		    Dim t As String = Format(v, fmt) + unit
		    g.DrawText(t, mPlotLeft - 8 - g.TextWidth(t), y + TextAscent(g) / 2 - 1)
		    v = v + stepSize
		  Wend
		  
		  // X labels under their samples, skipping those that would overlap; the latest is always shown
		  g.DrawingColor = textColor
		  Dim lastLabel As String = LabelAt(n - 1)
		  Dim lastLeft As Double = XForIndex(n - 1) - g.TextWidth(lastLabel) / 2
		  Dim usedRight As Double = -1e9
		  For i As Integer = 0 To n - 2
		    Dim xLabel As String = LabelAt(i)
		    Dim labelLeft As Double = XForIndex(i) - g.TextWidth(xLabel) / 2
		    Dim labelRight As Double = labelLeft + g.TextWidth(xLabel)
		    If labelLeft >= usedRight + 14 And labelRight <= lastLeft - 14 Then
		      g.DrawText(xLabel, labelLeft, mPlotBottom + 8 + TextAscent(g))
		      usedRight = labelRight
		    End If
		  Next
		  g.DrawText(lastLabel, lastLeft, mPlotBottom + 8 + TextAscent(g))
		  
		  // The series
		  Dim barCount As Integer
		  For Each s As SensorSeries In mSeries
		    If s.IsBar Then barCount = barCount + 1
		  Next
		  Dim barIndex As Integer
		  For Each s As SensorSeries In mSeries
		    If s.IsBar Then
		      DrawBars(g, s, barIndex, barCount)
		      barIndex = barIndex + 1
		    Else
		      DrawLine(g, s)
		    End If
		  Next
		  
		  If mHover >= 0 And mHover < n Then DrawHover(g, w)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DrawBars(g As Graphics, s As SensorSeries, barIndex As Integer, barCount As Integer)
		  // Rounded bars from the axis bottom (0 for bars), side by side when there are several series
		  Dim groupW As Double = GroupWidth()
		  Dim barWidth As Double = Max(2.0, groupW / Max(1, barCount) - 2)
		  Dim baseY As Double = YForValue(Max(0.0, mAxisLow))
		  g.DrawingColor = ChartColor(s.Kind)
		  For i As Integer = 0 To s.Values.LastIndex
		    Dim x As Double = XForIndex(i) - groupW / 2 + barIndex * (barWidth + 2)
		    Dim y As Double = YForValue(s.Values(i))
		    Dim barTop As Double = Min(y, baseY)
		    Dim barHeight As Double = Max(1.0, Abs(baseY - y))
		    g.FillRoundRectangle(x, barTop, barWidth, barHeight, Min(8.0, barWidth / 2), Min(8.0, barWidth / 2))
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DrawHover(g As Graphics, w As Double)
		  // A guide line at the inspected sample, and a box with its time and values
		  Dim dark As Boolean = Color.IsDarkMode()
		  Dim x As Double = XForIndex(mHover)
		  g.DrawingColor = If(dark, &c6C757D, &cADB5BD)
		  g.DrawLine(x, mPlotTop, x, mPlotBottom)
		  
		  Dim lines() As String
		  lines.Add LabelAt(mHover)
		  For Each s As SensorSeries In mSeries
		    If mHover <= s.Values.LastIndex Then
		      lines.Add s.Label + ":  " + ValueText(s.Values(mHover)) + s.Suffix
		    End If
		  Next
		  SetTextSize(g, 12, False)
		  Dim boxWidth As Double
		  For Each t As String In lines
		    boxWidth = Max(boxWidth, g.TextWidth(t))
		  Next
		  boxWidth = boxWidth + 20
		  Dim lineHeight As Double = TextAscent(g) + 6
		  Dim boxHeight As Double = lines.Count * lineHeight + 10
		  Dim boxX As Double = x + 12
		  If boxX + boxWidth > w - 8 Then boxX = x - 12 - boxWidth
		  Dim boxY As Double = mPlotTop + 8
		  g.DrawingColor = If(dark, &cF1F3F5, &c212529)
		  g.FillRoundRectangle(boxX, boxY, boxWidth, boxHeight, 10, 10)
		  For i As Integer = 0 To lines.LastIndex
		    g.DrawingColor = If(dark, &c212529, &cFFFFFF)
		    SetTextSize(g, 12, i = 0)
		    g.DrawText(lines(i), boxX + 10, boxY + 5 + i * lineHeight + TextAscent(g))
		  Next
		  SetTextSize(g, 12, False)
		  
		  // The points of the hovered sample, larger
		  For Each s As SensorSeries In mSeries
		    If Not s.IsBar And mHover <= s.Values.LastIndex Then
		      Dim y As Double = YForValue(s.Values(mHover))
		      g.DrawingColor = If(dark, &c1E1E1E, &cFFFFFF)
		      g.FillOval(x - 6, y - 6, 12, 12)
		      g.DrawingColor = ChartColor(s.Kind)
		      g.FillOval(x - 4, y - 4, 8, 8)
		    End If
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DrawLine(g As Graphics, s As SensorSeries)
		  // The line, a soft gradient under it, and points while there are few samples
		  If s.Values.Count = 0 Then Return
		  Dim c As Color = ChartColor(s.Kind)
		  Dim line As New GraphicsPath
		  Dim area As New GraphicsPath
		  For i As Integer = 0 To s.Values.LastIndex
		    Dim x As Double = XForIndex(i)
		    Dim y As Double = YForValue(s.Values(i))
		    If i = 0 Then
		      line.MoveToPoint(x * mPathScale, y * mPathScale)
		      area.MoveToPoint(x * mPathScale, mPlotBottom * mPathScale)
		    Else
		      line.AddLineToPoint(x * mPathScale, y * mPathScale)
		    End If
		    area.AddLineToPoint(x * mPathScale, y * mPathScale)
		  Next
		  area.AddLineToPoint(XForIndex(s.Values.LastIndex) * mPathScale, mPlotBottom * mPathScale)
		  
		  If s.Filled And s.Values.Count > 1 Then
		    Dim stops() As Pair
		    stops.Add 0.0 : Color.RGB(c.Red, c.Green, c.Blue, 150)
		    stops.Add 1.0 : Color.RGB(c.Red, c.Green, c.Blue, 245)
		    g.Brush = New LinearGradientBrush(New Point(0, mPlotTop * mPathScale), New Point(0, mPlotBottom * mPathScale), stops)
		    g.FillPath(area)
		    g.Brush = Nil
		  End If
		  
		  g.DrawingColor = c
		  g.PenSize = 2 * mPathScale
		  If s.Values.Count > 1 Then g.DrawPath(line)
		  g.PenSize = 1
		  
		  If s.Values.Count <= 40 Then
		    Dim dark As Boolean = Color.IsDarkMode()
		    For j As Integer = 0 To s.Values.LastIndex
		      Dim px As Double = XForIndex(j)
		      Dim py As Double = YForValue(s.Values(j))
		      g.DrawingColor = c
		      g.FillOval(px - 3.5, py - 3.5, 7, 7)
		      g.DrawingColor = If(dark, &c1E1E1E, &cFFFFFF)
		      g.FillOval(px - 1.5, py - 1.5, 3, 3)
		    Next
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DataRange(ByRef lo As Double, ByRef hi As Double)
		  // The lowest and highest value of all series, with a little room; bars include 0
		  Dim any As Boolean
		  Dim hasBars As Boolean
		  For Each s As SensorSeries In mSeries
		    If s.IsBar Then hasBars = True
		    For Each v As Double In s.Values
		      If Not any Then
		        lo = v
		        hi = v
		        any = True
		      Else
		        lo = Min(lo, v)
		        hi = Max(hi, v)
		      End If
		    Next
		  Next
		  If hasBars Then
		    lo = Min(lo, 0.0)
		    hi = Max(hi, 0.0)
		    hi = hi + (hi - lo) * 0.1
		  Else
		    Dim room As Double = (hi - lo) * 0.15
		    If room = 0 Then room = Max(Abs(hi) * 0.01, 0.5) // a flat series: a small band around it
		    lo = lo - room
		    hi = hi + room
		  End If
		  If hi <= lo Then hi = lo + 1
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function GroupWidth() As Double
		  // The width of one sample's bars: 70 % of the space to its nearest neighbour (on a time axis, the
		  // smallest gap), between 4 and 60 pixels
		  Dim n As Integer = SeriesLength()
		  Dim space As Double = SlotWidth()
		  If UseTime() Then
		    For i As Integer = 1 To n - 1
		      space = Min(space, XForIndex(i) - XForIndex(i - 1))
		    Next
		  End If
		  Return Min(60.0, Max(4.0, space * 0.7))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function LabelAt(i As Integer) As String
		  If i >= 0 And i <= mLabels.LastIndex Then Return mLabels(i)
		  Return ""
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function NiceStep(rough As Double) As Double
		  // 1, 2, 2.5 or 5 times a power of ten, at least rough
		  If rough <= 0 Then Return 1
		  Dim magnitude As Double = 10 ^ Floor(Log(rough) / Log(10))
		  Dim f As Double = rough / magnitude
		  If f <= 1 Then Return magnitude
		  If f <= 2 Then Return 2 * magnitude
		  If f <= 2.5 Then Return 2.5 * magnitude
		  If f <= 5 Then Return 5 * magnitude
		  Return 10 * magnitude
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SeriesLength() As Integer
		  // The number of samples: the longest series
		  Dim n As Integer
		  For Each s As SensorSeries In mSeries
		    n = Max(n, s.Values.Count)
		  Next
		  Return n
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SlotWidth() As Double
		  // The horizontal space of one sample
		  Dim n As Integer = SeriesLength()
		  If n <= 0 Then Return mPlotRight - mPlotLeft
		  Return (mPlotRight - mPlotLeft) / n
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function UseTime() As Boolean
		  // A time axis when there is one time per sample, and they span some time
		  Dim n As Integer = SeriesLength()
		  Return n >= 2 And mTimes.Count = n And mTimes(n - 1) > mTimes(0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ValueText(v As Double) As String
		  // A reading as the hover box shows it: up to 2 decimals, without trailing zeros (28.63, 998.2, 1242)
		  Dim t As String = FormatValue(v, "-0.00")
		  While t.EndsWith("0") And t.IndexOf(".") >= 0
		    t = t.Left(t.Length - 1)
		  Wend
		  If t.EndsWith(".") Then t = t.Left(t.Length - 1)
		  Return t
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function XForIndex(i As Integer) As Double
		  // With times (AddTimes): placed by time, so gaps keep their real width. Without: centred in equal slots
		  If UseTime() Then
		    Dim t0 As Double = mTimes(0)
		    Dim t1 As Double = mTimes(SeriesLength() - 1)
		    Dim pad As Double = Min(24.0, (mPlotRight - mPlotLeft) / 4)
		    Return mPlotLeft + pad + (mTimes(i) - t0) / (t1 - t0) * (mPlotRight - mPlotLeft - 2 * pad)
		  End If
		  Return mPlotLeft + (i + 0.5) * SlotWidth()
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function YForValue(v As Double) As Double
		  If mAxisHigh <= mAxisLow Then Return mPlotBottom
		  Return mPlotBottom - (v - mAxisLow) / (mAxisHigh - mAxisLow) * (mPlotBottom - mPlotTop)
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		Title As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPathScale As Double = 1
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mAxisHigh As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mAxisLow As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mHover As Integer = -1
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLabels() As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPlotBottom As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPlotLeft As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPlotRight As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPlotTop As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSeries() As SensorSeries
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTimes() As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mValueFormat As String = "0.0"
	#tag EndProperty


	#tag Constant, Name = kMinTickSpacing, Type = Double, Dynamic = False, Default = \"28", Scope = Private
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
		#tag ViewProperty
			Name="Title"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
