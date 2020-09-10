//
//  Settings.swift
//  WalkingSync
//
//  Created by Pasin Suriyentrakorn on 8/31/20.
//  Copyright © 2020 Pasin Suriyentrakorn. All rights reserved.
//

import UIKit

class Settings {
    private let deviceNameKey = "device_name"
    private let serverUseTLSKey = "server_use_tls"
    private let serverPortKey = "server_port"
    private let clientScanQRCodeKey = "client_scan_qrcode"
    
    var deviceName: String {
        get {
            return getValue(key: deviceNameKey, defaultValue: UIDevice.current.name)
        }
        set(value) {
            let v = value.trimmingCharacters(in: CharacterSet.whitespaces)
            setValue(v.count > 0 ? v : UIDevice.current.name, key: deviceNameKey)
        }
    }
    
    var serverUseTLS: Bool {
        get {
            return getValue(key: serverUseTLSKey, defaultValue: true)
        }
        set(value) {
            setValue(value, key: serverUseTLSKey)
        }
    }
    
    var serverPort: UInt16 {
        get {
            return getValue(key: serverPortKey, defaultValue: UInt16(0))
        }
        set(value) {
            setValue(value, key: serverPortKey)
        }
    }
    
    var clientScanQRCode: Bool {
        get {
            return getValue(key: clientScanQRCodeKey, defaultValue: true)
        }
        set(value) {
            setValue(value, key: clientScanQRCodeKey)
        }
    }
    
    func setValue<T: Any>(_ value: T, key: String) {
        let defaults = UserDefaults.standard
        defaults.set(value, forKey: key)
        defaults.synchronize()
    }
    
    func getValue<T: Any>(key: String, defaultValue: Any) -> T {
        let defaults = UserDefaults.standard
        if let value = defaults.value(forKey: key) {
            return value as! T
        } else {
            setValue(defaultValue, key: key)
            return defaultValue as! T
        }
    }
    
    private static func genId() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<4).map{ _ in letters.randomElement()! })
    }
}
