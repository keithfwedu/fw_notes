//
//  DebugPanel.swift
//  test_draw
//
//  Created by Fung Wing on 20/5/2025.
//

import UIKit

class DebugPanel: UIView {
    
    private var debugLabel: UILabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDebugPanel()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDebugPanel()
    }
    
    func setupDebugPanel() {
        let padding: CGFloat = 10
        let labelWidth: CGFloat = 250
        let labelHeight: CGFloat = 60

        debugLabel.numberOfLines = 0
        debugLabel.textColor = .white
        debugLabel.textAlignment = .left
        debugLabel.font = UIFont.systemFont(ofSize: 14)
        debugLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        debugLabel.layer.cornerRadius = 8
        debugLabel.layer.masksToBounds = true
        debugLabel.frame = CGRect(
            x: bounds.width - labelWidth - padding,  // Aligns right with padding
            y: padding,  // Top padding
            width: labelWidth,
            height: labelHeight
        )
        self.addSubview(debugLabel)
    }

    func updateDebugInfo(from layers: [PathLayer]) {
        let totalSegments = layers.reduce(0) { total, layer in
            guard let cgPath = layer.path else { return total }  // Skip if nil
            return total + countCGPathElements(path: cgPath)
        }
        debugLabel.text =
            "Sublayers: \(layers.count) (\(totalSegments))"
    }

    func countCGPathElements(path: CGPath) -> Int {
        var count = 0
        path.applyWithBlock { _ in
            count += 1
        }
        return count
    }

}
