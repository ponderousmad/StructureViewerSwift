//
//  ViewController.swift
//  StructureViewerSwift
//
//  Created by Adrian Smith on 2015-05-06.
//  Copyright (c) 2015 Adrian Smith. All rights reserved.
//

import UIKit

class ViewController: UIViewController, STSensorControllerDelegate {

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var depthView: UIImageView!
    
    var toRGBA : STDepthToRgba?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        STSensorController.shared().delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.appDidBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    func appDidBecomeActive() {
        if STSensorController.shared().isConnected() {
            tryStartStreaming()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if tryInitializeSensor() && STSensorController.shared().isConnected() {
            tryStartStreaming()
        } else {
            statusLabel.text = "Disconnected"
        }
    }
    
    func tryInitializeSensor() -> Bool {
        let result = STSensorController.shared().initializeSensorConnection()
        if result == .alreadyInitialized || result == .success {
            return true
        }
        return false
    }
    
    @discardableResult
    func tryStartStreaming() -> Bool {
        if tryInitializeSensor() {
            let options : [AnyHashable: Any] = [
                kSTStreamConfigKey: NSNumber(value: STStreamConfig.depth640x480.rawValue as Int),
                kSTFrameSyncConfigKey: NSNumber(value: STFrameSyncConfig.off.rawValue as Int),
                kSTHoleFilterEnabledKey: true
            ]
            do {
                try STSensorController.shared().startStreaming(options: options as [AnyHashable: Any])
                let toRGBAOptions : [AnyHashable: Any] = [
                    kSTDepthToRgbaStrategyKey : NSNumber(value: STDepthToRgbaStrategy.redToBlueGradient.rawValue as Int)
                ]
                toRGBA = STDepthToRgba(options: toRGBAOptions)
                return true
            } catch let error as NSError {
                print(error)
            }
        }
        return false
    }

    func sensorDidConnect() {
        if tryStartStreaming() {
            statusLabel.text = "Streaming"
        } else {
            statusLabel.text = "Connected"
        }
    }
    
    func sensorDidDisconnect()
    {
        statusLabel.text = "Disconnected"
    }
    
    func sensorDidStopStreaming(_ reason: STSensorControllerDidStopStreamingReason)
    {
        statusLabel.text = "Stopped Streaming"
    }
    
    func sensorDidLeaveLowPowerMode() {}
    
    func sensorBatteryNeedsCharging()
    {
        statusLabel.text = "Low Battery"
    }
    
    func sensorDidOutputDepthFrame(_ depthFrame: STDepthFrame!) {
        if let renderer = toRGBA {
            statusLabel.text = "Showing Depth \(depthFrame.width)x\(depthFrame.height)"
            let pixels = renderer.convertDepthFrame(toRgba: depthFrame)
            depthView.image = imageFromPixels(pixels!, width: Int(renderer.width), height: Int(renderer.height))
        }
    }
    
    func imageFromPixels(_ pixels : UnsafeMutablePointer<UInt8>, width: Int, height: Int) -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue))
        
        //Source of data for bitmap
        let provider = CGDataProvider(data: Data(bytes: UnsafePointer<UInt8>(pixels), count: width*height*4) as CFData)
        
        let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 8 * 4,
            bytesPerRow: width * 4,
            space: colorSpace,       //Quartz color space
            bitmapInfo: bitmapInfo,
            provider: provider!,
            decode: nil,
            shouldInterpolate: false,
            intent: CGColorRenderingIntent.defaultIntent);
        
        return UIImage(cgImage: image!)
    }
}

