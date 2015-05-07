//
//  ViewController.swift
//  StructureViewerSwift
//
//  Created by Adrian Smith on 2015-05-06.
//  Copyright (c) 2015 Adrian Smith. All rights reserved.
//

import UIKit

class ViewController: UIViewController, STSensorControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        STSensorController.sharedController().delegate = self
        
        if STSensorController.sharedController().isConnected() {
            tryStartStreaming()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            var error : NSError? = nil
            if STSensorController.sharedController().startStreamingWithOptions(options as [NSObject : AnyObject], error: &error) {
                return true
            }
        }
        return false
    }

    func sensorDidConnect() {
        tryStartStreaming()
    }
    
    func sensorDidDisconnect() {}
    func sensorDidStopStreaming(reason: STSensorControllerDidStopStreamingReason) {}
    func sensorDidLeaveLowPowerMode() {}
    func sensorBatteryNeedsCharging() {}
}

