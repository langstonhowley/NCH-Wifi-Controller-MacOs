//
//  PairDelegate.swift
//  NCH Wifi Control
//
//  Created by Langston Howley on 7/11/19.
//  Copyright © 2019 Nextek Power Systems. All rights reserved.
//

import Foundation
import IOBluetoothUI;
import IOBluetooth;

/// The PairDelegate class is responsible for handling the pairing process between a Mac and an NCH. It is also responsible for notifying the *ViewController* about events transpiring that are related to connection.
///
/// - Author: Langston Howley
/// - Date: Monday July 22, 2019
/// - Version: 1.0
/// - Since: 2019-07-22
class PairDelegate: NSObject, IOBluetoothDevicePairDelegate {
    private var observers = [NCHPairingObserver]() // The list of objects obsrving this class
    
    /// When a pair is started this notifies all of the observers that the pair has begun
    func devicePairingStarted(_ sender: Any!) {
        print("---Pairing With \((sender as! IOBluetoothDevicePair).device()?.name ?? "Unknown")---")
        
        for observer in observers{
            observer.pairing();
        }
    }
    
    /// When a pairing attempt is complete this is called. If the connection failed the error is denoted by the *error* parameter but if the pair is made *error* = 0
    ///
    /// - Important: Because of Apple's limited documentation it is almost impossible to tell what the *error* actually is so if the *error* is non-zero the connection failed.
    ///
    func devicePairingFinished(_ sender: Any!, error: IOReturn) {
        if(error == 0){
            while(!((sender as! IOBluetoothDevicePair).device()?.isPaired())!){
                //This wait until it's actually paired.
            }
            print("Paired!")
            
            for observer in observers{
                observer.paired()
            }
        }
        else{
            print("\(error)")
            
            for observer in observers{
                observer.pairingFailed()
            }
        }
    }
    
    /// This adds objects to the observers list so that events happening within this class can be sent out to the objects in the observers list.
    ///
    /// - Parameter observer: The object that is observing this class.
    func attachObserver(observer: NCHPairingObserver){
        print("Added observer for my list: \(observer)")
        observers.append(observer)
    }
}

/// An NCHPairingObserver must have the following methods so that the *ConnectDelegate* can notify it about when certain events occur
protocol NCHPairingObserver {
    func paired()
    func pairingFailed()
    func pairing()
}

