//
//  AppDelegate.swift
//  InsteonCommander
//
//  Created by Mark Veinot on 2015-06-28.
//  Copyright (c) 2015 Mark Veinot. All rights reserved.
//

import Cocoa
import Darwin

extension String {
    
    /// Create NSData from hexadecimal string representation
    ///
    /// This takes a hexadecimal representation and creates a NSData object. Note, if the string has any spaces, those are removed. Also if the string started with a '<' or ended with a '>', those are removed, too. This does no validation of the string to ensure it's a valid hexadecimal string
    ///
    /// The use of `strtoul` inspired by Martin R at http://stackoverflow.com/a/26284562/1271826
    ///
    /// :returns: NSData represented by this hexadecimal string. Returns nil if string contains characters outside the 0-9 and a-f range.
    
    func dataFromHexadecimalString() -> NSData? {
        let trimmedString = self.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<> ")).stringByReplacingOccurrencesOfString(" ", withString: "")
        
        // make sure the cleaned up string consists solely of hex digits, and that we have even number of them
        
        var error: NSError?
        let regex = NSRegularExpression(pattern: "^[0-9a-f]*$", options: .CaseInsensitive, error: &error)
        let found = regex?.firstMatchInString(trimmedString, options: nil, range: NSMakeRange(0, count(trimmedString)))
        if found == nil || found?.range.location == NSNotFound || count(trimmedString) % 2 != 0 {
            return nil
        }
        
        // everything ok, so now let's build NSData
        
        let data = NSMutableData(capacity: count(trimmedString) / 2)
        
        for var index = trimmedString.startIndex; index < trimmedString.endIndex; index = index.successor().successor() {
            let byteString = trimmedString.substringWithRange(Range<String.Index>(start: index, end: index.successor().successor()))
            let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
            data?.appendBytes([num] as [UInt8], length: 1)
        }
        
        return data
    }
}

class InsteonDevice {
    var address: String
    var name: String
    var type: Int
    
    init(address: String, name: String, type: Int) {
        self.address = address;
        self.name = name;
        self.type = type;
    }
    
    func print() {
        println("Device: Address: \(self.address)/Name: \(self.name)/Type: \(self.type)");
    }
}

class InsteonHub: NSObject, NSXMLParserDelegate {
    
    enum InsteonCommand: Int {
        case On = 11;
        case Fast_On = 12;
        case Off = 13;
        case Fast_Off = 14;
        case Bright = 15;
        case Dim = 16;
        case Status = 19;
        
        func value() -> Int {
            return self.rawValue;
        }
        
        func  valueAsString() -> String {
            return String(self.rawValue);
        }
    }
    
    var devices: [InsteonDevice] = [];
    var ip = "";
    var eName = "";
    
    func levelToHex(level: Int) -> String {
        if (level < 0) {
            return "ZZ";
        }
        
        let hex_level: Int = Int(level * 255) / 100;
        var hexString = NSString(format: "%02X", hex_level) as String;
        
        return hexString;
    }
    
    func sendCommand(device: Int, command: InsteonCommand, level: Int?) -> Int {
        var onPercent = 0;
        var commandStr = "";
        var _level = 0;
        var bytesRead = 0;
        var needBytes = 1;

        if (level != nil) {
            _level = level!;
        }
        
        switch command {
        case InsteonCommand.On:
            if (level == nil) {
                _level = 100;
            }
        case InsteonCommand.Off, InsteonCommand.Status:
            _level = 0;
        default:
            if (level != nil) {
                _level = level!;
            }

        }
        
        let levelString = levelToHex(_level);

        commandStr = "0262"+self.devices[device].address+"0F"+command.valueAsString()+levelString;

        let port = 9761;
        var inp: NSInputStream?;
        var out: NSOutputStream?;
        NSStream.getStreamsToHostWithName(ip, port: port, inputStream: &inp, outputStream: &out);
        let inputStream = inp!;
        let outputStream = out!;
        inputStream.open();
        outputStream.open();
        var outputBuffer = Array<UInt8>(count:8, repeatedValue: 0);
        let outData = commandStr.dataFromHexadecimalString();
        outData?.getBytes(&outputBuffer,length:8);
        outputStream.write(&outputBuffer, maxLength: 8);
      
        let bufferSize = 64;
        var inputBuffer = Array<UInt8>(count:bufferSize, repeatedValue: 0);
        if (command == InsteonCommand.Status)
        {
            needBytes = 19;
            sleep(1);
        }
        
        do {
            bytesRead = inputStream.read(&inputBuffer, maxLength: bufferSize);
        } while (bytesRead <= needBytes);

        onPercent = Int(inputBuffer[19]) * 100 / 255;

        inputStream.close();
        outputStream.close();

        return onPercent;
    }
    
    func on(device: Int) -> Int {
        return sendCommand(device, command: InsteonCommand.On, level: 100);
    }
    
    func off(device: Int) -> Int {
        return sendCommand(device, command: InsteonCommand.Off, level: 100);
    }
    
    func bright(device: Int) -> Int {
        return sendCommand(device, command: InsteonCommand.Bright, level: 100);
    }
    
    func dim(device: Int) -> Int {
        return sendCommand(device, command: InsteonCommand.Dim, level: 0);
    }
    
    func setLevel(device: Int, level: Int) -> Int {
        return sendCommand(device, command: InsteonCommand.On, level: level);
    }
    
    func getStatus(device: Int) -> Int {
        return sendCommand(device, command: InsteonCommand.Status, level: 0);
    }
    
