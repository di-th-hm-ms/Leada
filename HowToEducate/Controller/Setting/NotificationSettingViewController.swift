//
//  NotificationSettingViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/11/12.
//

import UIKit

class NotificationSettingViewController: UIViewController {
    
    //logo
    
    let noFunctionLabel: UILabel = {
        let label = UILabel()
        label.textColor = darkPurple
        label.text = "Sorry notification hasn't come yet "
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.layer.shadowColor = purple.cgColor
        label.layer.shadowOpacity = 1
        label.layer.shadowRadius = 3
        label.layer.shadowOffset = CGSize(width: 3, height: 3)
        //shadow
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(noFunctionLabel)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        noFunctionLabel.center(inView: view)
    }
}
