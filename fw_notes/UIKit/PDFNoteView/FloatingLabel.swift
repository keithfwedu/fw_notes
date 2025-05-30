//
//  ScaleLabel.swift
//  test_note
//
//  Created by Alex Ng on 26/4/2025.
//

import UIKit

class FloatingLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStyle()
    }

    private func setupStyle() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor.black.withAlphaComponent(0.6)
        textColor = .white
        textAlignment = .center
        font = UIFont.boldSystemFont(ofSize: 14)
        layer.cornerRadius = 8
        layer.masksToBounds = true
        layer.zPosition = 99999
    }
}
