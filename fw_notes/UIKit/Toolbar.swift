//
//  Toolbar.swift
//  test_draw
//
//  Created by Fung Wing on 20/5/2025.
//

import UIKit

protocol ToolBarDelegate: AnyObject {
    func toolDidChange(to mode: DrawMode)
    func saveDrawing()
    func loadDrawing()
    func clearDrawing()
    func addImage()
    func addGif()
    func clone()
    func undo()
    func redo()
}

class ToolBar: UIView {
    weak var delegate: ToolBarDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPanel()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPanel()
    }

    private func setupPanel() {
        let items = ["Pen", "Eraser", "Lasso", "Laser"]
        let modeSegmentedControl = UISegmentedControl(items: items)
        modeSegmentedControl.selectedSegmentIndex = 0
        modeSegmentedControl.addTarget(
            self,
            action: #selector(changeTool(_:)),
            for: .valueChanged
        )
        modeSegmentedControl.frame = CGRect(x: 10, y: 10, width: 500, height: 30)
        addSubview(modeSegmentedControl)

        let saveButton = createButton(title: "Save", action: #selector(saveDrawing))
        let loadButton = createButton(title: "Load", action: #selector(loadDrawing))
        let clearButton = createButton(title: "Clear", action: #selector(clearDrawing))
        let addImageButton = createButton(title: "Image", action: #selector(addImage)) // New button
        let addGifButton = createButton(title: "Gif", action: #selector(addGif)) // New button
        let cloneButton = createButton(title: "clone", action: #selector(clone)) // New button
        let undoButton = createButton(title: "undo", action: #selector(undo))
        let redoButton = createButton(title: "redo", action: #selector(redo))
       

        saveButton.frame.origin = CGPoint(x: 10, y: 50)
        loadButton.frame.origin = CGPoint(x: 80, y: 50)
        clearButton.frame.origin = CGPoint(x: 150, y: 50)
        addImageButton.frame.origin = CGPoint(x: 220, y: 50) // Positioned after Clear button
        addGifButton.frame.origin = CGPoint(x: 290, y: 50)
        cloneButton.frame.origin = CGPoint(x: 350, y: 50)
        undoButton.frame.origin = CGPoint(x: 400, y: 50)
        redoButton.frame.origin = CGPoint(x: 450, y: 50)
        addSubview(saveButton)
        addSubview(loadButton)
        addSubview(clearButton)
        addSubview(addImageButton)
        addSubview(addGifButton)
        addSubview(cloneButton)
        
        addSubview(undoButton)
        addSubview(redoButton)
        // Adjust frame to fit content dynamically
        adjustFrame()
    }


    private func adjustFrame() {
        let maxY = subviews.map { $0.frame.maxY }.max() ?? 0
        frame.origin = CGPoint(x: 50, y: 50)
        frame.size.height = maxY + 10  // Adding some padding
        frame.size.width = 500  // Fixed width or adjust accordingly
    }

    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
        return button
    }

    @objc private func changeTool(_ sender: UISegmentedControl) {
        guard let selectedMode = DrawMode(rawValue: sender.selectedSegmentIndex)
        else {
            print("Invalid mode selection")
            return
        }
        delegate?.toolDidChange(to: selectedMode)
    }

    @objc private func saveDrawing() {
        delegate?.saveDrawing()
    }

    @objc private func loadDrawing() {
        delegate?.loadDrawing()
    }

    @objc private func clearDrawing() {
        delegate?.clearDrawing()
    }
    
    @objc private func addImage() {
        delegate?.addImage()
    }
    
    @objc private func addGif() {
        delegate?.addGif()
    }
    
    @objc private func clone() {
        delegate?.clone()
    }
    
    @objc private func undo() {
        delegate?.undo()
    }
    
    @objc private func redo() {
        delegate?.redo()
    }
}
