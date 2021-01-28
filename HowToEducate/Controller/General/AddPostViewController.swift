//
//  AddPostViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/10/29.
//

import UIKit
import Firebase
import FirebaseAuth

///username, documentId, userId(rule用)は自動
class AddPostViewController: UIViewController, UITextViewDelegate {

    //MARK: - Property
    private var selectedAgeCategory = PostAgeCategory.toddler.rawValue
    
    var userIsMeRef: DocumentReference!
    
    //var userCollectionRef: CollectionReference!
    private var userListner: ListenerRegistration! //addSnapshotListener格納用
    //user情報を取ってきて、AddPostのusernameとfullnameなどを同時に満たせるようにしたい。AuthのProfileだけじゃ厳しそう
    var user: User?

    let ageSegement: UISegmentedControl = {
        let items = ["幼児", "小学生", "中高生"]
        let segment = Utilities().segmentColor(items: items)
        segment.addTarget(self, action: #selector(ageSegmentTapped), for: UIControl.Event.valueChanged)
        return segment
    }()
    
    let postTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = lightPurple
        //placeholderがない
        textView.textColor = purple //beginEditingでdarkPurpleへ
        textView.text = "書き方のコツ\nタイトル名： 〇〇〇〇\n本文："
        return textView
    }()
    
    let postButton: UIButton = {
        let button = UIButton()
        button.setTitle("投稿", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setDimensions(width: 130, height: 40)
        button.backgroundColor = darkPurple
        //button.layer.borderWidth = 1
        //button.layer.borderColor = UIColor.secondaryLabel.cgColor
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.layer.cornerRadius = 10
        button.layer.shadowColor = darkPurple.cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 5
        button.layer.shadowOffset = CGSize(width: 5, height: 5)
        return button
    }()
    
    let backButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        button.setTitle("ホームへ戻る", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 13)
        button.setTitleColor(purple, for: .normal)
        button.setDimensions(width: 130, height: 40)
        button.layer.borderColor = purple.cgColor
        button.layer.shadowColor = purple.cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 5
        button.layer.shadowOffset = CGSize(width: 5, height: 5)
        return button
    }()
    
    
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
    
    //textView.placeholder
    func textViewDidBeginEditing(_ textView: UITextView) {
        //複数あったらここのTVに働きかける
        textView.text = ""
        textView.textColor = darkPurple
    }
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        addSubViews()
        postTextView.delegate = self
        // Do any additional setup after loading the view.
        
        //userCollectionRef = Firestore.firestore().collection(USERS_REF)
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        ageSegement.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 8, paddingLeft: 20, paddingRight: 20)
        postTextView.anchor(top: ageSegement.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 14, paddingLeft: 20, paddingRight: 20, height: 300)
        postButton.anchor(top: postTextView.bottomAnchor, paddingTop: 14)
        postButton.centerX(inView: view)
        backButton.anchor(top: postButton.bottomAnchor, paddingTop: 14)
        backButton.centerX(inView: view)
    }
    override func viewWillAppear(_ animated: Bool) {
        //super.viewWillAppear(true)
        guard let uid = Auth.auth().currentUser?.uid else {
            debugPrint("DEBUG: Unable to get uid")
            return
        }
        userIsMeRef = Firestore.firestore().collection(USERS_REF).document(uid)
        setUserListener()
    }
    
    private func setUserListener() {
        //currentUserのuserDataを取得（AddSnapshotListener）し、それを用いてAddPostする。
        userListner = userIsMeRef.addSnapshotListener({ (documentSnapshot, error) in
            if let error = error {
                debugPrint("DEBUG: \(error.localizedDescription)")
            }
            else {
                //変数の中身を空にしつつparseして取得→下のAddPostでuserを使う流れ
                self.user = nil
                self.user = User.parseMyData(snapshot: documentSnapshot)
                //reloadはしなくていい取ってきたものを下で使うだけ
            }
        })
    }
    
    private func addSubViews() {
        view.addSubview(ageSegement)
        view.addSubview(postTextView)
        view.addSubview(postButton)
        view.addSubview(backButton)
    }

    
    //MARK: - Selectors
    @objc private func ageSegmentTapped() {
        selectedAgeCategory = ageSegmentSelected()
        print(selectedAgeCategory)
    }
    @objc private func buttonTapped() {
        guard let postText = postTextView.text else {
            return
        }
        //11/5 group query
        Firestore.firestore().collection(POSTS_REF).addDocument(data: [
            CATEGORY : selectedAgeCategory,
            NUM_COMMENTS : 0,
            NUM_LIKES : 0,
            POST_TEXT : postText,
            TIMESTAMP : FieldValue.serverTimestamp(),
            FULLNAME : user?.fullname ?? "",
//            USERNAME : user?.username ?? "",
            USER_ID : user?.userId ?? "",
            PROFILE_IMAGE_URL_STR : user?.profileImageString ?? "" //11/19
        ]) { (error) in
            if let error = error {
                debugPrint("DEBUG: \(error)")
            }
            else {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @objc private func backTapped() {
        dismiss(animated: true, completion: nil)
    }
}
