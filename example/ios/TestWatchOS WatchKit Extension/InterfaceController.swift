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
    @IBOutlet weak var optionPicker: WKInterfacePicker!
    @IBOutlet weak var counterLabel: WKInterfaceLabel!
    private var watchSession: WCSession?
    var itemTitles: [String] = ["Message", "Application Context", "User Info"]
    var pickedItem: WKPickerItem? = nil
    private var count: Int = 0
    
    override func awake(withContext context: Any?) {
        // Configure interface objects here.
        let pickerItems = itemTitles.map{ title -> WKPickerItem in
            let pickerItem = WKPickerItem()
            pickerItem.title = title
            return pickerItem
        }
        pickedItem = pickerItems.first
        optionPicker.setItems(pickerItems)
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
        sendCount()
    }
    
    @IBAction func onDecreased() {
        print("Decrease")
        count -= 1
        counterLabel.setText(String(count))
        sendCount()
    }
    
    func sendCount(){
        guard watchSession != nil else {
            return
        }
     
            var currentContext = watchSession?.applicationContext ?? [:]
            currentContext["count"] = count
            do{
                try watchSession?.updateApplicationContext(currentContext)
            }catch{
                print(error.localizedDescription)
            }
        
    }
}

extension InterfaceController: WCSessionDelegate{
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == WCSessionActivationState.activated{
            if let currentCount = session.receivedApplicationContext["count"] as? Int{
                count = currentCount
                counterLabel.setText(String(currentCount))
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let currentCount = message["count"] as? Int{
            count = currentCount
            counterLabel.setText(String(currentCount))
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let currentCount = message["count"] as? Int{
            count = currentCount
            counterLabel.setText(String(currentCount))
        }
        replyHandler(["state": true])
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let currentCount = applicationContext["count"] as? Int{
            count = currentCount
            counterLabel.setText(String(currentCount))
        }
    }
}
