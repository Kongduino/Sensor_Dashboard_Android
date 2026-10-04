#tag Class
Protected Class TabStrip
Inherits MobileCanvas
	#tag Note, Name = About
		A row of tabs that share the strip's width equally, whatever their number and the screen's width (Android's
		MobileSegmentedButton gives each segment a minimum width: only about three fit on a phone). A tap raises Pressed.
	#tag EndNote


	#tag Event
		Sub Paint(g As Graphics)
		  Dim dark As Boolean = Color.IsDarkMode()
		  Dim n As Integer = mCaptions.Count
		  g.AntiAliased = True
		  If n = 0 Then Return
		  Dim w As Double = g.Width
		  Dim h As Double = g.Height
		  Dim tabWidth As Double = w / n
		  Dim green As Color = If(dark, &c69DB7C, &c43A047)
		  Dim lineColor As Color = If(dark, &c495057, &cCED4DA)
		  // The selected tab: a light green fill and a green frame
		  If SelectedIndex >= 0 And SelectedIndex < n Then
		    g.DrawingColor = If(dark, &c1E3A23, &cEAF6EB)
		    g.FillRectangle(SelectedIndex * tabWidth, 0, tabWidth, h)
		  End If
		  g.DrawingColor = lineColor
		  g.DrawRoundRectangle(0.5, 0.5, w - 1, h - 1, 6, 6)
		  For i As Integer = 1 To n - 1
		    g.DrawLine(i * tabWidth, 0, i * tabWidth, h)
		  Next
		  If SelectedIndex >= 0 And SelectedIndex < n Then
		    g.DrawingColor = green
		    g.PenSize = 2
		    g.DrawRectangle(SelectedIndex * tabWidth + 1, 1, tabWidth - 2, h - 2)
		    g.PenSize = 1
		  End If
		  SetTextSize(g, 14, False)
		  For i As Integer = 0 To n - 1
		    Dim caption As String = mCaptions(i)
		    g.DrawingColor = If(i = SelectedIndex, green, If(dark, &cCED4DA, &c495057))
		    Dim tw As Double = g.TextWidth(caption)
		    g.DrawText(caption, i * tabWidth + (tabWidth - tw) / 2, (h + TextAscent(g)) / 2 - 2)
		  Next
		End Sub
	#tag EndEvent

	#tag Event
		Sub PointerUp(position As Point, pointerInfo() As PointerEvent)
		  // The tab under the finger
		  Dim n As Integer = mCaptions.Count
		  If n = 0 Or Me.Width <= 0 Then Return
		  Dim tabWidth As Double = Me.Width / n
		  Dim tapped As Integer = Floor(position.X / tabWidth)
		  If tapped < 0 Or tapped >= n Then Return
		  SelectedIndex = tapped
		  Me.Refresh()
		  RaiseEvent Pressed(tapped)
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub AddTab(caption As String)
		  mCaptions.Add(caption)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SelectTab(index As Integer)
		  // Shown as selected (without raising Pressed)
		  SelectedIndex = index
		  Me.Refresh()
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Pressed(tabIndex As Integer)
	#tag EndHook


	#tag Property, Flags = &h0
		SelectedIndex As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mCaptions() As String
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Enabled"
			Visible=true
			Group="UI Control"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Visible"
			Visible=true
			Group="UI Control"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
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
			Name="Height"
			Visible=true
			Group="Position"
			InitialValue="30"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Width"
			Visible=true
			Group="Position"
			InitialValue="200"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockLeft"
			Visible=true
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockRight"
			Visible=true
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockTop"
			Visible=true
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockBottom"
			Visible=true
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="AccessibilityHint"
			Visible=true
			Group="UI Control"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AccessibilityLabel"
			Visible=true
			Group="UI Control"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
