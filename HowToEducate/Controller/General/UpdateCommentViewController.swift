//
//  UpdateCommentViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/11/06.
//

import UIKit
import Firebase

class UpdateCommentViewController: UIViewController {

    //MARK: - Properties
    private let commentText: UITextView = {
        let textView = UITextView()
        textView.textColor = .darkGray
        textView.backgroundColor = lightPurple
        return textView
    }()
    
    private let updateButton: UIButton = {
        let button = UIButton()
        button.setTitle("更新", for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = darkPurple
        //button.layer.borderWidth = 1
        //button.layer.borderColor = UIColor.secondaryLabel.cgColor
        button.addTarget(self, action: #selector(updateTapped), for: .touchUpInside)
        button.layer.cornerRadius = 10
        button.layer.shadowColor = darkPurple.cgColor
        button.layer.shadowOpacity = 1
        button.layer.shadowRadius = 5
        button.layer.shadowOffset = CGSize(width: 5, height: 5)
        return button
    }()
    
    init(commentData: (Comment, Post, Message)) {
        super.init(nibName: nil, bundle: nil)
        self.commentData = commentData
        //タプル不安
        self.commentText.text = commentData.0.commentText
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Variables
    //遷移時に渡されたData（コードベースなら初期化＋configure時）
    var commentData: (comment: Comment, post: Post, message: Message)! //Tuple
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        commentText.layer.cornerRadius = 10
        updateButton.layer.cornerRadius = 10
        
        commentText.text = commentData.comment.commentText
        addSubViews()
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        commentText.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 20, paddingLeft: 12, paddingRight: 12, height: 200)
        updateButton.anchor(top: commentText.bottomAnchor, paddingTop: 16, width: 130, height: 40)
        updateButton.centerX(inView: view)
    }
    
    private func addSubViews() {
        view.addSubview(commentText)
        view.addSubview(updateButton)
    }
    
    //Numの表示とか変えない→transactionでなくていい。
    @objc private func updateTapped(_ sender: UIButton) {
        Firestore.firestore().collection(POSTS_REF).document(commentData.post.documentId)
            .collection(COMMENTS_REF).document(commentData.comment.documentId)
            .updateData([COMMENT_TEXT : commentText.text]) { (error) in
                if let error = error {
                    debugPrint("DEBUG: Unable to update comment \(error.localizedDescription)")
                }
                else {
                    
                    self.navigationController?.popViewController(animated: true)
                }
            }
    }
}
