//
//  DatabaseViewController.swift
//  WalkingSync
//
//  Created by Pasin Suriyentrakorn on 8/7/20.
//  Copyright © 2020 Pasin Suriyentrakorn. All rights reserved.
//

import UIKit

class DatabaseViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var items: [String] = []
    var itemTotals: [String: Int] = [:]
    var itemDeviceCounts: [String: [ItemDeviceCount]] = [:]
    var itemDeviceCountsQueryToken: QueryToken?
    
    override func viewDidLoad() {
        itemDeviceCountsQueryToken = DB.shared.getItemDeviceCounts(listener: { (counts) in
            var items: [String] = []
            var totals: [String: Int] = [:]
            var itemDeviceCounts: [String: [ItemDeviceCount]] = [:]
            for c in counts {
                if !items.contains(c.name) {
                    items.append(c.name)
                }
                totals[c.name] = (totals[c.name] ?? 0) + c.total
                
                var deviceCounts = itemDeviceCounts[c.name] ?? []
                deviceCounts.append(c)
                itemDeviceCounts[c.name] = deviceCounts
            }
            
            DispatchQueue.main.async {
                self.items = items
                self.itemTotals = totals
                self.itemDeviceCounts = itemDeviceCounts
                self.tableView.reloadData()
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let token = itemDeviceCountsQueryToken {
            token.remove()
        }
        DB.shared.resetItemsQuery()
        super.viewWillDisappear(animated)
    }
    
    @IBAction func resetAction(_ sender: Any) {
        Listener.shared.stop()
        Sync.shared.stop()
        DB.shared.reset()
    }
    
}

extension DatabaseViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let name = items[section]
        let total = itemTotals[name] ?? 0
        return "\(name) (\(total))"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let name = items[section]
        return itemDeviceCounts[name]!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell")!
        
        let name = items[indexPath.section]
        let count = itemDeviceCounts[name]![indexPath.row]
        
        if Device.settings.deviceName == count.deviceName {
            cell.textLabel?.text = "\(count.deviceName) (*)"
        } else {
            cell.textLabel?.text = count.deviceName
        }
        cell.detailTextLabel?.text = "\(count.total)"
        
        return cell
    }
    
}
