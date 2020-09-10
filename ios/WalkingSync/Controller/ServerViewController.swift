//
//  ServerViewController.swift
//  WalkingSync
//
//  Created by Pasin Suriyentrakorn on 8/5/20.
//  Copyright © 2020 Pasin Suriyentrakorn. All rights reserved.
//

import UIKit
import CouchbaseLiteSwift

/// Controller for Server that runs Listener
class ServerViewController: ItemsViewController {
    
    @IBOutlet weak var startButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var headerView: UIView!
    
    @IBOutlet weak var qrCodeImageView: UIImageView!
    
    @IBOutlet weak var urlButton: UIButton!
    
    var connStatusTimer: Timer?
    var connStatus: URLEndpointListener.ConnectionStatus?
    
    override func viewDidLoad() {
        updateStartButtonItemTitle()
        
        updateURL()
        
        self.delegate = self
        super.viewDidLoad()
    }
    
    @IBAction func startAction(_ sender: Any) {
        if Listener.shared.isListening {
            Listener.shared.stop()
            triggerConnectonStatusTimer(start: false)
        } else {
            Listener.shared.start()
            triggerConnectonStatusTimer(start: true)
        }
        updateStartButtonItemTitle()
        updateURL()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showUrls" {
            let controller = segue.destination as! ServerUrlsViewController
            controller.delegate = self
            controller.urls = Listener.shared.urls
            controller.selectedURL = Listener.shared.selectedURL
        }
    }
    
    func updateStartButtonItemTitle() {
        startButtonItem.title = Listener.shared.isListening ? "Stop" : "Start"
    }
    
    func updateURL() {
        var selectedURL = Listener.shared.selectedURL
        if selectedURL == nil {
            if let urls = Listener.shared.urls {
                // Ignore .local address as it's an apple specific address:
                if urls.count > 1 && urls.first!.absoluteString.contains(".local:") {
                    selectedURL = urls[1]
                } else {
                    selectedURL = urls.first
                }
                Listener.shared.selectedURL = selectedURL
            }
        }
        
        if let url = selectedURL {
            urlButton.setTitle(url.absoluteString, for: .normal)
            let image = UIImage.qrCodeImageForString(url.absoluteString, size: qrCodeImageView.bounds.size)
            qrCodeImageView.image = image
        } else {
            urlButton.setTitle("No Server Running", for: .normal)
            qrCodeImageView.image = nil
        }
    }
    
    func triggerConnectonStatusTimer(start: Bool) {
        if (start) {
            if connStatusTimer != nil { return }
            
            connStatusTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true, block: { (t) in
                DispatchQueue.main.async {
                    self.connStatus = Listener.shared.status
                    self.tableView.reloadData()
                }
            })
        } else {
            if let timer = connStatusTimer {
                timer.invalidate()
                connStatusTimer = nil
            }
        }
    }
}

extension ServerViewController: ItemsViewControllerHeaderSectionDelegate {
    func titleForHeaderSection(tableView: UITableView) -> String {
        "Connections"
    }
    
    func cellForHeaderSectionRow(tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConnectionCell")!
        cell.textLabel?.text = "Active / Total Connections"
        var active: UInt64 = 0, total: UInt64 = 0
        if let status = connStatus {
            active = status.activeConnectionCount
            total = status.connectionCount
        }
        cell.detailTextLabel?.text = "\(active)/\(total)"
        cell.selectionStyle = .none
        return cell
    }
    
    func didSelectHeaderSectionRow(tableView: UITableView) { }
}

extension ServerViewController: ServerUrlsViewControllerDelegate {
    func didSelectURL(url: URL) {
        self.presentedViewController?.dismiss(animated: true, completion: {
            Listener.shared.selectedURL = url
            self.updateURL()
        })
    }
}
