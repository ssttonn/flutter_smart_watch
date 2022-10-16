//
//  InterfaceController.swift
//  TestWatchOS WatchKit Extension
//
//  Created by sstonn on 01/10/2022.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController {
    @IBOutlet weak var image: WKInterfaceImage!
    var watchSession: WCSession?
    
    override func awake(withContext context: Any?) {
        watchSession = WCSession.default
        watchSession?.delegate = self
        watchSession?.activate()
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
    }
    
}

extension InterfaceController: WCSessionDelegate{
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        
    }
    
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        try! watchSession?.updateApplicationContext(fileTransfer.file.metadata!)
//        if let data = try? Data(contentsOf: fileTransfer.file.fileURL){
//            image.setImage(UIImage(data: data))
//        }
    }
    
}
