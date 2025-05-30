//
//  AnnotationView.swift
//  note3
//
//  Created by Fung Wing on 25/4/2025.
//

import PDFKit
import UIKit

class AnnotationView: UIView {
   

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
       
    }

    private func setupView() {
        // Configure border appearance
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.red.cgColor
       
        setupCanvasView()
    }

    private func setupCanvasView() {
        var canvasView = CanvasView(frame:  self.bounds)
               // Initialize the canvas view
        canvasView.bounds = self.bounds
    
       // canvasView.isUserInteractionEnabled = true
        self.addSubview(canvasView)
      
     

    }

    // Allow touches to pass through to underlying views if no interactive object is present
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        return hitView == self ? self.superview : hitView
    }

  
}
