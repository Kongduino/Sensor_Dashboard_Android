#tag Module
Protected Module SensorData
	#tag Note, Name = About
		The data side of Sensor_Dashboard, shared by the desktop app and the Android app (same file in both repositories:
		keep them identical). The database (records.sqlite: telemetry, sessions, logtypes, positions), the session, the
		event log, parsing of positions, AQI answers and channel keys, and the CSV / GPX writers. Nothing here refers to a
		window or a control; it compiles for Android (no Join, explicit parentheses, see Sensor_Dashboard_Android/log.md).
	#tag EndNote


	#tag Method, Flags = &h0
		Function NodeNumber(num As UInt32) As Int64
		  // A Meshtastic node number (unsigned 32-bit) as stored in the database. On Android, a UInt32 above 2^31 becomes
		  // negative when widened (sign extension): corrected here, so both apps store the same positive numbers
		  Dim n As Int64 = num
		  If n < 0 Then n = n + 4294967296
		  Return n
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function HexText(num As UInt64, digits As Integer) As String
		  // num as digits uppercase hex digits (the lowest ones). On Android, Hex() keeps only 32 bits (an M5Stack id has 48)
		  Dim hexDigits As String = "0123456789ABCDEF"
		  Dim v As UInt64 = num
		  Dim t As String
		  For i As Integer = 1 To digits
		    Dim d As Integer = v Mod 16
		    t = hexDigits.Middle(d, 1) + t
		    v = v \ 16
		  Next
		  Return t
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function HexValue(text As String) As UInt64
		  // Hex digits as a number, with an optional "!", "&H" or "0x" in front (node ids, M5Stack device ids). On Android,
		  // Val("&H…") gives 0: this parses the digits itself (stopping at the first non-hex character)
		  Dim t As String = text.Trim
		  If t.Left(1) = "!" Then t = t.Middle(1)
		  Dim lead As String = t.Left(2).Lowercase
		  If lead = "&h" Or lead = "0x" Then t = t.Middle(2)
		  Dim lower As String = t.Lowercase
		  Dim hexDigits As String = "0123456789abcdef"
		  Dim v As UInt64 = 0
		  For i As Integer = 0 To lower.Length - 1
		    Dim d As Integer = hexDigits.IndexOf(lower.Middle(i, 1))
		    If d < 0 Then Return v
		    v = v * 16 + d
		  Next
		  Return v
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function TelemetryRows(logType As Integer, fromID As Int64, senderID As Int64) As RowSet
		  // Every stored reading of a source (all sessions), oldest first, with all columns (for WriteTelemetryCSV).
		  // fromID / senderID of -1 match any
		  Dim cond As String = "logType=" + Str(logType)
		  If fromID >= 0 Then cond = cond + " AND fromID=" + Format(fromID, "0")
		  If senderID >= 0 Then cond = cond + " AND senderID=" + Format(senderID, "0")
		  Try
		    Return MySensordb.SelectSQL("select * from telemetry where " + cond + " group by timestamp order by timestamp;") // once per time: a restart stores the current reading again
		  Catch e As DatabaseException
		    LogEvents("TelemetryRows", "Database error: " + e.Message)
		    Return Nil
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ChildObject(js As JSONItem, key As String, ByRef child As JSONItem) As Boolean
		  // The JSON object under key, if there is one. Use this rather than Dim x As JSONItem = js.Lookup(key, Nil): on Android,
		  // putting a missing or null value into a JSONItem raises a NilObjectException, and any other value an IllegalCastException
		  child = Nil
		  If js = Nil Then Return False
		  If Not js.HasKey(key) Then Return False
		  Dim v As Variant = js.Value(key)
		  If Not (v IsA JSONItem) Then Return False // null, a number, a string...
		  child = v
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function OpenDatabase(dbFile As FolderItem, ByRef problem As String) As Boolean
		  // Opens records.sqlite (dbFile), creating it with the schema kSqliteCommand when it doesn't exist, then brings
		  // an older database up to date. False, with problem set, when it can't be used
		  problem = ""
		  Dim isNew As Boolean = Not dbFile.Exists
		  MySensordb = New SQLiteDatabase
		  MySensordb.DatabaseFile = dbFile
		  If isNew Then
		    LogEvents("OpenDatabase", "Creating db!")
		    Try
		      MySensordb.CreateDatabase()
		    Catch eCreate As IOException
		      problem = "The database could not be created: " + eCreate.Message
		    Catch eCreateDB As DatabaseException
		      problem = "Database error: " + eCreateDB.Message
		    End Try
		    If problem <> "" Then
		      LogEvents("OpenDatabase", problem)
		      Return False
		    End If
		    Dim statements() As String = kSqliteCommand.SplitBytes(EndOfLine)
		    For Each statement As String In statements
		      Try
		        MySensordb.ExecuteSQL(statement)
		      Catch eSQL As DatabaseException
		        problem = "Database error: " + eSQL.Message + EndOfLine + statement
		        LogEvents("OpenDatabase", problem)
		        Return False
		      End Try
		    Next
		  Else
		    Try
		      MySensordb.Connect()
		    Catch eConnect As IOException
		      problem = "The database exists but could not be connected to: " + eConnect.Message
		    Catch eConnectDB As DatabaseException
		      problem = "The database exists but could not be connected to: " + eConnectDB.Message
		    End Try
		    If problem <> "" Then
		      LogEvents("OpenDatabase", problem)
		      Return False
		    End If
		    LogEvents("OpenDatabase", "Connected to db!")
		  End If
		  // Source types (the table is created with 1 and 2; 3 is added to older databases too)
		  MySensordb.ExecuteSQL("INSERT OR IGNORE INTO logtypes(id, typeName) VALUES (3, 'Meshtastic device');")
		  // GPS positions of Meshtastic nodes (MQTT feeds and devices), for the Map tabs
		  MySensordb.ExecuteSQL("CREATE TABLE IF NOT EXISTS positions(posID INTEGER PRIMARY KEY, sessionID INTEGER, " + _
		  "timestamp INTEGER, fromID INTEGER, senderID INTEGER, latitude REAL, longitude REAL, altitude INTEGER, " + _
		  "precisionBits INTEGER, sats INTEGER, rssi INTEGER, snr REAL);")
		  // Range tests: one row per packet between a gateway node and a test device (see LogRange)
		  MySensordb.ExecuteSQL("CREATE TABLE IF NOT EXISTS rangetest(rtID INTEGER PRIMARY KEY, sessionID INTEGER, timestamp INTEGER, " + _
		  "gatewayID INTEGER, deviceID INTEGER, direction INTEGER, status TEXT, method TEXT, packetID INTEGER, seq INTEGER, label TEXT, " + _
		  "rssi INTEGER, snr REAL, hops INTEGER, hopStart INTEGER, relayNode INTEGER, viaMQTT INTEGER, " + _
		  "latitude REAL, longitude REAL, altitude INTEGER, posSource TEXT);")
		  // One-time repairs of data an earlier Android version stored wrongly (nothing to do on desktop): node numbers above
		  // 2^31 stored as negative numbers (see NodeNumber), and AQI readings stored with device 0 (Val("&H…") is 0 on Android)
		  Try
		    MySensordb.ExecuteSQL("UPDATE positions SET fromID = fromID + 4294967296 WHERE fromID < 0;")
		    MySensordb.ExecuteSQL("UPDATE positions SET senderID = senderID + 4294967296 WHERE senderID < 0;")
		    MySensordb.ExecuteSQL("UPDATE telemetry SET fromID = fromID + 4294967296 WHERE fromID < 0 AND logType <> 1;")
		    MySensordb.ExecuteSQL("UPDATE telemetry SET senderID = senderID + 4294967296 WHERE senderID < 0 AND logType <> 1;")
		    MySensordb.ExecuteSQL("DELETE FROM telemetry WHERE logType = 1 AND fromID = 0;")
		  Catch eRepair As DatabaseException
		    LogEvents("OpenDatabase", "Repair: " + eRepair.Message)
		  End Try
		  // Columns that came later, added to tables created before them: rssi / snr (positions), then how a packet reached
		  // the gateway or connected node (both tables): hops (NULL when unknown), hopStart, relayNode, viaMQTT (see
		  // MeshLastPacketRadio). The existing columns are asked first rather than relying on the "duplicate column" error
		  // (the debugger stops on it, and Android may raise another exception type)
		  Dim tables() As String = Array("positions", "telemetry")
		  Dim radioNames() As String = Array("rssi", "snr", "hops", "hopStart", "relayNode", "viaMQTT")
		  Dim radioTypes() As String = Array("INTEGER", "REAL", "INTEGER", "INTEGER", "INTEGER", "INTEGER")
		  For Each table As String In tables
		    Dim existing() As String
		    Dim info As RowSet = MySensordb.SelectSQL("PRAGMA table_info(" + table + ");")
		    While Not info.AfterLastRow
		      existing.Add(info.Column("name").StringValue.Lowercase)
		      info.MoveToNextRow()
		    Wend
		    For i As Integer = 0 To radioNames.LastIndex
		      If existing.IndexOf(radioNames(i).Lowercase) < 0 Then
		        MySensordb.ExecuteSQL("ALTER TABLE " + table + " ADD COLUMN " + radioNames(i) + " " + radioTypes(i) + ";")
		        LogEvents("OpenDatabase", "Column " + table + "." + radioNames(i) + " added")
		      End If
		    Next
		  Next
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub StartSession(sessionID As String)
		  // Records this run as a session (sessionID: a new UUID) and sets MySessionID and MySessionNum, which every
		  // stored reading carries
		  MySessionID = sessionID
		  Dim dt As DateTime = DateTime.Now()
		  Dim cmd As String = "INSERT INTO sessions(fullID, timestamp) VALUES (""" + MySessionID + """, " + Format(dt.SecondsFrom1970, "00000000") + ");"
		  LogEvents("StartSession", cmd)
		  MySensordb.ExecuteSQL(cmd)
		  Dim rs As RowSet = MySensordb.SelectSQL("SELECT sessionID from sessions where fullID='" + MySessionID + "'")
		  MySessionNum = rs.ColumnAt(0).IntegerValue
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub LogEvents(origin As String, txt As String)
		  // The session's event log, when one is open (EventLogTOS)
		  If EventLogTOS = Nil Then Return
		  Dim d As DateTime = DateTime.Now()
		  Dim s As String
		  s = Format(d.Hour, "00") + ":" +  Format(d.Minute, "00") + _
		  ":" + Format(d.Second, "00") + Chr(9) + origin + Chr(9) + txt
		  
		  EventLogTOS.WriteLine(s)
		  EventLogTOS.Flush()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub LogTelemetry(logType As Integer, fromID As String, senderID As String, TS As String, payload As String, rssi As Double, snr As Double, sessionID As Integer, hops As Integer = -1, hopStart As Integer = 0, relayNode As Integer = 0, viaMQTT As Boolean = False)
		  // One reading in the telemetry table. rssi / snr: -255 when unknown; hops ... viaMQTT: how the packet reached
		  // the gateway or connected node (see MeshLastPacketRadio; hops -1 = unknown, stored as NULL)
		  Dim cmd, pl As String
		  Dim rs As Integer
		  rs = rssi
		  
		  pl = payload.ReplaceAllBytes("""", "'")
		  
		  cmd = "INSERT INTO telemetry(logType, sessionID, timestamp, fromID, senderID, rssi, snr, payload, hops, hopStart, relayNode, viaMQTT)" + _
		  " VALUES (" + Str(logType) + ", " + Str(sessionID) + ", " + TS + ", " + fromID + ", " + _
		  senderID + ", " + FormatValue(rs, "-0") + ", " + FormatValue(snr, "-0.00") + ", """ + pl + """, " + _
		  HopsSQL(hops, hopStart, relayNode, viaMQTT) + ");"
		  
		  LogEvents "LogTelemetry", cmd
		  MySensordb.ExecuteSQL(cmd)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub LogPosition(fromID As Int64, senderID As Int64, ts As Integer, lat As Double, lon As Double, alt As Integer, precision As Integer, sats As Integer, rssi As Integer = -255, snr As Double = -255, hops As Integer = -1, hopStart As Integer = 0, relayNode As Integer = 0, viaMQTT As Boolean = False)
		  // One position in the positions table (fromID: the node, senderID: the gateway or connected node;
		  // rssi / snr as the gateway or connected node received it, -255 when unknown, e.g. its own packets;
		  // hops ... viaMQTT: how the packet reached it, see LogTelemetry)
		  Dim cmd As String = "INSERT INTO positions(sessionID, timestamp, fromID, senderID, latitude, longitude, altitude, precisionBits, sats, rssi, snr, hops, hopStart, relayNode, viaMQTT) VALUES (" + _
		  Str(MySessionNum) + ", " + Str(ts) + ", " + Format(fromID, "0") + ", " + Format(senderID, "0") + ", " + _
		  FormatValue(lat, "-0.0000000") + ", " + FormatValue(lon, "-0.0000000") + ", " + Str(alt) + ", " + Str(precision) + ", " + Str(sats) + ", " + _
		  Str(rssi) + ", " + FormatValue(snr, "-0.00") + ", " + HopsSQL(hops, hopStart, relayNode, viaMQTT) + ");"
		  LogEvents "LogPosition", cmd
		  Try
		    MySensordb.ExecuteSQL(cmd)
		  Catch e As DatabaseException
		    LogEvents "LogPosition", "Database error: " + e.Message
		  End Try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LogRange(gatewayID As Int64, deviceID As Int64, direction As Integer, status As String, method As String, packetID As UInt32, seq As Integer, label As String, rssi As Integer, snr As Double, hops As Integer, hopStart As Integer, relayNode As Integer, viaMQTT As Boolean, lat As Double, lon As Double, alt As Integer, posSource As String) As Int64
		  // One range-test row; returns its rtID (0 on error). direction: 1 gateway -> device, 2 device -> gateway.
		  // status: "heard", "sent" (a test message not reported yet), "missed". method: "mqtt" (the device's upload) or
		  // "tcp" (the gateway's link). seq: the test message's number (0 for other packets). posSource: "phone", "device",
		  // or "" (no position: latitude / longitude NULL). rssi / snr -255 when unknown; hops -1 unknown (NULL)
		  Dim position As String = "NULL, NULL, NULL"
		  If posSource <> "" Then position = FormatValue(lat, "-0.0000000") + ", " + FormatValue(lon, "-0.0000000") + ", " + Str(alt)
		  Dim cmd As String = "INSERT INTO rangetest(sessionID, timestamp, gatewayID, deviceID, direction, status, method, packetID, seq, label, " + _
		  "rssi, snr, hops, hopStart, relayNode, viaMQTT, latitude, longitude, altitude, posSource) VALUES (" + _
		  Str(MySessionNum) + ", " + Format(DateTime.Now().SecondsFrom1970, "0") + ", " + Format(gatewayID, "0") + ", " + Format(deviceID, "0") + ", " + _
		  Str(direction) + ", " + SQLText(status) + ", " + SQLText(method) + ", " + Format(NodeNumber(packetID), "0") + ", " + Str(seq) + ", " + SQLText(label) + ", " + _
		  Str(rssi) + ", " + FormatValue(snr, "-0.00") + ", " + HopsSQL(hops, hopStart, relayNode, viaMQTT) + ", " + position + ", " + SQLText(posSource) + ");"
		  LogEvents "LogRange", cmd
		  Try
		    MySensordb.ExecuteSQL(cmd)
		    Dim rs As RowSet = MySensordb.SelectSQL("SELECT last_insert_rowid() AS id;")
		    Return rs.Column("id").Int64Value
		  Catch e As DatabaseException
		    LogEvents "LogRange", "Database error: " + e.Message
		    Return 0
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub UpdateRange(rtID As Int64, status As String, rssi As Integer, snr As Double, hops As Integer, hopStart As Integer, relayNode As Integer, viaMQTT As Boolean)
		  // A sent test message reported by the device ("heard", with its reception) or given up on ("missed")
		  Dim h As String = "NULL"
		  If hops >= 0 Then h = Str(hops)
		  Dim cmd As String = "UPDATE rangetest SET status=" + SQLText(status) + ", method='mqtt', rssi=" + Str(rssi) + ", snr=" + FormatValue(snr, "-0.00") + _
		  ", hops=" + h + ", hopStart=" + Str(hopStart) + ", relayNode=" + Str(relayNode) + ", viaMQTT=" + If(viaMQTT, "1", "0") + _
		  " WHERE rtID=" + Format(rtID, "0") + ";"
		  LogEvents "UpdateRange", cmd
		  Try
		    MySensordb.ExecuteSQL(cmd)
		  Catch e As DatabaseException
		    LogEvents "UpdateRange", "Database error: " + e.Message
		  End Try
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function RangeRows(gatewayID As Int64, deviceID As Int64) As RowSet
		  // Every range-test row of this gateway and device (all sessions), oldest first
		  Try
		    Return MySensordb.SelectSQL("SELECT * FROM rangetest WHERE gatewayID=" + Format(gatewayID, "0") + " AND deviceID=" + Format(deviceID, "0") + _
		    " ORDER BY timestamp, rtID;")
		  Catch e As DatabaseException
		    LogEvents "RangeRows", "Database error: " + e.Message
		    Return Nil
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SQLText(t As String) As String
		  // A text value for SQL, quoted
		  Return "'" + t.ReplaceAll("'", "''") + "'"
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub WriteRangeCSV(rs As RowSet, fi As FolderItem)
		  // A range test as ";"-separated text, one row per packet, oldest first. rssi / snr describe the link only when
		  // hops is 0 and via_mqtt 0; a sent test message nobody reported has status "missed" (or "sent" while waiting)
		  If fi.Exists Then fi.Remove()
		  Dim tos As TextOutputStream = TextOutputStream.Create(fi)
		  tos.WriteLine("timestamp;direction;status;method;seq;label;packet_id;rssi;snr;hops;relay_node;via_mqtt;latitude;longitude;altitude;position_source")
		  Dim t() As String
		  rs.MoveToFirstRow()
		  While Not rs.AfterLastRow
		    t.RemoveAll()
		    Dim dt As New DateTime(rs.Column("timestamp").IntegerValue)
		    t.Add(dt.SQLDateTime)
		    t.Add(If(rs.Column("direction").IntegerValue = 1, "gateway->device", "device->gateway"))
		    t.Add(rs.Column("status").StringValue)
		    t.Add(rs.Column("method").StringValue)
		    t.Add(If(rs.Column("seq").IntegerValue > 0, rs.Column("seq").StringValue, ""))
		    t.Add(rs.Column("label").StringValue)
		    t.Add(rs.Column("packetID").StringValue)
		    t.Add(If(rs.Column("rssi").IntegerValue = -255, "", rs.Column("rssi").StringValue))
		    t.Add(If(rs.Column("snr").DoubleValue = -255, "", FormatValue(rs.Column("snr").DoubleValue, "-0.00")))
		    t.Add(If(rs.Column("hops").Value.IsNull, "", rs.Column("hops").StringValue))
		    Dim relay As Integer = rs.Column("relayNode").IntegerValue
		    t.Add(If(relay = 0, "", HexText(relay, 2).Lowercase))
		    t.Add(If(rs.Column("viaMQTT").IntegerValue = 1, "1", "0"))
		    If rs.Column("latitude").Value.IsNull Then
		      t.Add("")
		      t.Add("")
		      t.Add("")
		    Else
		      t.Add(FormatValue(rs.Column("latitude").DoubleValue, "-0.0000000"))
		      t.Add(FormatValue(rs.Column("longitude").DoubleValue, "-0.0000000"))
		      t.Add(rs.Column("altitude").StringValue)
		    End If
		    t.Add(rs.Column("posSource").StringValue)
		    tos.WriteLine(String.FromArray(t, ";"))
		    rs.MoveToNextRow()
		  Wend
		  tos.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function HopsSQL(hops As Integer, hopStart As Integer, relayNode As Integer, viaMQTT As Boolean) As String
		  // The hops, hopStart, relayNode, viaMQTT values of an INSERT: hops -1 (unknown) is NULL
		  Dim h As String = "NULL"
		  If hops >= 0 Then h = Str(hops)
		  Return h + ", " + Str(hopStart) + ", " + Str(relayNode) + ", " + If(viaMQTT, "1", "0")
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsDirect(hops As Integer, viaMQTT As Boolean) As Boolean
		  // RSSI / SNR describe the link to the sender only for a packet heard directly by radio
		  Return hops = 0 And Not viaMQTT
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function HistoryRows(logType As Integer, fromID As Int64, senderID As Int64, before As Int64 = 0) As RowSet
		  // The latest stored readings of a source, from every session, oldest first: at most 100 (what the charts
		  // keep). fromID / senderID of -1 match any; before > 0 keeps only readings older than that time. A reading
		  // stored twice (the same timestamp in two sessions) comes once
		  Dim cond As String = "logType=" + Str(logType)
		  If fromID >= 0 Then cond = cond + " AND fromID=" + Format(fromID, "0")
		  If senderID >= 0 Then cond = cond + " AND senderID=" + Format(senderID, "0")
		  If before > 0 Then cond = cond + " AND timestamp<" + Format(before, "0")
		  // rssi / snr only for packets heard directly (-255 otherwise, as for unknown hops: see IsDirect)
		  Dim cmd As String = "select * from (select timestamp, payload, " + _
		  "CASE WHEN hops = 0 AND viaMQTT = 0 THEN rssi ELSE -255 END AS rssi, " + _
		  "CASE WHEN hops = 0 AND viaMQTT = 0 THEN snr ELSE -255 END AS snr from telemetry where " + cond + _
		  " group by timestamp order by timestamp desc limit 100) order by timestamp;"
		  LogEvents "HistoryRows", cmd
		  Try
		    Return MySensordb.SelectSQL(cmd)
		  Catch e As DatabaseException
		    LogEvents "HistoryRows", "Database error: " + e.Message
		    Return Nil
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function PositionRows(fromID As Int64) As RowSet
		  // The node's latest stored positions (every session, at most PositionTrack.kMaxPositions), oldest first;
		  // a position stored twice (the same time) comes once
		  Dim cmd As String = "select * from (select timestamp, latitude, longitude, altitude, precisionBits, sats, rssi, snr, hops, viaMQTT from positions " + _
		  "where fromID=" + Format(fromID, "0") + " group by timestamp order by timestamp desc limit 500) order by timestamp;"
		  Try
		    Return MySensordb.SelectSQL(cmd)
		  Catch e As DatabaseException
		    LogEvents "PositionRows", "Database error: " + e.Message
		    Return Nil
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ParsePosition(js As JSONItem, ByRef ts As Integer, ByRef lat As Double, ByRef lon As Double, ByRef alt As Integer, ByRef precision As Integer, ByRef sats As Integer) As Boolean
		  // A "position" packet as converter JSON (payload: latitude_i / longitude_i in 1e-7 degrees, altitude, time,
		  // precision_bits, sats_in_view). False when it holds no valid fix (0 / 0, or out of range)
		  If js.Lookup("type", "").StringValue <> "position" Then Return False
		  Dim payload As JSONItem
		  If Not ChildObject(js, "payload", payload) Then Return False
		  Dim latI As Int64 = payload.Lookup("latitude_i", 0).Int64Value
		  Dim lonI As Int64 = payload.Lookup("longitude_i", 0).Int64Value
		  If latI = 0 And lonI = 0 Then Return False // no fix
		  lat = latI / 1e7
		  lon = lonI / 1e7
		  If Abs(lat) > 90 Or Abs(lon) > 180 Then Return False
		  alt = payload.Lookup("altitude", 0).IntegerValue
		  precision = payload.Lookup("precision_bits", 32).IntegerValue
		  sats = payload.Lookup("sats_in_view", 0).IntegerValue
		  // The fix's own time when the node has one, else when the packet was received, else now
		  ts = payload.Lookup("time", 0).IntegerValue
		  If ts <= 0 Then ts = js.Lookup("timestamp", 0).IntegerValue
		  If ts <= 0 Then ts = DateTime.Now().SecondsFrom1970
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ParseAQIResponse(content As String, ByRef values As JSONItem, ByRef updateTime As String, ByRef nickname As String, ByRef periodicity As Integer, ByRef problem As String) As Boolean
		  // One answer of https://ezdata2.m5stack.com/api/v2/<device id>/dataMacByKey/raw:
		  // {"code":200, "data":{"value":"<escaped JSON>", "updateTime":"<seconds>", ...}}
		  // Fills values (the decoded value: sen55, scd40, rtc, profile), updateTime, nickname and periodicity.
		  // False, with problem set, if any part is missing (this replaces curl + AirQ_json_parse.py)
		  Dim js As JSONItem
		  Try
		    js = New JSONItem(content)
		  Catch e As RuntimeException
		    problem = "the answer is not JSON (" + e.Message + ")"
		    Return False
		  End Try
		  
		  // An error answer has "data": null (e.g. code 500 when M5Stack's own database is down)
		  Dim data As JSONItem
		  If Not ChildObject(js, "data", data) Then
		    // The server's message can be a whole Java stack trace: the log gets all of it, the problem only its start
		    Dim msg As String = js.Lookup("msg", "").StringValue
		    LogEvents("ParseAQIResponse", "No data, code " + js.Lookup("code", "?").StringValue + ": " + msg)
		    Dim oneLine As String = msg.ReplaceLineEndings(" ")
		    Dim shortMsg As String = oneLine.Trim
		    If shortMsg.Length > 60 Then shortMsg = shortMsg.Left(60) + "…"
		    problem = "server error (code " + js.Lookup("code", "?").StringValue + ")" + If(shortMsg <> "", ": " + shortMsg, "")
		    Return False
		  End If
		  
		  Dim v As Variant = data.Lookup("value", Nil)
		  values = Nil
		  If v IsA JSONItem Then
		    values = v // already an object (dataType "object")
		  ElseIf v.Type = Variant.TypeString Then
		    values = DecodeAQIValue(v.StringValue)
		  End If
		  If values = Nil Or values.Count = 0 Then
		    problem = "no readable 'value' node"
		    Return False
		  End If
		  
		  Dim updated As String = data.Lookup("updateTime", "").StringValue
		  If updated = "" Then
		    problem = "no 'updateTime' node"
		    Return False
		  End If
		  
		  Dim profile, rtc As JSONItem
		  If Not ChildObject(values, "profile", profile) Or Not ChildObject(values, "rtc", rtc) Then
		    problem = "no 'profile' or 'rtc' node"
		    Return False
		  End If
		  If Not (values.HasKey("sen55") And values.HasKey("scd40")) Then
		    problem = "no 'sen55' or 'scd40' node"
		    Return False
		  End If
		  
		  Dim nick As String = profile.Lookup("nickname", "").StringValue
		  If nick = "" Then
		    problem = "no nickname"
		    Return False
		  End If
		  Dim interval As Integer = rtc.Lookup("sleep_interval", -1).IntegerValue
		  If interval <= 0 Then
		    problem = "no sleep_interval"
		    Return False
		  End If
		  
		  updateTime = updated
		  nickname = nick
		  periodicity = interval
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DecodeAQIValue(value As String) As JSONItem
		  // data.value is a JSON object written as a string, possibly escaped once more ({\"sen55\":...}).
		  // Same tries as parse_escaped_json in the former AirQ_json_parse.py. An empty JSONItem if none works
		  // The M5Stack's usual form is escaped ({\"sen55\":...}): then the unescaping comes first, so a normal reading
		  // raises no exception (the debugger stops on every one, even when caught)
		  Dim escaped As Boolean = value.IndexOf("\""") >= 0
		  If Not escaped Then
		    Try
		      Return New JSONItem(value)
		    Catch e1 As RuntimeException
		    End Try
		  End If
		  
		  // Escaped: unescaping the quotes is enough for the M5Stack's answers (tried first: reading the text out of a one-element
		  // JSON array, below, raises an IllegalCastException on Android)
		  If escaped Then
		    Try
		      Return New JSONItem(value.ReplaceAll("\""", """"))
		    Catch e0 As RuntimeException
		    End Try
		  End If
		  
		  // Unescape one layer: read the text as the content of a JSON string
		  Try
		    Dim wrapper As New JSONItem("[""" + value + """]")
		    Return New JSONItem(wrapper.ValueAt(0).StringValue)
		  Catch e2 As RuntimeException
		  End Try
		  
		  // Escaped text that the unescaping didn't help: as it is
		  If escaped Then
		    Try
		      Return New JSONItem(value)
		    Catch e4 As RuntimeException
		    End Try
		  End If
		  
		  // Last resort: only unescape the quotes
		  Try
		    Return New JSONItem(value.ReplaceAll("\""", """"))
		  Catch e3 As RuntimeException
		  End Try
		  Return New JSONItem // empty, not Nil: on Android a Nil JSONItem result raises an exception in the caller
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ParseChannelKeys(keys As String, names() As String, psks() As String, ByRef fallback As String, ByRef problem As String) As Boolean
		  // The Keys field of an MQTT feed: "Channel=PSK" entries separated by ";" (or ","), PSK as the Meshtastic
		  // app shows it (base64, e.g. AQ==) or any format MeshParsePSK takes. An entry with no channel name is the
		  // key for every other channel (like --psk of the former script). Empty field: AQ== for every channel.
		  // Fills names/psks and fallback; False, with problem set, if an entry can't be used
		  names.RemoveAll
		  psks.RemoveAll
		  fallback = "AQ=="
		  problem = ""
		  Dim entries() As String = keys.ReplaceAll(",", ";").Split(";")
		  For Each rawEntry As String In entries
		    Dim entry As String = rawEntry.Trim
		    If entry = "" Then Continue
		    Dim name As String = ""
		    Dim psk As String = entry
		    Dim eq As Integer = entry.IndexOf("=")
		    // base64 keys end with "=": a "=" only counts as the separator if a key follows it
		    If eq > 0 Then
		      Dim tail As String = entry.Middle(eq + 1).Trim
		      If tail.ReplaceAll("=", "") <> "" Then
		        name = entry.Left(eq).Trim
		        psk = tail
		      End If
		    End If
		    Dim pskBytes As String
		    If Not MeshParsePSK(psk, pskBytes) Then
		      problem = """" + psk + """ is not a key (base64 as in the Meshtastic app, or hex)"
		      Return False
		    End If
		    Dim n As Integer = pskBytes.Bytes
		    If n <> 0 And n <> 1 And n <> 16 And n <> 32 Then
		      problem = """" + psk + """ is " + Str(n) + " bytes long: a channel key has 1, 16 or 32 bytes"
		      Return False
		    End If
		    If name = "" Then
		      fallback = psk
		    Else
		      names.Add name
		      psks.Add psk
		    End If
		  Next
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function MeanOf(values() As Double) As Double
		  // Average of all the samples, 0 when there are none yet
		  If values.Count = 0 Then Return 0
		  Dim total As Double
		  For Each v As Double In values
		    total = total + v
		  Next
		  Return total / values.Count
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub WriteTelemetryCSV(rs As RowSet, fi As FolderItem, idColumn As String, withRadio As Boolean)
		  // The CSV of every export, so they all look the same: ";"-separated, one row per reading, oldest first.
		  // Columns: timestamp, the source (idColumn: "node" as !aabbccdd, or "device" as 12 hex digits), for MQTT
		  // the gateway, rssi and snr, then one column per payload key, over all rows (a key missing from a row,
		  // or a radio value the packet didn't have, is an empty cell)
		  Dim keys() As String
		  rs.MoveToFirstRow()
		  While Not rs.AfterLastRow
		    Dim pl As JSONItem = RowPayload(rs)
		    For Each k As String In pl.Keys()
		      If keys.IndexOf(k) < 0 Then keys.Add k
		    Next
		    rs.MoveToNextRow()
		  Wend
		  
		  If fi.Exists Then fi.Remove()
		  Dim tos As TextOutputStream = TextOutputStream.Create(fi)
		  Dim t() As String
		  t.Add "timestamp"
		  t.Add idColumn
		  If withRadio Then
		    t.Add "gateway"
		    t.Add "rssi"
		    t.Add "snr"
		    t.Add "hops"
		    t.Add "relay_node"
		    t.Add "via_mqtt"
		  End If
		  For Each k As String In keys
		    t.Add k
		  Next
		  tos.WriteLine(String.FromArray(t, ";"))
		  
		  rs.MoveToFirstRow()
		  While Not rs.AfterLastRow
		    t.RemoveAll
		    Dim dt As New DateTime(rs.Column("timestamp").IntegerValue)
		    t.Add dt.SQLDateTime
		    t.Add SourceID(rs.Column("fromID").Int64Value, idColumn)
		    If withRadio Then
		      t.Add SourceID(rs.Column("senderID").Int64Value, "node")
		      If rs.Column("rssi").IntegerValue = -255 Then
		        t.Add ""
		      Else
		        t.Add rs.Column("rssi").StringValue
		      End If
		      If rs.Column("snr").DoubleValue = -255 Then
		        t.Add ""
		      Else
		        t.Add FormatValue(rs.Column("snr").DoubleValue, "-0.00")
		      End If
		      // How the packet reached the gateway: rssi / snr describe the sender's link only when hops is 0 and via_mqtt 0.
		      // relay_node is the last byte of the relaying node, in hex
		      If rs.Column("hops").Value.IsNull Then
		        t.Add ""
		      Else
		        t.Add rs.Column("hops").StringValue
		      End If
		      Dim relay As Integer = rs.Column("relayNode").IntegerValue
		      If relay = 0 Then
		        t.Add ""
		      Else
		        t.Add HexText(relay, 2).Lowercase
		      End If
		      t.Add If(rs.Column("viaMQTT").IntegerValue = 1, "1", "0")
		    End If
		    Dim rowPL As JSONItem = RowPayload(rs)
		    For Each k As String In keys
		      If rowPL.HasKey(k) Then
		        t.Add FormatValue(rowPL.Value(k).DoubleValue, "-0.00")
		      Else
		        t.Add ""
		      End If
		    Next
		    tos.WriteLine(String.FromArray(t, ";"))
		    rs.MoveToNextRow()
		  Wend
		  tos.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub WritePositionsCSV(track As PositionTrack, f As FolderItem)
		  // The positions of a track as ";"-separated text, oldest first (an IOException goes to the caller)
		  If f.Exists Then f.Remove()
		  Dim tos As TextOutputStream = TextOutputStream.Create(f)
		  tos.WriteLine("timestamp;latitude;longitude;altitude;precision_bits;sats;rssi;snr;hops;via_mqtt")
		  Dim t() As String
		  For i As Integer = 0 To track.Count() - 1
		    t.RemoveAll()
		    Dim dt As New DateTime(track.Times(i))
		    t.Add(dt.SQLDateTime)
		    t.Add(FormatValue(track.Lats(i), "-0.0000000"))
		    t.Add(FormatValue(track.Lons(i), "-0.0000000"))
		    t.Add(Str(track.Alts(i)))
		    t.Add(Str(track.Precisions(i)))
		    t.Add(Str(track.SatCounts(i)))
		    t.Add(If(track.Rssis(i) = -255, "", Str(track.Rssis(i))))
		    t.Add(If(track.Snrs(i) = -255, "", FormatValue(track.Snrs(i), "-0.00")))
		    t.Add(If(track.Hops(i) < 0, "", Str(track.Hops(i))))
		    t.Add(If(track.ViaMQTTs(i), "1", "0"))
		    tos.WriteLine(String.FromArray(t, ";"))
		  Next
		  tos.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub WritePositionsGPX(track As PositionTrack, f As FolderItem, trackName As String)
		  // The positions of a track as a GPX 1.1 track (opens in GPX viewers, Google Earth, OsmAnd...), times in UTC
		  // (an IOException goes to the caller)
		  If f.Exists Then f.Remove()
		  Dim tos As TextOutputStream = TextOutputStream.Create(f)
		  tos.WriteLine("<?xml version=""1.0"" encoding=""UTF-8""?>")
		  tos.WriteLine("<gpx version=""1.1"" creator=""Sensor_Dashboard"" xmlns=""http://www.topografix.com/GPX/1/1"">")
		  tos.WriteLine("  <trk><name>" + trackName + "</name><trkseg>")
		  Dim utc As New TimeZone(0)
		  For i As Integer = 0 To track.Count() - 1
		    Dim d As New DateTime(track.Times(i), utc)
		    Dim iso As String = Format(d.Year, "0000") + "-" + Format(d.Month, "00") + "-" + Format(d.Day, "00") + "T" + _
		    Format(d.Hour, "00") + ":" + Format(d.Minute, "00") + ":" + Format(d.Second, "00") + "Z"
		    Dim pt As String = "    <trkpt lat=""" + FormatValue(track.Lats(i), "-0.0000000") + """ lon=""" + FormatValue(track.Lons(i), "-0.0000000") + """>"
		    If track.Alts(i) <> 0 Then pt = pt + "<ele>" + Str(track.Alts(i)) + "</ele>"
		    pt = pt + "<time>" + iso + "</time>"
		    If track.SatCounts(i) > 0 Then pt = pt + "<sat>" + Str(track.SatCounts(i)) + "</sat>"
		    tos.WriteLine(pt + "</trkpt>")
		  Next
		  tos.WriteLine("  </trkseg></trk>")
		  tos.WriteLine("</gpx>")
		  tos.Close()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function RowPayload(rs As RowSet) As JSONItem
		  // The payload of the current row (stored with ' for "), an empty object if it can't be read
		  Try
		    Return New JSONItem(rs.Column("payload").StringValue.ReplaceAllBytes("'", """"))
		  Catch e As RuntimeException
		    Return New JSONItem
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function SourceID(num As Int64, kind As String) As String
		  // "node": !aabbccdd (8 lowercase hex digits); "device": an M5Stack id, 12 uppercase hex digits
		  If kind = "device" Then Return HexText(num, 12)
		  Dim h As String = HexText(num, 8)
		  Return "!" + h.Lowercase
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		EventLogTOS As TextOutputStream
	#tag EndProperty

	#tag Property, Flags = &h0
		MySensordb As SQLiteDatabase
	#tag EndProperty

	#tag Property, Flags = &h0
		MySessionID As String
	#tag EndProperty

	#tag Property, Flags = &h0
		MySessionNum As Integer
	#tag EndProperty


	#tag Constant, Name = kSqliteCommand, Type = String, Dynamic = False, Default = \"CREATE TABLE telemetry(hitID INTEGER PRIMARY KEY\x2C logType INTEGER\x2C sessionID INTEGER\x2C timestamp INTEGER\x2C fromID INTEGER\x2C senderID INTEGER\x2C rssi INTEGER\x2C snr REAL\x2C payload TEXT);\nCREATE TABLE sessions(sessionID INTEGER PRIMARY KEY\x2C fullID TEXT NOT NULL UNIQUE\x2C timestamp TEXT);\nCREATE TABLE logtypes(id INTEGER PRIMARY KEY\x2C typeName TEXT NOT NULL UNIQUE);\nINSERT INTO logtypes(id\x2C typeName) VALUES (1\x2C \'M5 AQI\');\nINSERT INTO logtypes(id\x2C typeName) VALUES (2\x2C \'Meshtastic MQTT\');", Scope = Public
	#tag EndConstant


	#tag ViewBehavior
	#tag EndViewBehavior
End Module
#tag EndModule
