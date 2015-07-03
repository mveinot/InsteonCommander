//
//  PreferencesWindow.swift
//  InsteonCommander
//
//  Created by Mark Veinot on 2015-07-03.
//  Copyright (c) 2015 Mark Veinot. All rights reserved.
//

import Cocoa

class PreferencesWindow: NSWindowController, NSTableViewDataSource, NSTableViewDelegate {

    var dataSource: [String] = ["a", "b", "c", "d", "e", "f"];
    var devices: [InsteonDevice] = [];
    
    @IBOutlet weak var deviceTable: NSTableView!
    @IBAction func deviceAction(sender: NSTableView) {
        println(devices[sender.selectedRow].name);
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activateIgnoringOtherApps(true)
        deviceTable.setDataSource(self);

    }
    
    override var windowNibName : String! {
        return "PreferencesWindow"
    }
    
    func test(deviceList: [InsteonDevice]) {
        devices = deviceList;
        println("devices passed: \(devices.count)");
        deviceTable.reloadData();
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return devices.count;
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
