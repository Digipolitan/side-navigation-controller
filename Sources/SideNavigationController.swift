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
                #if os(iOS)
                self.setNeedsStatusBarAppearanceUpdate()
                #endif
            }
        }
    }

    fileprivate func side(direction: Direction) -> Side? {
        return direction == .left ? self.left : self.right
    }

    fileprivate func setSide(_ side: Side, direction: Direction) {
        if let old = self.side(direction: direction) {
            if old.viewController == self.visibleSideViewController {
                self.close(direction: direction, animated: false)
            }
            self.unlink(viewController: old.viewController)
        }
        side.viewController.view.isHidden = true
        self.link(viewController: side.viewController, at: side.options.position == .back ? 0 : -1)
        if direction == .left {
            self.left = side
        } else {
            self.right = side
        }
        self.updateSide(with: direction, progress: 0)
        #if os(iOS)
        self.sideGestures(enabled: true)
        #endif
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
        self.mainGestures(enabled: false)

        #if os(iOS)
        self.view.addGestureRecognizer(self.gestures.leftScreenEdgePan)
        self.view.addGestureRecognizer(self.gestures.rightScreenEdgePan)
        self.sideGestures(enabled: true)
        #endif
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

    #if os(iOS)

    open override var childViewControllerForStatusBarStyle: UIViewController? {
        return self.visibleViewController
    }

    open override var childViewControllerForStatusBarHidden: UIViewController? {
        return self.visibleViewController
    }

    #endif

    public func leftSide(viewController: UIViewController, options: Options = Options()) {
        self.setSide(Side(viewController: viewController, options: options), direction: .left)
    }

    public func rightSide(viewController: UIViewController, options: Options = Options()) {
        self.setSide(Side(viewController: viewController, options: options), direction: .right)
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
        guard let side = self.side(direction: direction) else {
            // EXCEPTION
            return
        }
        UIView.animate(withDuration: animated ? side.options.animationDuration : 0, animations: {
            self.visibleSideViewController = nil
            side.viewController.view.isHidden = false
            self.updateSide(with: direction, progress: 0)
        }) { _ in
            side.viewController.view.isHidden = true
            self.revertSideDirection = false
            self.mainGestures(enabled: false, direction: direction)
            #if os(iOS)
            self.sideGestures(enabled: true)
            #endif
        }
    }

    public func showLeftSide(animated: Bool = true) {
        self.show(direction: .left, animated: animated)
    }

    public func showRightSide(animated: Bool = true) {
        self.show(direction: .right, animated: animated)
    }

    fileprivate func updateSide(with direction: Direction, progress: CGFloat) {
        guard let side = self.side(direction: direction) else {
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
        guard let side = self.side(direction: direction)  else {
            // EXCEPTION
            return
        }
        UIView.animate(withDuration: animated ? side.options.animationDuration : 0, animations: {
            self.visibleSideViewController = side.viewController
            self.updateSide(with: direction, progress: 1)
        }) { _ in
            self.revertSideDirection = true
            self.mainGestures(enabled: true, direction: direction)
            #if os(iOS)
            self.sideGestures(enabled: false)
            #endif
        }
    }

    fileprivate func mainGestures(enabled: Bool, direction: Direction? = nil) {
        var overlayInteractionEnabled = enabled
        var panningEnabled = enabled
        if enabled && direction != nil {
            if let side = self.side(direction: direction!) {
                overlayInteractionEnabled = !side.options.alwaysInteractionEnabled
                panningEnabled = side.options.panningEnabled
            }
        }
        self.overlay.isUserInteractionEnabled = overlayInteractionEnabled
        self.gestures.mainPan.isEnabled = panningEnabled
        self.gestures.mainTap.isEnabled = enabled
    }

    #if os(iOS)
    fileprivate func sideGestures(enabled: Bool) {
        self.gestures.leftScreenEdgePan.isEnabled = enabled ? self.left?.options.panningEnabled ?? false : enabled
        self.gestures.rightScreenEdgePan.isEnabled = enabled ? self.right?.options.panningEnabled ?? false : enabled
    }
    #endif
}

// NESTED TYPES

public extension SideNavigationController {

    fileprivate enum Direction {
        case left
        case right
    }

    fileprivate class Gestures {

        public static let velocityTolerance: CGFloat = 600

        private weak var sideNavigationController: SideNavigationController?
        #if os(iOS)
        public var leftScreenEdgePan: UIScreenEdgePanGestureRecognizer!
        public var rightScreenEdgePan: UIScreenEdgePanGestureRecognizer!
        #endif
        public var mainPan: UIPanGestureRecognizer!
        public var mainTap: UITapGestureRecognizer!

        init(sideNavigationController: SideNavigationController) {
            self.sideNavigationController = sideNavigationController

            #if os(iOS)
            let leftScreenEdgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handle(panGesture:)))
            leftScreenEdgePan.edges = .left
            leftScreenEdgePan.maximumNumberOfTouches = 1
            self.leftScreenEdgePan = leftScreenEdgePan

            let rightScreenEdgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handle(panGesture:)))
            rightScreenEdgePan.edges = .right
            rightScreenEdgePan.maximumNumberOfTouches = 1
            self.rightScreenEdgePan = rightScreenEdgePan

            self.leftScreenEdgePan.require(toFail: self.rightScreenEdgePan)
            self.rightScreenEdgePan.require(toFail: self.leftScreenEdgePan)
            #endif

            self.mainPan = UIPanGestureRecognizer(target: self, action: #selector(handle(panGesture:)))

            self.mainTap = UITapGestureRecognizer(target: self, action: #selector(handle(tapGesture:)))

            self.mainTap.require(toFail: self.mainPan)
        }

        @objc
        private func handle(panGesture: UIPanGestureRecognizer) {
            guard let sideNavigationController = self.sideNavigationController else {
                return
            }
            if panGesture.state == .changed {
                let offset = panGesture.translation(in: sideNavigationController.view).x
                sideNavigationController.update(offset: offset)
            } else if panGesture.state != .began {
                let velocity = panGesture.velocity(in: sideNavigationController.view)
                let info = self.info(velocity: velocity.x)
                sideNavigationController.finish(direction: info.direction, swipe: info.swipe)
            }
        }

        @objc
        private func handle(tapGesture: UITapGestureRecognizer) {
            guard let sideNavigationController = self.sideNavigationController else {
                return
            }
            if sideNavigationController.visibleSideViewController == sideNavigationController.left?.viewController {
                sideNavigationController.finish(direction: .left, swipe: true)
            } else {
                sideNavigationController.finish(direction: .right, swipe: true)
            }
        }

        private func info(velocity: CGFloat) -> (direction: Direction, swipe: Bool) {
            if velocity >= 0 {
                if velocity > Gestures.velocityTolerance {
                    return (direction: .right, swipe: true)
                }
                return (direction: .right, swipe: false)
            }
            if -velocity > Gestures.velocityTolerance {
                return (direction: .left, swipe: true)
            }
            return (direction: .left, swipe: false)
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

    func update(offset: CGFloat) {
        if let left = self.left {
            if self.visibleSideViewController == left.viewController || (offset > 0 && self.visibleSideViewController == nil) {
                UIView.animate(withDuration: left.options.animationDuration, animations: {
                    self.visibleSideViewController = left.viewController
                })
                let leftWidth = left.viewController.view.frame.width
                var progress = min(fabs(offset), leftWidth) / leftWidth
                if self.revertSideDirection {
                    progress = 1 - (offset <= 0 ? progress : 0)
                } else if offset <= 0 {
                    progress = 0
                }
                self.updateSide(with: .left, progress: progress)
                return
            }
        }
        if let right = self.right {
            if self.visibleSideViewController == right.viewController || (offset < 0 && self.visibleSideViewController == nil) {
                UIView.animate(withDuration: right.options.animationDuration, animations: {
                    self.visibleSideViewController = right.viewController
                })
                let rightWidth = right.viewController.view.frame.width
                var progress = min(fabs(offset), rightWidth) / rightWidth
                if self.revertSideDirection {
                    progress = 1 - (offset >= 0 ? progress : 0)
                } else if offset >= 0 {
                    progress = 0
                }
                self.updateSide(with: .right, progress: progress)
                return
            }
        }
        var mainFrame = self.mainContainer.frame
        mainFrame.origin.x = 0
        self.mainContainer.frame = mainFrame
    }

    func finish(direction: Direction, swipe: Bool) {
        if self.visibleSideViewController != nil {
            if self.visibleSideViewController == self.left?.viewController {
                if !(swipe && direction == .left) {
                    if self.sideProgress > 0.5 || swipe {
                        self.show(direction: .left, animated: true)
                        return
                    }
                }
            } else if !(swipe && direction == .right) {
                if self.sideProgress > 0.5 || swipe {
                    self.show(direction: .right, animated: true)
                    return
                }
            }
        }
        self.closeSide()
    }
}
