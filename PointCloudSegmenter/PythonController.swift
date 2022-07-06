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
import ARKit

func processFromFile(fileName: String) -> PythonObject {
    var mainPath: String! = Bundle.main.path(forResource: "room2blocks", ofType: "py")
    let length = mainPath.count
    mainPath = String(mainPath.prefix(length - 14))
    
    let sys = Python.import("sys")
    sys.path.append(mainPath)

    let room2blocks = Python.import("room2blocks")
    let filePath = Bundle.main.path(forResource: fileName, ofType: "txt")
    
    return room2blocks.processFromFile(filePath)
}

func processFromArray(data: PythonObject) -> PythonObject {
    var mainPath: String! = Bundle.main.path(forResource: "room2blocks", ofType: "py")
    let length = mainPath.count
    mainPath = String(mainPath.prefix(length - 14))
    
    let sys = Python.import("sys")
    sys.path.append(mainPath)

    let room2blocks = Python.import("room2blocks")
    
    return room2blocks.processFromArray(data)
}

func predict(data: PythonObject) -> [[Double]] {
    let config = MLModelConfiguration()
    config.computeUnits = .all
    guard let model = try? dgcnn_model(configuration: config)
    else {
        fatalError("Unexpected Runtime Error.")
    }

    
    let data = Array(processFromArray(data: data))
    var res = [[Double]]()
    
    var blockCount = 0
    
    for block in data[1] {
        for row in block[0] {
            let particle = [Double(row[0])!, Double(row[1])!, Double(row[2])!, Double(row[3])!, Double(row[4])!, Double(row[5])!]
            res.append(particle)
        }
    }
    
    for block in data[0] {
        guard let mlArray = try? MLMultiArray(shape: [1, 9, 4096], dataType: MLMultiArrayDataType.double)
        else {
            fatalError("Unexpected Runtime Error")
        }
        
        var index = 0
        for row in block {
            for col in row {
                let num : Double! = Double(col)
                mlArray[index] = NSNumber(value: num)
                index += 1
            }
        }

        guard let modelOutput = try? model.prediction(input: mlArray)
        else {
            fatalError("Unexpected Runtime Error.")
        }
        
        index = 0
        for num in castToDoubleArray(modelOutput.reduce_argmax_4) {
            res[index + (blockCount * 4096)].append(num)
            index += 1
        }
        
        blockCount += 1
    }
    
    return res
}

func getVolumeFromArray(data: [[Double]]) -> [[Double]] {
    var mainPath: String! = Bundle.main.path(forResource: "points2volume", ofType: "py")
    let length = mainPath.count
    mainPath = String(mainPath.prefix(length - 16))
    
    let sys = Python.import("sys")
    sys.path.append(mainPath)

    let points2volume = Python.import("points2volume")
    
    let res: [[Double]] = Array(points2volume.getVolume(data))!
    
    return res
}

func getVolumeFromArrayCBL(data: [[Double]], inference: [[Double]]) -> [[Double]] {
    var mainPath: String! = Bundle.main.path(forResource: "points2volume", ofType: "py")
    let length = mainPath.count
    mainPath = String(mainPath.prefix(length - 16))
    
    let sys = Python.import("sys")
    sys.path.append(mainPath)

    let points2volume = Python.import("points2volume")
    
    let res: [[Double]] = Array(points2volume.getVolumeCBL(data, inference))!
    
    return res
}

func castToDoubleArray(_ o: MLMultiArray) -> [Double] {
    var result: [Double] = Array(repeating: 0.0, count: o.count)
    for i in 0 ..< o.count {
        result[i] = o[i].doubleValue
    }
    
    return result
}

func castToPythonArray(arr: [[Double]]) -> PythonObject {
    let points: PythonObject = []
    
    for particle in arr {
        let x = PythonObject(particle[0])
        let y = PythonObject(particle[1])
        let z = PythonObject(particle[2])
        let r = PythonObject(Int(particle[3]))
        let g = PythonObject(Int(particle[4]))
        let b = PythonObject(Int(particle[5]))
        let a = PythonObject(Int(particle[6]))
        
        let point: PythonObject = [x, y, z, r, g, b, a]
        points.append(point)
    }
    
    return points
}

/**
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
     let a: PythonObject = 255
     let point: PythonObject = [x, y, z, r, g, b, a]
     points.append(point)
 }
 */
