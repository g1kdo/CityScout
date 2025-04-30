//
//  OnBoard3ViewController.swift
//  CityScout
//
//  Created by Umuco Auca on 23/04/2025.
//

import UIKit

class OnBoard3ViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var lineView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var peopleLabel: UILabel!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var skipButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = UIImage(named: "OnBoard3")
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 30

        // Title (first part)
        titleLabel.text = "People don't take trips, trips take"
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .heavy)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        // Explore label (orange)
        peopleLabel.text = "people"
        peopleLabel.font = UIFont.systemFont(ofSize: 26, weight: .bold)
        peopleLabel.textColor = UIColor(hex: "#FF7029")
        peopleLabel.textAlignment = .center

        // Subtitle
        subtitleLabel.text = "To get the best of your adventure you just need to leave and go where you like. We are waiting for you"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .gray
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        // Next button
        nextButton.setTitle("Next", for: .normal)
        nextButton.backgroundColor = UIColor(red: 30/255, green: 175/255, blue: 240/255, alpha: 1.0)
        nextButton.setTitleColor(.white, for: .normal)
        nextButton.layer.cornerRadius = 10
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)

        // Skip button
        skipButton.setTitle("Skip", for: .normal)
        skipButton.setTitleColor(.white, for: .normal)
        skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)

        // LineView image setup
        lineView.image = UIImage(named: "Line")
        lineView.contentMode = .scaleAspectFit

        // Custom page indicator stack
        //setupPageIndicatorStack()
        view.addSubview(pageIndicatorStack)

        // Constraints
        setupConstraints()
    }

    
    private let pageIndicatorStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center

        let medium = UIView()
        medium.backgroundColor = UIColor(hex: "#24BAEC").withAlphaComponent(0.4)
        medium.layer.cornerRadius = 4
        medium.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            medium.widthAnchor.constraint(equalToConstant: 16),
            medium.heightAnchor.constraint(equalToConstant: 8)
        ])

        let active = UIView()
        active.backgroundColor = UIColor(hex: "#24BAEC")
        active.layer.cornerRadius = 4
        active.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            active.widthAnchor.constraint(equalToConstant: 24),
            active.heightAnchor.constraint(equalToConstant: 8)
        ])

        let small = UIView()
        small.backgroundColor = UIColor(hex: "#24BAEC").withAlphaComponent(0.2)
        small.layer.cornerRadius = 4
        small.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            small.widthAnchor.constraint(equalToConstant: 8),
            small.heightAnchor.constraint(equalToConstant: 8)
        ])

        stack.addArrangedSubview(small)
        stack.addArrangedSubview(medium)
        stack.addArrangedSubview(active)

        return stack
    }()


    func setupConstraints() {
        // Disable implicit constraints
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        peopleLabel.translatesAutoresizingMaskIntoConstraints = false
        lineView.translatesAutoresizingMaskIntoConstraints = false
        pageIndicatorStack.translatesAutoresizingMaskIntoConstraints = false
        lineView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Image View Constraints
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.55),

            
            // Title
               titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 30),
               titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
               titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

               // People label
               peopleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
               peopleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

               // LineView image
            lineView.topAnchor.constraint(equalTo: peopleLabel.bottomAnchor, constant: 8), // Adjust constant if needed
               lineView.centerXAnchor.constraint(equalTo: peopleLabel.centerXAnchor),
               lineView.widthAnchor.constraint(equalToConstant: 60),  // Set width if necessary
               lineView.heightAnchor.constraint(equalToConstant: 10),

               // Subtitle
               subtitleLabel.topAnchor.constraint(equalTo: lineView.bottomAnchor, constant: 16),
               subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
               subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

               // Page indicator stack
               pageIndicatorStack.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -20),
               pageIndicatorStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Next Button Constraints
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 50),

            // Skip Button Constraints
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    @objc func nextButtonTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainVC = storyboard.instantiateViewController(withIdentifier: "signin") as? SignInViewController {
            mainVC.modalTransitionStyle = .crossDissolve
            mainVC.modalPresentationStyle = .fullScreen
            self.present(mainVC, animated: true, completion: nil)
           }
       }

       @objc func skipButtonTapped() {
           let storyboard = UIStoryboard(name: "Main", bundle: nil)
           if let mainVC = storyboard.instantiateViewController(withIdentifier: "signin") as? SignInViewController {
               mainVC.modalTransitionStyle = .crossDissolve
               mainVC.modalPresentationStyle = .fullScreen
               self.present(mainVC, animated: true, completion: nil)
              }
       }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
