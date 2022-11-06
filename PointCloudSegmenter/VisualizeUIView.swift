//
//  VisualizeUIView.swift
//  PointCloudSegmenter
//
//  Created by User01 on 16/10/22.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct VizualizePage: View {
    @State var targetfiles = [URL]()
    @State var fileName = ""
    @State var pickedFile = "file:///None"
    @State var chosenCloud = URL(fileURLWithPath: "None")

    @State var showVisualize = false
    var body: some View {
        if showVisualize {
            VisualizeViewController(chosenCloud: chosenCloud)
        } else {
            ZStack{
                Color(UIColor.white).opacity(0.3).ignoresSafeArea()
                VStack(spacing: 30) {
                    Text("Vizualize Page")
                        .foregroundColor(.orange)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("Segmented Clouds: \(targetfiles.count-1) found")
                        .fontWeight(.semibold)
                    VStack(spacing: 10){
                        Text("Selected File: ")
                            .fontWeight(.semibold)
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
                    }.padding(.top, 60)
                    
                    Spacer(minLength: 0)
                    HStack {
                        customButton(action: {
                            executeDelete()
                        }, text: "Delete")
                        customButton(action: {
                            executeVisualize()
                        }, text: "Visualize")
                    }
                }.foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.top)
            }.onAppear() {
                setDefault()
            }
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
    
    func executeVisualize() -> Void {
        guard pickedFile != "" && pickedFile != "file:///None" else { return }
        
        let selectedCloud = URL(string: pickedFile)
        chosenCloud = selectedCloud!
        
        showVisualize = true
    }
    
    func setDefault() -> Void {
        if !targetfiles.isEmpty {
            pickedFile = targetfiles[0].absoluteString
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
        loadSegmentedClouds(docURL: docURL)
    }
    
    func loadSegmentedClouds(docURL: URL) {
        let segmentedPath = docURL.appendingPathComponent("Segmented")
        targetfiles = try! FileManager.default.contentsOfDirectory(
            at: segmentedPath, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        targetfiles.append(URL(fileURLWithPath: "None"))
    }
}

struct VisualizeViewController: UIViewControllerRepresentable {
    var chosenCloud: URL

    func makeUIViewController(context: Context) -> some UIViewController {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: "visualizeController") as! VisualizeController
        viewController.chosenCloud = chosenCloud
        return viewController
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}
