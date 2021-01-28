//
//  SettingViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/10/29.
//

import UIKit
import Firebase
import SafariServices
import GoogleSignIn


class SettingViewController: UIViewController {
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(SettingCell.self, forCellReuseIdentifier: SettingCell.identifier)
        tableView.backgroundColor = UIColor.rgb(red: 243, green: 243, blue: 243)
        tableView.separatorStyle = .none
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor =  UIColor.rgb(red: 243, green: 243, blue: 243)
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        
        //いらないかも
        self.edgesForExtendedLayout = .all
        
        if GIDSignIn.sharedInstance()?.hasPreviousSignIn() == true {
            GIDSignIn.sharedInstance()?.restorePreviousSignIn()
        }
    }
    
    override func viewDidLayoutSubviews() {
        tableView.frame = view.bounds
    }
    
}

extension SettingViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 4
        }
        else {
            return 3
        }
    }
    
    
    //sectionHeaderCustomiza
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UIView()
        headerView.setDimensions(width: view.width-10, height: 20)
        headerView.backgroundColor = UIColor.rgb(red: 243, green: 243, blue: 243)
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingCell.identifier,
                                                 for: indexPath) as! SettingCell
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        let sectionNumber = indexPath.section
        let rowNumber = indexPath.row
        switch sectionNumber {
        case 0:
            switch rowNumber {
            case 0:
                if (GIDSignIn.sharedInstance()?.hasPreviousSignIn()) == true && GIDSignIn.sharedInstance()?.currentUser != nil {
                    print("Googleでサインイン中！！！")
                    cell.configure(title: "アカウント設定", googleUser: true)
                }
                else {
                    cell.configure(title: "アカウント設定", googleUser: false)
                }
            case 1:
                cell.configure(title: "問い合わせ", googleUser: nil)
            case 2:
                cell.configure(title: "プライバシーポリシー", googleUser: nil)
            default:
                cell.configure(title: "利用規約", googleUser: nil)
            }
        default:
            switch rowNumber {
            case 0:
                cell.configure(title: "通知", googleUser: nil)
            case 1:
                cell.configure(title: "ログアウト", googleUser: nil)
            default:
                cell.configure(title: "退会する", googleUser: nil)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //let cell = self.tableView(tableView, cellForRowAt: indexPath) as! SettingCell
        let rowNumber = indexPath.row
        let accountVC = AccountInfoViewController()
        let notificationVC = NotificationSettingViewController()
        let deleteAccountVC = DeleteAccountViewController()
        
        //safari
        var urlString: String = ""
        
        switch indexPath.section {
        case 0:
            switch rowNumber {
            case 0:
                if (GIDSignIn.sharedInstance()?.hasPreviousSignIn()) == false || GIDSignIn.sharedInstance()?.currentUser == nil {
                    navigationController?.pushViewController(accountVC, animated: true)
                }
                break
            case 1:
                //お問い合わせ contact
                urlString = "https://howtoeducate-ba7a4.web.app/"
            case 2:
                //よくある質問 questions
                urlString = "https://howtoeducate-ba7a4.web.app/policy"
            default:
                //利用規約 rule
                urlString = "https://howtoeducate-ba7a4.web.app/terms"
            }
            guard let url = URL(string: urlString) else {
                return
            }
            let vc = SFSafariViewController(url: url)
            present(vc, animated: true)
            
        default:
            switch rowNumber {
            case 0:
                navigationController?.pushViewController(notificationVC, animated: true)
            case 1:
                //logout
                let alert = UIAlertController(title: "ログアウト", message: "再度ログインする必要があります。", preferredStyle: .alert)
                let logout = UIAlertAction(title: "ログアウト", style: .destructive) { (_) in
                    if GIDSignIn.sharedInstance()?.currentUser != nil {
                        print("GoogleUserからログアウトしました。")
                        GIDSignIn.sharedInstance()?.signOut()
                    }
                    
                    do {
                        
                        try Auth.auth().signOut()
                    } catch let error {
                        debugPrint(error.localizedDescription)
                    }
                    self.navigationController?.popToRootViewController(animated: true)
                }
                let cancel = UIAlertAction(title: "戻る", style: .cancel, handler: nil)
                alert.addAction(logout)
                alert.addAction(cancel)
                present(alert, animated: true, completion: nil)
                break
            default:
                //退会
                navigationController?.pushViewController(deleteAccountVC, animated: true)
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
}

extension SettingViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}
