# NCH Wifi Controller (For Mac OS X)

To see the Android version of this application click [here](https://github.com/langstonhowley/NCH-Wifi-Controller-Android).

This Mac OS X application allows users to connect to a Nextek NCH and toggle its wifi.

More specifically, a virtual serial port is made between the device and a user-selected NCH using the Bluetooth RFCOMM Protocol (more information on RFCOMM [here](https://en.wikipedia.org/wiki/List_of_Bluetooth_protocols#RFCOMM)). This allows for the user to toggle wifi by sending byte data through the serial port.


## Bluetooth Handling:

Handling of Bluetooth events are spread across multiple ```Delegates``` importing [IOBluetooth](https://developer.apple.com/documentation/iobluetooth) and [IOBluetoothUI](https://developer.apple.com/documentation/iobluetoothui) **(NOT CoreBluetooth)**:

### Search Delegate

The code for the Search Delegate can be found [here](https://github.com/langstonhowley/NCH-Wifi-Controller-MacOs/blob/master/NCH%20Wifi%20Controller/SearchDelegate.swift) in the repository. It implements [IOBluetoothDevieInquiryDelegate](https://developer.apple.com/documentation/iobluetooth/iobluetoothdeviceinquirydelegate) .

Generally this is what a search delegate looks like:
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
