//
//  YellowMessengerModule.swift
//  abhic-testing
//
//  Created by Priyank Upadhyay on 24/02/20.
//  Copyright © 2020 Priyank Upadhyay. All rights reserved.
//

import Foundation
import UIKit

public class YellowMessengerModule{
    public static let shared = YellowMessengerModule()
    
    //public static let shared = YellowMessengerModule()
    var configData: [String : String]
    var payloadData: String

    public let events : EventManager
    var window : UIWindow
    public init(){
        self.configData = Dictionary<String, String>()
        self.payloadData = ""
        self.events = EventManager()
        self.window = UIWindow()
    }
    
    public func initPlugin(config : Dictionary<String, String>) {
        self.configData = config
    }
    
    public func startChatBot(view : UIView){
        let chatViewer = ChatController()
        guard let windowScene = view.window?.windowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = chatViewer
        self.window = window
        window.makeKeyAndVisible()
    }
    
    public func stopChatBot(){
        self.window.rootViewController = nil
    }
    
    public func setPayload(payload: Dictionary<String, String>) {
            payloadData = "%7B"
         payload.forEach({ (key: String, value: String) in
            payloadData += "%22\(key)%22:%22\(value)%22,"
        })
        payloadData += "%22Platform%22:%22iOS-App%22%7D"
    }
    
    public static func intializeYM(userID: String, accessToken: String, refreshToken: String, mobileNumber: String, journalSlug: String, userState: String){
        //Set Configuration data
        let config:[String:String] = ["BotId" : userID]
        var sender:UIView = UIView()
        if let topVC = UIApplication.getTopViewController() {
             sender = topVC.view
        }

        //Initialize the plugin with config values.
        YellowMessengerModule.shared.initPlugin(config: config) //Step 1

        //Set EventListener to handle bot events.
        YellowMessengerModule.shared.events.listenTo(eventName: "BotEvent", action: {
            (information:Any?) in
            if let info = information as? Dictionary<String, String> {
                print("Closing Bot")
                //To stop chatbot use the following function
                YellowMessengerModule.shared.stopChatBot() //Step 5
                switch info["code"] {
                case "login-user":
                    //Each event has two keys, "code" and "data". Use info["code"] or info["data"] to access the values
                    //The following code restarts the chatbot with different payload values.
                    let payloads:[String:String] = ["UserState":"LoggedIn"]
                    Self.shared.setPayload(payload: payloads)
                    Self.shared.startChatBot(view: sender)
                //Add other cases acording to need.
                default:
                    print("Unknown Event")
                }
            }
        }) // Step 2
        
        //Setting payload values
        let payloads:[String:String] = ["UserState":userState]

        //Pass payload to the bot
        YellowMessengerModule.shared.setPayload(payload: payloads) //Step 3
    }
    
    public static func invokeChatBot(){
        var sender:UIView = UIView()
        if let topVC = UIApplication.getTopViewController() {
             sender = topVC.view
        }
        //Start the chatbot webview
          YellowMessengerModule.shared.startChatBot(view: sender) //Step 4

    }
    
    public static func openWebView(_ sender: Any) {


         }
       
}


extension UIApplication {

    class func getTopViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {

        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)

        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)

        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
}
