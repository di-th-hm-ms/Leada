//
//  ReportViewController.swift
//  HowToEducate
//
//  Created by Lon on 2021/01/26.
//

import UIKit
import Firebase

class ReportViewController: UIViewController {
    
    //MARK: - properties
    var post: Post?
    var user: User?
    let texts = ["興味のない内容", "刺激的または不適切な内容", "不要な広告", "人を傷つけるような内容"]
    let tableView: UITableView = {
        let tableView = UITableView()
        
        tableView.backgroundColor = .white
        return tableView
    }()
    
    init(post: Post?, user: User?) {
        super.init(nibName: nil, bundle: nil)
        self.post = post
        self.user = user
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createHeaderView()
        tableView.tableFooterView = createFooterView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "reportCell")
        //        tableView.tableFooterView = createFooterView()
        view.addSubview(tableView)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "キャンセル", style: .done, target: self, action: #selector(cancelButtonTapped))
        navigationController?.navigationBar.barTintColor = lightPurple
        navigationController?.navigationBar.tintColor = darkPurple
        
        
    }
    
    override func viewWillLayoutSubviews() {
        if let header = tableView.tableHeaderView{
            tableView.anchor(top: header.bottomAnchor, left: view.leftAnchor, width: view.width, height: view.height)
        }
        
    }
    
    private func createHeaderView() -> UIView {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: view.height/15).integral)
        let label = UILabel(frame: CGRect(x: 10, y: 10, width: view.width-20, height: view.height/16).integral)
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "このユーザー・投稿・コメントにどのような問題がありましたか？ご協力よろしくお願いいたします。"
        label.textColor = .blue
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        header.addSubview(label)
        
        return header
    }
    
    private func createFooterView() -> UIView {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: view.height/10).integral)
        let label = UILabel(frame: CGRect(x: 20, y: 10, width: view.width-20, height: footer.height/5))
        label.font = UIFont(name: "Copperplate", size: 14)
        let atr = NSAttributedString(string: "プライバシーポリシー", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        label.attributedText = atr
        label.textColor = darkPurple
        footer.addSubview(label)
        
        return footer
    }
    
    @objc private func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    
    
}
extension ReportViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return texts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reportCell", for: indexPath)
        cell.textLabel?.text = texts[indexPath.row]
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        if let post = self.post {
            Firestore.firestore().collection(REPORTS_REF)
                .addDocument(data: ["category" : texts[indexPath.row],
                                    "postId" : post.documentId,
                                    REPORTING_USER_ID : currentUser.uid,
                                    REPORTED_USER_ID : "none"]) { (error) in
                    if let error = error {
                        debugPrint("DEBUG: \(error)")
                    } else {
                        let vc = ReportCompletedViewController()
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
        } else if let user = self.user {
            Firestore.firestore().collection(REPORTS_REF)
                .addDocument(data: ["category" : texts[indexPath.row],
                                    "postId" : "none",
                                    REPORTING_USER_ID : currentUser.uid,
                                    REPORTED_USER_ID : user.userId]) { (error) in
                    if let error = error {
                        debugPrint("DEBUG: \(error)")
                    } else {
                        let vc = ReportCompletedViewController()
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
        } else {
            return
        }
        
    }
    
}
