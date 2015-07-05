//
//  AppDelegate.swift
//  InsteonCommander
//
//  Created by Mark Veinot on 2015-06-28.
//  Copyright (c) 2015 Mark Veinot. All rights reserved.
//

import Cocoa
import Darwin

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    var preferencesWindow: PreferencesWindow!
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
    var prefItem : NSMenuItem = NSMenuItem()
    var insteonHub : InsteonHub = InsteonHub()
    var configPath = "";
    
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
        configPath = dir.stringByAppendingPathComponent(file)
        insteonHub.readFromFile(configPath)
        initMenu()
    }
    
    func initMenu() {
        
        menu.removeAllItems()
        
        //Add menuItems
        exitItem.title = "Exit";
        exitItem.action = Selector("closeApp:");
        exitItem.keyEquivalent = "";
        menu.addItem(exitItem);
        
        prefItem.title = "Edit Devices...";
        prefItem.action = Selector("showPrefWindow");
        prefItem.keyEquivalent = "";
        menu.addItem(prefItem);
        
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
    
    func devicesChanged()
    {
        initMenu();
        insteonHub.writeToFile(configPath);
    }
    
    @IBAction func OKPressed(sender: NSButton) {
        self.window!.orderOut(self)
    }
    
    func aboutApp() {
        let popup: NSAlert = NSAlert();
        popup.messageText = "Insteon Commander";
        popup.informativeText = "Written by: Mark Veinot\nVersion: 1.1.0";
        popup.alertStyle = NSAlertStyle.InformationalAlertStyle;
        popup.addButtonWithTitle("OK");
        popup.runModal();
    }
    
    func showPrefWindow() {
        preferencesWindow = PreferencesWindow();
        preferencesWindow.showWindow(nil);
        preferencesWindow.setDeviceList(insteonHub.devices);
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

