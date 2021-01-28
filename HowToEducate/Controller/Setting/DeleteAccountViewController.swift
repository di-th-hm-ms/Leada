//
//  DeleteAccountViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/11/12.
//

import UIKit
import Firebase
import JGProgressHUD
import GoogleSignIn
import MessageUI

class DeleteAccountViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    
    //MARK: - Property
    private let firestore = Firestore.firestore()
    private var allPostsDocuments = [String]()
    private var myCommentsDocuments = [String]()
    private var likedUsersDocuments = [String]()
    
    private let spinner = JGProgressHUD(style: .light)
    private var handle: AuthStateDidChangeListenerHandle?
    
    private var googleUser: Bool = true
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    private let alertLabel: UILabel = {
        let label = UILabel()
        label.text = "退会する前にご確認ください"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = purple
        return label
    }()
    
    private let alertDetailLabel: UILabel = {
        let label = UILabel()
        label.textColor = .darkGray
        label.font = UIFont.systemFont(ofSize: 15)
        label.lineBreakMode = .byCharWrapping
        label.numberOfLines = 0
        label.text = "HowToEducateの退会処理が完了すると、あなたのアカウントは削除されてこのアプリを利用できなくなります。また、再度登録しても過去のデータが引き継がれることはありません。"
        return label
    }()
    
    private let deleteAccountButton: UIButton = {
        let button = UIButton()
        button.setTitle("同意して退会する", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.setDimensions(width: 200, height: 40)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = darkPurple
        button.layer.cornerRadius = 40/2
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor =  UIColor.rgb(red: 243, green: 243, blue: 243)
        addSubViews()
        deleteAccountButton.addTarget(self, action: #selector(didTapDeleteButton), for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        containerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 15, width: view.width, height: 280)
        alertLabel.anchor(top: containerView.topAnchor, paddingTop: 20)
        alertLabel.centerX(inView: containerView)
        alertDetailLabel.anchor(top: alertLabel.bottomAnchor, left: containerView.leftAnchor, right: containerView.rightAnchor, paddingTop: 25, paddingLeft: 15, paddingRight: 15)
        deleteAccountButton.anchor(top: alertDetailLabel.bottomAnchor, paddingTop: 30)
        deleteAccountButton.centerX(inView: containerView)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        getAllPostsDocuments()
    }
    
    private func getAllPostsDocuments() {
        //セキュリティルール的に他のUserのPostの読み取りもできるはず
        firestore.collection(POSTS_REF).getDocuments { (snapshot, error) in
            if let error = error {
                debugPrint("DEBUG: \(error.localizedDescription)")
            }
            else {
                guard let snapshot = snapshot else {
                    return
                }
                let documents = snapshot.documents
                for document in documents {
                    //let data = document.data()
                    let documentId = document.documentID
                    //print(documentId)
                    self.allPostsDocuments.append(documentId)
                }
            }
        }
    }
    
    @objc private func didTapDeleteButton() {
        googleUser = true
        let alert = UIAlertController(title: "アカウントを削除しますか？", message: "削除されたデータの復元はできません。", preferredStyle: .alert)
        let delete = UIAlertAction(title: "削除", style: .destructive, handler: { _ in
            guard let currentUser = Auth.auth().currentUser else {
                return
            }
            
            guard GIDSignIn.sharedInstance()?.hasPreviousSignIn() == true else {
                //print("currentUserでひっかかる")
                self.googleUser = false
                let alert = UIAlertController(title: "本当に削除しますか？", message: "確認のため、パスワードを入力してください。", preferredStyle: .alert)
                alert.addTextField { (textField) in
                    //textField.delegate = self
                    textField.isSecureTextEntry = true
                    //                guard let textField = textField.text else { return }
                    //                password = textField
                }
                alert.addAction(UIAlertAction(title: "実行", style: .destructive, handler: { _ in
                    print((alert.textFields?[0].text)!)
                    let credential = EmailAuthProvider.credential(withEmail: currentUser.email!, password: (alert.textFields?[0].text)!)
                    Auth.auth().currentUser?.reauthenticate(with: credential, completion: { (authResult, error) in
                        if let error = error {
                            DispatchQueue.main.async {
                                self.spinner.dismiss()
                            }
                            let alert = UIAlertController(title: "PasswordIsNotCollect", message: "パスワードが間違っています。", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "戻る", style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            debugPrint("DEBUG: 再認証に失敗しました。 \(error)")
                        } else {
                            self.deleteAccount(self.googleUser)
                        }
                    })
                }))
                alert.addAction(UIAlertAction(title: "戻る", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            
            let applyDelete = UIAlertController(title: "アカウント削除の申請", message: "Googleアカウントに基づくアカウントの削除は申請を行います。", preferredStyle: .alert)
            let apply = UIAlertAction(title: "申請", style: .destructive) { (_) in
                self.configureMail()
            }
            let cancel = UIAlertAction(title: "戻る", style: .cancel, handler: nil)
            applyDelete.addAction(apply)
            applyDelete.addAction(cancel)
            self.present(applyDelete, animated: true, completion: nil)
            //共通
            ///Authenticationから削除→LoginViewへ
           
            
            
        })
        let cancel = UIAlertAction(title: "戻る", style: .cancel, handler: nil)
        alert.addAction(cancel)
        alert.addAction(delete)
        present(alert, animated: true, completion: nil)
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
            mailViewController.setMessageBody("\((Auth.auth().currentUser?.email)!)\nそのまま送信を押してください。\nFrom Leada Inquiry.", isHTML: false)
            
            self.present(mailViewController, animated: true, completion: nil)
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
    private func addSubViews() {
        
        view.addSubview(containerView)
        containerView.addSubview(alertLabel)
        containerView.addSubview(alertDetailLabel)
        containerView.addSubview(deleteAccountButton)
    }
    
    private func deleteAccount(_ googleUser: Bool) {
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        ///CloudFunctions
        ///users, likedPostsから削除
        self.spinner.show(in: self.view)
        self.delete(collection: self.firestore.collection(USERS_REF).document(currentUser.uid).collection(LIKED_POST)) { (error) in
            if let error = error {
                debugPrint("DEBUG: \(error)")
            } else {
                self.delete(collection: self.firestore.collection(USERS_REF).document(currentUser.uid).collection(BLOCKING_USERS_REF)) { (error) in
                    if let error = error {
                        debugPrint("DEBUG: \(error)")
                    } else {
                        self.firestore.collection(USERS_REF).document(currentUser.uid).delete { (error) in
                            if let error = error {
                                debugPrint("DEBUG: \(error)")
                            } else {
                                ///storageから削除
                                if googleUser == false {
                                    self.deleteProfileImage()
                                }
                                else {
                                    print("GoogleUserのプロフィール画像は削除せずに放置 URLの構造がfirebasesotrageだったとしても")
                                }
                            }
                        }
                    }
                }
            }
            ///post, comment, likedUssers,
            for documentId in self.allPostsDocuments {
                self.firestore.collection(POSTS_REF).document(documentId).collection(COMMENTS_REF).whereField(USER_ID, isEqualTo: currentUser.uid).getDocuments { (snapshot, error) in
                    
                    guard let snapshot = snapshot else {
                        let actionSheet = UIAlertController(title: "Unable to update CommentData", message: "コメント投稿の更新ができませんでした。再度やり直してください。", preferredStyle: .alert)
                        actionSheet.addAction(UIAlertAction(title: "やり直す", style: .cancel, handler: nil))
                        return
                    }
                    let documents = snapshot.documents
                    
                    //removeallしないと重複で意味のわからない挙動が起きて、新しい同じコメントIdのdocumentが生成される。
                    self.myCommentsDocuments.removeAll()
                    for document in documents {
                        //let data = document.data()
                        let documentId = document.documentID
                        self.myCommentsDocuments.append(documentId)
                    }
                    
                    //すべての投稿の自身のコメントを削除
                    for myCommentId in self.myCommentsDocuments {
                        //print("いいいいいい\(myCommentId)")
                        self.firestore.collection(POSTS_REF).document(documentId).collection(COMMENTS_REF).document(myCommentId).delete { (error) in
                            if let error = error {
                                debugPrint("DEBUG: \(error)")
                            } else {
                                self.firestore.collection(POSTS_REF).document(documentId).setData([NUM_COMMENTS : self.myCommentsDocuments.count], merge: true) { (error) in
                                    if let error = error {
                                        debugPrint("DEBUG: え\(error)")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            //likedUserの削除
            for documentId in self.allPostsDocuments {
                self.firestore.collection(POSTS_REF).document(documentId).collection(LIKED_USER).whereField(USER_ID, isEqualTo: currentUser.uid).getDocuments { (snapshot, error) in
                    
                    guard let snapshot = snapshot else {
                        let actionSheet = UIAlertController(title: "Unable to delete likedUserData", message: "アカウントの削除に一部失敗しました。もう一度やり直してください。", preferredStyle: .alert)
                        actionSheet.addAction(UIAlertAction(title: "戻る", style: .cancel, handler: nil))
                        return
                    }
                    let documents = snapshot.documents
                    
                    //removeallしないと重複で意味のわからない挙動が起きて、新しい同じコメントIdのdocumentが生成される。
                    self.likedUsersDocuments.removeAll()
                    for document in documents {
                        //let data = document.data()
                        let likedUsersDocumentId = document.documentID
                        self.likedUsersDocuments.append(likedUsersDocumentId)
                    }
                    
                    //すべての投稿の自身のコメントを削除
                    for likedUserId in self.likedUsersDocuments {
                        //print("いいいいいい\(myCommentId)")
                        Firestore.firestore().collection(POSTS_REF).document(documentId).collection(LIKED_USER).document(likedUserId).delete { (error) in
                            if let error = error {
                                debugPrint("DEBUG: \(error)")
                            } else {
                                self.firestore.collection(POSTS_REF).document(documentId).setData([NUM_LIKES : self.likedUsersDocuments.count], merge: true) { (error) in
                                    if let error = error {
                                        debugPrint("DEBUG: \(error)")
                                    }
                                }
                            }
                        }
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                ///Authから削除
                
                currentUser.delete { (error) in
                    if let error = error {
                        debugPrint("DEBUG: \(error)")
                    } else {
                        print("Auth削除完了")
                        //hud
                        DispatchQueue.main.async {
                            self.spinner.dismiss()
                        }
                        //自動遷移
                        self.handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
                            if user == nil {
                                //UIの変更はDispatch.main
                                DispatchQueue.main.async {
                                    let nav = UINavigationController(rootViewController: LoginViewController())
                                    nav.modalPresentationStyle = .fullScreen
                                    self.present(nav, animated: true, completion: nil)
                                }
                            }
                        })
                    }
                }
            }
            
        }
    }
    
    
    private func deleteProfileImage() {
        guard let currentUser = Auth.auth().currentUser else {
            print("?????")
            return
        }
        let userProfileImg = currentUser.photoURL?.absoluteString ?? ""
        var imageRef: String = ""
        if userProfileImg != "" {
            let firstChar = userProfileImg.index(userProfileImg.startIndex, offsetBy: 94)
            var lastNum = 135
            repeat {
                let lastChar = userProfileImg.index(userProfileImg.startIndex, offsetBy: lastNum)
                imageRef = String(userProfileImg[firstChar...lastChar])
                lastNum -= 1
                
            }
            while (imageRef.suffix(5) == ".jpeg")
            
            var droppedImageRef = ""
            if imageRef.suffix(1) == "?" {
                droppedImageRef = String(imageRef.dropLast())
                
            }
            
            Firebase.Storage.storage().reference().child("profile_images/\(String(droppedImageRef))").delete { (error) in
                if let error = error {
                    debugPrint("DEBUG: 元の画像がセットされていなかったようです。\(error)")
                } else {
                    print("\(droppedImageRef)FromStorage削除完了")
                }
                //??user
            }
        }
    }
    
    
    func delete(collection: CollectionReference, batchSize: Int = 100, completion: @escaping (Error?) -> ()) {
        collection.limit(to: batchSize).getDocuments { (docset, error) in
            
            guard let docset = docset else {
                completion(error)
                return
            }
            
            guard docset.count > 0 else {
                completion(nil)
                return
            }
            
            let batch = collection.firestore.batch()
            docset.documents.forEach {batch.deleteDocument($0.reference)}
            batch.commit { (batchError) in
                
                if let batchError = batchError {
                    completion(batchError)
                }
                else {
                    self.delete(collection: collection, batchSize: batchSize, completion: completion)
                }
            }
        }
    }
    
}
