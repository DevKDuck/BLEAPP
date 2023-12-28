//
//  ViewController.swift
//  BLEAPP
//
//  Created by duck on 2023/12/27.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController{
    
    @IBAction func switchOnOff(_ sender: UISwitch) {
        if sender.isOn{
            print("찾기")
            if !(centralManager.isScanning){
                centralManager?.scanForPeripherals(withServices: nil, options: nil)
                //서비스를 광고하는 주변 장치 검색
                //CBUUID - 블루투스 저에너지 통신에 표준에 정의된 보편적인 고유 식별자
//                bluetoothTableView.reloadData()
            }
        }
        else{
            print("찾기 끝")
            centralManager.stopScan()
        }
    }
    var peripherals: [CBPeripheral] = [] //검색되는 기기들
    var centralManager: CBCentralManager!
    
    @IBOutlet weak var bluetoothTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        
        bluetoothTableView.delegate = self
        bluetoothTableView.dataSource = self
        bluetoothTableView.backgroundColor = .white
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        bluetoothTableView.register(BluetoothTableViewCell.self, forCellReuseIdentifier: "BluetoothTableViewCell")
    }


}

extension ViewController: CBCentralManagerDelegate{
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state{
        case .unknown:
            print("unknown")
        case .resetting:
            print("resetting")
        case .unsupported:
            print("unsupported")
        case .unauthorized:
            print("unauthorized")
        case .poweredOff:
            print("poweredOff")
        case .poweredOn:
            print("poweredOn")
        default:
            fatalError()
        }
    }
}

extension ViewController: CBPeripheralDelegate{
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let check: Bool = false
        if !check{
            peripherals.append(peripheral)
            print("Discover:",peripheral.name ?? peripheral.identifier.uuidString)
            bluetoothTableView.reloadData()
        }
    }
}

extension ViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BluetoothTableViewCell", for: indexPath) as? BluetoothTableViewCell else {return UITableViewCell()}
        cell.bluetoothNamelabel.text = peripherals[indexPath.row].name ?? peripherals[indexPath.row].identifier.uuidString
        return cell
    }
    
    
}
