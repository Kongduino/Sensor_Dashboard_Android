#tag Class
Protected Class MobileSensorChart
Inherits MobileCanvas
	#tag Event
		Sub Paint(g As Graphics)
		  Painter().Title = Title
		  Painter().Paint(g, g.Width, g.Height)
		End Sub
	#tag EndEvent

	#tag Event
		Sub PointerDown(position As Point, pointerInfo() As PointerEvent)
		  // A tap shows the sample under the finger (guide line and values); tapping the same sample again hides it
		  Dim changed As Boolean = Painter().HoverAt(position.X)
		  If Not changed And Painter().IsHovering() Then
		    // Not "changed = ClearHover()": Android can't assign a Boolean function result to an existing variable
		    Call Painter().ClearHover()
		    changed = True
		  End If
		  If changed Then Me.Refresh()
		End Sub
	#tag EndEvent

	#tag Event
		Sub PointerDrag(position As Point, pointerInfo() As PointerEvent)
		  // Sliding the finger moves the inspected sample along
		  If Painter().HoverAt(position.X) Then Me.Refresh()
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub AddDataset(s As SensorSeries)
		  Painter().AddDataset(s)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddLabels(labels() As String)
		  // The screen's own label array (one per sample): kept by reference, never modified
		  Painter().AddLabels(labels)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub AddTimes(times() As Double)
		  // The screen's own array of sample times (seconds): kept by reference. With it, the X axis is a time axis
		  Painter().AddTimes(times)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Painter() As ChartPainter
		  // The chart itself (Shared/ChartPainter, the same as on desktop); this control only shows it and follows taps
		  If mPainter = Nil Then mPainter = New ChartPainter
		  Return mPainter
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemoveAllDatasets()
		  Painter().RemoveAllDatasets()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemoveAllLabels()
		  Painter().RemoveAllLabels()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ToPicture() As Picture
		  // The chart as a picture at twice the size (for sharing)
		  Painter().Title = Title
		  Return Painter().ToPicture(Me.Width, Me.Height)
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		Title As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPainter As ChartPainter
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
