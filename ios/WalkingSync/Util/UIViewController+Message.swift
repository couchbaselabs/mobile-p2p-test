//
//  UIViewController+Message.swift
//  WalkingSync
//
//  Created by Pasin Suriyentrakorn on 8/7/20.
//  Copyright © 2020 Pasin Suriyentrakorn. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func showMessage(_ message: String, title: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel) { (_) in })
        self.present(alert, animated: true, completion: nil)
    }
    
}