    func doParse(filePath : String) {
        var data : NSData = NSData(contentsOfFile: filePath)!
        var xmlString = NSString(data: data, encoding: NSUTF8StringEncoding)
        var xmlParser : NSXMLParser = NSXMLParser(data: data)

        xmlParser.delegate = self
        xmlParser.parse()
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName:String?, attributes attributeDict: [NSObject : AnyObject]) {
        
        var deviceAddress = "";
        var deviceName = "";
        var tmpDeviceType = "";
        var deviceType = 0;
        
        eName = elementName;
        if elementName == "device" {
            if attributeDict["address"] != nil {
                deviceAddress = attributeDict["address"] as! String
            }
            if attributeDict["name"] != nil {
                deviceName = attributeDict["name"] as! String
            }
            if attributeDict["type"] != nil {
                tmpDeviceType = attributeDict["type"] as! String
                if (tmpDeviceType.toInt() != nil) {
                    deviceType = tmpDeviceType.toInt()!;
                } else {
                    println("Couldn't convert \(tmpDeviceType) to Int");
                }
            }
            
            var insteonDevice = InsteonDevice(address: deviceAddress, name: deviceName, type: deviceType)
            devices.append(insteonDevice)
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String?) {
        let data = string!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        if (!data.isEmpty) {
            if (eName == "ip") {
                if let tmpIP = data as String? {
                    self.ip = tmpIP;
                }
            }
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet weak var percentLabel: NSTextField!
    @IBOutlet weak var sliderValue: NSSlider!
    @IBOutlet weak var sliderUI: NSSlider!
    
    var buttonPresses = 0;
    var sliderPercent: Int = 0;
    var activeDevice = 0;
    
    var statusBar = NSStatusBar.systemStatusBar()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    var exitItem : NSMenuItem = NSMenuItem()
    var aboutItem : NSMenuItem = NSMenuItem()
    var insteonHub : InsteonHub = InsteonHub()
    
    override func awakeFromNib() {
        percentLabel.stringValue = "\(sliderPercent)%"
        
        //Icon
        let icon = NSImage(named: "tray.png");
        icon!.setTemplate(true);
        
        //Statusbar item
        statusBarItem = statusBar.statusItemWithLength(-1)
        statusBarItem.menu = menu;
        statusBarItem.image = icon;
        
        let file = ".insteon_hub"
        let dir = NSHomeDirectory()
        let path = dir.stringByAppendingPathComponent(file)
        insteonHub.doParse(path)
        initMenu()
    }
    
    func initMenu() {
        
        menu.removeAllItems()
        
        //Add menuItem
        exitItem.title = "Exit";
        exitItem.action = Selector("closeApp:");
        exitItem.keyEquivalent = "";
        menu.addItem(exitItem);
        
        aboutItem.title = "About...";
        aboutItem.action = Selector("aboutApp");
        aboutItem.keyEquivalent = "";
        menu.addItem(aboutItem);
        
        menu.addItem(NSMenuItem.separatorItem())
        
        for var index = 0; index < insteonHub.devices.count; index++ {
            var tmpMenuItem : NSMenuItem = NSMenuItem()
            tmpMenuItem.title = insteonHub.devices[index].name;
            tmpMenuItem.action = Selector("controlWindow:")
            tmpMenuItem.keyEquivalent = ""
            tmpMenuItem.tag = index
            menu.addItem(tmpMenuItem)
        }
    }
    
    func setSliderPos(pos: Int) {
        sliderUI.doubleValue = Double(pos);
        percentLabel.stringValue = "\(pos)%";
    }
    
    @IBAction func percentSlider(sender: NSSlider) {
        sliderPercent = sender.integerValue;
        percentLabel.stringValue = "\(sliderPercent)%";
        insteonHub.setLevel(activeDevice, level: sliderPercent);
    }
    
    @IBAction func deviceOn(sender: NSButton) {
        insteonHub.on(activeDevice);
    }
    
    @IBAction func deviceOff(sender: NSButton) {
        insteonHub.off(activeDevice);
    }
    
    @IBAction func deviceBright(sender: NSButton) {
        insteonHub.bright(activeDevice);
    }
    
    @IBAction func deviceDim(sender: NSButton) {
        insteonHub.dim(activeDevice);
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        self.window!.orderOut(self)
    }
    
    @IBAction func OKPressed(sender: NSButton) {
        self.window!.orderOut(self)
    }
    
    func aboutApp() {
        let popup: NSAlert = NSAlert();
        popup.messageText = "Insteon Commander";
        popup.informativeText = "Written by: Mark Veinot\nVersion: 1.0.1";
        popup.alertStyle = NSAlertStyle.InformationalAlertStyle;
        popup.addButtonWithTitle("OK");
        popup.runModal();
    }
    
    func controlWindow(sender: AnyObject) {
        activeDevice = sender.tag();
        self.window!.title = "Controlling \(insteonHub.devices[activeDevice].name)";
        let sliderValue : Int = insteonHub.getStatus(activeDevice);
        self.window!.orderFront(self)
        self.window!.center();
        self.window!.styleMask = self.window!.styleMask & ~NSResizableWindowMask;
        window.level = Int(CGWindowLevelForKey(Int32(kCGFloatingWindowLevelKey)));
        if (insteonHub.devices[activeDevice].type == 91) {
            sliderUI.enabled = true;
        } else
        {
            sliderUI.enabled = false;
        }
        setSliderPos(sliderValue);
    }
    
    func closeApp(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(self);
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

