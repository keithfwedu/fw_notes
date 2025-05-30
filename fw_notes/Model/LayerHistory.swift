//
//  LayerHistory.swift
//  test_draw
//
//  Created by Fung Wing on 29/5/2025.
//

import UIKit

struct LayerHistory {
    var pageId: UUID
    var tag: ActionTag
    var action: HistoryAction
    var oldLayers: [CALayer] = []
    var newLayers: [CALayer] = []

    init(
        pageId: UUID,
        action: HistoryAction,
        tag: ActionTag = ActionTag.normal,
        oldLayers: [CALayer] = [],
        newLayers: [CALayer] = []
    ) {
        self.pageId = pageId
        self.action = action
        self.tag = tag
        self.oldLayers = oldLayers
        self.newLayers = newLayers
    }
}
