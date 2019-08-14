//
//  ViewController.swift
//  NCH Wifi Controller
//
//  Created by Langston Howley on 7/15/19.
//  Copyright © 2019 Nextek Power Systems. All rights reserved.
//

import Cocoa
import IOBluetooth
import IOBluetoothUI


/// This is the class that has complete control of the UI elements displayed by the app window.
///
/// - Author: Langston Howley
/// - Date: Monday July 22, 2019
/// - Version: 1.0
/// - Since: 2019-07-22
class ViewController: NSViewController{
    var searchDelegate = SearchDelegate() //The Delegate for device searches
    var pairDelegate = PairDelegate() //The Delegate for device pairing
    var connectDelegate = ConnectDelegate() //The Delegate for device connection
    var connector = Connector() //A helper class to facilitate device connection

    var nchs = [IOBluetoothDevice]() //The list of nchs found during search
    var ibdi = IOBluetoothDeviceInquiry() //The object that allows for device searching
    var selectedNCH = IOBluetoothDevice() //The nach selected by the user
    
    var width = CGFloat() //The width of the app
    var height = CGFloat() //The height of the app
    var og_x = CGFloat() //The original x position of the button selected by the user
    var og_y = CGFloat() //The original y position of the button selected by the user
    var current_x = CGFloat() //The current x value of a placed button
    var current_y = CGFloat() //The current y value of a placed button
    
    var nchButtons = [NSButton]() //The list of nch buttons
    var wifi_status = NSTextField() //The text field holding the selected nch's wifi status
    var selectedButton = NSButton() //The button selected by the user
    var press_s_label = NSTextField() //The label saying "Press 's' To Begin Another Search"
    var toggleWifiButton = NCHButton() //The button to toggle nch wifi
    var toggleWifiCell = NCHButtonCell() //The button cell
    
    var nch_connection = false //Whether or not a connection to the nch is being made or is already made
    var manually_disconnected = false; //Whether or not the user manually disconnected from the nch
    var status = String() //The text that is put into wifi_status
    var nchReturn = String() //The return from the nch when wifi is requested
    
    @IBOutlet weak var progress_indicator: NSProgressIndicator! //The loading spinner
    @IBOutlet weak var loading_field: NSTextField! //The text displayed during loading
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Add this to the the search and connect delegates
        searchDelegate.attachObserver(observer: self)
        connectDelegate.attachObserver(observer: self)
        
        //Attach the search delegate to a device searcher and begin the search
        ibdi.delegate = searchDelegate
        ibdi.updateNewDeviceNames = true
        switch (ibdi.start()) {
            case kIOReturnSuccess:
                break
            default:
                dialogCancel(question: "Searching Failed. Please try again.")
        }
        
