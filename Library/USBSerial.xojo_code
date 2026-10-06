#tag Class
Protected Class USBSerial
	#tag Note, Name = About
		A USB serial port for Xojo Android, through usb-serial-for-android (MIT, github.com/mik3y/usb-serial-for-android):
		CDC-ACM (nRF52, RP2040, ESP32-S3 native USB...), CP210x, CH34x, FTDI and PL2303 chips.

		The project needs, in Build Settings → Android, the Dependencies line:
		  implementation 'com.github.mik3y:usb-serial-for-android:3.11.0'

		Use:
		  Dim names() As String = USBSerial.Devices()  // each: name, Tab, vid:pid, Tab, driver, Tab, product
		  If Not USBSerial.HasPermission(name) Then Call USBSerial.RequestPermission(name)  // Android asks the user
		  Dim port As New USBSerial
		  AddHandler port.DataAvailable, ...   // binary data, one byte per character
		  If port.Open(name, 115200) Then Call port.Write(bytes)

		Reading is polled by a Timer (declares can't take a listener with a byte array), every PollMilliseconds, with a
		10 ms read timeout. Bytes cross the declares as Base64 text. Binary Strings use the one-byte-per-character form
		(see Bin): the same rule as the MQTT_Xojo library's MeshBin.
	#tag EndNote


	#tag Method, Flags = &h21
		Private Shared Function Bin(s As String) As String
		  // Binary data, one byte per character (on Android a String made by concatenation or decoding is tagged UTF-8
		  // and its byte functions count characters 128-255 as two bytes); identity on other targets
		  #If TargetAndroid Then
		    Dim t As String = s + ""
		    Return t.DefineEncoding(Encodings.ISOLatin1)
		  #Else
		    Return s
		  #EndIf
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Close()
		  // Closes the port (nothing if it isn't open)
		  If mTimer <> Nil Then mTimer.RunMode = Timer.RunModes.Off
		  If mPort = Nil Then Return
		  #If TargetAndroid Then
		    Declare Sub usbClose Lib "com.hoho.android.usbserial.driver.UsbSerialPort:Kotlin" Alias _
		    "try { (port as com.hoho.android.usbserial.driver.UsbSerialPort).close() } catch (e: Exception) { }" (port As Ptr)
		    usbClose(mPort)
		  #EndIf
		  mPort = Nil
		  mName = ""
		  mReadErrors = 0
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Shared Function Devices() As String()
		  // The USB serial devices attached now, one String each: device name (e.g. /dev/bus/usb/001/002), Tab,
		  // vendor:product id in hex, Tab, driver (e.g. CdcAcmSerialDriver), Tab, product name ("" if unknown)
		  Dim result() As String
		  #If TargetAndroid Then
		    Declare Function usbList Lib "com.hoho.android.usbserial.driver.UsbSerialProber:Kotlin" Alias _
		    "com.hoho.android.usbserial.driver.UsbSerialProber.getDefaultProber().findAllDrivers((ctx as android.content.Context).getSystemService(android.content.Context.USB_SERVICE) as android.hardware.usb.UsbManager).joinToString(""\n"") { it.device.deviceName + ""\t"" + it.device.vendorId.toString(16) + "":"" + it.device.productId.toString(16) + ""\t"" + it.javaClass.simpleName + ""\t"" + (try { it.device.productName } catch (e: Exception) { null } ?: """") }" _
		    (ctx As Ptr) As CString
		    Dim listText As String = usbList(App.AndroidContextHandle)
		    If listText = "" Then Return result
		    Dim lf As String = Chr(10)
		    result = listText.Split(lf)
		  #EndIf
		  Return result
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Shared Function HasPermission(name As String) As Boolean
		  // True when the app may open the device name (one of Devices(), first field)
		  #If TargetAndroid Then
		    Declare Function usbHasPermission Lib "android.hardware.usb.UsbManager:Kotlin" Alias _
		    "((ctx as android.content.Context).getSystemService(android.content.Context.USB_SERVICE) as android.hardware.usb.UsbManager).let { m -> m.deviceList[name.toString()]?.let { d -> m.hasPermission(d) } ?: false }" _
		    (ctx As Ptr, name As CString) As Boolean
		    Return usbHasPermission(App.AndroidContextHandle, name)
		  #Else
		    Return False
		  #EndIf
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Shared Function IsAttached(name As String) As Boolean
		  // True when the device name is attached now
		  Dim tab As String = Chr(9)
		  For Each line As String In Devices()
		    Dim fields() As String = line.Split(tab)
		    If fields(0) = name Then Return True
		  Next
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function IsOpen() As Boolean
		  Return mPort <> Nil
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DeviceName() As String
		  // The open device's name ("" when closed)
		  Return mName
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastError() As String
		  // Why the last Open, Write or read failed
		  Return mLastError
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Open(name As String, baud As Integer = 115200) As Boolean
		  // Opens the device name (one of Devices(), first field) at baud, 8N1, DTR and RTS on (CDC-ACM devices such as
		  // nRF52 boards send nothing until DTR is set). Needs HasPermission(name). False on failure (see LastError)
		  Close()
		  mLastError = ""
		  #If TargetAndroid Then
		    Declare Function usbOpen Lib "com.hoho.android.usbserial.driver.UsbSerialProber:Kotlin" Alias _
		    "try { ((ctx as android.content.Context).getSystemService(android.content.Context.USB_SERVICE) as android.hardware.usb.UsbManager).let { m -> val drv = com.hoho.android.usbserial.driver.UsbSerialProber.getDefaultProber().findAllDrivers(m).firstOrNull { it.device.deviceName == name.toString() }; val conn = if (drv != null) m.openDevice(drv.device) else null; if (drv != null && conn != null) { val p = drv.ports[0]; p.open(conn); p.setParameters(baud.toInt(), 8, com.hoho.android.usbserial.driver.UsbSerialPort.STOPBITS_1, com.hoho.android.usbserial.driver.UsbSerialPort.PARITY_NONE); p.dtr = true; p.rts = true; p } else null } } catch (e: Exception) { null }" _
		    (ctx As Ptr, name As CString, baud As Int32) As Ptr
		    Dim baudRate As Int32 = baud
		    Dim p As Ptr = usbOpen(App.AndroidContextHandle, name, baudRate)
		    If p = Nil Then
		      mLastError = "can't open " + name + If(HasPermission(name), "", " (no permission)")
		      Return False
		    End If
		    mPort = p
		    mName = name
		    If mTimer = Nil Then
		      mTimer = New Timer
		      AddHandler mTimer.Run, WeakAddressOf Poll
		    End If
		    mTimer.Period = PollMilliseconds
		    mTimer.RunMode = Timer.RunModes.Multiple
		    Return True
		  #Else
		    mLastError = "USB serial is for Android only"
		    Return False
		  #EndIf
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Poll(sender As Timer)
		  // Reads what has arrived (10 ms timeout) and passes it on; an error closes the port
		  #Pragma Unused sender
		  If mPort = Nil Then Return
		  #If TargetAndroid Then
		    Declare Function usbRead Lib "com.hoho.android.usbserial.driver.UsbSerialPort:Kotlin" Alias _
		    "try { val b = ByteArray(4096); val n = (port as com.hoho.android.usbserial.driver.UsbSerialPort).read(b, 10); if (n > 0) android.util.Base64.encodeToString(b, 0, n, android.util.Base64.NO_WRAP) else """" } catch (e: Exception) { ""!"" + (e.message ?: ""read error"") }" _
		    (port As Ptr) As CString
		    Dim got As String = usbRead(mPort)
		    If got = "" Then Return
		    If got.BeginsWith("!") Then
		      // Base64 never contains "!": an error. usb-serial-for-android also reports one when its connection check after
		      // an empty read fails ("USB get_status request failed", seen with an nRF52 that was still plugged in): the
		      // port is only closed when the device is gone, or after kMaxReadErrors errors in a row
		      mLastError = got.Middle(1)
		      mReadErrors = mReadErrors + 1
		      If mReadErrors < kMaxReadErrors And IsAttached(mName) Then Return
		      Close()
		      RaiseEvent Error(mLastError)
		      Return
		    End If
		    mReadErrors = 0
		    Dim raw As String = DecodeBase64(got)
		    RaiseEvent DataAvailable(Bin(raw))
		  #EndIf
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Shared Function RequestPermission(name As String) As Boolean
		  // Makes Android ask the user to allow the device name; poll HasPermission(name) for the answer.
		  // False when the device isn't attached
		  #If TargetAndroid Then
		    Declare Function usbRequest Lib "android.hardware.usb.UsbManager:Kotlin" Alias _
		    "((ctx as android.content.Context).getSystemService(android.content.Context.USB_SERVICE) as android.hardware.usb.UsbManager).let { m -> m.deviceList[name.toString()]?.let { d -> m.requestPermission(d, android.app.PendingIntent.getBroadcast(ctx as android.content.Context, 0, android.content.Intent((ctx as android.content.Context).packageName + "".USB_PERMISSION"").setPackage((ctx as android.content.Context).packageName), android.app.PendingIntent.FLAG_MUTABLE)); true } ?: false }" _
		    (ctx As Ptr, name As CString) As Boolean
		    Return usbRequest(App.AndroidContextHandle, name)
		  #Else
		    Return False
		  #EndIf
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Write(data As String) As Boolean
		  // Sends binary data (one byte per character, see Bin); False on error (see LastError)
		  If mPort = Nil Then
		    mLastError = "not open"
		    Return False
		  End If
		  #If TargetAndroid Then
		    Declare Function usbWrite Lib "com.hoho.android.usbserial.driver.UsbSerialPort:Kotlin" Alias _
		    "try { (port as com.hoho.android.usbserial.driver.UsbSerialPort).write(android.util.Base64.decode(data.toString(), android.util.Base64.NO_WRAP), 500); """" } catch (e: Exception) { e.message ?: ""write error"" }" _
		    (port As Ptr, data As CString) As CString
		    Dim encoded As String = EncodeBase64(Bin(data), 0)
		    Dim problem As String = usbWrite(mPort, encoded)
		    If problem <> "" Then
		      mLastError = problem
		      Return False
		    End If
		    Return True
		  #Else
		    Return False
		  #EndIf
		End Function
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event DataAvailable(data As String)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Error(message As String)
	#tag EndHook


	#tag Property, Flags = &h21
		Private mLastError As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mName As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mPort As Ptr
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mReadErrors As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mTimer As Timer
	#tag EndProperty

	#tag Property, Flags = &h0
		PollMilliseconds As Integer = 50
	#tag EndProperty


	#tag Constant, Name = kMaxReadErrors, Type = Double, Dynamic = False, Default = \"20", Scope = Private
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
