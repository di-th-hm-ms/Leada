//
//  CommentsViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/11/06.
//

import UIKit
import Firebase
import JGProgressHUD
import MessageKit
import InputBarAccessoryView
import SDWebImage

struct Sender: SenderType {
    var senderId: String
    var displayName: String
}

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

class CommentsViewController: MessagesViewController, UITextFieldDelegate, InputBarAccessoryViewDelegate, MessagesDataSource {
    
    //MARK: - Properties
    private var currentUser = Sender(senderId: "", displayName: "")
    
    //otherUserを配列にすればいけるかな
    //let otherUser = Sender(senderId: "the other", displayName: "noa")
    
    var messages = [MessageType]()
    
    private let spinner = JGProgressHUD(style: .light)
    
    
    
    
    //MARK: - Variables
    var post: Post!
    var comments = [Comment]()
    var posttRef: DocumentReference!
    let firestore = Firestore.firestore()
    var fullname: String!
    var commentsListener: ListenerRegistration!
    var userListener: ListenerRegistration!
    //var commentUserId: String?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.isHidden = true
        navigationController?.navigationBar.barTintColor = lightPurple
        navigationItem.leftBarButtonItem?.tintColor = darkPurple
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        
        messageInputBar.delegate = self
        //tableView.estimatedRowHeight = 66
        posttRef = firestore.collection(POSTS_REF).document(post.documentId)
        //        addSubViews()
        //Authのuser?.user == currentUser のデータ
        if let name = Auth.auth().currentUser?.displayName {
            fullname = name  //
        }
        
    }
    
    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        commentsListener = firestore.collection(POSTS_REF).document(self.post.documentId)
            .collection(COMMENTS_REF)
            .order(by: TIMESTAMP, descending: false)
            .addSnapshotListener({ (snapshot, error) in
                if let error = error {
                    debugPrint("DEBUG: Error fetching comments \(error)")
                    return
                }
                
                self.comments.removeAll()
                //class method インスタンス化せずに使用
                //11/9 Comment x Message
                self.comments = Comment.parseCommentData(snapshot: snapshot)
                self.messages.removeAll()
                for comment in self.comments {
                    
                    let sender = Sender(senderId: comment.userId, displayName: comment.fullname)
                    //self.commentUserId = comment.userId //11/11 cell.Avatar->ProfileVC(userId)
                    let message = Message(sender: sender, messageId: comment.documentId, sentDate: comment.timestamp, kind: .text(comment.commentText))
                    self.messages.append(message)
                    self.comments.append(comment)
                }
                
                //setUserListener()
                
                //MessageKitをリロード？いやいらないかも
                self.messagesCollectionView.reloadData()
                
            })
        guard let authenticatedUser = Auth.auth().currentUser else {
            return
        }
        currentUser = Sender(senderId: authenticatedUser.uid, displayName: authenticatedUser.displayName ?? "")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        commentsListener.remove()
        if userListener != nil {
            userListener.remove()
        } else {
            print("userListenerはnilです。")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touched")
        if (self.messageInputBar.inputTextView.isFirstResponder) {
            self.messageInputBar.inputTextView.resignFirstResponder()
            messagesCollectionView.endEditing(true)
        }
    }
    
    //MARK: - DelegateではないただのCommentMethod
    func commentOptionTapped(comment: Comment, message: Message) {
        let alert = UIAlertController(title: "Edit Comment", message: "You can delete or edit", preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete Comment", style: .destructive) { (action) in
            let confirmDeleteAlert = UIAlertController(title: "本当に削除しますか？", message: "一度削除したコメントは復元することができません。", preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: "削除", style: .destructive) { (action2) in
                
                self.firestore.runTransaction { (transaction, errorPointer) -> Any? in
                    let postDocument: DocumentSnapshot
                    do {
                        //遷移時の値をold
                        try postDocument = transaction.getDocument(self.firestore.collection(POSTS_REF).document(self.post.documentId))
                    } catch {
                        //取得ミスると、ここで終わらせるためのreturn
                        debugPrint("DEBUG: \(error.localizedDescription)")
                        return nil
                    }
                    //documentはdata()メソッドで辞書型へ。それの...
                    guard let oldNumComments = postDocument.data()?[NUM_COMMENTS] as? Int else { return nil }
                    
                    //transaction1
                    transaction.updateData([NUM_COMMENTS : oldNumComments - 1], forDocument: self.posttRef)
                    
                    //transaction2
                    let commentRef = self.firestore.collection(POSTS_REF).document(self.post.documentId)
                        .collection(COMMENTS_REF).document(comment.documentId)
                    
                    transaction.deleteDocument(commentRef)
                    
                    return nil
                } completion: { (object, error) in
                    if let error = error {
                        debugPrint("DEBUG: Transaction error \(error)")
                    }
                    else {
                        //Delegate使わずに、Cellに渡っているModelingされた値を用いて編集もできるが、
                        alert.dismiss(animated: true, completion: nil)
                    }
                }
            }
            let confirmCancel = UIAlertAction(title: "戻る", style: .cancel, handler: nil)
            confirmDeleteAlert.addAction(confirmAction)
            confirmDeleteAlert.addAction(confirmCancel)
            self.present(confirmDeleteAlert, animated: true, completion: nil)
        }
        let editAction = UIAlertAction(title: "Edit Comment", style: .default) { (action) in
            //self.performSegue(withIdentifier: "toEditComment", sender: (comment, self.post))
            let commentData: (comment: Comment, post: Post, message: Message) = (comment: comment, post: self.post, message: message)
            let vc = UpdateCommentViewController(commentData: commentData)
            self.navigationController?.pushViewController(vc, animated: false)
            alert.dismiss(animated: true, completion: nil)
        }
        let cancel = UIAlertAction(title: "戻る", style: .cancel, handler: nil)
        alert.addAction(deleteAction)
        alert.addAction(editAction)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
        
    }
