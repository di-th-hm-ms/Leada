//
//  RegisterViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/10/27.
//

import UIKit
import Firebase
import FirebaseAuth
import JGProgressHUD
import SafariServices

class RegisterViewController: UIViewController {
    
    //MARK: - Properties
    private let spinner = JGProgressHUD(style: .light)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let emailTextField: UITextField = {
        let textField = Utilities().textField(withPlaceholder: "Email  ex：aaaa@gmail.com")
        configureTextField(textField: textField)
        textField.textContentType = .username
        textField.keyboardType = .emailAddress
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = Utilities().textField(withPlaceholder: "パスワード")
        configureTextField(textField: textField)
        textField.keyboardType = .emailAddress
        textField.isSecureTextEntry = true
        textField.disableAutoFill()
        //textField.textContentType = .newPassword
        return textField
    }()
    
    private var iconClick = true
    private let exposeEyeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = purple
        return button
    }()
    
    private let usernameTextField: UITextField = {
        let textField = Utilities().textField(withPlaceholder: "ユーザーネーム  ex：abcde1")
        configureTextField(textField: textField)
        textField.keyboardType = .emailAddress
        return textField
    }()
    
    private let fullnameTextField: UITextField = {
        let textField = Utilities().textField(withPlaceholder: "フルネーム  ex：Max Butler")
        configureTextField(textField: textField)
        textField.keyboardType = .default
        return textField
    }()
    
    private let button: UIButton = {
        let button = UIButton()
        button.setTitle("登録", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setDimensions(width: 130, height: 40)
        button.backgroundColor = purple
        //button.layer.borderWidth = 1
        //button.layer.borderColor = UIColor.white.cgColor
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.layer.cornerRadius = 10
        button.layer.shadowColor = purple.cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 5
        button.layer.shadowOffset = CGSize(width: 5, height: 5)
        return button
    }()
    
    private let termLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Copperplate", size: 14)
        let atr = NSAttributedString(string: "利用規約", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        label.attributedText = atr
        label.textColor = darkPurple
        return label
    }()
    
    //checkboxは別で用意
    let checkedImage: UIImage = UIImage(systemName: "checkmark.square")!
    let unCheckedImage: UIImage = UIImage(systemName: "square")!
    
    
    //Bool property
    var isChecked: Bool = false {
        didSet {
            if isChecked == true {
                checkBox.setImage(checkedImage, for: .normal)
            } else {
                checkBox.setImage(unCheckedImage, for: .normal)
            }
        }
    }
    
    let checkBox: UIButton = {
        let button = UIButton()
        button.tintColor = .darkGray
        return button
    }()
    
    private let hasAccountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Copperplate", size: 13)
        let atr = NSAttributedString(string: "Already have account?", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        label.attributedText = atr
        label.textColor = .darkGray
        return label
    }()
    
    //MARK: - Selectors
    @objc private func buttonTapped() {
        guard let email = emailTextField.text,
              let password = passwordTextField.text,
              let username = usernameTextField.text,
              let fullname = fullnameTextField.text,
              !email.isEmpty, !password.isEmpty, !username.isEmpty, !fullname.isEmpty, password.count >= 8 else {
            alertAuthError()
            return
        }
        guard isChecked == true else {
            alertNoTermError()
            return
        }
        spinner.show(in: view)
        //Auth.auth().currentUser?.createProfileChangeRequest()
        Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
            if let error = error {
                debugPrint("DEBUG: \(error.localizedDescription)")
                self.alertUserAlreadyExists()
            }
            
            //Authで使うのは、email password  そのUserのデータをAuthのメソッドで持っておくことができる！
            //プロフィール情報の更新→ProfileVCがないから、登録時点で代替するものが必要？
            let changeRequest = user?.user.createProfileChangeRequest()
            changeRequest?.displayName = fullname
            changeRequest?.commitChanges(completion: { (error) in
                if let error = error {
                    debugPrint("DEBUG: \(error.localizedDescription)")
                }
            })
            
            guard let userId = user?.user.uid else {
                DispatchQueue.main.async {
                    self.spinner.dismiss()
                }
                return
            }
            
            //Firestoreにあらためて保存
            Firestore.firestore().collection(USERS_REF).document(userId)
                .setData([
                    USER_ID : userId,
                    USERNAME : username,
                    FULLNAME : fullname,
                    TIMESTAMP : FieldValue.serverTimestamp(),
                    BIO : "",
                    POSTS_COUNT : 0,
                    POST_LIKES_COUNT : 0
                ]) { (error) in
                    
                    DispatchQueue.main.async {
                        self.spinner.dismiss()
                    }
                    if let error = error {
                        debugPrint("DEBUG: \(error.localizedDescription)")
                    }
                    else {
                        self.dismiss(animated: true)
                    }
                }
            
        }
    }
    private func alertUserAlreadyExists() {
        let alert = UIAlertController(title: "Woops", message: "すでにこのEmailアカウントは存在します。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "戻る", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func alertAuthError() {
        let alert = UIAlertController(title: "Oops", message: "Fillout all information\nパスワードは8文字以上", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "戻る", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    private func alertNoTermError() {
        let alert = UIAlertController(title: "Agreement Error", message: "利用規約に同意してください。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "戻る", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.backgroundColor = UIColor(patternImage: UIImage(named: "paperBg")!)
        let tap = UITapGestureRecognizer(target: self, action: #selector(hasAccountTapped))
        hasAccountLabel.addGestureRecognizer(tap)
        hasAccountLabel.isUserInteractionEnabled = true
        addSubViews()
        exposeEyeButton.addTarget(self, action: #selector(exposeTapped), for: .touchUpInside)
        let tapTerm = UITapGestureRecognizer(target: self, action: #selector(didTapTermLabel))
        termLabel.addGestureRecognizer(tapTerm)
        termLabel.isUserInteractionEnabled = true
        checkBox.addTarget(self, action: #selector(buttonClicked(sender:)), for: .touchUpInside)
        isChecked = false
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        scrollView.frame = view.bounds
        emailTextField.anchor(top: scrollView.safeAreaLayoutGuide.topAnchor, left: scrollView.leftAnchor, paddingTop: 14, paddingLeft: 20, width: scrollView.width-40, height: 30)
        passwordTextField.anchor(top: emailTextField.bottomAnchor, left: scrollView.leftAnchor, paddingTop: 14, paddingLeft: 20, width: scrollView.width-40, height: 30)
        exposeEyeButton.anchor(top: passwordTextField.topAnchor, right: passwordTextField.rightAnchor, paddingTop: 1, paddingRight: 2, height: 26)
        usernameTextField.anchor(top: passwordTextField.bottomAnchor, left: scrollView.leftAnchor, paddingTop: 14, paddingLeft: 20,  width: scrollView.width-40, height: 30)
        fullnameTextField.anchor(top: usernameTextField.bottomAnchor, left: scrollView.leftAnchor, paddingTop: 14, paddingLeft: 20, width: scrollView.width-40, height: 30)
        termLabel.anchor(top: fullnameTextField.bottomAnchor, paddingTop: 16, height: 30)
        termLabel.centerX(inView: scrollView)
        checkBox.anchor(top: termLabel.topAnchor, right: termLabel.leftAnchor, paddingRight: 5, width: 30, height: 30)
        button.anchor(top: termLabel.bottomAnchor, paddingTop: 20)
        button.centerX(inView: scrollView)
        hasAccountLabel.anchor(top: button.bottomAnchor, paddingTop: 16, height: 30)
        hasAccountLabel.centerX(inView: scrollView)
        
    }
    @objc private func exposeTapped() {
        if(iconClick == true) {
            passwordTextField.isSecureTextEntry = false
            exposeEyeButton.setImage(UIImage(systemName: "eye"), for: .normal)
        } else {
            passwordTextField.isSecureTextEntry = true
            exposeEyeButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        }
        iconClick = !iconClick
    }
    @objc private func hasAccountTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func didTapTermLabel() {
        let url = URL(string: "https://howtoeducate-ba7a4.web.app/terms")
        let vc = SFSafariViewController(url: url!)
        present(vc, animated: true)
    }
    
    //checkBox
    @objc func buttonClicked(sender: UIButton) {
            isChecked = !isChecked
    }
    
    private func addSubViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordTextField)
        scrollView.addSubview(exposeEyeButton)
        scrollView.addSubview(usernameTextField)
        scrollView.addSubview(fullnameTextField)
        scrollView.addSubview(button)
        scrollView.addSubview(checkBox)
        scrollView.addSubview(termLabel)
        scrollView.addSubview(hasAccountLabel)
    }
    
    
    
    
}
extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        }else if textField == passwordTextField {
            usernameTextField.becomeFirstResponder()
        }else if textField == usernameTextField {
            fullnameTextField.becomeFirstResponder()
        }
        else if textField == fullnameTextField {
            //handleSignUp(RegisterButton)
            //textField.endEditing(true)
            textField.resignFirstResponder()
        }
        return true
    }
}


extension UITextField {
    func disableAutoFill() {
        if #available(iOS 12, *) {
            textContentType = .oneTimeCode
        } else {
            textContentType = .init(rawValue: "")
        }
    }
}
