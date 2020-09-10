//
//  ServerUrlsViewController.swift
//  WalkingSync
//
//  Created by Pasin Suriyentrakorn on 9/1/20.
//  Copyright © 2020 Pasin Suriyentrakorn. All rights reserved.
//

import UIKit

/// Delegate for selecting a URL
protocol ServerUrlsViewControllerDelegate {
    func didSelectURL(url: URL)
}

/// Controller for Server URLs
class ServerUrlsViewController: UITableViewController {
    
    var delegate: ServerUrlsViewControllerDelegate?
    
    var urls:[URL]?
    
    var selectedURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return urls?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UrlCell")!
        
        let urlStr = urls![indexPath.row].absoluteString;
        cell.textLabel?.text = urlStr
        
        if urlStr == selectedURL?.absoluteString {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let delegate = self.delegate {
            let url = urls![indexPath.row]
            delegate.didSelectURL(url: url)
        }
    }
    
}
