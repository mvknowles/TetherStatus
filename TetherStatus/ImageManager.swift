//
//  ImageManager.swift
//  tetherinfo
//
//  Created by Mark Knowles on 11/5/20.
//  Copyright © 2020 Mark Knowles. All rights reserved.
//

import Cocoa
import Foundation

extension NSImage {
    
    private func ciImages() -> [CIImage] {
        var ciImages: [CIImage] = []
  
        for imageRep in self.representations {
            guard let cgImage = imageRep.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                return ciImages
            }
            ciImages.append(CIImage(cgImage: cgImage))
        }
        
        return ciImages
    }
    
    func darkImage() throws -> NSImage  {
        let black = NSColor(red:0, green:0, blue:0, alpha:1.0)
        let white = NSColor(red:1, green:1, blue:1, alpha:1.0)
        return try replaceColor(colorOld:black, colorNew:white)
    }
    
    
    /* the Cocoa drawing guide explains how CIFilters work and the cube in particular
     https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaDrawingGuide/Images/Images.html#//apple_ref/doc/uid/TP40003290-CH208-BCIBBFGJ
     
     */
    
    public func replaceColor(colorOld: NSColor, colorNew: NSColor) throws -> NSImage {
        let images = self.ciImages()
        
        let returnImage = NSImage()

        for image in images {
            guard let ciImage = NSImage.replaceColorInCIImage(image:image, colorOld:colorOld, colorNew:colorNew) else {
                throw StringError("Couldn't return outputImage")
            }
            let rep = NSCIImageRep(ciImage: ciImage)
            returnImage.addRepresentation(rep)
        }
        
        return returnImage
    }
    
    public func replaceHue(minHue: CGFloat, maxHue: CGFloat, newColor: NSColor) throws -> NSImage {
        let images = self.ciImages()
        
        let returnImage = NSImage()

        for image in images {
            guard let ciImage = NSImage.replaceHueInCIImage(image:image, minHue:minHue, maxHue:maxHue, newColor:newColor) else {
                throw StringError("Couldn't return outputImage")
            }
            let rep = NSCIImageRep(ciImage: ciImage)
            returnImage.addRepresentation(rep)
        }
        
        return returnImage
    }
    
    public typealias ColorOperation = (_: NSColor) -> NSColor?
    
    public static func replaceHueInCIImage(image: CIImage, minHue: CGFloat, maxHue: CGFloat, newColor: NSColor) -> CIImage? {
        self.operateOnCIImage(image:image, colorOperation: { c in
            if c.hueComponent >= minHue && c.hueComponent <= maxHue {
                return newColor
            } else {
                return nil
            }
        })
    }
    
    public static func replaceColorInCIImage(image: CIImage, colorOld: NSColor, colorNew: NSColor) -> CIImage? {
        self.operateOnCIImage(image:image, colorOperation: { c in
            if c == colorOld {
                return colorNew
            } else {
                return nil
            }
        })
    }
    

    public static func operateOnCIImage(image: CIImage, colorOperation: ColorOperation) -> CIImage? {

        let size = 8
        var cubeData = [Float](repeating: 0, count: size * size * size * 4)
        var red: CGFloat
        var green: CGFloat
        var blue: CGFloat
        var offset = 0

        for z in 0..<size {
            blue = CGFloat(Double(z)/Double(size-1))
            
            for y in 0..<size {
                green = CGFloat(Double(y)/Double(size-1))
                for x in 0..<size {
                    red = CGFloat(Double(x)/Double(size-1))
                    
                    var c = NSColor(red: red, green: green, blue: blue, alpha: 1)
                    
                    if let newColor = colorOperation(c) {
                        c = newColor
                    }

                    cubeData[offset] = Float(c.redComponent)
                    cubeData[offset + 1] = Float(c.greenComponent)
                    cubeData[offset + 2] = Float(c.blueComponent)
                    cubeData[offset + 3] = Float(c.alphaComponent)
                    offset += 4
                }
            }
        }
        
        let data = cubeData.withUnsafeBufferPointer{ Data(buffer: $0) } as NSData
        let colorCube = CIFilter(name: "CIColorCube")!
        colorCube.setValue(size, forKey: "inputCubeDimension")
        colorCube.setValue(data, forKey:"inputCubeData")
        colorCube.setValue(image, forKey:kCIInputImageKey)
        
        return colorCube.outputImage
        
    }
    
}

