//
//  SwiftUIView.swift
//  PointCloudSegmenter
//
//  Created by Natanael Jop on 15/10/2022.
//  Copyright © 2022 Apple. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var showSegment = false
    @State var showVizualize = false
    @State var showScan = false
    
    @State var scannedCloudURLs = [URL]()
    @State var segmentedCloudURLs = [URL]()
    
    var body: some View {
        if showScan {
            ScanViewController()
        } else {
            NavigationView {
                ZStack{
                    Color(UIColor.white).opacity(0.3).ignoresSafeArea()
                    VStack() {
                        Spacer()
                        Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150)
                            .foregroundColor(.orange)
                        Text("Point Cloud Segmenter")
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(20)
                            .padding(.bottom, 50)
                        Spacer()
                        VStack(spacing: 20){
                            ZStack{
                                customButton(action: {
                                    showScan = true
                                }, text: "Scan")
                            }.frame(height: 80)
                            HStack(spacing: 20){
                                customButton(action: {
                                    loadSavedClouds()
                                    showSegment = true
                                }, text: "Segment")
                                customButton(action: {
                                    loadSavedClouds()
                                    showVizualize = true
                                }, text: "Visualize")
                            }
                        }
                        Spacer()
                    }.padding()
                        .padding(.horizontal, 10)
                }.sheet(isPresented: $showSegment, onDismiss: loadSavedClouds) {
                    SegmentPage(targetfiles: scannedCloudURLs)
                }
                .sheet(isPresented: $showVizualize, onDismiss: loadSavedClouds) {
                    VizualizePage(targetfiles: segmentedCloudURLs)
                }.navigationBarBackButtonHidden(true)
                    .navigationBarHidden(true)
            }.preferredColorScheme(.light)
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
                    .font(.system(size: 20, weight: .semibold))
            }.frame(height: 60)
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
}

struct ScanViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: "scanController") as! ScanController
        return viewController
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

extension Array where Element: Equatable {
    mutating func remove(object: Element) {
        guard let index = firstIndex(of: object) else {return}
        remove(at: index)
    }
}
