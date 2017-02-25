//
//  SideNavigationController.swift
//  DGSideNavigation
//
//  Created by Benoit BRIATTE on 24/02/2017.
//  Copyright © 2017 Digipolitan. All rights reserved.
//

import UIKit

open class SideNavigationController: UIViewController {

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
        public var animationDuration: Float
        public var hideStatusBar: Bool
        public var overlayColor: UIColor
        public var overlayAlpha: Float

        public init(widthPercent: CGFloat = 0.33, animationDuration: Float = 0.3, hideStatusBar: Bool = false, overlayColor: UIColor = .black, overlayAlpha: Float = 0.7) {
            self.widthPercent = widthPercent
            self.animationDuration = animationDuration
            self.hideStatusBar = hideStatusBar
            self.overlayColor = overlayColor
            self.overlayAlpha = overlayAlpha
        }
    }

    private var visibleSideViewController: UIViewController?

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
    private let mainPan: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handle(panGesture:)))
    private let mainTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handle(tapGesture:)))

    public private(set) var left: Side?
    public private(set) var right: Side?

    public var mainViewController: UIViewController? {
        willSet(newValue) {
            self.unlink(viewController: self.mainViewController)
        }
        didSet {
            if let mainViewController = self.mainViewController {
                self.link(viewController: mainViewController)
                mainViewController.view.frame = self.view.bounds
            }
        }
    }

    public func handle(panGesture: UIPanGestureRecognizer) {

    }

    public func handle(tapGesture: UITapGestureRecognizer) {

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

    private func link(viewController: UIViewController, index: Int = -1) {
        viewController.sideNavigationController = self
        viewController.view.autoresizingMask = UIViewAutoresizing(rawValue: 0b111111)
        if index >= 0 {
            self.view.insertSubview(viewController.view, at: index)
        } else {
            self.view.addSubview(viewController.view)
        }
        self.addChildViewController(viewController)
    }

    private func unlink(viewController: UIViewController?) {
        if let viewController = viewController {
            viewController.view.removeFromSuperview()
            viewController.sideNavigationController = nil
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
        self.link(viewController: viewController)
        let bounds = self.view.bounds
        //viewController.view.isHidden = true
        let width = bounds.width * options.widthPercent
        viewController.view.frame = CGRect(x: -width / 3, y: 0, width: width, height: bounds.height)
        self.left = Side(viewController: viewController, options: options)
    }

    public func rightSide(viewController: UIViewController, options: Options = Options()) {
        self.unlink(viewController: self.right?.viewController)
        self.link(viewController: viewController)
        let bounds = self.view.bounds
        //viewController.view.isHidden = true
        let width = bounds.width * options.widthPercent
        viewController.view.frame = CGRect(x: bounds.width - width / 1.5, y: 0, width: width, height: bounds.height)
        self.right = Side(viewController: viewController, options: options)
    }

}

public extension UIViewController {

    private struct AssociatedKeys {
        static var sideNavigationController = "dg_side_navigation_controller"
    }

    public fileprivate(set) var sideNavigationController: SideNavigationController? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.sideNavigationController) as? SideNavigationController
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.sideNavigationController, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
