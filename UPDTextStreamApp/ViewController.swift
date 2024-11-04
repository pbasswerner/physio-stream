import UIKit
import Network
import HealthKit

class ViewController: UIViewController {
    
    // Touch area for 2D slider
    let touchAreaView = UIView()
    let xCoordLabel = UILabel()
    let yCoordLabel = UILabel()
    
    // UI for the text input
    let nameTextField = UITextField()
    let sendNameButton = UIButton(type: .system)
    
    // UI for Heart Rate Stream
    let hRLabelTextField = UITextField()
    let hRTextField = UITextField()
    
    // HealthKit variables
    let healthStore = HKHealthStore()
    var heartRateQuery: HKAnchoredObjectQuery?
    
    // Set up UDP connection
    var connection: NWConnection?
    let host = NWEndpoint.Host("169.254.156.194") // Replace with TouchDesigner computer's IP
    let port = NWEndpoint.Port(rawValue: 5000)! // Standard port, but can customize
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the UI
        setupUI()
        
        // Initialize UDP connection
        setupConnection()
        
        // Request access to health data
        requestHealthKitAccess()
    }
    
    func setupUI() {
        // Set up touch area
        touchAreaView.backgroundColor = .lightGray
        touchAreaView.layer.cornerRadius = 10
        touchAreaView.clipsToBounds = true
        
        // Coordinate labels
        xCoordLabel.text = "X: 0"
        yCoordLabel.text = "Y: 0"
        
        nameTextField.borderStyle = .roundedRect
        nameTextField.placeholder = "Enter text to send"
        
        sendNameButton.setTitle("Send", for: .normal)
        sendNameButton.addTarget(self, action: #selector(sendText), for: .touchUpInside)
        
        hRLabelTextField.text = "Heart Rate: "
        hRTextField.text = "0"
        
        view.addSubview(touchAreaView)
        view.addSubview(xCoordLabel)
        view.addSubview(yCoordLabel)
        view.addSubview(nameTextField)
        view.addSubview(sendNameButton)
        view.addSubview(hRLabelTextField)
        view.addSubview(hRTextField)
        
        // Layout code (using Auto Layout)
        touchAreaView.translatesAutoresizingMaskIntoConstraints = false
        xCoordLabel.translatesAutoresizingMaskIntoConstraints = false
        yCoordLabel.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        sendNameButton.translatesAutoresizingMaskIntoConstraints = false
        hRLabelTextField.translatesAutoresizingMaskIntoConstraints = false
        hRTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Constraints for touchAreaView (Square)
            touchAreaView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            touchAreaView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            touchAreaView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            touchAreaView.heightAnchor.constraint(equalTo: touchAreaView.widthAnchor),
            
            // Constraints for xCoordLabel
            xCoordLabel.topAnchor.constraint(equalTo: touchAreaView.bottomAnchor, constant: 10),
            xCoordLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -40),
            
            // Constraints for yCoordLabel
            yCoordLabel.topAnchor.constraint(equalTo: touchAreaView.bottomAnchor, constant: 10),
            yCoordLabel.leadingAnchor.constraint(equalTo: xCoordLabel.trailingAnchor, constant: 20),
            
            // Constraints for nameTextField
            nameTextField.topAnchor.constraint(equalTo: xCoordLabel.bottomAnchor, constant: 10),
            nameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameTextField.widthAnchor.constraint(equalToConstant: 200),
            
            // Constraints for sendNameButton
            sendNameButton.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 10),
            sendNameButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Constraints for hRLabelTextField
            hRLabelTextField.topAnchor.constraint(equalTo: sendNameButton.bottomAnchor, constant: 20),
            hRLabelTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -40),
            
            // Constraints for hRTextField
            hRTextField.leadingAnchor.constraint(equalTo: hRLabelTextField.trailingAnchor, constant: 8),
            hRTextField.centerYAnchor.constraint(equalTo: hRLabelTextField.centerYAnchor),
        ])
    }
    
    // Override touch handling for the touchAreaView
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: touchAreaView)
        
        // Ensure touch is within bounds
        if touchAreaView.bounds.contains(location) {
            xCoordLabel.text = "X: \(Int(location.x))"
            yCoordLabel.text = "Y: \(Int(location.y))"
        }
    }
    
    func setupConnection() {
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
    
    func requestHealthKitAccess() {
        // Request permission to access heart rate data
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        healthStore.requestAuthorization(toShare: [], read: [heartRateType]) { (success, error) in
            if success {
                self.startHeartRateQuery()
            } else if let error = error {
                print("HealthKit authorization error: \(error)")
            }
        }
    }
    
    func startHeartRateQuery() {
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
        guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
        
        for sample in heartRateSamples {
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
            sendHeartRateData(heartRate: heartRate)
        }
    }
    
    func sendHeartRateData(heartRate: Double) {
        let heartRateString = "HR " + String(heartRate)
        let data = heartRateString.data(using: .utf8)
        connection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Error sending data: \(error)")
            } else {
                print("Heart rate data sent: \(heartRateString)")
                DispatchQueue.main.async {
                    self.updateHRView(heartRate: String(heartRate))
                }
            }
        })
    }
    
    @objc func sendText() {
        guard let text = nameTextField.text else { return }
        let data = (text + "\n").data(using: .utf8)
        connection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Error sending data: \(error)")
            } else {
                print("Text sent: " + text)
            }
        })
    }
    
    @objc func updateHRView(heartRate: String) {
        self.hRTextField.text = heartRate
    }
}
