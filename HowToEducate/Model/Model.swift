//
//  Model.swift
//  HowToEducate
//
//  Created by Lon on 2020/10/27.
//

import Foundation
import Firebase

class Post {
    private(set) var fullname: String! //setterだけprivateに 読み込みだけinternal(public)にしておくといいよね
    private(set) var timestamp: Date!
    private(set) var postText: String!
    private(set) var numLikes: Int!
    private(set) var numComments: Int!
    private(set) var documentId: String!
    private(set) var userId: String!

    //10/23
    private(set) var category: String
    //11/18
    var profileImageString: String
    
    init(fullname: String, timestamp: Date, postText: String, numLikes: Int, numComments: Int, documentId: String, userId: String, category: String, profileImageString: String) {
        self.fullname = fullname
        self.timestamp = timestamp
        self.postText = postText
        self.numLikes = numLikes
        self.numComments = numComments
        self.documentId = documentId
        self.userId = userId
        self.category = category
        self.profileImageString = profileImageString
    }
    
    class func parseData(snapshot: QuerySnapshot?) -> [Post] {
        var posts = [Post]() //return用
        guard let snap = snapshot else {
            return posts
        }
        for document in snap.documents {
            //print(document.data()) snapshot.documentsは全documents->for
            let data = document.data() //これも辞書型
            //nilかもしれない＋ThoughtModelでは、AnyでなくString
            let fullname = data[FULLNAME] as? String ?? "Anonymous" //USERNAME 打ち間違い予防
            let timestamp = data[TIMESTAMP] as? Timestamp
            let dateValue = timestamp?.dateValue() ?? Date() //NSDateと見せかけてDateになってる。Cellでformatter使って更に変換
            let postText = data[POST_TEXT] as? String ?? ""
            let numLikes = data[NUM_LIKES] as? Int ?? 0
            let numComments = data[NUM_COMMENTS] as? Int ?? 0
            let documentId = document.documentID //non-field
            let userId = data[USER_ID] as? String ?? ""
            //10/23
            let category = data[CATEGORY] as? String ?? ""
            //11/18
            let profileImageString = data[PROFILE_IMAGE_URL_STR] as? String ?? ""
            
            let newPost = Post(fullname: fullname, timestamp: dateValue, postText: postText, numLikes: numLikes, numComments: numComments, documentId: documentId, userId: userId, category: category, profileImageString: profileImageString)
            posts.append(newPost)
        }
        
        return posts
    }
}

class User {
    var username: String
    var fullname: String
    var profileImageString: String
    private(set) var userId: String
    var bio: String
    
    init(username: String, fullname: String, profileImageString: String, userId: String, bio: String) {
        self.username = username
        self.fullname = fullname
        self.profileImageString = profileImageString
        self.userId = userId
        self.bio = bio
    }
    
    class func parseMyData(snapshot: DocumentSnapshot?) -> User {
        
        var user: User
        guard let snap = snapshot else {
            return User(username: "no user", fullname: "none", profileImageString: "", userId: "0000", bio: "no profile")
        }
        //print(document.data()) snapshot.documentsは全documents->for
        //これも辞書型
        if let data = snap.data() {
            //nilかもしれない＋ThoughtModelでは、AnyでなくString
            let username = data[USERNAME] as? String ?? "Anonymous" //USERNAME 打ち間違い予防
            let userId = data[USER_ID] as? String ?? "no ID"
            let fullname = data[FULLNAME] as? String ?? "no name"
            let profileImageString = data[PROFILE_IMAGE_URL_STR] as? String ?? ""
            let bio = data[BIO] as? String ?? ""
            user = User(username: username, fullname: fullname, profileImageString: profileImageString, userId: userId, bio: bio)
            
            return user
        }
        else {
            return User(username: "no user", fullname: "none", profileImageString: "", userId: "0000", bio: "")
        }
    }
}

class Comment {
    private(set) var username: String! //setterだけprivateに 読み込みだけinternal(public)にしておくといいよね 他のClassで読み込んで使われる場合あり
    private(set) var fullname: String!
    private(set) var profileImageString: String
    private(set) var timestamp: Date!
    private(set) var commentText: String!
    private(set) var userId: String!
    private(set) var documentId: String!
    
    init(fullname: String, username: String, profileImageString: String, timestamp: Date, commentText: String, userId: String, documentId: String) {
        self.username = username
        self.fullname = fullname
        self.profileImageString = profileImageString
        self.timestamp = timestamp
        self.commentText = commentText
        self.documentId = documentId
        self.userId = userId
    }
    
  class func parseCommentData(snapshot: QuerySnapshot?) -> [Comment] {
        var comments = [Comment]() //return用
        guard let snap = snapshot else {
            return comments
        }
        for document in snap.documents {
            //print(document.data()) snapshot.documentsは全documents->for
            let data = document.data() //これも辞書型
            //nilかもしれない＋ThoughtModelでは、AnyでなくString
            let username = data[USERNAME] as? String ?? "Anonymous" //USERNAME 打ち間違い予防
            let fullname = data[FULLNAME] as? String ?? "Anonymous"
            let profileImageString = data[PROFILE_IMAGE_URL_STR] as? String ?? ""
            let timestamp = data[TIMESTAMP] as? Timestamp
            let dateValue = timestamp?.dateValue() ?? Date() //!でクラッシュしたからオプショナルにしといた。
            //NSDateと見せかけてDateになってる。Cellでformatter使って更に変換
            let commentText = data[COMMENT_TEXT] as? String ?? ""
            let documentId = document.documentID //comments/{document}  thoughtsとはまた別 サブこれだけど。
            let userId = data[USER_ID] as? String ?? ""

            let newComment = Comment(fullname: fullname, username: username, profileImageString: profileImageString, timestamp: dateValue, commentText: commentText, userId: userId, documentId: documentId)
            comments.append(newComment)
        }

        return comments
  }
}
