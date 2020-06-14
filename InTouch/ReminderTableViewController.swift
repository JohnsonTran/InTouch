//
//  ReminderTableViewController.swift
//  InTouch
//
//  Created by Johnson Tran on 3/3/20.
//  Copyright © 2020 Johnson Tran. All rights reserved.
//

import UIKit
import UserNotifications
import SwiftUI
import CoreData

class ReminderTableViewController: UITableViewController {

//    @FetchRequest(fetchRequest: Reminder.getAllReminders()) var reminders:FetchedResults<Reminder>
    @State private var newReminder = ""
    // 0th row = one-time
    // 1st row = while working
    // 2nd row = daily
    var reminders = [Reminder]()
    var reminderList = [[Reminder]]()
    let dateFormatter = DateFormatter()
    let locale = NSLocale.current
    let timeFormatter = DateFormatter()
    var editReminder: Reminder?
    var editObjID: NSManagedObjectID?
            
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.isUserInteractionEnabled = true

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
                
        dateFormatter.locale = locale
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        timeFormatter.locale = locale
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none
        
        reminderList = [
            [],
            [],
            []
        ]
        
        reminders = []
        
        let fetchRequest: NSFetchRequest<Reminder> = Reminder.fetchRequest()
        do {
            fetchRequest.returnsObjectsAsFaults = false
            let reminders = try PersistenceService.context.fetch(fetchRequest)
            self.reminders = reminders
            self.tableView.reloadData()
            // sort the reminders based on type
            for remind in self.reminders {
                if remind.type == "One Time" {
                    reminderList[0].append(remind)
                } else if remind.type == "Daily" {
                    reminderList[1].append(remind)
                } else {
                    // TODO: setup for other types that are not implemented yet
                    reminderList[2].append(remind)
                }
            }
            // sorts the reminders in temporal order
            for section in 0...2 {
                reminderList[section] = reminderList[section].sorted(by: { $0.time!.compare($1.time!) == .orderedAscending } )
            }
                        
        } catch {
            print("error")
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        tableView.reloadData()
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 && reminderList[0].capacity > 0 {
            return "One Time Reminders"
        } else if section == 1 && reminderList[1].capacity > 0 {
            return "Daily Reminders"
        } else {
            return ""
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return reminderList.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return reminderList[section].count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reminderCell", for: indexPath)
        // Configure the cell...
        //let reminder = reminders[indexPath.row]
        let reminder = reminderList[indexPath.section][indexPath.row]
        cell.textLabel?.text = reminder.name
        if reminder.type == "One Time" {
            cell.detailTextLabel?.text = "Due " + dateFormatter.string(from: reminder.time!)
        } else if reminder.type == "Daily" {
            cell.detailTextLabel?.text = "Every day at " + timeFormatter.string(from: reminder.time!)
        } else {
            // TODO: just temporary
            // so far: while working
            let duration = reminder.timeInterval
            let hour: Int = Int(duration) / 3600
            let min: Int = (Int(duration) % 3600) / 60
            var outputTime: String
            if hour == 0 {
                outputTime = "\(min) min"
            } else {
                outputTime = "\(hour) hr \(min) min"
            }
            cell.detailTextLabel?.text = "Every " + outputTime
        }
        return cell
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let remindRemove = reminderList[indexPath.section].remove(at: indexPath.row)
            let index = reminders.firstIndex(of: remindRemove)
            reminders.remove(at: index!)
            
            let center = UNUserNotificationCenter.current()
            if remindRemove.type != "While Working" && remindRemove.type != nil {
                center.removePendingNotificationRequests(withIdentifiers: [remindRemove.identifier!])
                PersistenceService.context.delete(remindRemove)
                PersistenceService.saveContext()
            }
            
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.reloadData()
        }
    }
    
    // allow the user to edit the existing reminders in the tableView
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        editReminder = reminderList[indexPath.section][indexPath.row]
        self.performSegue(withIdentifier: "addReminderSegue", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
        // get the ID of the reminder that is trying to be edited to remove it later and replace with a new one
        editObjID = editReminder!.objectID
        editReminder = nil
        
    }
    // MARK: - Navigation
    // edit the addReminderTableViewController with current info
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(editReminder != nil) {
            let temp = segue.destination.children[0] as! UITableViewController
            let viewController = temp as! AddReminderTableViewController
            viewController.reminder = editReminder
        }
    }
    
    // gets the reminder that was created and display it in the reminders list
    @IBAction func unwindToReminderList(sender: UIStoryboardSegue) {
        if let sourceView = sender.source as? AddReminderTableViewController, let reminder = sourceView.reminder {
            
            // add a new reminder
            var section: Int
            if reminder.type == "One Time" {
                section = 0
            } else if reminder.type == "Daily" {
                section = 1
            } else {
                // TODO: setup for other types that are not implemented yet
                // while working
                section = 2
            }
            for list in 0...(reminderList.count-1) {
                //var remindList = reminderList[list]
                reminderList[list] = reminderList[list].filter { $0.objectID != editObjID }
            }
            tableView.reloadData()
            reminderList[section].append(reminder)
            // don't sort for while working reminders
            if section != 2 {
                reminderList[section] = reminderList[section].sorted(by: { $0.time!.compare($1.time!) == .orderedAscending } )
            }
            
            let newIndexPath = NSIndexPath(row: reminderList[section].count - 1, section: section)
            reminders = reminders.filter { $0.objectID != editObjID }
            reminders.append(reminder)
            // puts the reminder in the list based on date
            if section != 2 {
                reminders = reminders.sorted(by: { $0.time!.compare($1.time!) == .orderedAscending } )
            }
            tableView.insertRows(at: [(newIndexPath as IndexPath)], with: .bottom)
            tableView.reloadData()
        }
    }

}
