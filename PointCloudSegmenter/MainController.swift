//
//  MainController.swift
//  SceneDepthPointCloud
//
//  Created by User01 on 21/03/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import UIKit
import Open3DSupport
import NumPySupport
import PythonSupport
import PythonKit
import Foundation

class MainController : UIViewController {
    var scannedCloudURLs = [URL]()
    var segmentedCloudURLs = [URL]()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        self.initializeSaveFolders()
        
        PythonSupport.initialize()
        NumPySupport.sitePackagesURL.insertPythonPath()
        Open3DSupport.sitePackagesURL.insertPythonPath()
        
        let appIcon = UIImageView(image: UIImage(systemName: "camera.circle", withConfiguration: UIImage.SymbolConfiguration(scale: .large)))
        appIcon.translatesAutoresizingMaskIntoConstraints = false
        appIcon.tintColor = .white
        view.addSubview(appIcon)
        
        let titleText = UILabel()
        titleText.text = "Point Cloud Segmenter"
        titleText.translatesAutoresizingMaskIntoConstraints = false
        titleText.textAlignment = NSTextAlignment.center
        view.addSubview(titleText)
        
        let scanButton = UIButton(type: .system)
        scanButton.setTitle("Scan", for: .normal)
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        scanButton.addTarget(self, action: #selector(toScan), for: .touchUpInside)
        scanButton.tintColor = .white
        scanButton.backgroundColor = .systemGray
        view.addSubview(scanButton)
        
        let segmentButton = UIButton(type: .system)
        segmentButton.setTitle("Segment", for: .normal)
        segmentButton.translatesAutoresizingMaskIntoConstraints = false
        segmentButton.addTarget(self, action: #selector(showScanResults), for: .touchUpInside)
        segmentButton.tintColor = .white
        segmentButton.backgroundColor = .systemGray
        view.addSubview(segmentButton)
        
        let visualizeButton = UIButton(type: .system)
        visualizeButton.setTitle("Visualize", for: .normal)
        visualizeButton.translatesAutoresizingMaskIntoConstraints = false
        visualizeButton.addTarget(self, action: #selector(showSegmentResult), for: .touchUpInside)
        visualizeButton.tintColor = .white
        visualizeButton.backgroundColor = .systemGray
        view.addSubview(visualizeButton)
        
        NSLayoutConstraint.activate([
            appIcon.widthAnchor.constraint(equalToConstant: 100),
            appIcon.heightAnchor.constraint(equalToConstant: 100),
            appIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appIcon.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -600),
            
            titleText.widthAnchor.constraint(equalToConstant: 200),
            titleText.heightAnchor.constraint(equalToConstant: 50),
            titleText.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleText.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -550),
            
            scanButton.widthAnchor.constraint(equalToConstant: 150),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -400),
            
            segmentButton.widthAnchor.constraint(equalToConstant: 150),
            segmentButton.heightAnchor.constraint(equalToConstant: 50),
            segmentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -300),
            
            visualizeButton.widthAnchor.constraint(equalToConstant: 150),
            visualizeButton.heightAnchor.constraint(equalToConstant: 50),
            visualizeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            visualizeButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -200)
        ])
        
        self.loadSavedClouds()
    }
    
    @objc func toScan() -> Void {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: "scanController") as! ScanController
        UIApplication.shared.windows.first?.rootViewController = viewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    @objc func toVisualize(url: URL) -> Void {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: "visualizeController") as! VisualizeController
        viewController.chosenCloud = url
        UIApplication.shared.windows.first?.rootViewController = viewController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    @objc func showScanResults() -> Void {
        let segmentController = SegmentController()
        segmentController.mainController = self
        present(segmentController, animated: true, completion: nil)
    }
    
    @objc func showSegmentResult() -> Void {
        let resultController = ResultController()
        resultController.mainController = self
        present(resultController, animated: true, completion: nil)
    }
    
    func onSaveError(error: XError) {
        displayErrorMessage(error: error)
    }
    
    func displayErrorMessage(error: XError) -> Void {
        var title: String
        switch error {
            case .alreadySavingFile: title = "Save in Progress Please Wait."
            case .noScanDone: title = "No scan to Save."
            case.savingFailed: title = "Failed To Write File."
            case .serverOffline: title = "Server is Offline"
        }
        
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        present(alert, animated: true, completion: nil)
        let when = DispatchTime.now() + 1.75
        DispatchQueue.main.asyncAfter(deadline: when) {
            alert.dismiss(animated: true, completion: nil)
        }
    }
    
    func loadSavedClouds() {
        let docURL = getDocsURL()
        loadRawClouds(docURL: docURL)
        loadSegmentedClouds(docURL: docURL)
    }
    
    func loadRawClouds(docURL: URL) {
        let rawPath = docURL.appendingPathComponent("Raw")
        scannedCloudURLs = try! FileManager.default.contentsOfDirectory(
            at: rawPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
    }
    
    func loadSegmentedClouds(docURL: URL) {
        let segmentedPath = docURL.appendingPathComponent("Segmented")
        segmentedCloudURLs = try! FileManager.default.contentsOfDirectory(
            at: segmentedPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
    }
    
    func initializeSaveFolders() {
        let docURL = getDocsURL()
        let rawPath = docURL.appendingPathComponent("Raw")
        let segmentedPath = docURL.appendingPathComponent("Segmented")
        if !FileManager.default.fileExists(atPath: rawPath.path) {
            do {
                try FileManager.default.createDirectory(atPath: rawPath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
        if !FileManager.default.fileExists(atPath: segmentedPath.path) {
            do {
                try FileManager.default.createDirectory(atPath: segmentedPath.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func getDocsURL() -> URL {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let docURL = URL(string: documentsDirectory)!
        return docURL
    }
}
