//
//  MailViewController.swift
//  HowToEducate
//
//  Created by Lon on 2021/01/09.
//

import UIKit
import MessageUI
import Firebase

class MailViewController: UIViewController, MFMailComposeViewControllerDelegate{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = .white
        configureMail()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        configureMail()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        
    }
    
    private func configureMail() {
        //メールを送信できるかチェック
        if MFMailComposeViewController.canSendMail() {
            let mailViewController = MFMailComposeViewController()
            let toRecipients = ["longt.humanity@gmail.com"]
            let CcRecipients = [""]
            let BccRecipients = ["Bcc@1gmail.com","Bcc2@1gmail.com"]
            
            
            mailViewController.mailComposeDelegate = self
            mailViewController.setSubject("メールの件名")
            mailViewController.setToRecipients(toRecipients) //Toアドレスの表示
            mailViewController.setCcRecipients(CcRecipients) //Ccアドレスの表示
            mailViewController.setBccRecipients(BccRecipients) //Bccアドレスの表示
            mailViewController.setMessageBody("\((Auth.auth().currentUser?.email)!)\nそのまま送信を押してください。", isHTML: false)
            
            self.present(mailViewController, animated: false, completion: nil)
        } else {
            let alert = UIAlertController(title: "送信失敗", message: "送信できませんでした。", preferredStyle: .alert)
            let cancel = UIAlertAction(title: "閉じる", style: .cancel, handler: nil)
            alert.addAction(cancel)
            present(alert, animated: true, completion: nil)
        }
        
        
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        if result == MFMailComposeResult.cancelled {
            print("メール送信がキャンセルされました")
        } else if result == MFMailComposeResult.saved {
            print("下書きとして保存されました")
        } else if result == MFMailComposeResult.sent {
            print("メール送信に成功しました")
        } else if result == MFMailComposeResult.failed {
            print("メール送信に失敗しました")
        }
        dismiss(animated: true, completion: nil) //閉じる
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
