import Cocoa

class SettingsViewController: NSViewController {
    private var apiBaseField: NSTextField?
    private var apiKeyField: NSSecureTextField?
    private var modelField: NSTextField?
    private var testButton: NSButton?
    private var statusLabel: NSTextField?
    private var llmRefiner: LLMRefiner?
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 200))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        llmRefiner = LLMRefiner()
        setupUI()
        loadSettings()
    }
    
    private func setupUI() {
        let padding: CGFloat = 20
        let rowHeight: CGFloat = 24
        let labelWidth: CGFloat = 100
        let fieldWidth: CGFloat = 340
        let spacing: CGFloat = 16
        
        var y = view.bounds.height - padding - rowHeight
        
        apiBaseField = createRow(label: "API Base URL", placeholder: "https://api.openai.com/v1", y: &y, labelWidth: labelWidth, fieldWidth: fieldWidth, rowHeight: rowHeight, spacing: spacing)
        apiKeyField = createSecureRow(label: "API Key", placeholder: "sk-...", y: &y, labelWidth: labelWidth, fieldWidth: fieldWidth, rowHeight: rowHeight, spacing: spacing)
        modelField = createRow(label: "Model", placeholder: "gpt-4o-mini", y: &y, labelWidth: labelWidth, fieldWidth: fieldWidth, rowHeight: rowHeight, spacing: spacing)
        
        y -= spacing
        
        let buttonY = y
        let testBtn = NSButton(frame: NSRect(x: padding + labelWidth, y: buttonY, width: 80, height: rowHeight))
        testBtn.title = "Test"
        testBtn.bezelStyle = .rounded
        testBtn.target = self
        testBtn.action = #selector(testConnection)
        view.addSubview(testBtn)
        testButton = testBtn
        
        let saveBtn = NSButton(frame: NSRect(x: padding + labelWidth + 90, y: buttonY, width: 80, height: rowHeight))
        saveBtn.title = "Save"
        saveBtn.bezelStyle = .rounded
        saveBtn.target = self
        saveBtn.action = #selector(saveSettings)
        view.addSubview(saveBtn)
        
        let status = NSTextField(frame: NSRect(x: padding + labelWidth + 180, y: buttonY, width: 200, height: rowHeight))
        status.isEditable = false
        status.isSelectable = false
        status.isBezeled = false
        status.drawsBackground = false
        status.font = NSFont.systemFont(ofSize: 12)
        status.textColor = NSColor.labelColor
        view.addSubview(status)
        statusLabel = status
    }
    
    private func createRow(label: String, placeholder: String, y: inout CGFloat, labelWidth: CGFloat, fieldWidth: CGFloat, rowHeight: CGFloat, spacing: CGFloat) -> NSTextField {
        let padding: CGFloat = 20
        
        let labelField = NSTextField(frame: NSRect(x: padding, y: y, width: labelWidth, height: rowHeight))
        labelField.stringValue = label
        labelField.isEditable = false
        labelField.isSelectable = false
        labelField.isBezeled = false
        labelField.drawsBackground = false
        labelField.font = NSFont.systemFont(ofSize: 13)
        labelField.alignment = .right
        view.addSubview(labelField)
        
        let field = NSTextField(frame: NSRect(x: padding + labelWidth + 10, y: y, width: fieldWidth, height: rowHeight))
        field.placeholderString = placeholder
        field.font = NSFont.systemFont(ofSize: 13)
        field.bezelStyle = .roundedBezel
        view.addSubview(field)
        
        y -= spacing
        return field
    }
    
    private func createSecureRow(label: String, placeholder: String, y: inout CGFloat, labelWidth: CGFloat, fieldWidth: CGFloat, rowHeight: CGFloat, spacing: CGFloat) -> NSSecureTextField {
        let padding: CGFloat = 20
        
        let labelField = NSTextField(frame: NSRect(x: padding, y: y, width: labelWidth, height: rowHeight))
        labelField.stringValue = label
        labelField.isEditable = false
        labelField.isSelectable = false
        labelField.isBezeled = false
        labelField.drawsBackground = false
        labelField.font = NSFont.systemFont(ofSize: 13)
        labelField.alignment = .right
        view.addSubview(labelField)
        
        let field = NSSecureTextField(frame: NSRect(x: padding + labelWidth + 10, y: y, width: fieldWidth, height: rowHeight))
        field.placeholderString = placeholder
        field.font = NSFont.systemFont(ofSize: 13)
        field.bezelStyle = .roundedBezel
        view.addSubview(field)
        
        y -= spacing
        return field
    }
    
    private func loadSettings() {
        apiBaseField?.stringValue = UserDefaults.standard.string(forKey: "llm_api_base") ?? ""
        apiKeyField?.stringValue = UserDefaults.standard.string(forKey: "llm_api_key") ?? ""
        modelField?.stringValue = UserDefaults.standard.string(forKey: "llm_model") ?? ""
    }
    
    @objc private func testConnection() {
        guard let refiner = llmRefiner else { return }
        
        UserDefaults.standard.set(apiBaseField?.stringValue ?? "", forKey: "llm_api_base")
        UserDefaults.standard.set(apiKeyField?.stringValue ?? "", forKey: "llm_api_key")
        UserDefaults.standard.set(modelField?.stringValue ?? "", forKey: "llm_model")
        
        testButton?.isEnabled = false
        statusLabel?.stringValue = "Testing..."
        statusLabel?.textColor = NSColor.labelColor
        
        refiner.testConnection { [weak self] success, message in
            DispatchQueue.main.async {
                self?.testButton?.isEnabled = true
                if success {
                    self?.statusLabel?.stringValue = "Connection successful"
                    self?.statusLabel?.textColor = NSColor(calibratedRed: 0, green: 0.6, blue: 0, alpha: 1)
                } else {
                    self?.statusLabel?.stringValue = message ?? "Unknown error"
                    self?.statusLabel?.textColor = NSColor(calibratedRed: 0.8, green: 0, blue: 0, alpha: 1)
                }
            }
        }
    }
    
    @objc private func saveSettings() {
        UserDefaults.standard.set(apiBaseField?.stringValue ?? "", forKey: "llm_api_base")
        UserDefaults.standard.set(apiKeyField?.stringValue ?? "", forKey: "llm_api_key")
        UserDefaults.standard.set(modelField?.stringValue ?? "", forKey: "llm_model")
        
        statusLabel?.stringValue = "Settings saved"
        statusLabel?.textColor = NSColor(calibratedRed: 0, green: 0.6, blue: 0, alpha: 1)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.statusLabel?.stringValue = ""
        }
    }
}