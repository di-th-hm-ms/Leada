//
//  FormCell.swift
//  HowToEducate
//
//  Created by Lon on 2020/11/03.
//

import UIKit

protocol FormCellDelegate: AnyObject {
    func formCell(_ cell: FormCell, didUpdateField updatedModel: EditProfileFormModel)
}
class FormCell: CustomCell, UITextFieldDelegate {
    
    //MARK: - Property
    static let identifier = "FormCell"
    private var model: EditProfileFormModel?
    public weak var delegate: FormCellDelegate?
    private var user: User?
    
    private let formLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = purple
        label.font = UIFont(name: "IowanOldStyle-Bold", size: 13)
        return label
    }()
    
    private let field: UITextField = {
        let field = UITextField()
        field.returnKeyType = .done
        field.textColor = .darkGray
        field.font = UIFont(name: "IowanOldStyle-Bold", size: 13)
        return field
    }()
    
    private let halfAlertLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.textColor = .red
        label.text = "半角英数字５文字~10文字"
        label.font = UIFont.systemFont(ofSize: 11)
        return label
    }()
    
    //MARK: - Lifecycle
    override init(style: CustomCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        clipsToBounds = true
        contentView.addSubview(formLabel)
        contentView.addSubview(field)
        contentView.addSubview(halfAlertLabel)
        field.delegate = self
        //selectionStyle = .none
        contentView.backgroundColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        formLabel.text = nil
        field.placeholder = nil
        field.text = nil
    }
    public func configure(with model: EditProfileFormModel) {
        self.model = model
        formLabel.text = model.label
        field.placeholder = model.placeholder
        field.text = model.value
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        formLabel.anchor(top: contentView.topAnchor, left: contentView.leftAnchor, paddingTop: 5, paddingLeft: 10, width: contentView.width/4, height: contentView.height-10)
        field.anchor(top: contentView.topAnchor, left: formLabel.rightAnchor, paddingLeft: 10, width: contentView.width-20-formLabel.width, height: contentView.height)
        halfAlertLabel.anchor(bottom: field.topAnchor, right: field.rightAnchor, paddingBottom: 2, paddingRight: 2)
        
    }
    
    //MARK: - Selectors
    
    
    //MARK: - textField
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        model?.value = textField.text
        guard let model = model else {
            return true
        }
        delegate?.formCell(self, didUpdateField: model)
        textField.resignFirstResponder()
        return true
    }
    
    //変換確定前で値を飛ばすメソッド 変換確定前に保存押すと値がUpdateProfileVCに飛ばない。
    func textFieldDidChangeSelection(_ textField: UITextField) {
        model?.value = field.text
        guard let model = model else {
            return
        }
        delegate?.formCell(self, didUpdateField: model)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        model?.value = field.text
        guard let model = model else {
            return
        }
        delegate?.formCell(self, didUpdateField: model)
        field.endEditing(true)
    }
    
    //12/17
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == USERNAME {
            if checkHalfWidthCharacters(textfield: field) == true {
                halfAlertLabel.isHidden = false
            }
            else {
                
            }
        }
    }
    
    
}

class CustomCell: UITableViewCell {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.next?.touchesBegan(touches, with: event)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //print("touches ended")
    }
}
