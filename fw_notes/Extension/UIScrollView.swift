//
//  UIScrollView.swift
//  test_note
//
//  Created by Fung Wing on 30/4/2025.
//
import UIKit
import PDFKit

extension UIScrollView: @retroactive UIGestureRecognizerDelegate {
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer:
            UIGestureRecognizer
    ) -> Bool {

      
        if (otherGestureRecognizer.view is PDFView) {
                return true
            }
        return otherGestureRecognizer is UIPinchGestureRecognizer
            || otherGestureRecognizer is UIPanGestureRecognizer
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return false
       
    }

}
