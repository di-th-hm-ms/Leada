//
//  UsernameViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/12/13.
//

import UIKit
import Firebase

class UsernameViewController: UIViewController {
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "IowanOldStyle-Bold", size: 13)
        let atr = NSAttributedString(string: "ユーザーネームを登録してください。(半角英数字5~10文字)", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        label.attributedText = atr
        label.textColor = .darkGray
        return label
    }()
    
    private let usernameTextField: UITextField = {
        let textField = UITextField()
        textField.attributedPlaceholder = NSAttributedString(string: "例: user1", attributes: [NSAttributedString.Key.foregroundColor : purple])
        textField.backgroundColor = .white
        textField.textColor = .darkGray
        textField.font = UIFont(name: "IowanOldStyle-Bold", size: 13)
        textField.keyboardType = .asciiCapable
        textField.autocapitalizationType = .none
        textField.borderStyle = .roundedRect
        return textField
    }()
        
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "登録", style: .done, target: self, action: #selector(didTapStartButton))
        navigationController?.navigationBar.barTintColor = lightPurple
        navigationController?.navigationBar.tintColor = darkPurple
        usernameTextField.delegate = self
        view.addSubview(usernameLabel)
        view.addSubview(usernameTextField)
    }
    
    override func viewWillLayoutSubviews() {
        usernameLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, paddingTop: 20, paddingLeft: 15)
        usernameTextField.anchor(top: usernameLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 10, paddingLeft: 15, paddingRight: 15)
    }
    
    @objc private func didTapStartButton() {
        guard let currentUser = Auth.auth().currentUser, let text = usernameTextField.text else {
            let alert = UIAlertController(title: "UserError", message: "usernameが不当またはUserが存在しません。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "戻る", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        guard checkHalfWidthCharactersWithText(text: text) && !(text.isEmpty) else {
            let alert = UIAlertController(title: "入力に誤りがあります。", message: "半角英数字5~10文字で入力してください。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "戻る", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        Firestore.firestore().collection(USERS_REF).document(currentUser.uid).setData([USERNAME : text], merge: true) { (error) in
            if let error = error {
                debugPrint("DEBUG: Usernameの保存に失敗 \(error)")
            }
            else {
                self.dismiss(animated: false, completion: nil)
            }
        }
    }

}

extension UsernameViewController: UITextFieldDelegate {
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        if let currentString = textField.text, let _range = Range(range, in: currentString) {
//            let newString = currentString.replacingCharacters(in: _range, with: string)
//
//        }
//        else {
//             return false
//        }
//    }
}
