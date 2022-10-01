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
    @IBOutlet weak var counterLabel: WKInterfaceLabel!
    private var watchSession: WCSession?
    
    private var count: Int = 0
    
    override func awake(withContext context: Any?) {
        // Configure interface objects here.
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

  
    @IBAction func onIncreased() {
        print("Increase")
        count += 1
        counterLabel.setText(String(count))
        if watchSession != nil && watchSession!.isReachable{
            watchSession?.sendMessage(["count": count], replyHandler: nil)
        }
    }
    
    @IBAction func onDecreased() {
        print("Decrease")
        count -= 1
        counterLabel.setText(String(count))
        if watchSession != nil && watchSession!.isReachable{
            watchSession?.sendMessage(["count": count], replyHandler: nil)
        }
    }
}

extension InterfaceController: WCSessionDelegate{
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let currentCount = message["count"] as? Int{
            count = currentCount
            counterLabel.setText(String(currentCount))
        }
    }
}
