//
//  SegmentUIView.swift
//  PointCloudSegmenter
//
//  Created by User01 on 16/10/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI
import Foundation
import Alamofire

struct SegmentPage: View {
    @State var targetfiles = [URL]()
    @State var fileName = ""
    @State var picked = "CBL"
    @State var pickedFile = "file:///None"
    
    @State var isSavingFile = false
    @State var savingError: XError? = nil
    @State var lastURL: URL = URL(fileURLWithPath: "None")

    var options = ["CBL","DGCNN","NONE"]
    var body: some View {
        ZStack{
            Color(UIColor.white).opacity(0.3).ignoresSafeArea()
            ScrollView{
                VStack(spacing: 30) {
                    Text("Segment Page")
                        .foregroundColor(.orange)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("Saved Scans: \(targetfiles.count-1) found")
                        .fontWeight(.semibold)
                    Text("Saved File: ")
                        .fontWeight(.semibold)
                    ZStack(alignment: .leading){
                        if fileName.isEmpty {
                            Text("File Name")
                                .padding(.leading, 20)
                        }
                        TextField("File Name", text: $fileName)
                            .padding(20)
                            .foregroundColor(.white)
                            .background(RoundedRectangle(cornerRadius: 5).stroke())
                    }
                    VStack(spacing: 10){
                        Text("TargetFile: ")
                            .fontWeight(.semibold)
                            .padding(.bottom, 10)
                        
                        Picker("", selection: $pickedFile, content: {
                            ForEach(targetfiles, id: \.self.absoluteString){
                                Text(
                                    $0.lastPathComponent != "None"
                                    ? $0.lastPathComponent.prefix(35) + "..."
                                    : "None"
                                )
                            }
                        })
                            .labelsHidden()
                            .foregroundColor(.orange)
                            .compositingGroup()
                            .clipped()
                    }
                    VStack(spacing: 10){
                        Text("Segmentation Method: ")
                            .fontWeight(.semibold)
                        Picker("", selection: $picked, content: {
                            ForEach(options, id: \.self){ Text($0) }
                        })
                            .labelsHidden()
                            .foregroundColor(.orange)
                    }
                    Spacer(minLength: 0)
                    HStack {
                        customButton(action: {
                            executeDelete()
                        }, text: "Delete")
                        customButton(action: {
                            segmentCloud()
                        }, text: "Segment")
                    }
                }
            }.foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.top)
        }
        .onAppear() {
            setDefault()
        }
    }
    @ViewBuilder
    func customButton(action: @escaping () -> Void, text: String) -> some View {
        Button {
            action()
        } label: {
            ZStack{
                RoundedRectangle(cornerRadius: 10)
                    .stroke(lineWidth: 3)
                    .fill(Color(UIColor.white))
                Text(text)
                    .foregroundColor(.orange)
                    .font(.system(size: 25, weight: .semibold))
            }.frame(height: 80)
        }

    }
    
    func setDefault() -> Void {
        picked = options[0]
        
        if !targetfiles.isEmpty {
            pickedFile = targetfiles[0].absoluteString
        }
    }
    
    func executeDelete() -> Void {
        guard pickedFile != "" && pickedFile != "file:///None" else { return }
        
        let selectedCloud = URL(string: pickedFile)
        
        try! FileManager.default.removeItem(at: selectedCloud!)
        targetfiles.remove(object: selectedCloud!)
        
        if !targetfiles.isEmpty {
            pickedFile = targetfiles[0].absoluteString
        } else {
            pickedFile = "None"
        }
        
        loadSavedClouds()
    }
    
    func segmentCloud() -> Void {
        guard pickedFile != "" && pickedFile != "file:///None" else { return }
        
        let selectedCloud = URL(string: pickedFile)
        
        let fileName = fileName != "" ? fileName : "untitled"
        
        var result = FileReader.readFile(url: selectedCloud!, raw: true)
        
        if picked == "CBL" {
            
            let headers: HTTPHeaders = [
                "Content-type": "multipart/form-data"
            ]
            
            AF.upload(multipartFormData: { multipartFormData in multipartFormData.append(selectedCloud!, withName: "file", fileName: "test", mimeType: "text/plain")}, to: "http://34.82.223.138:18999/api/cbl/inference/", headers: headers) { $0.timeoutInterval = 300 }
                .responseDecodable(of: CBLResponse.self) {
                response in
                
                guard let inferenceResult = response.value?.data
                else {
                    return
                }
                
                result = getVolumeFromArrayCBL(data: result, inference: inferenceResult)
                
                self.saveFile(
                    fileName: fileName,
                    pointCloud: result,
                    beforeGlobalThread: [],
                    afterGlobalThread: [afterSave]
                )
            }
            
            return
        }
        else if picked == "DGCNN" {
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
            fileName: fileName,
            pointCloud: result,
            beforeGlobalThread: [],
            afterGlobalThread: [afterSave]
        )
    }

    func afterSave() -> Void {
        let err = self.savingError
        if err == nil {
            return
        }
        try? FileManager.default.removeItem(at: self.lastURL)
        targetfiles.removeLast()
    }
    
    func saveFile(fileName: String, pointCloud: [[Double]], beforeGlobalThread: [() -> Void], afterGlobalThread: [() -> Void]) {
        
        guard !isSavingFile else {
            return
        }
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let mainController = mainStoryboard.instantiateViewController(withIdentifier: "mainController") as! MainController
        
        DispatchQueue.global().async {
            isSavingFile = true
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
                lastURL = fileURL
            } catch {
                savingError = XError.noScanDone
            }
    
            DispatchQueue.main.async {
                for task in afterGlobalThread { task() }
            }
            isSavingFile = false
        }
    }
    
    func getDocsURL() -> URL {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let docURL = URL(string: documentsDirectory)!
        return docURL
    }
    
    func loadSavedClouds() {
        let docURL = getDocsURL()
        loadRawClouds(docURL: docURL)
    }
    
    func loadRawClouds(docURL: URL) {
        let rawPath = docURL.appendingPathComponent("Raw")
        targetfiles = try! FileManager.default.contentsOfDirectory(
            at: rawPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
    }
}
