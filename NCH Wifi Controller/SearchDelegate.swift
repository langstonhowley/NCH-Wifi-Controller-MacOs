//
//  SearchDelegate.swift
//  NCH Wifi Controller
//
//  Created by Langston Howley on 7/11/19.
//  Copyright © 2019 Nextek Power Systems. All rights reserved.
//

import Foundation
import IOBluetoothUI;
import IOBluetooth;

/// The SearchDelegate class is responsible for handling the discovery of devices (not just NCHs). It is also responsible for notifying the *ViewController* about events transpiring that are related to connection.
///
/// - Author: Langston Howley
/// - Date: Monday July 22, 2019
/// - Version: 1.0
/// - Since: 2019-07-22
class SearchDelegate : IOBluetoothDeviceInquiryDelegate {
    var isSearching = false; // Whether or not the delegate is searching or not
    private var observers = [NCHListObserver]() // The list of objects obsrving this class
    
    /// When a search is started this notifies all of the observers that the search has begun
    func deviceInquiryStarted(_ sender: IOBluetoothDeviceInquiry) {
        print("Inquiry Started...")
        isSearching = true
        
        for observer in observers {
            observer.onSearchStart()
        }
    }
    
    /// When a device is found this passes the device to all of the observers
    func deviceInquiryDeviceFound(_ sender: IOBluetoothDeviceInquiry, device: IOBluetoothDevice) {
        /*
        print("---Device Found---")
        print("     Name: \(device.name!)")
        print("     Address: \(device.addressString!)")
        print("     Paired: \(device.isPaired())")
        */
        
         if device.name.lowercased().contains("nch") {
            for observer in observers{
                observer.update(nch: device)
            }
         }
    }
    
    /// When the search is complete this notifies all of the observers that search completed.
    func deviceInquiryComplete(_ sender: IOBluetoothDeviceInquiry!, error: IOReturn, aborted: Bool) {
        print("---SEARCH COMPLETE---")
        for observer in observers{
            observer.onSearchFinish()
        }
        isSearching = false
    }
    
    /// This adds objects to the observers list so that events happening within this class can be sent out to the objects in the observers list.
    ///
    /// - Parameter observer: The object that is observing this class.
    func attachObserver(observer: NCHListObserver){
        print("Added observer for my list: \(observer)")
        observers.append(observer)
    }
}

/// An NCHListObserver must have the following methods so that the *SearchDelegate* can notify it about when certain events occur
protocol NCHListObserver {
    func update(nch: IOBluetoothDevice!)
    func onSearchFinish()
    func onSearchStart()
}



