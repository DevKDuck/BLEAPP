//
//  ViewController.swift
//  BLEAPP
//
//  Created by duck on 2023/12/27.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, BluetoothSerialDelegate{
    
    
    //MARK: 객체
    
    var peripheralList: [(peripheral: CBPeripheral, RSSI: Float)] = []
    
    // peripheral(주변 기기)를 보여줄 테이블 뷰
    @IBOutlet weak var bluetoothTableView: UITableView!
    
    //주변 기기를 확인하는 기능을 키고 끄는 스위치
    @IBAction func switchOnOff(_ sender: UISwitch) {
        if sender.isOn{
            //스위치가 on일 경우 list 초기화
            //serial의 대리자를 ViewController로 지정
            //주변 기기 검색시작
            peripheralList = []
            serial.delegate = self
            serial.startScan()
        }
        else{
            //주변 기기 검색중지
            serial.stopScan()
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = .white
        setTableView()
        serial = BluetoothSerial.init()
    }
    
    func setTableView(){
        bluetoothTableView.delegate = self
        bluetoothTableView.dataSource = self
        bluetoothTableView.backgroundColor = .white
        bluetoothTableView.register(BluetoothTableViewCell.self, forCellReuseIdentifier: "BluetoothTableViewCell")
    }
    
}




extension ViewController : UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripheralList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BluetoothTableViewCell", for: indexPath) as? BluetoothTableViewCell else {return UITableViewCell()}
        cell.bluetoothNamelabel.text = peripheralList[indexPath.row].peripheral.name ?? peripheralList[indexPath.row].peripheral.identifier.uuidString
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        serial.stopScan()
        let selectedPeripheral = peripheralList[indexPath.row].peripheral
        serial.connectToPeripheral(selectedPeripheral)
        
    }
}

extension ViewController{
    func serialDidConnectPeripheral(peripheral: CBPeripheral) {
        // serial의 delegate에서 호출됩니다.
        // 연결 성공 시 alert를 띄우고, alert 확인 시 View를 dismiss합니다.
        let connectSuccessAlert = UIAlertController(title: "블루투스 연결 성공", message: "\(peripheral.name ?? "알수없는기기")와 성공적으로 연결되었습니다.", preferredStyle: .actionSheet)
        let confirm = UIAlertAction(title: "확인", style: .default, handler: { _ in self.dismiss(animated: true, completion: nil) } )
        connectSuccessAlert.addAction(confirm)
        serial.delegate = nil
        present(connectSuccessAlert, animated: true, completion: nil)
    }
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?) {
        // serial의 delegate에서 호출됩니다.
        // 이미 저장되어 있는 기기라면 return합니다.
        for existing in peripheralList {
            if existing.peripheral.identifier == peripheral.identifier {return}
        }
        // 신호의 세기에 따라 정렬하도록 합니다.
        let fRSSI = RSSI?.floatValue ?? 0.0
        peripheralList.append((peripheral : peripheral , RSSI : fRSSI))
        peripheralList.sort { $0.RSSI < $1.RSSI}
        // tableView를 다시 호출하여 검색된 기기가 반영되도록 합니다.
        bluetoothTableView.reloadData()
    }
}
