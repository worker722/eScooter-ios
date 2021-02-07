//
//  MoreViewController.swift
//  eScooter
//
//  Created by Dove on 02/12/2020.
//  Copyright © 2020 Dove. All rights reserved.
//

import UIKit
//BaseViewController
class MoreViewController: BaseViewController{

    @IBOutlet weak var view_about: UIView!
    @IBOutlet weak var ic_about: UIImageView!
    
    @IBOutlet weak var view_service: UIView!
    @IBOutlet weak var ic_service: UIImageView!
    
    @IBOutlet weak var view_version: UIView!
    @IBOutlet weak var ic_version: UIImageView!
    
    @IBOutlet weak var lbl_trip: UILabel!
    @IBOutlet weak var lbl_top_speed: UILabel!
    @IBOutlet weak var img_avatar: UIImageView!
    @IBOutlet weak var lbl_username: UILabel!
    @IBOutlet weak var img_profile: UIImageView!
    public static var mViewController:MoreViewController?
    override func viewDidLoad() {
        super.viewDidLoad()
        MoreViewController.mViewController = self
        view_about.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.goAboutPage)))
        img_profile.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.goProfilePage)))
        view_service.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.goServicePage)))
        view_version.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.goVersionPage)))
        UIGraphicsBeginImageContextWithOptions(self.img_avatar.intrinsicContentSize, false, 0)
        self.getInfo()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
       if let touch = touches.first {
        switch touch.view {
            case self.view_service:
                self.ic_service.setAssetImage(name:"ic_services_touch")
            case self.view_about:
                self.ic_about.setAssetImage(name:"ic_about_touch")
            case self.view_version:
                self.ic_version.setAssetImage(name:"ic_version_touch")
            default:
                break
        }
       }
        super.touchesBegan(touches, with:event)
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?){
        super.touchesCancelled(touches, with:event)
        self.touchesEnded(touches, with:event)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?){
       if let touch = touches.first{
        switch touch.view {
            case self.view_service:
                self.ic_service.setAssetImage(name:"ic_services_nor")
            case self.view_about:
                self.ic_about.setAssetImage(name:"ic_about_nor")
            case self.view_version:
                self.ic_version.setAssetImage(name:"ic_version_nor")
            default:
                break
        }
       }
        super.touchesEnded(touches, with: event)
    }
    func getInfo(){
        ApiService.getUserInfo() {(result) in
            if((result["success"] as? Bool) == true){
                DispatchQueue.main.async(execute: {
                    self.lbl_username.text = result["name"] as? String
                
                    guard let avatar = result["avatar"] as? String else { return }

                    if let cachedImage = ImageCache.shared.image(forKey: avatar) {
                        self.img_avatar.image = cachedImage
                        return
                    }
                    ApiService.getImage(url: avatar) {(result) in
                        DispatchQueue.main.async(execute: {
                            self.img_avatar.image = result
                            ImageCache.shared.save(image: result, forKey: avatar)
                        })
                    }
                });
            }
        }
    }
    @objc func goAboutPage() {
        let nextViewController = self.storyBoard.instantiateViewController(withIdentifier: "AboutViewController") as! AboutViewController
        self.show(nextViewController, sender: self)
    }
    @objc func goProfilePage() {
        let nextViewController = self.storyBoard.instantiateViewController(withIdentifier: "ProfileViewController") as! ProfileViewController
        self.show(nextViewController, sender: self)
    }
    @objc func goServicePage() {
        let nextViewController = self.storyBoard.instantiateViewController(withIdentifier: "CustomServiceViewController") as! CustomServiceViewController
        self.show(nextViewController, sender: self)
    }
    @objc func goVersionPage() {
        let nextViewController = self.storyBoard.instantiateViewController(withIdentifier: "VersionViewController") as! VersionViewController
        self.show(nextViewController, sender: self)
    }
    func didUpdateValues(){
        self.lbl_trip.text = String(format:"%.2f", Utils.mScooterInfo.trip)
        self.lbl_top_speed.text = String(format: "%.1f", UserDefaults.standard.float(forKey: "MaxSpeed") )
    }
}

class AboutViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
class CustomServiceViewController: BaseViewController {
    @IBOutlet weak var edt_email_to: CustomTextField!
    @IBOutlet weak var edt_username: CustomTextField!
    @IBOutlet weak var edt_subject: CustomTextField!
    @IBOutlet weak var edt_message: CustomTextField!
    private var isMoveByKeyboard = false
    override func viewDidLoad() {
        super.viewDidLoad()
        edt_message.delegate = self        
        edt_username.text = UserDefaults.standard.string(forKey: "username")
        NotificationCenter.default.addObserver(self, selector: #selector(CustomServiceViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CustomServiceViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    @objc func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
           return
        }
        if(isMoveByKeyboard){
            self.view.frame.origin.y = 60 - keyboardSize.height
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
      self.view.frame.origin.y = 0
    }
    @IBAction func on_send(_ sender: Any) {
        let username:String? = edt_username.text
        let subject:String? =  edt_subject.text
        let message:String? = edt_message.text
        if(username?.isEmpty == true){
            self.showToast(title: "Warning", body: NSLocalizedString("login_empty_name", comment: ""))
            return
        }
        if(subject?.isEmpty == true || message?.isEmpty == true){
            self.showToast(title: "Warning", body: NSLocalizedString("invalid_message", comment: ""))
            return
        }
        let data:[String: Any]! = ["username":username!, "subject":subject!, "message":message!]
        ApiService.sendCustomService(params:data){ (result) in
            print(result)
            if((result["success"] as? Bool) == true){
                self.showToast(title: "Success", body: NSLocalizedString("success_message", comment: ""))
                self.goBack()
            }else{
                self.showToast(title: "Error", body: NSLocalizedString("request_error", comment: ""))
            }
        }
    }
}
extension CustomServiceViewController:UITextFieldDelegate{
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if(textField == edt_message){
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
class VersionViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
