//
//  MainController.swift
//  SceneDepthPointCloud
//
//  Created by User01 on 21/03/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import UIKit
import SwiftUI
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
        
        self.initializeSaveFolders()
        
        PythonSupport.initialize()
        NumPySupport.sitePackagesURL.insertPythonPath()
        Open3DSupport.sitePackagesURL.insertPythonPath()
        
        self.loadSavedClouds()
        
        let swiftUIViewController = UIHostingController(rootView: ContentView(scannedCloudURLs: scannedCloudURLs, segmentedCloudURLs: segmentedCloudURLs))
        addChild(swiftUIViewController)
        swiftUIViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(swiftUIViewController.view)
        swiftUIViewController.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            swiftUIViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            swiftUIViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor),
            swiftUIViewController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            swiftUIViewController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
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
        scannedCloudURLs.append(URL(fileURLWithPath: "None"))
    }
    
    func loadSegmentedClouds(docURL: URL) {
        let segmentedPath = docURL.appendingPathComponent("Segmented")
        segmentedCloudURLs = try! FileManager.default.contentsOfDirectory(
            at: segmentedPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        segmentedCloudURLs.append(URL(fileURLWithPath: "None"))
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
