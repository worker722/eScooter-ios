//
//  BaseViewController.swift
//  eScooter
//
//  Created by Dove on 05/12/2020.
//  Copyright © 2020 Dove. All rights reserved.
//

import UIKit
import CoreBluetooth
import SwiftMessages

class BaseViewController: UIViewController {

    var values: [String: String] = [:]
    private var speedTimer: Timer?
    
    @IBOutlet weak var lbl_back: UILabel!
    @IBOutlet weak var lbl_home: UILabel!
    public let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
    public var isShowed = false
    public var disconnectCount = 0
    private var bef_time:Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        Utils.mMain = self
    }
    override func viewDidAppear(_ animated: Bool) {
        Utils.mMain = self
        lbl_back?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goBack)))
        lbl_home?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(goHome)))

        if(Utils.centralManager == nil || (Utils.centralManager.isScanning == false && Utils.connectedDevice == nil)){
            Utils.centralManager = CBCentralManager(delegate: self, queue: nil)
        }
        ApiService.updateOdo()
    }
    @IBAction func btn_back(_ sender: Any) {
        goBack()
    }
    
    @IBAction func btn_home(_ sender: Any) {
        goHome()
    }
    
    @objc func goBack() {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    func checkConnection(){
        if(Utils.debugging){
            return
        }
//        if(Utils.connectedDevice == nil){
        if(Utils.connectedDevice?.state != CBPeripheralState.connected){
            let nextViewController = self.storyBoard.instantiateViewController(withIdentifier: "BluetoothViewController") as! BluetoothViewController
            nextViewController.modalPresentationStyle = .fullScreen
            DispatchQueue.main.async {
               self.present(nextViewController, animated: true, completion: nil)
            }
        }
    }
    @objc func goHome() {
        Switcher.updateRootVC()
    }
    
    func discover() {
        Utils.centralManager.scanForPeripherals(withServices: nil)
    }
    func connect(device: CBPeripheral) {
        self.showLoading(message: NSLocalizedString("connect", comment: ""))
        Utils.centralManager.stopScan()
        Utils.centralManager.connect(device, options: nil)
    }
    func disconnect() {
        if let connectedDevice = Utils.connectedDevice {
            speedTimer?.invalidate()
            Utils.centralManager.cancelPeripheralConnection(connectedDevice)
            Utils.connectedDevice = nil
        }
    }
    func sendData( command:String ){
        guard let peripheral = Utils.connectedDevice else { return }
        guard let services = peripheral.services else { return }
        print("send", command, services.count)
        for service in services {
            guard let characteristics = service.characteristics else { return }
            for characteristic in characteristics {
                if characteristic.uuid == Utils.writeCharacterisitc {
                    peripheral.writeValue(Data(Utils.Command[command]!), for: characteristic, type: .withoutResponse)
                }
            }
        }
    }
    
    func showLoading(message: String = "Please wait..."){
        DispatchQueue.main.async(execute: {
//            self.dismiss(animated: false, completion: nil)
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = UIActivityIndicatorView.Style.gray
            loadingIndicator.startAnimating();

            alert.view.addSubview(loadingIndicator)
            self.present(alert, animated: true, completion: nil)
        })
    }
    func dismissLoading(){
        DispatchQueue.main.async(execute: {
            self.dismiss(animated: false, completion: nil)
        })
    }
    func showToast(title:String = "Success", body:String!){
        DispatchQueue.main.async(execute: {
//        https://github.com/SwiftKickMobile/SwiftMessages
            let view = MessageView.viewFromNib(layout: .cardView)
            var iconText = "😀";
            if(title == "Error"){
                view.configureTheme(.error)
                iconText = "😥"
            }else if(title == "Warning"){
                view.configureTheme(.warning)
                iconText = "🤔"
            }else if(title == "Info"){
                view.configureTheme(.info)
                iconText = "😎"
            }else{
                view.configureTheme(.success)
            }
            view.button?.isHidden = true
            view.configureContent(title: title, body: body, iconText: iconText)
            
            SwiftMessages.show(view: view)
        });
    }
    func changeState(central: CBCentralManager){
        (Utils.mMain as? BluetoothViewController)?.didChangeState(state: central.state)
    }
    func changeInfo(){
        (Utils.mMain as? MainViewController)?.didUpdateValues()
        (Utils.mMain as? SettingViewController)?.didUpdateValues()
        (Utils.mMain as? NavigationViewcontroller)?.didUpdateValues()
        (Utils.mMain as? MoreViewController)?.didUpdateValues()
        (Utils.mMain as? ProfileViewController)?.didUpdateValues()
    }
    func checkDevice(){
        (Utils.mMain as? DiagnosticsViewController)?.didUpdateValues()
    }
    func discoveredDevice(peripheral: CBPeripheral){
        (Utils.mMain as? BluetoothViewController)?.didDiscoverDevice(peripheral:peripheral)
    }
    func connected(peripheral: CBPeripheral){
        (Utils.mMain as? BluetoothViewController)?.didConnect(peripheral: peripheral)
    }
}

