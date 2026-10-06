# Sensor_Dashboard_Android

The Android version of [Sensor_Dashboard](https://github.com/Kongduino/Sensor_Dashboard): environment readings and positions from a Meshtastic MQTT feed, a Meshtastic node on your network, and an M5Stack air-quality monitor (AQI), charted and mapped on a phone or tablet.

It's written in Xojo, with no plugins; the only external libraries are for USB: [usb-serial-for-android](https://github.com/mik3y/usb-serial-for-android) and [XojoUsbAttach](https://github.com/Kongduino/XojoUsbAttach), fetched by Gradle at build time. The Meshtastic and MQTT parts use the [MQTT_Xojo](https://github.com/Kongduino/MQTT_Xojo) library (in `Library/`), and the data, chart and map code is shared with the desktop app (in `Shared/`).

## Screenshots

An M5Stack AQI device on a tablet: the temperature of its two sensors, CO₂, and particulate matter as bars. Under each chart, min / avg / max.

<p>
  <img src="docs/screenshots/aqi-temperature.png" alt="Temperature chart of the AQI's two sensors" width="32%">
  <img src="docs/screenshots/aqi-co2.png" alt="CO2 chart" width="32%">
  <img src="docs/screenshots/aqi-pm.png" alt="Particulate matter bars" width="32%">
</p>

## Contents

- [Screenshots](#screenshots)
- [What it does](#what-it-does)
- [Requirements](#requirements)
- [Getting started](#getting-started)
- [Sources](#sources)
- [Screens](#screens)
- [Range test](#range-test)
- [Sharing](#sharing)
- [Where things are kept](#where-things-are-kept)
- [Repository layout](#repository-layout)
- [Notes on Xojo for Android](#notes-on-xojo-for-android)
- [Limitations](#limitations)
- [License](#license)

## What it does

- **Three sources**, each with its own card on the Home screen and an on/off switch:
  - a **Meshtastic MQTT feed** (the packets one gateway uploads), decrypted with your channel keys
  - a **Meshtastic node** on your network over TCP (port 4403), or plugged into the phone or tablet over USB
  - an **M5Stack AQI** device, through M5Stack's ezdata service
- **Charts** with a time axis and a fitted Y axis: temperature, humidity and pressure; the radio (RSSI / SNR) of an MQTT feed, for packets the gateway heard directly (a relayed packet's values describe the last relay, so only its hop count is kept); CO2, VOC and particulate matter (as bars) for the AQI. Tap a chart, or slide along it, to read a sample's values.
- **A map** of a node's positions on OpenStreetMap: drag, pinch, double-tap, and the +/−/Fit buttons; tap a point for its time, coordinates, altitude, satellites and reception.
- **Storage** in a local SQLite database, so the charts start with earlier readings.
- **Sharing**: the readings (CSV), the positions (CSV and GPX) and the chart or map (PNG), through Android's share sheet.

## Requirements

- Xojo **2026r2.1** with Android support, to build it.
- Android 9 (API 28) or later. Tested on a tablet with Android 16.
- For the sources: an MQTT broker your gateway publishes to, a Meshtastic node reachable on your network, or an M5Stack AQI device registered with ezdata.

## Getting started

1. Open `Sensor_Dashboard_Android.xojo_project` in Xojo and run it on a device or an emulator.
2. On the Home screen, tap a card that says **set up: tap here**, fill in its settings, and **Save**.
3. Turn the card's switch on. The card turns green when connected and shows the latest reading.
4. Tap a card to open its charts.

A source that was on when you left the app starts again the next time you open it.

## Sources

| Source | Settings | Notes |
|---|---|---|
| **MQTT feed** | broker (`host` or `host:port`), root topic (for example `msh/EU_868`), the gateway's node ID (`!aabbccdd`), user and password, channel keys, an optional single node, TLS | Subscribes to `<root topic>/2/e/+/!<gateway>`, as the desktop app does. The root topic is the prefix only, without `#` or `+`. Channel keys: `Name=base64` entries separated by `;`; a key without a name is used for the other channels; empty means the default key (`AQ==`). **Saved feeds:** every saved setup is kept; pick one in the popup at the top of the settings to fill the fields, then Save (Forget deletes it). Spaces are removed from the broker, topic and IDs on Save (Android's keyboard can add one after each dot). |
| **Meshtastic node** | address (or `usb`), port (4403) | A node accepts one TCP client at a time: close the Meshtastic app (or anything else connected to the node) first. With `usb`, the node plugged into the phone or tablet is used: plugging it in opens the app with the USB permission granted ([XojoUsbAttach](https://github.com/Kongduino/XojoUsbAttach); choose **Always** the first time), and the card connects on its next try. The node's own sensor is charted by default; any node it knows can be picked. |
| **M5Stack AQI** | the device ID (12 hex digits) | Polled at the device's own interval (at most every minute). |

## Screens

- **Home**: one card per source, with its state (green connected, orange connecting or retrying, grey off, red a problem), what it follows, its latest reading, and its switch.
- **Source screen**, opened from a card:
  - **Node**: a filter and a node picker; tabs °C, %, hPa, Map; **Request** asks the selected node for its readings (on the Map tab, its position). Nodes that have nothing new answer `NO_RESPONSE`, which the status line shows.
  - **MQTT**: tabs °C, %, hPa, RSSI (RSSI and SNR), Map.
  - **AQI**: tabs °C and % (both sensors, SEN55 and SCD40), CO₂, VOC, PM.
  - The tabs share the screen's width, so they fit on a phone as well as a tablet.
  - **Settings** in the toolbar opens the source's settings.
- The screen stays on while a source is on: the app collects data only while it's in the foreground.

## Range test

How far a test device can send and receive, measured against a gateway node at home: the **Range test** card.

- **Gateway → device:** the gateway is the Meshtastic node card's node (over TCP or USB). **Send** makes it broadcast "Message from !<gateway> #<n>" on the test channel with **hop limit 0**, so only a device in direct range can hear it. The test device, paired with the phone's Meshtastic app, uploads what it hears to MQTT through the app (**MQTT client proxy**); the app follows those uploads (`<root>/2/e/+/!<device>`, with the MQTT card's broker and keys). A message reported back is *heard*, with the device's RSSI / SNR; one not reported within 2 minutes is *missed*. Send waits 5 seconds between messages: the firmware refuses texts sent closer together, and a message the gateway refuses is marked *failed* and left off the map.
- **Device → gateway:** every packet of the test device the gateway hears (positions, replies…), with the gateway's RSSI / SNR. When the device sends the same packet twice (it heard no node rebroadcast it, a sign of a weak link), the Log tab says *repeated*. Automatic packets (positions, telemetry, node info), in either direction, taken less than 30 m from the previous one kept are dropped, so a device standing still doesn't pile up points; test messages and texts are always kept.
- **Where:** each reading is placed at the phone's position (location permission, asked once; it needs a GPS, which many tablets don't have), else at the device's last reported position if its fix is at most 15 minutes old. For a walk, set the test device to broadcast its position often (for example `position.position_broadcast_secs` 60; the default is an hour).
- **Maps:** one per direction. Packets heard directly are coloured by SNR (red at −20 dB, yellow around −7, green from +5); relayed packets are grey dots with their hop count, unknown hops grey rings, missed messages red crosses. Tap a point for its details. Earlier tests between the same gateway and device are shown too. The **Log** tab lists the latest readings.
- **Share:** a CSV of every reading (direction, status, RSSI, SNR, hops, relay node, position and its source) and the current map.

Before testing: on the gateway, LoRa **OK to MQTT** on (otherwise the device doesn't upload the gateway's packets); on the test device, MQTT on with **proxy to client**, uplink on the test channel, and the same channel and key as the gateway. On **both** nodes, turn **downlink off** on the test channel: otherwise each gets the other's packets back from the broker before the radio copy, drops the radio copy as a duplicate, and nothing is measured. Keep the phone connected to the device by Bluetooth during the test, and the device off a computer's USB (while a computer client was connected over USB, the device's own packets weren't uploaded). The gateway accepts one TCP client: turning the range test on turns the node card off, and the other way round. Any other app connected to the gateway over the network, the Meshtastic app included (even on the same tablet), keeps pushing the range test off: disconnect it first.

## Sharing

**Share** on a source screen writes, then offers through Android's share sheet:

- `<source>.csv`: every stored reading of what the screen shows, in the same columns as the desktop export
- `<source>_positions.csv` and `.gpx`: the positions (node and MQTT), when there are any
- `<source>_<tab>.png`: the current chart or map, at twice the screen size

Several files are shared as one zip.

## Where things are kept

All in the app's own storage, readable by the app only:

| What | Where |
|---|---|
| Settings (including the MQTT password and channel keys) | `settings.json` in the app's files folder |
| Readings, positions, range tests, saved MQTT feeds (with their passwords and keys) | `records.sqlite`, next to it |
| Event log of the last run | `Event_Log.txt`, next to it |
| Map tiles | the app's cache folder (`tiles/`); Android may clear it, and they come back |

Uninstalling the app removes all of them.

## Repository layout

```
Sensor_Dashboard_Android.xojo_project   the project (open this in Xojo)
App.xojo_code                 the app: back in the foreground, the sources catch up
Hub.xojo_code                 the app's state: settings, database, the three sources
MQTTSource.xojo_code          the MQTT feed
NodeSource.xojo_code          a Meshtastic node over TCP or USB
AQISource.xojo_code           an M5Stack AQI device
HomeScreen.xojo_code          the cards and switches
SourceCard.xojo_code          one card (a canvas)
SourceScreen.xojo_code        a source's tabs, charts, map, Request and Share
SettingsScreen.xojo_code      a source's settings
MobileSensorChart.xojo_code   the chart control (touch)
MobileMapView.xojo_code       the map control (touch, pinch)
TabStrip.xojo_code            the tab bar (tabs share its width)
Icons/                        the app icon: PNGs and their SVG sources
Shared/                       the code shared with the desktop app, kept identical to Sensor_Dashboard/Shared
Library/                      MQTT_Xojo's library, kept identical to MQTT_Xojo/Library
LICENSE                       GPL-3.0
```

`Shared/` and `Library/` are copies: changes go to the desktop app and to MQTT_Xojo first, then are copied here.

## Notes on Xojo for Android

Xojo translates Android projects to Kotlin, and some code that's fine on desktop compiles or runs differently there. The shared code follows these rules:

- Binary Strings: after a concatenation a String is tagged UTF-8, so byte functions miscount bytes 128–255. The library keeps binary data tagged one byte per character (`MeshBin`) and decodes text with `MeshUTF8Text`.
- No `Crypto.AESDecrypt`: AES-CTR is done in plain Xojo (`MeshAESCTRXojo`). No `Join`, `StrComp`, `SerialConnection`, or `SpecialFolder.ApplicationData`.
- `Format` treats a `-` in the mask as text: signed numbers go through `FormatValue`. `Val("&H…")` gives 0 and `Hex()` keeps 32 bits: `HexValue` and `HexText`.
- A missing or null JSON value can't be put in a JSONItem (it throws): `ChildObject`. A MemoryBlock function never returns Nil.
- GraphicsPath shapes ignore `Graphics.ScaleX/ScaleY`: the painters scale them by hand in exports.
- A screen's Functions can't be called from its `Opening` event; controls aren't moved or resized at run time.
- Files to share go under `SpecialFolder.Temporary/images/` (the template's FileProvider root); `ShareFile` with an array doesn't compile, so several files are zipped.

## Limitations

- The app collects data only while it's on screen (no background service).
- MQTT TLS encrypts the connection but doesn't verify the broker's certificate (Xojo's SSLSocket).
- Sharing several files gives one zip.

## License

GPL-3.0, like Sensor_Dashboard and MQTT_Xojo. See [LICENSE](LICENSE).

It includes the [MQTT_Xojo](https://github.com/Kongduino/MQTT_Xojo) library (`Library/`) and the code shared with [Sensor_Dashboard](https://github.com/Kongduino/Sensor_Dashboard) (`Shared/`), both GPL-3.0.
