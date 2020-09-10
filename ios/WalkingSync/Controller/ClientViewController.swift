//
//  ClientViewController.swift
//  WalkingSync
//
//  Created by Pasin Suriyentrakorn on 8/7/20.
//  Copyright © 2020 Pasin Suriyentrakorn. All rights reserved.
//

import UIKit
import CouchbaseLiteSwift

/// Controller for Client that runs Replicator
class ClientViewController: ItemsViewController {

    @IBOutlet weak var connectButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var urlLabel: UILabel!
    
    var replicatorDidConnect = false
    
    var replicatorToken: ListenerToken?
    var replicationChange: ReplicatorChange?
    
    deinit {
        if let token = replicatorToken {
            Sync.shared.removeChangeListener(token: token)
        }
    }
    
    override func viewDidLoad() {
        updateConnectionButtonItem()
        updateEndpointURL()
        observeReplicationStatus()
        
        self.delegate = self
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "scan" {
            (segue.destination as! CameraViewController).delegate = self
        }
    }
    
    @IBAction func connectAction(_ sender: Any) {
        if replicatorDidConnect {
            stopReplicator()
        } else {
            if Device.settings.clientScanQRCode {
                #if targetEnvironment(simulator)
                    showRemoteURLInput()
                #else
                    performSegue(withIdentifier: "scan", sender: self)
                #endif
            } else {
                showRemoteURLInput()
            }
        }
    }
    
    func showRemoteURLInput() {
        let dialog = TextDialog()
        dialog.title = "Enter Remote URL"
        dialog.onOkAction = { url in
            if let url = URL(string: url) {
                self.startReplicator(url: url)
            }
        }
        dialog.show(controller: self)
    }
    
    func updateConnectionButtonItem() {
        if let status = Sync.shared.status, status.activity != .stopped {
            connectButtonItem.title = "Stop"
            replicatorDidConnect = true
        } else {
            connectButtonItem.title = "Connect"
            replicatorDidConnect = false
        }
    }
    
    func updateEndpointURL() {
        if let url = Sync.shared.url {
            urlLabel.text = url.absoluteString
        } else {
            urlLabel.text = "No Replicator Running"
        }
    }
    
    func startReplicator(url: URL) {
        Sync.shared.start(withURL: url)
        observeReplicationStatus()
    }
    
    func stopReplicator() {
        Sync.shared.stop()
    }
    
    func observeReplicationStatus() {
        replicatorToken = Sync.shared.addChangeListener { (change) in
            self.replicationChange = change
            self.updateConnectionButtonItem()
            self.updateEndpointURL()
            self.tableView.reloadRows(at: [IndexPath.init(row: 0, section: 0)], with: .none)
        }
    }
    
    let kStatus = ["STOPPED", "OFFLINE", "CONNECTING", "IDLE", "BUSY"]
    
    func getReplicatorStatus() -> (activity: String, progress: String) {
        var activity = Replicator.ActivityLevel.stopped
        var progress: Replicator.Progress? = nil
        var error: Error? = nil
        
        if let change = replicationChange {
            activity = change.status.activity
            progress = change.status.progress
            error = change.status.error
        } else if let status = Sync.shared.status {
            activity = status.activity
            progress = status.progress
            error = status.error
        }
        
        let s = kStatus[Int(activity.rawValue)]
        let e = error != nil ? " (\(error!.localizedDescription))" : ""
        let p = "\(progress?.completed ?? 0) / \(progress?.total ?? 0)"
        return (activity: "\(s)\(e)", progress: p)
    }
}

extension ClientViewController: ItemsViewControllerHeaderSectionDelegate {
    func titleForHeaderSection(tableView: UITableView) -> String {
        "Replication"
    }
    
    func cellForHeaderSectionRow(tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReplicatorStatusCell")!
        let status = getReplicatorStatus()
        cell.textLabel?.text = status.activity
        cell.detailTextLabel?.text = status.progress
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func didSelectHeaderSectionRow(tableView: UITableView) {
        self.performSegue(withIdentifier: "showReplicatorChanges", sender: self)
    }
}

extension ClientViewController: CameraViewControllerDelegate {
    func didScanRemoteEndpointURL(url: URL) {
        self.presentedViewController?.dismiss(animated: true, completion: {
            self.startReplicator(url: url)
        })
    }
}
