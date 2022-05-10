//
//  SaveController.swift
//  SceneDepthPointCloud

import SwiftUI
import Foundation
import PythonKit
import PythonSupport

class SaveController : UIViewController, UITextFieldDelegate {
    private let saveCurrentButton = UIButton(type: .system)
    private let saveCurrentScanLabel = UILabel()
    private let fileTypeWarning = UILabel()
    private let savingLabel = UILabel()
    private let fileNameInput = UITextField()
    var scanController: ScanController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        fileTypeWarning.text = "File will be saved as .txt"
        fileTypeWarning.translatesAutoresizingMaskIntoConstraints = false
        fileTypeWarning.textColor = .white
        view.addSubview(fileTypeWarning)
        
        fileNameInput.delegate = self
        fileNameInput.isUserInteractionEnabled = true
        fileNameInput.translatesAutoresizingMaskIntoConstraints = false
        fileNameInput.placeholder = "File Name"
        fileNameInput.borderStyle = .roundedRect
        fileNameInput.autocorrectionType = .no
        fileNameInput.returnKeyType = .done
        fileNameInput.backgroundColor = .systemBackground
        view.addSubview(fileNameInput)
        
        saveCurrentScanLabel.text = "Current Scan: \(scanController.renderer.highConfCount) points"
        saveCurrentScanLabel.translatesAutoresizingMaskIntoConstraints = false
        saveCurrentScanLabel.textColor = .white
        view.addSubview(saveCurrentScanLabel)
        
        savingLabel.text = "Saving, please wait"
        savingLabel.translatesAutoresizingMaskIntoConstraints = false
        savingLabel.textColor = .white
        
        saveCurrentButton.tintColor = .green
        saveCurrentButton.setTitle("Save Scan", for: .normal)
        saveCurrentButton.setImage(.init(systemName: "arrow.down.doc"), for: .normal)
        saveCurrentButton.translatesAutoresizingMaskIntoConstraints = false
        saveCurrentButton.addTarget(self, action: #selector(executeSave), for: .touchUpInside)
        view.addSubview(saveCurrentButton)
        
        NSLayoutConstraint.activate([
            fileNameInput.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fileNameInput.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            fileNameInput.widthAnchor.constraint(equalToConstant: 250),
            fileNameInput.heightAnchor.constraint(equalToConstant: 45),
            
            saveCurrentScanLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveCurrentScanLabel.bottomAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            
            fileTypeWarning.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fileTypeWarning.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -120),
            
            saveCurrentButton.widthAnchor.constraint(equalToConstant: 150),
            saveCurrentButton.heightAnchor.constraint(equalToConstant: 50),
            saveCurrentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveCurrentButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -165)
        ])
    }
    
    /// Text field delegate methods
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool { return true }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
   
    func onSaveError(error: XError) {
        dismissModal()
        scanController.onSaveError(error: error)
    }
        
    func dismissModal() { self.dismiss(animated: true, completion: nil) }
    
    private func beforeSave() {
        saveCurrentButton.isEnabled = false
        isModalInPresentation = true
    }
        
    @objc func executeSave() -> Void {
        view.addSubview(savingLabel)
        NSLayoutConstraint.activate([
            savingLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            savingLabel.bottomAnchor.constraint(equalTo: view.topAnchor, constant: 100)
        ])
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "id")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let date = Date()
        
        let fileName = !fileNameInput.text!.isEmpty ? fileNameInput.text : "untitled-" + dateFormatter.string(from: date)

        let points: PythonObject = []
        
        for particle in scanController.renderer.getCpuParticles() {
            if particle.confidence != 2 { continue }
            let colors = particle.color
            let x = PythonObject(particle.position.x)
            let y = PythonObject(particle.position.y)
            let z = PythonObject(particle.position.z)
            let r = PythonObject(Int(colors.x))
            let g = PythonObject(Int(colors.y))
            let b = PythonObject(Int(colors.z))
            
            let point: PythonObject = [x, y, z, r, g, b]
            points.append(point)
        }
        
        let result: [[Double]] = Array(points)!
        
        scanController.renderer.saveFile(
            fileName: fileName!,
            pointCloud: result,
            raw: true,
            beforeGlobalThread: [beforeSave],
            afterGlobalThread: [dismissModal, scanController.afterSave],
            errorCallback: onSaveError
        )
    }
}

