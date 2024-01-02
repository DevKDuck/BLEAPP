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
    var centralManager: CBCentralManager! //주변기기 검색 및 연결 역할 수행
    
    
    /// serviceUUID는 Peripheral이 가지고 있는 서비스의 UUID를 뜻합니다. 거의 모든 HM-10모듈이 기본적으로 갖고있는 FFE0으로 설정하였습니다. 하나의 기기는 여러개의 serviceUUID를 가질 수도 있습니다.
       var serviceUUID = CBUUID(string: "FFE0")
    
    
    //MARK: 기기 검색
    func startScan(){
        guard centralManager.state == .poweredOn else {return}
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
        
        
        //특정 UUID서비스를 가지는 기기만 검색
        let p = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])
        
        for peripheral in p{
            //검색된 기기들에 대한 처리
        }
        
    }
    
    //MARK: 기기 검색 중단
    func stopScan(){
        centralManager.stopScan()
    }
    
    //현재 연결을 시도하고 있는 주변기기
    var pendingPeripheral: CBPeripheral?
    
    //연결에 성공된 기기, 기기와 통신시 이 객체와 통신함
    var connectedPeripheral: CBPeripheral?
    
    //MARK: 파라미터로 넘어온 주변 기기 centralManager 에 연결시도
    func connectToPeripheral(_ peripheral: CBPeripheral){
        //실패 할 수 있으니 임시로 넣어놓는 것이라 함
        pendingPeripheral = peripheral
        //연결하는 메서드
        centralManager.connect(peripheral, options: nil)
    }
    
    
    
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
    
    //MARK: central 기기의 블루투스 상태를 나타냄
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
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        default:
            fatalError()
        }
    }
}

extension ViewController: CBPeripheralDelegate{
    
    //MARK: 기기 검색 될때마다 호출되는 메서드
    //rssi 신호 강도
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let check: Bool = false
        if !check{
            peripherals.append(peripheral)
            print("Discover:",peripheral.name ?? peripheral.identifier.uuidString)
            bluetoothTableView.reloadData()
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
                    print("Peripheral Name: \(peripheralName)")
                }
        }
    }
    
    //MARK: 기기가 연결되면 호출되는 메서드
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        pendingPeripheral = nil
        connectedPeripheral = peripheral
        
        //peripheral의 Service를 검색. 파라미터를 nil로 설정하면 peripheral의 모든 서비스를 검색함
        peripheral.discoverServices([serviceUUID])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        centralManager.connect(peripherals[indexPath.row], options: nil) 
        connectToPeripheral(peripherals[indexPath.row])
    }
    
    
}
