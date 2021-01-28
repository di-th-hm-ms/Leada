//
//  ProfileViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/10/27.
//

import UIKit
import Firebase
import SDWebImage
import GoogleSignIn
import JGProgressHUD

class ProfileViewController: UIViewController {
    
    //MARK: - Properties
    private var myDataRef: DocumentReference?
    private var mypostsRef: CollectionReference?
    private var myDataListner: ListenerRegistration? //addSnapshotListener格納用
    private var myPostsListner: ListenerRegistration? //addSnapshotListener格納用
    
    private var posts = [Post]()
    private var user: User?
    
    private let firestore = Firestore.firestore()
    private var likedPostsListener: ListenerRegistration?
    private var likedPostsDocumentIds = [String]()
    
    var likedDocumentIds = [String]()
    private let spinner = JGProgressHUD(style: .light)
    
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
        label.textColor = .darkGray
        return label
    }()
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "name"
        label.textColor = .darkGray
        return label
    }()
    
    private let bioLabel: UILabel = {
        let label = UILabel()
        label.text = "your profile"
        label.font = UIFont.systemFont(ofSize: 12)
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        label.textColor = .darkGray
        return label
    }()
    
    private var stack = UIStackView()
    let postLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = "投稿数"
        label.textColor = .darkGray
        return label
    }()
    let likesLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.text = "いいね数"
        label.textColor = .darkGray
        return label
    }()
    private let postCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = darkPurple
        label.text = "0"
        return label
    }()
    
    private let likesCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = darkPurple
        label.text = "0"
        return label
    }()
    
    private let noPostsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = purple
        label.isHidden = true
        label.text = "まだ投稿がありません。"
        return label
    }()
    
    private let updateProfileButton: UIButton = {
        let button = UIButton()
        button.setTitle("プロファイルを編集する", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        button.setDimensions(width: 200, height: 30)
        button.setTitleColor(darkPurple, for: .normal)
        button.backgroundColor = .white
        button.layer.borderWidth = 2
        button.layer.borderColor = darkPurple.cgColor
        button.layer.cornerRadius = 30/2
        return button
    }()
    
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        tableView.tableHeaderView = createTableHeaderView()
        tableView.backgroundColor = .white
        addSubViews()
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.triangle.2.circlepath"),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(didTapReloadButton))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "gear"),
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(didTapSettingButtton))
        navigationController?.navigationBar.barTintColor = lightPurple
        navigationController?.navigationBar.tintColor = darkPurple
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: darkPurple]
        updateProfileButton.addTarget(self, action: #selector(didTapUpdateProfileButton), for: .touchUpInside)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 66
        
        
        if GIDSignIn.sharedInstance()?.hasPreviousSignIn() == true {
            GIDSignIn.sharedInstance()?.restorePreviousSignIn()
        }
        
    }
    @objc private func didTapReloadButton() {
        loadView()
        viewDidLoad()
        viewWillAppear(true)
        viewWillLayoutSubviews()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let header = tableView.tableHeaderView {
            updateProfileButton.anchor(top: header.topAnchor, right: header.rightAnchor, paddingTop: 20, paddingRight: 12)
            nameLabel.anchor(top: profileImageView.bottomAnchor, left: header.leftAnchor, paddingTop: 20, paddingLeft: 12)
            stack.anchor(top: nameLabel.bottomAnchor, left: header.leftAnchor, paddingTop: 6, paddingLeft: 12)
            bioLabel.anchor(top: stack.bottomAnchor, left: header.leftAnchor, right: header.rightAnchor,paddingTop: 14, paddingLeft: 12, paddingRight: 12)
            tableView.anchor(top: header.bottomAnchor, width: view.width, height: view.height)
            noPostsLabel.anchor(top: header.bottomAnchor, paddingTop: 20)
            noPostsLabel.centerX(inView: tableView)
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //super.viewWillAppear(<#T##animated: Bool##Bool#>)
        //firestore 当初はviewDidLoadで呼び出してたけど、アプリ落とさずにいるとviewWillAppearしか発動しなくなる→uid放置になっちゃう
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        myDataRef = Firestore.firestore().collection(USERS_REF).document(currentUser.uid)
        mypostsRef = Firestore.firestore().collection(POSTS_REF)
        tabBarController?.tabBar.isHidden = false
        setMyDataListener() {
            DispatchQueue.main.async {
                self.usernameLabel.text = self.user?.username
                self.nameLabel.text = self.user?.fullname
                self.navigationItem.title = self.user?.username
                self.bioLabel.text = self.user?.bio
                let imageString: String = self.user?.profileImageString ?? ""
                if imageString != "" {
                    self.profileImageView.sd_setImage(with: URL(string: imageString), completed: nil)
                }
                else {
                    self.profileImageView.sd_setImage(with: currentUser.photoURL, completed: nil)
                }
            }
        }
        
        setMyPostsListener() {
            self.postCountLabel.text = "\(self.posts.count)"
            self.likesCountLabel.text = "\(self.likesCount)"
            self.spinner.dismiss()
            if self.posts.count == 0 {
                self.noPostsLabel.isHidden = false
            } else {
                self.noPostsLabel.isHidden = true
            }
        }
        setLikedPostsListener()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.validateUsername(username: self.user?.username ?? "")
        }
        
        
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        if myDataListner != nil || myPostsListner != nil {
            myDataListner?.remove()  //画面離れてもlistenerしてtara無駄。金だけかかる
            myPostsListner?.remove()
        }
        if likedPostsListener != nil {
            likedPostsListener?.remove()
        }
    }
    
    private func createTableHeaderView() -> UIView {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: view.height/2.8).integral)
        header.attachBorder(width: view.width, color: lightPurple, position: .bottom)
        header.backgroundColor = .white
        let size = header.height / 5 * 2
        profileImageView.frame = CGRect(x: 12, y: 20, width: size, height: size)
        profileImageView.layer.cornerRadius = size / 2.0
        header.addSubview(profileImageView)
        
        //updateProfileButton.frame =
        
        header.addSubview(usernameLabel)
        header.addSubview(nameLabel)
        header.addSubview(postCountLabel)
        header.addSubview(postLabel)
        header.addSubview(bioLabel)
        header.addSubview(updateProfileButton)
        
        
        
        stack = UIStackView(arrangedSubviews: [postLabel, postCountLabel, likesLabel, likesCountLabel])
        stack.axis = .horizontal
        stack.distribution = .fillProportionally
        stack.spacing = 2
        header.addSubview(stack)
        
        
        return header
    }
    
    private func setMyDataListener(completion: @escaping () -> Void) {
        myDataListner = myDataRef?.addSnapshotListener({ (snapshot, error) in
            if let error = error {
                debugPrint("DEBUG: \(error)")
            }
            else {
                self.user = nil
                self.user = User.parseMyData(snapshot: snapshot)
                completion()
            }
        })
    }
    
    private func setMyPostsListener(completion: @escaping () -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        spinner.show(in: tableView)
        myPostsListner = mypostsRef?.whereField(USER_ID, isEqualTo: uid).order(by: TIMESTAMP, descending: true).addSnapshotListener({ (snapshot, error) in
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
                DispatchQueue.main.asyncAfter(deadline: .now()+0.3) {
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
    
    private func validateUsername(username: String) {
        if username == "" {
            let vc = UINavigationController(rootViewController: UsernameViewController())
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: false, completion: nil)
        }
    }
    
    private func addSubViews() {
        view.addSubview(tableView)
        tableView.addSubview(noPostsLabel)
        postCountLabel.text = "\(posts.count)"
    }
    
    //MARK: - Selectors
    @objc private func didTapSettingButtton() {
        let vc = SettingViewController()
        vc.title = "設定"
        
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func didTapUpdateProfileButton() {
        guard let user = user else {
            return
        }
        let vc = UpdateProfileViewController(user: user, posts: posts)
        vc.title = "プロファイルを編集"
        navigationController?.pushViewController(vc, animated: false)
    }
    
}
extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
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
extension ProfileViewController: PostDelegate {
    func userImageTapped(userId: String) {
        return
    }
    
    func toOtherOptionsTapped(post: Post) {
        return
    }
    
    func postOptionsTapped(post: Post) {
        print("postOptionTapped")
        
        //actionSheet
        let alert = UIAlertController(title: "Delete",
                                      message: "Do you wanna delete this thought?",
                                      preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Delete Thought",
                                         style: .destructive) { (_) in
            
            self.delete(collection: self.firestore.collection(POSTS_REF).document(post.documentId).collection(COMMENTS_REF)) { (error) in
                if let error = error {
                    debugPrint("DEBUG: Unable to delete this thought:\(error.localizedDescription)")
                }
                else {
                    self.delete(collection: self.firestore.collection(POSTS_REF).document(post.documentId).collection(LIKED_USER)) { (error) in
                        if let error = error {
                            debugPrint("DEBUG: \(error)")
                        } else {
                            //super thoughtsDocument削除
                            self.firestore.collection(POSTS_REF).document(post.documentId)
                                .delete { (error) in
                                    if let error = error {
                                        debugPrint("DEBUG: Unable to delete this thought:\(error.localizedDescription)")
                                    }
                                    else {
                                        //サブこれまで消したいが。。。 NodeとかのCloudFuctions泣きがする
                                        alert.dismiss(animated: true, completion: nil)
                                    }
                                }
                        }
                    }
                    
                }
            }
        }
        let editAction = UIAlertAction(title: "Edit Thought",
                                       style: .default) { (_) in
            let vc = UpdatePostViewController(post: post)
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: false, completion: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel,
                                         handler: nil)
        alert.addAction(deleteAction)
        alert.addAction(editAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
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
