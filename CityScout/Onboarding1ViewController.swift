import UIKit

// Note: UIColor(hex:) initializer defined elsewhere in project
class Onboarding1ViewController: UIViewController {
    // MARK: - UI Elements
    private let imageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "OnBoard1"))
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 30
        iv.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return iv
    }()

    private let titleLine1Label: UILabel = {
        let lbl = UILabel()
        lbl.text = "Life is short and the world is"
        lbl.font = UIFont.systemFont(ofSize: 26, weight: .heavy)
        lbl.textColor = .black
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()

    private let titleLine2Label: UILabel = {
        let lbl = UILabel()
        lbl.text = "wide"
        lbl.font = UIFont.systemFont(ofSize: 26, weight: .heavy)
        lbl.textColor = UIColor(hex: "#FF7029")
        lbl.textAlignment = .center
        return lbl
    }()

    private let arcImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "Line"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let subtitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "At Friends tours and travel, we customize reliable and trustworthy educational tours to destinations all over the world"
        lbl.font = UIFont.systemFont(ofSize: 16)
        lbl.textColor = .gray
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()

    private let pageIndicatorStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8

        let active = UIView()
        active.backgroundColor = UIColor(hex: "#24BAEC")
        active.layer.cornerRadius = 4
        active.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            active.widthAnchor.constraint(equalToConstant: 24),
            active.heightAnchor.constraint(equalToConstant: 8)
        ])

        let medium = UIView()
        medium.backgroundColor = UIColor(hex: "#24BAEC").withAlphaComponent(0.4)
        medium.layer.cornerRadius = 4
        medium.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            medium.widthAnchor.constraint(equalToConstant: 16),
            medium.heightAnchor.constraint(equalToConstant: 8)
        ])

        let small = UIView()
        small.backgroundColor = UIColor(hex: "#24BAEC").withAlphaComponent(0.2)
        small.layer.cornerRadius = 4
        small.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            small.widthAnchor.constraint(equalToConstant: 8),
            small.heightAnchor.constraint(equalToConstant: 8)
        ])

        stack.addArrangedSubview(active)
        stack.addArrangedSubview(medium)
        stack.addArrangedSubview(small)
        return stack
    }()

    private let nextButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Get Started", for: .normal)
        btn.backgroundColor = UIColor(hex: "#24BAEC")
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btn.layer.cornerRadius = 10
        return btn
    }()

    private let skipButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Skip", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        return btn
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // Add targets
        nextButton.addTarget(self, action: #selector(getStartedTapped), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)

        // Add subviews
        view.addSubview(imageView)
        view.addSubview(titleLine1Label)
        view.addSubview(titleLine2Label)
        view.addSubview(arcImageView)
        view.addSubview(subtitleLabel)
        view.addSubview(pageIndicatorStack)
        view.addSubview(nextButton)
        view.addSubview(skipButton)

        setupConstraints()
    }

    private func setupConstraints() {
        [imageView, titleLine1Label, titleLine2Label, arcImageView,
         subtitleLabel, pageIndicatorStack, nextButton, skipButton].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

        NSLayoutConstraint.activate([
            // Image height fixed to 60%
            imageView.topAnchor.constraint(equalTo: view.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.55),

            // Title line1
            titleLine1Label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 30),
            titleLine1Label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            titleLine1Label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            // Title line2
            titleLine2Label.topAnchor.constraint(equalTo: titleLine1Label.bottomAnchor, constant: 4),
            titleLine2Label.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Arc under "wide"
            arcImageView.topAnchor.constraint(equalTo: titleLine2Label.bottomAnchor, constant: 4),
            arcImageView.centerXAnchor.constraint(equalTo: titleLine2Label.centerXAnchor),
            arcImageView.widthAnchor.constraint(equalToConstant: 60),
            arcImageView.heightAnchor.constraint(equalToConstant: 10),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: arcImageView.bottomAnchor, constant: 14),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            // Next button
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 50),

            // Page indicators
            pageIndicatorStack.bottomAnchor.constraint(equalTo: nextButton.topAnchor, constant: -20),
            pageIndicatorStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            // Skip button
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    // MARK: - Actions
    @objc private func skipTapped() {
        // handle skip
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let mainVC = storyboard.instantiateViewController(withIdentifier: "signin") as? SignInViewController {
            mainVC.modalTransitionStyle = .crossDissolve
            mainVC.modalPresentationStyle = .fullScreen
            self.present(mainVC, animated: true, completion: nil)
           }
    }

    @objc private func getStartedTapped() {
        // handle get started
        // Instantiate the third onboarding view controller
     let storyboard = UIStoryboard(name: "Main", bundle: nil)
     if let mainVC = storyboard.instantiateViewController(withIdentifier: "onboard2") as? OnBoard2ViewController {
         mainVC.modalTransitionStyle = .crossDissolve
         mainVC.modalPresentationStyle = .fullScreen
         self.present(mainVC, animated: true, completion: nil)
        }
    }
}
