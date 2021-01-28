//
//  LoginViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/10/27.
//

import UIKit
import Firebase
import JGProgressHUD

class EmailLoginViewController: UIViewController {
    
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
        textField.keyboardType = .emailAddress
        textField.textContentType = .username
        textField.returnKeyType = .continue
        return textField
    }()
    
    private let passwordTextField: UITextField = {
        let textField = Utilities().textField(withPlaceholder: "パスワード")
        configureTextField(textField: textField)
        textField.isSecureTextEntry = true
        textField.keyboardType = .emailAddress
        textField.textContentType = .password
        textField.returnKeyType = .done
        return textField
    }()
    
    private var iconClick = true
    private let exposeEyeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = purple
        return button
    }()
    
    let button: UIButton = {
        let button = UIButton()
        button.setTitle("Login", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setDimensions(width: 130, height: 40)
        button.backgroundColor = purple
        //        button.layer.borderWidth = 1
        //        button.layer.borderColor = UIColor.cgColor
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.layer.cornerRadius = 10
        button.layer.shadowColor = purple.cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 5
        button.layer.shadowOffset = CGSize(width: 5, height: 5)
        return button
    }()
    
    let noAccountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Copperplate", size: 13)
        let atr = NSAttributedString(string: "Have you no account?", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        label.attributedText = atr
        label.textColor = .darkGray
        return label
    }()
    
    let loginWaysLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Copperplate", size: 13)
        let atr = NSAttributedString(string: "Choose how to login.", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        label.attributedText = atr
        label.textColor = .gray
        return label
    }()
    
    //MARK: - Selectors
    @objc private func buttonTapped() {
        guard let email = emailTextField.text,
              let password = passwordTextField.text, !email.isEmpty, !password.isEmpty, password.count >= 8 else {
            alertAuthError()
            return
        }
        spinner.show(in: view)
        
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            //            guard let strongSelf = self else {
            //                return
            //            }
            DispatchQueue.main.async {
                self.spinner.dismiss()
            }
            
            if let error = error {
                debugPrint("DEBUG: \(error.localizedDescription)")
                let alert = UIAlertController(title: "Woops", message: "Emailまたはパスワードが間違っています。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "戻る", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
            else {
                //self.dismiss(animated: true, completion: nil)
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
    }
    
    private func alertAuthError() {
        let alert = UIAlertController(title: "Woops", message: "Fillout all information\nパスワードは8文字以上", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "戻る", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.backgroundColor = UIColor(patternImage: UIImage(named: "paperBg")!)
        navigationController?.navigationBar.isHidden = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(noAccountTapped))
        noAccountLabel.addGestureRecognizer(tap)
        noAccountLabel.isUserInteractionEnabled = true
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(chooseLoginTapped))
        loginWaysLabel.addGestureRecognizer(tap2)
        loginWaysLabel.isUserInteractionEnabled = true
        addSubViews()
        exposeEyeButton.addTarget(self, action: #selector(exposeTapped), for: .touchUpInside)
    }
    @objc private func noAccountTapped() {
        let vc = RegisterViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    @objc private func chooseLoginTapped() {
        navigationController?.popViewController(animated: true)
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
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        scrollView.frame = view.bounds
        emailTextField.anchor(top: scrollView.safeAreaLayoutGuide.topAnchor, left: scrollView.leftAnchor, right: scrollView.rightAnchor, paddingTop: 14, paddingLeft: 20, width: scrollView.width-40)
        passwordTextField.anchor(top: emailTextField.bottomAnchor, left: scrollView.leftAnchor, right: scrollView.rightAnchor, paddingTop: 16, paddingLeft: 20, width: scrollView.width-40)
        exposeEyeButton.anchor(top: passwordTextField.topAnchor, right: passwordTextField.rightAnchor, paddingRight: 2, height: 26)
        button.anchor(top: passwordTextField.bottomAnchor, paddingTop: 20)
        button.centerX(inView: scrollView)
        noAccountLabel.anchor(top: button.bottomAnchor, paddingTop: 16, height: 30)
        noAccountLabel.centerX(inView: scrollView)
        loginWaysLabel.anchor(top: noAccountLabel.bottomAnchor, paddingTop: 10, height: 30)
        loginWaysLabel.centerX(inView: scrollView)
        
    }
    
    private func addSubViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordTextField)
        scrollView.addSubview(exposeEyeButton)
        scrollView.addSubview(button)
        scrollView.addSubview(noAccountLabel)
        scrollView.addSubview(loginWaysLabel)
        
    }
    
}
