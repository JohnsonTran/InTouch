//
//  TrackRecordTableViewController.swift
//  InTouch
//
//  Created by Johnson Tran on 5/21/20.
//  Copyright © 2020 Johnson Tran. All rights reserved.
//

import UIKit
import UserNotifications
import SwiftUI

class TrackRecordTableViewController: UITableViewController {
    
    var habit: Habit!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        if habit != nil {
//            print(habit!.startDate!, Date().description(with: Locale.current))
//        }
    
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
        return habit.recordTrack!.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    // displays the habit cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "trackRecordCell", for: indexPath) as! TrackRecordCell
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        cell.dateLabel.text = formatter.string(from: habit.startDate!.addingTimeInterval(TimeInterval(86400 * (habit.recordTrack!.count - 1 - indexPath.row))))
        cell.dateLabel.sizeToFit()
        cell.progressLabel.text = "\(String(habit.recordTrack![habit.recordTrack!.count - 1 - indexPath.row])) \(habit.units!)"
        cell.progressLabel.sizeToFit()
        cell.selectionStyle = .none
        return cell
    }

}
