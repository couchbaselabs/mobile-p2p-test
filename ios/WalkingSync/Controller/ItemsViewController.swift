//
//  ItemsViewController.swift
//  WalkingSync
//
//  Created by Pasin Suriyentrakorn on 9/1/20.
//  Copyright © 2020 Pasin Suriyentrakorn. All rights reserved.
//

import UIKit
import CouchbaseLiteSwift

/// Delegate for showing the header section of the table.
protocol ItemsViewControllerHeaderSectionDelegate {
    func titleForHeaderSection(tableView: UITableView) -> String
    func cellForHeaderSectionRow(tableView: UITableView) -> UITableViewCell
    func didSelectHeaderSectionRow(tableView: UITableView)
}

// Base controllers for showing and adding items.
// Subclassed by ServerViewController and ClientViewController
class ItemsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var delegate: ItemsViewControllerHeaderSectionDelegate?
    var itemCounts: [String: ItemCount] = [:]
    var itemCountsQueryToken: QueryToken?
    
    override func viewDidLoad() {
        getItemCounts()
        
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let index = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: index, animated: true)
        }
        
        getItemCounts()
        
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let token = itemCountsQueryToken {
            token.remove()
        }
        DB.shared.resetItemsQuery()
        itemCountsQueryToken = nil
        super.viewWillDisappear(animated)
    }
    
    // MARK: UITableView
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? delegate!.titleForHeaderSection(tableView: tableView) : "Items"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : Data.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return delegate!.cellForHeaderSectionRow(tableView: tableView)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell")!
            
            let name = Data.items[indexPath.row]["name"] as! String
            cell.textLabel?.text = name
            
            if let count = itemCounts[name] {
                if count.mine == count.total {
                    cell.detailTextLabel?.text = "\(count.mine)"
                } else {
                    cell.detailTextLabel?.text = "\(count.mine)/\(count.total)"
                }
            } else {
                cell.detailTextLabel?.text = "0"
            }
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            delegate!.didSelectHeaderSectionRow(tableView: tableView)
            return
        }
        
        let name = Data.items[indexPath.row]["name"] as! String
        addItem(name: name)
    }
    
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let name = Data.items[indexPath.row]["name"] as! String
        
        let add25 = UIContextualAction.init(style: .normal, title: "+25") { (action, view, completion) in
            self.addItem(name: name, number: 25)
            completion(true)
        }
        add25.backgroundColor = .blue
        
        let add50 = UIContextualAction.init(style: .normal, title: "+50") { (action, view, completion) in
            self.addItem(name: name, number: 50)
            completion(true)
        }
        add50.backgroundColor = .purple
        
        let add100 = UIContextualAction.init(style: .normal, title: "+100") { (action, view, completion) in
            self.addItem(name: name, number: 100)
            completion(true)
        }
        add100.backgroundColor = .orange
        
        let config = UISwipeActionsConfiguration(actions: [add25, add50, add100])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    // MARK: Utils
    
    func getItemCounts() {
        if itemCountsQueryToken == nil {
            itemCountsQueryToken = DB.shared.getItemCounts(listener: { (counts) in
                DispatchQueue.main.async {
                    self.itemCounts = counts
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    func addItem(name: String, number: UInt = 1) {
        DispatchQueue.global(qos: .userInitiated).async {
            DB.shared.addItem(name: name, number: number)
        }
    }
}
