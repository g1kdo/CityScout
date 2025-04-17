//
//  WelcomeViewController.swift
//  CityScout
//
//  Created by Umuco Auca on 16/04/2025.
//

import UIKit

class WelcomeViewController: UIViewController {

    @IBOutlet var holderView: UIView!
    @IBOutlet var button: UIButton!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(hex: "#24BAEC")

        imageView.image = UIImage(named: "Logo")
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // ImageView center constraints
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 300),
            imageView.heightAnchor.constraint(equalToConstant: 300)
        ])

        // Title label styling
        titleLabel.text = "City Scout"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        // TitleLabel constraints
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])

        // Start rotating logo
        startLogoRotation()

        // Dismiss after ~60 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.proceedToMainScreen()
        }
    }

    private func startLogoRotation() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.toValue = NSNumber(value: -Double.pi * 2)
        rotation.duration = 3 // 3 seconds per rotation
        rotation.repeatCount = .infinity
        imageView.layer.add(rotation, forKey: "rotateLogo")
    }

    private func proceedToMainScreen() {
        // Replace this with your actual main view controller transition logic
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainVC = storyboard.instantiateViewController(withIdentifier: "onboard2") as? OnBoard2ViewController {
            mainVC.modalTransitionStyle = .crossDissolve
            mainVC.modalPresentationStyle = .fullScreen
            self.present(mainVC, animated: true, completion: nil)
        }
    }
}




