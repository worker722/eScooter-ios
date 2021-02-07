//
//  utils.swift
//  eScooter
//
//  Created by Dove on 06/12/2020.
//  Copyright © 2020 Dove. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit


struct ScooterInfo {
    var speed:Float = 0
    var trip:Float = 0
    var odo:Float = 0
    var battery: Int = 0
    var locked:Bool = false
    var speedKM:Bool = false
    var zeroStart:Bool = false
    var cruiseOn:Bool = false
    var speedMode:Int = 1
    var perNum:Float = 1.0
    var selfCheck:String = ""
}
class Utils {
    public static var centralManager: CBCentralManager!
    public static var timer: Timer?
    public static var connectedDevice: CBPeripheral?
    public static var Command:[String:[UInt8]] = [
        "CONSTANT_SPEED_OFF": [0xFF, 0x55, 0x1D, 0x01, 0x02, 0x74], // CONSTANT_SPEED_OFF
        "CONSTANT_SPEED_ON": [0xFF, 0x55, 0x1D, 0x01, 0x01, 0x73], // CONSTANT_SPEED_ON
        "GEAR_D1": [0xFF, 0x55, 0x1F, 0x01, 0x02, 0x76], // GEAR_D1
        "GEAR_D2": [0xFF, 0x55, 0x1F, 0x01, 0x03, 0x77], // GEAR_D2
        "GEAR_D3": [0xFF, 0x55, 0x1F, 0x01, 0x04, 0x78], // GEAR_D3
        "LOCK": [0xFF, 0x55, 0x17, 0x01, 0x02, 0x6E], // LOCK
        "UNLOCK": [0xFF, 0x55, 0x17, 0x01, 0x01, 0x6D], // UNLOCK
        "SPEED_KM": [0xFF, 0x55, 0x18, 0x01, 0x01, 0x6E], // SPEED_KM
        "SPEED_MP": [0xFF, 0x55, 0x18, 0x01, 0x02, 0x6F], // SPEED_MP
        "START_MODE_NOT_ZERO": [0xFF, 0x55, 0x1A, 0x01, 0x02, 0x71], // START_MODE_NOT_ZERO
        "START_MODE_ZERO": [0xFF, 0x55, 0x1A, 0x01, 0x01, 0x70], // START_MODE_ZERO
        "SELF_CHECK": [0xFF, 0x55, 0x1E, 0x02, 0x00, 0x00, 0x74], // self check
    ]

    public static var payloads: [[UInt8]] = [
        [0xFF, 0x55, 0x01, 0x00, 0x55], // loopRequestStatus
        [0xFF, 0x55, 0x08, 0x00, 0x5c], // timer
    ]

    public static var writeCharacterisitc = CBUUID(string: "00008877-0000-1000-8000-00805f9b34fb")
    public static var readCharacterisitc = CBUUID(string: "00008888-0000-1000-8000-00805f9b34fb")
    
    public static var mScooterInfo = ScooterInfo()
    public static var debugging = false
    public static var mMain:UIViewController!
    public static var mDate:Date!
}
class CustomTextField : UITextField {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        customize()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        customize()
        
    }
    func customize(){
        return
        let border = CALayer()
        let width = CGFloat(2.0)
        border.borderColor = UIColor.darkGray.cgColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - width, width: self.frame.size.width, height: self.frame.size.height)
        border.borderWidth = width
        self.borderStyle = .none
        self.layer.addSublayer(border)
        self.layer.masksToBounds = true
    }
}
protocol Localizable {
    var localized: String { get }
}
extension String: Localizable {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}
protocol XIBLocalizable {
    var xibLocKey: String? { get set }
}
extension UILabel: XIBLocalizable {
    @IBInspectable var xibLocKey: String? {
        get { return nil }
        set(key) {
            text = key?.localized
        }
    }
}
extension UIButton: XIBLocalizable {
    @IBInspectable var xibLocKey: String? {
        get { return nil }
        set(key) {
            setTitle(key?.localized, for: .normal)
        }
   }
}
extension UITextField: XIBLocalizable {
    @IBInspectable var xibLocKey: String? {
        get { return nil }
        set(key) {
            placeholder = key?.localized
        }
   }
}
extension UISegmentedControl: XIBLocalizable {
    @IBInspectable var xibLocKey: String? {
        get { return nil }
        set(key) {
            setTitle("push-start".localized, forSegmentAt: 0)
            setTitle("zero-start".localized, forSegmentAt: 1)
        }
   }
}
extension UIButton{
    func setAssetImage(name:String){
        self.imageView?.contentMode = .scaleAspectFit
        if let image = UIImage(named: name) {
            self.setImage(image, for: .normal)
        }
    }
}
extension UIImageView{
    func setAssetImage(name:String){
        self.contentMode = .scaleAspectFit
        if let image = UIImage(named: name) {
            self.image = image
        }
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
    mutating func appendString(string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
}
extension String {
    subscript(i: Int) -> String {
        return String(self[index(startIndex, offsetBy: i)])
    }
}
extension CATransition {
    //New viewController will appear from bottom of screen.
    func segueFromBottom() -> CATransition {
        self.duration = 1 //set the duration to whatever you'd like.
        self.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        self.type = CATransitionType.moveIn
        self.subtype = CATransitionSubtype.fromTop
        return self
    }
    //New viewController will appear from top of screen.
    func segueFromTop() -> CATransition {
        self.duration = 1 //set the duration to whatever you'd like.
        self.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        self.type = CATransitionType.moveIn
        self.subtype = CATransitionSubtype.fromBottom
        return self
    }
     //New viewController will appear from left side of screen.
    func segueFromLeft() -> CATransition {
        self.duration = 0.1 //set the duration to whatever you'd like.
        self.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        self.type = CATransitionType.moveIn
        self.subtype = CATransitionSubtype.fromLeft
        return self
    }
    //New viewController will pop from right side of screen.
    func popFromTop() -> CATransition {
        self.duration = 1
        self.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        self.type = CATransitionType.reveal
        self.subtype = CATransitionSubtype.fromTop
        return self
    }
    //New viewController will appear from left side of screen.
    func popFromBottom() -> CATransition {
        self.duration = 1 //set the duration to whatever you'd like.
        self.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        self.type = CATransitionType.reveal
        self.subtype = CATransitionSubtype.fromBottom
        return self
    }
    //New viewController will pop from right side of screen.
    func popFromRight() -> CATransition {
        self.duration = 1
        self.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        self.type = CATransitionType.reveal
        self.subtype = CATransitionSubtype.fromRight
        return self
    }
    //New viewController will appear from left side of screen.
    func popFromLeft() -> CATransition {
        self.duration = 1
        self.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        self.type = CATransitionType.reveal
        self.subtype = CATransitionSubtype.fromLeft
        return self
    }
}
