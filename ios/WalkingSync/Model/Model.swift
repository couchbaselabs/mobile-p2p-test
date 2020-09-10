//
//  Model.swift
//  WalkingSync
//
//  Created by Pasin Suriyentrakorn on 8/5/20.
//  Copyright © 2020 Pasin Suriyentrakorn. All rights reserved.
//

import Foundation
import CouchbaseLiteSwift

class Device {
    static let settings = Settings()
}

class Data {
    static let items: [[String: Any]] = [
        ["name": "Apple"],
        ["name": "Banana"],
        ["name": "Orange"]
    ]
}

class DB {
    static let shared = DB()
    
    var database: Database
    
    var query: Query?
    
    let queryQueue = DispatchQueue(label: "QueryQueue")
    
    private init() {
        database = try! Database.init(name: "db")
    }
    
    func reset() {
        try! database.delete()
        database = try! Database.init(name: "db")
        query = nil
    }
    
    func itemsQuery() -> Query {
        if query == nil {
            query = QueryBuilder
            .select(SelectResult.property("name"),
                    SelectResult.property("deviceName"),
                    SelectResult.expression(Function.count(Expression.int(1))))
            .from(DataSource.database(database))
            .groupBy(Expression.property("name"), Expression.property("deviceName"))
            .orderBy(Ordering.property("name"), Ordering.property("deviceName"))
        }
        return query!
    }
    
    // Workaround to the issue that the second listener doesn't get the query result
    // after adding the listener.
    func resetItemsQuery() {
        query = nil
    }
    
    func addItem(name: String) {
        let doc = MutableDocument()
        doc.setString(name, forKey: "name")
        doc.setString(Device.settings.deviceName, forKey: "deviceName")
        try! database.saveDocument(doc)
    }
    
    func getItemCounts(listener: @escaping ([String: ItemCount]) -> Void) -> QueryToken? {
        let query = itemsQuery()
        let token = query.addChangeListener(withQueue: queryQueue) { (change) in
            var counts : [String: ItemCount] = [:]
            if let results = change.results {
                for r in results {
                    let name = r.string(at: 0)!
                    let deviceid = r.string(at: 1)!
                    let count = r.int(at: 2)
                    
                    var itemCount = counts[name] ?? ItemCount(name: name)
                    if deviceid == Device.settings.deviceName {
                        itemCount.mine = count
                    }
                    itemCount.total = itemCount.total + count
                    counts[name] = itemCount
                }
            }
            listener(counts)
        }
        return QueryToken(query: query, token: token)
    }
    
    func getItemDeviceCounts(listener: @escaping ([ItemDeviceCount]) -> Void) -> QueryToken? {
        let query = itemsQuery()
        let token = query.addChangeListener(withQueue: queryQueue) { (change) in
            var counts : [ItemDeviceCount] = []
            if let results = change.results {
                for r in results {
                    let name = r.string(at: 0)!
                    let deviceid = r.string(at: 1)!
                    let total = r.int(at: 2)
                    counts.append(ItemDeviceCount(name: name, deviceName: deviceid, total: total))
                }
            }
            listener(counts)
        }
        return QueryToken(query: query, token: token)
    }
}

class Listener {
    static let shared = Listener()
    
    var listener: URLEndpointListener?
    
    var urls: [URL]? {
        return listener?.urls
    }
    
    var selectedURL: URL?
    
    var isListening: Bool {
        return listener?.port != nil
    }
    
    var status: URLEndpointListener.ConnectionStatus? {
        return listener?.status
    }
    
    func start() {
        stop()
        
        let config = URLEndpointListenerConfiguration.init(database: DB.shared.database)
        config.disableTLS = !Device.settings.serverUseTLS
        config.port = Device.settings.serverPort
        listener = URLEndpointListener.init(config: config)
        try! listener!.start()
    }
    
    func stop() {
        if let listener = self.listener {
            listener.stop()
            selectedURL = nil
        }
    }
}


class Sync {
    static let shared = Sync()
    
    private var replicator: Replicator?
    
    private let maxHistory = 500
    
    private var changeToken: ListenerToken?
    
    var replicatorChanges: [ReplicatorChangeRecord] = []
    
    var status: Replicator.Status? {
        return replicator?.status
    }
    
    var url: URL? {
        if let r = replicator {
            return (r.config.target as! URLEndpoint).url
        }
        return nil
    }
    
    private init() { }
    
    func start(withURL url: URL) {
        stop()
        
        if let r = replicator, let token = changeToken {
            r.removeChangeListener(withToken: token)
            changeToken = nil
        }
        replicatorChanges.removeAll()
        
        let db = DB.shared.database
        let target = URLEndpoint.init(url: url)
        let config = ReplicatorConfiguration.init(database: db, target: target)
        config.continuous = true
        config.acceptOnlySelfSignedServerCertificate = true
        replicator = Replicator.init(config: config)
        changeToken = replicator?.addChangeListener({ (change) in
            self.addChangeHistory(change: change)
        })
        replicator!.start()
    }
    
    func stop() {
        if let r = replicator { r.stop() }
    }
    
    func addChangeListener(listener: @escaping (ReplicatorChange) -> Void) -> ListenerToken? {
        if let r = replicator {
            return r.addChangeListener(listener)
        }
        return nil
    }
    
    func removeChangeListener(token: ListenerToken) {
        if let r = replicator {
            r.removeChangeListener(withToken: token)
        }
    }
    
    func addChangeHistory(change: ReplicatorChange) {
        if (replicatorChanges.count > maxHistory) {
            replicatorChanges.removeFirst()
        }
        replicatorChanges.append(ReplicatorChangeRecord(change: change, timestamp: Date()))
    }
}

struct ItemCount {
    let name: String
    var mine = 0
    var total = 0
}

struct ItemDeviceCount {
    let name: String
    let deviceName: String
    var total = 0
}

struct QueryToken {
    let query: Query
    let token: ListenerToken
    func remove() {
        query.removeChangeListener(withToken: token)
    }
}

struct ReplicatorChangeRecord {
    let change: ReplicatorChange
    let timestamp: Date
}
