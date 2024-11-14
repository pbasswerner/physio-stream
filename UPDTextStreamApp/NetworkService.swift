//
//  NetworkService.swift
//  UPDTextStreamApp
//
//  Created by Paula Basswerner on 11/4/24.
//


import Network

class NetworkService  {
    private var connection: NWConnection?
    private let host: NWEndpoint.Host
    private let port: NWEndpoint.Port
    
    var onStateChange: ((NWConnection.State) -> Void)?
    
    init(host: String, port: UInt16) {
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(rawValue: port)!
    }
    
    func setupConnection() {
        connection = NWConnection(host: host, port: port, using: .udp)
        connection?.stateUpdateHandler = { [weak self] state in
            self?.onStateChange?(state)
        }
        connection?.start(queue: .global())
    }
    
//    func send(data: Data) {
//        connection?.send(content: data, completion: .contentProcessed { error in
//            if let error = error {
//                print("Error sending data: \(error)")
//            }
//        })
//    }
    
    func reconnect() {
        connection?.cancel()
        setupConnection()
    }
}