//    private func othersCommentOptionTapped() {
//        let alert = UIAlertController(title: "このコメントについて",
//                                      message: "このコメントを通報しますか?",
//                                      preferredStyle: .actionSheet)
//        let reportAction = UIAlertAction(title: "通報",
//                                         style: .destructive) { (_) in
//
//            let vc = UINavigationController(rootViewController: ReportViewController(post: self., user: nil))
//            vc.modalPresentationStyle = .fullScreen
//            self.present(vc, animated: true, completion: nil)
//        }
//
//        let cancelAction = UIAlertAction(title: "Cancel",
//                                         style: .cancel,
//                                         handler: nil)
//        alert.addAction(reportAction)
//        //alert.addAction(shareAction)
//        alert.addAction(cancelAction)
//        present(alert, animated: true, completion: nil)
//    }
    
    //MARK: - Selectors
    @objc private func didTapButton() {
        navigationController?.popViewController(animated: true)
    }
    func didTapMessage(in cell: MessageCollectionViewCell) {
        //Call Method to Show Action Picker
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        
        //条件分岐をどこかしらでしたい。comment.userId != currentId → 発動しない的な
        if comments[indexPath.section].userId == Auth.auth().currentUser?.uid {
            commentOptionTapped(comment: comments[indexPath.section], message: messages[indexPath.section] as! Message)
        }
//            othersCommentOptionTapped()
        
    }
    //MARK: - MessageKit
    func currentSender() -> SenderType {
        return currentUser
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        //多分送信Button→表示はDefault
        //UITextView.text must be used from main thread only → メインスレッドオンリー
        let inputText = self.messageInputBar.inputTextView.text
        //UI
        
        //Firestore
        firestore.runTransaction { (transaction, errorPointer) -> Any? in
            let postDocument: DocumentSnapshot
            do {
                //遷移時に渡ってきたself.postはold
                try postDocument = transaction.getDocument(self.firestore.collection(POSTS_REF).document(self.post.documentId))
            } catch {
                //取得ミスると、ここで終わらせるためのreturn
                debugPrint("DEBUG: \(error.localizedDescription)")
                return nil
            }
            //documentはdata()メソッドで辞書型へ。それの...
            guard let oldNumComments = postDocument.data()?[NUM_COMMENTS] as? Int else { return nil }
            
            //transaction1
            transaction.updateData([NUM_COMMENTS : oldNumComments + 1], forDocument: self.posttRef)
            
            let newCommentRef = self.firestore.collection(POSTS_REF).document(self.post.documentId).collection(COMMENTS_REF).document()
            
            
            //transaction2
            transaction.setData([
                COMMENT_TEXT : inputText,
                TIMESTAMP : FieldValue.serverTimestamp(),
                FULLNAME : self.fullname,//viewDidLoadにてAuthでーたから読み込む
                PROFILE_IMAGE_URL_STR : Auth.auth().currentUser?.photoURL?.absoluteString,
                USER_ID : Auth.auth().currentUser?.uid
            ], forDocument: newCommentRef)
            
            //commentsを設計して反映させる。
            
            
            return nil
        } completion: { (object, error) in
            if let error = error {
                debugPrint("DEBUG: Transaction error \(error)")
            }
        }
        messageInputBar.inputTextView.resignFirstResponder()
        messageInputBar.inputTextView.text = ""
        messagesCollectionView.scrollToBottom()
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            return NSAttributedString(
                string: MessageKitDateFormatter.shared.string(from: message.sentDate),
                attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                             NSAttributedString.Key.foregroundColor: UIColor.darkGray]
            )
        }
        return nil
    }
    // メッセージの上に文字を表示（名前）
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    // メッセージの下に文字を表示（日付）
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
    
    
}
extension CommentsViewController: MessagesLayoutDelegate {
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
}

//MARK: - ここから難題
extension CommentsViewController: MessageCellDelegate {
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
        //予め別でProfileImageはセットしておいて、
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        //guard let messagesDataSource = messagesCollectionView.dataSource else { return }
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        let senderId = messages[indexPath.section].sender.senderId
        if senderId == currentUser.uid {
            let vc = ProfileViewController()
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let vc = OtherUserProfileViewController.init(otherUserId: senderId)
            navigationController?.pushViewController(vc, animated: true)
        }
        
    }

}

extension CommentsViewController: MessagesDisplayDelegate {

    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : purple
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? darkPurple : UIColor.rgb(red: 243, green: 243, blue: 243)
    }
    
    // put a tail onto a message
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    // setIcon
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        var avatar: Avatar?
        let senderId = message.sender.senderId
        //addsna
        userListener = firestore.collection(USERS_REF).document(senderId).addSnapshotListener({ (snapshot, error) in
            if let error = error {
                debugPrint("DEBUG: Unable to getUserData \(error.localizedDescription)")
                avatar = Avatar(image: UIImage(), initials: "None")
            }
            else {
                avatar = Avatar(image: self.getImageByUrl(url: self.comments[indexPath.section].profileImageString), initials: "人")
            }
            //let avater2 = Avatar(image: <#T##UIImage?#>, initials: <#T##String#>)
            avatarView.set(avatar: avatar!)
        })
    }
    
    private func getImageByUrl(url: String) -> UIImage{
        guard let url = URL(string: url) else {
            return UIImage()
        }
        do {
            let data = try Data(contentsOf: url)
            return UIImage(data: data) ?? UIImage()
        } catch let err {
            print("Error : \(err.localizedDescription)")
        }
        return UIImage()
    }
}
