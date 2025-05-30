//
//  RotationControlView.swift
//  test_draw
//
//  Created by Fung Wing on 23/5/2025.
//
import UIKit

class RotationControlView: UIView {
    private let rotateCircle = UIView()
    var color: UIColor = .blue

    init() {
        super.init(frame: .zero)
        setupViews()
    }
    
    override func layoutSubviews() {
        self.layer.cornerRadius = self.frame.size.width / 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        // Setup rotation circle
        self.backgroundColor = self.color

        // Add rotation icon inside the circle
        let rotateIcon = UIImageView(
            image: UIImage(systemName: "arrow.triangle.2.circlepath")
        )
        rotateIcon.tintColor = .white
        rotateIcon.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(rotateIcon)

        // Define constraints
        NSLayoutConstraint.activate([
            // Rotation Icon Inside Circle
            rotateIcon.widthAnchor.constraint(
                equalTo: self.widthAnchor,
                multiplier: 0.75
            ),
            rotateIcon.heightAnchor.constraint(
                equalTo: self.heightAnchor,
                multiplier: 0.75
            ),
            rotateIcon.centerXAnchor.constraint(
                equalTo: self.centerXAnchor
            ),
            rotateIcon.centerYAnchor.constraint(
                equalTo: self.centerYAnchor
            ),

        ])
    }

}
