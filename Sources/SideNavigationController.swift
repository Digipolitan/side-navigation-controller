//
//  SideNavigationController.swift
//  DGSideNavigation
//
//  Created by Benoit BRIATTE on 24/02/2017.
//  Copyright © 2017 Digipolitan. All rights reserved.
//

import UIKit

open class SideNavigationController: UIViewController {

    private lazy var gestures: Gestures = {
        return Gestures(sideNavigationController: self)
    }()
    fileprivate lazy var overlay: UIView = {
        let overlay = UIView()
        overlay.isUserInteractionEnabled = false
        overlay.autoresizingMask = UIViewAutoresizing(rawValue: 0b111111)
        overlay.alpha = 0
        return overlay
    }()
    fileprivate lazy var mainContainer: UIView = {
        let mainContainer = UIView()
        mainContainer.autoresizingMask = UIViewAutoresizing(rawValue: 0b111111)
        return mainContainer
    }()

    fileprivate var sideProgress: CGFloat = 0
    fileprivate var revertSideDirection: Bool = false

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

    fileprivate var visibleSideViewController: UIViewController? {
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

    open override func viewDidLoad() {
        super.viewDidLoad()

        self.mainContainer.frame = self.view.bounds
        let mainBounds = self.mainContainer.bounds
        self.overlay.frame = mainBounds
        self.mainContainer.addSubview(self.overlay)
        if let mainViewController = self.mainViewController {
            mainViewController.view.frame = mainBounds
        }
        self.view.addSubview(self.mainContainer)

        self.overlay.addGestureRecognizer(self.gestures.mainPan)
        self.overlay.addGestureRecognizer(self.gestures.mainTap)

        self.view.addGestureRecognizer(self.gestures.leftScreenEdgePan)
        self.view.addGestureRecognizer(self.gestures.rightScreenEdgePan)

        self.mainGestures(enabled: false)
        self.sideGestures(enabled: true)
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
                self.close(direction: .left, animated: false)
            }
            self.unlink(viewController: left.viewController)
        }
        viewController.view.isHidden = true
        self.link(viewController: viewController, at: options.position == .back ? 0 : -1)
        self.left = Side(viewController: viewController, options: options)
        self.updateSide(with: .left, progress: 0)
        self.sideGestures(enabled: true)
    }

    public func rightSide(viewController: UIViewController, options: Options = Options()) {
        if let right = self.right {
            if right.viewController == self.visibleSideViewController {
                self.close(direction: .right, animated: false)
            }
            self.unlink(viewController: right.viewController)
        }
        viewController.view.isHidden = true
        self.link(viewController: viewController, at: options.position == .back ? 0 : -1)
        self.right = Side(viewController: viewController, options: options)
        self.updateSide(with: .right, progress: 0)
        self.sideGestures(enabled: true)
    }

    public func closeSide(animated: Bool = true) {
        guard let visibleSideViewController = self.visibleSideViewController else {
            return
        }
        if self.left?.viewController == visibleSideViewController {
            self.close(direction: .left, animated: animated)
        } else if self.right?.viewController == visibleSideViewController {
            self.close(direction: .right, animated: animated)
        }
    }

    private func close(direction: Direction, animated: Bool) {
        guard let side = direction == .left ? self.left : self.right else {
            // EXCEPTION
            return
        }
        UIView.animate(withDuration: animated ? side.options.animationDuration : 0, animations: {
            self.updateSide(with: direction, progress: 0)
        }) { _ in
            self.visibleSideViewController = nil
            self.mainGestures(enabled: false, direction: direction)
            self.sideGestures(enabled: true)
            self.revertSideDirection = false
        }
    }

    public func showLeftSide(animated: Bool = true) {
        self.show(direction: .left, animated: animated)
    }

    public func showRightSide(animated: Bool = true) {
        self.show(direction: .right, animated: animated)
    }

    fileprivate func updateSide(with direction: Direction, progress: CGFloat) {
        guard let side = direction == .left ? self.left : self.right else {
            // EXCEPTION
            return
        }
        self.sideProgress = progress
        if side.options.position == .back {
            self.updateBack(side: side, direction: direction, progress: progress)
        } else {
            self.updateFront(side: side, direction: direction, progress: progress)
        }
    }

    fileprivate func show(direction: Direction, animated: Bool) {
        self.view.endEditing(animated)
        guard let side = direction == .left ? self.left : self.right else {
            // EXCEPTION
            return
        }
        self.visibleSideViewController = side.viewController
        UIView.animate(withDuration: animated ? side.options.animationDuration : 0, animations: {
            self.updateSide(with: direction, progress: 1)
        }) { _ in
            self.mainGestures(enabled: true, direction: direction)
            self.sideGestures(enabled: false)
            self.revertSideDirection = true
        }
    }

    fileprivate func mainGestures(enabled: Bool, direction: Direction? = nil) {
        guard let side = direction == .left ? self.left : self.right else {
            return
        }
        self.overlay.isUserInteractionEnabled = enabled ? !side.options.alwaysInteractionEnabled : enabled
        self.gestures.mainPan.isEnabled = enabled ? side.options.panningEnabled : enabled
        self.gestures.mainTap.isEnabled = enabled
    }

    fileprivate func sideGestures(enabled: Bool) {
        self.gestures.leftScreenEdgePan.isEnabled = enabled ? self.left?.options.panningEnabled ?? false : enabled
        self.gestures.rightScreenEdgePan.isEnabled = enabled ? self.right?.options.panningEnabled ?? false : enabled
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

// NESTED TYPES

public extension SideNavigationController {

    fileprivate enum Direction {
        case left
        case right
    }

    public enum Position {
        case front
        case back
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

        public static var defaultTintColor = UIColor.white

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
                    overlayColor: UIColor = Options.defaultTintColor,
                    overlayOpacity: CGFloat = 0.5,
                    shadowColor: UIColor = Options.defaultTintColor,
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

    fileprivate class Gestures {

        public static let velocityTolerance: CGFloat = 600

        private weak var sideNavigationController: SideNavigationController?
        public var leftScreenEdgePan: UIScreenEdgePanGestureRecognizer!
        public var rightScreenEdgePan: UIScreenEdgePanGestureRecognizer!
        public var mainPan: UIPanGestureRecognizer!
        public var mainTap: UITapGestureRecognizer!

        init(sideNavigationController: SideNavigationController) {
            self.sideNavigationController = sideNavigationController
            let leftScreenEdgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handle(panGesture:)))
            leftScreenEdgePan.edges = .left
            leftScreenEdgePan.maximumNumberOfTouches = 1
            self.leftScreenEdgePan = leftScreenEdgePan

            let rightScreenEdgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handle(panGesture:)))
            rightScreenEdgePan.edges = .right
            rightScreenEdgePan.maximumNumberOfTouches = 1
            self.rightScreenEdgePan = rightScreenEdgePan

            self.mainPan = UIPanGestureRecognizer(target: self, action: #selector(handle(panGesture:)))

            self.mainTap = UITapGestureRecognizer(target: self, action: #selector(handle(tapGesture:)))

            self.mainTap.require(toFail: self.mainPan)

            self.leftScreenEdgePan.require(toFail: self.rightScreenEdgePan)
            self.rightScreenEdgePan.require(toFail: self.leftScreenEdgePan)
        }

        @objc
        private func handle(panGesture: UIPanGestureRecognizer) {
            guard let sideNavigationController = self.sideNavigationController else {
                return
            }
            if panGesture.state == .changed {
                let offset = panGesture.translation(in: sideNavigationController.view).x
                sideNavigationController.update(gesture: panGesture, offset: offset)
            } else if panGesture.state != .began {
                let velocity = panGesture.velocity(in: sideNavigationController.view)
                sideNavigationController.finish(gesture: panGesture, velocity: velocity.x)
            }
        }

        @objc
        private func handle(tapGesture: UITapGestureRecognizer) {
            guard let sideNavigationController = self.sideNavigationController else {
                return
            }
            sideNavigationController.finish(gesture: tapGesture, velocity: Gestures.velocityTolerance)
        }
    }
}