class ImageManager {
    private static let coreWLANKitPath = "/System/Library/PrivateFrameworks/CoreWLANKit.framework"
    private static var coreServicesBundlePath = "/System/Library/CoreServices/CoreTypes.bundle"

    private var cellImageMappings = (0...4).map {
        String(format:"cellBars-%d", $0)
    }

    private var batteryImageMappings = ["battery"] +
            stride(from:10, to:110, by:10).map { String(format:"battery_%d", $0) }

    public var cellImages: [NSImage] = []
    public var batteryImages: [NSImage] = []
    public var noDeviceImage: NSImage
    public var iPhoneImage: NSImage
    
    private var greenBatteryColor = NSColor(red: 108.0 / 255.0, green: 237 / 255.0, blue: 130 / 255.0, alpha:1.0)
    private var yellowBatteryColor = NSColor(red: 1.0, green:1.0, blue:0, alpha:1.0)
    private var redBatteryColor = NSColor(red:1.0, green:0, blue:0, alpha:1.0)

    
    /* Note: apple apparently doesn't provide a good way of determining the
     status bar height, so callers probably need to hard code the value */
    init(statusBarImageHeight: CGFloat) throws {
        guard let coreTypesBundle = Bundle(path: ImageManager.coreServicesBundlePath) else {
            throw FatalError(format:"Couldn't open %@", ImageManager.coreServicesBundlePath)
        }

        
        guard let bundle = Bundle(path: ImageManager.coreWLANKitPath) else {
            throw FatalError(format:"Couldn't open %@", ImageManager.coreWLANKitPath)
        }

        self.cellImages =  try ImageManager.loadImages(bundle:bundle, imageNames:self.cellImageMappings)
        self.batteryImages =  try ImageManager.loadImages(bundle:bundle, imageNames:self.batteryImageMappings)

        self.batteryImages[5] = try self.batteryImages[5].replaceHue(minHue: 0.1, maxHue: 0.5, newColor: yellowBatteryColor)
        self.batteryImages[4] = try self.batteryImages[4].replaceHue(minHue: 0.1, maxHue: 0.5, newColor: yellowBatteryColor)
        self.batteryImages[3] = try self.batteryImages[3].replaceHue(minHue: 0.1, maxHue: 0.5, newColor: yellowBatteryColor)
        self.batteryImages[2] = try self.batteryImages[2].replaceHue(minHue: 0.1, maxHue: 0.5, newColor: redBatteryColor)
        self.batteryImages[1] = try self.batteryImages[1].replaceHue(minHue: 0.1, maxHue: 0.5, newColor: redBatteryColor)

        self.iPhoneImage =  try ImageManager.loadImage(bundle:coreTypesBundle, imageName:"SidebariPhone")
        self.iPhoneImage.size = NSSize(width: statusBarImageHeight, height: statusBarImageHeight)
        self.noDeviceImage = self.iPhoneImage
    }
    
    public static func combinedStatusImage(batteryImage: NSImage, cellImage: NSImage) -> NSImage {
        let spaceBetween = CGFloat(5.0)
        let combinedSize = NSSize(width: batteryImage.size.width + cellImage.size.width + spaceBetween, height: batteryImage.size.height)

        let statusImage = NSImage(size: combinedSize)
        let statusRect = CGRect(x: 0, y: 0, width: statusImage.size.width, height: statusImage.size.height)
        statusImage.lockFocus()
        batteryImage.draw(at: NSPoint(x: 0, y: 0), from: statusRect, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
        cellImage.draw(at: NSPoint(x:batteryImage.size.width + spaceBetween, y: 0), from: cellImage.alignmentRect, operation: NSCompositingOperation.sourceOver, fraction: 1.0)
         
        statusImage.unlockFocus()
        
        return statusImage
    }
    
    private static func loadImages(bundle: Bundle, imageNames: [String]) throws -> [NSImage] {
        var images: [NSImage] = []
        
        //TODO: revert to text if images not available
        for imageName in imageNames {
            let image = try loadImage(bundle:bundle, imageName: imageName)
            images.append(image)
        }
        return images
    }
    
    private static func loadImage(bundle: Bundle, imageName: String) throws -> NSImage {
        var returnImage: NSImage
        if let i = bundle.image(forResource:imageName) {
            returnImage = i
        } else {
            NSLog("Couldn't read bundle image")
            throw FatalError(format:"Couldn't load %s", imageName)
        }

        do {
            returnImage = try returnImage.darkImage()
        } catch {
            NSLog("Couldn't create dark images")
            NSLog(error.localizedDescription)
        }
        return returnImage
    }
    
}
