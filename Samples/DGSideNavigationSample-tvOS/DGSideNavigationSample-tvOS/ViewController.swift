//
//  ViewController.swift
//  DGSideNavigationSample-tvOS
//
//  Created by Benoit BRIATTE on 23/12/2016.
//  Copyright © 2016 Digipolitan. All rights reserved.
//

import UIKit
import DGSideNavigation

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func displayLeft(_ sender: UIButton) {
        self.sideNavigationController?.showLeftSide()
    }

    @IBAction func displayRight(_ sender: UIButton) {
        self.sideNavigationController?.showRightSide()
    }
}
