//
//  Room2Blocks.swift
//  pointcloudmetal
//
//  Created by User01 on 13/03/22.
//

import Open3DSupport
import NumPySupport
import PythonSupport
import PythonKit
import Foundation

func testPython() -> PythonObject {
    PythonSupport.initialize()
    NumPySupport.sitePackagesURL.insertPythonPath()
    Open3DSupport.sitePackagesURL.insertPythonPath()

    var mainPath: String! = Bundle.main.path(forResource: "show", ofType: "py")
    let length = mainPath.count
    mainPath = String(mainPath.prefix(length - 7))
    
    let sys = Python.import("sys")
    sys.path.append(mainPath)

    let room2blocks = Python.import("room2blocks")
    let filePath = Bundle.main.path(forResource: "ayatkursi", ofType: "txt")
    
    return room2blocks.test(filePath)
}
