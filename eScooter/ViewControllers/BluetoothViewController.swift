
//  ViewController.swift
//  eScooter
//
//  Created by Dove on 01/12/2020.
//  Copyright © 2020 Dove. All rights reserved.
//

import UIKit
import CoreBluetooth
import os

class DeviceItemCell: UITableViewCell {
    @IBOutlet weak var deviceName: UILabel!
    @IBOutlet weak var deviceAddress: UILabel!
}

class BluetoothViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var img_searching: UIImageView!
    
    public var devices: [CBPeripheral] = []
    private var searching = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.modalPresentationStyle = .fullScreen
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.reloadData()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }
    @IBAction func search_device(_ sender: Any) {
        if(self.searching == false){
            self.searching = true
            self.rotateView(targetView: self.img_searching)
            self.discover()
        }else{
            self.tableView.reloadData()
        }
    }
    
    private func rotateView(targetView: UIView, duration: Double = 0.5) {
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveLinear, animations: {
            targetView.transform = targetView.transform.rotated(by: CGFloat(Double.pi))
        }) { finished in
            if(self.searching == true){
                self.rotateView(targetView: targetView, duration: duration)
            }
        }
    }
    func didChangeState(state: CBManagerState) {
        switch state {
            case .poweredOn:
                os_log("CBManager is powered on")
                sleep(3)
                DispatchQueue.main.async(execute: {
                    self.search_device(self)
                })
            case .poweredOff:
                showToast(title:"Error", body: "Bluetooth is not powered on")
                return
            case .resetting:
                os_log("CBManager is resetting")
                return
            case .unauthorized:
                showToast(title:"Warning", body: "You are not authorized to use Bluetooth")
                return
            case .unknown:
                os_log("CBManager state is unknown")
                return
            case .unsupported:
                showToast(title:"Error", body: "Bluetooth is not supported on this device")
                return
            default:
                os_log("A previously unknown central manager state occurred")
                return
        }
    }
    
    func didDiscoverDevice(peripheral: CBPeripheral){
        DispatchQueue.main.async(execute: {
            if peripheral.name?.isEmpty == false && (self.devices.count <= 0 || self.devices.filter({ $0.name == peripheral.name }).count == 0) {
                self.devices.append(peripheral)
            }
            print("find", self.devices.count)
            self.tableView.reloadData()
        })
    }
    func didConnect(peripheral: CBPeripheral){
        print("connected")
        self.dismiss(animated: false, completion: nil)
        Switcher.updateRootVC()
    }
}

extension BluetoothViewController : UITableViewDelegate, UITableViewDataSource{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    private func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> CBPeripheral? {
        return devices[section]
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:DeviceItemCell = self.tableView.dequeueReusableCell(withIdentifier: "DeviceItem") as! DeviceItemCell
        let text = devices[indexPath.row]
        cell.deviceName.text = text.name
        cell.deviceAddress.text = text.identifier.uuidString
//        if(text.name == "Scooter"){
//            self.searching = false
//            self.connect(device: self.devices[indexPath.row])
//        }
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.searching = false
        self.connect(device: self.devices[indexPath.row])
    }
}
