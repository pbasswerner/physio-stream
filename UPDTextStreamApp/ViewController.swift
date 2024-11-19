import UIKit
import Network
import HealthKit

import UIKit
import Network

class ViewController: UIViewController, ConnectViewDelegate {
    
    let connectView = ConnectView()
    
    var userInitials = "DI" //default initials -> DI
    
    // Thread-safe serial queue
    private let udpQueue = DispatchQueue(label: "com.example.udp")
    private var _connection: NWConnection? // Private storage for connection
    private var connection: NWConnection?  // Thread-safe accessor
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(connectView)
        connectView.delegate = self
        
        connectView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            connectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            connectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            connectView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            connectView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    func setupConnection(hostString: String, portValue: Int) {
        let host = NWEndpoint.Host(hostString)
        let port = NWEndpoint.Port(rawValue: UInt16(portValue))!
        
        udpQueue.async { [weak self] in
            guard let self = self else { return }
            
            let newConnection = NWConnection(host: host, port: port, using: .udp)
            newConnection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("Ready to send data")
                case .failed(let error):
                    print("Failed with error: \(error)")
                    self.cleanupConnection()
                default:
                    break
                }
            }
            newConnection.start(queue: self.udpQueue)
            self.connection = newConnection
        }
    }

    @objc func sendInitials(text: String) {
        let data = (text + "\n").data(using: .utf8)
        
        udpQueue.async { [weak self] in
            guard let self = self, let connection = self.connection else { return }
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    print("Error sending data: \(error)")
                } else {
                    print("Text sent: \(text)")
                }
            })
        }
    }
    
    func onUserClickedConnect(initials: String, ipAddress: String, port: Int) {
        print(ipAddress)
        print(port)
        print(initials)
        setupConnection(hostString: ipAddress, portValue: port)
        userInitials = initials
        sendInitials(text: initials)
    }
    
    func sendAppraisal(emotionalIntensity: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .long)
        
        let message = "User: \(userInitials) EI: \(emotionalIntensity) Timestamp: \(timestamp)\n"
        let data = message.data(using: .utf8)
        
        // Save locally
        let entry = AppraisalEntry(userInitials: userInitials, emotionalIntensity: emotionalIntensity, timestamp: timestamp)
        DataManager.shared.saveAppraisal(entry)
        
        // Send data via the UDP connection
        udpQueue.async { [weak self] in
            guard let self = self, let connection = self.connection else { return }
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    print("Error sending data: \(error)")
                } else {
                    print("Sent: \(message)")
                }
            })
        }
    }

    
    func startCollection() {
        print("start collection called")
        let savedEntries = DataManager.shared.getAppraisals()
        print(savedEntries)
    }

    private func cleanupConnection() {
        udpQueue.async { [weak self] in
            guard let self = self else { return }
            self.connection?.cancel()
            self.connection = nil
        }
    }
    
    func uploadSavedAppraisals() {
        let savedEntries = DataManager.shared.getAppraisals()
        
        for entry in savedEntries {
            let message = "User: \(entry.userInitials) EI: \(entry.emotionalIntensity) Timestamp: \(entry.timestamp)\n"
            let data = message.data(using: .utf8)
            
            udpQueue.async { [weak self] in
                guard let self = self, let connection = self.connection else { return }
                connection.send(content: data, completion: .contentProcessed { error in
                    if let error = error {
                        print("Error sending data: \(error)")
                    } else {
                        print("Uploaded: \(message)")
                    }
                })
            }
        }
        
        // Clear saved entries after uploading
        DataManager.shared.clearAppraisals()
    }
}


