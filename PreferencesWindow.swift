//
//  PreferencesWindow.swift
//  InsteonCommander
//
//  Created by Mark Veinot on 2015-07-03.
//  Copyright (c) 2015 Mark Veinot. All rights reserved.
//

import Cocoa

class PreferencesWindow: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {

    var devices: [InsteonDevice] = [];
    
    @IBOutlet weak var deviceTable: NSTableView!
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activateIgnoringOtherApps(true)
        deviceTable.setDelegate(self);
        deviceTable.setDataSource(self);

    }
    
    override var windowNibName : String! {
        return "PreferencesWindow"
    }
    
    @IBAction func removeDevice(sender: NSButton) {
        devices.removeAtIndex(deviceTable.selectedRow);
        deviceTable.reloadData();
    }
    
    @IBAction func addDevice(sender: NSButton) {
        var insteonDevice = InsteonDevice(address: "", name: "", type: 90);
        devices.append(insteonDevice);
        deviceTable.reloadData();
        deviceTable.scrollToEndOfDocument(sender);
        let indexSet : NSIndexSet = NSIndexSet(index: devices.count - 1);
        deviceTable.selectRowIndexes(indexSet, byExtendingSelection: false);
    }
    
    @IBAction func btnSave(sender: NSButton) {
        // get a reference back to the main App window instance
        var appDelegate : AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
        
        // then tell it the device list was updated
        appDelegate.devicesChanged();

        // close the window
        self.close();
    }
    
    func setDeviceList(deviceList: [InsteonDevice]) {
        devices = deviceList;
        deviceTable.reloadData();
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return devices.count;
    }
    
    func tableView(tableView: NSTableView, setObjectValue object: AnyObject?, forTableColumn tableColumn: NSTableColumn?, row: Int) {
        if (tableColumn?.identifier != nil && object?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != nil) {
            var newValue : String = (object!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()));
            
            if (tableColumn!.identifier == "name") {
                devices[row].name = newValue;
            }
            
            if (tableColumn!.identifier == "type") {
                if (newValue.lowercaseString == "relay") {
                    devices[row].type = 90;
                } else if (newValue.lowercaseString == "dimmer") {
                    devices[row].type = 91;
                } else if (newValue.lowercaseString == "scene") {
                    devices[row].type = 92;
                }
            }
            
            if (tableColumn!.identifier == "address") {
                devices[row].address = newValue;
            }
        }
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        if (tableColumn != nil) {
            switch (tableColumn!.identifier) {
                case "name":
                    return (devices[row].name);
                case "type":
                    switch (devices[row].type) {
                    case 90:
                        return "Relay";
                    case 91:
                        return "Dimmer";
                    case 92:
                        return "Scene";
                    default:
                        return "Unknown Type";
                    }
                case "address":
                    return (devices[row].address);
            default:
                return "No data";
            }
        } else
        {
            return nil;
        }
    }
}
