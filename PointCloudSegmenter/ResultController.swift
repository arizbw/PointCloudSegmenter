//
//  ResultController.swift
//  SceneDepthPointCloud

import SwiftUI
import Foundation


class ResultController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    private var exportData = [URL]()
    private var selectedExport: URL?
    private var selectedExportIdx : Int?
    private let deleteButton = UIButton(type: .system)
    private let exportPicker = UIPickerView()
    private let goToSaveCurrentViewButton = UIButton(type: .system)
    private let exportLabel = UILabel()
    var mainController: MainController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        mainController.loadSavedClouds()
        exportData = mainController.segmentedCloudURLs
        
        goToSaveCurrentViewButton.setTitle("Visualize Point Cloud", for: .normal)
        goToSaveCurrentViewButton.tintColor = .cyan
        goToSaveCurrentViewButton.setImage(.init(systemName: "arrow.down.doc"), for: .normal)
        goToSaveCurrentViewButton.translatesAutoresizingMaskIntoConstraints = false
        goToSaveCurrentViewButton.addTarget(self, action: #selector(goToCurrentScan), for: .touchUpInside)
        view.addSubview(goToSaveCurrentViewButton)
        
        exportLabel.text = "Segmented Clouds: \(exportData.count) found"
        exportLabel.translatesAutoresizingMaskIntoConstraints = false
        exportLabel.textColor = .white
        view.addSubview(exportLabel)
        
        exportPicker.delegate = self
        exportPicker.dataSource = self
        exportPicker.translatesAutoresizingMaskIntoConstraints = false
        if !exportData.isEmpty {
            exportPicker.delegate?.pickerView?(exportPicker, didSelectRow: 0, inComponent: 0)
        }
        view.addSubview(exportPicker)
        
        deleteButton.tintColor = .red
        deleteButton.setTitle("Delete Selected Cloud", for: .normal)
        deleteButton.setImage(.init(systemName: "trash.slash"), for: .normal)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(executeDelete), for: .touchUpInside)
        view.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            exportLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            exportLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            deleteButton.widthAnchor.constraint(equalToConstant: 250),
            deleteButton.heightAnchor.constraint(equalToConstant: 50),
            deleteButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -100),
            deleteButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            exportPicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exportPicker.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 150),
            
            goToSaveCurrentViewButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            goToSaveCurrentViewButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return exportData.count
    }
    func pickerView(_ pickerView: UIPickerView,titleForRow row: Int, forComponent component: Int) -> String? {
        return exportData[row].lastPathComponent
        
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedExportIdx = row
        selectedExport = !exportData.isEmpty ? exportData[row] : nil
    }
   
    func onSaveError(error: XError) {
        dismissModal()
        mainController.onSaveError(error: error)
    }
        
    func dismissModal() { self.dismiss(animated: true, completion: nil) }
    
    @objc func goToCurrentScan() {
        guard selectedExport != nil else { return }
        
        dismissModal()
        mainController.toVisualize(url: selectedExport!)
    }
    
    @objc func executeDelete() -> Void {
        guard selectedExport != nil else { return }

        try! FileManager.default.removeItem(at: selectedExport!)
        mainController.scannedCloudURLs.remove(at: selectedExportIdx!)
        exportData.remove(at: selectedExportIdx!)
        exportPicker.reloadAllComponents()
        
        if selectedExportIdx == 0  {
            exportPicker.delegate?.pickerView?(exportPicker, didSelectRow: 0, inComponent: 0)
        } else if selectedExportIdx == exportData.count {
            exportPicker.delegate?.pickerView?(exportPicker, didSelectRow: selectedExportIdx!-1, inComponent: 0)
        } else {
            exportPicker.delegate?.pickerView?(exportPicker, didSelectRow: selectedExportIdx!, inComponent: 0)
        }
        
        exportLabel.text = "Saved Scans: \(exportData.count) found"
    }
    
    func loadSavedClouds() -> [URL] {
        let docs = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask)[0]
        let savedCloudURLs = try! FileManager.default.contentsOfDirectory(
            at: docs, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        
        return savedCloudURLs
    }
}
