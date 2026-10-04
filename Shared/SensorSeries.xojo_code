#tag Class
Protected Class SensorSeries
	#tag Note, Name = About
		One series of a SensorChart: its values (the window's own array, so new samples show up
		at the next Refresh), its name in the legend, its colour (ChartColor kind) and its unit.
	#tag EndNote


	#tag Property, Flags = &h0
		Filled As Boolean = True
	#tag EndProperty

	#tag Property, Flags = &h0
		IsBar As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		Kind As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Label As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Suffix As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Values() As Double
	#tag EndProperty


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
