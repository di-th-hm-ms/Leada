//
//  EmailUpdateTableViewCell.swift
//  HowToEducate
//
//  Created by Lon on 2020/12/03.
//

import UIKit
protocol EmailUpdateCellDelegate: AnyObject {
    func EmailUpdateCell(_ cell: EmailUpdateCell, didUpdateField updatedModel: UpdateAuthFormModel)
}

class EmailUpdateCell: CustomCell, UITextFieldDelegate {
    
    static let identifier = "EmailUpdateTableViewCell"
    
    private var model: UpdateAuthFormModel?
    var delegate: EmailUpdateCellDelegate?
    
    private var iconClick = true
    private let field: UITextField = {
        let field = UITextField()
        field.returnKeyType = .done
        field.autocapitalizationType = .none
        field.textColor = .darkGray
        field.font = UIFont(name: "Thonburi-Bold", size: 14)
        return field
    }()
    
    private let exposeEyeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = purple
        return button
    }()
    
    
    override init(style: CustomCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        clipsToBounds = true
        contentView.addSubview(field)
        field.delegate = self
        //selectionStyle = .none
        contentView.backgroundColor = .white
        contentView.addSubview(exposeEyeButton)
        exposeEyeButton.addTarget(self, action: #selector(exposeTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        field.attributedPlaceholder = nil
        field.text = nil
    }
    public func configure(with model: UpdateAuthFormModel) {
        self.model = model
        switch model.placeholder {
        case "新しいメールアドレス":
            exposeEyeButton.isHidden = true
        default:
            exposeEyeButton.isHidden = false
            field.isSecureTextEntry = true
        }
        field.attributedPlaceholder = NSAttributedString(string: model.placeholder, attributes: [NSAttributedString.Key.foregroundColor : purple])
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        field.anchor(top: contentView.topAnchor, left: contentView.leftAnchor, paddingLeft: 10, width: contentView.width-50, height: contentView.height)
        exposeEyeButton.anchor(top: contentView.topAnchor, left: field.rightAnchor, paddingTop: 5, width: 30, height: 30)
    }
    
    @objc private func exposeTapped() {
        if model?.placeholder == "パスワード" {
            if iconClick == true {
                        field.isSecureTextEntry = false
                exposeEyeButton.setImage(UIImage(systemName: "eye"), for: .normal)
                    }
            else {
                        field.isSecureTextEntry = true
                exposeEyeButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
                    }
            iconClick = !iconClick
        }
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        model?.value = field.text
        guard let model = model else {
            return
        }
        delegate?.EmailUpdateCell(self, didUpdateField: model)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        model?.value = field.text
        guard let model = model else {
            return
        }
        delegate?.EmailUpdateCell(self, didUpdateField: model)
        
        field.endEditing(true)
    }
}