        //This allows for certain key presses to be processed by the application
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown, handler: keyDownEvent)
    }
    
    /// This handles the key down events during runtime. The key *'s'* is reserved for searching and the key *'d'* is reserved for discconnecting from an NCH.
    ///
    ///- Important:
    ///     The key *'s'* only works when the program is not searching and/or connected to an NCH.
    ///
    ///     The key *'d'* only works when connected to an NCH.
    ///
    ///- Parameter event: The event associated with a key press.
    ///- Returns: NSEvent (unused)
    func keyDownEvent(event: NSEvent) -> NSEvent {
        if((event.characters?.elementsEqual("s"))! || (event.characters?.elementsEqual("S"))!){
            //"S" and "s" keys
            if(!searchDelegate.isSearching && !nch_connection){
                //Re-initialize the device searcher and begin a new search
                ibdi = IOBluetoothDeviceInquiry(delegate: searchDelegate)
                ibdi.updateNewDeviceNames = true
                ibdi.start()
            }
            else{
                //If the app is already searching or there is a connection with the nch don't search again.
                if(searchDelegate.isSearching){
                    dialogCancel(question: "Cannot Start Search: Already Searching")
                }
                else if(nch_connection){
                    dialogCancel(question: "Cannot Start Search: Making Connection or Already Connected to an NCH")
                }
            }
        }
        else if((event.characters?.elementsEqual("d"))! || (event.characters?.elementsEqual("D"))!){
            //"D" and "d" keys
            if(connector.channel.isOpen()){
                //This starts the process of disconnection.
                buttonClicked(sender: NSButton())
            }
        }
        else if((event.characters?.elementsEqual("h"))! || (event.characters?.elementsEqual("H"))!){
            let s1 = "-To begin a search for NCHs press 's'.";
            let s2 = "-To pop up this menu press 'h'.";
            let s3 = "-To make a connection to an NCH, press the button with the NCH's name on it.";
            let s4 = "-Once connected, press the button with the title 'Turn Wifi: ' to toggle the NCH's wifi.";
            let s5 = "-To disconnect press 'd' or the button with the NCH's name on it on the bottom of the window.";
            let full = s1 + "\n\n" + s2 + "\n\n" + s3 + "\n\n" + s4 + "\n\n" + s5;
            
            
            dialogCancel(question: full)
        }
        
        
        return event
    }
    
    override func viewWillLayout() {
        //Set the width and height variables after the window is displayed.
        width = self.view.bounds.size.width
        height = self.view.bounds.size.height
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    /// Pops up an NSAlert with a 'yes' and 'no' button. The message is set to the *question* specified.
    ///
    /// - Parameter question: The question to ask the user for confirmation.
    /// - Returns: *true* if the user answered 'yes', *false* if the user answered 'no'.
    func dialogConfirmation(question: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = question
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        alert.icon = NSImage(imageLiteralResourceName: "n_logo")
        return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
    }
    
    /// Pops up an NSAlert the specifies when a user enetered a command or key when they weren't supposed to.
    ///
    /// - Parameter question: The message to show the user.
    func dialogCancel(question: String){
        let alert = NSAlert()
        alert.messageText = question
        alert.addButton(withTitle: "Ok")
        alert.icon = NSImage(imageLiteralResourceName: "n_logo")
        alert.runModal()
    }
    
    /// When an NCH button is clicked on the UI, this method is called.
    ///
    /// - Parameter sender: the button clicked.
    /// - Important:
    ///     If a connection had been made and the button is clicked, this disconnects the user from the NCH
    @objc func buttonClicked(sender: NSButton){
        selectedButton = sender
        noSLabel()
        if(connector.channel.isOpen()){
            //DISCONNECT
            if(dialogConfirmation(question: "Disconnect from \(selectedNCH.name!)?")){
                manually_disconnected = true;
                print("Disconnecting")
                bringUpLoadingAnimations(loadingMessage: "Disconnecting From \(selectedNCH.name!)", completion: {
                    print("Done putting up animations")
                })
                connector.disconnect()
            }
            else{
                print("Not Disconnecting")
            }
            return
        }
        else{
            if(!nch_connection){
                pairWithNCH(sender: sender)
            }
            else{
                dialogCancel(question: "Cannot Start Connection: Making Connection or Already Connected to an NCH")
            }
        }
        
    }
    
    /// Pairs the user with the nch selected by the user.
    ///
    /// - Parameter sender: the button clicked by the user denoting the NCH
    func pairWithNCH(sender: NSButton){
        let title = sender.title
        
        for nch in nchs{
            //loop through the found nchs and check which nch's name matches the name of the button
            if title.elementsEqual(nch.name){
                if(searchDelegate.isSearching){
                    ibdi.stop()
                }
                
                selectedNCH = nch
                
                //This performs an SDP query on the NCH to find the RFCOMM port
                nch.performSDPQuery(nil)
                
                //Set the original x and y so that the button can move and be returned
                og_x = sender.frame.origin.x
                og_y = sender.frame.origin.y
                
                if(dialogConfirmation(question: "Pair and Connect to \(selectedNCH.name ?? "Unknown")?")){
                    
                    if(!nch.isPaired()){
                        //Start a new pairing process
                        let ibdp = IOBluetoothDevicePair(device: nch)
                        pairDelegate.attachObserver(observer: self)
                        ibdp?.delegate = pairDelegate
                        ibdp?.start()
                        break
                    }
                    else{
                        //Called the paired function if already paired with the nch
                        paired()
                        break;
                    }
                }
            }
        }
    }
    
    
    /// Sends the *Wifi_Disable* or *Wifi_Enable* command to the NCH
    @objc func sendWifi(){
        //print("Called")
        
        if(toggleWifiCell.title.elementsEqual("Turn Wifi OFF")){
            connector.write(message: "Wifi_Disable")
        }
        else if(toggleWifiCell.title.elementsEqual("Turn Wifi ON")){
            connector.write(message: "Wifi_Enable")
        }
        
        bringUpLoadingAnimations(loadingMessage: "Sending Command to " + selectedNCH.name, completion: {
            print("Done");
        });
        
        toggleWifiButton.isEnabled = false
        selectedButton.isEnabled = false
        DispatchQueue.global().async {
            //Remake the currently displayed screen with updated information
            self.setUpConnectScreen()
        }
        
    }
    
    /// This brings up the loading animations seen at the bottom of the app whenever an extended operation has begun.
    ///
    /// - Parameters:
    ///   - loadingMessage: The message shown
    ///   - completion: What to do when the loading animations are finished being put up.
    func bringUpLoadingAnimations(loadingMessage: String, completion: () -> ()){
        progress_indicator.startAnimation(self)
        loading_field.isEditable = false
        loading_field.wantsLayer = true
        loading_field.alignment = NSTextAlignment.center
        progress_indicator?.isHidden = false
        loading_field?.isHidden = false
        loading_field.stringValue = loadingMessage
        loading_field.sizeToFit()
        loading_field.frame.origin.x = (width/2)-loading_field.frame.width/2
        progress_indicator.frame.origin.x = (width/2)-progress_indicator.frame.width/2
        
       
        
        animateTextFade(layer: loading_field.layer!)
        completion()
    }
    
    
    /// This takes down the loading animations indicating that the process is finished.
    func takeDownLoadingAnimations(){
        progress_indicator?.stopAnimation(self)
        progress_indicator?.isHidden = true
        loading_field?.isHidden = true
    }
    
    
    /// This updates the UI to display the "second screen" which is shown when a connection is made to an NCH
    func setUpConnectScreen(){
        nchReturn = ""
        connector.write(message: "Get_Wifi") //Send the Get_Wifi command to the NCH
        
        var finished = false
        
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                //Since this is always called asynchronously a special method is used to run this
                //on the main thread to update the UI
                self.bringUpLoadingAnimations(loadingMessage: "Fetching Data From NCH", completion: {
                    print("Done bringing up loading animations")
                })
            }
            while true{
                if(self.nchReturn.elementsEqual("0")){
                    self.status = "Wifi Status: OFF"
                    finished = true
                    break
                }
                else if(self.nchReturn.elementsEqual("1")){
                    self.status = "Wifi Status: ON"
                    finished = true
                    break
                }
            }
        }
        while !finished {
            //This makes the program wait until the NCH responds to the Get Wifi command
            sleep(2)
        }
        DispatchQueue.main.async {
            self.wifiStatus()
            self.wifiButton()
            self.takeDownLoadingAnimations()
            self.enableButtons()
        }
        
    }
    
    /// This places the "Press 's' To Begin Another Search" Label shown when a search is finished.
    func sLabel(){
        press_s_label.isEnabled = true
        press_s_label.wantsLayer = true
        press_s_label.isHidden = false
        press_s_label.isBezeled = false
        press_s_label.drawsBackground = false
        press_s_label.stringValue = "Press 's' to Begin Another Search"
        press_s_label.textColor = NSColor.white
        press_s_label.sizeToFit()
        press_s_label.frame.origin.x = (width/2)-(press_s_label.frame.width/2)
        press_s_label.frame.origin.y = 10
        
        animateTextFade(layer: press_s_label.layer!)
        self.view.addSubview(press_s_label)
        
    }
    
    /// This removes the "Press 's'" label
    func noSLabel(){
        press_s_label.isEnabled = false
        press_s_label.isHidden = true
    }
    
    /// This places the wifi status text field.
    func wifiStatus(){
        self.wifi_status.isHidden = false
        self.wifi_status.isEnabled = true
        self.wifi_status.isEditable = false
        self.wifi_status.stringValue = status
        self.wifi_status.textColor = NSColor.white
        
        self.wifi_status.font = NSFont(name: "Arial", size: 20)
        self.wifi_status.sizeToFit()
        
        self.wifi_status.frame.origin.x = (self.width/2) - (self.wifi_status.frame.width/2)
        self.wifi_status.frame.origin.y = (self.height/2) - (self.wifi_status.frame.height/2)
        self.wifi_status.drawsBackground = false
        self.wifi_status.isBezeled = false
        self.view.animator().addSubview(self.wifi_status)
    }
    
    /// This takes away the wifi status text field.
    func noWifiStatus(){
        wifi_status.isHidden = true
        wifi_status.isEnabled = false
    }
    
    /// This places the toggle wifi button.
    func wifiButton(){
        self.toggleWifiCell.isEnabled = true
        self.toggleWifiButton.isEnabled = true
        self.toggleWifiButton.isHidden = false
        self.toggleWifiButton.setFrameSize(NSSize(width: 250, height: 50))
        
        if(status.elementsEqual("Wifi Status: ON")){
            self.toggleWifiCell.title = "Turn Wifi OFF"
            self.toggleWifiCell.font = NSFont(name: "Arial", size: 15)
            self.toggleWifiCell.backgroundColor = NSColor(red:0.76, green:0.13, blue:0.13, alpha:0.5)
        }
        else if(status.elementsEqual("Wifi Status: OFF")){
            self.toggleWifiCell.title = "Turn Wifi ON"
            self.toggleWifiCell.backgroundColor = NSColor(red:0.00, green:0.70, blue:0.24, alpha:0.5)
        }
        
        self.toggleWifiButton.cell = self.toggleWifiCell
        self.toggleWifiButton.frame.origin.x = (self.width/2) - (self.toggleWifiButton.frame.width/2)
        self.toggleWifiButton.frame.origin.y = (self.wifi_status.frame.origin.y)-(self.toggleWifiButton.frame.height)-10
        self.toggleWifiButton.target = self
        self.toggleWifiButton.action = #selector(self.sendWifi)
        
        self.view.animator().addSubview(self.toggleWifiButton)
    }
    
    /// This takes away the toggle button.
    func noWifiButton(){
        toggleWifiCell.isEnabled = false
        toggleWifiButton.isEnabled = false
        toggleWifiButton.isHidden = true
    }
    
    /// Any button that occupies the screen is hidden and disabled when this is called.
    func disableButtons(){
        for view in self.view.subviews{
            if view.isKind(of: NSButton.self){
                (view as! NSButton).isEnabled = false
                view.isHidden = true
            }
        }
    }
    
    /// This brings any button that was hidden back onto the screen and enabled
    func enableButtons(){
        for view in self.view.subviews{
            if view.isKind(of: NSButton.self){
                (view as! NSButton).isEnabled = true
                view.isHidden = false
            }
        }
    }
    
    /// This is the "master resetter" that resets all values set post startup
    func reset(){
        og_x = 0
        og_y = 0
        current_x = 0
        current_y = height-50
        nchs.removeAll()
        nchButtons.removeAll()
        
        for thing in self.view.subviews{
            if (thing.isKind(of: NSButton.self)){
                thing.removeFromSuperview()
            }
        }
        
        noSLabel()
        manually_disconnected = false;
    }
    
    /// This moves the selected NCH button to the "Connected" position.
    ///
    /// - Important: This only occur when a connection is made.
    func moveButtonToConnectedPosition() {
        NSAnimationContext.runAnimationGroup({(context) -> Void in
            context.duration = 1.5
            let button = selectedButton
            
            button.animator().frame.origin.x = (width/2)-(button.frame.width/2)
            button.animator().frame.origin.y = (loading_field.frame.origin.y)+loading_field.frame.height+10
            button.title = "\(selectedNCH.name!)\n(Press To Disconnect)"
        }) {
            print("Animation done")
        }
    }
    
    /// This moves the selected button back to its original position.
    func moveButtonToOriginalPosition(){
        NSAnimationContext.runAnimationGroup({(context) -> Void in
            context.duration = 1.5
            //self.theWidthConstraint.animator().constant = 200
            let button = selectedButton
            
            /*
            for thing in self.view.subviews{
                if(thing.isKind(of: NSButton.self) && (thing as! NSButton).title.prefix(9).elementsEqual(selectedNCH.name)){
                    button = thing as! NSButton
                }
            }
            */
            
            button.animator().frame.origin.x = og_x
            button.animator().frame.origin.y = og_y
            button.title = "\(selectedNCH.name ?? "Unknown")"
            
            selectedNCH = IOBluetoothDevice()
            nch_connection = false
            enableButtons()
            sLabel()
            
        }) {
            print("Animation done")
        }
    }
    
    
    /// This animates the *layer* given by an object of type NSView to fade in and out.
    ///
    /// - Parameter layer: The layer of the NSView
    func animateTextFade(layer: CALayer){
        if(layer.animation(forKey: "opacity") != nil){
            print("Non null animation")
            return
        }
        
        let fadeIn = CABasicAnimation(keyPath: "opacity")
        fadeIn.fromValue = 0.0
        fadeIn.toValue = 1.0
        fadeIn.duration = 1.5
        fadeIn.beginTime = 0
        fadeIn.delegate = self
        fadeIn.setValue(layer, forKey: "layer")
        fadeIn.setValue("in", forKey: "type")
        
        layer.add(fadeIn, forKey: "opacity")
        //print(layer.animation(forKey: "opacity")!)
    }
    
}
// MARK: - Search Delegate Observer
extension ViewController : NCHListObserver{
    //Every method within this extension is called from SearchDelegate
    
