//
//  Utilities.swift
//  HowToEducate
//
//  Created by Lon on 2020/10/27.
//

import UIKit
import Firebase

class Utilities {
    func textField(withPlaceholder placeholder: String) -> UITextField {
        let textField = UITextField()
        //textField.textColor = .white
        textField.font = UIFont.systemFont(ofSize: 14)
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [NSAttributedString.Key.foregroundColor : UIColor.darkGray])
        return textField
    }
    func segmentColor(items: [String]) -> UISegmentedControl {
        let segment = UISegmentedControl(items: items)
        segment.selectedSegmentIndex = 0
        // ベースカラー
        if #available(iOS 13.0, *) {
            segment.selectedSegmentTintColor = lightPurple
        } else {
            segment.tintColor = lightPurple
        }
        //dark
        segment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: purple], for: .normal)
        // 選択時の文字色
        segment.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: darkPurple], for: .selected)
        return segment
    }
}

let lightPurple: UIColor = UIColor(red: 0.8, green: 0.8, blue: 1.0, alpha:1.0)
let purple: UIColor = UIColor(red: 0.6, green: 0.6, blue: 1.0, alpha:1.0)
let darkPurple: UIColor = UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha:1.0)

func configureTextField(textField: UITextField) {
    textField.font = UIFont(name: "IowanOldStyle-Bold",size: 14)
    textField.textColor = .darkGray
}

/// - Returns: true：半角英数字のみ、false：半角英数字以外が含まれる
func checkHalfWidthCharacters(textfield: UITextField) -> Bool {
    return textfield.text?.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
func checkHalfWidthCharactersWithText(text: String) -> Bool {
    return text.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }


//let noImageUrl = "https://www.google.com/url?sa=i&url=https%3A%2F%2Fschoolshop-lab.jp%2Fnoimage%25E4%25BA%25BA&psig=AOvVaw1CqrnqYE9Yxv-ABYQrhJgM&ust=1604229733512000&source=images&cd=vfe&ved=0CAIQjRxqFwoTCMjjjM3b3uwCFQAAAAAdAAAAABAD"


