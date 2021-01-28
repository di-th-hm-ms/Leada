//
//  LoginViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/12/11.
//

import UIKit
import GoogleSignIn
import Firebase

class LoginViewController: UIViewController {
    
    let googleSignInButton: GIDSignInButton = {
        let button = GIDSignInButton()
        button.style = .wide
        return button
    }()
    let logoImageView: UIImageView = {
        let imageView = UIImageView()
        //width height →view.widthで判定
        imageView.image = UIImage(name: "iconImage")
        imageView.layer.corner
        return imageView
    }()
    
    let emailLogoButton: UIButton = {
       let button = UIButton()
        button.backgroundColor = .clear
        button.setImage(UIImage(systemName: "envelope"), for: .normal)
        button.tintColor = .white
        return button
    }()
    let toEmailLoginButton: UIButton = {
       let button = UIButton()
        button.backgroundColor = purple
        button.setTitle("Emailでログイン", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont(name: "IowanOldStyle-Bold",size: 14)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = purple
        //        button.layer.borderWidth = 1
        //        button.layer.borderColor = UIColor.cgColor
        button.layer.cornerRadius = 1
        button.layer.shadowColor = purple.cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 3
        button.layer.shadowOffset = CGSize(width: 3, height: 3)
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
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(patternImage: UIImage(named: "paperBg")!)
        navigationController?.navigationBar.isHidden = true
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance()?.delegate = self
        
        toEmailLoginButton.addTarget(self, action: #selector(didTapEmailLoginButton), for: .touchUpInside)
        view.addSubview(googleSignInButton)
        view.addSubview(toEmailLoginButton)
        view.addSubview(noAccountLabel)
        toEmailLoginButton.addSubview(emailLogoButton)
        let tap = UITapGestureRecognizer(target: self, action: #selector(noAccountTapped))
        noAccountLabel.addGestureRecognizer(tap)
        noAccountLabel.isUserInteractionEnabled = true
    }
    override func viewDidAppear(_ animated: Bool) {
        if Auth.auth().currentUser != nil {
            dismiss(animated: true, completion: nil)
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        googleSignInButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 20)
        googleSignInButton.centerX(inView: view)
        toEmailLoginButton.anchor(top: googleSignInButton.bottomAnchor, paddingTop: 20, width: 190, height: 30)
        toEmailLoginButton.centerX(inView: view)
        noAccountLabel.anchor(top: toEmailLoginButton.bottomAnchor, paddingTop: 16, height: 30)
        noAccountLabel.centerX(inView: view)
        emailLogoButton.anchor(top: toEmailLoginButton.topAnchor, left: toEmailLoginButton.leftAnchor, paddingTop: 5, paddingLeft: 10, width: 20, height: 20)
    }
    
    @objc private func noAccountTapped() {
        let vc = RegisterViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    @objc private func didTapEmailLoginButton() {
        let vc = EmailLoginViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

}

extension LoginViewController: GIDSignInDelegate {
    //このメソッドは GIDSignIn インスタンスの handleURL メソッドを呼び出します。これによって、認証プロセスの最後にアプリが受け取る URL が正しく処理されます。
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any])
      -> Bool {
      return GIDSignIn.sharedInstance().handle(url)
    }
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        var gidInfo = [USER_ID : "", USERNAME : "", FULLNAME : ""]
          if let error = error {
            debugPrint("DEBUG: \(error)")
            return
        }
          else {
            let userId = user.userID //for-clientSide use only
            let idToken = user.authentication.idToken //Safe to send to the server
            let fullName = user.profile.name
            let giveName = user.profile.givenName //与えられた下の名前
            let familyName = user.profile.familyName
            print("userId: \(userId), 成功 \(user.profile.email ?? "no email")")
            gidInfo[USER_ID] = userId
            gidInfo[FULLNAME] = fullName
          }
        
        guard let authentication = user.authentication else {
            return
        }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        //createUserはcredentialでできないので、AuthのphotoURLとか変更するのは難しそう。
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                debugPrint("DEBUG: \(error)")
            }
            //Firestoreにあらためて保存
            guard let currentUser = Auth.auth().currentUser else { return }
            //print("FullName\(Auth.auth().currentUser?.displayName)") しっかりFullName←自動で入れられるのかも
            //気づき：photoURLも自動で画像が反映されている。
            Firestore.firestore().collection(USERS_REF).document(currentUser.uid)
                .setData([
                    USER_ID : currentUser.uid,
                    USERNAME : "",
                    FULLNAME : gidInfo[FULLNAME],
                    TIMESTAMP : FieldValue.serverTimestamp(),
                    BIO : "",
                    POSTS_COUNT : 0,
                    POST_LIKES_COUNT : 0,
                    PROFILE_IMAGE_URL_STR : currentUser.photoURL?.absoluteString ?? ""
                    //ID_TOKEN :
                ]) { (error) in

//                    DispatchQueue.main.async {
//                        self.spinner.dismiss()
//                    }
                    if let error = error {
                        debugPrint("DEBUG: \(error.localizedDescription)")
                    }
                    else {
                        self.dismiss(animated: true)
                    }
                }
            self.dismiss(animated: true)
        }
        
    }
}
