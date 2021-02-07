//
//  DiagnosticsViewController.swift
//  eScooter
//
//  Created by Dove on 05/12/2020.
//  Copyright © 2020 Dove. All rights reserved.
//

import UIKit
import CoreBluetooth

class DiagnosticsViewController: BaseViewController {

    @IBOutlet weak var img_checking: UIImageView!
    @IBOutlet weak var lbl_percentage: UILabel!
    
    @IBOutlet weak var view_check1: UIView!
    @IBOutlet weak var view_check2: UIView!
    @IBOutlet weak var view_check3: UIView!
    @IBOutlet weak var view_check4: UIView!
    @IBOutlet weak var view_check5: UIView!
    
    @IBOutlet weak var lbl_check1: UILabel!
    @IBOutlet weak var lbl_check2: UILabel!
    @IBOutlet weak var lbl_check3: UILabel!
    @IBOutlet weak var lbl_check4: UILabel!
    @IBOutlet weak var lbl_check5: UILabel!
   
    @IBOutlet weak var img_check1: UIImageView!
    @IBOutlet weak var img_check2: UIImageView!
    @IBOutlet weak var img_check3: UIImageView!
    @IBOutlet weak var img_check4: UIImageView!
    @IBOutlet weak var img_check5: UIImageView!

    @IBOutlet weak var img_check_err1: UIImageView!
    @IBOutlet weak var img_check_err2: UIImageView!
    @IBOutlet weak var img_check_err3: UIImageView!
    @IBOutlet weak var img_check_err4: UIImageView!
    @IBOutlet weak var img_check_err5: UIImageView!

    @IBOutlet weak var img_loading1: UIImageView!
    @IBOutlet weak var img_loading2: UIImageView!
    @IBOutlet weak var img_loading3: UIImageView!
    @IBOutlet weak var img_loading4: UIImageView!
    @IBOutlet weak var img_loading5: UIImageView!
    
    private var checking:[Int]!//checking 0:checking, 1:true, 2:false
    private var tmp_checking:[Bool]!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.initview()
        lbl_percentage.isHidden = true
    }
    private func initview(hidden:Bool = true){
        for index in 0...4 {
            self.getElement(index: index, type: 0).isHidden = hidden
        }
    }
    private func totalchecking(value:Int) ->Bool {
        for item in self.checking {
            if(item == value){
                return true
            }
        }
        return false
    }
    private func rotateView(targetView: UIView, index:Int, duration: Double = 0.5) {
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveLinear, animations: {
            targetView.transform = targetView.transform.rotated(by: CGFloat(Double.pi))
        }) { finished in
            if((index == -1 && self.totalchecking(value: 0)) ||
                (index >= 0 && self.checking[index] == 0)) {
                self.rotateView(targetView: targetView, index: index, duration: duration)
            }
        }
    }
    private func getElement(index:Int, type:Int) -> UIView { //type: 0-> view_check, 1:lbl_check, 2:img_check, 3:img_check_error, 4:img_loading
        let views = [
            [view_check1, view_check2, view_check3, view_check4, view_check5],
            [lbl_check1, lbl_check2, lbl_check3, lbl_check4, lbl_check5],
            [img_check1, img_check2, img_check3, img_check4, img_check5],
            [img_check_err1, img_check_err2, img_check_err3, img_check_err4, img_check_err5],
            [img_loading1, img_loading2, img_loading3, img_loading4, img_loading5]
        ]
        return views[type][index]!
    }
    @IBAction func startCheck(_ sender: Any) {
        updated_value = false
        checkingDevice(init_type: 0)
        sendData(command: "SELF_CHECK")
        self.rotateView(targetView: self.img_checking, index: -1)
        for index in 0...4 {
            self.rotateView(targetView: self.getElement(index: index, type: 4), index: index)
        }
        self.didUpdateValues()
        
    }
    func checkingDevice(car_type:Int  = 1, init_type:Int){ //init_type: 0-> start, 1:update
        let text = [
            ["scooter throttle", "brake", "hall sensor", "car body hardware", "battery"],
            ["car body hardware", "hall sensor", "communication equipment", "battery", "circuit board"]
        ]
        
        if(init_type == 0){
            self.checking = [0, 0, 0, 0, 0]
            self.tmp_checking = [false, false, false, false, false]
        }
        for index in 0...4 {
            if(init_type == 0){
                (self.getElement(index: index, type: 1) as! UILabel).text = NSLocalizedString(text[car_type][index], comment: "")
            }

            self.getElement(index: index, type: 2).isHidden = true
            self.getElement(index: index, type: 3).isHidden = true
            self.getElement(index: index, type: 4).isHidden = true
            
            if(self.checking[index] == 0){
                self.getElement(index: index, type: 4).isHidden = false
            }
            if(self.checking[index] == 1){
                self.getElement(index: index, type: 2).isHidden = false
            }
            if(self.checking[index] == 2){
                self.getElement(index: index, type: 3).isHidden = false
            }
        }
        self.initview(hidden: false)
    }
    public var timer: Timer?
    public var index: Int = 0
    private var updated_value: Bool = false
    func didUpdateValues(){
        if(updated_value == true){
            return
        }
        if(Utils.connectedDevice?.state != CBPeripheralState.connected){
            self.checking = [2, 2, 2, 2, 2]
            self.checkingDevice(init_type: 1)
        }
         updated_value = true
//        let str:String! = Utils.mScooterInfo.selfCheck
//        for i in 0...4 {
//            var z = false
//            if(i >= str.count){
//                z = true
//            }
//            else if(str[i] == "1"){
//                z = true
//            }
//            self.tmp_checking[i] = z
//            self.checking[i] = (z ? 1 : 2)
//            checkingDevice(init_type: 1)
//        }
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 0...3), repeats: true) { timer in
            if(self.totalchecking(value:0) == false){
                self.timer?.invalidate()
                return
            }
//            let time = Double.random(in: 0...3000000.0)
//            usleep(useconds_t(time))
            var number = Int.random(in: 0...4)
            while self.checking[number] != 0 {
                number = Int.random(in: 0...4)
            }
            self.checking[number] = 1
            self.checkingDevice(init_type: 1)
        }
        
    }
}
