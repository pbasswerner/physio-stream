import UIKit
import Network
import HealthKit

class ViewController: UIViewController, ConnectViewDelegate {
    
    let connectView = ConnectView()
    
    let healthManager = HealthManager()
    
    // HealthKit variables
    let healthStore = HKHealthStore()
    var heartRateQuery: HKAnchoredObjectQuery?
    
    // Set up UDP connection
    var connection: NWConnection?
    let hostString = "10.110.209.218"
    let portValue = 5000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(connectView)
        connectView.delegate = self
        
        // Set constraints for connect view
        connectView.translatesAutoresizingMaskIntoConstraints = false
           NSLayoutConstraint.activate([
            connectView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            connectView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            connectView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            connectView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
           ])
        

        // Initialize UDP connection
        //setupConnection(hostString: self.hostString, portValue: self.portValue)
        
        
        // Request access to health data
        healthManager.requestHealthKitAccess()
        
    }
    

    
    func setupConnection(hostString: String, portValue: Int) {
        let host = NWEndpoint.Host(hostString) //
        let port = NWEndpoint.Port(rawValue: UInt16(portValue))! //
        
        connection = NWConnection(host: host, port: port, using: .udp)
        connection?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Ready to send data")
                
            case .failed(let error):
                print("Failed with error: \(error)")
            default:
                break
            }
        }
        connection?.start(queue: .global())
        
    }

 
    
    func startHeartRateQuery() {
        print("health query started")
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { (query, samples, deletedObjects, anchor, error) in
            self.processHeartRateSamples(samples)
        }
        
        query.updateHandler = { (query, samples, deletedObjects, anchor, error) in
            self.processHeartRateSamples(samples)
        }
        
        healthStore.execute(query)
        heartRateQuery = query
    }
    
    


    func processHeartRateSamples(_ samples: [HKSample]?) {
        print("process heart rate called")
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
        
        for sample in heartRateSamples {
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
            let timestamp = sample.startDate
           
            print("HR: \(heartRate) at \(timestamp)")
            sendHeartRateData(heartRate: heartRate, timestamp: timestamp, user: "user")
        }
    }

    
    func sendHeartRateData(heartRate: Double, timestamp: Date, user:String) {
        print("send heart rate called")
        let heartRateString = user + " " + timestamp.description + " HR " + String(heartRate)
        let data = heartRateString.data(using: .utf8)
    
        connection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Error sending data: \(error)")
            } else {
                print("\(heartRateString)")
            }
        })
    }
    
    @objc func sendInitials(text : String) {
        let data = (text + "\n").data(using: .utf8)
        connection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Error sending data: \(error)")
            } else {
                print("Text sent: " + text)
            }
        })
    }
    func onUserClickedConnect(initials: String, ipAddress: String, port: Int) {
        setupConnection(hostString: self.hostString, portValue: self.portValue)
        sendInitials(text: initials)
    }
    
    func startCollection() {
        print("start collection called")
        //get timestamp of this method called
        startHeartRateQuery()
    }

}
