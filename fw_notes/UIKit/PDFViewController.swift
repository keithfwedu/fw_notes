import PDFKit
import UIKit

class PDFViewController: UIViewController, UIPageViewControllerDelegate {

    let pdfView: PDFView = PDFView()
    var scrollView: UIScrollView?
    var zoomView: UIScrollView?
    var pdfVC: UIPageViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        //view.backgroundColor = .lightGray

        guard
            let url = Bundle.main.url(
                forResource: "sample",
                withExtension: "pdf"
            )
        else {
            print("Error: PDF file not found.")
            return
        }

        pdfView.document = PDFDocument(url: url)
        pdfView.displayDirection = .horizontal
        pdfView.displayMode = .singlePage
        pdfView.autoScales = true

        pdfView.usePageViewController(true)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(pdfView)
        NSLayoutConstraint.activate([
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor
            ),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        initPage()

    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        if completed {
            pdfPageDidChange(pageViewController)
        }

    }

    func initPage() {

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            print("Page changed, updating overlay!")

            if let contentView = self.pdfView.subviews.first(where: {
                String(describing: type(of: $0))
                    == "_UIPageViewControllerContentView"
            }) {
                if let contentView2 = contentView.subviews.first(where: {
                    String(describing: type(of: $0)) == "_UIQueuingScrollView"
                }) {
                    if let parentViewController = self.findViewController(
                        for: contentView2
                    ) {
                        parentViewController.delegate = self
                       
                        pdfPageDidChange(parentViewController)

                    }
                }
            }
        }
    }

    @objc func pdfPageDidChange(_ parentViewController: UIPageViewController) {
        parentViewController.delegate = self
        let allContentViews = parentViewController.view.subviews.first!.subviews
            .filter {
                String(describing: type(of: $0)) == "UIView"
            }
        for view in allContentViews {
            if view.subviews.count > 0 {
                let allContentViews2 = view.subviews.filter {
                    String(describing: type(of: $0)) == "UIView"
                }

                for view2 in allContentViews2 {

                    if let view3 = view2.subviews.first(where: {
                        $0 is UIScrollView
                    }) {
                        scrollView =
                            parentViewController.view.subviews.first
                            as? UIScrollView
                        self.zoomView = view3 as? UIScrollView
                       
                        scrollView!.delaysContentTouches = false
                        zoomView!.delaysContentTouches = false
                        zoomView!.canCancelContentTouches = true

                        zoomView?.bounces = false

                        scrollView?.panGestureRecognizer
                            .minimumNumberOfTouches = 3
                        scrollView?.panGestureRecognizer
                            .maximumNumberOfTouches = 3

                        zoomView?.panGestureRecognizer
                            .minimumNumberOfTouches = 2
                        zoomView?.panGestureRecognizer
                            .maximumNumberOfTouches = 2

                        if let gestures = pdfView.gestureRecognizers {
                            for gesture in gestures {
                                if let tapGesture = gesture
                                    as? UITapGestureRecognizer,
                                    tapGesture.numberOfTapsRequired == 2
                                {
                                    pdfView.removeGestureRecognizer(tapGesture)
                                    print("Removed double-tap gesture")
                                }
                            }
                        }
                        let pageView = zoomView!.subviews.first!.subviews.first
                        let subview = CanvasView(frame: pageView!.frame)
                        subview.bounds = pageView!.bounds
                        subview.isUserInteractionEnabled = true
                       
                        
                        self.zoomView!.subviews.first?.addSubview(subview)


                    }
                }
            }
        }

    }

    @objc func handleCustomPinch(_ sender: UIPinchGestureRecognizer) {
        // print("Custom pinch scale: \(sender.scale)")
    }

    @objc func handleCustomPan(_ sender: UIPanGestureRecognizer) {
        guard let scrollView = sender.view as? UIScrollView else { return }

        if scrollView.contentOffset.x <= 0 {
            print("Reached left edge")
        } else if scrollView.contentOffset.x >= scrollView.contentSize.width
            - scrollView.frame.width
        {
            print("Reached right edge")
        }
    }

    func findViewController(for view: UIView) -> UIPageViewController? {
        var responder: UIResponder? = view
        while responder != nil {
            responder = responder?.next
            if let viewController = responder as? UIPageViewController {
                return viewController
            }
        }
        return nil
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true // Allow multiple gestures to be recognized at the same time
        }

}