    /// This method is called from the *SearchDelegate* which in this case brings up the loading animations and resets values.
    func onSearchStart() {
        bringUpLoadingAnimations(loadingMessage: "Searching For Nearby NCHs", completion: {
            print("Completed Bringing Up Animations")
        })
        reset()
    }
    
    
    /// This updates the NCH list and adds an NCH button to the screen upon being called from the *SearchDelegate*
    ///
    /// - Parameter nch: The NCH to add
    func update(nch: IOBluetoothDevice!) {
        
        //Search through the list of NCHs and if the NCH is
        //already in the list don't add a button
        var alreadyIn = false
        for d in nchs {
            if(d.name.elementsEqual(nch.name)){
                alreadyIn = true
                print("\(d.name!) is already in the list")
                break
            }
        }
        
        if(!alreadyIn){
            //Determine where the button will go.
            if(nchButtons.count > 0){
                current_x += CGFloat(integerLiteral: 200)
            }
            if (current_x >= width){
                current_x = 0
                current_y -= CGFloat(integerLiteral: 50)
            }
            
            //print("(\(current_x),\(current_y))")
            if(current_y - loading_field.frame.origin.y < 50){
                //If the button will intersect the loading layout, don't place it.
                return
            }
            
            nchs.append(nch!)
            print("Added \(nch!.name ?? "Unknown") To Array")
            
            //This creates the button in a custom style
            let cell = NCHButtonCell()
            let button = NCHButton(frame: NSMakeRect(current_x, current_y, 200, 50))
            var color = NSColor()
            if(nchs.count%2 == 0){color = NSColor(red:0.00, green:0.70, blue:0.24, alpha:0.5)}
            else{color = NSColor(red:0.01, green:0.45, blue:0.76, alpha:0.5)}
            cell.backgroundColor = color
            button.cell = cell
            button.bezelColor = color
            button.title = "\(nch.name ?? "Unknown")"
            button.ignoresMultiClick = true
            
            //setting the buttonClicked action.
            button.target = self
            button.action = #selector(buttonClicked)
            
            self.view.addSubview(button)
            nchButtons.append(button)
            
        }
        
    }
    
