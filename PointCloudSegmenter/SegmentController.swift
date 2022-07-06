//
//  SegmentController.swift
//  PointCloudSegmenter
//

import SwiftUI
import Foundation
import Alamofire

struct CBLResponse: Codable {
    let status: String
    let data: [[Double]]
}

class SegmentController : UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    private var savedClouds = [URL]()
    private var selectedCloud: URL?
    private var selectedCloudIdx : Int?
    private let deleteButton = UIButton(type: .system)
    private let cloudPicker = UIPickerView()
    private let segmentationMethodPicker = UIPickerView()
    private let fileNameInput = UITextField()
    private let cloudLabel = UILabel()
    var mainController: MainController!
    
    private var methodsData: [String] = ["CBL", "DGCNN", "None"]
    private var selectedMethod: String?
    
    private let segmentButton = UIButton(type: .system)
    
    var isSavingFile = false
    var savingError: XError? = nil
    var lastURL: URL = URL(fileURLWithPath: "None")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        mainController.loadSavedClouds()
        savedClouds = mainController.scannedCloudURLs
        
        cloudLabel.text = "Saved Scans: \(savedClouds.count) found"
        cloudLabel.translatesAutoresizingMaskIntoConstraints = false
        cloudLabel.textColor = .white
        view.addSubview(cloudLabel)
        
        cloudPicker.tag = 1
        cloudPicker.delegate = self
        cloudPicker.dataSource = self
        cloudPicker.translatesAutoresizingMaskIntoConstraints = false
        if !savedClouds.isEmpty {
            cloudPicker.delegate?.pickerView?(cloudPicker, didSelectRow: 0, inComponent: 0)
        }
        view.addSubview(cloudPicker)
        
        segmentationMethodPicker.tag = 2
        segmentationMethodPicker.delegate = self
        segmentationMethodPicker.dataSource = self
        segmentationMethodPicker.translatesAutoresizingMaskIntoConstraints = false
        segmentationMethodPicker.delegate?.pickerView?(segmentationMethodPicker, didSelectRow: 0, inComponent: 0)
        view.addSubview(segmentationMethodPicker)
        
        fileNameInput.delegate = self
        fileNameInput.isUserInteractionEnabled = true
        fileNameInput.translatesAutoresizingMaskIntoConstraints = false
        fileNameInput.placeholder = "File Name"
        fileNameInput.borderStyle = .roundedRect
        fileNameInput.autocorrectionType = .no
        fileNameInput.returnKeyType = .done
        fileNameInput.backgroundColor = .systemBackground
        view.addSubview(fileNameInput)
        
        deleteButton.tintColor = .red
        deleteButton.setTitle("Delete Selected Scan", for: .normal)
        deleteButton.setImage(.init(systemName: "trash.slash"), for: .normal)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(executeDelete), for: .touchUpInside)
        view.addSubview(deleteButton)
        
        segmentButton.setTitle("Segment Selected Scan", for: .normal)
        segmentButton.tintColor = .cyan
        segmentButton.setImage(.init(systemName: "arrow.down.doc"), for: .normal)
        segmentButton.translatesAutoresizingMaskIntoConstraints = false
        segmentButton.addTarget(self, action: #selector(segmentCloud), for: .touchUpInside)
        view.addSubview(segmentButton)
        
        NSLayoutConstraint.activate([
            cloudLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            cloudLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            segmentationMethodPicker.heightAnchor.constraint(equalToConstant: 225),
            segmentationMethodPicker.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -200),
            segmentationMethodPicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            cloudPicker.heightAnchor.constraint(equalToConstant: 225),
            cloudPicker.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -375),
            cloudPicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            fileNameInput.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fileNameInput.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -600),
            fileNameInput.widthAnchor.constraint(equalToConstant: 250),
            fileNameInput.heightAnchor.constraint(equalToConstant: 45),
            
            deleteButton.widthAnchor.constraint(equalToConstant: 250),
            deleteButton.heightAnchor.constraint(equalToConstant: 50),
            deleteButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            deleteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            segmentButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            segmentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        self.loadSavedClouds()
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool { return true }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1 {
            return savedClouds.count
        }
        else {
            return methodsData.count
        }
    }
    func pickerView(_ pickerView: UIPickerView,titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 1 {
            return savedClouds[row].lastPathComponent
        }
        else {
            return methodsData[row]
        }
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1 {
            selectedCloudIdx = row
            selectedCloud = !savedClouds.isEmpty ? savedClouds[row] : nil
        }
        else {
            selectedMethod = methodsData[row]
        }
    }
   
    func onSaveError(error: XError) {
        dismissModal()
        mainController.onSaveError(error: error)
    }
    
    func export(url: URL) -> Void {
        present(
            UIActivityViewController(
                activityItems: [url as Any],
                applicationActivities: .none),
            animated: true)
    }
    
    func afterSave() -> Void {
        let err = self.savingError
        if err == nil {
            self.loadSavedClouds()
            return export(url: self.lastURL)
        }
        try? FileManager.default.removeItem(at: self.lastURL)
        self.savedClouds.removeLast()
        onSaveError(error: err!)
    }
    
    private func beforeSave() {
        segmentButton.isEnabled = false
        isModalInPresentation = true
    }
        
    func dismissModal() { self.dismiss(animated: true, completion: nil) }
    
    @objc func segmentCloud() {
        guard selectedCloud != nil else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "id")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let date = Date()
        
        let fileName = !fileNameInput.text!.isEmpty ? fileNameInput.text : "untitled-" + dateFormatter.string(from: date)
        
        var result = FileReader.readFile(url: selectedCloud!, raw: true)
        
        if selectedMethod == "CBL" {
            
            let headers: HTTPHeaders = [
                "Content-type": "multipart/form-data"
            ]
            
            AF.upload(multipartFormData: { multipartFormData in multipartFormData.append(self.selectedCloud!, withName: "file", fileName: "test", mimeType: "text/plain")}, to: "http://34.82.223.138:18999/api/cbl/inference/", headers: headers) { $0.timeoutInterval = 300 }
                .responseDecodable(of: CBLResponse.self) {
                response in
                
                guard let inferenceResult = response.value?.data
                else {
                    self.onSaveError(error: XError.serverOffline)
                    return
                }
                
                result = getVolumeFromArrayCBL(data: result, inference: inferenceResult)
                
                self.saveFile(
                    fileName: fileName!,
                    pointCloud: result,
                    beforeGlobalThread: [],
                    afterGlobalThread: [self.dismissModal, self.afterSave],
                    errorCallback: self.onSaveError
                )
            }
            
            self.beforeSave()
            return
        }
        else if selectedMethod == "DGCNN" {
            let points = castToPythonArray(arr: result)
            let rawResult = predict(data: points)
            
            result = getVolumeFromArray(data: rawResult)
        }
        else {
            var newRes = [[Double]]()
            
            for cloud in result {
                var newPoint = cloud
                newPoint[6] = Double(12)
                newRes.append(newPoint)
            }
            
            result = getVolumeFromArray(data: newRes)
        }
        
        self.saveFile(
            fileName: fileName!,
            pointCloud: result,
            beforeGlobalThread: [beforeSave],
            afterGlobalThread: [dismissModal, self.afterSave],
            errorCallback: onSaveError
        )
        
        dismissModal()
    }
    
    @objc func executeDelete() -> Void {
        guard selectedCloud != nil else { return }
        
        try! FileManager.default.removeItem(at: selectedCloud!)
        mainController.scannedCloudURLs.remove(at: selectedCloudIdx!)
        savedClouds.remove(at: selectedCloudIdx!)
        cloudPicker.reloadAllComponents()
        
        if selectedCloudIdx == 0  {
            cloudPicker.delegate?.pickerView?(cloudPicker, didSelectRow: 0, inComponent: 0)
        } else if selectedCloudIdx == savedClouds.count {
            cloudPicker.delegate?.pickerView?(cloudPicker, didSelectRow: selectedCloudIdx!-1, inComponent: 0)
        } else {
            cloudPicker.delegate?.pickerView?(cloudPicker, didSelectRow: selectedCloudIdx!, inComponent: 0)
        }
        
        cloudLabel.text = "Saved Scans: \(savedClouds.count) found"
    }
    
    func saveFile(fileName: String, pointCloud: [[Double]], beforeGlobalThread: [() -> Void], afterGlobalThread: [() -> Void], errorCallback: (XError) -> Void) {
        
        guard !isSavingFile else {
            return errorCallback(XError.alreadySavingFile)
        }
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let mainController = mainStoryboard.instantiateViewController(withIdentifier: "mainController") as! MainController
        
        DispatchQueue.global().async {
            self.isSavingFile = true
            DispatchQueue.main.async {
                for task in beforeGlobalThread { task() }
            }
            
            do {
                let fileURL = try FileWriter.write(
                        fileName: fileName,
                        pointCloud: pointCloud,
                        raw: false
                )
                mainController.scannedCloudURLs.append(fileURL)
                self.lastURL = fileURL
            } catch {
                self.savingError = XError.noScanDone
            }
    
            DispatchQueue.main.async {
                for task in afterGlobalThread { task() }
            }
            self.isSavingFile = false
        }
    }
    
    func loadSavedClouds() {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let mainController = mainStoryboard.instantiateViewController(withIdentifier: "mainController") as! MainController
        
        mainController.loadSavedClouds()
        savedClouds = mainController.scannedCloudURLs
    }
}
