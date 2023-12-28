//
//  BluetoothTableViewCell.swift
//  BLEAPP
//
//  Created by duck on 2023/12/28.
//

import UIKit

class BluetoothTableViewCell: UITableViewCell{
    
    var bluetoothNamelabel: UILabel = {
       var label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .darkGray
        label.numberOfLines = 0
        return label
    }()
    
    
    private func setConstraint(){
        contentView.addSubview(bluetoothNamelabel)
        
        NSLayoutConstraint.activate([
            bluetoothNamelabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            bluetoothNamelabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bluetoothNamelabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
           
           super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = .white
        setConstraint()
           
       }
       
       
       
       required init?(coder aDecoder: NSCoder) {
           
           fatalError("init(coder:) has not been implemented")
           
       }
}
