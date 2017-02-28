//
//  SideNavigationController.swift
//  DGSideNavigation
//
//  Created by Benoit BRIATTE on 24/02/2017.
//  Copyright © 2017 Digipolitan. All rights reserved.
//

import UIKit

open class SideNavigationController: UIViewController {

    private enum Direction {
        case left
        case right
    }

    public enum Position {
        case front
        case back
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
                if (mainFrame.origin.x >= left.viewController.view.frame.width / 2 || velocity.x > 600) && self.visibleSideViewController == left.viewController {
                    self.show(side: left, to: .left, animated: true)
                    return
                }
            } else if let right = self.right, mainFrame.origin.x < 0 {
                if (-mainFrame.origin.x > right.viewController.view.frame.width / 2 || velocity.x < -600) && self.visibleSideViewController == right.viewController {
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

    private func apply(side: Side, progress: CGFloat) {
        self.overlay.alpha = side.options.overlayOpacity * progress
        self.overlay.backgroundColor = side.options.overlayColor
        self.mainContainer.layer.shadowColor = side.options.shadowCGColor
        self.mainContainer.layer.shadowOpacity = Float(side.options.shadowOpacity)
        if side.options.scale != 1 {
            let scale = 1 - (1 - side.options.scale) * progress
            self.mainContainer.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
        }
    }

    private func move(offset: CGFloat) {
        let bounds = self.view.bounds
        let minOffset = bounds.minX + offset
        if let left = self.left {
            if minOffset > 0 && (self.visibleSideViewController == nil || self.visibleSideViewController == left.viewController) {
                self.visibleSideViewController = left.viewController
                let leftWidth = left.viewController.view.frame.width
                let progress = min(minOffset, leftWidth) / leftWidth
                self.apply(side: left, progress: progress)
                self.move(side: left, with: .left, progress: progress)
                return
            }
        }
        if let right = self.right {
            let maxOffset = bounds.maxX + offset
            if maxOffset < bounds.width && (self.visibleSideViewController == nil || self.visibleSideViewController == right.viewController) {
                self.visibleSideViewController = right.viewController
                let rightWidth = right.viewController.view.frame.width
                let progress = min(fabs(minOffset), rightWidth) / rightWidth
                self.apply(side: right, progress: progress)
                self.move(side: right, with: .right, progress: progress)
                return
            }
        }
        var mainFrame = self.mainContainer.frame
        mainFrame.origin.x = 0
        self.mainContainer.frame = mainFrame
    }

    @objc
    private func handle(tapGesture: UITapGestureRecognizer) {
        self.closeSide()
    }

    private func enableMainGestures(side: Side) {
        self.overlay.isUserInteractionEnabled = !side.options.alwaysInteractionEnabled
        self.mainPan.isEnabled = side.options.panningEnabled
        self.mainTap.isEnabled = true
    }

    private func disableMainGestures() {
        self.overlay.isUserInteractionEnabled = false
        self.mainPan.isEnabled = false
        self.mainTap.isEnabled = false
    }

    private func enableSideGestures() {
        self.leftScreenEdgePan.isEnabled = self.left?.options.panningEnabled ?? false
        self.rightScreenEdgePan.isEnabled = self.right?.options.panningEnabled ?? false
    }

    private func disableSideGestures() {
        self.leftScreenEdgePan.isEnabled = false
        self.rightScreenEdgePan.isEnabled = false
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

        self.disableMainGestures()
        self.enableSideGestures()
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
        if let left = self.left {
            if left.viewController == self.visibleSideViewController {
                self.close(side: left, to: .left, animated: false)
            }
            self.unlink(viewController: left.viewController)
        }
        self.link(viewController: viewController, at: 0)
        let bounds = self.view.bounds
        let width = bounds.width * options.widthPercent
        viewController.view.frame = CGRect(x: -width / 3, y: 0, width: width, height: bounds.height)
        self.left = Side(viewController: viewController, options: options)
        self.enableSideGestures()
    }

    public func rightSide(viewController: UIViewController, options: Options = Options()) {
        if let right = self.right {
            if right.viewController == self.visibleSideViewController {
                self.close(side: right, to: .right, animated: false)
            }
            self.unlink(viewController: right.viewController)
        }
        self.link(viewController: viewController, at: 0)
        let bounds = self.view.bounds
        let width = bounds.width * options.widthPercent
        viewController.view.frame = CGRect(x: bounds.width - width / 1.5, y: 0, width: width, height: bounds.height)
        self.right = Side(viewController: viewController, options: options)
        self.enableSideGestures()
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

    private func close(side: Side, to direction: Direction, animated: Bool) {
        let width = self.view.bounds.width
        UIView.animate(withDuration: animated ? side.options.animationDuration : 0, animations: {
            self.apply(side: side, progress: 0)
            self.move(side: side, with: direction, progress: 0)
        }) { _ in
            self.visibleSideViewController = nil
            self.disableMainGestures()
            self.enableSideGestures()
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

    private func move(side: Side, with direction: Direction, progress: CGFloat) {
        var mainFrame = self.mainContainer.frame
        var sideFrame = side.viewController.view.frame
        let parallaxWidth = sideFrame.width / 3
        let viewBounds = self.view.bounds
        switch direction {
        case .left :
            mainFrame.origin.x = sideFrame.width * progress
            sideFrame.origin.x = parallaxWidth * progress - parallaxWidth
            break
        case .right :
            mainFrame.origin.x = -sideFrame.width * progress
            sideFrame.origin.x = (viewBounds.width - sideFrame.width) + parallaxWidth * (1.0 - progress)
            break
        }
        self.mainContainer.frame = mainFrame
        side.viewController.view.frame = sideFrame
    }

    private func show(side: Side, to direction: Direction, animated: Bool) {
        self.view.endEditing(animated)
        let width = self.view.bounds.width
        self.visibleSideViewController = side.viewController
        UIView.animate(withDuration: animated ? side.options.animationDuration : 0, animations: {
            self.apply(side: side, progress: 1)
            self.move(side: side, with: direction, progress: 1)
            /*
            var sideFrame = side.viewController.view.frame
            var mainFrame = self.mainContainer.frame

            switch direction {
            case .left:
                sideFrame.origin.x = 0
                mainFrame.origin.x = sideFrame.width
                break
            case .right:
                sideFrame.origin.x = width - sideFrame.width
                mainFrame.origin.x = -sideFrame.width
                break
            }

            side.viewController.view.frame = sideFrame
            self.mainContainer.frame = mainFrame
 */
        }) { _ in
            self.enableMainGestures(side: side)
            self.disableSideGestures()
        }
    }
}

public extension SideNavigationController {

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
        public var overlayColor: UIColor
        public var overlayOpacity: CGFloat
        public var shadowOpacity: CGFloat
        public var alwaysInteractionEnabled: Bool
        public var panningEnabled: Bool
        public var scale: CGFloat
        public var position: Position
        public var shadowColor: UIColor {
            get {
                return UIColor(cgColor: self.shadowCGColor)
            }
            set(newValue) {
                self.shadowCGColor = newValue.cgColor
            }
        }
        fileprivate var shadowCGColor: CGColor!

        public init(widthPercent: CGFloat = 0.33,
                    animationDuration: TimeInterval = 0.3,
                    overlayColor: UIColor = .black,
                    overlayOpacity: CGFloat = 0.5,
                    shadowColor: UIColor = .black,
                    shadowOpacity: CGFloat = 0.5,
                    alwaysInteractionEnabled: Bool = false,
                    panningEnabled: Bool = true,
                    scale: CGFloat = 1,
                    position: Position = .back) {
            self.widthPercent = widthPercent
            self.animationDuration = animationDuration
            self.overlayColor = overlayColor
            self.overlayOpacity = overlayOpacity
            self.shadowOpacity = shadowOpacity
            self.alwaysInteractionEnabled = alwaysInteractionEnabled
            self.panningEnabled = panningEnabled
            self.scale = scale
            self.position = position
            self.shadowColor = shadowColor
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
