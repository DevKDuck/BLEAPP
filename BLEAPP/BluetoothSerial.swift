//
//  BluetoothSerial.swift
//  BLEAPP
//
//  Created by duck on 2023/12/27.
//

import UIKit
import CoreBluetooth

//블루투스 연결과정에서 뷰와 시리얼의 소통에 필요한 프로토콜
protocol BluetoothSerialDelegate: AnyObject{
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?)
    func serialDidConnectPeripheral(peripheral: CBPeripheral)
}

//프로토콜에 았는 일부 함수를 옵셔널로 설정
extension BluetoothSerialDelegate{
    func serialDidDiscoverPeripheral(peripheral: CBPeripheral, RSSI: NSNumber?){}
    func serialDidConnectPeripheral(peripheral: CBPeripheral){}
}

//글로벌 시리얼 핸들러
var serial: BluetoothSerial!

class BluetoothSerial: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate{
    
    //현재 설정된 BluetoothSerialDelegate 객체에 정의된 메서드를 대신 호출할 수 있게 하는 대리자
    var delegate: BluetoothSerialDelegate?
    
    
    var centralManager: CBCentralManager! //주변기기 검색 및 연결 역할 수행
    
    //현재 연결을 시도하고 있는 주변기기
    var pendingPeripheral: CBPeripheral?
    
    //연결에 성공된 기기, 기기와 통신시 이 객체와 통신함
    var connectedPeripheral: CBPeripheral?
    
    //검색된 peripheralList
    var peripheralList: [(peripheral: CBPeripheral, RSSI: Float)] = []
    
    var peripherals: [CBPeripheral] = [] //검색되는 기기들
    
    
    
    /// serviceUUID는 Peripheral이 가지고 있는 서비스의 UUID를 뜻합니다. 거의 모든 HM-10모듈이 기본적으로 갖고있는 FFE0으로 설정하였습니다. 하나의 기기는 여러개의 serviceUUID를 가질 수도 있습니다.
    var serviceUUID = CBUUID(string: "FFE0")
    
    
    /// characteristicUUID는 serviceUUID에 포함되어있습니다. 이를 이용하여 데이터를 송수신합니다. FFE0 서비스가 갖고있는 FFE1로 설정하였습니다. 하나의 service는 여러개의 characteristicUUID를 가질 수 있습니다.
    var characteristicUUID = CBUUID(string : "FFE1")
    
    ///데이터를 주변 기기에 보내기 위한  characteristic을 저장하는 변수입니다.
    weak var writeCharacteristic: CBCharacteristic?
    
    /// 데이터를 주변기기에 보내는 type을 설정합니다. withResponse는 데이터를 보내면 이에 대한 답장이 오는 경우입니다. withoutResponse는 반대로 데이터를 보내도 답장이 오지 않는 경우입니다.
    private var writeType: CBCharacteristicWriteType = .withResponse
    
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
    
    //MARK: 기기 검색
    func startScan(){
        guard centralManager.state == .poweredOn else {return}
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
        
        
        //특정 UUID서비스를 가지는 기기만 검색
        let p = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])
        
        for peripheral in p{
            //검색된 기기들에 대한 처리
            delegate?.serialDidDiscoverPeripheral(peripheral: peripheral, RSSI: nil)
        }
        
    }
    
    //MARK: 기기 검색 중단
    func stopScan(){
        centralManager.stopScan()
    }
    
    
    
    //MARK: 파라미터로 넘어온 주변 기기 centralManager 에 연결시도
    func connectToPeripheral(_ peripheral: CBPeripheral){
        //실패 할 수 있으니 임시로 넣어놓는 것이라 함
        pendingPeripheral = peripheral
        //연결하는 메서드
        centralManager.connect(peripheral, options: nil)
    }
    
    
    //MARK: 기기 검색 될때마다 호출되는 메서드
    //rssi 신호 강도
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        let check: Bool = false
//        if !check{
//            peripherals.append(peripheral)
//            print("Discover:",peripheral.name ?? peripheral.identifier.uuidString)
//            if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
//                print("Peripheral Name: \(peripheralName)")
//            }
//        }
        delegate?.serialDidDiscoverPeripheral(peripheral: peripheral, RSSI: RSSI)
    }
    
    //MARK: 기기가 연결되면 호출되는 메서드
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        pendingPeripheral = nil
        connectedPeripheral = peripheral
        
        //peripheral의 Service를 검색. 파라미터를 nil로 설정하면 peripheral의 모든 서비스를 검색함
        peripheral.discoverServices([serviceUUID])
    }
    //MARK: Service를 검색 성공시 호출되는 메서드
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services!{
            
            //검색된 모든 Service메서 characteristic을 검색. 파라미터를 nil로 설정하면 peripheral의 모든 특성를 검색함
            peripheral.discoverCharacteristics([characteristicUUID], for: service)
        }
    }
    
    //MARK: Characteristic 검색에 성공시 호출되는 메서드
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for characteristic in service.characteristics!{
            if characteristic.uuid == characteristicUUID{
                
                //해당 기기 데이터를 구독
                peripheral.setNotifyValue(true, for: characteristic)
                
                //데이터를 보내기 위한 characteristic 저장
                writeCharacteristic = characteristic
                
                //보내는 데이터 타입 설정, 주변 기가 어떤 타입인지에 따라 변경됨
                writeType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
                
                delegate?.serialDidConnectPeripheral(peripheral: peripheral)
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        // writeType이 .withResponse일 때, 블루투스 기기로부터의 응답이 왔을 때 호출되는 함수입니다.
        // 제가 테스트한 주변 기기는 .withoutResponse이기 때문에 호출되지 않습니다.
        // writeType이 .withResponse인 블루투스 기기로부터 응답이 왔을 때 필요한 코드를 작성합니다.(필요하다면 작성해주세요.)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        // 블루투스 기기의 신호 강도를 요청하는 peripheral.readRSSI()가 호출하는 함수입니다.
        // 신호 강도와 관련된 코드를 작성합니다.(필요하다면 작성해주세요.)
    }
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
}

