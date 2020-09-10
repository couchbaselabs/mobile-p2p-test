//
//  HomeViewController.swift
//  WalkingSync
//
//  Created by Pasin Suriyentrakorn on 8/5/20.
//  Copyright © 2020 Pasin Suriyentrakorn. All rights reserved.
//

import UIKit
import CouchbaseLiteSwift

class HomeViewController: UIViewController {
    
    @IBOutlet weak var serverButton: UIButton!
    
    @IBOutlet weak var clientButton: UIButton!
    
    @IBOutlet weak var databaseButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Database.log.console.level = .verbose
    }

}
