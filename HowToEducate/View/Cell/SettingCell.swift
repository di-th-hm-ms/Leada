//
//  SettingTableViewCell.swift
//  HowToEducate
//
//  Created by Lon on 2020/11/12.
//

import UIKit

//enum SettingViewModel {
//    case imageView: UIImageView
//    case title:
//}

class SettingCell: UITableViewCell {

    //インスタンスごとに値の変動がおきないように
    static var identifier = "SettingCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "title"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.font = UIFont(name: "Thonburi-Bold",size: 14)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleLabel.textColor = purple
        addSubview(titleLabel)
        backgroundColor = .white
        
    }
    
    override func prepareForReuse() {
        self.titleLabel.text = ""
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.anchor(top: contentView.topAnchor, left: contentView.leftAnchor, paddingTop: 10, paddingLeft: 20)
    }
    
    func configure(title: String?, googleUser: Bool?) {
        self.titleLabel.text = title
        if googleUser == true {
            titleLabel.textColor = .gray
            self.selectionStyle = .none
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