    /// When the search finishes, this is called.
    func onSearchFinish() {
        sLabel()
        takeDownLoadingAnimations()
    }
    
}
// MARK: - Pair Delegate Observer
extension ViewController : NCHPairingObserver{
    //Every method within this extension is called from PairDelegate
    
    /// When a pair is initiated this is called.
    func pairing() {
        bringUpLoadingAnimations(loadingMessage: "Pairing With \(selectedNCH.name!)", completion: {
            print("Completed Bring Up Loading Animations")
        })
        noSLabel()
        nch_connection = true
    }
    
    /// This is called when a pair fails.
    func pairingFailed() {
        nch_connection = false;
        takeDownLoadingAnimations()
        //dialogCancel(question: "Failed to pair. Please try again.")
        if(dialogConfirmation(question: "Pairing with \(selectedNCH.name!) Failed. Attempt again?")){
            pairWithNCH(sender: selectedButton)
            return
        }
        
        enableButtons()
    }
    
    /// This is called when pairing is successful and the connecting process can begin.
    func paired() {
        noSLabel()
        takeDownLoadingAnimations()
        print("Pairing Success!")
        nch_connection = true
        
        bringUpLoadingAnimations(loadingMessage: "Connecting To \(selectedNCH.name!)", completion: {
            print("Completed Bring Up Loading Animations")
        })
        connector = Connector()
        connector.connect(nch: selectedNCH, connectDelegate: connectDelegate)
        
    }
}
extension ViewController : NCHConnecterObserver{
    //Every method within this extension is called from ConnectDelegate
    
