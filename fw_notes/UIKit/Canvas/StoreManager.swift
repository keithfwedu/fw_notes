//
//  StoreManager.swift
//  test_draw
//
//  Created by Fung Wing on 26/5/2025.
//

import UIKit

class StoreManager {
    func saveLayers(with layers: [CALayer], to fileURL: URL) {
        autoreleasepool {
            var wrappedLayers = layers.compactMap { StoreDataWrapper(layer: $0) }  // Ensure valid conversion

            do {
                let binaryData = try autoreleasepool {
                    return try NSKeyedArchiver.archivedData(
                        withRootObject: wrappedLayers,
                        requiringSecureCoding: false
                    )
                }
                wrappedLayers.removeAll()
                try binaryData.write(to: fileURL)
            } catch {
                print("Failed to save layers: \(error)")
            }
        }
    }

    func loadLayers(from fileURL: URL) -> [CALayer] {
        do {
            let binaryData = try Data(contentsOf: fileURL)
            guard
                let decodedLayers = try NSKeyedUnarchiver.unarchivedObject(
                    ofClasses: [
                        NSArray.self, StoreDataWrapper.self, PathInfo.self,
                        ImageInfo.self,
                    ],
                    from: binaryData
                ) as? [StoreDataWrapper]
            else {
                print("Failed to decode binary data")
                return []
            }
            print(decodedLayers)
            return decodedLayers.compactMap { $0.buildLayer() }  // Ensure valid layers are returned
        } catch {
            print("Failed to load layers: \(error)")
            return []
        }
    }
}
