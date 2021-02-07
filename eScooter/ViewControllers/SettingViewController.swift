//
//  SettingViewController.swift
//  eScooter
//
//  Created by Dove on 02/12/2020.
//  Copyright © 2020 Dove. All rights reserved.
//

import UIKit

class SettingViewController: BaseViewController {

    @IBOutlet weak var view_diagnostics: UIView!
    @IBOutlet weak var ic_diagnostics: UIImageView!
    @IBOutlet weak var seg_startup: UISegmentedControl!
    @IBOutlet weak var view_cruise: UIView!
    @IBOutlet weak var img_cruise: UIImageView!
    @IBOutlet weak var ic_cruise: UIImageView!
    @IBOutlet weak var view_switch_walk: UIView!
    @IBOutlet weak var ic_switch_walk: UIImageView!
    @IBOutlet weak var img_km: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        view_cruise.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.changeCruise)))
        view_switch_walk.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.changeWalkMode)))
        view_diagnostics.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.selfDiagnostics)))
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        super.touchesBegan(touches, with:event)
       if let touch = touches.first {
        print("touch")
        switch touch.view {
            case self.view_diagnostics:
                self.ic_diagnostics.setAssetImage(name:"ic_diagnostics_touch")
            case self.view_cruise:
                self.ic_cruise.setAssetImage(name:"ic_cruise_touch")
                self.img_cruise.setAssetImage(name: Utils.mScooterInfo.cruiseOn ? "ic_switch_on_touch":"ic_switch_off_touch")
            case self.view_switch_walk:
                self.ic_switch_walk.setAssetImage(name:"ic_switch_touch")
                self.img_km.setAssetImage(name: Utils.mScooterInfo.speedKM ? "ic_switch_kmh_touch":"ic_switch_mph_touch")
            default:
                break
        }
       }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?){
        super.touchesCancelled(touches, with:event)
        self.touchesEnded(touches, with:event)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?){
       if let touch = touches.first{
        print("end")
        switch touch.view {
            case self.view_diagnostics:
                self.ic_diagnostics.setAssetImage(name:"ic_diagnostics_nor")
            case self.view_cruise:
                self.ic_cruise.setAssetImage(name:"ic_cruise_nor")
                self.img_cruise.setAssetImage(name: Utils.mScooterInfo.cruiseOn ? "ic_switch_on_nor":"ic_switch_off_nor")
            case self.view_switch_walk:
                self.ic_switch_walk.setAssetImage(name:"ic_switch_nor")
                self.img_km.setAssetImage(name: Utils.mScooterInfo.speedKM ? "ic_switch_kmh_nor":"ic_switch_mph_nor")
            default:
                break
        }
       }
        super.touchesEnded(touches, with: event)
    }
    @objc func changeCruise(){
        let cruiseOn = Utils.mScooterInfo.cruiseOn
        var cmd:String? = nil
        if(cruiseOn){
            cmd = "CONSTANT_SPEED_OFF"
        } else{
            cmd = "CONSTANT_SPEED_ON"
        }
        if(cmd == nil || cmd?.isEmpty == true){
            return
        }
        sendData(command: cmd!)
    }
    @objc func changeWalkMode(){
        let speedKM = Utils.mScooterInfo.speedKM
        var cmd:String? = nil
        if(speedKM){
            cmd = "SPEED_MP"
        } else{
            cmd = "SPEED_KM"
        }
        if(cmd == nil || cmd?.isEmpty == true){
            return
        }
        sendData(command: cmd!)
    }
    @objc func selfDiagnostics() {
        let nextViewController = self.storyBoard.instantiateViewController(withIdentifier: "DiagnosticsViewController") as! DiagnosticsViewController
        self.show(nextViewController, sender: self)
    }
    @IBAction func indexChanged(_ sender: Any) {
        switch seg_startup.selectedSegmentIndex
        {
        case 0:
            seg_startup.selectedSegmentIndex = 1
            sendData(command: "START_MODE_NOT_ZERO")
            break
        case 1:
            seg_startup.selectedSegmentIndex = 0
            sendData(command: "START_MODE_ZERO")
            break
        default:
            break
        }
    }
    func didUpdateValues(){
        self.img_cruise.setAssetImage(name: Utils.mScooterInfo.cruiseOn ? "ic_switch_on_nor":"ic_switch_off_nor")
        self.img_km.setAssetImage(name: Utils.mScooterInfo.speedKM ? "ic_switch_kmh_nor":"ic_switch_mph_nor")
        seg_startup.selectedSegmentIndex = (Utils.mScooterInfo.zeroStart ? 1 : 0)
    }

    	
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
