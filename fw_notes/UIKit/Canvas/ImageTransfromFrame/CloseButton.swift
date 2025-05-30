//
//  CloseButton.swift
//  test_draw
//
//  Created by Fung Wing on 23/5/2025.
//

import UIKit

class CloseButton: UIButton {
    init() {
        super.init(frame: .zero)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        self.backgroundColor = .red
        self.layer.cornerRadius = 20  // Ensures rounded button
        self.translatesAutoresizingMaskIntoConstraints = false

        // Add close icon
        let closeIcon = UIImageView(image: UIImage(systemName: "xmark"))
        closeIcon.tintColor = .white
        closeIcon.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(closeIcon)

        // Define constraints
        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalToConstant: 40),
            self.heightAnchor.constraint(equalToConstant: 40),

            closeIcon.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.75),
            closeIcon.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.75),
            closeIcon.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            closeIcon.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ])
    }
}
