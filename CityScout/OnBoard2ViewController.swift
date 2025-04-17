//
//  OnBoard2ViewController.swift
//  CityScout
//
//  Created by Umuco Auca on 17/04/2025.
//

import UIKit

class OnBoard2ViewController: UIViewController {

    
    @IBOutlet var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
              imageView.image = UIImage(named: "OnBoard")
              imageView.translatesAutoresizingMaskIntoConstraints = false
             // titleLabel.translatesAutoresizingMaskIntoConstraints = false

              // ImageView center constraints
              NSLayoutConstraint.activate([
                  imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                  imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                  imageView.widthAnchor.constraint(equalToConstant: 300),
                  imageView.heightAnchor.constraint(equalToConstant: 500),
                  imageView.topAnchor.constraint(equalTo:
                      view.safeAreaLayoutGuide.topAnchor, constant: -30)
              ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.layer.cornerRadius = 20
        imageView.translatesAutoresizingMaskIntoConstraints = true
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
