import UIKit

protocol ConnectViewDelegate: AnyObject{
    //func onUserClickedConnect(initials: String)
    func onUserClickedConnect(initials: String, ipAddress: String, port: Int)
    func startCollection()

}





class ConnectView: UIView, UITextFieldDelegate {

    weak var delegate: ConnectViewDelegate?
    
    private let defaultInitials = "Default Initials"
    private let defaultIPAddress = "10.110.209.218"
    private let defaultPort = "5000"
    
    // Define UI components
    let touchAreaView = UIView()
    let xCoordLabel = UILabel()
    let yCoordLabel = UILabel()
    let nameTextField = UITextField()
    let connectButton = UIButton(type: .system)
    let portLabel = UILabel()
    let portInputView = UITextField()
    let ipLabel = UILabel()
    let ipInputView = UITextField()
    let collectDataLabel = UILabel()
    let collectDataSwitch = UISwitch()
    
    // Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // Set up the UI components and layout
    private func setupUI() {
        
        ipLabel.text = "IP Address"
        ipInputView.borderStyle = .roundedRect
        ipInputView.placeholder = "IP"
        ipInputView.delegate = self
        
        portLabel.text = "Port"
        portInputView.borderStyle = .roundedRect
        portInputView.placeholder = "Port"
        portInputView.delegate = self
        
        nameTextField.borderStyle = .roundedRect
        nameTextField.placeholder = "Enter your initials"
        nameTextField.delegate = self
        
        connectButton.setTitle("Connect", for: .normal)
        connectButton.addTarget(self, action: #selector(onUserClickedConnect), for: .touchUpInside)
        
        collectDataLabel.text = "Collect Data"
        collectDataSwitch.addTarget(self, action: #selector(onStreamToggleChanged), for: .valueChanged)
        
        touchAreaView.backgroundColor = .clear
        touchAreaView.layer.cornerRadius = 10
        touchAreaView.clipsToBounds = true
        
        // Add pan gesture recognizer for touch tracking
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        touchAreaView.addGestureRecognizer(panGesture)

        // Create the quadrants
        let quadrantColors: [UIColor] = [.red, .yellow, .blue, .green]
        let quadrants: [UIView] = quadrantColors.map { color in
            let view = UIView()
            view.backgroundColor = color.withAlphaComponent(0.3)
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }
        
        quadrants.forEach { touchAreaView.addSubview($0) }

        // Configure other UI components
        xCoordLabel.text = "Valence: 0"
        yCoordLabel.text = "Arousal: 0"
        
        // TODO: add BMP HR view and label
        
      
        
        // Add subviews
        addSubview(touchAreaView)
        addSubview(xCoordLabel)
        addSubview(yCoordLabel)
        addSubview(nameTextField)
        addSubview(ipLabel)
        addSubview(ipInputView)
        addSubview(portLabel)
        addSubview(portInputView)
        addSubview(connectButton)

        addSubview(collectDataLabel)
        addSubview(collectDataSwitch)
        
        // Set constraints
        setupConstraints(quadrants: quadrants)
        
        // Disable inputs for debugging
        nameTextField.isEnabled = true
        ipInputView.isEnabled = true
        portInputView.isEnabled = true
        
        //Hide Toggle
        hideShowToggle(shouldHide: false)
        
        // Hide bottom views while not connected
        hideShowMoodQuadrant(shouldHide: true)
        
        //hide hr
        hideShowHRValues(shouldHide: true)
       

       
    }
    

    
    private func setupConstraints(quadrants: [UIView]) {
        [touchAreaView, xCoordLabel, yCoordLabel, nameTextField, ipLabel, ipInputView, portLabel, portInputView, connectButton, collectDataLabel, collectDataSwitch].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            ipLabel.topAnchor.constraint(equalTo: topAnchor, constant: 60),
            ipLabel.leadingAnchor.constraint(equalTo: nameTextField.leadingAnchor),

            
            ipInputView.centerYAnchor.constraint(equalTo: ipLabel.centerYAnchor),
            ipInputView.leadingAnchor.constraint(equalTo: ipLabel.trailingAnchor, constant: 20),
            ipInputView.widthAnchor.constraint(equalToConstant: 100),
            
            portLabel.topAnchor.constraint(equalTo: ipLabel.bottomAnchor, constant: 20),
            portLabel.leadingAnchor.constraint(equalTo: ipLabel.leadingAnchor),
            
            portInputView.centerYAnchor.constraint(equalTo: portLabel.centerYAnchor),
            portInputView.leadingAnchor.constraint(equalTo: portLabel.trailingAnchor, constant: 20),
            portInputView.widthAnchor.constraint(equalToConstant: 100),
            
            nameTextField.topAnchor.constraint(equalTo: portInputView.bottomAnchor, constant: 20),
            nameTextField.centerXAnchor.constraint(equalTo: centerXAnchor),
            nameTextField.widthAnchor.constraint(equalToConstant: 200),
        
            connectButton.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
            connectButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            
            // `touchAreaView` constraints (Square and Centered)
            touchAreaView.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 20),
            touchAreaView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            touchAreaView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            touchAreaView.heightAnchor.constraint(equalTo: touchAreaView.widthAnchor),
            
            // Quadrant constraints
            quadrants[0].topAnchor.constraint(equalTo: touchAreaView.topAnchor),
            quadrants[0].leadingAnchor.constraint(equalTo: touchAreaView.leadingAnchor),
            quadrants[0].trailingAnchor.constraint(equalTo: touchAreaView.centerXAnchor),
            quadrants[0].bottomAnchor.constraint(equalTo: touchAreaView.centerYAnchor),
            
            quadrants[1].topAnchor.constraint(equalTo: touchAreaView.topAnchor),
            quadrants[1].leadingAnchor.constraint(equalTo: touchAreaView.centerXAnchor),
            quadrants[1].trailingAnchor.constraint(equalTo: touchAreaView.trailingAnchor),
            quadrants[1].bottomAnchor.constraint(equalTo: touchAreaView.centerYAnchor),
            
            quadrants[2].topAnchor.constraint(equalTo: touchAreaView.centerYAnchor),
            quadrants[2].leadingAnchor.constraint(equalTo: touchAreaView.leadingAnchor),
            quadrants[2].trailingAnchor.constraint(equalTo: touchAreaView.centerXAnchor),
            quadrants[2].bottomAnchor.constraint(equalTo: touchAreaView.bottomAnchor),
            
            quadrants[3].topAnchor.constraint(equalTo: touchAreaView.centerYAnchor),
            quadrants[3].leadingAnchor.constraint(equalTo: touchAreaView.centerXAnchor),
            quadrants[3].trailingAnchor.constraint(equalTo: touchAreaView.trailingAnchor),
            quadrants[3].bottomAnchor.constraint(equalTo: touchAreaView.bottomAnchor),
            

            xCoordLabel.topAnchor.constraint(equalTo: touchAreaView.bottomAnchor, constant: 20),
            xCoordLabel.centerXAnchor.constraint(equalTo: touchAreaView.centerXAnchor, constant: -50),
               
            yCoordLabel.topAnchor.constraint(equalTo: xCoordLabel.topAnchor),
            yCoordLabel.leadingAnchor.constraint(equalTo: xCoordLabel.trailingAnchor, constant: 20),
               
            collectDataLabel.leadingAnchor.constraint(equalTo: xCoordLabel.leadingAnchor),
            collectDataLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50),
            
            collectDataSwitch.leadingAnchor.constraint(equalTo: collectDataLabel.trailingAnchor, constant: 20),
            collectDataSwitch.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -50)
            
            
        ])
    }

    // Handle pan gesture to update mood meter values
       @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
           let location = gesture.location(in: touchAreaView)
           
           // Calculate valence and arousal as values between -2 and +2
           let valence = ((location.x / touchAreaView.bounds.width) * 4) - 2
           let arousal = ((location.y / touchAreaView.bounds.height) * 4) - 2
           
           // Clamp values to ensure they stay within -2 to +2 range
           let clampedValence = max(-2, min(2, valence))
           let clampedArousal = max(-2, min(2, arousal))
           
           // Update labels with clamped values
           xCoordLabel.text = String(format: "Valence: %.2f", clampedValence)
           yCoordLabel.text = String(format: "Arousal: %.2f", clampedArousal)
       }
    
    @objc func onUserClickedConnect(){
        let initials = nameTextField.text ?? defaultInitials
        let ipAddress = ipInputView.text ?? defaultIPAddress
        let port = portInputView.text ?? defaultPort
        
        delegate?.onUserClickedConnect(initials: initials, ipAddress: ipAddress, port: Int(port) ?? 5000 )
        
        
        // Disable Connect button, ip address, ipPort
        // show toggle view at the bottom
        
     }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder() // Dismisses the keyboard
        return true
    }
    
    @objc func onStreamToggleChanged() {
        print("Toggle changed: \(collectDataSwitch.isOn)")
        if collectDataSwitch.isOn {
            hideShowMoodQuadrant(shouldHide: false)
            hideShowHRValues(shouldHide: false)
            //delegate?.startCollection()
        } else {
            hideShowMoodQuadrant(shouldHide: true)
            hideShowHRValues(shouldHide: true)
            //delegate?.stopCollection()
        }
    }
    
    func hideShowMoodQuadrant(shouldHide : Bool) {
        touchAreaView.isHidden = shouldHide
        xCoordLabel.isHidden = shouldHide
        yCoordLabel.isHidden = shouldHide
    }
    
    func hideShowToggle(shouldHide: Bool){
        
    }
    
    func hideShowHRValues(shouldHide: Bool) {
        
    }
    
    
    

}


