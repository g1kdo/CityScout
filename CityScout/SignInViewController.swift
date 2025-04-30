//
//  SignInViewController.swift
//  CityScout
//
//  Created by Umuco Auca on 24/04/2025.
//

import UIKit
import FirebaseAuth

class SignInViewController: UIViewController {

    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var signInButton: UIButton!
    @IBOutlet var forgotPasswordButton: UIButton!
    @IBOutlet var googleSignInButton: UIButton!
    @IBOutlet var facebookSignInButton: UIButton!
    @IBOutlet var appleSignInButton: UIButton!
    @IBOutlet var signUpLabel: UILabel!


    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
    }

    func setupUI() {
            // Main vertical stack view
            let mainStackView = UIStackView()
            mainStackView.axis = .vertical
            mainStackView.spacing = 30 // Adjust spacing as needed
            mainStackView.alignment = .center // Center horizontally
            mainStackView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(mainStackView)

            // Top spacing view (for equal top/bottom spacing)
            let topSpacingView = UIView()
            topSpacingView.translatesAutoresizingMaskIntoConstraints = false
            mainStackView.addArrangedSubview(topSpacingView)

            // Title label
            let titleLabel = UILabel()
            titleLabel.text = "Sign in to your account"
            titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)
            titleLabel.textColor = .black
            titleLabel.translatesAutoresizingMaskIntoConstraints = false
            mainStackView.addArrangedSubview(titleLabel)

            let subtitleLabel = UILabel()
            subtitleLabel.text = "Please sign in to your account"
            subtitleLabel.font = UIFont.systemFont(ofSize: 18)
            subtitleLabel.textColor = .gray
            subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
            mainStackView.addArrangedSubview(subtitleLabel)

            // Email label and text field container
            let emailStackView = UIStackView()
            emailStackView.axis = .vertical
            emailStackView.spacing = 6
            emailStackView.translatesAutoresizingMaskIntoConstraints = false
            let emailLabel = UILabel()
            emailLabel.text = "Email Address"
            emailLabel.font = UIFont.systemFont(ofSize: 14)
            emailLabel.textColor = .black
            emailStackView.addArrangedSubview(emailLabel)
            emailTextField.placeholder = ""
            emailTextField.borderStyle = .roundedRect
            emailTextField.layer.cornerRadius = 10
            emailTextField.keyboardType = .emailAddress
            emailTextField.autocapitalizationType = .none
            emailTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
            emailStackView.addArrangedSubview(emailTextField)
            mainStackView.addArrangedSubview(emailStackView)

            // Password label and text field container
            let passwordContainerView = UIView() // Container to hold text field and forgot password
            passwordContainerView.translatesAutoresizingMaskIntoConstraints = false
            mainStackView.addArrangedSubview(passwordContainerView)

            let passwordStackView = UIStackView()
            passwordStackView.axis = .vertical
            passwordStackView.spacing = 6
            passwordStackView.translatesAutoresizingMaskIntoConstraints = false
            passwordContainerView.addSubview(passwordStackView)

            let passwordLabel = UILabel()
            passwordLabel.text = "Password"
            passwordLabel.font = UIFont.systemFont(ofSize: 14)
            passwordLabel.textColor = .black
            passwordStackView.addArrangedSubview(passwordLabel)
            passwordTextField.placeholder = ""
            passwordTextField.borderStyle = .roundedRect
            passwordTextField.layer.cornerRadius = 10
            passwordTextField.isSecureTextEntry = true
            passwordTextField.heightAnchor.constraint(equalToConstant: 50).isActive = true
            passwordStackView.addArrangedSubview(passwordTextField)

            // Eye button adjustment
            let eyeButton = UIButton(type: .custom)
            eyeButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
            eyeButton.tintColor = .gray
            eyeButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            eyeButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)

            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: passwordTextField.frame.height)) // Add some padding
            passwordTextField.rightView = UIView() // Initialize rightView to allow setting mode
            passwordTextField.rightViewMode = .always
            passwordTextField.rightView?.addSubview(paddingView)
            eyeButton.center = CGPoint(x: paddingView.frame.width / 2 + 10, y: paddingView.frame.height / 2) // Center the eye button with padding
            passwordTextField.rightView?.addSubview(eyeButton)
            passwordTextField.rightView?.frame = CGRect(x: 0, y: 0, width: paddingView.frame.width + eyeButton.frame.width + 10, height: passwordTextField.frame.height)

            // Forgot password button (moved out of passwordStackView)
            forgotPasswordButton.setTitle("Forgot Password?", for: .normal)
            forgotPasswordButton.titleLabel?.font = UIFont.systemFont(ofSize: 14) // Increased font size
            forgotPasswordButton.tintColor = UIColor(red: 255/255, green: 105/255, blue: 0/255, alpha: 1.0) // Example orange color
            forgotPasswordButton.translatesAutoresizingMaskIntoConstraints = false
            passwordContainerView.addSubview(forgotPasswordButton)

            // Sign In button configuration
            signInButton.setTitle("Sign In", for: .normal)
            signInButton.backgroundColor = UIColor(red: 0/255, green: 175/255, blue: 240/255, alpha: 1.0) // Example blue color
            signInButton.tintColor = .white
            signInButton.layer.cornerRadius = 10
            signInButton.titleLabel?.font = UIFont.systemFont(ofSize: 28, weight: .heavy) // Increased font size
            signInButton.translatesAutoresizingMaskIntoConstraints = false
            signInButton.widthAnchor.constraint(equalToConstant: 340).isActive = true
            signInButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
            mainStackView.addArrangedSubview(signInButton)

            // "Or sign in with" label with surrounding lines
            let orSignInContainerView = UIView()
            orSignInContainerView.translatesAutoresizingMaskIntoConstraints = false
            mainStackView.addArrangedSubview(orSignInContainerView)

            let leftLine = UIView()
            leftLine.backgroundColor = .lightGray
            leftLine.translatesAutoresizingMaskIntoConstraints = false
            orSignInContainerView.addSubview(leftLine)

            let orSignInLabel = UILabel()
            orSignInLabel.text = "Or sign in with"
            orSignInLabel.font = UIFont.systemFont(ofSize: 14)
            orSignInLabel.textColor = .gray
            orSignInLabel.translatesAutoresizingMaskIntoConstraints = false
            orSignInContainerView.addSubview(orSignInLabel)

            let rightLine = UIView()
            rightLine.backgroundColor = .lightGray
            rightLine.translatesAutoresizingMaskIntoConstraints = false
            orSignInContainerView.addSubview(rightLine)

            NSLayoutConstraint.activate([
                orSignInContainerView.leadingAnchor.constraint(greaterThanOrEqualTo: mainStackView.leadingAnchor, constant: 20),
                orSignInContainerView.trailingAnchor.constraint(greaterThanOrEqualTo: mainStackView.trailingAnchor, constant: 20),
                orSignInContainerView.heightAnchor.constraint(equalToConstant: 20),
                orSignInContainerView.widthAnchor.constraint(lessThanOrEqualToConstant: 340),
                orSignInContainerView.centerXAnchor.constraint(equalTo: mainStackView.centerXAnchor),

                leftLine.leadingAnchor.constraint(equalTo: orSignInContainerView.leadingAnchor),
                leftLine.centerYAnchor.constraint(equalTo: orSignInContainerView.centerYAnchor),
                leftLine.trailingAnchor.constraint(equalTo: orSignInLabel.leadingAnchor, constant: -10), // Adjust spacing

                orSignInLabel.centerXAnchor.constraint(equalTo: orSignInContainerView.centerXAnchor),
                orSignInLabel.centerYAnchor.constraint(equalTo: orSignInContainerView.centerYAnchor),

                rightLine.leadingAnchor.constraint(equalTo: orSignInLabel.trailingAnchor, constant: 10), // Adjust spacing
                rightLine.centerYAnchor.constraint(equalTo: orSignInContainerView.centerYAnchor),
                rightLine.trailingAnchor.constraint(equalTo: orSignInContainerView.trailingAnchor),

                // Height for the lines (make them thin)
                leftLine.heightAnchor.constraint(equalToConstant: 1),
                rightLine.heightAnchor.constraint(equalToConstant: 1)
            ])

            // Social sign-in buttons stack view
            let socialStackView = UIStackView(arrangedSubviews: [googleSignInButton, facebookSignInButton, appleSignInButton])
            socialStackView.axis = .horizontal
            socialStackView.spacing = 5
            socialStackView.alignment = .center
            socialStackView.translatesAutoresizingMaskIntoConstraints = false
            mainStackView.addArrangedSubview(socialStackView)

            // Configure existing social buttons
            googleSignInButton.setImage(UIImage(named: "google_logo"), for: .normal)
            googleSignInButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
            googleSignInButton.heightAnchor.constraint(equalToConstant: 60).isActive = true

            facebookSignInButton.setImage(UIImage(named: "facebook_logo"), for: .normal)
            facebookSignInButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
            facebookSignInButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

            appleSignInButton.setImage(UIImage(named: "apple_logo"), for: .normal)
            appleSignInButton.tintColor = .black
            appleSignInButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
            appleSignInButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

            // Don't have an account? Sign up stack view
            let signUpContainerStackView = UIStackView()
            signUpContainerStackView.axis = .horizontal
            signUpContainerStackView.spacing = 4
            signUpContainerStackView.alignment = .center
            signUpContainerStackView.translatesAutoresizingMaskIntoConstraints = false
            let dontHaveAccountLabel = UILabel()
            dontHaveAccountLabel.text = "Don't have an account?"
            dontHaveAccountLabel.font = UIFont.systemFont(ofSize: 14)
            dontHaveAccountLabel.textColor = .gray
            let signUpButton = UIButton(type: .system)
            signUpButton.setTitle("Sign up", for: .normal)
            signUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
            signUpButton.tintColor = UIColor(red: 255/255, green: 105/255, blue: 0/255, alpha: 1.0) // Example orange color
            signUpContainerStackView.addArrangedSubview(dontHaveAccountLabel)
            signUpContainerStackView.addArrangedSubview(signUpButton)
            mainStackView.addArrangedSubview(signUpContainerStackView)

            // Spacing adjustments for title and subtitle
            mainStackView.setCustomSpacing(40, after: topSpacingView) // Space after the top spacing view
            mainStackView.setCustomSpacing(10, after: titleLabel)   // Space after the title label
            mainStackView.setCustomSpacing(30, after: subtitleLabel) // Space after the subtitle label
            mainStackView.setCustomSpacing(30, after: signInButton)  // Space after the sign-in button
            mainStackView.setCustomSpacing(30, after: orSignInContainerView) // Space after the "Or sign in with" lines

            // Bottom spacing view (for equal top/bottom spacing)
            let bottomSpacingView = UIView()
            bottomSpacingView.translatesAutoresizingMaskIntoConstraints = false
            mainStackView.addArrangedSubview(bottomSpacingView)

            // Constraints for the password container and forgot password button
            NSLayoutConstraint.activate([
                passwordContainerView.leadingAnchor.constraint(equalTo: mainStackView.leadingAnchor),
                passwordContainerView.trailingAnchor.constraint(equalTo: mainStackView.trailingAnchor),
                passwordStackView.leadingAnchor.constraint(equalTo: passwordContainerView.leadingAnchor),
                passwordStackView.trailingAnchor.constraint(equalTo: passwordContainerView.trailingAnchor),
                passwordStackView.topAnchor.constraint(equalTo: passwordContainerView.topAnchor),

                forgotPasswordButton.trailingAnchor.constraint(equalTo: passwordContainerView.trailingAnchor),
                forgotPasswordButton.topAnchor.constraint(equalTo: passwordStackView.bottomAnchor, constant: 8),
                forgotPasswordButton.bottomAnchor.constraint(equalTo: passwordContainerView.bottomAnchor)
            ])

            // Constraints for the main stack view and spacing views
            NSLayoutConstraint.activate([
                mainStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                mainStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor), // Center vertically initially
                mainStackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
                mainStackView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
                mainStackView.widthAnchor.constraint(lessThanOrEqualToConstant: 400), // Optional max width

                topSpacingView.heightAnchor.constraint(equalTo: bottomSpacingView.heightAnchor),
                topSpacingView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                bottomSpacingView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])

            // Width constraints for text fields
            NSLayoutConstraint.activate([
                emailTextField.widthAnchor.constraint(equalToConstant: 340),
                passwordTextField.widthAnchor.constraint(equalToConstant: 340)
            ])
        }


    @objc func togglePasswordVisibility() {
        passwordTextField.isSecureTextEntry.toggle()
        if let button = passwordTextField.rightView as? UIButton {
            let imageName = passwordTextField.isSecureTextEntry ? "eye.slash.fill" : "eye.fill"
            button.setImage(UIImage(systemName: imageName), for: .normal)
        }
    }
    
    @objc func signInTapped() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Please enter both email and password.")
            return
        }
        signInUser(email: email, password: password)
    }
    
    func signInUser(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                print("Sign in failed: \(error.localizedDescription)")
                self?.showAlert(message: "Sign in failed: \(error.localizedDescription)")
                return
            }
            // Signed in successfully
            print("User signed in: \(authResult?.user.email ?? "No Email")")
            self?.navigateToHomeScreen()
        }
    }

    func showAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }

    func navigateToHomeScreen() {
        // Replace this with your logic to transition to the next screen
        let alert = UIAlertController(title: "Success", message: "Signed in successfully!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Continue", style: .default))
        present(alert, animated: true)
    }

}
