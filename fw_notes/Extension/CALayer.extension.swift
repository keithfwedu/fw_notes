//
//  BaseLayer.swift
//  test_draw
//
//  Created by Fung Wing on 26/5/2025.
//
import UIKit
import ObjectiveC

extension CALayer {
    var deleted: Bool {
        get {
            return value(forKey: "deleted") as? Bool ?? false
        }
        set {
            setValue(newValue, forKey: "deleted")
        }
    }
}


