//
//  ReplicatorChangesViewController.swift
//  WalkingSync
//
//  Created by Pasin Suriyentrakorn on 8/25/20.
//  Copyright © 2020 Pasin Suriyentrakorn. All rights reserved.
//

import UIKit
import CouchbaseLiteSwift

/// Controller for showing the history of the replicator change events
class ReplicatorChangesViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    let dateFormatter = DateFormatter()

    var changes: [ReplicatorChangeRecord] = []
    
    var replicatorToken: ListenerToken?
    
    override func viewDidLoad() {
        self.dateFormatter.dateFormat = "HH:mm:ss.SSS"
        
        replicatorToken = Sync.shared.addChangeListener { (change) in
            self.updateChanges()
        }
        
        updateChanges()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let token = replicatorToken {
            Sync.shared.removeChangeListener(token: token)
        }
        super.viewWillDisappear(animated)
    }
    
    func updateChanges() {
        changes = Sync.shared.replicatorChanges
        self.tableView.reloadData()
    }
    
    let kStatus = ["STOPPED", "OFFLINE", "CONNECTING", "IDLE", "BUSY"]
    
    func status(change: ReplicatorChange) -> String {
        let activity = change.status.activity
        let progress = change.status.progress
        let error = change.status.error
        
        let s = kStatus[Int(activity.rawValue)]
        let e = error != nil ? " (\(error!.localizedDescription))" : ""
        let p = "\(progress.completed) / \(progress.total)"
        return "\(s)\(e) \(p)"
    }
}

extension ReplicatorChangesViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
        
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return changes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let change = changes[changes.count - indexPath.row - 1]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReplicatorChangeCell")!
        cell.textLabel?.text = status(change: change.change)
        cell.detailTextLabel?.text = self.dateFormatter.string(from: change.timestamp)
        return cell
    }
}
