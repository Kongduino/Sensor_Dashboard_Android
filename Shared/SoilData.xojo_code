#tag Module
Protected Module SoilData
	#tag Note, Name = About
		Soil readings (Meshtastic EnvironmentMetrics soil_temperature and soil_moisture), shared by the desktop and Android
		apps. They are stored like any environment telemetry (table telemetry, the payload as JSON), from the MQTT feed
		(logType 2) and from a node's own link (logType 3); this module reads them back per node and per metric.

		The metrics are listed in kMetrics, one entry per metric: JSON key | name | short label (tab) | unit | number format |
		chart colour (a ChartColor kind); "{deg}" stands for the degree sign.
		A new soil metric (pH, conductivity... once the library decodes them) is one more entry.
	#tag EndNote


	#tag Method, Flags = &h0
		Function HasSoilData(payload As JSONItem) As Boolean
		  // True when a telemetry payload holds at least one soil metric
		  If payload = Nil Then Return False
		  For i As Integer = 0 To SoilMetricCount() - 1
		    If payload.HasKey(SoilMetricKey(i)) Then Return True
		  Next
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function MetricField(i As Integer, field As Integer) As String
		  // Field field (0 key, 1 name, 2 short label, 3 unit, 4 format, 5 chart colour) of metric i in kMetrics
		  Dim sep As String = ";"
		  Dim entries() As String = kMetrics.Split(sep)
		  If i < 0 Or i > entries.LastIndex Then Return ""
		  Dim bar As String = "|"
		  Dim fields() As String = entries(i).Split(bar)
		  If field < 0 Or field > fields.LastIndex Then Return ""
		  // "{deg}" stands for the degree sign: the constant stays plain ASCII
		  Dim degreeTag As String = "{deg}"
		  Dim degree As String = Chr(176)
		  Dim value As String = fields(field)
		  Dim result As String = value.ReplaceAll(degreeTag, degree)
		  Return result
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ParseStoredPayload(stored As String, ByRef item As JSONItem) As Boolean
		  // A payload as stored in the telemetry table (JSON; older rows used single quotes), as a JSONItem. ByRef rather than
		  // a JSONItem result: on Android a JSONItem function returning Nil throws (see ChildObject)
		  item = Nil
		  Dim quote As String = """"
		  Dim apostrophe As String = "'"
		  Dim jsonText As String = stored.ReplaceAllBytes(apostrophe, quote)
		  Try
		    item = New JSONItem(jsonText)
		  Catch e As RuntimeException
		    item = Nil
		    Return False
		  End Try
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SoilMetricCount() As Integer
		  Dim sep As String = ";"
		  Dim entries() As String = kMetrics.Split(sep)
		  Return entries.Count
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SoilMetricColor(i As Integer) As String
		  // The ChartColor kind the metric is drawn with
		  Return MetricField(i, 5)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SoilMetricFormat(i As Integer) As String
		  // Number format for the metric's values (FormatValue mask)
		  Return MetricField(i, 4)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SoilMetricKey(i As Integer) As String
		  // The metric's JSON key in the telemetry payload
		  Return MetricField(i, 0)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SoilMetricName(i As Integer) As String
		  // The metric's full name, e.g. "Soil temperature"
		  Return MetricField(i, 1)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SoilMetricShort(i As Integer) As String
		  // A short label for a tab or a menu, e.g. "Soil °C"
		  Return MetricField(i, 2)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SoilMetricUnit(i As Integer) As String
		  Return MetricField(i, 3)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SoilNodes(viaGateway As Int64 = -1) As RowSet
		  // The nodes that have sent soil readings (either feed, every session), the most recent first: fromID, lastTS, n.
		  // viaGateway >= 0: only the nodes an MQTT feed of that gateway brought (logType 2, senderID)
		  Dim cond As String = "logType IN (2, 3)"
		  If viaGateway >= 0 Then cond = "logType = 2 AND senderID=" + Format(viaGateway, "0")
		  Dim cmd As String = "SELECT fromID, MAX(timestamp) AS lastTS, COUNT(DISTINCT timestamp) AS n FROM telemetry " + _
		  "WHERE " + cond + " AND payload LIKE '%soil%' GROUP BY fromID ORDER BY lastTS DESC;"
		  Try
		    Return MySensordb.SelectSQL(cmd)
		  Catch e As DatabaseException
		    LogEvents "SoilNodes", "Database error: " + e.Message
		    Return Nil
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SoilRows(nodeID As Int64, limit As Integer = 100) As RowSet
		  // The latest soil readings of a node (either feed, every session), oldest first: timestamp, payload. A reading
		  // received by both feeds (same node and time) comes once
		  Dim cmd As String = "SELECT * FROM (SELECT timestamp, payload FROM telemetry WHERE logType IN (2, 3) AND fromID=" + _
		  Format(nodeID, "0") + " AND payload LIKE '%soil%' GROUP BY timestamp ORDER BY timestamp DESC LIMIT " + Str(limit) + _
		  ") ORDER BY timestamp;"
		  Try
		    Return MySensordb.SelectSQL(cmd)
		  Catch e As DatabaseException
		    LogEvents "SoilRows", "Database error: " + e.Message
		    Return Nil
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SoilSeries(nodeID As Int64, metric As Integer, times() As Double, values() As Double)
		  // One metric of a node as a time series (seconds since 1970, values), oldest first; readings without that
		  // metric are skipped
		  times.RemoveAll
		  values.RemoveAll
		  Dim key As String = SoilMetricKey(metric)
		  If key = "" Then Return
		  Dim rs As RowSet = SoilRows(nodeID)
		  If rs = Nil Then Return
		  While Not rs.AfterLastRow
		    Dim item As JSONItem
		    If ParseStoredPayload(rs.Column("payload").StringValue, item) Then
		      If item.HasKey(key) Then
		        Dim ts As Double = rs.Column("timestamp").IntegerValue
		        Dim v As Double = item.Value(key).DoubleValue
		        times.Add(ts)
		        values.Add(v)
		      End If
		    End If
		    rs.MoveToNextRow()
		  Wend
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub WriteSoilCSV(nodeID As Int64, fi As FolderItem)
		  // Every stored soil reading of a node as ";"-separated text, oldest first: timestamp, time, then one column per metric
		  // (empty when a reading doesn't have it)
		  If fi.Exists Then fi.Remove()
		  Dim tos As TextOutputStream = TextOutputStream.Create(fi)
		  Dim header() As String
		  header.Add("timestamp")
		  header.Add("time")
		  For i As Integer = 0 To SoilMetricCount() - 1
		    header.Add(SoilMetricKey(i))
		  Next
		  Dim sep As String = ";"
		  tos.WriteLine(String.FromArray(header, sep))
		  Dim rs As RowSet = SoilRows(nodeID, 1000000)
		  If rs <> Nil Then
		    While Not rs.AfterLastRow
		      Dim item As JSONItem
		      If ParseStoredPayload(rs.Column("payload").StringValue, item) Then
		        Dim ts As Integer = rs.Column("timestamp").IntegerValue
		        Dim cells() As String
		        cells.Add(Str(ts))
		        cells.Add(TimeLabel(ts, True))
		        For i As Integer = 0 To SoilMetricCount() - 1
		          If item.HasKey(SoilMetricKey(i)) Then
		            Dim v As Double = item.Value(SoilMetricKey(i)).DoubleValue
		            cells.Add(FormatValue(v, "-0.00"))
		          Else
		            cells.Add("")
		          End If
		        Next
		        tos.WriteLine(String.FromArray(cells, sep))
		      End If
		      rs.MoveToNextRow()
		    Wend
		  End If
		  tos.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SoilSummary(nodeID As Int64) As String
		  // The node's latest soil reading in one line, e.g. "Soil 21.4 °C · Moisture 37 %" ("" when it has none)
		  Dim rs As RowSet = SoilRows(nodeID, 1)
		  If rs = Nil Or rs.AfterLastRow Then Return ""
		  Dim item As JSONItem
		  If Not ParseStoredPayload(rs.Column("payload").StringValue, item) Then Return ""
		  Dim parts() As String
		  For i As Integer = 0 To SoilMetricCount() - 1
		    If item.HasKey(SoilMetricKey(i)) Then
		      Dim v As Double = item.Value(SoilMetricKey(i)).DoubleValue
		      parts.Add(SoilMetricShort(i) + " " + FormatValue(v, SoilMetricFormat(i)))
		    End If
		  Next
		  Dim sep As String = " · "
		  Return String.FromArray(parts, sep)
		End Function
	#tag EndMethod


	#tag Constant, Name = kMetrics, Type = String, Dynamic = False, Default = \"soil_temperature|Soil temperature|Soil {deg}C|{deg}C|-0.0|temperature;soil_moisture|Soil moisture|Moisture %|%|0|humidity", Scope = Private
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
End Module
#tag EndModule