//class ViewController: UIViewController, ConnectViewDelegate {
//    
//    let connectView = ConnectView()
//    
//    let healthManager = HealthManager()
//    
//    // HealthKit variables
//    let healthStore = HKHealthStore()
//    var heartRateQuery: HKAnchoredObjectQuery?
//    
//    //thread safe serial queue
//    private let udpQueue = DispatchQueue(label: "com.example.udp")
//    // Set up UDP connection
//    var connection: NWConnection?
//    //run command ifconfig | grep 'inet ' | awk '{print $2}' and change the host string on touch designer/python server to the second address
//    // update the host string below accordingly 
//    let hostString = "169.254.251.55"
//    let portValue = 5000
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        view.addSubview(connectView)
//        connectView.delegate = self
//        
//        // Set constraints for connect view
//        connectView.translatesAutoresizingMaskIntoConstraints = false
//           NSLayoutConstraint.activate([
//            connectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            connectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            connectView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            connectView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
//           ])
//
//        
//        // Request access to health data
//        //healthManager.requestHealthKitAccess()
//        
//    }
//    
//
//    
////    func setupConnection(hostString: String, portValue: Int) {
////        let host = NWEndpoint.Host(hostString) //
////        let port = NWEndpoint.Port(rawValue: UInt16(portValue))! //
////        
////        connection = NWConnection(host: host, port: port, using: .udp)
////        connection?.stateUpdateHandler = { state in
////            switch state {
////            case .ready:
////                print("Ready to send data")
////                
////            case .failed(let error):
////                print("Failed with error: \(error)")
////            default:
////                break
////            }
////        }
////        connection?.start(queue: .global())
////        
////    }
//    
//    func setupConnection(hostString: String, portValue: Int) {
//         let host = NWEndpoint.Host(hostString)
//         let port = NWEndpoint.Port(rawValue: UInt16(portValue))!
//         
//         udpQueue.async { [weak self] in
//             self?.connection = NWConnection(host: host, port: port, using: .udp)
//             self?.connection?.stateUpdateHandler = { state in
//                 switch state {
//                 case .ready:
//                     print("Ready to send data")
//                 case .failed(let error):
//                     print("Failed with error: \(error)")
//                 default:
//                     break
//                 }
//             }
//             self?.connection?.start(queue: self?.udpQueue ?? DispatchQueue.global())
//         }
//     }
//
// 
//    
////    func startHeartRateQuery() {
////        print("health query started")
////        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
////        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in
////            self.processHeartRateSamples(samples)
////        }
////        
////        query.updateHandler = { (query, samples, deletedObjects, anchor, error) in
////            print("update handler")
////            self.processHeartRateSamples(samples)
////        }
////        
////        healthStore.execute(query)
////        heartRateQuery = query
////    }
//    
//    
//
////
////    func processHeartRateSamples(_ samples: [HKSample]?) {
////        print("process heart rate called")
////        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
////        
////        for sample in heartRateSamples {
////            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
////            let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
////            let timestamp = sample.startDate
////           
////            print("HR: \(heartRate) at \(timestamp)")
////            sendHeartRateData(heartRate: heartRate, timestamp: timestamp, user: "user")
////        }
////    }
//
//    
////    func sendHeartRateData(heartRate: Double, timestamp: Date, user:String) {
////        print("send heart rate called")
////        let heartRateString = user + " " + timestamp.description + " HR " + String(heartRate)
////        let data = heartRateString.data(using: .utf8)
////    
////        connection?.send(content: data, completion: .contentProcessed { error in
////            if let error = error {
////                print("Error sending data: \(error)")
////            } else {
////                print("\(heartRateString)")
////            }
////        })
////    }
//    
//    @objc func sendInitials(text : String) {
//        let data = (text + "\n").data(using: .utf8)
//        connection?.send(content: data, completion: .contentProcessed { error in
//            if let error = error {
//                print("Error sending data: \(error)")
//            } else {
//                print("Text sent: " + text)
//            }
//        })
//    }
//    func onUserClickedConnect(initials: String, ipAddress: String, port: Int) {
//        setupConnection(hostString: self.hostString, portValue: self.portValue)
//        sendInitials(text: initials)
//    }
//    
//    func startCollection() {
//        print("start collection called")
//        //get timestamp of this method called
//        //startHeartRateQuery()
//    }
//
//    private func cleanupConnection() {
//        udpQueue.async { [weak self] in
//            self?.connection?.cancel()
//            self?.connection = nil
//        }
//    }
//}
