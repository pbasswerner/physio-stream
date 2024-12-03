import UIKit
import Network
import HealthKit

import UIKit
import Network

class ViewController: UIViewController, ConnectViewDelegate {

    private var dispatchTimer: DispatchSourceTimer?
    let connectView = ConnectView()
    var emotionalIntensity:Float = -1.0
    
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
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        
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
    
    func updateAppraisal(emotionalIntensity: Float) {
        self.emotionalIntensity = emotionalIntensity
    }

    
    func startCollection() {
        print("start collection called")
        onStartStreaming()
        
    }
    
    func stopCollection() {
        print("Stop collection called")
        onStopStreaming()
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
        //DataManager.shared.clearAppraisals()
    }
    func onIntervalStreamIntensity() {
        // Cancel any existing timer
            dispatchTimer?.cancel()
            
            // Create a new DispatchSourceTimer
            dispatchTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .background))
            dispatchTimer?.schedule(deadline: .now(), repeating: 0.1) // Interval in seconds (e.g., 0.1 seconds)
            dispatchTimer?.setEventHandler { [weak self] in
                guard let self = self else { return }
                
                let sliderValue = self.emotionalIntensity
                let intensity = String(format: "%.2f", sliderValue)
                
                // Call the sendAppraisal method with the slider's current value
                self.sendAppraisal(emotionalIntensity: intensity)
            }
            dispatchTimer?.resume()
       }
    
    func onStartStreaming() {
          // Called when the toggle is enabled
          onIntervalStreamIntensity()
      }

      func onStopStreaming() {
          // Stop and cancel the timer
              dispatchTimer?.cancel()
              dispatchTimer = nil      }

}

