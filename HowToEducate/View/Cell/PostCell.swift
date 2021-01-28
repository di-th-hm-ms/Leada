//
//  PostCell.swift
//  HowToEducate
//
//  Created by Lon on 2020/10/27.
//

import UIKit
import Firebase
import FirebaseAuth

protocol PostDelegate: class {
    func postOptionsTapped(post: Post)
    func toOtherOptionsTapped(post: Post)
    func userImageTapped(userId: String)
}

class PostCell: UITableViewCell {
    
    //MARK: - Properties
    static let identifier = "PostCell"
    let firestore = Firestore.firestore()
    var posttRef: DocumentReference?
    
    private var post: Post? //like機能に必要
    
    weak var delegate: PostDelegate?
    
    
    //多分初期化した後にconfigure呼ばれると仮定して。。。
    var goodAlreadyTapped: Bool? //いいねButton viewDidでuserDefaultsから呼び出して入れる
    
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "shinobi"
        label.textColor = .darkGray
        label.font = UIFont.boldSystemFont(ofSize: 15)
        return label
    }()
    private let timestampLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .darkGray
        return label
    }()
    private let postTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont(name: "Thonburi", size: 13)
        label.textColor = .darkGray
        return label
    }()
    private let likesNumLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.setDimensions(width: 30, height: 20)
        label.textColor = .darkGray
        return label
    }()
    private let commentsNumLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.textColor = .darkGray
        label.setDimensions(width: 30, height: 20)
        return label
    }()
    private let likesImage: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "heart"))
        imageView.tintColor = .lightGray
        imageView.clipsToBounds = true
        imageView.setDimensions(width: 22, height: 22)
        return imageView
    }()
    private let commentsImage: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "message"))
        imageView.tintColor = lightPurple
        imageView.setDimensions(width: 22, height: 22)
        return imageView
    }()
    private let optionsMenu: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "scribble.variable"))
        imageView.tintColor = .purple
        return imageView
    }()
    private let toOtherOptionsMenu: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "icloud"))
        imageView.tintColor = .purple
        return imageView
    }()
    private let userImageView: UIImageView = {
        //let imageView = UIImageView(image: UIImage(named: <#T##String#>))
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .purple
        imageView.setDimensions(width: 48, height: 48)
        imageView.layer.cornerRadius = 48 / 2
        return imageView
    }()
    
    
    //MARK: - Lifecycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .white
        
        addSubViews()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(likeTapped))
        likesImage.addGestureRecognizer(tap)
        likesImage.isUserInteractionEnabled = true
        
        commentsImage.tintColor = .lightGray
        
        
        
        
        let stack = UIStackView(arrangedSubviews: [likesImage, likesNumLabel, commentsImage, commentsNumLabel])
        stack.axis = .horizontal
        stack.distribution = .fillProportionally
        stack.spacing = 2
        addSubview(stack)
        stack.anchor(top: postTextLabel.bottomAnchor, left: userImageView.rightAnchor, bottom: contentView.bottomAnchor, paddingTop: 8, paddingLeft: 12, paddingBottom: 8)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(userImageTapped))
        userImageView.addGestureRecognizer(tap2)
        userImageView.isUserInteractionEnabled = true
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //Prepares the receiver for service after it has been loaded from an Interface Builder archive, or nib file.
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.anchor(top: contentView.topAnchor, left: contentView.leftAnchor, paddingTop: 10, paddingLeft: 8)
        
        nameLabel.anchor(top: contentView.topAnchor, left: userImageView.rightAnchor, paddingTop: 5, paddingLeft: 12)
        timestampLabel.anchor(top: contentView.topAnchor, left: nameLabel.rightAnchor, paddingTop: 5, paddingLeft: 6)
        
        postTextLabel.anchor(top: contentView.topAnchor, left: userImageView.rightAnchor, bottom: contentView.bottomAnchor, right: contentView.rightAnchor, paddingTop: 28, paddingLeft: 12, paddingBottom: 35, paddingRight: 10)
        
        optionsMenu.anchor(top: contentView.topAnchor, right: contentView.rightAnchor, paddingTop: 4, paddingRight: 4)
        toOtherOptionsMenu.anchor(top: contentView.topAnchor, right: contentView.rightAnchor, paddingTop: 4, paddingRight: 4)
    }
    
    @objc func likeTapped() {
        likesImage.gestureRecognizers?[0].isEnabled = false
        guard let post = post else {
            likesImage.gestureRecognizers?[0].isEnabled = true
            return
        }
        posttRef = firestore.collection(POSTS_REF).document(post.documentId)
        var postDocument: DocumentSnapshot?
        firestore.collection(POSTS_REF).document(post.documentId).getDocument(completion: { (snapshot, error) in
            guard let snapshot = snapshot else {
                self.likesImage.gestureRecognizers?[0].isEnabled = true
                return
            }
            postDocument = snapshot
            
            //いいねされているか判定
            if self.goodAlreadyTapped == true {
                self.likesImage.image = UIImage(systemName: "heart")
                self.likesImage.tintColor = .lightGray
                
                guard let uid = Auth.auth().currentUser?.uid else {
                    self.likesImage.gestureRecognizers?[0].isEnabled = true
                    return
                }
                
                var likedPostDocumentId = ""
                self.firestore.collection(USERS_REF).document(uid)
                    .collection(LIKED_POST).whereField(DOCUMENT_ID, isEqualTo: (post.documentId)!).getDocuments { (snapshot, error) in
                        if let error = error {
                            debugPrint("DEBUG: \(error)")
                        }
                        guard let documents = snapshot?.documents else {
                            self.likesImage.gestureRecognizers?[0].isEnabled = true
                            return
                        }
                        for document in documents {
                            likedPostDocumentId = document.documentID
                        }
                        print(likedPostDocumentId)
                        
                        var likedUserDocumentId = ""
                        
                        //データ取得の速度差が原因
                        self.firestore.collection(POSTS_REF).document((post.documentId)!)
                            .collection(LIKED_USER).whereField(USER_ID, isEqualTo: uid).getDocuments { (snapshot, error) in
                                if let error = error {
                                    debugPrint("DEBUG: \(error)")
                                }
                                guard let documents = snapshot?.documents else {
                                    self.likesImage.gestureRecognizers?[0].isEnabled = true
                                    return
                                }
                                for document in documents {
                                    let data = document.data()
                                    likedUserDocumentId = data[DOCUMENT_ID] as? String ?? ""
                                }
                                
                                self.firestore.runTransaction { (transaction, errorPointer) -> Any? in
                                    
                                    //documentはdata()メソッドで辞書型へ。それの...
                                    guard let unwrappedPostDocument = postDocument else {
                                        debugPrint("Unable to unwrap")
                                        self.likesImage.gestureRecognizers?[0].isEnabled = true
                                        return nil
                                    }
                                    guard let oldNumLikes = unwrappedPostDocument.data()?[NUM_LIKES] as? Int else {
                                        debugPrint("Fail to get oldNumLikes")
                                        self.likesImage.gestureRecognizers?[0].isEnabled = true
                                        return nil
                                    }
                                    guard let postRef = self.posttRef else {
                                        debugPrint("Fail to get postrRef")
                                        self.likesImage.gestureRecognizers?[0].isEnabled = true
                                        return nil
                                    }
                                    
                                    //transaction1
                                    transaction.updateData([NUM_LIKES : oldNumLikes - 1], forDocument: postRef)
                                    
                                    //transaction2 currentUserのDocumentだけ消す
                                    transaction.deleteDocument(self.firestore.collection(POSTS_REF).document((post.documentId)!).collection(LIKED_USER).document(likedUserDocumentId))
                                    
                                    transaction.deleteDocument(self.firestore.collection(USERS_REF).document(uid).collection(LIKED_POST).document(likedPostDocumentId))
                                    
                                    return nil
                                } completion: { (object, error) in
                                    if let error = error {
                                        debugPrint("DEBUG: Transaction error \(error)")
                                    }
                                    else {
                                        print(object)
                                    }
                                    self.likesImage.gestureRecognizers?[0].isEnabled = true
                                }
                            }
                    }
            } else {
                
                //NUM_likes 1増やして、FirestoreのUserのサブコレにlikedPosts と PostsのサブコレにlikedUserを置く
                self.firestore.runTransaction { (transaction, errorPointer) -> Any? in
                    let postDocument: DocumentSnapshot
                    do {
                        //遷移時に渡ってきたself.thoughtはold transactionで取ってきたものを代入
                        try postDocument = transaction.getDocument(self.firestore.collection(POSTS_REF).document((self.post?.documentId)!))
                    } catch {
                        //取得ミスると、ここで終わらせるためのreturn
                        debugPrint("DEBUG: \(error.localizedDescription)")
                        return nil
                    }
                    //documentはdata()メソッドで辞書型へ。それの...
                    guard let oldNumLikes = postDocument.data()?[NUM_LIKES] as? Int else {
                        self.likesImage.gestureRecognizers?[0].isEnabled = true
                        return nil
                    }
                    //transactionとは関係ない、ただの参照元を保証するだけのもの
                    guard let postRef = self.posttRef else {
                        self.likesImage.gestureRecognizers?[0].isEnabled = true
                        return nil
                    }
                    //transaction1
                    transaction.updateData([NUM_LIKES : oldNumLikes + 1], forDocument: postRef)
                    
                    //transaction2
                    //2-1
                    let likedUserDocument = self.firestore.collection(POSTS_REF).document((self.post?.documentId)!)
                        .collection(LIKED_USER).document() //try-catchで確かめてるからCrushはしない
                    transaction.setData([
                                            USERNAME : Auth.auth().currentUser?.displayName,
                                            USER_ID : Auth.auth().currentUser?.uid,
                                            DOCUMENT_ID : likedUserDocument.documentID,
                                            TIMESTAMP : FieldValue.serverTimestamp()], forDocument: likedUserDocument)
                    //2-2
                    guard let uid = Auth.auth().currentUser?.uid else { return nil }
                    let likedPostDocument = self.firestore.collection(USERS_REF).document(uid)
                        .collection(LIKED_POST).document() //try-catchで確かめてるからCrushはしない
                    transaction.setData([
                                            USERNAME : Auth.auth().currentUser?.displayName, //like舌人のuid
                                            USER_ID : Auth.auth().currentUser?.uid,  //like舌人のuid
                                            DOCUMENT_ID : self.post?.documentId,
                                            ////likedPostDocumentのdocumentIdを入れてしまうと、削除する際に行うクエリの条件がしていできなくなる。
                                            TIMESTAMP : FieldValue.serverTimestamp()], forDocument: likedPostDocument)
                    return nil
                } completion: { (object, error) in
                    if let error = error {
                        debugPrint("DEBUG: Transaction error \(error)")
                    }
                    else {
                        print(object)
                    }
                }
                
            }
            self.goodAlreadyTapped = !(self.goodAlreadyTapped!)
            self.likesImage.gestureRecognizers?[0].isEnabled = true
        })
    }
    
    @objc func userImageTapped() {
        guard let userId = post?.userId, let currentUser = Auth.auth().currentUser else {
            debugPrint("DEBUG: postが取得できなかった？")
            return
        }
        if currentUser.uid != userId {
            delegate?.userImageTapped(userId: userId)
        } else {
            return
        }
        
        
    }
    //commentは急遽追加 削除用
    func configure(post: Post, goodAlreadyTapped: Bool) {
        optionsMenu.isHidden = true
        toOtherOptionsMenu.isHidden = true
        //likeはCellの動作によって数が左右されるので、
        self.post = post
        
        self.goodAlreadyTapped = goodAlreadyTapped
        if goodAlreadyTapped == true {
            self.likesImage.tintColor = darkPurple
            self.likesImage.image = UIImage(systemName: "heart.fill")
        }
        else {
            self.likesImage.tintColor = .lightGray
            self.likesImage.image = UIImage(systemName: "heart")
        }
        
        nameLabel.text = post.fullname
        postTextLabel.text = post.postText
        likesNumLabel.text = String(post.numLikes)
        commentsNumLabel.text = String(post.numComments)
        userImageView.sd_setImage(with: URL(string: post.profileImageString), completed: nil)
        
        //時間の表示
        //Date型
        let formatter = DateFormatter()
        //formatter.dateFormat = "MMM d, hh:mm"
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        let timestamp = formatter.string(from: post.timestamp) //FieldValue.serverTimestamp()でaddDocしたやつ。
        timestampLabel.text = timestamp
        
        if post.userId == Auth.auth().currentUser?.uid {
            optionsMenu.isHidden = false
            optionsMenu.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(postOptionsTapped))
            optionsMenu.addGestureRecognizer(tap)
        } else {
            toOtherOptionsMenu.isHidden = false
            toOtherOptionsMenu.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(toOtherOptionsTapped))
            toOtherOptionsMenu.addGestureRecognizer(tap)
        }
    }
    
    @objc private func postOptionsTapped() {
        guard let post = post else {
            return
        }
        delegate?.postOptionsTapped(post: post)
    }
    
    @objc private func toOtherOptionsTapped() {
        guard let post = post else {
            return
        }
        delegate?.toOtherOptionsTapped(post: post)
    }
    
    private func addSubViews() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(timestampLabel)
        contentView.addSubview(postTextLabel)
        contentView.addSubview(likesNumLabel)
        contentView.addSubview(commentsNumLabel)
        contentView.addSubview(likesImage)
        contentView.addSubview(commentsImage)
        contentView.addSubview(optionsMenu)
        contentView.addSubview(toOtherOptionsMenu)
        contentView.addSubview(userImageView)
    }
}
