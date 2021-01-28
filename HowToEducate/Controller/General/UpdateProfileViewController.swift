//
//  UpdateProfileViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/11/15.
//
import UIKit
import Firebase
import SDWebImage
import JGProgressHUD

struct EditProfileFormModel {
    let label: String
    let placeholder: String
    var value: String?
}

//tvDelegate追加 11/15
class UpdateProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    
    //MARK: - Properties
    var user: User?
    private var updatedUser: User?
    
    private var posts = [Post]()
    
    //12/24
    private var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()
    
    
    //updateにすべてのdocumentのdocumentIdを渡すためのもの 11/21
    private var allPosts = [Post]()
    private var allPostsDocuments = [String]()
    private var myCommentsDocuments = [String]()
    
    private var wordCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = darkPurple
        return label
    }()
    fileprivate var maxWordCount: Int = 250 //最大文字数
    fileprivate let placeholder: String = "テキストを入力・・・" //プレイスホルダー
    
    var tableView: CustomTableView = {
        let tv = CustomTableView()
        //Static member 'identifier' cannot be used on instance of type 'FormTableViewCell' インスタンスに依存しないので、インスタンス化してから参照すると怒られる
        tv.register(FormCell.self, forCellReuseIdentifier: FormCell.identifier)
        tv.separatorColor = lightPurple
        return tv
    }()
    
    //tableViewHeaderで初期化 <- photoPickerで使うため
    var profilePhotoButton = UIButton()
    
    private let textView: UITextView = {
        let textView = UITextView()
        textView.textColor = .darkGray
        textView.backgroundColor = lightPurple
        textView.text = "プロフィール"
        return textView
    }()
    
    private var pickerdImage = UIImage()
    private var models = [[EditProfileFormModel]]()
    
    //12/31
    private var keyboardHeight = 0
    
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureModels()
        tableView.tableHeaderView = createTableHeaderView()
        tableView.tableFooterView = createTableFooterView()
        tableView.dataSource = self
        tableView.estimatedRowHeight = 40
        self.edgesForExtendedLayout = .all
        //tableView.translatesAutoresizingMaskIntoConstraints = false
        textView.text = user?.bio
        textView.delegate = self
        view.backgroundColor = .white
        tableView.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "保存",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapSave))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "キャンセル",
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(didTapCancel))
        view.addSubview(tableView)

        guard let user = user else {
            return
        }
        updatedUser = User(username: user.username, fullname: user.fullname,
                           profileImageString: user.profileImageString, userId: user.userId, bio: user.bio)
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.anchor(top: view.topAnchor, left: view.leftAnchor, width: view.width, height: view.height)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //documentsを取ってくる
        getAllPostsDocuments()
        setupNotifications()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeObservers()
    }
    //MARK: - ??
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    init(user: User, posts: [Post]) {
        super.init(nibName: nil, bundle: nil)
        self.user = user
        self.posts = posts
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange), name: UIResponder.keyboardWillHideNotification, object: nil)
        //scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    //@objc private func keyboardWillShow(_ notification: Notification) {
        
    //}
    @objc private func keyboardWillChange(_ notification: Notification) {
        
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        if notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillChangeFrameNotification {
            self.keyboardHeight = Int(keyboardRect.height - 150)
            if view.frame.origin.y < -40 {
                print("何もしない。")
            }
            else {
                view.frame.origin.y -= CGFloat(keyboardHeight)
            }
        } else {
            view.frame.origin.y = -(view.safeAreaInsets.bottom) + ((navigationController?.navigationBar.height ?? 0)*1.5)
        }
    }
    private func removeObservers() {
        NotificationCenter.default.removeObserver(UIResponder.keyboardWillShowNotification)
        NotificationCenter.default.removeObserver(UIResponder.keyboardWillChangeFrameNotification)
        NotificationCenter.default.removeObserver(UIResponder.keyboardWillHideNotification)
    }
    
    private func getAllPostsDocuments() {
        //セキュリティルール的に他のUserのPostの読み取りもできるはず
        Firestore.firestore().collection(POSTS_REF).getDocuments { (snapshot, error) in
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
    
    //MARK: - Selectors
    //NavigationBar
    @objc private func didTapSave() {
        guard let updatedUser = updatedUser else {
            return
        }
        //直接saveButtonが押された時用
        updatedUser.bio = textView.text
        
        //updatedUserのusernameの半角英数判定→Alert
        guard checkHalfWidthCharactersWithText(text: updatedUser.username) && !(updatedUser.username.isEmpty) else {
            let alert = UIAlertController(title: "入力に誤りがあります。", message: "半角英数字5~10文字で入力してください。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "戻る", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        guard let user = user else {
            let alert = UIAlertController(title: "User Error", message: "Userが無効です。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "戻る", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }
        
        //imageUrlがない場合でも、postsとcommentsの更新は必要
        guard let imageData = pickerdImage.jpegData(compressionQuality: 0.3) else {
            //firestoreに画像以外を保存
            Firestore.firestore().collection(USERS_REF).document(user.userId)
                .setData([
                    FULLNAME : self.updatedUser?.fullname,
                    USERNAME : self.updatedUser?.username,
                    BIO : self.updatedUser?.bio
                ], merge: true)
            //自分の全PostのFullNameを変更
            for post in self.posts {
                Firestore.firestore().collection(POSTS_REF).document(post.documentId).setData([FULLNAME : self.updatedUser?.fullname], merge: true)
            }
            //全Postの中の自分のコメントを抽出
            for documentId in self.allPostsDocuments {
                Firestore.firestore().collection(POSTS_REF).document(documentId).collection(COMMENTS_REF).whereField(USER_ID, isEqualTo: user.userId).getDocuments { (snapshot, error) in
                    
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
                    
                    //コメントがもつprofileImageUrlStringを変更 グループクエリなし。
                    for myCommentId in self.myCommentsDocuments {
                        //print("いいいいいい\(myCommentId)")
                        Firestore.firestore().collection(POSTS_REF).document(documentId).collection(COMMENTS_REF).document(myCommentId).setData(
                            [FULLNAME : self.updatedUser?.fullname], merge: true)
                    }
                    //Authのprofileも変更
                    if let currentUser = Auth.auth().currentUser {
                        let req = currentUser.createProfileChangeRequest()
                        req.displayName = self.updatedUser?.fullname ?? user.fullname
                        req.commitChanges(completion: { error in
                            if let error = error {
                                debugPrint(error)
                            }
                        })
                    }
                }
            }
            //画面遷移
            self.navigationController?.popViewController(animated: false)
            return
        }
        let filename = UUID().uuidString
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        let fileRef = "\(PROFILE_IMAGES)/\(filename).jpeg"
        storageRef.child(fileRef).putData(imageData, metadata: meta) { (storageMeta, error) in
            storageRef.child(fileRef).downloadURL { (url, error) in
                //storageRef.downloadURL { (url, error) in
                if let downloadError = error {
                    debugPrint("DEBUG: Unable to download the URL of your photo \(downloadError)")
                }
                else {
                    print("Storageの参照元のデータの取得完了。")
                    //元々の画像をStorageから削除
                    let userProfileImg = user.profileImageString
                    var imageRef: String = ""
                    if userProfileImg.contains("firebasestorage") {
                            let firstChar = userProfileImg.index(userProfileImg.startIndex, offsetBy: 94)
                            var lastNum = 135
                            repeat {
                                var lastChar = userProfileImg.index(userProfileImg.startIndex, offsetBy: lastNum)
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
                                }
                                //??user
                                self.user?.profileImageString = url?.absoluteString ?? ""
                            }
                    } else if userProfileImg != "" {
                        self.user?.profileImageString = url?.absoluteString ?? ""
                    } else {
                        print("空文字。")
                    }
                    
                }
                
                Firestore.firestore().collection(USERS_REF).document(user.userId)
                    .setData([
                        FULLNAME : self.updatedUser?.fullname,
                        USERNAME : self.updatedUser?.username,
                        BIO : self.updatedUser?.bio,
                        PROFILE_IMAGE_URL_STR : url?.absoluteString ?? ""
                    ], merge: true)
                
                guard let url = url else {
                    return
                }
                for post in self.posts {
                    Firestore.firestore().collection(POSTS_REF).document(post.documentId).setData([PROFILE_IMAGE_URL_STR : url.absoluteString, FULLNAME : self.updatedUser?.fullname], merge: true)
                }
                for documentId in self.allPostsDocuments {
                    //print(documentId)
                    //postsのdocumentIdを用いて、自分のuserIdの入ったコメントのdocumentIdを
                    Firestore.firestore().collection(POSTS_REF).document(documentId).collection(COMMENTS_REF).whereField(USER_ID, isEqualTo: user.userId).getDocuments { (snapshot, error) in
                        
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
                        
                        //コメントがもつprofileImageUrlStringを変更 グループクエリなし。
                        for myCommentId in self.myCommentsDocuments {
                            Firestore.firestore().collection(POSTS_REF).document(documentId).collection(COMMENTS_REF).document(myCommentId).setData(
                                [PROFILE_IMAGE_URL_STR : url.absoluteString,
                                 FULLNAME : self.updatedUser?.fullname], merge: true)
                        }
                        if let currentUser = Auth.auth().currentUser {
                            let req = currentUser.createProfileChangeRequest()
                            req.displayName = self.updatedUser?.fullname ?? user.fullname
                            req.photoURL = URL(string: url.absoluteString)
                            req.commitChanges(completion: { error in
                                if let error = error {
                                    debugPrint(error)
                                }
                            })
                        }
                    }
                }
            }
        }
        
        
        
        self.navigationController?.popViewController(animated: false)
    }
    @objc private func didTapCancel() {
        self.navigationController?.popViewController(animated: false)
    }
    //profileImage
    @objc func didTapChangeProfilePhotoButton() {
        let actionSheet = UIAlertController(title: "プロフィール画像",
                                            message: "プロフィール画像を変更",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "写真を撮る", style: .default, handler: { [weak self] _ in
            self?.presentCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "ライブラリから選択", style: .default, handler: { [weak self] _ in  self?.presentPhotoPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "キャンセル", style: .destructive, handler: nil))
        
        actionSheet.popoverPresentationController?.sourceView = view
        actionSheet.popoverPresentationController?.sourceRect = view.bounds
        present(actionSheet, animated: true)
    }
    
    
    //MARK: - Helpers
    private func configureModels() {
        //name, username, website, bio
        let section1Labels = ["Name", "Username"]
        var section1 = [EditProfileFormModel]()
        var model: EditProfileFormModel
        for label in section1Labels {
            switch label {
            case "Name":
                model = EditProfileFormModel(label: label,
                                             placeholder: "Enter \(label)...",
                                             value: user?.fullname)
            default:
                model = EditProfileFormModel(label: label,
                                             placeholder: "Enter \(label)...",
                                             value: user?.username)
            }
            
            section1.append(model)
        }
        models.append(section1)
    }
    
    private func createTableFooterView() -> UIView {
        let footer = UIView(frame: CGRect(x: 0,
                                          y: 0,
                                          width: view.width,
                                          height: view.height/4))
        textView.frame = CGRect(x: 5, y: 25, width: view.width-10, height: view.height/4-35)
        wordCountLabel.frame = CGRect(x: view.width-40, y: 5, width: 40, height: 10)
        footer.addSubview(textView)
        footer.addSubview(wordCountLabel)
        return footer
    }
    
    func createTableHeaderView() -> UIView {
        let header = UIView(frame: CGRect(x: 0,
                                          y: 0,
                                          width: view.width,
                                          height: view.height/4).integral)
        let size = header.height / 1.5
        profilePhotoButton = UIButton(frame: CGRect(x: (view.width-size)/2,
                                                    y: (header.height-size)/2,
                                                    width: size,
                                                    height: size))
        header.addSubview(profilePhotoButton)
        profilePhotoButton.layer.masksToBounds = true
        profilePhotoButton.layer.cornerRadius = size/2.0
        profilePhotoButton.addTarget(self,
                                     action: #selector(didTapChangeProfilePhotoButton),
                                     for: .touchUpInside)
        
        profilePhotoButton.setImage(UIImage(systemName: "plus.circle"),
                                    for: .normal)
        profilePhotoButton.tintColor = purple
        if user?.profileImageString != "" || user?.profileImageString != nil {
            guard let user = user else {
                return header
            }
            profilePhotoButton.sd_setBackgroundImage(with: URL(string: user.profileImageString), for: .normal, completed: nil)
            
        }
        
        return header
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return models.count // 1??
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return models[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: FormCell.identifier, for: indexPath) as! FormCell
        cell.configure(with: model)
        cell.delegate = self
        //cell.textLabel?.text = model.label
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    //MARK: - textfield
    //工夫点 override x override
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    //MARK: - TextViewDelegate
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "プロフィール" {
            textView.text = ""
        }
        //print(self.keyboardHeight)
        
        //setupNotifications()
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        textView.endEditing(true)
        updatedUser?.bio = textView.text
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let existingLines = textView.text.components(separatedBy: .newlines)//既に存在する改行数
        let newLines = text.components(separatedBy: .newlines)//新規改行数
        let linesAfterChange = existingLines.count + newLines.count - 1 //最終改行数。-1は編集したら必ず1改行としてカウントされるから。
        
        return linesAfterChange <= 8 && textView.text.count + (text.count - range.length) <= maxWordCount
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let existingLines = textView.text.components(separatedBy: .newlines)//既に存在する改行数
        if existingLines.count <= 8 {
            self.wordCountLabel.text = "\(maxWordCount - textView.text.count)"
            
        }
    }

    
}


extension UpdateProfileViewController: FormCellDelegate {
    func formCell(_ cell: FormCell, didUpdateField updatedModel: EditProfileFormModel) {
        //普通にUpdateVCのFirestore保存用のUserModelに入れ直す。あくまでshouldreturn, touchesBeganのときに呼ばれるだけだから
        //一旦newUserModelかなんかに入れてって感じ
        guard let updatedUser = updatedUser else {
            return
        }
        switch updatedModel.label {
        case "Name":
            updatedUser.fullname = updatedModel.value ?? "Anonymous"
        default:
            updatedUser.username = updatedModel.value ?? "vacant@username"
        }
        
    }
}

class CustomTableView: UITableView {
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.next?.touchesBegan(touches, with: event)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touches ended")
        
    }
}

//MARK: - CameraDelegate
extension UpdateProfileViewController: UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    func presentPhotoActionSheet() {
        let actionSheet = UIAlertController(title: "画像の選択方法", message: "How would you like select a picture?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "TAKE photo", style: .default, handler: { [weak self] _ in  self?.presentCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose photo", style: .default, handler: { [weak self] _ in  self?.presentPhotoPicker() }))
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    
    //MARK: - delegateMethod
    //複数選択にしたい
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //info[UimagePickerConroller.InfoKey.editedImage]
        guard let selectedImage = info[.editedImage]  else { return }
        pickerdImage = selectedImage as! UIImage
        profilePhotoButton.setImage(pickerdImage as? UIImage, for: .normal)
        
        
        //user?.profileImageString
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
