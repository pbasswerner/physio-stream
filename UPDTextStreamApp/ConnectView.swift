import UIKit

protocol ConnectViewDelegate: AnyObject{
    func onUserClickedConnect(initials: String, ipAddress: String, port: Int)
    func startCollection()
    func sendAppraisal(emotionalIntensity: String)

}


class ConnectView: UIView, UITextFieldDelegate {

    private var lastSentValue: Int = -1
    weak var delegate: ConnectViewDelegate?
    private var debounceWorkItem: DispatchWorkItem?
    
    private let defaultInitials = "DI"
    private let defaultIPAddress = "169.254.92.166"
    private let defaultPort = "5000"
    
    // Define UI components
    let nameTextField = UITextField()
    let connectButton = UIButton(type: .system)
    let portLabel = UILabel()
    let portInputView = UITextField()
    let ipLabel = UILabel()
    let ipInputView = UITextField()
    let collectDataLabel = UILabel()
    let collectDataSwitch = UISwitch()
    let intensitySlider = UISlider()
    let intensityLabel = UILabel()
    
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
        
        // Configure intensity slider
        intensitySlider.minimumValue = 0
        intensitySlider.maximumValue = 5
        intensitySlider.value = 0
        intensitySlider.isContinuous = true
        intensitySlider.addTarget(self, action: #selector(onSliderValueChanged(_:)), for: .valueChanged)
        
        // Configure intensity label
        intensityLabel.text = "Emotional Intensity: 0"
        intensityLabel.textAlignment = .center
        
        // Add subviews
        addSubview(nameTextField)
        addSubview(ipLabel)
        addSubview(ipInputView)
        addSubview(portLabel)
        addSubview(portInputView)
        addSubview(connectButton)
        addSubview(collectDataLabel)
        addSubview(collectDataSwitch)
        addSubview(intensitySlider)
        addSubview(intensityLabel)
        
        // Set constraints
        setupConstraints()
        
        // Disable inputs for debugging
        nameTextField.isEnabled = true
        ipInputView.isEnabled = true
        portInputView.isEnabled = true
        
        // Enable/disable toggle
        enableDisableToggle(shouldEnable: false)
    }
    
    private func setupConstraints() {
        [nameTextField, ipLabel, ipInputView, portLabel, portInputView, connectButton, collectDataLabel, collectDataSwitch, intensitySlider, intensityLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            ipLabel.topAnchor.constraint(equalTo: topAnchor, constant: 60),
            ipLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            
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
            
            intensitySlider.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 20),
            intensitySlider.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            intensitySlider.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            intensityLabel.topAnchor.constraint(equalTo: intensitySlider.bottomAnchor, constant: 10),
            intensityLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            collectDataLabel.topAnchor.constraint(equalTo: intensityLabel.bottomAnchor, constant: 20),
            collectDataLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            
            collectDataSwitch.centerYAnchor.constraint(equalTo: collectDataLabel.centerYAnchor),
            collectDataSwitch.leadingAnchor.constraint(equalTo: collectDataLabel.trailingAnchor, constant: 20)
        ])
    }

    @objc func onUserClickedConnect() {
        
        
        let initials = nameTextField.text?.isEmpty == false ? nameTextField.text! : defaultInitials
        let ipAddress = ipInputView.text?.isEmpty == false ? ipInputView.text! : defaultIPAddress
        let port = portInputView.text?.isEmpty == false ? portInputView.text! : defaultPort

        delegate?.onUserClickedConnect(initials: initials, ipAddress: ipAddress, port: Int(port)! )
        collectDataSwitch.isEnabled = true
    }
    
    @objc func onSliderValueChanged(_ slider: UISlider) {
        let stepValue = Int(round(slider.value))
        slider.value = Float(stepValue) // Snap slider to steps
        intensityLabel.text = "Emotional Intensity: \(stepValue)"
        
        // Only send if the value has changed
        if stepValue != lastSentValue {
            lastSentValue = stepValue
            delegate?.sendAppraisal(emotionalIntensity: String(stepValue))
        }
    }
    
    @objc func onStreamToggleChanged() {
        print("Toggle changed: \(collectDataSwitch.isOn)")
        if collectDataSwitch.isOn {
            enableDisableSlider(shouldEnable: true)
            delegate?.startCollection()
        } else {
            enableDisableSlider(shouldEnable: false)
        }
    }
    
    func enableDisableToggle(shouldEnable: Bool) {
        collectDataSwitch.isEnabled = shouldEnable
    }
    
    func enableDisableSlider(shouldEnable: Bool) {
        intensitySlider.isEnabled = shouldEnable
    }
}


