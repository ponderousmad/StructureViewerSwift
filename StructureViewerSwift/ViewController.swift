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

    func sensorDidConnect() {}
    func sensorDidDisconnect() {}
    func sensorDidStopStreaming(reason: STSensorControllerDidStopStreamingReason) {}
    func sensorDidLeaveLowPowerMode() {}
    func sensorBatteryNeedsCharging() {}
}

