//
//  ViewController.swift
//  SideNavigationControllerSample-iOS
//
//  Created by Benoit BRIATTE on 23/12/2016.
//  Copyright © 2019 Digipolitan. All rights reserved.
//

import UIKit
import SideNavigationController

class ViewController: UIViewController {

    @IBOutlet var otherSideViewConainer: UIView!
    private var otherSideNavigationController: SideNavigationController?

    @IBAction func touchLeft(_ sender: UIButton) {
        self.sideNavigationController?.showLeftSide()
    }

    @IBAction func touchRight(_ sender: UIButton) {
        self.sideNavigationController?.showRightSide()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let snv = SideNavigationController(mainViewController: ChildViewController())
        snv.leftSide(viewController: LeftViewController(), options: .init(widthPercent: 0.5,
                                                                           overlayColor: .gray,
                                                                           overlayOpacity: 0.5,
                                                                           shadowColor: .black,
                                                                           scale: 0.8,
                                                                           position: .front))
        snv.rightSide(viewController: RightViewController())

        snv.view.frame = self.otherSideViewConainer.bounds

        self.otherSideViewConainer.addSubview(snv.view)
        self.otherSideNavigationController = snv
    }
}
