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
        
        let backgroundLayer = UIImageView()
        backgroundLayer.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        backgroundLayer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundLayer)
        
        let appIcon = UIImageView(image: UIImage(systemName: "camera.circle", withConfiguration: UIImage.SymbolConfiguration(scale: .large)))
        appIcon.translatesAutoresizingMaskIntoConstraints = false
        appIcon.tintColor = .white
        view.addSubview(appIcon)
        
        let titleText = UILabel()
        titleText.text = "Point Cloud Segmenter"
        titleText.translatesAutoresizingMaskIntoConstraints = false
        titleText.textAlignment = NSTextAlignment.center
        titleText.font = titleText.font.withSize(25)
        view.addSubview(titleText)
        
        let scanButton = UIButton(type: .system)
        scanButton.setTitle("Scan", for: .normal)
        scanButton.titleLabel?.font = scanButton.titleLabel?.font.withSize(20)
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        scanButton.addTarget(self, action: #selector(toScan), for: .touchUpInside)
        scanButton.tintColor = .white
        scanButton.layer.borderWidth = 3
        scanButton.layer.borderColor = UIColor.white.cgColor
        scanButton.layer.cornerRadius = 2
        view.addSubview(scanButton)
        
        let segmentButton = UIButton(type: .system)
        segmentButton.setTitle("Segment", for: .normal)
        segmentButton.titleLabel?.font = segmentButton.titleLabel?.font.withSize(20)
        segmentButton.translatesAutoresizingMaskIntoConstraints = false
        segmentButton.addTarget(self, action: #selector(showScanResults), for: .touchUpInside)
        segmentButton.tintColor = .white
        segmentButton.layer.borderWidth = 3
        segmentButton.layer.borderColor = UIColor.white.cgColor
        segmentButton.layer.cornerRadius = 2
        view.addSubview(segmentButton)
        
        let visualizeButton = UIButton(type: .system)
        visualizeButton.setTitle("Visualize", for: .normal)
        visualizeButton.titleLabel?.font = segmentButton.titleLabel?.font.withSize(20)
        visualizeButton.translatesAutoresizingMaskIntoConstraints = false
        visualizeButton.addTarget(self, action: #selector(showSegmentResult), for: .touchUpInside)
        visualizeButton.tintColor = .white
        visualizeButton.layer.borderWidth = 3
        visualizeButton.layer.borderColor = UIColor.white.cgColor
        visualizeButton.layer.cornerRadius = 2
        view.addSubview(visualizeButton)
        
        NSLayoutConstraint.activate([
            backgroundLayer.widthAnchor.constraint(equalToConstant: 100000),
            backgroundLayer.heightAnchor.constraint(equalToConstant: 100000),
            backgroundLayer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            backgroundLayer.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            appIcon.widthAnchor.constraint(equalToConstant: 150),
            appIcon.heightAnchor.constraint(equalToConstant: 150),
            appIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            appIcon.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -550),
            
            titleText.widthAnchor.constraint(equalTo: view.widthAnchor),
            titleText.heightAnchor.constraint(equalToConstant: 50),
            titleText.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleText.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -500),
            
            scanButton.widthAnchor.constraint(equalToConstant: 250),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -400),
            
            segmentButton.widthAnchor.constraint(equalToConstant: 250),
            segmentButton.heightAnchor.constraint(equalToConstant: 50),
            segmentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            segmentButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -325),
            
            visualizeButton.widthAnchor.constraint(equalToConstant: 250),
            visualizeButton.heightAnchor.constraint(equalToConstant: 50),
            visualizeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            visualizeButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -250)
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
