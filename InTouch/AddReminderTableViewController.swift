//
//  AddReminderTableViewController.swift
//  InTouch
//
//  Created by Johnson Tran on 3/8/20.
//  Copyright © 2020 Johnson Tran. All rights reserved.
//

import UIKit
import UserNotifications
import SwiftUI
import CoreData

class TitleAndNameCell: UITableViewCell {
    
    @IBOutlet weak var reminderName: UITextField!
    
}

class FrequencyCell: UITableViewCell {
    
    @IBOutlet weak var frequency: UITextField!
    
}

class OneTimeCell: UITableViewCell {
    
    @IBOutlet weak var dateField: UITextField!
    
}

class WhileWorkingCell: UITableViewCell {
    
    @IBOutlet weak var everyTimeField: UITextField!
    
}

class DailyCell: UITableViewCell {
    
    @IBOutlet weak var timeField: UITextField!
    
}

class AddReminderTableViewController: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
    
    var reminder: Reminder!
    
    var reminderTextField: UITextField!
    var titleAndNameCell: TitleAndNameCell!
    
    var freqCell: FrequencyCell!
    var freqField: UITextField!
    var freqPicker: UIPickerView?
    var freqChoices = ["One Time", "While Working", "Daily", "Custom"]
    
    var datePicker: UIDatePicker?
    var oneTimeCell: OneTimeCell?
    var otDateField: UITextField?
    
    let locale = NSLocale.current
    
    var everyTimePicker: UIDatePicker?
    var whileWorkingCell: WhileWorkingCell?
    var everyTimeField: UITextField?
    
    var timePicker: UIDatePicker?
    var dailyCell: DailyCell?
    var timeField: UITextField?
    
    var cellStack: [String]? // keeps track of the cells in the tableView
    
    var choice: String?
    
    var editingReminder: Bool?
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.allowsSelection = false
        tableView.allowsSelectionDuringEditing = false
        navigationItem.title = "Add Reminder"
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(gestureRecognizer:)))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        freqPicker = UIPickerView()
        freqPicker?.dataSource = self
        freqPicker?.delegate = self
        
        datePicker = UIDatePicker()
        datePicker!.datePickerMode = .dateAndTime
        datePicker!.addTarget(self, action: #selector(dateChanged(datePicker:)), for: .valueChanged)
        
        everyTimePicker = UIDatePicker()
        everyTimePicker!.datePickerMode = .countDownTimer
        everyTimePicker!.addTarget(self, action: #selector(dateChanged(datePicker:)), for: .valueChanged)
        
        timePicker = UIDatePicker()
        timePicker!.datePickerMode = .time
        timePicker!.addTarget(self, action: #selector(dateChanged(datePicker:)), for: .valueChanged)
        
        cellStack = ["titleAndName", "frequency"]
        
        saveButton.isEnabled = false
        
        editingReminder = false
        
        // set up the tableview with the reminder the user is trying to edit
        if reminder != nil {
            cellStack?.append(reminder.type!)
            editingReminder = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // helps dismiss the pickerView and update the cells of the table
    // inidicates the user made their frequency choice
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
        // since the field always updates with the selection, this will not error when trying to insert a row when there is no 3rd element in cellStack
        if !(freqField.text!.isEmpty) {
            if cellStack?.count == 2 {
                choice = freqField.text
                cellStack!.append(choice!)
                let insertIndex = IndexPath(row: 2, section: 0)
                tableView.insertRows(at: [insertIndex], with: .automatic)
                tableView.reloadData()
            } else {
                let prevChoice = choice
                choice = freqField.text
                // only change the cell when there is a change
                if prevChoice != choice {
                    // delete the existing one and update the cell
                    cellStack?.remove(at: 2)
                    cellStack!.append(choice!)
                    let insertIndex = IndexPath(row: 2, section: 0)
                    tableView.reloadRows(at: [insertIndex], with: .automatic)
                    tableView.reloadData()
                }
            }
            reminder?.type = freqField.text
        }
    }
    
    // format the date input for the given frequency choice
    @objc func dateChanged(datePicker: UIDatePicker) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = locale
        if datePicker == self.datePicker {
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            otDateField?.text = dateFormatter.string(from: datePicker.date)
            reminder?.time = datePicker.date
        } else if datePicker == self.timePicker {
            dateFormatter.timeStyle = .short
            timeField?.text = dateFormatter.string(from: datePicker.date)
            reminder?.time = timePicker!.date
        } else if datePicker == self.everyTimePicker {
            let duration = datePicker.countDownDuration
            let hour: Int = Int(duration) / 3600
            let min: Int = (Int(duration) % 3600) / 60
            
            if hour == 0 {
                everyTimeField?.text = "\(min) min"
            } else {
                everyTimeField?.text = "\(hour) hr \(min) min"
            }
        }
    }
    
    //MARK: - UITextField methods
    func checkName() {
        // disable save button if text field is empty
        if cellStack!.count < 3 {
            saveButton.isEnabled = false
        } else {
            let name = reminderTextField!.text ?? ""
            let freq = freqField!.text ?? ""
            if !name.isEmpty && !freq.isEmpty {
                reminder?.name = name
                let last = cellStack!.last
                if last == "One Time" {
                    let dateChoice = otDateField!.text ?? ""
                    if !dateChoice.isEmpty {
                        saveButton.isEnabled = true
                    }
                } else if last == "Daily" {
                    let dateChoice = timeField!.text ?? ""
                    if !dateChoice.isEmpty {
                        saveButton.isEnabled = true
                    }
                } else if last == "While" {
                    let dateChoice = everyTimeField!.text ?? ""
                    if !dateChoice.isEmpty {
                        saveButton.isEnabled = true
                    }
                }
            }
        }
    }
    
    func checkDate() {
        // disable save button if date in text field has passed
        if cellStack!.last == "One Time" && NSDate().earlierDate(datePicker!.date) == datePicker!.date {
            saveButton.isEnabled = false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        checkName()
        checkDate()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        saveButton.isEnabled = false
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let sender = sender as? UIBarButtonItem, sender === saveButton {
            // update preexisting reminder
            var oldIdent = String()
            if reminder != nil {
                oldIdent = reminder.identifier!
                // remove the reminder from the reminder queue
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.identifier!])
                PersistenceService.context.delete(reminder)
                PersistenceService.saveContext()
            }
            reminder = Reminder(context: PersistenceService.context)
            PersistenceService.saveContext()
            
            
            // set time and date components based on one time and daily
            // if while working, just pass it and keep an array of while working
            // maybe send while working to firstviewcontroller
            let name = reminderTextField!.text
            reminder!.name = name
            if cellStack?.last == "One Time" {
                var time = datePicker!.date
                reminder!.time = time
                reminder!.type = "One Time"
                
                let timeInterval = floor(time.timeIntervalSinceReferenceDate/60) * 60
                time = NSDate(timeIntervalSinceReferenceDate: timeInterval) as Date
                // build notification
                let content = UNMutableNotificationContent()
                content.title = "Reminder"
                content.body = "Don't forget to \(name!)"
                
                let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: time)
                
                // set the trigger
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                
                // indentifer for request
                var uuidString = String()
                //if !editingReminder! {
                uuidString = UUID().uuidString
                reminder?.identifier = uuidString
                //} else {
                //    reminder.identifier = oldIdent
                //}
                PersistenceService.saveContext()
                let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
                
                let center = UNUserNotificationCenter.current()
                center.add(request) { (error) in
                    // check error
                    if error != nil {
                        // handle
                    }
                }
                
            } else if cellStack?.last == "Daily" {
                var time = timePicker!.date
                reminder!.time = time
                reminder!.type = "Daily"
                
                let timeInterval = floor(time.timeIntervalSinceReferenceDate/60) * 60
                time = NSDate(timeIntervalSinceReferenceDate: timeInterval) as Date
                // build notification
                let content = UNMutableNotificationContent()
                content.title = "Reminder"
                content.body = "Daily Reminder to \(name!)"
                
                var dateComponents = DateComponents()
                dateComponents.calendar = Calendar.current
                dateComponents.hour = dateComponents.calendar?.component(.hour, from: time)
                dateComponents.minute = dateComponents.calendar?.component(.minute, from: time)
                
                // set the trigger
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                
                // indentifer for request
                var uuidString = String()
                //if !editingReminder! {
                uuidString = UUID().uuidString
                reminder?.identifier = uuidString
                //} else {
                //    reminder.identifier = oldIdent
                //}
                PersistenceService.saveContext()
                let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
                
                let center = UNUserNotificationCenter.current()
                center.add(request) { (error) in
                    // check error
                    if error != nil {
                        // handle
                    }
                }
                
            } else if cellStack?.last == "While Working" {
                let timeInterval = everyTimePicker?.countDownDuration
                reminder!.timeInterval = timeInterval!
                reminder!.type = "While Working"
                
            }
            // }
            
        }
    }
    
    //MARK: - PickerView methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return freqChoices.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return freqChoices[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        freqField.text = freqChoices[row]
    }
    
    //MARK: - TableView Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellStack!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "titleAndName") as! TitleAndNameCell
            titleAndNameCell = cell
            reminderTextField = titleAndNameCell.reminderName
            reminderTextField.delegate = self
            if reminder != nil {
                reminderTextField.text = reminder!.name
            }
            return titleAndNameCell
        } else if indexPath.row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "frequency") as! FrequencyCell
            freqCell = cell
            freqField = freqCell.frequency
            freqField.inputView = freqPicker
            if reminder != nil {
                freqField.text = reminder.type!
            }
            return freqCell
        } else if indexPath.row == 2 {
            // added cell is based on frequency
            if cellStack!.count > 2 {
                if cellStack!.last! == "One Time" {
                    let cell = tableView.dequeueReusableCell(withIdentifier: cellStack!.last!, for: indexPath) as! OneTimeCell
                    oneTimeCell = cell
                    otDateField = oneTimeCell!.dateField
                    otDateField!.inputView = datePicker
                    otDateField!.delegate = self
                    if reminder != nil && reminder.type == "One Time" {
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = locale
                        dateFormatter.dateStyle = .medium
                        dateFormatter.timeStyle = .short
                        otDateField!.text = dateFormatter.string(from: reminder.time!)
                    }
                    return oneTimeCell!
                } else if cellStack!.last! == "While Working" {
                    let cell = tableView.dequeueReusableCell(withIdentifier: cellStack!.last!, for: indexPath) as! WhileWorkingCell
                    whileWorkingCell = cell
                    everyTimeField = whileWorkingCell!.everyTimeField
                    everyTimeField!.inputView = everyTimePicker
                    everyTimeField!.delegate = self
                    return whileWorkingCell!
                } else if cellStack!.last! == "Daily" {
                    let cell = tableView.dequeueReusableCell(withIdentifier: cellStack!.last!, for: indexPath) as! DailyCell
                    dailyCell = cell
                    timeField = dailyCell!.timeField
                    timeField!.inputView = timePicker
                    timeField!.delegate = self
                    if reminder != nil && reminder.type == "Daily" {
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = locale
                        dateFormatter.timeStyle = .short
                        timeField!.text = dateFormatter.string(from: reminder.time!)
                    }
                    return dailyCell!
                }
            }
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "blank")
        return cell!
        
    }
}

extension AddReminderTableViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        //        let p = touch.location(in: view)
        //        if (freqPicker?.frame.contains(p))! {
        //            return true
        //        }
        //        return true
        return (touch.view === self.view)
    }
}

