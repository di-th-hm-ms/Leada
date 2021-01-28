//
//  AccountInfoViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/11/12.
//

import UIKit


class AccountInfoViewController: UIViewController {
    
    private let titles = ["メールアドレス", "パスワード"]
    
    private var tableView: UITableView = {
        let tv = UITableView()
        tv.register(AccountInfoCell.self, forCellReuseIdentifier: AccountInfoCell.identifier)
        tv.separatorColor = lightPurple
        return tv
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor =  UIColor.rgb(red: 243, green: 243, blue: 243)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        self.edgesForExtendedLayout = .all
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 16, width: view.width, height: 80)
        //tableView.frame = view.bounds
    }
    

}

extension AccountInfoViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//
//        let headerView = UIView()
//        headerView.setDimensions(width: view.width, height: 20)
//        headerView.backgroundColor = UIColor.rgb(red: 243, green: 243, blue: 243)
//        return headerView
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AccountInfoCell.identifier, for: indexPath) as! AccountInfoCell
        cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
        //cell.configure(title: titles[indexPath.row])
        switch indexPath.row {
        case 0:
            cell.configure(title: titles[0])
        default:
            cell.configure(title: titles[1])
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let emailChangeVC = EmailUpdateViewController()
        let passwordChangeVC = PasswordUpdateViewController()
        if indexPath.row == 0 {
            navigationController?.pushViewController(emailChangeVC, animated: true)
        }
        else {
            navigationController?.pushViewController(passwordChangeVC, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40.0
    }
    
}
