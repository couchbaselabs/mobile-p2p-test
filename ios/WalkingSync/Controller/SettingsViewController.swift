//
//  SettingsViewController.swift
//  WalkingSync
//
//  Created by Pasin Suriyentrakorn on 8/31/20.
//  Copyright © 2020 Pasin Suriyentrakorn. All rights reserved.
//

import UIKit

/// Controller for Settings
class SettingsViewController: UITableViewController {
    
    @IBOutlet weak var deviceName: UITextField!
    
    @IBOutlet weak var useTLS: UISwitch!
    
    @IBOutlet weak var port: UITextField!
    
    @IBOutlet weak var scanQRCode: UISwitch!
    
    override func viewDidLoad() {
        let settings = Device.settings
        deviceName.text = settings.deviceName
        useTLS.isOn = settings.serverUseTLS
        port.text = settings.serverPort > 0 ? "\(settings.serverPort)" : nil
        scanQRCode.isOn = settings.clientScanQRCode
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let settings = Device.settings
        settings.deviceName = deviceName.text!
        settings.serverUseTLS = useTLS.isOn
        settings.serverPort = UInt16(port.text!) ?? 0
        settings.clientScanQRCode = scanQRCode.isOn
    }
    
}
