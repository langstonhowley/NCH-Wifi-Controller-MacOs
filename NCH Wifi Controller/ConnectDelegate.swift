//
//  ConnectDelegate.swift
//  NCH Wifi Controller
//
//  Created by Langston Howley on 7/11/19.
//  Copyright © 2019 Nextek Power Systems. All rights reserved.
//

import Foundation
import IOBluetoothUI;
import IOBluetooth;

/// The ConnectDelegate class is responsible for handling the connection and communication between the user's Mac and an NCH. It is also responsible for notifying the *ViewController* about events transpiring that are related to connection.
///
/// - Author: Langston Howley
/// - Date: Monday July 22, 2019
/// - Version: 1.0
/// - Since: 2019-07-22
class ConnectDelegate: IOBluetoothRFCOMMChannelDelegate {
    var observers = [NCHConnecterObserver]() // The list of objects obsrving this class
    var previous_wifi_state = String() // The previous value returned from an NCH.
                                       // This is stored because the NCH prints a confirmation message when wifi is changed.
    
    
    /// When a connection attempt is complete this is called. If the connection failed the error is denoted by the *error* parameter but if the connection is made the *rfcommChannel* parameter holds the connected socket.
    ///
    /// - Important: Because of Apple's limited documentation it is almost impossible to tell what the *error* actually is so if the *error* is non-zero the connection failed.
    ///
    func rfcommChannelOpenComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, status error: IOReturn) {
         if(error == kIOReturnSuccess){
            print("Success")
            
            for o in observers{
                o.onConnect()
            }
         }
         else{
            print("Something Went Terribly Worng")
            print(error)
            
            for o in observers{
                o.onConnectFailure()
            }
         }
    }
    
    /// This is called when the message is done being sent to the NCH.
    ///
    func rfcommChannelWriteComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, refcon: UnsafeMutableRawPointer!, status error: IOReturn) {
        print("Message Sent To NCH!!!!!!!!!!!!")
    }
    ///On disconnect this notifies all observers that the channel was closed.
    func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        print("Socket Closed")
        
        for o in observers{
            o.onDisconnect()
        }
    }
    
    ///This receives the output from the NCH and sends it out to the observers of this class.
    func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {
        
        let message = String(bytesNoCopy: dataPointer, length: Int(dataLength), encoding: String.Encoding.utf8, freeWhenDone: false)
        
        print("MESSAGE RECIEVED FROM NCH: \(message ?? "couldn't read it")")
        
        if !(message!.elementsEqual("CONNECTED")) && !(message!.elementsEqual(previous_wifi_state)){
            
            for o in observers{
                o.passNCHReturn(ret: message!)
            }
        }
    }
    
    /// This adds objects to the observers list so that events happening within this class can be sent out to the objects in the observers list.
    ///
    /// - Parameter observer: The object that is observing this class.
    func attachObserver(observer: NCHConnecterObserver){
        print("Added observer for my list: \(observer)")
        observers.append(observer)
    }
    
    func failed(){
        for observer in observers {
            observer.onConnectFailure()
        }
    }
}


/// An NCHConnecterObserver must have the following methods so that the *ConnectDelegate* can notify it about when certain events occur
protocol NCHConnecterObserver {
    func onConnect()
    func onConnectFailure()
    func onDisconnect()
    func passNCHReturn(ret: String)
}