/// 블루투스 통신을 담당할 시리얼을 클래스로 선언합니다. CoreBluetooth를 사용하기 위한 프로토콜을 추가해야합니다.
//class BluetoothSerial: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
//
//    /// centralManager은 블루투스 주변기기를 검색하고 연결하는 역할을 수행합니다.
//    var centralManager : CBCentralManager!
//
//    /// pendingPeripheral은 현재 연결을 시도하고 있는 블루투스 주변기기를 의미합니다.
//    var pendingPeripheral : CBPeripheral?
//
//    /// connectedPeripheral은 연결에 성공된 기기를 의미합니다. 기기와 통신을 시작하게되면 이 객체를 이용하게됩니다.
//    var connectedPeripheral : CBPeripheral?
//
//   /// 데이터를 주변기기에 보내기 위한 characteristic을 저장하는 변수입니다.
//    weak var writeCharacteristic: CBCharacteristic?
//
//    /// 데이터를 주변기기에 보내는 type을 설정합니다. withResponse는 데이터를 보내면 이에 대한 답장이 오는 경우입니다. withoutResponse는 반대로 데이터를 보내도 답장이 오지 않는 경우입니다.
//    private var writeType: CBCharacteristicWriteType = .withoutResponse
//
//    /// serviceUUID는 Peripheral이 가지고 있는 서비스의 UUID를 뜻합니다. 거의 모든 HM-10모듈이 기본적으로 갖고있는 FFE0으로 설정하였습니다. 하나의 기기는 여러개의 serviceUUID를 가질 수도 있습니다.
//    var serviceUUID = CBUUID(string: "FFE0")
//
//      /// characteristicUUID는 serviceUUID에 포함되어있습니다. 이를 이용하여 데이터를 송수신합니다. FFE0 서비스가 갖고있는 FFE1로 설정하였습니다. 하나의 service는 여러개의 characteristicUUID를 가질 수 있습니다.
//    var characteristicUUID = CBUUID(string : "FFE1")
//
//
//  // CBCentralManagerDelegate에 포함되어 있는 메서드입니다. central 기기의 블루투스가 켜져있는지, 꺼져있는지 등에 대한 상태가 변화할 때 마다 호출됩니다. 이 상태는 블루투스가 켜져있을 때는 .poweredOn, 꺼져있을 때는 .poweredOff로 관리됩니다.
//      func centralManagerDidUpdateState(_ central: CBCentralManager) {
//        pendingPeripheral = nil
//        connectedPeripheral = nil
//    }
//    /// 기기 검색을 시작합니다. 연결이 가능한 모든 주변기기를 serviceUUID를 통해 찾아냅니다.
//       func startScan() {
//           guard centralManager.state == .poweredOn else { return }
//
//         // CBCentralManager의 메서드인 scanForPeripherals를 호출하여 연결가능한 기기들을 검색합니다. 이 떄 withService 파라미터에 nil을 입력하면 모든 종류의 기기가 검색되고, 지금과 같이
//         // serviceUUID를 입력하면 특정 serviceUUID를 가진 기기만을 검색합니다.
//           centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
//
//           let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])
//           for peripheral in peripherals {
//            // TODO : 검색된 기기들에 대한 처리를 여기에 작성합니다.(잠시 후 작성할 예정입니다)
//
//           }
//           }
//
//       /// 기기 검색을 중단합니다.
//       func stopScan() {
//           centralManager.stopScan()
//       }
//
//         /// 파라미터로 넘어온 주변 기기를 CentralManager에 연결하도록 시도합니다.
//       func connectToPeripheral(_ peripheral : CBPeripheral)
//       {
//           // 연결 실패를 대비하여 현재 연결 중인 주변 기기를 저장합니다.
//           pendingPeripheral = peripheral
//           centralManager.connect(peripheral, options: nil)
//       }
//
//       // CBCentralManagerDelegate에 포함되어 있는 메서드입니다.
//       // central 기기의 블루투스가 켜져있는지, 꺼져있는지 확인합니다. 확인하여 centralManager.state의 값을 .powerOn 또는 .powerOff로 변경합니다.
//       func centralManagerDidUpdateState(_ central: CBCentralManager) {
//           pendingPeripheral = nil
//           connectedPeripheral = nil
//       }
//
//       // 기기가 검색될 때마다 호출되는 메서드입니다.
//       func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//           // RSSI는 기기의 신호 강도를 의미합니다.
//           // TODO : 기기가 검색될 때마다 필요한 코드를 여기에 작성합니다.(잠시 후 작성할 예정입니다)
//       }
//
//
//       // 기기 연결가 연결되면 호출되는 메서드입니다.
//       func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
//           peripheral.delegate = self
//           pendingPeripheral = nil
//           connectedPeripheral = peripheral
//
//           // peripheral의 Service들을 검색합니다.파라미터를 nil으로 설정하면 peripheral의 모든 service를 검색합니다.
//           peripheral.discoverServices([serviceUUID])
//       }
//
//
//       // service 검색에 성공 시 호출되는 메서드입니다.
//       func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//           for service in peripheral.services! {
//               // 검색된 모든 service에 대해서 characteristic을 검색합니다. 파라미터를 nil로 설정하면 해당 service의 모든 characteristic을 검색합니다.
//               peripheral.discoverCharacteristics([characteristicUUID], for: service)
//           }
//       }
//
//
//       // characteristic 검색에 성공 시 호출되는 메서드입니다.
//       func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
//           for characteristic in service.characteristics! {
//               // 검색된 모든 characteristic에 대해 characteristicUUID를 한번 더 체크하고, 일치한다면 peripheral을 구독하고 통신을 위한 설정을 완료합니다.
//               if characteristic.uuid == characteristicUUID {
//                   // 해당 기기의 데이터를 구독합니다.
//                   peripheral.setNotifyValue(true, for: characteristic)
//                   // 데이터를 보내기 위한 characteristic을 저장합니다.
//                   writeCharacteristic = characteristic
//                   // 데이터를 보내는 타입을 설정합니다. 이는 주변기기가 어떤 type으로 설정되어 있는지에 따라 변경됩니다.
//                   writeType = characteristic.properties.contains(.write) ? .withResponse :  .withoutResponse
//                   // TODO : 주변 기기와 연결 완료 시 동작하는 코드를 여기에 작성합니다.(잠시 후 작성할 예정입니다)
//               }
//           }
//       }
//
//       func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
//           // writeType이 .withResponse일 때, 블루투스 기기로부터의 응답이 왔을 때 호출되는 함수입니다.
//           // 제가 테스트한 주변 기기는 .withoutResponse이기 때문에 호출되지 않습니다.
//           // writeType이 .withResponse인 블루투스 기기로부터 응답이 왔을 때 필요한 코드를 작성합니다.(필요하다면 작성해주세요.)
//
//       }
//
//       func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
//           // 블루투스 기기의 신호 강도를 요청하는 peripheral.readRSSI()가 호출하는 함수입니다.
//           // 신호 강도와 관련된 코드를 작성합니다.(필요하다면 작성해주세요.)
//       }
//    override init() {
//           super.init()
//           self.centralManager = CBCentralManager(delegate: self, queue: nil)
//       }
//    var delegate : BluetoothSerialDelegate?
//}
//
//protocol BluetoothSerialDelegate : AnyObject {
//    func serialDidDiscoverPeripheral(peripheral : CBPeripheral, RSSI : NSNumber?)
//    func serialDidConnectPeripheral(peripheral : CBPeripheral)
//}
//
//// 프로토콜에 포함되어 있는 일부 함수를 옵셔널로 설정합니다.
//extension BluetoothSerialDelegate {
//    func serialDidDiscoverPeripheral(peripheral : CBPeripheral, RSSI : NSNumber?) {}
//    func serialDidConnectPeripheral(peripheral : CBPeripheral) {}
//}
