#tag Class
Protected Class MobileMapView
Inherits MobileCanvas
	#tag Note, Name = About
		The map of a PositionTrack on Android (see Shared/MapPainter, which draws it and keeps the tiles, in the app's
		cache folder): one finger drags, a tap shows the nearest position (tap it again to hide), a double tap zooms in,
		two fingers pinch to zoom, and the +/−/Fit buttons are larger for fingers.
	#tag EndNote


	#tag Event
		Sub Paint(g As Graphics)
		  Painter().Paint(g, g.Width, g.Height)
		End Sub
	#tag EndEvent

	#tag Event
		Sub PointerDown(position As Point, pointerInfo() As PointerEvent)
		  If pointerInfo.Count >= 2 Then
		    StartPinch(pointerInfo)
		    Return
		  End If
		  If Painter().HitButton(position.X, position.Y) Then
		    Me.Refresh()
		    Return
		  End If
		  mMoved = False
		  mDownX = position.X
		  mDownY = position.Y
		  Painter().StartDrag(position.X, position.Y)
		End Sub
	#tag EndEvent

	#tag Event
		Sub PointerDrag(position As Point, pointerInfo() As PointerEvent)
		  If pointerInfo.Count >= 2 Then
		    If Not mPinching Then StartPinch(pointerInfo)
		    // Pinch: one zoom level each time the fingers' spread changes by kPinchStep, around their middle
		    Dim spread As Double = FingerSpread(pointerInfo)
		    If mPinchSpread > 0 And spread > 0 Then
		      Dim ratio As Double = spread / mPinchSpread
		      Dim steps As Integer
		      If ratio >= kPinchStep Then steps = 1
		      If ratio <= 1 / kPinchStep Then steps = -1
		      If steps <> 0 Then
		        mPinchSpread = spread
		        If Painter().ZoomAt(mPinchX, mPinchY, steps) Then Me.Refresh()
		      End If
		    End If
		    Return
		  End If
		  If mPinching Then Return // the second finger lifted first: wait until all are up
		  // A finger always moves a little: it's a tap until it has gone kTapSlop points from where it went down
		  If Not mMoved And Abs(position.X - mDownX) + Abs(position.Y - mDownY) < kTapSlop Then Return
		  If Painter().DragTo(position.X, position.Y) Then
		    mMoved = True
		    Me.Refresh()
		  End If
		End Sub
	#tag EndEvent

	#tag Event
		Sub PointerUp(position As Point, pointerInfo() As PointerEvent)
		  Painter().EndDrag()
		  If mPinching Then
		    mPinching = False
		    mMoved = True
		    Return
		  End If
		  If mMoved Then Return
		  // A tap. Twice in a row at the same place: zoom in there
		  Dim now As Double = System.Microseconds
		  If now - mLastTap < kDoubleTapMicroseconds And Abs(position.X - mLastTapX) + Abs(position.Y - mLastTapY) < 40 Then
		    mLastTap = 0
		    Call Painter().ClearHover()
		    If Painter().ZoomAt(position.X, position.Y, 1) Then Me.Refresh()
		    Return
		  End If
		  mLastTap = now
		  mLastTapX = position.X
		  mLastTapY = position.Y
		  // One tap: the nearest position (within a finger's reach); the same one again hides it
		  Dim changed As Boolean = Painter().HoverAt(position.X, position.Y, 24)
		  If Not changed Then
		    If Painter().ClearHover() Then Me.Refresh()
		    Return
		  End If
		  Me.Refresh()
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h21
		Private Function FingerSpread(pointerInfo() As PointerEvent) As Double
		  // The distance between the first two fingers
		  If pointerInfo.Count < 2 Then Return 0
		  Dim dx As Double = pointerInfo(1).Position.X - pointerInfo(0).Position.X
		  Dim dy As Double = pointerInfo(1).Position.Y - pointerInfo(0).Position.Y
		  Return Sqrt(dx * dx + dy * dy)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub FitView()
		  // Back to the automatic view: every position, with a margin
		  Painter().FitView()
		  Me.Refresh()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function Painter() As MapPainter
		  // The map itself (Shared/MapPainter), its tiles in the app's cache folder (Android may clear it: they come back)
		  If mPainter = Nil Then
		    mPainter = New MapPainter
		    mPainter.ControlScale = 1.4
		    Try
		      mPainter.CacheFolder = SpecialFolder.Caches.Child("Sensor_Dashboard")
		    Catch e As RuntimeException
		      mPainter.CacheFolder = Nil
		    End Try
		    AddHandler mPainter.Changed, WeakAddressOf PainterChanged
		  End If
		  Return mPainter
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub PainterChanged(sender As MapPainter)
		  // A tile arrived
		  Me.Refresh()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub StartPinch(pointerInfo() As PointerEvent)
		  // Two fingers down: no drag any more, the zoom follows their spread around their middle
		  Painter().EndDrag()
		  mPinching = True
		  mPinchSpread = FingerSpread(pointerInfo)
		  mPinchX = (pointerInfo(0).Position.X + pointerInfo(1).Position.X) / 2
		  mPinchY = (pointerInfo(0).Position.Y + pointerInfo(1).Position.Y) / 2
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ToPicture() As Picture
		  // The map as a picture at twice the size (for sharing)
		  Return Painter().ToPicture(Me.Width, Me.Height)
		End Function
	#tag EndMethod


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Painter().Track
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Painter().Track = value
			End Set
		#tag EndSetter
		Track As PositionTrack
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mDownX As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDownY As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastTap As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastTapX As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastTapY As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mMoved As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPainter As MapPainter
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPinchSpread As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPinchX As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPinchY As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPinching As Boolean
	#tag EndProperty


	#tag Constant, Name = kDoubleTapMicroseconds, Type = Double, Dynamic = False, Default = \"350000", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kTapSlop, Type = Double, Dynamic = False, Default = \"10", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kPinchStep, Type = Double, Dynamic = False, Default = \"1.6", Scope = Private
	#tag EndConstant


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
