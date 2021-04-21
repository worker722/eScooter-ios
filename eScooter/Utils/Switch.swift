//
//  Switch.swift
//  eScooter
//
//  Created by Dove on 05/12/2020.
//  Copyright © 2020 Dove. All rights reserved.
//

import Foundation
import UIKit

class Switcher {
    static func updateRootVC(){
        let status = UserDefaults.standard.bool(forKey: "status")
        var rootVC : UIViewController?
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if(status == true){
            if(Utils.connectedDevice == nil){
                rootVC = storyboard.instantiateViewController(withIdentifier: "BluetoothViewController") as! BluetoothViewController
            }else{
            rootVC = storyboard.instantiateViewController(withIdentifier: "UITabBarController") as! UITabBarController
            }
        }else{
            rootVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.window?.rootViewController = rootVC
        UIApplication.shared.keyWindow?.rootViewController = rootVC
        
    }
    
}
