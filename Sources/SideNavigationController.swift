//
//  SideNavigationController.swift
//  DGSideNavigation
//
//  Created by Benoit BRIATTE on 24/02/2017.
//  Copyright © 2017 Digipolitan. All rights reserved.
//

import UIKit

open class SideNavigationController: UIViewController {

    private enum Position {
        case left
        case right
    }

    public struct Side {

        public let viewController: UIViewController
        public let options: Options

        fileprivate init(viewController: UIViewController, options: Options) {
            self.viewController = viewController
            self.options = options
        }
    }

    public struct Options {
        public var widthPercent: CGFloat
        public var animationDuration: TimeInterval
        public var hideStatusBar: Bool
        public var overlayColor: UIColor
        public var overlayAlpha: CGFloat

        public init(widthPercent: CGFloat = 0.33, animationDuration: TimeInterval = 0.3, hideStatusBar: Bool = false, overlayColor: UIColor = .black, overlayAlpha: CGFloat = 0.7) {
            self.widthPercent = widthPercent
            self.animationDuration = animationDuration
            self.hideStatusBar = hideStatusBar
            self.overlayColor = overlayColor
            self.overlayAlpha = overlayAlpha
        }
    }

    private var visibleSideViewController: UIViewController? {
        willSet(newValue) {
            if self.visibleSideViewController != newValue {
                self.visibleSideViewController?.view.isHidden = true
            }
        }
        didSet {
            if self.visibleSideViewController != oldValue {
                self.visibleSideViewController?.view.isHidden = false
                self.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    private lazy var overlay: UIView = {
        let overlay = UIView()
        overlay.isUserInteractionEnabled = false
        overlay.autoresizingMask = UIViewAutoresizing(rawValue: 0b111111)
        overlay.alpha = 0
        return overlay
    }()
    private lazy var leftScreenEdgePan: UIScreenEdgePanGestureRecognizer = {
        let leftScreenEdgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handle(panGesture:)))
        leftScreenEdgePan.edges = .left
        leftScreenEdgePan.maximumNumberOfTouches = 1
        return leftScreenEdgePan
    }()
    private lazy var rightScreenEdgePan: UIScreenEdgePanGestureRecognizer = {
        let rightScreenEdgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handle(panGesture:)))
        rightScreenEdgePan.edges = .right
        rightScreenEdgePan.maximumNumberOfTouches = 1
        return rightScreenEdgePan
    }()
    private lazy var mainPan: UIPanGestureRecognizer = {
        return UIPanGestureRecognizer(target: self, action: #selector(handle(panGesture:)))
    }()
    private lazy var mainTap: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(handle(tapGesture:)))
    }()
    private lazy var mainContainer: UIView = {
        let mainContainer = UIView()
        mainContainer.backgroundColor = .red
        mainContainer.autoresizingMask = UIViewAutoresizing(rawValue: 0b111111)
        return mainContainer
    }()

    public private(set) var left: Side?
    public private(set) var right: Side?

    public var mainViewController: UIViewController? {
        willSet(newValue) {
            self.unlink(viewController: self.mainViewController)
        }
        didSet {
            if let mainViewController = self.mainViewController {
                self.link(viewController: mainViewController, in: self.mainContainer, at: 0)
                if self.isViewLoaded {
                    mainViewController.view.frame = self.mainContainer.bounds
                }
            }
        }
    }

    @objc
    private func handle(panGesture: UIPanGestureRecognizer) {
        if panGesture.state == .changed {
            var offset = panGesture.translation(in: self.mainContainer).x
            offset += self.startOffset
            self.move(offset: offset)
        } else if panGesture.state != .began {
            let mainFrame = self.mainContainer.frame
            let velocity = panGesture.velocity(in: self.view)
            if let left = self.left, mainFrame.origin.x > 0 {
                if mainFrame.origin.x >= left.viewController.view.frame.width / 2 || velocity.x > 600 {
                    self.show(side: left, to: .left, animated: true)
                    return
                }
            } else if let right = self.right, mainFrame.origin.x < 0 {
                if -mainFrame.origin.x > right.viewController.view.frame.width / 2 || velocity.x < -600 {
                    self.show(side: right, to: .right, animated: true)
                    return
                }
            }
            self.closeSide()
        } else {
            self.startOffset = self.mainContainer.frame.minX
        }
    }

    private var startOffset: CGFloat = 0

    private func move(offset: CGFloat) {
        let bounds = self.view.bounds
        var mainFrame = self.mainContainer.frame
        let minOffset = bounds.minX + offset
        if let left = self.left {
            if minOffset > 0 {
                self.visibleSideViewController = left.viewController
                var leftFrame = left.viewController.view.frame
                mainFrame.origin.x = min(minOffset, leftFrame.width)
                let parallaxWidth = leftFrame.width / 3
                let ratio = mainFrame.minX / leftFrame.width
                leftFrame.origin.x = parallaxWidth * ratio - parallaxWidth
                left.viewController.view.frame = leftFrame
                self.mainContainer.frame = mainFrame
                overlay.alpha = left.options.overlayAlpha * ratio
                overlay.backgroundColor = left.options.overlayColor
                return
            }
        }
        if let right = self.right {
            let maxOffset = bounds.maxX + offset
            if maxOffset < bounds.width {
                self.visibleSideViewController = right.viewController
                var rightFrame = right.viewController.view.frame
                mainFrame.origin.x = max(minOffset, -rightFrame.width)
                let parallaxWidth = rightFrame.width / 3
                let ratio = fabs(mainFrame.minX / rightFrame.width)
                rightFrame.origin.x = (bounds.width - rightFrame.width) + parallaxWidth * (1.0 - ratio)
                right.viewController.view.frame = rightFrame
                self.mainContainer.frame = mainFrame
                overlay.alpha = right.options.overlayAlpha * ratio
                overlay.backgroundColor = right.options.overlayColor
                return
            }
        }
        self.visibleSideViewController = nil
        mainFrame.origin.x = 0
        self.mainContainer.frame = mainFrame
    }

    @objc
    private func handle(tapGesture: UITapGestureRecognizer) {
        self.closeSide()
    }

    private func enableMainGestures() {
        self.overlay.isUserInteractionEnabled = true
        self.mainPan.isEnabled = true
        self.mainTap.isEnabled = true
    }

    private func disableMainGesture() {
        self.overlay.isUserInteractionEnabled = false
        self.mainPan.isEnabled = false
        self.mainTap.isEnabled = false
    }

    public var visibleViewController: UIViewController? {
        if self.visibleSideViewController != nil {
            return self.visibleSideViewController
        }
        return self.mainViewController
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    public convenience init(mainViewController: UIViewController) {
        self.init()
        defer {
            self.mainViewController = mainViewController
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.mainContainer.frame = self.view.bounds
        self.overlay.frame = self.mainContainer.bounds
        self.mainContainer.addSubview(self.overlay)
        if let main = self.mainViewController {
            main.view.frame = self.mainContainer.bounds
        }
        self.view.addSubview(self.mainContainer)

        self.overlay.addGestureRecognizer(self.mainPan)
        self.overlay.addGestureRecognizer(self.mainTap)

        self.mainTap.require(toFail: self.mainPan)

        self.leftScreenEdgePan.require(toFail: self.rightScreenEdgePan)
        self.rightScreenEdgePan.require(toFail: self.leftScreenEdgePan)
        self.view.addGestureRecognizer(self.leftScreenEdgePan)
        self.view.addGestureRecognizer(self.rightScreenEdgePan)

        self.disableMainGesture()
    }

    private func link(viewController: UIViewController, in view: UIView? = nil, at position: Int = -1) {
        viewController.view.autoresizingMask = UIViewAutoresizing(rawValue: 0b111111)
        let container: UIView = view != nil ? view! : self.view
        if position < 0 {
            container.addSubview(viewController.view)
        } else {
            container.insertSubview(viewController.view, at: position)
        }
        self.addChildViewController(viewController)
    }

    private func unlink(viewController: UIViewController?) {
        if let viewController = viewController {
            viewController.view.removeFromSuperview()
            viewController.removeFromParentViewController()
        }
    }

    open override var childViewControllerForStatusBarStyle: UIViewController? {
        return self.visibleViewController
    }

    open override var childViewControllerForStatusBarHidden: UIViewController? {
        return self.visibleViewController
    }

    public func leftSide(viewController: UIViewController, options: Options = Options()) {
        self.unlink(viewController: self.left?.viewController)
        self.link(viewController: viewController, at: 0)
        let bounds = self.view.bounds
        let width = bounds.width * options.widthPercent
        viewController.view.frame = CGRect(x: -width / 3, y: 0, width: width, height: bounds.height)
        self.left = Side(viewController: viewController, options: options)
    }

    public func rightSide(viewController: UIViewController, options: Options = Options()) {
        self.unlink(viewController: self.right?.viewController)
        self.link(viewController: viewController, at: 0)
        let bounds = self.view.bounds
        let width = bounds.width * options.widthPercent
        viewController.view.frame = CGRect(x: bounds.width - width / 1.5, y: 0, width: width, height: bounds.height)
        self.right = Side(viewController: viewController, options: options)
    }

    public func closeSide(animated: Bool = true) {
        guard let visibleSideViewController = self.visibleSideViewController else {
            return
        }
        if self.left?.viewController == visibleSideViewController {
            self.close(side: self.left!, to: .left, animated: animated)
        } else if self.right?.viewController == visibleSideViewController {
            self.close(side: self.right!, to: .right, animated: animated)
        }
    }

    private func close(side: Side, to position: Position, animated: Bool) {
        let width = self.view.bounds.width
        UIView.animate(withDuration: animated ? side.options.animationDuration : 0, animations: {
            var frame = self.mainContainer.frame
            frame.origin.x = 0
            self.mainContainer.frame = frame
            frame = side.viewController.view.frame
            switch position {
            case .left:
                frame.origin.x = -frame.width / 3
                break
            case .right:
                frame.origin.x = width - frame.width / 1.5
                break
            }
            side.viewController.view.frame = frame
            self.overlay.alpha = 0
        }) { _ in
            self.visibleSideViewController = nil
            self.disableMainGesture()
        }
    }

    public func showLeftSide(animated: Bool = true) {
        guard let left = self.left else {
            return // EXCEPTION ?
        }
        self.show(side: left, to: .left, animated: animated)
    }

    public func showRightSide(animated: Bool = true) {
        guard let right = self.right else {
            return // EXCEPTION ?
        }
        self.show(side: right, to: .right, animated: animated)
    }

    private func show(side: Side, to position: Position, animated: Bool) {
        self.visibleSideViewController = side.viewController
        self.view.endEditing(animated)
        UIView.animate(withDuration: animated ? side.options.animationDuration : 0, animations: {
            var sideFrame = side.viewController.view.frame
            var mainFrame = self.mainContainer.frame

            switch position {
            case .left:
                sideFrame.origin.x = 0
                mainFrame.origin.x = sideFrame.width
                break
            case .right:
                sideFrame.origin.x = mainFrame.width - sideFrame.width
                mainFrame.origin.x = -sideFrame.width
                break
            }

            side.viewController.view.frame = sideFrame
            self.mainContainer.frame = mainFrame

            self.overlay.alpha = side.options.overlayAlpha
            self.overlay.backgroundColor = side.options.overlayColor
        }) { _ in
            self.enableMainGestures()
        }
    }
}

public extension UIViewController {

    public var sideNavigationController: SideNavigationController? {
        var current = self
        while let parent = current.parent {
            if let side = parent as? SideNavigationController {
                return side
            }
            current = parent
        }
        return nil
    }
}
