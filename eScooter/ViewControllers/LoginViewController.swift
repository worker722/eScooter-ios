//
//  LoginViewController.swift
//  eScooter
//
//  Created by Dove on 05/12/2020.
//  Copyright © 2020 Dove. All rights reserved.
//

import UIKit

class LoginViewController: BaseViewController {
    
    @IBOutlet weak var edt_name: CustomTextField!
    @IBOutlet weak var edt_pwd: CustomTextField!
    @IBOutlet weak var edt_sn: CustomTextField!
    @IBOutlet weak var lbl_register: UILabel!
    public var isMoveByKeyboard = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lbl_register.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.register)))
        NotificationCenter.default.addObserver(self, selector: #selector(CustomServiceViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CustomServiceViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        self.edt_name.delegate = self
        self.edt_pwd.delegate = self
        self.edt_sn.delegate = self
        if(Utils.debugging){
            edt_name.text = "test"
            edt_pwd.text="test"
            edt_sn.text = "TN2020P117A001"
//            self.btnLogin(self)
        }
    }
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
           return
        }
        if(isMoveByKeyboard){
            self.view.frame.origin.y = 100 - keyboardSize.height
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
      self.view.frame.origin.y = 0
    }
    @objc func register() {
       if let url = URL(string: "https://www.terasys-network.com/index.php/shop/user") {
           UIApplication.shared.open(url)
       }
    }
    @IBAction func btnLogin(_ sender: Any) {
        let username = self.edt_name.text!
        let password = self.edt_pwd.text!
        let serial_number = self.edt_sn.text!
        if(username.isEmpty){
            self.showToast(title: "Warning", body: NSLocalizedString("login_empty_name", comment: ""))
            return
        }
        if(password.isEmpty){
            self.showToast(title: "Warning", body: NSLocalizedString("login_empty_pwd", comment: ""))
            return
        }
        if(serial_number.isEmpty){
            self.showToast(title: "Warning", body: NSLocalizedString("login_empty_sn", comment: ""))
            return
        }
        self.showLoading()

        let user: [String: Any] = [
            "username" : username,
            "password": password
        ]
        ApiService.login(params: user) { (result) -> () in
            if(result["code"] as? String == "200") {
                let userid = result["id"] as! String
                ApiService.checkSN(serial_number:serial_number, userid:userid ) { (sn_result) -> () in
                    self.dismissLoading()
                    if((sn_result["success"] as? Bool) == true){
                        DispatchQueue.main.async(execute: {
                            UserDefaults.standard.set(true, forKey: "status")
                            UserDefaults.standard.set(username, forKey: "username")
                            UserDefaults.standard.set(serial_number, forKey: "serial_number")
                            UserDefaults.standard.set(result["auth"] as! String, forKey: "token")
                            UserDefaults.standard.set(userid, forKey: "userid")
                            Switcher.updateRootVC()
                        })
                    }else{
                        self.showToast(title: "Error", body: NSLocalizedString("wrong_serial_number", comment: ""))
                        self.dismissLoading()
                        return;
                    }
                }
            }else{
                if(result["message"] as? String != nil){
                    self.showToast(title: "Error", body: (result["message"] as! String))
                }else{
                    self.showToast(title: "Error", body: NSLocalizedString("request_error", comment: ""))
                }
                self.dismissLoading()
                return;
            }
        }
    }
}

extension LoginViewController:UITextFieldDelegate{
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.isMoveByKeyboard = false
        if(textField == edt_sn){
            self.isMoveByKeyboard = true
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
     func textFieldDidEndEditing(_ textField: UITextField) {
        self.isMoveByKeyboard = false
     }
}
