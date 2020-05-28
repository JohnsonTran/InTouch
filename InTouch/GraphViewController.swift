//
//  GraphViewController.swift
//  InTouch
//
//  Created by Johnson Tran on 5/27/20.
//  Copyright © 2020 Johnson Tran. All rights reserved.
//

import UIKit
import Macaw

class GraphViewController: UIViewController {
    
    @IBOutlet private var chartView: MacawChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        chartView.contentMode = .scaleAspectFit
        MacawChartView.playAnimations()
    }
    
    @IBAction func showChartButtonTapped(_ sender: Any) {
        MacawChartView.playAnimations()
    }
    
}
