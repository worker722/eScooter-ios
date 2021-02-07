//
//  ProfileViewController.swift
//  eScooter
//
//  Created by Dove on 05/12/2020.
//  Copyright © 2020 Dove. All rights reserved.
//

import UIKit

class ProfileViewController: BaseViewController {
    var imagePicker: ImagePicker!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var edt_name: CustomTextField!
    @IBOutlet weak var edt_street: CustomTextField!
    @IBOutlet weak var edt_zip: CustomTextField!
    @IBOutlet weak var edt_town: CustomTextField!
    @IBOutlet weak var edt_sn: CustomTextField!
    @IBOutlet weak var edt_odo: CustomTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        self.imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.showImagePicker)))
        
        self.edt_odo.text = String(format:"%.2f", Utils.mScooterInfo.odo)
        self.getInfo()
    }
    override func viewWillDisappear(_ animated: Bool) {
        MoreViewController.mViewController?.getInfo()
    }
    @objc func showImagePicker() {
        self.imagePicker.present(from: imageView.self)
    }
    func getInfo(){
        ApiService.getUserInfo() {(result) in
            if((result["success"] as? Bool) == true){
                DispatchQueue.main.async(execute: {
                    self.edt_name.text = result["name"] as? String
                    self.edt_street.text = result["street"] as? String
                    self.edt_zip.text = result["zip"] as? String
                    self.edt_town.text = result["town"] as? String
                    self.edt_sn.text = UserDefaults.standard.string(forKey: "serial_number")

                    guard let avatar = result["avatar"] as? String else { return }
                    
                    if let cachedImage = ImageCache.shared.image(forKey: avatar) {
                        self.imageView.image = cachedImage
                        return
                    }
                    
                    ApiService.getImage(url: avatar) {(result) in
                        DispatchQueue.main.async(execute: {
                            self.imageView.image = result
                            ImageCache.shared.save(image: result , forKey: avatar)
                        })
                    }
                })
            }
        }
    }
    @IBAction func Logout(_ sender: Any) {
        UserDefaults.standard.set(false, forKey: "status")
        Switcher.updateRootVC()
    }
}
extension ProfileViewController: ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        if(image == nil){
            return
        }
        self.imageView.image = image

        ApiService.uploadAvatar(image:image!) { (result) -> () in
            if(result["success"] as! Bool == true){
                self.showToast(body: NSLocalizedString("upload_success", comment: ""))
                guard let avatar:String = result["url"] as? String else{return}
                ImageCache.shared.save(image: image!, forKey: avatar)
            }else{
                self.showToast(body: NSLocalizedString("upload_failed", comment: ""))
            }
        }
    }
    
    func didUpdateValues(){
        self.edt_odo.text = String(format:"%.2f", Utils.mScooterInfo.odo)
    }
}
