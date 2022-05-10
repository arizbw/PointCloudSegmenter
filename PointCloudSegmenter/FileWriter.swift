//
//  PLYFile.swift
//  SceneDepthPointCloud

/*
 PLY File Scalar Byte Counts
 http://paulbourke.net/dataformats/ply/
 
 name        type        number of bytes
 ---------------------------------------
 char       character                 1
 uchar      unsigned character        1
 short      short integer             2
 ushort     unsigned short integer    2
 int        integer                   4
 uint       unsigned integer          4
 float      single-precision float    4
 double     double-precision float    8
 */

import Foundation

final class FileWriter {
    static func write(fileName: String, pointCloud: [[Double]], raw: Bool) throws -> URL {
        
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask)[0]
        var file = documentsDirectory
        if (raw == true) {
            file = file.appendingPathComponent("Raw")
        }
        else {
            file = file.appendingPathComponent("Segmented")
        }
        file = file.appendingPathComponent(
            "\(fileName)_\(Date().description(with: .current)).txt", isDirectory: false)
        
        FileManager.default.createFile(atPath: file.path, contents: nil, attributes: nil)
        
        try writeAscii(file: file, pointCloud: pointCloud, raw: raw)
        
        return file
    }
    
    private static func arrangeColorByte(color: simd_float1) -> UInt8 {
        /// Convert [0, 255] Float32 to UInt8
        let absColor = abs(Int16(color))
        return absColor <= 255 ? UInt8(absColor) : UInt8(255)
    }
    
    private static func writeAscii(file: URL, pointCloud: [[Double]], raw: Bool) throws  -> Void {
        var vertexStrings = ""
        for particle in pointCloud {
            let x = particle[0]
            let y = particle[1]
            let z = particle[2]
            
            let red = particle[3]
            let green = particle[4]
            let blue = particle[5]
            
            vertexStrings +=  "\(x) \(y) \(z) \(red) \(green) \(blue)"
            
            if (raw == false) {
                let classification = particle[6]
                let vol = particle[7]
                let id = particle[8]
                
                vertexStrings +=  " \(classification) \(vol) \(id)"
            }
            
            vertexStrings += "\r\n"
        }
        
        let fileHandle = try FileHandle(forWritingTo: file)
        do {
            try fileHandle.truncate(atOffset: 0)
        }
        catch {
            print(error)
        }
        
        fileHandle.seekToEndOfFile()
        fileHandle.write(vertexStrings.data(using: .ascii)!)
        fileHandle.closeFile()
    }
}