extension BaseViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.changeState(central:central)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.discoveredDevice(peripheral:peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        Utils.connectedDevice = peripheral
//        sleep(2)
        peripheral.discoverServices([])
        self.connected(peripheral: peripheral)
    }
}

extension BaseViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([], for: service)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if(self.bef_time == nil){
            self.bef_time = Date()
        }
        
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == Utils.writeCharacterisitc {
                for payload in Utils.payloads {
                    self.isShowed = false
                    Utils.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                        if(self.isShowed == true) {
                            Utils.timer?.invalidate()
                            Utils.timer = nil
                            return
                        }
                        if(peripheral.state == .connected){
                            self.disconnectCount = 0
                            peripheral.writeValue(Data(payload), for: characteristic, type: .withoutResponse)
                        }else if(peripheral.state == .disconnected){
                             let difference = Calendar.current.dateComponents([.second], from: self.bef_time!, to: Date())
                            if(self.disconnectCount <= 1){
                                print("state", difference.second as Any)
                            }
                            self.bef_time = Date()
                            self.disconnectCount += 1
                            if(self.disconnectCount < 20){
                                return
                            }
                            self.disconnectCount = 0
                            self.isShowed = true
                            self.showToast(title:"Error", body: "Device disconnected")
                            self.checkConnection()
                        }
                    }
                }
            }
            if characteristic.uuid == Utils.readCharacterisitc {
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        if(characteristic.value!.count < 3){
            return
        }
        let cmd = characteristic.value![0..<3].map { String(format: "%02hhX", $0) }

        guard cmd[0] == "FF" && cmd[1] == "55" && cmd.count >= 3 else {
            print("invalid command")
            return
        }
        
        let value = characteristic.value![4..<characteristic.value!.count-1]
        switch cmd[2] {
            case "0A":
                let speed = numberSerializer(bytes: value, factor: 1000)
                Utils.mScooterInfo.speed = speed
                let bef_speed = UserDefaults.standard.float(forKey: "MaxSpeed")
                if(bef_speed < speed || bef_speed > 30){
                    UserDefaults.standard.set(Float(speed), forKey: "MaxSpeed")
                }
                break
            case "0B":
                Utils.mScooterInfo.trip = Float(Int32(bigEndian: value.withUnsafeBytes { $0.pointee }))/1000
                break
            case "0C":
                Utils.mScooterInfo.odo = Float(Int32(bigEndian: value.withUnsafeBytes { $0.pointee }))/1000
                break
            case "0D":
                Utils.mScooterInfo.battery = Int(value.hexEncodedString(), radix: 16)!
                break
            case "17":
                let str = value.hexEncodedString()
                Utils.mScooterInfo.locked = (str == "02" ? true : false)
                break
            case "18":
                let str = value.hexEncodedString()
                Utils.mScooterInfo.speedKM = (str == "01" ? true : false)
                Utils.mScooterInfo.perNum = (str == "01" ? 1 : 0.62)
                break
            case "1A":
                let str = value.hexEncodedString()
                Utils.mScooterInfo.zeroStart = (str == "01" ? true : false)
                break
            case "1D":
                let str = value.hexEncodedString()
                Utils.mScooterInfo.cruiseOn = (str == "01" ? true : false)
                break
            case "1F":
                let str = value.hexEncodedString()
                Utils.mScooterInfo.speedMode = (str == "02" ? 1 : str == "03" ? 2 : 3)
                break
            case "1E":
                Utils.mScooterInfo.selfCheck = value.hexEncodedString()
                self.checkDevice()
                return
            default:
                return
        }
        self.changeInfo()
    }
    func numberSerializer(bytes: Data, factor: Float = 1) -> Float {
        let hexString = bytes.map { String(format: "%02hhX", $0) }.joined()
        return Float(Float(Int(hexString, radix: 16)!)/factor)
    }
}
