//
//  GifWrapper.swift
//  test_note
//
//  Created by Fung Wing on 28/4/2025.
//
import UIKit

class GifWrapper {
    var gifLayer: CALayer
    var source: CGImageSource
    var delays: [Double]
    var cachedFrames: [CGImage] = []
    var frameCount: Int
    
    // **New property**
    var totalDuration: Double

    init(gifLayer: CALayer, source: CGImageSource, frameCount: Int, delays: [Double]) {
        self.gifLayer = gifLayer
        self.source = source
        self.frameCount = frameCount
        self.delays = delays
        self.totalDuration = delays.reduce(0, +) // Computes total animation duration
    }

 
}
