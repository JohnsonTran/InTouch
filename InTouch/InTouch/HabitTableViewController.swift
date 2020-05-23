//
//  HabitTableViewController.swift
//  InTouch
//
//  Created by Johnson Tran on 5/14/20.
//  Copyright © 2020 Johnson Tran. All rights reserved.
//

import UIKit
import UserNotifications
import SwiftUI
import CoreData

protocol HabitCellDelegate {
    func changeHabitAlert(_ cell: HabitCell, _ add: Bool)
}

class HabitCell: UITableViewCell {
    
    @IBOutlet weak var habitNameLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var subtractButton: UIButton!
    
    var delegate: HabitCellDelegate?
    @IBAction func buttonPressed(_ sender: UIButton) {
        if sender == addButton {
            delegate?.changeHabitAlert(self, true)
        } else if sender == subtractButton {
            delegate?.changeHabitAlert(self, false)
        }
    }
    
}

class HabitTableViewController: UITableViewController, HabitCellDelegate {
    
    var habits = [Habit]()
    var habitToView: Habit!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = true

        let fetchRequest: NSFetchRequest<Habit> = Habit.fetchRequest()
        do {
            fetchRequest.returnsObjectsAsFaults = false
            habits = try PersistenceService.context.fetch(fetchRequest)
                        
        } catch {
            print("error")
        }
        
        // check when the user last logged in and add new dates to the record track of each habit to represent the days
        if let lastTimeLogIn = UserDefaults.standard.object(forKey: "lastTimeLogIn") as? Date {
            let timeDiff = Date().interval(ofComponent: .day, fromDate: lastTimeLogIn)
            var day = 0
            while day < timeDiff {
                for habit in habits {
                    habit.recordTrack!.append(0)
                }
                day += 1
            }
            PersistenceService.saveContext()
        }
        
        UserDefaults.standard.set(Date(), forKey: "lastTimeLogIn")
        
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
        return habits.count
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 116
    }
    
    // displays the habit cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "habitCell", for: indexPath) as! HabitCell
        // Configure the cell...
        cell.delegate = self
        let habit = habits[indexPath.row]
        cell.habitNameLabel.text = habit.name
        cell.habitNameLabel.textAlignment = .center
        cell.habitNameLabel.sizeToFit()
        cell.progressLabel.text = "\(habit.recordTrack![habit.recordTrack!.count - 1]) / \(habit.goal) \(habit.units!)"
        cell.progressLabel.sizeToFit()
        cell.progressLabel.textAlignment = .center
        return cell
    }
    
    // sends an alert pop up that asks the user to input an amount to add/subtract to the habit for the day and updates the habit
    func changeHabitAlert(_ cell: HabitCell, _ add: Bool) {
        let alert = UIAlertController(title: "Change Habit", message: "How much do you want to add/subtract?", preferredStyle: UIAlertController.Style.alert)
        
        let cancel = UIAlertAction(title: "Cancel", style: .default) { (alertAction) in }
        alert.addAction(cancel)
        
        let save = UIAlertAction(title: "Save", style: .default) { (alertAction) in
            let textfield = alert.textFields![0] as UITextField
            if textfield.text != "" {
                if let input = Double(textfield.text!) {
                    let indexPath = self.tableView.indexPath(for: cell)
                    var habitTrack = self.habits[indexPath!.row].recordTrack!
                    if add {
                        habitTrack[habitTrack.count - 1] += input
                    } else {
                        habitTrack[habitTrack.count - 1] -= input
                    }
                    self.habits[indexPath!.row].recordTrack = habitTrack
                    PersistenceService.saveContext()
                    self.tableView.reloadData()
                }
            }
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = "Enter a value"
            textField.keyboardType = .decimalPad
        }
        
        alert.addAction(save)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let habitRemove = habits.remove(at: indexPath.row)
            
            PersistenceService.context.delete(habitRemove)
            PersistenceService.saveContext()
            
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()
        }
    }
    
    // allows the user to look at their track record for the habit
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        habitToView = habits[indexPath.row]
        self.performSegue(withIdentifier: "viewTrackRecordSegue", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    // view the track record
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewTrackRecordSegue" {
            let temp = segue.destination as! UITableViewController
            let viewController = temp as! TrackRecordTableViewController
            viewController.habit = habitToView
        }
    }
    
    // gets the habit that was created and display it in the habits list
    @IBAction func unwindToHabitList(sender: UIStoryboardSegue) {
        if let sourceView = sender.source as? AddHabitViewController, let habit = sourceView.habit {
            habits.append(habit)
            let newIndexPath = NSIndexPath(row: habits.count - 1, section: 0)
            tableView.insertRows(at: [(newIndexPath as IndexPath)], with: .bottom)
            tableView.reloadData()
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    

}

extension Date {
    // determines the amount of calendar days in between 2 dates
    func interval(ofComponent comp: Calendar.Component, fromDate date: Date) -> Int {
        let timeZoneOffset = TimeZone.current.secondsFromGMT()
        // get day differences accounting for time zones
        guard let beg = Calendar.current.ordinality(of: comp, in: .era, for: date.addingTimeInterval(TimeInterval(timeZoneOffset))) else { return 0 }
        guard let end = Calendar.current.ordinality(of: comp, in: .era, for: self.addingTimeInterval(TimeInterval(timeZoneOffset))) else { return 0 }
        return end - beg
    }
}

