#tag Class
Protected Class NodeSource
	#tag Note, Name = About
		A Meshtastic node over TCP for the Android app: the desktop Meshtastic window's logic without its window.
	#tag EndNote


	#tag Method, Flags = &h0
		Function SharePrefix() As String
		  Dim h As String = Hub.NodeText(ChartNode)
		  Return "DEV_" + h.Middle(1)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ExportRows() As RowSet
		  Dim nodeArg As Int64 = NodeNumber(ChartNode)
		  Return TelemetryRows(3, nodeArg, -1)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Resume()
		  // Back in the foreground: a dropped link is opened again now rather than at the next retry
		  If Not mOn Or mLink <> Nil Then Return
		  If mRetry <> Nil Then mRetry.RunMode = Timer.RunModes.Off
		  CreateLink()
		  SetStatus("connecting")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub FillNodeList(link As MeshDeviceLink)
		  // The nodes the connected node knows, for the source screen's picker: label and a lowercase search text
		  NodeNums.RemoveAll()
		  NodeLabels.RemoveAll()
		  NodeSearch.RemoveAll()
		  For i As Integer = 0 To link.NodeCount() - 1
		    Dim num As UInt32 = link.NodeNumAt(i)
		    If num <> mMyNum Then
		      Dim longName As String = link.NodeLongNameAt(i)
		      Dim shortName As String = link.NodeShortNameAt(i)
		      Dim id As String = Hub.NodeText(num)
		      NodeNums.Add(num)
		      NodeLabels.Add(If(longName <> "", longName + "  (" + id + ")", id))
		      Dim search As String = longName + " " + shortName + " " + id
		      NodeSearch.Add(search.Lowercase)
		    End If
		  Next
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function NodeLabel(num As UInt32) As String
		  If num = mMyNum Then Return "own sensor"
		  Dim i As Integer = NodeNums.IndexOf(num)
		  If i >= 0 Then Return NodeLabels(i)
		  Return Hub.NodeText(num)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MyNum() As UInt32
		  Return mMyNum
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SetChartNode(num As UInt32)
		  // Another node to chart: its stored readings and positions, then live ones
		  If num = ChartNode Then Return
		  ChartNode = num
		  mRequestID = 0
		  ClearData()
		  LoadHistory()
		  RaiseEvent Changed
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Request(position As Boolean) As String
		  // Asks the charted node for its readings (or its position) now; "" when sent, otherwise why not
		  If mLink = Nil Or Not mOn Then Return "not connected"
		  If ChartNode = 0 Then Return "no node selected"
		  Dim id As UInt32
		  If position Then
		    id = mLink.RequestPosition(ChartNode)
		  Else
		    id = mLink.RequestTelemetry(ChartNode)
		  End If
		  If id = 0 Then Return "not sent"
		  mRequestID = id
		  mRequestedPosition = position
		  SetStatus(If(position, "position", "readings") + " requested from " + NodeLabel(ChartNode))
		  Return ""
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Start()
		  // A Meshtastic node over TCP (port 4403), as the desktop Meshtastic window does
		  If mOn Or Not IsConfigured() Then Return
		  mOn = True
		  ClearData()
		  mHistoryLoaded = False
		  CreateLink()
		  SetStatus("connecting")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Stop()
		  If Not mOn Then Return
		  mOn = False
		  If mRetry <> Nil Then mRetry.RunMode = Timer.RunModes.Off
		  DropLink()
		  SetStatus("off")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsOn() As Boolean
		  Return mOn
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsConfigured() As Boolean
		  Return Hub.Setting("device_host") <> ""
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Describe() As String
		  If Owner <> "" Then Return Owner + " · " + Str(NodeCount) + " nodes"
		  Return Hub.Setting("device_host")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub CreateLink()
		  DropLink()
		  mLink = New MeshDeviceLink
		  AddHandler mLink.ConfigComplete, WeakAddressOf LinkConfigComplete
		  AddHandler mLink.LinkClosed, WeakAddressOf LinkClosed
		  AddHandler mLink.PacketReceived, WeakAddressOf LinkPacketReceived
		  Dim port As Integer = Val(Hub.Setting("device_port"))
		  If port <= 0 Then port = 4403
		  mLink.ConnectTCP(Hub.Setting("device_host"), port)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DropLink()
		  If mLink = Nil Then Return
		  mLink.Close()
		  mLink = Nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub SetStatus(text As String)
		  Status = text
		  RaiseEvent Changed
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LinkConfigComplete(sender As MeshDeviceLink)
		  mMyNum = sender.MyNodeNum()
		  Owner = sender.LongName()
		  NodeCount = sender.NodeCount()
		  FillNodeList(sender)
		  If ChartNode = 0 Then ChartNode = mMyNum
		  LogEvents("Node", "Connected to " + Hub.NodeText(mMyNum) + " " + Owner)
		  If Not mHistoryLoaded Then
		    mHistoryLoaded = True
		    LoadHistory()
		  End If
		  SetStatus("connected")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LinkClosed(sender As MeshDeviceLink, reason As String)
		  // Still on: try again every 30 s (a node rebooting, or another app holding its single TCP client slot)
		  LogEvents("Node", "Connection closed: " + reason)
		  mLink = Nil
		  If Not mOn Then Return
		  If mRetry = Nil Then
		    mRetry = New Timer
		    AddHandler mRetry.Run, WeakAddressOf RetryNow
		  End If
		  mRetry.Period = 30000
		  mRetry.RunMode = Timer.RunModes.Single
		  SetStatus("disconnected, retrying")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub RetryNow(sender As Timer)
		  If Not mOn Then Return
		  CreateLink()
		  SetStatus("connecting")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LinkPacketReceived(sender As MeshDeviceLink, envelope As String)
		  Dim jsonText, packetKey As String
		  Dim summary As String = MeshPacketSummary(envelope, jsonText, packetKey)
		  If summary = "" Then Return
		  LogEvents("Node", summary)
		  // An ACK / NAK for our request: NO_RESPONSE means the node has nothing to answer with
		  Dim requestID, routeFrom, routeTo As UInt32
		  Dim errorCode As Integer
		  If MeshTakeRouting(requestID, routeFrom, routeTo, errorCode) Then
		    If requestID = mRequestID And mRequestID <> 0 And errorCode <> 0 Then
		      mRequestID = 0
		      SetStatus(If(mRequestedPosition, "position", "readings") + " from " + NodeLabel(ChartNode) + ": " + MeshRoutingErrorName(errorCode))
		    End If
		  End If
		  If jsonText <> "" Then HandlePacketJSON(jsonText)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandlePacketJSON(jsonText As String)
		  // Environment telemetry of any node is stored (once per node and time: the node replays its last packets at
		  // each connection); the charted node's is kept for the charts
		  Dim js As JSONItem
		  Try
		    js = New JSONItem(jsonText)
		  Catch e As RuntimeException
		    Return
		  End Try
		  Dim kind As String = js.Lookup("type", "?").StringValue
		  If kind = "position" Then
		    HandlePosition(js)
		    Return
		  End If
		  If kind <> "telemetry" Then Return
		  Dim payload As JSONItem
		  If Not ChildObject(js, "payload", payload) Then Return
		  If Not payload.HasKey("temperature") Then Return
		  Dim fromNum As UInt32 = js.Lookup("from", 0).UInt64Value
		  Dim TS As Integer = js.Lookup("timestamp", 0).IntegerValue
		  If TS <= 0 Then
		    Dim nowTS As Integer = DateTime.Now().SecondsFrom1970
		    TS = nowTS
		  End If
		  If mLastStored = Nil Then mLastStored = New Dictionary
		  Dim key As String = Str(fromNum)
		  If TS > mLastStored.Lookup(key, 0).IntegerValue Then
		    mLastStored.Value(key) = TS
		    // With the radio values and hops of the packet as the connected node received it (none for its own)
		    Dim hops, hopStart, relayNode As Integer
		    Dim viaMQTT As Boolean
		    MeshLastPacketRadio(hops, hopStart, relayNode, viaMQTT) // how this packet reached the gateway / node
		    Dim rssi As Double = js.Lookup("rssi", -255).DoubleValue
		    Dim snr As Double = js.Lookup("snr", -255).DoubleValue
		    LogTelemetry(3, Format(NodeNumber(fromNum), "0"), Format(NodeNumber(mMyNum), "0"), Str(TS), payload.ToString(), rssi, snr, MySessionNum, hops, hopStart, relayNode, viaMQTT)
		  End If
		  If fromNum <> ChartNode Then Return
		  UpdateData(payload.Lookup("temperature", -255).DoubleValue, payload.Lookup("relative_humidity", -255).DoubleValue, _
		  payload.Lookup("barometric_pressure", -255).DoubleValue, TS)
		  RaiseEvent Changed
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandlePosition(js As JSONItem)
		  Dim ts, alt, precision, sats As Integer
		  Dim lat, lon As Double
		  If Not ParsePosition(js, ts, lat, lon, alt, precision, sats) Then Return
		  Dim fromNum As UInt32 = js.Lookup("from", 0).UInt64Value
		  Dim rssi As Integer = js.Lookup("rssi", -255).IntegerValue
		  Dim snr As Double = js.Lookup("snr", -255).DoubleValue
		  Dim hops, hopStart, relayNode As Integer
		  Dim viaMQTT As Boolean
		  MeshLastPacketRadio(hops, hopStart, relayNode, viaMQTT) // how this packet reached the gateway / node
		  If mLastStoredPos = Nil Then mLastStoredPos = New Dictionary
		  Dim key As String = Str(fromNum)
		  If ts > mLastStoredPos.Lookup(key, 0).IntegerValue Then
		    mLastStoredPos.Value(key) = ts
		    LogPosition(NodeNumber(fromNum), NodeNumber(mMyNum), ts, lat, lon, alt, precision, sats, rssi, snr, hops, hopStart, relayNode, viaMQTT)
		  End If
		  If fromNum = ChartNode Then
		    Track().Add(ts, lat, lon, alt, precision, sats, rssi, snr, hops, viaMQTT)
		    RaiseEvent Changed
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Track() As PositionTrack
		  If mTrack = Nil Then mTrack = New PositionTrack
		  Return mTrack
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ClearData()
		  Temps.RemoveAll()
		  RHs.RemoveAll()
		  PAs.RemoveAll()
		  Times.RemoveAll()
		  Labels.RemoveAll()
		  Track().Clear()
		  Latest = ""
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub LoadHistory()
		  // The charted node's earlier readings and positions from the database (every session)
		  Dim nodeArg As Int64 = NodeNumber(ChartNode)
		  Dim rs As RowSet = HistoryRows(3, nodeArg, -1)
		  If rs <> Nil Then
		    While Not rs.AfterLastRow
		      Dim pl As JSONItem
		      Try
		        pl = New JSONItem(rs.Column("payload").StringValue.ReplaceAllBytes("'", """"))
		      Catch e As RuntimeException
		        pl = Nil
		      End Try
		      If pl <> Nil Then
		        If pl.HasKey("temperature") Then
		          UpdateData(pl.Lookup("temperature", -255).DoubleValue, pl.Lookup("relative_humidity", -255).DoubleValue, _
		          pl.Lookup("barometric_pressure", -255).DoubleValue, rs.Column("timestamp").IntegerValue)
		        End If
		      End If
		      rs.MoveToNextRow()
		    Wend
		  End If
		  Call Track().LoadHistory(NodeNumber(ChartNode))
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub UpdateData(temp As Double, rh As Double, pa As Double, TS As Integer)
		  If rh = -255 Or temp = -255 Or pa = -255 Then Return
		  Dim label As String = TimeLabel(TS, True)
		  Labels.Add(label)
		  Times.Add(TS)
		  Temps.Add(temp)
		  RHs.Add(rh)
		  PAs.Add(pa)
		  While Labels.Count > kMaxSamples
		    Labels.RemoveAt(0)
		    Times.RemoveAt(0)
		    Temps.RemoveAt(0)
		    RHs.RemoveAt(0)
		    PAs.RemoveAt(0)
		  Wend
		  Latest = FormatValue(temp, "-0.0") + " °C · " + Format(rh, "0") + " % · " + Format(pa, "0") + " hPa   " + label
		End Sub
	#tag EndMethod

	#tag Hook, Flags = &h0
		Event Changed()
	#tag EndHook

	#tag Property, Flags = &h21
		Private mRequestedPosition As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRequestID As UInt32
	#tag EndProperty

	#tag Property, Flags = &h0
		NodeSearch() As String
	#tag EndProperty

	#tag Property, Flags = &h0
		NodeNums() As UInt32
	#tag EndProperty

	#tag Property, Flags = &h0
		NodeLabels() As String
	#tag EndProperty

	#tag Property, Flags = &h0
		ChartNode As UInt32
	#tag EndProperty

	#tag Property, Flags = &h0
		Labels() As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Latest As String
	#tag EndProperty

	#tag Property, Flags = &h0
		NodeCount As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		Owner As String
	#tag EndProperty

	#tag Property, Flags = &h0
		PAs() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		RHs() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		Status As String = "off"
	#tag EndProperty

	#tag Property, Flags = &h0
		Temps() As Double
	#tag EndProperty

	#tag Property, Flags = &h0
		Times() As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mHistoryLoaded As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastStored As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLastStoredPos As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mLink As MeshDeviceLink
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mMyNum As UInt32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mOn As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mRetry As Timer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTrack As PositionTrack
	#tag EndProperty

	#tag Constant, Name = kMaxSamples, Type = Double, Dynamic = False, Default = \"100", Scope = Private
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
