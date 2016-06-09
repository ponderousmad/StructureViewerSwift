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
        
        STSensorController.sharedController().delegate = self
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.appDidBecomeActive), name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    func appDidBecomeActive() {
        if STSensorController.sharedController().isConnected() {
            tryStartStreaming()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        if tryInitializeSensor() && STSensorController.sharedController().isConnected() {
            tryStartStreaming()
        } else {
            statusLabel.text = "Disconnected"
        }
    }
    
    func tryInitializeSensor() -> Bool {
        let result = STSensorController.sharedController().initializeSensorConnection()
        if result == .AlreadyInitialized || result == .Success {
            return true
        }
        return false
    }
    
    func tryStartStreaming() -> Bool {
        if tryInitializeSensor() {
            let options : [NSObject : AnyObject] = [
                kSTStreamConfigKey: NSNumber(integer: STStreamConfig.Depth640x480.rawValue),
                kSTFrameSyncConfigKey: NSNumber(integer: STFrameSyncConfig.Off.rawValue),
                kSTHoleFilterConfigKey: true
            ]
            do {
                try STSensorController.sharedController().startStreamingWithOptions(options as [NSObject : AnyObject])
                let toRGBAOptions : [NSObject : AnyObject] = [
                    kSTDepthToRgbaStrategyKey : NSNumber(integer: STDepthToRgbaStrategy.RedToBlueGradient.rawValue)
                ]
                try toRGBA = STDepthToRgba(options: toRGBAOptions)
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
    
    func sensorDidStopStreaming(reason: STSensorControllerDidStopStreamingReason)
    {
        statusLabel.text = "Stopped Streaming"
    }
    
    func sensorDidLeaveLowPowerMode() {}
    
    func sensorBatteryNeedsCharging()
    {
        statusLabel.text = "Low Battery"
    }
    
    func sensorDidOutputDepthFrame(depthFrame: STDepthFrame!) {
        if let renderer = toRGBA {
            statusLabel.text = "Showing Depth \(depthFrame.width)x\(depthFrame.height)"
            let pixels = renderer.convertDepthFrameToRgba(depthFrame)
            depthView.image = imageFromPixels(pixels, width: Int(renderer.width), height: Int(renderer.height))
        }
    }
    
    func imageFromPixels(pixels : UnsafeMutablePointer<UInt8>, width: Int, height: Int) -> UIImage? {
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        let bitmapInfo = CGBitmapInfo.ByteOrder32Big.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.NoneSkipLast.rawValue))
        
        let provider = CGDataProviderCreateWithCFData(NSData(bytes:pixels, length: width*height*4))
        
        let image = CGImageCreate(
            width,                       //width
            height,                      //height
            8,                           //bits per component
            8 * 4,                       //bits per pixel
            width * 4,                   //bytes per row
            colorSpace,                  //Quartz color space
            bitmapInfo,                  //Bitmap info (alpha channel?, order, etc)
            provider,                    //Source of data for bitmap
            nil,                         //decode
            false,                       //pixel interpolation
            CGColorRenderingIntent.RenderingIntentDefault);     //rendering intent
        
        return UIImage(CGImage: image!)
    }
}

