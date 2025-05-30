//
//  HistoryManager.swift
//  test_draw
//
//  Created by Fung Wing on 26/5/2025.
//
import UIKit

class HistoryManager {
    private var stepOfUndo: Int = 50
    private var histories: [LayerHistory] = []
    private var redoHistories: [LayerHistory] = []

    func addInsertHistory(pageId: UUID, tag: ActionTag, layers: [CALayer] = [])
    {
        let clonedNewLayers: [CALayer] = layers.map { layer in
            if let pathLayer = layer as? PathLayer {
                return pathLayer.clone() as! PathLayer
            } else if let imageLayer = layer as? ImageLayer {
                return imageLayer.clone() as! ImageLayer
            } else {
                return layer  // If unsupported type, return original
            }
        }

        let clonedOldLayers: [CALayer] = layers.map { layer in
            if let pathLayer = layer as? PathLayer {
                let cloned = pathLayer.clone() as! PathLayer
                cloned.deleted = true
                return cloned
            } else if let imageLayer = layer as? ImageLayer {
                let cloned = imageLayer.clone() as! ImageLayer
                cloned.deleted = true
                return cloned
            } else {
                return layer
            }
        }


        setHistory(
            pageId: pageId,
            action: HistoryAction.insert,
            tag: tag,
            oldLayers: clonedOldLayers,
            newLayers: clonedNewLayers
        )
    }

    func addDeleteHistory(pageId: UUID, tag: ActionTag, layers: [CALayer] = [])
    {
        let clonedOldLayers: [CALayer] = layers.map { layer in
            if let pathLayer = layer as? PathLayer {
                return pathLayer.clone() as! PathLayer
            } else if let imageLayer = layer as? ImageLayer {
                print("ImageLayer")
                return imageLayer.clone() as! ImageLayer
            } else {
                return layer  // If unsupported type, return original
            }
        }

        
        let  clonedNewLayers: [CALayer] = layers.map { layer in
            if let pathLayer = layer as? PathLayer {
                let cloned = pathLayer.clone() as! PathLayer
                cloned.deleted = true
                return cloned
            } else if let imageLayer = layer as? ImageLayer {
                let cloned = imageLayer.clone() as! ImageLayer
                cloned.deleted = true
                return cloned
            } else {
                return layer
            }
        }

        setHistory(
            pageId: pageId,
            action: HistoryAction.delete,
            tag: tag,
            oldLayers: clonedOldLayers,
            newLayers: clonedNewLayers
        )
    }

    func addUpdateHistory(
        pageId: UUID,
        tag: ActionTag,
        oldLayers: [CALayer] = [],
        newLayers: [CALayer] = []
    ) {
        let clonedOldLayers: [CALayer] = oldLayers.map { layer in
            if let pathLayer = layer as? PathLayer {
                return pathLayer.clone() as! PathLayer
            } else if let imageLayer = layer as? ImageLayer {
               
                return imageLayer.clone() as! ImageLayer
            } else {
                return layer  // If unsupported type, return original
            }
        }

        let clonedNewLayers: [CALayer] = newLayers.map { layer in
            if let pathLayer = layer as? PathLayer {
                return pathLayer.clone() as! PathLayer
            } else if let imageLayer = layer as? ImageLayer {
                return imageLayer.clone() as! ImageLayer
            } else {
                return layer
            }
        }

        setHistory(
            pageId: pageId,
            action: HistoryAction.delete,
            tag: tag,
            oldLayers: clonedOldLayers,
            newLayers: clonedNewLayers
        )
    }

    private func setHistory(
        pageId: UUID,
        action: HistoryAction,
        tag: ActionTag,
        oldLayers: [CALayer] = [],
        newLayers: [CALayer] = []
    ) {
        oldLayers.forEach({ print("deleted2: \($0.deleted)")})
        let history = LayerHistory(
            pageId: pageId,
            action: action,
            tag: tag,
            oldLayers: oldLayers,
            newLayers: newLayers
        )
        histories.append(history)

        // Maintain the limit on undo steps
        if histories.count > stepOfUndo {
            histories.removeFirst()
        }

    }

    func getUndoHistory() -> LayerHistory? {
        guard let latestAction = histories.popLast() else {
            print("No more undo history")
            return nil
        }

        // Move the undone action to redo history
        redoHistories.append(latestAction)

        return latestAction
    }

    func getRedoHistory() -> LayerHistory? {
        print(redoHistories)
        guard let latestAction = redoHistories.popLast() else {
            print("No more redo history")
            return nil
        }

        histories.append(latestAction)

        return latestAction
    }

}
