#tag Class
Protected Class SourceCard
Inherits MobileCanvas
	#tag Note, Name = About
		One source on the Home screen: a rounded card with its name, its state and its latest reading. A tap raises
		Pressed. The on/off switch is a MobileSwitch placed over the card's right side by the screen.
	#tag EndNote


	#tag Event
		Sub Paint(g As Graphics)
		  Dim dark As Boolean = Color.IsDarkMode()
		  g.AntiAliased = True
		  g.DrawingColor = If(dark, &c2B2B2B, &cF8F9FA)
		  g.FillRoundRectangle(0, 0, g.Width, g.Height, 16, 16)
		  g.DrawingColor = If(dark, &c3A3A3A, &cDEE2E6)
		  g.DrawRoundRectangle(0, 0, g.Width, g.Height, 16, 16)
		  Dim textWidth As Double = g.Width - 32 - 70 // the switch sits at the right
		  SetTextSize(g, 17, True)
		  g.DrawingColor = If(dark, &cF1F3F5, &c212529)
		  g.DrawText(CardTitle, 16, 14 + TextAscent(g), textWidth, True)
		  SetTextSize(g, 13, False)
		  g.DrawingColor = StatusColor(dark)
		  g.DrawText(FirstLine(StatusText), 16, 44 + TextAscent(g), g.Width - 32, True)
		  g.DrawingColor = If(dark, &cCED4DA, &c495057)
		  g.DrawText(FirstLine(DetailText), 16, 66 + TextAscent(g), g.Width - 32, True)
		End Sub
	#tag EndEvent

	#tag Event
		Sub PointerUp(position As Point, pointerInfo() As PointerEvent)
		  RaiseEvent Pressed
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Function FirstLine(text As String) As String
		  // One line per row of the card, whatever the text (a server error can span many)
		  Dim t As String = text.ReplaceLineEndings(EndOfLine)
		  Dim cut As Integer = t.IndexOf(EndOfLine)
		  If cut >= 0 Then t = t.Left(cut)
		  Return t
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function StatusColor(dark As Boolean) As Color
		  // Green when connected, orange while connecting or retrying, grey when off, red on a problem
		  Dim t As String = StatusText.Lowercase
		  If t.BeginsWith("connected") Or t.BeginsWith("soil readings") Then Return If(dark, &c69DB7C, &c2B8A3E)
		  If t.BeginsWith("no soil") Then Return If(dark, &cADB5BD, &c868E96)
		  If t.BeginsWith("off") Or t.BeginsWith("set up") Then Return If(dark, &cADB5BD, &c868E96)
		  If t.IndexOf("connecting") >= 0 Or t.IndexOf("retrying") >= 0 Then Return If(dark, &cFFA94D, &cE8590C)
		  Return If(dark, &cFF8787, &cC92A2A)
		End Function
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Pressed()
	#tag EndHook


	#tag Property, Flags = &h0
		CardTitle As String
	#tag EndProperty

	#tag Property, Flags = &h0
		DetailText As String
	#tag EndProperty

	#tag Property, Flags = &h0
		StatusText As String
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