    /// When a connection to an NCH is made this is called to move the selected button and create the "connected screen"
    func onConnect() {
        print("Connected")
        takeDownLoadingAnimations()
        disableButtons()
        
        for thing in self.view.subviews{
            if(thing.isEqual(selectedButton)){
                thing.isHidden = false;
                (thing as! NSButton).isEnabled = true;
            }
        }
        
        moveButtonToConnectedPosition()
        
        //Asynchronously set up the connected screen
        DispatchQueue.global().async {
            self.setUpConnectScreen()
        }
        
    }
    
    /// When connection fails this pops up a message telling the user to attempt another connection.
    func onConnectFailure() {
        print("Connect Failure")
        //dialogCancel(question: "Connection failed. Please try again.")
        if(dialogConfirmation(question: "Connecting to \(selectedNCH.name!) Failed. Attempt again?")){
            connector = Connector()
            connector.connect(nch: selectedNCH, connectDelegate: connectDelegate)
            return
        }
        moveButtonToOriginalPosition()
        takeDownLoadingAnimations()
        enableButtons()
    }
    
    /// When the user is disconnected from an NCH for any reason this is called. It resets the screen to the "home"/original screen layout
    func onDisconnect() {
        print("Disconnected")
        
        if(!manually_disconnected){
            dialogCancel(question: "Connection to NCH was broken")
        }
        
        moveButtonToOriginalPosition()
        takeDownLoadingAnimations()
        enableButtons()
        noWifiButton();
        noWifiStatus();
    }
    
