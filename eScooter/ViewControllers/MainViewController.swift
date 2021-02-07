//
//  MainViewController.swift
//  eScooter
//
//  Created by Dove on 02/12/2020.
//  Copyright © 2020 Dove. All rights reserved.
//

import UIKit
import os
import CoreBluetooth
class MainViewController: BaseViewController {
    @IBOutlet weak var lbl_speed: UILabel!
    @IBOutlet weak var lbl_battery: UILabel!
    @IBOutlet weak var img_battery: UIImageView!
    @IBOutlet weak var lbl_remain: UILabel!
    @IBOutlet weak var img_mode: UIImageView!
    @IBOutlet weak var lbl_trip: UILabel!
    @IBOutlet weak var lbl_odo: UILabel!
    @IBOutlet weak var btn_lock: UIButton!
    @IBOutlet weak var img_pointer: UIImageView!
    @IBOutlet weak var btn_navigation: UIButton!
    @IBOutlet weak var btn_mode: UIButton!
    @IBAction func btn_mode_down(_ sender: Any) {
        self.btn_mode.setAssetImage(name: "ic_mode_touch")
    }
    @IBAction func btn_mode_up(_ sender: Any) {
        self.btn_mode.setAssetImage(name: "ic_mode_nor")
        self.changeMode()
    }
    @IBAction func btn_lock_down(_ sender: Any) {
        self.btn_lock.setAssetImage(name: Utils.mScooterInfo.locked ? "ic_lock_touch" : "ic_unlock_touch")
    }
    @IBAction func btn_lock_up(_ sender: Any) {
        self.btn_lock.setAssetImage(name: Utils.mScooterInfo.locked ? "ic_lock_nor" : "ic_unlock_nor")
        self.changeLock()
    }
    @IBAction func btn_navigation_down(_ sender: Any) {
        self.btn_navigation.setAssetImage(name: "ic_arrow_down_touch")
    }
    @IBAction func btn_navigation_up(_ sender: Any) {
        self.btn_navigation.setAssetImage(name: "ic_arrow_down_nor")
        self.goNavigation()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.btn_mode.imageView?.contentMode = .scaleAspectFit
        self.btn_lock.imageView?.contentMode = .scaleAspectFit
        self.btn_navigation.imageView?.contentMode = .scaleAspectFit
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.checkConnection()
    }
    @objc func goNavigation(){
        let nextViewController = self.storyBoard.instantiateViewController(withIdentifier: "NavigationViewcontroller") as! NavigationViewcontroller
        nextViewController.modalPresentationStyle = .fullScreen

        DispatchQueue.main.async {
           self.view.layer.add(CATransition().segueFromTop(), forKey: nil)
           self.present(nextViewController, animated: false, completion: nil)
        }

    }
    @objc func changeMode(){
        let mode = Utils.mScooterInfo.speedMode
        var cmd:String? = nil
        if(mode == 1){
            cmd = "GEAR_D1"
        }
        else if(mode == 2){
            cmd = "GEAR_D2"
        }
        else if(mode == 3){
            cmd = "GEAR_D3"
        }
        if(cmd == nil || cmd?.isEmpty == true){
            return
        }
        sendData(command: cmd!)
    }
    @objc func changeLock(){
        let locked = Utils.mScooterInfo.locked
        var cmd:String? = nil
        if(locked){
            cmd = "UNLOCK"
        }
        else{
            cmd = "LOCK"
        }
        if(cmd == nil || cmd?.isEmpty == true){
            return
        }
        sendData(command: cmd!)
    }
    func setSpeed(speed: Float){
        self.lbl_speed.text = String(format:"%.1f", speed)
        let max:Float = 286
        let step:Float = 30
//        let angle = max / 30 * speed;
        let angle = (max / step * speed) * .pi / 180;
        self.img_pointer.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
//        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveLinear, animations: {
//            let radians = atan2(self.img_pointer.transform.b, self.img_pointer.transform.a)
//            self.img_pointer.transform = self.img_pointer.transform.rotated(by: (CGFloat(angle) - radians))
//        })
//        self.img_pointer.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
    }
    func setBattery(battery: Int){
        var battery = battery
        if(battery < 0){
            battery = 0
        }
        if(battery > 100){
            battery = 100
        }
        
        self.lbl_battery.text = String(battery)+"%"
        var battery_image:String!
        if (battery == 0) {
            battery_image = "ic_battery_0"
        }
        else if (battery <= 20) {
            battery_image = "ic_battery_20"
        }
        else if (battery <= 40) {
            battery_image = "ic_battery_40"
        }
        else if (battery <= 60) {
            battery_image = "ic_battery_60"
        }
        else if (battery <= 80) {
            battery_image = "ic_battery_80"
        }
        else if (battery <= 100) {
            battery_image = "ic_battery_100"
        }

        self.img_battery.image = UIImage(named: battery_image)
        self.lbl_remain.text = String(Float(battery)*20/100)
    }
    func setMode(mode:Int){
        var mode_image:String!
        if(mode == 1){
            mode_image = "ic_mode1_nor"
        }else if(mode == 2){
            mode_image = "ic_mode2_nor"
        }else if(mode == 3){
            mode_image = "ic_mode3_nor"
        }
        self.img_mode.image = UIImage(named: mode_image)
    }
    func setLock(){
        if(Utils.mScooterInfo.locked){
            self.btn_lock.setImage(UIImage(named: "ic_lock_nor"), for:.normal)
        }else{
            self.btn_lock.setImage(UIImage(named: "ic_unlock_nor"), for:.normal)
        }
    }
    func didUpdateValues(){
        self.lbl_trip.text = String(format:"%.2f", Utils.mScooterInfo.trip)
        self.lbl_odo.text = String(format:"%.2f", Utils.mScooterInfo.odo)
        self.setSpeed(speed: Utils.mScooterInfo.speed)
        self.setBattery(battery: Utils.mScooterInfo.battery)
        self.setMode(mode:Utils.mScooterInfo.speedMode)
        self.setLock()
    }
}
