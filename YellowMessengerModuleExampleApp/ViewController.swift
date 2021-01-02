//
//  ViewController.swift
//  YellowMessengerModuleExampleApp
//
//  Created by G Srinivasa on 02/01/21.
//  Copyright © 2021 G Srinivasa. All rights reserved.
//

import UIKit
import YellowMessengerModule

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    @IBAction func onInvokeYM(_ sender: UIButton) {
        YellowMessengerModule.intializeYM(userID: "x1607601182827", accessToken: "abcd", refreshToken: "abcd", mobileNumber: "9845473370", journalSlug: "abcd", userState: "abcd")
        YellowMessengerModule.invokeChatBot()
    }
}

