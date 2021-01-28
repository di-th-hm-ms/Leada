//
//  EmailChangeViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/11/26.
//

import UIKit
import Firebase
import JGProgressHUD

struct UpdateAuthFormModel {
    let placeholder: String
    var value: String?
}

class EmailUpdateViewController: UIViewController {

    private let titles = ["新しいメールアドレス", "パスワード"]
    var models = [[UpdateAuthFormModel]]() //firestore で取得した時の値。
    var updatedUserAuth = [EMAIL : "", PASSWORD : ""]
    private let spinner = JGProgressHUD(style: .light)
    
    private var tableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .white
        tv.register(HowToEducate.EmailUpdateCell.self, forCellReuseIdentifier: HowToEducate.EmailUpdateCell.identifier)
        //Static member 'identifier' cannot be used on instance of type 'FormTableViewCell' インスタンスに依存しないので、インスタンス化してから参照すると怒られる
        tv.separatorColor = lightPurple
        return tv
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存", style: .plain, target: self, action: #selector(didTapSaveButton))
        view.backgroundColor =  UIColor.rgb(red: 243, green: 243, blue: 243)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        var model: UpdateAuthFormModel
        var sections = [UpdateAuthFormModel]()
        for title in titles {
            switch title {
            case "新しいメールアドレス":
                model = UpdateAuthFormModel(placeholder: title, value: currentUser.email)
            default:
                model = UpdateAuthFormModel(placeholder: title) //passwordはクライアントサイドで保持して良いのかわからない。
            }
            
            sections.append(model)
        }
        models.append(sections)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //tableView.frame = view.bounds
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 16, width: view.width, height: 80)
    }
    
    @objc private func didTapSaveButton() {
        //Auth.auth().updateCurrentUser(<#T##user: User##User#>, completion: <#T##((Error?) -> Void)?##((Error?) -> Void)?##(Error?) -> Void#>)
        
        guard let currentUser = Auth.auth().currentUser, let password = updatedUserAuth[PASSWORD], let updatedEmail = self.updatedUserAuth[EMAIL] else {
            let alert = UIAlertController(title: "PasswordIsNotFilled", message: "新しいメールアドレスとパスワードを入力してください。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "戻る", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        //古いEmailの入力はさせるか迷うな
        let credential = EmailAuthProvider.credential(withEmail: currentUser.email!, password: password)
        spinner.show(in: view)
        currentUser.reauthenticate(with: credential) { (authResult, error) in
            if let error = error {
                DispatchQueue.main.async {
                    self.spinner.dismiss()
                }
                let alert = UIAlertController(title: "PasswordIsNotCollect", message: "パスワードが間違っています。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "戻る", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                debugPrint("DEBUG: 認証に失敗しました。 \(error)")
            }
            else {
                Auth.auth().currentUser?.updateEmail(to: updatedEmail, completion: { (error) in
                    DispatchQueue.main.async {
                        self.spinner.dismiss()
                    }
                    if let error = error {
                        let alert = UIAlertController(title: "EmailUpdateError", message: "Emailのアップデートに失敗しました。", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "戻る", style: .cancel, handler: nil))
                        debugPrint("DEBUG: Unable to udpate your email：\(error)")
                        self.present(alert, animated: true, completion: nil)
                    }
                    else {
                        self.navigationController?.popViewController(animated: true)
                    }
                    
                })
            }
        }
        
        
        //Auth.auth().currentUser?.updatePassword(to: <#T##String#>, completion: <#T##((Error?) -> Void)?##((Error?) -> Void)?##(Error?) -> Void#>)
    }
    

}

extension EmailUpdateViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HowToEducate.EmailUpdateCell.identifier, for: indexPath) as! EmailUpdateCell
        cell.delegate = self
        switch indexPath.row {
        case 1:
            cell.configure(with: models[0][indexPath.row])
        default:
            cell.configure(with: models[0][indexPath.row])
        }
        //cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40.0
    }
    
}

//
extension EmailUpdateViewController: EmailUpdateCellDelegate {
    func EmailUpdateCell(_ cell: EmailUpdateCell, didUpdateField updatedModel: UpdateAuthFormModel) {
//        guard let currentUser = Auth.auth().currentUser else {
//            return
//        }
        switch updatedModel.placeholder {
        case "新しいメールアドレス":
            updatedUserAuth[EMAIL] = updatedModel.value
        default:
            updatedUserAuth[PASSWORD] = updatedModel.value
        }
    }
}
