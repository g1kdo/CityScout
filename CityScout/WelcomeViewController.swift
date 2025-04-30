//
//  WelcomeViewController.swift
//  CityScout
//
//  Created by Umuco Auca on 16/04/2025.
//

import UIKit
import FirebaseAnalytics

class WelcomeViewController: UIViewController {

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

//        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
//            AnalyticsParameterScreenName: "Welcome Screen",
//            AnalyticsParameterScreenClass: "\(WelcomeViewController.self)"
//        ])

        // TitleLabel constraints
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])

        startLogoAnimation()
        animateTitleLabel()


        // Dismiss after ~60 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.proceedToMainScreen()
        }
    }
    
    private func startLogoAnimation() {
        imageView.alpha = 0
        imageView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)

        UIView.animate(withDuration: 1.2,
                       delay: 0.2,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseOut,
                       animations: {
            self.imageView.alpha = 1
            self.imageView.transform = CGAffineTransform.identity
        }, completion: nil)
    }

    private func animateTitleLabel() {
        titleLabel.alpha = 0
        UIView.animate(withDuration: 1.0,
                       delay: 1.0,
                       options: .curveEaseOut,
                       animations: {
            self.titleLabel.alpha = 1
        }, completion: nil)
    }


    private func proceedToMainScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainVC = storyboard.instantiateViewController(withIdentifier: "onboard1") as? Onboarding1ViewController {
            mainVC.modalTransitionStyle = .crossDissolve
            mainVC.modalPresentationStyle = .fullScreen
            self.present(mainVC, animated: true, completion: nil)
        }
    }
}




