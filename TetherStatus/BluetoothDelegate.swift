//
//  BluetoothDelegate.swift
//  TetherStatus
//
//  Created by Mark Knowles on 15/5/20.
//  Copyright © 2020 Mark Knowles. All rights reserved.
//

import Foundation
import CoreBluetooth
import CoreLocation




class WasPartOfMainApp : NSObject, CBCentralManagerDelegate, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager?
    private var bluetoothManager: CBCentralManager?
    
    func main() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            NSLog("Core location authorized")
            //self.initBluetooth()
            // locations services are on
        case .notDetermined:
            NSLog("Location entitlement not enabled, asking")
            self.locationManager = CLLocationManager()
            guard let lm = self.locationManager else {
                break
            }
            lm.delegate = self
            lm.requestAlwaysAuthorization()
            // still need to request access
        case .restricted, .denied:
            NSLog("Core location not authorized")
            // locations services off or denied
        @unknown default:
            NSLog("WTF: unknown value for CLLocationManager.authorizationStatus")
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        NSLog("central manager update")
        
        switch central.state {
          case .unknown:
            print("central.state is .unknown")
          case .resetting:
            print("central.state is .resetting")
          case .unsupported:
            print("central.state is .unsupported")
          case .unauthorized:
            print("central.state is .unauthorized")
          case .poweredOff:
            print("central.state is .poweredOff")
          case .poweredOn:
            print("central.state is .poweredOn")
            //central.retrieveConnectedPeripherals(withServices: [CBService.])
            central.scanForPeripherals(withServices: nil)
            //central.retrieveConnectedPeripherals(withServices: nil)
        @unknown default:
            NSLog("WTF: Unknown CBCentralManager.state")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        NSLog(String(describing:peripheral.name))
        NSLog(String(describing:advertisementData["kCBAdvDataLocalName"]))
        
        guard let services = peripheral.services else {
            return
        }
        for service in services {
            NSLog(String(describing:peripheral))
            NSLog(String(describing:service))
        }

        /*if peripheral.name != nil {
            NSLog(String(describing:peripheral))
        }*/
        //NSLog(String(describing:peripheral))
        //NSLog(String(describing:advertisementData))
        NSLog(String(describing:advertisementData["kCBAdvDataLocalName"]))
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("didConnect")
        
    }
    
    internal func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        NSLog("Changed location authorization status")
        if status == .authorizedAlways {
            self.initBluetooth()
        }
    }
    
    private func initBluetooth() {
        NSLog("Init bluetooth")
        if self.bluetoothManager == nil {
            let opts = [CBCentralManagerOptionShowPowerAlertKey: true]
            self.bluetoothManager = CBCentralManager(delegate: self, queue: nil, options: opts)
            //self.bluetoothDelegate = BluetoothDelegate()
            //self.bluetoothManager?.delegate = self.bluetoothDelegate
        }
    }
}
