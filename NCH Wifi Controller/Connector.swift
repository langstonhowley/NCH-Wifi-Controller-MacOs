//
//  Connector.swift
//  NCH Wifi Control
//
//  Created by Langston Howley on 7/11/19.
//  Copyright © 2019 Nextek Power Systems. All rights reserved.
//

import Foundation
import IOBluetoothUI;
import IOBluetooth;


/// The Connector class is a helper class to help facilitate the connecting and messgae sending to an NCH.
public class Connector{
    
    var channel = IOBluetoothRFCOMMChannel(); // The RFComm channel that makes the connection.
    var channel_ptr : AutoreleasingUnsafeMutablePointer<IOBluetoothRFCOMMChannel?>? = nil; // A pointer to the channel.
    var id = BluetoothRFCOMMChannelID(); // The id associated with the RFComm channel.
    var id_ptr = UnsafeMutablePointer<BluetoothRFCOMMChannelID>(nil) // A pointer to the id.
    
    
    /// This connects the Mac to an NCH
    ///
    /// - Parameters:
    ///   - nch: The targt NCH
    ///   - connectDelegate: The delegate to recieve connection events
    func connect(nch: IOBluetoothDevice!, connectDelegate: ConnectDelegate!){
        id_ptr = UnsafeMutablePointer<BluetoothRFCOMMChannelID>(&id)
        
        if(!findRFCOMM(nch: nch)){
            // If the RFComm socket could not be found the connection cannot occur so return
            connectDelegate.failed()
            print("Couldn't fnd RFCOMM")
            return
        }
         
         channel_ptr = AutoreleasingUnsafeMutablePointer<IOBluetoothRFCOMMChannel?>.init(&channel)
        if(nch.openRFCOMMChannelAsync(channel_ptr, withChannelID: id, delegate: connectDelegate) == kIOReturnSuccess){
            //This signifies that the connection process started.
            print("This says it started")
        }
        else{
            connectDelegate.failed()
            print("This says it didnt start")
        }
    }
    
    /// This disconnects the Mac from an NCH
    func disconnect(){
        if(channel.close() == kIOReturnSuccess){
            // The channel was closed successfully and the connection ended
            print("Successful Closing")
        }
        else{
            print("There was an error closing it")
        }
    }
    
    /// This attempts to find the RFComm socket for a target NCH
    ///
    /// - Parameters:
    ///   - nch: The target NCH
    /// - Returns: *true* if the RFComm socket is found, *false* if not.
    func findRFCOMM(nch: IOBluetoothDevice!) -> Bool {
        nch.performSDPQuery(nil)
        let a = nch.services;
        if(a != nil && a!.count > 0){
            for record in a!{
                if((record as! IOBluetoothSDPServiceRecord).getRFCOMMChannelID(id_ptr) == kIOReturnSuccess){
                    print("found the rfcomm record")
                    return true
                }
                else{
                    print(a!)
                }
            }
        }
        else{
            print("Coulnd't get services")
        }
        return false
    }
    
    
    /// This writes a command to the NCH
    ///
    /// - Parameter message: The command
    func write(message: String){
        var buf = [UInt8] (message.utf8);
        let p = UnsafeMutableRawPointer(&buf)
        
        channel.writeSync(p, length: UInt16(buf.count))
    }
}

