//
//  LeftViewController.swift
//  DGSideNavigationSample-tvOS
//
//  Created by Benoit BRIATTE on 13/03/2017.
//  Copyright © 2017 Digipolitan. All rights reserved.
//

import UIKit
import DGSideNavigation

class LeftViewController: UIViewController {

    @IBAction func closeSide(_ sender: UIButton) {
        self.sideNavigationController?.closeSide()
    }

    @IBAction func consoleLog(_ sender: UIButton) {
        print("UI Event");
    }

}
