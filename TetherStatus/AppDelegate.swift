//
//  AppDelegate.swift
//  tetherinfo
//
//  Created by Mark Knowles on 9/5/20.
//  Copyright © 2020 Mark Knowles. All rights reserved.
//

import Cocoa
import SwiftUI
import CoreWLAN


extension NSView {
    var isDarkMode: Bool {
        if #available(OSX 10.14, *) {
            if effectiveAppearance.name == .darkAqua {
                return true
            }
        }
        return false
    }
}

class DefaultKeys {
    public static var showDeviceKey = "showDeviceKey"
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, CWEventDelegate {

    private var statusBarItem: NSStatusItem!
    private var wifiClient: CWWiFiClient
    private var title: String = ""
    private var statusImage: NSImage?
    private var imageManager: ImageManager
    private var statusBarImageHeight = CGFloat(15)
    private var showDeviceName = false
    private var lastTetherDevice: CWTetherDevice?
    
    public static var networkTypeNoService = 0
    public static var networkTypeLabels: [String] = [
            "Search", "GSM", "GPRS", "EDGE", "3G", "4G", "LTE", "5G"]
    
    required override init() {
        do {
            self.imageManager = try ImageManager(statusBarImageHeight: statusBarImageHeight)
        } catch {
            NSLog("Exception loading ImageManager:")
            NSLog(error.localizedDescription)
            exit(0);
        }

        self.wifiClient = CWWiFiClient.shared()
        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        /* This is a really frustrating problem. When NSStatusBar gets too long, it simply
         disappears. Discussion here:
         https://stackoverflow.com/questions/4987044/can-an-nsstatusitem-be-shrunk-to-fit
         */
        //let statusImage = combinedStatusImage()
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        
        if let button = self.statusBarItem.button {
            button.imageHugsTitle = false
            button.imagePosition = NSControl.ImagePosition.imageRight
            button.title = self.title
            //button.image = self.imageManager.noDeviceImage
            button.image = self.imageManager.iPhoneImage
            //button.addObserver(self, forKeyPath: , options: nil, context: nil)
        }
        self.createMenu()
                        
        self.wifiClient.delegate = self
        
        do {
            for eventType in [CWEventType.linkDidChange, CWEventType.linkQualityDidChange, CWEventType.bssidDidChange, CWEventType.modeDidChange, CWEventType.powerDidChange, CWEventType.scanCacheUpdated, CWEventType.ssidDidChange] {
                try self.wifiClient.startMonitoringEvent(with: eventType)
            }
        } catch {
            NSLog(error.localizedDescription)
        }

        self.updateStatus()
    }

    private func isVisible() -> Bool {
        if NSApp.windows.count >= 1 {
            // get our window number

            let windowId = NSApp.windows[0].windowNumber
            let windowsListInfo = CGWindowListCopyWindowInfo(CGWindowListOption.optionOnScreenAboveWindow, CGWindowID(windowId))
            let infoList = windowsListInfo as! [[String:Any]]

            return infoList.count == 0
        } else {
            return true
        }
    }

    @objc public func updateStatus() {
        DispatchQueue.main.async() {
            
            guard let interface = self.wifiClient.interface() else {
                return
            }

            guard let tetherDevice = interface.lastTetherDeviceJoined() as! CWTetherDevice? else {
                self.statusBarItem.button?.title = ""
                self.statusBarItem.button?.image = self.imageManager.noDeviceImage
                self.lastTetherDevice = nil
                return
            }
            
            let app = (NSApp.delegate as! AppDelegate)

            //TODO: do bounds checking
            /* The battery life can be 0 to 100 (TODO: check)
             There are 10 battery images. So divide by 10 and convert to int */
        
            // I don't know what precision the batteryLife NSNumber is */
            let batteryLife = tetherDevice.batteryLife.floatValue
            let batteryIndex = Int(batteryLife / 10)        
            let batteryImage = self.imageManager.batteryImages[batteryIndex]
            batteryImage.isTemplate = true
            var cellImage: NSImage
            
            if tetherDevice.signalStrength != nil {
                cellImage = self.imageManager.cellImages[tetherDevice.signalStrength.intValue]
            } else {
                cellImage = self.imageManager.cellImages[0]
            }
            cellImage.isTemplate = true
            
            let networkTypeLabel = AppDelegate.networkTypeLabels[Int(tetherDevice.networkType)]
            let deviceName = tetherDevice.deviceName ?? String("No deviceName")
            
            if self.lastTetherDevice != tetherDevice {
                app.statusBarItem.button?.image = ImageManager.combinedStatusImage(batteryImage: batteryImage, cellImage: cellImage)
            }

            if self.showDeviceName {
                self.title = String(format: "%@ %@ ", deviceName, networkTypeLabel)
            } else {
                self.title = String(format: "%@ ", networkTypeLabel)
            }
            app.statusBarItem.button?.title = self.title
            
            self.lastTetherDevice = tetherDevice

        }
    }
    
    private func createMenu() {
        let statusBarMenu = NSMenu(title: "TetherInfo Menu")
        let item = NSMenuItem(title: "Show device name", action: #selector(AppDelegate.toggleShowDeviceName), keyEquivalent: "")
        item.state = NSControl.StateValue(rawValue:Int(UserDefaults.standard.integer(forKey: DefaultKeys.showDeviceKey))) //NSControl.StateValue.off
        self.showDeviceName = item.state == NSControl.StateValue.on
        statusBarMenu.addItem(item)
        statusBarMenu.addItem(NSMenuItem.separator())
        statusBarMenu.addItem(
            withTitle: "Exit",
            action: #selector(AppDelegate.exitAction),
            keyEquivalent: "")
        
        self.statusBarItem.menu = statusBarMenu
    }
    
    @objc func toggleShowDeviceName(item: NSMenuItem) {
        item.state = item.state == NSControl.StateValue.on ? NSControl.StateValue.off : NSControl.StateValue.on
        UserDefaults.standard.set(item.state.rawValue, forKey:DefaultKeys.showDeviceKey)
        self.showDeviceName = item.state == NSControl.StateValue.on
        self.updateStatus()
    }
    
    @objc func exitAction(item: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    public func powerStateDidChangeForWiFiInterface(withName interfaceName: String) {
        self.updateStatus()
    }
    
    public func ssidDidChangeForWiFiInterface(withName interfaceName: String) {
        self.updateStatus()
    }
    
    public func bssidDidChangeForWiFiInterface(withName interfaceName: String) {
        self.updateStatus()
    }
    
    public func modeDidChangeForWiFiInterface(withName interfaceName: String) {
        self.updateStatus()
    }
    
    public func linkQualityDidChangeForWiFiInterface(withName interfaceName: String, rssi: Int, transmitRate: Double) {
        self.updateStatus()
    }
    
    public func scanCacheUpdatedForWiFiInterface(withName interfaceName: String) {
        self.updateStatus()
    }
    
    @objc public func handleWifiNotification(notification: NSNotification) {
        self.updateStatus()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
    }
}