// DRAWING

fileprivate extension SideNavigationController {

    fileprivate func updateBack(side: Side, direction: Direction, progress: CGFloat) {
        self.overlay.alpha = side.options.overlayOpacity * progress
        self.overlay.backgroundColor = side.options.overlayColor
        self.mainContainer.layer.shadowColor = side.options.shadowCGColor
        self.mainContainer.layer.shadowOpacity = Float(side.options.shadowOpacity)
        self.mainContainer.layer.shadowRadius = 15
        if side.options.scale != 1 {
            let scale = 1 - (1 - side.options.scale) * progress
            self.mainContainer.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
        }
        var mainFrame = self.mainContainer.frame
        let viewBounds = self.view.bounds
        var sideFrame = side.viewController.view.frame
        sideFrame.size.width = viewBounds.width * side.options.widthPercent
        sideFrame.size.height = viewBounds.height
        let parallaxWidth = sideFrame.width / 3
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

    fileprivate func updateFront(side: Side, direction: Direction, progress: CGFloat) {
        self.overlay.alpha = side.options.overlayOpacity * progress
        self.overlay.backgroundColor = side.options.overlayColor
        self.mainContainer.layer.shadowColor = side.options.shadowCGColor
        self.mainContainer.layer.shadowOpacity = Float(side.options.shadowOpacity)
        self.mainContainer.layer.shadowRadius = 15
        if side.options.scale != 1 {
            let scale = 1 - (1 - side.options.scale) * progress
            self.mainContainer.transform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
        }
        let viewBounds = self.view.bounds
        var sideFrame = side.viewController.view.frame
        sideFrame.size.width = viewBounds.width * side.options.widthPercent
        sideFrame.size.height = viewBounds.height
        switch direction {
        case .left :
            sideFrame.origin.x = -sideFrame.width + sideFrame.width * progress
            break
        case .right :
            sideFrame.origin.x = (viewBounds.width - sideFrame.width) + sideFrame.width * (1.0 - progress)
            break
        }
        side.viewController.view.frame = sideFrame
    }
}

// GESTURES

fileprivate extension SideNavigationController {

    func update(gesture: UIGestureRecognizer, offset: CGFloat) {
        if let left = self.left {
            if self.visibleSideViewController == left.viewController || (offset > 0 && self.visibleSideViewController == nil) {
                self.visibleSideViewController = left.viewController
                let leftWidth = left.viewController.view.frame.width
                var progress = min(fabs(offset), leftWidth) / leftWidth
                if self.revertSideDirection {
                    guard offset <= 0 else {
                        return
                    }
                    progress = 1 - progress
                }
                self.updateSide(with: .left, progress: progress)
                return
            }
        }
        if let right = self.right {
            if self.visibleSideViewController == right.viewController || (offset < 0 && self.visibleSideViewController == nil) {
                self.visibleSideViewController = right.viewController
                let rightWidth = right.viewController.view.frame.width
                var progress = min(fabs(offset), rightWidth) / rightWidth
                if self.revertSideDirection {
                    guard offset >= 0 else {
                        return
                    }
                    progress = 1 - progress
                }
                self.updateSide(with: .right, progress: progress)
                return
            }
        }
        var mainFrame = self.mainContainer.frame
        mainFrame.origin.x = 0
        self.mainContainer.frame = mainFrame
    }

    func finish(gesture: UIGestureRecognizer, velocity: CGFloat) {
        if self.visibleSideViewController != nil {
            let swipe = fabs(velocity) >= Gestures.velocityTolerance
            var displaySide = false
            if self.revertSideDirection {
                if !(self.sideProgress < 0.5 || swipe) {
                    displaySide = true
                }
            } else if self.sideProgress > 0.5 || swipe {
                displaySide = true
            }
            if displaySide {
                if self.visibleSideViewController == self.left?.viewController {
                    self.show(direction: .left, animated: true)
                } else {
                    self.show(direction: .right, animated: true)
                }
                return
            }
        }
        self.closeSide()
    }
}
