//
//  ForgotPasswordViewController.swift
//  CityScout
//
//  Created by Umuco Auca on 24/04/2025.
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var forgotPasswordLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var emailAddressLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var resetPasswordButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    func setupUI() {
        view.backgroundColor = .white

        // Forgot Password Label
       // forgotPasswordLabel = UILabel()
        forgotPasswordLabel.translatesAutoresizingMaskIntoConstraints = false
        forgotPasswordLabel.text = "Forgot password"
        forgotPasswordLabel.font = UIFont.boldSystemFont(ofSize: 24)
        forgotPasswordLabel.textAlignment = .center
        view.addSubview(forgotPasswordLabel)

        // Instruction Label
        //instructionLabel = UILabel()
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.text = "Enter your email account to reset your password"
        instructionLabel.font = UIFont.systemFont(ofSize: 16)
        instructionLabel.textColor = .gray
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        view.addSubview(instructionLabel)

        // Email Address Label
        //emailAddressLabel = UILabel()
        emailAddressLabel.translatesAutoresizingMaskIntoConstraints = false
        emailAddressLabel.text = "Email Address"
        emailAddressLabel.font = UIFont.systemFont(ofSize: 16)
        view.addSubview(emailAddressLabel)

        // Email Text Field
        //emailTextField = UITextField()
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.borderStyle = .roundedRect
        emailTextField.keyboardType = .emailAddress
        emailTextField.placeholder = "adogreatkaty@gmail.com" // Placeholder text
        view.addSubview(emailTextField)

        // Reset Password Button
        //resetPasswordButton = UIButton(type: .system)
        resetPasswordButton.translatesAutoresizingMaskIntoConstraints = false
        resetPasswordButton.setTitle("Reset Password", for: .normal)
        resetPasswordButton.backgroundColor = UIColor(red: 33/255, green: 158/255, blue: 215/255, alpha: 1.0) // Example blue color
        resetPasswordButton.setTitleColor(.white, for: .normal)
        resetPasswordButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        resetPasswordButton.layer.cornerRadius = 8
        view.addSubview(resetPasswordButton)

        // Constraints
        NSLayoutConstraint.activate([
            forgotPasswordLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            forgotPasswordLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            forgotPasswordLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            instructionLabel.topAnchor.constraint(equalTo: forgotPasswordLabel.bottomAnchor, constant: 10),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            emailAddressLabel.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 30),
            emailAddressLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emailAddressLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            emailTextField.topAnchor.constraint(equalTo: emailAddressLabel.bottomAnchor, constant: 8),
            emailTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            emailTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            emailTextField.heightAnchor.constraint(equalToConstant: 44),

            resetPasswordButton.topAnchor.constraint(equalTo: emailTextField.bottomAnchor, constant: 30),
            resetPasswordButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            resetPasswordButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resetPasswordButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
}
