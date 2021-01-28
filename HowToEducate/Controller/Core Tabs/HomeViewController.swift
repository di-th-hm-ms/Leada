//
//  HomeViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/10/27.
//

import UIKit
import Firebase
import FirebaseAuth
import JGProgressHUD

enum PostAgeCategory : String {
    case toddler = "toddler"
    case elementary = "elmentary"
    case highschool = "highschool"
    //case popular = "popular"
}

enum PostRankCategory : String {
    case new = "new"
    case popular = "popular"
}

protocol ScrollableProtocol {
    func scrollTop()
}

class HomeViewController: UIViewController, ScrollableProtocol {
    
    //MARK: - Properties
    private var posts = [Post]()
    private var postsCollectionRef: CollectionReference? //collection(THOUGHTS_REF)格納用
    private var postsListner: ListenerRegistration? //addSnapshotListener格納用
    private var selectedAgeCategory = PostAgeCategory.toddler.rawValue
    private var selectedRankCategory = PostRankCategory.new.rawValue
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    private var likedPostsListener: ListenerRegistration?
    private var likedPostsDocumentIds = [String]()
    
    private let firestore = Firestore.firestore()
    
    private let spinner = JGProgressHUD(style: .light)
    
    private(set) var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(PostCell.self, forCellReuseIdentifier: PostCell.identifier)
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private let invisibleView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.85)
        view.isHidden = true
        return view
    }()
    
    //segment スクロールしたら隠れる機能
    let ageSegement: UISegmentedControl = {
        let items = ["幼児", "小学生", "中高生"]
        let segment = Utilities().segmentColor(items: items)
        segment.addTarget(self, action: #selector(ageSegmentTapped), for: UIControl.Event.valueChanged)
        segment.backgroundColor = .white
        segment.isHidden = true
        return segment
    }()
    
    let rankSegement: UISegmentedControl = {
        let items = ["新着順", "人気順"]
        let segment = Utilities().segmentColor(items: items)
        segment.addTarget(self, action: #selector(rankSegmentTapped), for: UIControl.Event.valueChanged)
        segment.backgroundColor = .white
        segment.isHidden = true
        return segment
    }()
    
    private let addPostButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = lightPurple
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .light, scale: .small)
        //let largeConfing2 = UIImage.SymbolConfiguration(font: <#T##UIFont#>, scale: <#T##UIImage.SymbolScale#>)
        let largeBoldDoc = UIImage(systemName: "paperplane", withConfiguration: largeConfig)
        button.setImage(largeBoldDoc, for: .normal)
        button.tintColor = purple
        button.layer.borderWidth = 1
        button.layer.borderColor = purple.cgColor
        return button
    }()
    
    
    var blockingUsers = [String]()
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.backgroundColor = lightPurple
        tableView.backgroundColor = .white
        let imageView = UIImageView(image: UIImage(systemName: "books.vertical.fill"))
        imageView.setDimensions(width: 30, height: 30)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = darkPurple
        navigationItem.titleView = imageView
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "arrow.triangle.2.circlepath"),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(didTapReloadButton))
        //navi
        navigationController?.navigationBar.barTintColor = lightPurple
        navigationController?.navigationBar.tintColor = darkPurple
        let image = UIImage(systemName: "slider.horizontal.3")
        image?.withTintColor(darkPurple)
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(didTapSegmentAppeard))
        
        //navigationController?.navigationBar.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 66
        
        addSubViews()
        
        //tableView.rowHeight = 66
        
        addPostButton.addTarget(self, action: #selector(addPostTapped), for: .touchUpInside)
        
        postsCollectionRef = Firestore.firestore().collection(POSTS_REF)
        
        
        ///blockingUserIdを取得 uid  + getDocumet
        getBlockingUsers()
        
    }
    
    @objc private func didTapReloadButton() {
        loadView()
        viewDidLoad()
        viewWillAppear(true)
        viewWillLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = false
        handle = Auth.auth().addStateDidChangeListener({ (auth, user) in
            if user == nil {
                //UIの変更はDispatch.main
                DispatchQueue.main.async {
                    let nav = UINavigationController(rootViewController: LoginViewController())
                    nav.modalPresentationStyle = .fullScreen
                    self.present(nav, animated: true, completion: nil)
                }
            }
            else {
                self.setListener() {
                    self.tableView.reloadData()
                    self.spinner.dismiss()
                }
                self.setLikedPostsListener()
            }
        })
        
        
    }
    
    
    
    override func viewDidDisappear(_ animated: Bool) {
        //addStateDidChangeListenerが実行されてuser == nilだと、setListener()のthoughtListnerが実行されない
        if postsListner != nil {
            postsListner!.remove()  //画面離れてもlistenerしてtara無駄。金だけかかる
        }
        if likedPostsListener != nil {
            likedPostsListener?.remove()
        }
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //tableView.frame = view.bounds
        invisibleView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, height: view.height)
        ageSegement.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 8, paddingLeft: 20, paddingRight: 20)
        rankSegement.anchor(top: ageSegement.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor,paddingTop: 14, paddingLeft: 20, paddingRight: 20)
        addPostButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingBottom: 20, paddingRight: 20, width: 60, height: 60)
        addPostButton.layer.cornerRadius = addPostButton.width/2
        tableView.anchor(top: view.safeAreaLayoutGuide.topAnchor, width: view.width, height: view.height)
        
    }
    //segment初期化
    private func ageSegmentSelected() -> String {
        switch ageSegement.selectedSegmentIndex {
        case 0:
            return PostAgeCategory.toddler.rawValue
        case 1:
            return PostAgeCategory.elementary.rawValue
        default:
            return PostAgeCategory.highschool.rawValue
        }
    }
    private func rankSegmentSelected() -> String {
        switch rankSegement.selectedSegmentIndex {
        case 0:
            return PostRankCategory.new.rawValue
        default:
            return PostRankCategory.popular.rawValue
        }
    }
    
    @objc private func didTapSegmentAppeard() {
        if invisibleView.isHidden {
            //
            invisibleView.isHidden = false
            ageSegement.isHidden = false
            rankSegement.isHidden = false
        }
        else {
            invisibleView.isHidden = true
            ageSegement.isHidden = true
            rankSegement.isHidden = true
        }
    }
    
    //segmentTapped
    @objc private func ageSegmentTapped() {
        selectedAgeCategory = ageSegmentSelected()
        //viewDidLoad()
        postsListner!.remove()
        setListener() {
            self.spinner.dismiss()
        }
        likedPostsListener?.remove()
        setLikedPostsListener()
    }
    @objc private func rankSegmentTapped() {
        selectedRankCategory = rankSegmentSelected()
        postsListner!.remove()
        setListener() {
            self.spinner.dismiss()
        }
        likedPostsListener?.remove()
        setLikedPostsListener()
    }
    
    @objc private func addPostTapped() {
        let vc = AddPostViewController()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }
    
    //scrollableProtocol
    func scrollTop() {
        print("ScrollableProtocolTapped")
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    
    var startingFrame : CGRect!
    var endingFrame : CGRect!
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) && addPostButton.isHidden {
            addPostButton.isHidden = false
            addPostButton.frame = startingFrame
            UIView.animate(withDuration: 1.0) {
                self.addPostButton.frame = self.endingFrame
            }
        }
    }
    func configureSizes() {
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        startingFrame = CGRect(x: 0, y: screenHeight+100, width: screenWidth, height: 100)
        endingFrame = CGRect(x: 0, y: screenHeight-100, width: screenWidth, height: 100)
        
    }
    
    ///Listenr
    private func setListener(completion: @escaping () -> Void) {
        spinner.show(in: tableView)
        //サブコレの取得が意外とだるくて、型もCollectionReferenceではない
        //let postsCollectionRef = Firestore.firestore().collectionGroup(POSTS_REF)
        if selectedRankCategory == PostRankCategory.new.rawValue {
            postsListner = postsCollectionRef!.whereField(CATEGORY, isEqualTo: selectedAgeCategory).order(by: TIMESTAMP, descending: true).addSnapshotListener({ (snapshot, error) in
                if let error = error {
                    debugPrint("DEBUG: \(error)")
                }
                else {
                    self.posts.removeAll()
                    self.posts = Post.parseData(snapshot: snapshot)
                    self.removeBlockingPosts()
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                        self.tableView.reloadData()
                        completion()
                    }
                }
            })
        }
        else {
            postsListner = postsCollectionRef!.whereField(CATEGORY, isEqualTo: selectedAgeCategory).order(by: NUM_LIKES, descending: true).addSnapshotListener({ (snapshot, error) in
                if let error = error {
                    debugPrint("DEBUG: \(error)")
                }
                else {
                    self.posts.removeAll()
                    self.posts = Post.parseData(snapshot: snapshot)
                    self.removeBlockingPosts()
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                        self.tableView.reloadData()
                        completion()
                    }
                    
                }
            })
        }
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
    private func getBlockingUsers() {
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        firestore.collection(USERS_REF).document(currentUser.uid).collection(BLOCKING_USERS_REF).getDocuments { (snapshot, error) in
            if let error = error {
                debugPrint("DEBUG: \(error)")
            } else {
                guard let snap = snapshot else {
                    print("blockingUserは存在しません。")
                    return
                }
                self.blockingUsers.removeAll()
                let documents = snap.documents
                for document in documents {
                    let data = document.data()
                    self.blockingUsers.append(data[USER_ID] as? String ?? "")
                }
            }
        }
    }
    
    private func removeBlockingPosts() {
        var i = 0
        if self.blockingUsers.count > 0 {
            for post in self.posts {
                
                for num in 0..<self.blockingUsers.count {
                    if post.userId == self.blockingUsers[num] {
                        self.posts.remove(at: i)
                        break
                    }
                }
                
                i += 1
            }
        } else {
            print("ブロックする対象がいません。")
        }
    }
    
    private func addSubViews() {
        view.addSubview(tableView)
        view.addSubview(invisibleView)
        invisibleView.addSubview(ageSegement)
        invisibleView.addSubview(rankSegement)
        view.addSubview(addPostButton)
    }
    
    
}
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
        //return mockModel.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.identifier, for: indexPath) as! PostCell
        cell.delegate = self
        if likedPostsDocumentIds.contains(posts[indexPath.row].documentId) {
            cell.configure(post: posts[indexPath.row], goodAlreadyTapped: true) //引数にselfいれて参照元のCellで委任はなし。
            
        }
        else {
            cell.configure(post: posts[indexPath.row], goodAlreadyTapped: false) //引数にselfいれて参照元のCellで委任はなし。
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = CommentsViewController(post: posts[indexPath.row])
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        //height = 0.1
        //firestorez->blockingUser
        //        var blockingPostsId = [String]()
        //var index = 0
        //        if posts[indexPath.row].userId == "XWxNakoqBKaKeiXSfNKZToaIELN2" {
        //            return 50
        //        }
        
        return UITableView.automaticDimension
    }
    
}
extension HomeViewController: PostDelegate {
    func userImageTapped(userId: String) {
        let vc = OtherUserProfileViewController(otherUserId: userId)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    func postOptionsTapped(post: Post) {
        
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
                            //super postsDocument削除
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
        let editAction = UIAlertAction(title: "Edit Post",
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
    
    func toOtherOptionsTapped(post: Post) {
        let alert = UIAlertController(title: "この投稿について",
                                      message: "この投稿を通報しますか?",
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

