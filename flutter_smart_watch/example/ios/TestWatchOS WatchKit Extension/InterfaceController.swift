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
    
    @IBAction func onButtonPressed() {
        if let path = Bundle.main.path(forResource: "download", ofType: "jpeg"){
            let fileUrl = NSURL.fileURL(withPath: path)
            self.watchSession?.transferFile(fileUrl, metadata: ["count": 1])
        }
       
    }
}

extension InterfaceController: WCSessionDelegate{
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        
    }
    
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        try! watchSession?.updateApplicationContext(fileTransfer.file.metadata!)
       
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        var tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
        tempURL.appendPathComponent(file.fileURL.lastPathComponent)
        do {
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(atPath: tempURL.path)
            }
            try FileManager.default.moveItem(atPath: file.fileURL.path, toPath: tempURL.path)
            if let data = try? Data(contentsOf: tempURL){
                image.setImage(UIImage(data: data))
            }
        } catch {
            
        }
    }
    
}
