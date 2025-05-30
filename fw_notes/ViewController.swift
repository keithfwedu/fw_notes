//
//  ViewController.swift
//  fw_notes
//
//  Created by Fung Wing on 30/5/2025.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .lightGray
        setupOpenPDFButton()
    }
    
    private func setupOpenPDFButton() {
        let button = UIButton(type: .system)
        button.setTitle("Open PDF Viewer", for: .normal)
        button.addTarget(self, action: #selector(openPDFViewer), for: .touchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 200),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func openPDFViewer() {
        let pdfViewController = PDFViewController()
        pdfViewController.modalPresentationStyle = .fullScreen
        present(pdfViewController, animated: true, completion: nil)
    }

}

