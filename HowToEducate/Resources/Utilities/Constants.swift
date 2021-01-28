//
//  Constants.swift
//  HowToEducate
//
//  Created by Lon on 2020/10/27.
//

import Foundation
import Firebase

let storageRef = Storage.storage().reference()

let USERS_REF = "users"
let POSTS_REF = "posts"
let COMMENTS_REF = "comments"
let CATEGORY = "category"

let USER_ID = "userId"
let EMAIL = "email"
let PASSWORD = "password"
let BIO = "bio"
let USERNAME = "username"
let FULLNAME = "fullname"
let PROFILE_IMAGE_URL_STR = "profileImageUrlString"
let NUM_COMMENTS = "numComments"
let NUM_LIKES = "numLikes"
let POST_TYPE = "postType"
let THUMBNAIL_IMAGE_STRING = "thumbnailImageString"
let TIMESTAMP = "timestamp"
let POST_TEXT = "postText"
let POSTS_COUNT = "postsCount"
let POST_LIKES_COUNT = "postsLikesCount" //Postsのいいね数の合計
let COMMENT_TEXT = "commentText"
let LIKED_USER = "likedUsers"
let LIKED_POST = "likedPosts"

let PROFILE_IMAGES = "profile_images"
let DOCUMENT_ID = "documentId"

let ID_TOKEN = "idToken"

let ADD_OLD_PASSWORD = "現在のパスワードを入力"
let ADD_NEW_PASSWORD = "新しいパスワードを入力(半角英数8文字以上)"

let BLOCKING_USERS_REF = "blockingUsers"
let BLOCKED_USERS_REF = "blockedUsers"

let REPORTS_REF = "reports"
let REPORTED_USER_ID = "reportedUserId"
let REPORTING_USER_ID = "reportingUserId"
