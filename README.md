# NCH Wifi Controller (For Mac OS X)

To see the Android version of this application click [here](https://github.com/langstonhowley/NCH-Wifi-Controller-Android).

This Mac OS X application allows users to connect to a Nextek NCH and toggle its wifi.

More specifically, a virtual serial port is made between the device and a user-selected NCH using the Bluetooth RFCOMM Protocol (more information on RFCOMM [here](https://en.wikipedia.org/wiki/List_of_Bluetooth_protocols#RFCOMM)). This allows for the user to toggle wifi by sending byte data through the serial port.


## Bluetooth Handling:

Handling of Bluetooth events are spread across multiple ```Delegates``` importing [IOBluetooth](https://developer.apple.com/documentation/iobluetooth) and [IOBluetoothUI](https://developer.apple.com/documentation/iobluetoothui) **(NOT CoreBluetooth)**:

### Search Delegate

The code for the Search Delegate can be found [here](https://github.com/langstonhowley/NCH-Wifi-Controller-MacOs/blob/master/NCH%20Wifi%20Controller/SearchDelegate.swift) in the repository. It implements [IOBluetoothDevieInquiryDelegate](https://developer.apple.com/documentation/iobluetooth/iobluetoothdeviceinquirydelegate) .

Empty example of a Search Delegate:
```swift
class MyDeviceSearchDelegate : IOBluetoothDeviceInquiryDelegate{

  /// When a device search begins this is called.
  func deviceInquiryStarted(_ sender: IOBluetoothDeviceInquiry) {}
  
  /// When a device is found this is called. 
  /// (Does find the same device multiple times so a check must be put in place)
  func deviceInquiryDeviceFound(_ sender: IOBluetoothDeviceInquiry, device: IOBluetoothDevice) {}
  
  /// When a device search completes this is called
  func deviceInquiryComplete(_ sender: IOBluetoothDeviceInquiry!, error: IOReturn, aborted: Bool) {}

}
```

#### Usage:

See [this line](https://github.com/langstonhowley/NCH-Wifi-Controller-MacOs/blob/fc21c8871eaa7150f7ee022907faa166675d73a3/NCH%20Wifi%20Controller/ViewController.swift#L60)

---

### Pair Delegate

The code for the Pair Delegate can be found [here](https://github.com/langstonhowley/NCH-Wifi-Controller-MacOs/blob/master/NCH%20Wifi%20Controller/PairDelegate.swift) in the repository. It implements [IOBluetoothDevicePairDelegate](https://developer.apple.com/documentation/iobluetooth/iobluetoothdevicepairdelegate) .

Although pairing is not necessarily required I implemented it just to stay consistent with the Applications. 

Empty example of a Pair Delegate:
```swift
class MyDevicePairingDelegate : IOBluetoothDevicePairDelegate{

  func devicePairingStarted(_ sender: Any!) {}

  func devicePairingFinished(_ sender: Any!, error: IOReturn) {}

}
```

#### Usage:

See [this line](https://github.com/langstonhowley/NCH-Wifi-Controller-MacOs/blob/fc21c8871eaa7150f7ee022907faa166675d73a3/NCH%20Wifi%20Controller/ViewController.swift#L222)

---

### Connect Delegate

The code for the Connect Delegate can be found [here](https://github.com/langstonhowley/NCH-Wifi-Controller-MacOs/blob/master/NCH%20Wifi%20Controller/ConnectDelegate.swift) in the repository. It implements [IOBluetoothRFCOMMChannelDelegate](https://developer.apple.com/documentation/iobluetooth/iobluetoothrfcommchanneldelegate) .

Empty example of a Connect Delegate:
```swift
class MyDeviceConnectDelegate : IOBluetoothRFCOMMChannelDelegate{
  
  /// When a connection attempt is complete this is called. If error != 0 connection failed.
  func rfcommChannelOpenComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {}
  
  /// Whe the RFCOMM channel is closed and the user is disconnected this is called.
  func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {}
  
  /// When data is received on the RFCOMM channel from the remote device this is called.
  func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {}
  
}
```

#### Usage:

See [this line](https://github.com/langstonhowley/NCH-Wifi-Controller-MacOs/blob/fc21c8871eaa7150f7ee022907faa166675d73a3/NCH%20Wifi%20Controller/ViewController.swift#L638)

---

### Sending data through the RFCOMM channel

I made a helper class named [Connector](https://github.com/langstonhowley/NCH-Wifi-Controller-MacOs/blob/master/NCH%20Wifi%20Controller/Connector.swift) which is responsible for [finding the RFCOMM service](https://github.com/langstonhowley/NCH-Wifi-Controller-MacOs/blob/fc21c8871eaa7150f7ee022907faa166675d73a3/NCH%20Wifi%20Controller/Connector.swift#L65) on the remote device, connecting and disconnecting from the remote device, and [writing messages to the RFCOMM channel](https://github.com/langstonhowley/NCH-Wifi-Controller-MacOs/blob/fc21c8871eaa7150f7ee022907faa166675d73a3/NCH%20Wifi%20Controller/Connector.swift#L89) .
