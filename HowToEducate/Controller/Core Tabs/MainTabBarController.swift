//
//  MainTabBarController.swift
//  HowToEducate
//
//  Created by Lon on 2020/10/27.
//

import UIKit
import Firebase


class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    //MARK: - Properties
    private var scrollBool: Bool = false
    private var lastSelectedIndex = 0
    
    //MARK: - LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.barTintColor = lightPurple
        tabBar.tintColor = darkPurple
        configureViewControllers()
        self.edgesForExtendedLayout = .all
        guard let currentUser = Auth.auth().currentUser else {
            return
        }
        Firestore.firestore().collection(USERS_REF).document(currentUser.uid).getDocument { (document, error) in
            if let error = error {
                debugPrint("DEBUG: Unable to get document for currentUser: \(error)")
            }
            else {
                print("currentUser")
                guard let document = document else {
                    return
                }
                let data = document.data()
                let username = data?[USERNAME] as? String ?? ""
                self.validateUsername(username: username)
            }
        }
    }
    
//    override func viewWillAppear(_ animated: Bool) {
        
//    }
    
    //MARK: - API
    private func validateUsername(username: String) {
        if username == "" {
            print("Username登録へ")
            let vc = UINavigationController(rootViewController: UsernameViewController())
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: false, completion: nil)
        }
        else {
            print("usernmae入ってます")
        }
    }
    

    
    //MARK: - Selector
    
    
    
    //MARK: - Helpers
    private func configureViewControllers() {
        let home = HomeViewController()
        let profile = ProfileViewController()
        let nav1 = templateNavigationController(image: UIImage(systemName: "house"), rootViewController: home)
        let nav2 = templateNavigationController(image: UIImage(systemName: "person"), rootViewController: profile)
        
        viewControllers = [nav1, nav2]
        
        home.tableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: self.tabBar.height*2, right: 0.0)
        
    }

    private func templateNavigationController(image: UIImage?, rootViewController: UIViewController) -> UINavigationController {
        let nav = UINavigationController(rootViewController: rootViewController)
        nav.tabBarItem.image = image
        return nav
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        self.scrollBool = false
        // 表示しているvcがnavigationControllerルートのときはスクロールさせる
        // ルート以外は、navigationControllerの戻る機能を優先しスクロールさせない
        if let navigationController: UINavigationController = viewController as? UINavigationController {
            let visibleVC = navigationController.visibleViewController!
            if let index = navigationController.viewControllers.firstIndex(of: visibleVC), index == 0 {
                scrollBool = true
            }
        }
        
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard self.scrollBool else {
            return
        }
        if self.lastSelectedIndex == tabBarController.selectedIndex {
            if let navigationController: UINavigationController = viewController as? UINavigationController {
                let visibleVC = navigationController.visibleViewController!
                if let scrollableVC = visibleVC as? ScrollableProtocol {
                    scrollableVC.scrollTop()
                }
            }
        }
        self.lastSelectedIndex = tabBarController.selectedIndex
    }
}