    /// This receives the message sent by an NCH
    ///
    /// - Parameter ret: (Short for return) The response from the NCH
    func passNCHReturn(ret: String){
        self.nchReturn = ret
    }
}
extension ViewController : CAAnimationDelegate{
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        
        let layer = anim.value(forKey: "layer") as? CALayer
        let type = anim.value(forKey: "type") as? String
        
        if (type?.elementsEqual("in"))! {
            let fadeOut = CABasicAnimation(keyPath: "opacity")
            fadeOut.fromValue = 1.0
            fadeOut.toValue = 0.0
            fadeOut.duration = 1.5
            fadeOut.beginTime = 0
            fadeOut.delegate = self
            fadeOut.setValue(layer, forKey: "layer")
            fadeOut.setValue("out", forKey: "type")
            
            layer?.add(fadeOut, forKey: "opacity")
        }
        else if (type?.elementsEqual("out"))!{
            let fadeIn = CABasicAnimation(keyPath: "opacity")
            fadeIn.fromValue = 0.0
            fadeIn.toValue = 1.0
            fadeIn.duration = 1.5
            fadeIn.beginTime = 0
            fadeIn.delegate = self
            fadeIn.setValue(layer, forKey: "layer")
            fadeIn.setValue("in", forKey: "type")
            
            layer?.add(fadeIn, forKey: "opacity")
        }
        
        if((layer?.isEqual(press_s_label.layer))! && (type?.elementsEqual("out"))!){
            let s = "Press 's' to Begin Another Search"
            let h = "Press 'h' For Help"
            //print("Animation did stop")
            
            if(press_s_label.stringValue.elementsEqual(s)){
                press_s_label.stringValue = h
            }
            else{
                if(!nch_connection){
                    press_s_label.stringValue = s
                }
                else{
                    press_s_label.stringValue = h
                }
            }
            
            press_s_label.sizeToFit()
            press_s_label.frame.origin.x = (width/2)-(press_s_label.frame.width/2)
            press_s_label.frame.origin.y = 10
        }
        
        
        
    }
    
    func animationDidStart(_ anim: CAAnimation) {
        //sdafdd
    }
    
}


/// A custom Button
class NCHButton : NSButton{
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}

/// A custom Button Cell
class NCHButtonCell : NSButtonCell{
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    override init(textCell string: String) {
        super.init(textCell: string)
    }
    override init(imageCell image: NSImage?) {
        super.init(imageCell: image)
    }
    
}


