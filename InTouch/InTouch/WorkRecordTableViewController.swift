//
//  WorkRecordTableViewController.swift
//  InTouch
//
//  Created by Johnson Tran on 5/23/20.
//  Copyright © 2020 Johnson Tran. All rights reserved.
//

import Foundation
import UserNotifications
import SwiftUI

class WorkRecordTableViewController: UITableViewController {
    
    var workRecord: [Double]!
    var startDate: Date!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        tableView.reloadData()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workRecord!.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    // displays the habit cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "trackRecordCell", for: indexPath) as! TrackRecordCell
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        cell.dateLabel.text = formatter.string(from: startDate.addingTimeInterval(TimeInterval(86400 * (workRecord.count - 1 - indexPath.row))))
        cell.dateLabel.sizeToFit()
        cell.progressLabel.text = displayTime(timeInSecs: workRecord[workRecord.count - 1 - indexPath.row])
        cell.progressLabel.sizeToFit()
        cell.selectionStyle = .none
        return cell
    }
    
    // display the time based on the counter
    func displayTime(timeInSecs: Double) -> String {
        // HH:MM:SS
        var timeString = ""
        let flooredCounter = Int(timeInSecs)
        let hour = flooredCounter / 3600
        let minute = (flooredCounter % 3600) / 60
        var minuteString = "\(minute)"
        if minute < 10 {
            minuteString = "0\(minute)"
        }
        let second = (flooredCounter % 3600) % 60
        var secondString = "\(second)"
        if second < 10 {
            secondString = "0\(second)"
        }
        
        if hour > 0 {
            timeString = "\(hour):\(minuteString):\(secondString)"
        } else {
            timeString = "\(minuteString):\(secondString)"
        }
        return timeString
    }

}
