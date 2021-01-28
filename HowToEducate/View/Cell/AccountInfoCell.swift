//
//  AccountInfoCell.swift
//  HowToEducate
//
//  Created by Lon on 2020/11/26.
//

import UIKit

class AccountInfoCell: UITableViewCell {
    static let identifier = "AccountInfoCell"
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = purple
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        addSubview(titleLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.anchor(top: contentView.topAnchor, left: contentView.leftAnchor, paddingTop: 10, paddingLeft: 20)
        //titleLabel.centerY(inView: contentView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(title: String) {
        titleLabel.text = title
    }
}
