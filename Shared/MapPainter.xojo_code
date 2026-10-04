#tag Class
Protected Class MapPainter
	#tag Note, Name = About
		Sensor_Dashboard's map, without the control: a PositionTrack on OpenStreetMap tiles (fetched one at a time,
		cached on disk in CacheFolder/tiles), fitted to every position, with the track, the points (the latest larger),
		precision circles for approximate positions, the +/−/Fit buttons and the inspected position. Paint(g, w, h) draws
		it; HitButton, StartDrag / DragTo / EndDrag, ZoomAt, Wheel and HoverAt act on it and say whether to redraw; Changed
		is raised when a tile arrives. MapView (desktop) and MobileMapView (Android) are thin controls around it.
		Shared with the Android version: keep identical in both repositories.
	#tag EndNote


	#tag Method, Flags = &h21
		Private Function CacheFile(key As String, create As Boolean) As FolderItem
		  // tiles/<z>/<x>/<y>.png in CacheFolder (set by the control: next to settings.json on desktop, the app's own folder
		  // on Android). Nil without a cache folder
		  If CacheFolder = Nil Then Return Nil
		  Dim parts() As String = key.Split("/")
		  Try
		    // Each folder is checked before going into it: on Android, Child of a folder that doesn't exist raises an exception
		    Dim names() As String = Array("tiles", parts(0), parts(1))
		    Dim f As FolderItem = CacheFolder
		    For level As Integer = 0 To names.LastIndex + 1
		      If Not f.Exists Then
		        If Not create Then Return Nil
		        f.CreateFolder()
		      End If
		      If level <= names.LastIndex Then f = f.Child(names(level))
		    Next
		    Return f.Child(parts(2) + ".png")
		  Catch e As RuntimeException
		    Return Nil
		  End Try
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ClearHover() As Boolean
		  // No position inspected any more. True if that changed something (the control then redraws)
		  If mHover < 0 Then Return False
		  mHover = -1
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DragTo(x As Double, y As Double) As Boolean
		  // Panning: the map follows the pointer or finger since StartDrag. True when it moved (the control then redraws);
		  // a movement smaller than a few points is a click or a tap, not a drag
		  If Not mDragging Then Return False
		  If Abs(x - mDragX) + Abs(y - mDragY) < 3 * ControlScale And Not mManual Then Return False
		  mManual = True
		  mOriginX = mDragOriginX - (x - mDragX)
		  mOriginY = mDragOriginY - (y - mDragY)
		  mHover = -1
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub EndDrag()
		  mDragging = False
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub FetchNext()
		  // One tile at a time, as OpenStreetMap's tile usage policy asks, with a User-Agent naming the app. The tile is
		  // written straight to its cache file (FileReceived), so its bytes never pass through a String
		  If mBusy Or mQueue.Count = 0 Then Return
		  mFetching = mQueue(0)
		  mQueue.RemoveAt(0)
		  Dim f As FolderItem = CacheFile(mFetching, True)
		  If f = Nil Then
		    If mFailed = Nil Then mFailed = New Dictionary
		    mFailed.Value(mFetching) = True
		    mFetching = ""
		    Return
		  End If
		  If mConnection = Nil Then
		    mConnection = New URLConnection
		    AddHandler mConnection.FileReceived, WeakAddressOf TileReceived
		    AddHandler mConnection.Error, WeakAddressOf TileError
		  End If
		  mBusy = True
		  mConnection.RequestHeader("User-Agent") = kUserAgent
		  mConnection.Send("GET", "https://tile.openstreetmap.org/" + mFetching + ".png", f)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function FitRect() As Rect
		  Return New Rect(10, 10 + 68 * ControlScale, 32 * ControlScale, 26 * ControlScale)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub FitView()
		  // Back to the automatic view: every position, with a margin (also when another node is shown)
		  mManual = False
		  mHover = -1
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function HitButton(x As Double, y As Double) As Boolean
		  // The + / − / Fit buttons: True when (x, y) was on one (it acted; the control then redraws)
		  If InRect(PlusRect(), x, y) Then
		    Call ZoomAt(mWidth / 2, mHeight / 2, 1)
		    Return True
		  End If
		  If InRect(MinusRect(), x, y) Then
		    Call ZoomAt(mWidth / 2, mHeight / 2, -1)
		    Return True
		  End If
		  If mManual And InRect(FitRect(), x, y) Then
		    FitView()
		    Return True
		  End If
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function HoverAt(x As Double, y As Double, radius As Double = 14) As Boolean
		  // The position nearest to (x, y) within radius, shown in a box (see DrawHover); none when there is none that close.
		  // True if that changed something (the control then redraws)
		  Dim found As Integer = -1
		  If Track <> Nil Then
		    Dim best As Double = radius
		    For i As Integer = 0 To Track.Count() - 1
		      Dim d As Double = Sqrt((ScreenX(Track.Lons(i)) - x) ^ 2 + (ScreenY(Track.Lats(i)) - y) ^ 2)
		      If d <= best Then
		        best = d
		        found = i
		      End If
		    Next
		  End If
		  If found = mHover Then Return False
		  mHover = found
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function InControls(x As Double, y As Double) As Boolean
		  Return InRect(PlusRect(), x, y) Or InRect(MinusRect(), x, y) Or (mManual And InRect(FitRect(), x, y))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function InRect(r As Rect, x As Double, y As Double) As Boolean
		  Return x >= r.Left And x < r.Left + r.Width And y >= r.Top And y < r.Top + r.Height
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsDragging() As Boolean
		  // A drag is on (it moved the map since StartDrag)
		  Return mDragging And mManual
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function MinusRect() As Rect
		  Return New Rect(10, 10 + 34 * ControlScale, 32 * ControlScale, 30 * ControlScale)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Paint(g As Graphics, w As Double, h As Double)
		  // The whole map in a w × h area of g
		  mWidth = w
		  mHeight = h
		  DrawMap(g, w, h)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function PlusRect() As Rect
		  Return New Rect(10, 10, 32 * ControlScale, 30 * ControlScale)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub StartDrag(x As Double, y As Double)
		  // The pointer or finger went down on the map (not on a button): a drag may follow
		  mDragging = True
		  mDragX = x
		  mDragY = y
		  mDragOriginX = mOriginX
		  mDragOriginY = mOriginY
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub TileError(sender As URLConnection, e As RuntimeException)
		  // No network, for example: this tile isn't asked for again in this session
		  mBusy = False
		  If mFailed = Nil Then mFailed = New Dictionary
		  mFailed.Value(mFetching) = True
		  mFetching = ""
		  FetchNext()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub TileReceived(sender As URLConnection, URL As String, HTTPStatus As Integer, file As FolderItem)
		  // The tile is in its cache file: opened from there (a failed download leaves no file behind)
		  mBusy = False
		  Dim key As String = mFetching
		  mFetching = ""
		  Dim p As Picture
		  If HTTPStatus = 200 And file <> Nil Then
		    Try
		      If file.Exists Then p = Picture.Open(file)
		    Catch e As RuntimeException
		      p = Nil
		    End Try
		  End If
		  If p = Nil Then
		    If mFailed = Nil Then mFailed = New Dictionary
		    mFailed.Value(key) = True
		    Try
		      If file <> Nil And file.Exists Then file.Remove()
		    Catch eRemove As RuntimeException
		    End Try
		  Else
		    If mTiles = Nil Then mTiles = New Dictionary
		    mTiles.Value(key) = p
		    RaiseEvent Changed
		  End If
		  FetchNext()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ToPicture(w As Double, h As Double) As Picture
		  // The map as a picture at twice the size (for exports); tiles not downloaded yet show as empty squares
		  Dim p As New Picture(w * 2, h * 2)
		  p.Graphics.ScaleX = 2
		  p.Graphics.ScaleY = 2
		  Dim saved As Integer = mHover
		  mHover = -1
		  mExporting = True // no buttons in the picture
		  // Android: GraphicsPath shapes ignore Graphics.ScaleX / ScaleY (dots, lines and text don't), so in an export at
		  // twice the size the paths get their coordinates scaled by hand (mPathScale); 1 everywhere else
		  #If TargetAndroid Then
		    mPathScale = 2
		  #EndIf
		  DrawMap(p.Graphics, w, h)
		  mPathScale = 1
		  mExporting = False
		  mHover = saved
		  Return p
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Wheel(x As Double, y As Double, deltaY As Integer) As Boolean
		  // A scroll (wheel or two fingers on a trackpad) zooms around the pointer; small steps add up first.
		  // True when the zoom changed
		  mWheel = mWheel + deltaY
		  If mWheel <= -3 Then
		    mWheel = 0
		    Return ZoomAt(x, y, 1)
		  ElseIf mWheel >= 3 Then
		    mWheel = 0
		    Return ZoomAt(x, y, -1)
		  End If
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function ZoomAt(x As Double, y As Double, steps As Integer) As Boolean
		  // One zoom level in (+1) or out (−1), keeping the point under (x, y) in place. True when the zoom changed
		  Dim newZoom As Integer = Max(kMinZoom, Min(kTopZoom, mZoom + steps))
		  If newZoom = mZoom Then Return False
		  Dim factor As Double = 2 ^ (newZoom - mZoom)
		  Dim pointX As Double = (mOriginX + x) * factor
		  Dim pointY As Double = (mOriginY + y) * factor
		  mZoom = newZoom
		  mOriginX = pointX - x
		  mOriginY = pointY - y
		  mManual = True
		  mHover = -1
		  Return True
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DrawButton(g As Graphics, r As Rect, caption As String)
		  g.DrawingColor = Color.RGB(255, 255, 255, 25)
		  g.FillRoundRectangle(r.Left, r.Top, r.Width, r.Height, 8, 8)
		  g.DrawingColor = &cADB5BD
		  g.DrawRoundRectangle(r.Left, r.Top, r.Width, r.Height, 8, 8)
		  g.DrawingColor = &c212529
		  g.DrawText(caption, r.Left + (r.Width - g.TextWidth(caption)) / 2, r.Top + (r.Height + TextAscent(g)) / 2 - 2)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DrawControls(g As Graphics)
		  // + and − at the top left, and Fit below them once the view was moved or zoomed by hand
		  SetTextSize(g, 16, True)
		  DrawButton(g, PlusRect(), "+")
		  DrawButton(g, MinusRect(), "−")
		  SetTextSize(g, 12, True)
		  If mManual Then DrawButton(g, FitRect(), "Fit")
		  SetTextSize(g, 12, False)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ComputeView(w As Double, h As Double)
		  // The zoom and origin that show every position with a margin (one position: street level)
		  If Track = Nil Or Track.Count() = 0 Then
		    mZoom = 2
		    mOriginX = WorldX(0, mZoom) - w / 2
		    mOriginY = WorldY(20, mZoom) - h / 2
		    Return
		  End If
		  Dim minLat As Double = Track.Lats(0)
		  Dim maxLat As Double = minLat
		  Dim minLon As Double = Track.Lons(0)
		  Dim maxLon As Double = minLon
		  For i As Integer = 1 To Track.Count() - 1
		    minLat = Min(minLat, Track.Lats(i))
		    maxLat = Max(maxLat, Track.Lats(i))
		    minLon = Min(minLon, Track.Lons(i))
		    maxLon = Max(maxLon, Track.Lons(i))
		  Next
		  Dim margin As Double = 48
		  mZoom = kMaxZoom
		  While mZoom > 1
		    Dim spanX As Double = WorldX(maxLon, mZoom) - WorldX(minLon, mZoom)
		    Dim spanY As Double = WorldY(minLat, mZoom) - WorldY(maxLat, mZoom)
		    If spanX <= w - 2 * margin And spanY <= h - 2 * margin Then Exit
		    mZoom = mZoom - 1
		  Wend
		  // One spot (a single position, or all at the same place): street level, not the closest zoom
		  If minLat = maxLat And minLon = maxLon Then mZoom = Min(mZoom, kSpotZoom)
		  Dim cx As Double = (WorldX(minLon, mZoom) + WorldX(maxLon, mZoom)) / 2
		  Dim cy As Double = (WorldY(minLat, mZoom) + WorldY(maxLat, mZoom)) / 2
		  mOriginX = cx - w / 2
		  mOriginY = cy - h / 2
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DrawHover(g As Graphics, w As Double)
		  // A box with the time, coordinates, altitude, satellites and reception of the inspected position
		  Dim i As Integer = mHover
		  Dim px As Double = ScreenX(Track.Lons(i))
		  Dim py As Double = ScreenY(Track.Lats(i))
		  Dim lines() As String
		  lines.Add TimeLabel(Track.Times(i), True)
		  lines.Add FormatValue(Track.Lats(i), "-0.000000") + ", " + FormatValue(Track.Lons(i), "-0.000000")
		  Dim extra As String
		  If Track.Alts(i) <> 0 Then extra = Str(Track.Alts(i)) + " m"
		  If Track.SatCounts(i) > 0 Then extra = extra + If(extra = "", "", "  ·  ") + Str(Track.SatCounts(i)) + " sats"
		  If Track.Precisions(i) > 0 And Track.Precisions(i) < 32 Then extra = extra + If(extra = "", "", "  ·  ") + "approximate"
		  If extra <> "" Then lines.Add extra
		  Dim radio As String
		  If Track.Rssis(i) <> -255 Then radio = "RSSI " + Str(Track.Rssis(i)) + " dBm"
		  If Track.Snrs(i) <> -255 Then radio = radio + If(radio = "", "", "  ·  ") + "SNR " + FormatValue(Track.Snrs(i), "-0.0") + " dB"
		  If radio <> "" Then lines.Add radio
		  SetTextSize(g, 12, False)
		  Dim boxWidth As Double
		  For Each t As String In lines
		    boxWidth = Max(boxWidth, g.TextWidth(t))
		  Next
		  boxWidth = boxWidth + 20
		  Dim lineHeight As Double = TextAscent(g) + 6
		  Dim boxHeight As Double = lines.Count * lineHeight + 10
		  Dim boxX As Double = px + 14
		  If boxX + boxWidth > w - 8 Then boxX = px - 14 - boxWidth
		  Dim boxY As Double = Max(8.0, py - boxHeight / 2)
		  g.DrawingColor = &c212529
		  g.FillRoundRectangle(boxX, boxY, boxWidth, boxHeight, 10, 10)
		  g.DrawingColor = &cFFFFFF
		  For k As Integer = 0 To lines.LastIndex
		    SetTextSize(g, 12, k = 0)
		    g.DrawText(lines(k), boxX + 10, boxY + 5 + k * lineHeight + TextAscent(g))
		  Next
		  SetTextSize(g, 12, False)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub DrawMap(g As Graphics, w As Double, h As Double)
		  // The tiles, the precision circles, the track and its points, the credit, and the hover box
		  g.AntiAliased = True
		  g.DrawingColor = &cE9ECEF
		  g.FillRectangle(0, 0, w, h)
		  If Not mManual Then ComputeView(w, h) // moved or zoomed by hand: the view stays until Fit
		  
		  // Tiles: those not cached yet are fetched in the background and drawn when they arrive
		  Dim n As Integer = 2 ^ mZoom
		  Dim firstX As Integer = Floor(mOriginX / 256)
		  Dim lastX As Integer = Floor((mOriginX + w) / 256)
		  Dim firstY As Integer = Floor(mOriginY / 256)
		  Dim lastY As Integer = Floor((mOriginY + h) / 256)
		  Dim visibleTiles As New Dictionary
		  For ty As Integer = firstY To lastY
		    If ty < 0 Or ty >= n Then Continue
		    For tx As Integer = firstX To lastX
		      Dim wrapped As Integer = ((tx Mod n) + n) Mod n
		      visibleTiles.Value(Str(mZoom) + "/" + Str(wrapped) + "/" + Str(ty)) = True
		      Dim p As Picture = TileFor(mZoom, wrapped, ty)
		      Dim sx As Double = tx * 256 - mOriginX
		      Dim sy As Double = ty * 256 - mOriginY
		      If p <> Nil Then
		        g.DrawPicture(p, sx, sy, 256, 256, 0, 0, p.Width, p.Height)
		      Else
		        g.DrawingColor = &cDEE2E6
		        g.DrawRectangle(sx, sy, 256, 256)
		      End If
		    Next
		  Next
		  // Tiles that scrolled out of view aren't downloaded any more (panning and zooming)
		  For q As Integer = mQueue.LastIndex DownTo 0
		    If Not visibleTiles.HasKey(mQueue(q)) Then mQueue.RemoveAt(q)
		  Next
		  
		  If Track = Nil Or Track.Count() = 0 Then
		    g.DrawingColor = &c495057
		    SetTextSize(g, 14, False)
		    Dim waiting As String = "No position yet"
		    g.DrawText(waiting, (w - g.TextWidth(waiting)) / 2, h / 2)
		  Else
		    Dim c As Color = ChartColor("position")
		    // Approximate positions (sent rounded on purpose): a circle of their precision
		    For i As Integer = 0 To Track.Count() - 1
		      Dim bits As Integer = Track.Precisions(i)
		      If bits > 0 And bits < 32 Then
		        Dim r As Double = PrecisionMeters(bits) / MetersPerPixel(Track.Lats(i))
		        If r > 4 Then
		          g.DrawingColor = Color.RGB(c.Red, c.Green, c.Blue, 215)
		          g.FillOval(ScreenX(Track.Lons(i)) - r, ScreenY(Track.Lats(i)) - r, 2 * r, 2 * r)
		        End If
		      End If
		    Next
		    // The track, in time order
		    If Track.Count() > 1 Then
		      Dim path As New GraphicsPath
		      path.MoveToPoint(ScreenX(Track.Lons(0)) * mPathScale, ScreenY(Track.Lats(0)) * mPathScale)
		      For i As Integer = 1 To Track.Count() - 1
		        path.AddLineToPoint(ScreenX(Track.Lons(i)) * mPathScale, ScreenY(Track.Lats(i)) * mPathScale)
		      Next
		      g.DrawingColor = Color.RGB(c.Red, c.Green, c.Blue, 60)
		      g.PenSize = 3 * mPathScale
		      g.DrawPath(path)
		      g.PenSize = 1
		    End If
		    // The points; the latest larger, with a white ring
		    For i As Integer = 0 To Track.Count() - 1
		      Dim px As Double = ScreenX(Track.Lons(i))
		      Dim py As Double = ScreenY(Track.Lats(i))
		      Dim size As Double = If(i = Track.Count() - 1, 9.0, 5.0)
		      g.DrawingColor = &cFFFFFF
		      g.FillOval(px - size - 2, py - size - 2, 2 * size + 4, 2 * size + 4)
		      g.DrawingColor = If(i = Track.Count() - 1, c, Color.RGB(c.Red, c.Green, c.Blue, 90))
		      g.FillOval(px - size, py - size, 2 * size, 2 * size)
		    Next
		  End If
		  
		  // The credit OpenStreetMap asks for
		  SetTextSize(g, 10, False)
		  Dim credit As String = "© OpenStreetMap contributors"
		  Dim cw As Double = g.TextWidth(credit) + 10
		  g.DrawingColor = Color.RGB(255, 255, 255, 80)
		  g.FillRectangle(w - cw, h - 16, cw, 16)
		  g.DrawingColor = &c343A40
		  g.DrawText(credit, w - cw + 5, h - 4)
		  
		  If mHover >= 0 And Track <> Nil And mHover < Track.Count() Then DrawHover(g, w)
		  If Not mExporting Then DrawControls(g)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function MetersPerPixel(lat As Double) As Double
		  Return 156543.03392 * Cos(lat * kPi / 180) / (2 ^ mZoom)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function PrecisionMeters(bits As Integer) As Double
		  // Meshtastic keeps the top bits of the 1e-7 degree coordinates: the rest is an error of up to
		  // 2^(32 - bits) units, about 0.011 m each
		  Return (2 ^ (32 - bits)) * 1e-7 * 111320 / 2
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ScreenX(lon As Double) As Double
		  Return WorldX(lon, mZoom) - mOriginX
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function ScreenY(lat As Double) As Double
		  Return WorldY(lat, mZoom) - mOriginY
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function WorldX(lon As Double, z As Integer) As Double
		  // Web Mercator, in pixels of the whole world at zoom z (256 per tile)
		  Return (lon + 180) / 360 * 256 * (2 ^ z)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function WorldY(lat As Double, z As Integer) As Double
		  Dim clamped As Double = Max(-85.0511, Min(85.0511, lat))
		  Dim r As Double = clamped * kPi / 180
		  Return (1 - Log(Tan(r) + 1 / Cos(r)) / kPi) / 2 * 256 * (2 ^ z)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function TileFor(z As Integer, tx As Integer, ty As Integer) As Picture
		  // A tile from memory, else from the disk cache, else Nil after queuing its download
		  Dim key As String = Str(z) + "/" + Str(tx) + "/" + Str(ty)
		  If mTiles = Nil Then mTiles = New Dictionary
		  If mTiles.HasKey(key) Then
		    Dim cached As Picture = mTiles.Value(key)
		    Return cached
		  End If
		  If mFailed <> Nil And mFailed.HasKey(key) Then Return Nil
		  Dim f As FolderItem = CacheFile(key, False)
		  If f <> Nil And f.Exists Then
		    Try
		      Dim p As Picture = Picture.Open(f)
		      If p <> Nil Then
		        mTiles.Value(key) = p
		        // Older than 30 days: shown, and fetched again in the background
		        Dim age As Double = DateTime.Now().SecondsFrom1970 - f.ModificationDateTime.SecondsFrom1970
		        If age > 30 * 86400 And mQueue.IndexOf(key) < 0 Then
		          mQueue.Add key
		          FetchNext()
		        End If
		        Return p
		      End If
		    Catch e As RuntimeException
		    End Try
		  End If
		  If mQueue.IndexOf(key) < 0 And mFetching <> key Then
		    mQueue.Add key
		    FetchNext()
		  End If
		  Return Nil
		End Function
	#tag EndMethod

	#tag Hook, Flags = &h0
		Event Changed()
	#tag EndHook


	#tag Property, Flags = &h0
		CacheFolder As FolderItem
	#tag EndProperty

	#tag Property, Flags = &h0
		ControlScale As Double = 1
	#tag EndProperty

	#tag Property, Flags = &h0
		Track As PositionTrack
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPathScale As Double = 1
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mBusy As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mConnection As URLConnection
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDragOriginX As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDragOriginY As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDragX As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDragY As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mDragging As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mExporting As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mFailed As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mFetching As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mHeight As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mHover As Integer = -1
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mManual As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mOriginX As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mOriginY As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mQueue() As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTiles As Dictionary
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mWheel As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mWidth As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mZoom As Integer
	#tag EndProperty


	#tag Constant, Name = kMinZoom, Type = Double, Dynamic = False, Default = \"2", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kTopZoom, Type = Double, Dynamic = False, Default = \"19", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kMaxZoom, Type = Double, Dynamic = False, Default = \"18", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kSpotZoom, Type = Double, Dynamic = False, Default = \"16", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kPi, Type = Double, Dynamic = False, Default = \"3.14159265358979", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kUserAgent, Type = String, Dynamic = False, Default = \"Sensor_Dashboard/1.0 (+https://github.com/Kongduino/Sensor_Dashboard)", Scope = Private
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
			Name="ControlScale"
			Visible=false
			Group="Behavior"
			InitialValue="1"
			Type="Double"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
