//
//  OtherUserProfileViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/11/11.
//

import UIKit
import Firebase
import JGProgressHUD

//currentUser.uid == post.userId or comment.userId ー＞ ProfileVC
class OtherUserProfileViewController: UIViewController {
    
    //MARK: - Property
    
    private var otherUserId: String?
    
    private var otherUserDataRef: DocumentReference?
    private var postsRef: CollectionReference?
    private var otherUserDataListner: ListenerRegistration? //addSnapshotListener格納用
    private var otherUserPostsListner: ListenerRegistration? //addSnapshotListener格納用
    
    private var posts = [Post]()
    private var otherUser: User?
    
    private var likedPostsListener: ListenerRegistration?
    private var likedPostsDocumentIds = [String]()
    
    var likedDocumentIds = [String]()
    
    let spinner = JGProgressHUD(style: .light)
    
    var likesCount = 0
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(PostCell.self, forCellReuseIdentifier: PostCell.identifier)
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = darkPurple
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = purple.cgColor
        return imageView
    }()
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "user@name"
        return label
    }()
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "name"
        return label
    }()
    
    private let bioLabel: UILabel = {
        let label = UILabel()
        label.text = "your profile"
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        return label
    }()
    
    private var stack = UIStackView()
    let postLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = "投稿数"
        return label
    }()
    private let postCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = darkPurple
        label.text = "0"
        return label
    }()
    
    let likesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = "いいね数"
        label.textColor = .darkGray
        return label
    }()
    
    private let likesCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = darkPurple
        label.text = "0"
        return label
    }()
    
    let userOptionButton: UIButton = {
        let button = UIButton()
        let image = UIImage(systemName: "gearshape.fill")
        button.tintColor = darkPurple
        button.setImage(image, for: .normal)
        return button
    }()
    
    
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        tableView.tableHeaderView = createTableHeaderView()
        addSubViews()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.triangle.2.circlepath"),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(didTapReloadButton))
        navigationController?.navigationBar.barTintColor = lightPurple
        navigationController?.navigationBar.tintColor = darkPurple
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: darkPurple]
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 66
        
        //元々
        //otherUserIdがなかったらここで止まる
        guard let otherUserId = otherUserId else {
            return
        }
        otherUserDataRef = Firestore.firestore().collection(USERS_REF).document(otherUserId)
    }
    @objc private func didTapReloadButton() {
        loadView()
        viewDidLoad()
        viewWillAppear(true)
        viewWillLayoutSubviews()
    }
    
    private func createTableHeaderView() -> UIView {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: view.height/3).integral)
        header.attachBorder(width: view.width, color: lightPurple, position: .bottom)
        header.backgroundColor = .white
        let size = header.height / 10 * 3
        profileImageView.frame = CGRect(x: 12, y: 20, width: size, height: size)
        profileImageView.layer.cornerRadius = size / 2.0
        header.addSubview(profileImageView)
        
        //updateProfileButton.frame =
        
        header.addSubview(usernameLabel)
        header.addSubview(userOptionButton)
        header.addSubview(nameLabel)
        header.addSubview(postCountLabel)
        header.addSubview(postLabel)
        header.addSubview(bioLabel)
        
        userOptionButton.addTarget(self, action: #selector(userOptionTapped), for: .touchUpInside)
        
        stack = UIStackView(arrangedSubviews: [postLabel, postCountLabel, likesLabel, likesCountLabel])
        stack.axis = .horizontal
        stack.distribution = .fillProportionally
        stack.spacing = 2
        header.addSubview(stack)
        
        
        return header
    }
    
    //otherUserId経由でなければ必要ない。
    init(otherUserId: String?) {
        //主に他のUser用のId→これをもとにUserを取得
        self.otherUserId = otherUserId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let header = tableView.tableHeaderView {
            nameLabel.anchor(top: profileImageView.bottomAnchor, left: header.leftAnchor, paddingTop: 20, paddingLeft: 12)
            userOptionButton.anchor(top: profileImageView.topAnchor, right: header.rightAnchor, paddingRight: 12, width: view.width/6, height: view.width/6)
            stack.anchor(top: nameLabel.bottomAnchor, left: header.leftAnchor, paddingTop: 6, paddingLeft: 12)
            bioLabel.anchor(top: stack.bottomAnchor, left: header.leftAnchor, right: header.rightAnchor,paddingTop: 14, paddingLeft: 12, paddingRight: 12)
            tableView.anchor(top: header.bottomAnchor, width: view.width, height: view.height)
        }
        
    }
    
    var blockedUser = [String]()
    override func viewWillAppear(_ animated: Bool) {
        //super.viewWillAppear(<#T##animated: Bool##Bool#>)
        guard let otherUserId = otherUserId else {
            //userが存在しませんorloadingError表示
            return
        }
        
        otherUserDataRef = Firestore.firestore().collection(USERS_REF).document(otherUserId)
        ///if blockedUser.userId == otherUserId    blockedUserId -> currentUser.uid .collection
        postsRef = Firestore.firestore().collection(POSTS_REF)
        tabBarController?.tabBar.isHidden = false
        self.setOtherUserPostsListener(otherUserId) {
            //not effected
            self.postCountLabel.text = "\(self.posts.count)"
            self.likesCountLabel.text = "\(self.likesCount)"
            self.spinner.dismiss()
        }
        setOtherUserDataListener(otherUserDataRef!) {
            self.usernameLabel.text = self.otherUser?.username
            self.nameLabel.text = self.otherUser?.fullname
            self.navigationItem.title = self.otherUser?.username
            self.bioLabel.text = self.otherUser?.bio
            //            let profileImageUrl = URL(string: self.user?.profileImageString ?? noImageUrl)
            //            self.profileImageView.sd_setImage(with: profileImageUrl, completed: nil)
            
            //GoogleUserは最初StorageとFirestoreのprofileImageUrlが入っていない。
            let imageString: String = self.otherUser?.profileImageString ?? ""
            self.profileImageView.sd_setImage(with: URL(string: imageString), completed: nil)
        }
        setLikedPostsListener()
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        if otherUserDataListner != nil || otherUserPostsListner != nil {
            otherUserDataListner?.remove()  //画面離れてもlistenerしてtara無駄。金だけかかる
            otherUserPostsListner?.remove()
        }
        if likedPostsListener != nil {
            likedPostsListener?.remove()
        }
    }
    
    private func setOtherUserDataListener(_ ref: DocumentReference, completion: @escaping () -> Void) {
        otherUserDataListner = otherUserDataRef?.addSnapshotListener({ (snapshot, error) in
            if let error = error {
                debugPrint("DEBUG: \(error)")
            }
            else {
                //Excellent 空にして別のUser用に
                self.otherUser = nil
                self.otherUser = User.parseMyData(snapshot: snapshot)
                completion()
            }
        })
    }
    
    private func setOtherUserPostsListener(_ id: String, completion: @escaping () -> Void) {
        spinner.show(in: tableView)
        otherUserPostsListner = postsRef?.whereField(USER_ID, isEqualTo: id).addSnapshotListener({ (snapshot, error) in
            if let error = error {
                debugPrint("DEBUG: \(error)")
            }
            else {
                self.posts.removeAll()
                self.posts = Post.parseData(snapshot: snapshot) //postCellはhomeと同じものを使うのでコレ以外余計なものは必要ない。
                self.likesCount = 0
                for post in self.posts {
                    self.likesCount += Int(post.numLikes)
                }
                DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                    self.tableView.reloadData()
                    completion()
                }
            }
        })
        
    }
    private func setLikedPostsListener() {
        //一旦Listenerでなくてもいけそうなので
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        likedPostsListener = Firestore.firestore().collection(USERS_REF).document(uid).collection(LIKED_POST).addSnapshotListener({ (snapshot, error) in
            if let error = error {
                debugPrint("DEBUG: \(error)")
            }
            self.likedPostsDocumentIds.removeAll()
            guard let documents = snapshot?.documents else { return }
            for document in documents {
                let data = document.data()
                let likedPostsDocumentId = data[DOCUMENT_ID] as? String ?? ""
                self.likedPostsDocumentIds.append(likedPostsDocumentId)
            }
            self.tableView.reloadData()
        })
        
    }
    
    ///blockingUser
    var  blockingUsers = [String]()
    @objc func userOptionTapped() {
        guard let currentUser = Auth.auth().currentUser else {
            print("loginされていません。")
            return
        }
        let blockingUsersRef = Firestore.firestore().collection(USERS_REF).document(currentUser.uid).collection(BLOCKING_USERS_REF)
        blockingUsersRef.getDocuments { (snapshot, error) in
            if let error = error {
                debugPrint("DEBUG: \(error)")
            } else {
                guard let snap = snapshot else {
                    print("snapshot error")
                    return
                }
                let documents = snap.documents
                self.blockingUsers.removeAll()
                for document in documents {
                    let data = document.data()
                    self.blockingUsers.append(data[USER_ID] as? String ?? "")
                    print(self.blockingUsers)
                }
            }
            
            let actionSheet = UIAlertController(title: "オプション", message: "このユーザーに対するオプション", preferredStyle: .actionSheet)
            let block = UIAlertAction(title: "このユーザーをブロックする。", style: .destructive) { (_) in
                blockingUsersRef.addDocument(data: [USER_ID : self.otherUserId])
            }
            
            
            ///////////
            let unblock = UIAlertAction(title: "ブロックを解除する", style: .destructive) { (_) in
                guard let otherUserId = self.otherUserId else {
                    debugPrint("DEBUG: otherUserIdがありません。")
                    return
                }
                self.spinner.show(in: self.view)
                
                blockingUsersRef.whereField(USER_ID, isEqualTo: otherUserId).getDocuments { (snapshot, error) in
                    if let error = error {
                        debugPrint("DEBUG: otherStrictUserId取得→\(error)")
                    } else {
                        guard let snap = snapshot else {
                            debugPrint("DEBUG: snapはありません。")
                            return
                        }
                        let documents = snap.documents
                        documents[0].reference.delete { (error) in
                            if let error = error {
                                debugPrint("DEBUG: deleteBlockingUserDoc→\(error)")
                            } else {
                                print("削除成功。。")
                                self.spinner.dismiss()
                            }
                        }
                    }
                }
                
                
            }
            //blockしていた場合には、解除するメソッド
            
            if self.blockingUsers.count > 0 {
                var isInclueded = false
                for blockingUser in self.blockingUsers {
                    if blockingUser == self.otherUserId {
                        actionSheet.addAction(unblock)
                        isInclueded = true
                        break
                    }
                }
                if isInclueded == false {
                    actionSheet.addAction(block)
                }
            } else {
                actionSheet.addAction(block)
            }
            
            let report = UIAlertAction(title: "報告する", style: .destructive) { (_) in
                let vc = UINavigationController(rootViewController: ReportViewController(post: nil, user: self.otherUser))
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true, completion: nil)
            }
            actionSheet.addAction(report)
            actionSheet.addAction(UIAlertAction(title: "戻る", style: .cancel, handler: nil))
            self.present(actionSheet, animated: true, completion: nil)
            
        }
    }
    
    private func addSubViews() {
        view.addSubview(tableView)
        postCountLabel.text = "\(posts.count)"
    }
    
}
extension OtherUserProfileViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.identifier,
                                                 for: indexPath) as! PostCell
        if likedPostsDocumentIds.contains(posts[indexPath.row].documentId) {
            cell.configure(post: posts[indexPath.row], goodAlreadyTapped: true) //引数にselfいれて参照元のCellで委任はなし。
        }
        else {
            cell.configure(post: posts[indexPath.row], goodAlreadyTapped: false) //引数にselfいれて参照元のCellで委任はなし。
            
        }
        //tableView.reloadData()
        cell.delegate = self
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = CommentsViewController(post: posts[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
}
extension OtherUserProfileViewController: PostDelegate {
    func userImageTapped(userId: String) {
        
        //        let vc = PostCommentUserViewController()
        //        navigationController?.pushViewController(vc, animated: true)
        return
    }
    
    func postOptionsTapped(post: Post) {
        return
    }
    
    //Delegateメソッド神
    func toOtherOptionsTapped(post: Post) {
        
        //actionSheet
        let alert = UIAlertController(title: "この投稿について",
                                      message: "Do you wanna delete this thought?",
                                      preferredStyle: .actionSheet)
        let reportAction = UIAlertAction(title: "通報",
                                         style: .destructive) { (_) in
            let vc = UINavigationController(rootViewController: ReportViewController(post: post, user: nil))
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel,
                                         handler: nil)
        alert.addAction(reportAction)
        //alert.addAction(shareAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
}
