//
//  UpdatePostViewController.swift
//  HowToEducate
//
//  Created by Lon on 2020/11/05.
//

import UIKit
import Firebase

class UpdatePostViewController: UIViewController {

    //MARK: - Properties
    
    var selectedCategory = ""
    var post: Post?
    
    let ageSegement: UISegmentedControl = {
        let items = ["幼児", "小学生", "中高生"]
        let segment = Utilities().segmentColor(items: items)
        segment.addTarget(self, action: #selector(ageSegmentSelected), for: UIControl.Event.valueChanged)
        
        return segment
    }()
    
    let postTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = lightPurple
        //placeholderがない
        textView.textColor = purple //beginEditingでdarkPurpleへ
        textView.text = "書き方のコツ\nタイトル名： 〇〇〇〇\n本文："
        textView.returnKeyType = .done
        return textView
    }()
    
    let updateButton: UIButton = {
        let button = UIButton()
        button.setTitle("更新", for: .normal)
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
    
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        guard let post = post else {
            return
        }
        postTextView.text = post.postText
        selectedCategory = post.category
        categoryDetermined()
        addSubViews()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ageSegement.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 8, paddingLeft: 20, paddingRight: 20)
        postTextView.anchor(top: ageSegement.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 14, paddingLeft: 20, paddingRight: 20, height: 300)
        updateButton.anchor(top: postTextView.bottomAnchor, paddingTop: 14)
        updateButton.centerX(inView: view)
        backButton.anchor(top: updateButton.bottomAnchor, paddingTop: 14)
        backButton.centerX(inView: view)
    }
    
    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubViews() {
        view.addSubview(ageSegement)
        view.addSubview(postTextView)
        view.addSubview(updateButton)
        view.addSubview(backButton)
    }
    
    //MARK: - Segment
    //Segmentが反映されない
    @objc private func ageSegmentSelected() {
        switch ageSegement.selectedSegmentIndex {
        case 0:
            selectedCategory = PostAgeCategory.toddler.rawValue
        case 1:
            selectedCategory = PostAgeCategory.elementary.rawValue
        default:
            selectedCategory = PostAgeCategory.highschool.rawValue
        }
    }
    
    ///取得してきたcategory からsegment.indexを変えるメソッド
    private func categoryDetermined() {
        switch selectedCategory {
        case PostAgeCategory.toddler.rawValue:
            ageSegement.selectedSegmentIndex = 0
        case PostAgeCategory.elementary.rawValue:
            ageSegement.selectedSegmentIndex = 1
        default:
            ageSegement.selectedSegmentIndex = 2
        }
    }
    
    //    func configure(thought: Thought) {
    //        self.thought = thought
    //        //delegate
    //
    //        thoughtTextView.text = thought.thoughtText
    //
    //    }
    @objc private func buttonTapped() {
        //Save to update Firestore
        guard let post = post else {
            return
        }
        Firestore.firestore().collection(POSTS_REF).document(post.documentId)
            .updateData([CATEGORY : selectedCategory,
                         POST_TEXT : postTextView.text]) { (error) in
                if let error = error {
                    debugPrint("DEBUG: Unable to update this thought: \(error.localizedDescription)")
                }
                else {
                    self.dismiss(animated: false, completion: nil)
                }
            }
    }
    @objc private func backTapped() {
        dismiss(animated: true, completion: nil)
    }

    

}
