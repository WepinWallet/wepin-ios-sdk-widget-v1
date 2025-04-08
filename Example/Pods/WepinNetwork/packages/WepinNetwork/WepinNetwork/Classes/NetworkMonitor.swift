//
//  NetworkMonitor.swift
//  Pods
//
//  Created by iotrust on 3/17/25.
//

import Network

public class NetworkMonitor {
    public static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    public var isConnected: Bool = false
    
    private init() {
        monitor.pathUpdateHandler = { path in
            self.isConnected = path.status == .satisfied
            if self.isConnected {
                
            } else {
                
            }
        }
        monitor.start(queue: queue)
    }
}
