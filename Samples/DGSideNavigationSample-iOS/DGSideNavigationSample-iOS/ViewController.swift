//
//  ViewController.swift
//  DGSideNavigationSample-iOS
//
//  Created by Benoit BRIATTE on 23/12/2016.
//  Copyright © 2016 Digipolitan. All rights reserved.
//

import UIKit
import DGSideNavigation

class ViewController: UIViewController {

    @IBAction func touchLeft(_ sender: UIButton) {
        self.sideNavigationController?.showLeftSide()
    }

    @IBAction func touchClose(_ sender: UIButton) {
        self.sideNavigationController?.closeSide()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
