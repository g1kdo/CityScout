//
//  ViewController.swift
//  CityScout
//
//  Created by Umuco Auca on 16/04/2025.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if Core.shared.isNewUser() {
            let vc = storyboard?.instantiateViewController(identifier: "cityscout") as! WelcomeViewController
            vc.modalPresentationStyle = .fullScreen
            present (vc, animated: true)
        }
    }

}

class Core{
    static let shared = Core()
    
    func isNewUser() -> Bool {
        return !UserDefaults.standard.bool(forKey: "isNewUser")
    }
    
    func setIsNewUser(_ isNewUser: Bool) {
        UserDefaults.standard.set(true, forKey: "isNewUser")
    }
}
