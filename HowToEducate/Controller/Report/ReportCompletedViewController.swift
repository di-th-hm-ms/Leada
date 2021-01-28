//
//  ReportCompletedViewController.swift
//  HowToEducate
//
//  Created by Lon on 2021/01/26.
//

import UIKit

class ReportCompletedViewController: UIViewController {
    
    //var post: Post!
    
    let thanksLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Copperplate", size: 16)
        label.text = "貴重なご意見ありがとうございました。\n メールからも問い合わせ可能です。"
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        return label
    }()
    
    let mailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "GillSans-SemiBold", size: 14)
        let atr = NSAttributedString(string: "longt.humanity@gmail.com", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        label.attributedText = atr
        label.textColor = .darkGray
        return label
    }()
    
    let alertLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Copperplate", size: 13)
        let atr = NSAttributedString(string: "同じユーザー・投稿・コメントに複数件問い合わせがあった場合\nやむを得ず削除させていただく場合がございます。", attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue])
        label.attributedText = atr
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(thanksLabel)
        view.addSubview(mailLabel)
        view.addSubview(alertLabel)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "完了", style: .done, target: self, action: #selector(didTapDone))
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        thanksLabel.centerX(inView: view, topAnchor: view.safeAreaLayoutGuide.topAnchor, paddingTop: view.height/3)
        thanksLabel.anchor(height: 80)
        mailLabel.centerX(inView: view, topAnchor: thanksLabel.bottomAnchor, paddingTop: 20)
        alertLabel.centerX(inView: view, topAnchor: mailLabel.bottomAnchor, paddingTop: 20)
//        thanksLabel.anchor(height: 100)
//        alertLabel.anchor(width: view.width-20, height: 100)
    }
    
    @objc private func didTapDone() {
        dismiss(animated: true, completion: nil)
    }

}
