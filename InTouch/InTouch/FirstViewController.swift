//
//  FirstViewController.swift
//  InTouch
//
//  Created by Johnson Tran on 1/26/20.
//  Copyright © 2020 Johnson Tran. All rights reserved.
//

import UIKit
import UserNotifications
import SwiftUI
import CoreData


class FirstViewController: UIViewController, UNUserNotificationCenterDelegate {
    
    @IBOutlet weak var resetButton: UIButton!
    
    @IBOutlet weak var startPauseButton: UIButton!
    
    @IBOutlet weak var time: UILabel!
    
    @IBOutlet weak var breakIntervalTextField: UITextField!
    let everyTimePicker = UIDatePicker()
    
    var timer = Timer()
    
    var isTimerRunning = false
    
    var counter = 0.0
    
    var diffHrs = 0
    var diffMins = 0
    var diffSecs = 0
    var diffNanosecs = 0
    
    var secBuffer = 0  // nanosecond buffer taken when the timer starts firing to make the notifications match the timer
    
    //var workingReminders: [Reminder] = []
    
    var whileWorkIdent: [String] = []
    
    let center = UNUserNotificationCenter.current()
    
    var latestDate: Date!
    var breakInterval: TimeInterval!
    
    var wasTerminated: Bool!  // keep track if the user terminated the app while the timer is running to fix the accuracy of the timer
    
    var workRecord: [Double]!
    var firstDateLogIn: Date!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(pauseWhenBackground(noti:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground(noti:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willTerminate(noti:)), name: UIApplication.willTerminateNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIApplication.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: UIApplication.keyboardWillChangeFrameNotification, object: nil)
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            
        }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(gestureRecognizer:)))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
        
        //center.removeAllPendingNotificationRequests()
        everyTimePicker.datePickerMode = .countDownTimer
        everyTimePicker.addTarget(self, action: #selector(dateChanged(datePicker:)), for: .valueChanged)
        breakIntervalTextField.inputView = everyTimePicker
        
        // add bottom line to break interval text field
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0.0, y: breakIntervalTextField.frame.height - 1, width: breakIntervalTextField.frame.width, height: 1.0)
        bottomLine.backgroundColor = UIColor.black.cgColor
        breakIntervalTextField.borderStyle = UITextField.BorderStyle.none
        breakIntervalTextField.layer.addSublayer(bottomLine)
        
        // display the break interval
        breakInterval = UserDefaults.standard.double(forKey: "breakInterval")
        if(breakInterval != 0) {
            let hour: Int = Int(breakInterval) / 3600
            let min: Int = (Int(breakInterval) % 3600) / 60
            breakIntervalTextField.text = "Every "
            if hour == 0 {
                breakIntervalTextField.text! += "\(min) min"
            } else {
                breakIntervalTextField.text! += "\(hour) hr \(min) min"
            }
            everyTimePicker.countDownDuration = breakInterval
        }
        
        registerForNotification()
        wasTerminated = false
        let isTimerStillRunning = UserDefaults.standard.bool(forKey: "isTimerRunning")
        if isTimerStillRunning {
            //let startDate = UserDefaults.standard.object(forKey: "startDate") as! Date
            counter = UserDefaults.standard.double(forKey: "counter")
            whileWorkIdent = UserDefaults.standard.object(forKey: "breakIdentifiers") as! [String]
            let oldTimer = UserDefaults.standard.string(forKey: "timerID")
            startTimer()
            let newTimer = UserDefaults.standard.string(forKey: "timerID")
            if(oldTimer != newTimer) {
                wasTerminated = true
            }
            
        } else {
            counter = UserDefaults.standard.double(forKey: "counter")
            displayTime(timeInSecs: counter)
        }
        
        // check if the user is new and set the date they first logged in and workRecord
        // used to keep track of the work sessions
        firstDateLogIn = UserDefaults.standard.object(forKey: "firstDateLogIn") as? Date
        if firstDateLogIn == nil {
            firstDateLogIn = Date()
            UserDefaults.standard.set(firstDateLogIn, forKey: "firstDateLogIn")
            workRecord = [0.0]
            UserDefaults.standard.set(workRecord, forKey: "workRecord")
        }
        
        workRecord = UserDefaults.standard.object(forKey: "workRecord") as? [Double]
        // add days to the workRecord when it is a new day
        if let lastTimeLogIn = UserDefaults.standard.object(forKey: "workLastTimeLogIn") as? Date {
            let timeDiff = Date().interval(ofComponent: .day, fromDate: lastTimeLogIn)
            print(timeDiff)
            var day = 0
            while day < timeDiff {
                workRecord.append(0.0)
                day += 1
            }
            UserDefaults.standard.set(workRecord, forKey: "workRecord")
        }
        UserDefaults.standard.set(Date(), forKey: "workLastTimeLogIn")
        print(workRecord!)
        
    }
    
    deinit {
        // remove listening for keyboard observer
        NotificationCenter.default.removeObserver(self, name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.keyboardWillChangeFrameNotification, object: nil)
    }
    
    // moves the frame when the user wants to change the break interval
    @objc func keyboardWillChange(notification: Notification) {
        if notification.name == UIApplication.keyboardWillShowNotification || notification.name == UIApplication.keyboardWillChangeFrameNotification {
            view.frame.origin.y = -everyTimePicker.frame.height + self.tabBarController!.tabBar.frame.size.height
        } else {
            view.frame.origin.y = 0
        }
    }
    
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
        let duration = everyTimePicker.countDownDuration
        displayBreakInterval(breakTime: duration)
    }
    
    // when the app enters the background, it saves the current date and time
    @objc func pauseWhenBackground(noti: Notification) {
        //let shared = UserDefaults.standard
        //shared.set(Date(), forKey: "savedTime")
    }
    
    // when the app comes back up, it calculates the difference in time and updates
    // the time accounting for how much time has passed
    @objc func willEnterForeground(noti: Notification) {
        if let savedDate = UserDefaults.standard.object(forKey: "startDate") as? Date {
            (diffHrs, diffMins, diffSecs, diffNanosecs) = FirstViewController.getTimeDifference(startDate: savedDate)
            self.refresh(hours: diffHrs, mins: diffMins, secs: diffSecs, nanosecs: diffNanosecs)
        }
    }
    
    // when the app is killed, save the counter, so it can update it when the user returns
    @objc func willTerminate(noti: Notification) {
        //UserDefaults.standard.set(counter, forKey: "counter")
    }
    
    // calculates the time difference when the user came back from the background
    static func getTimeDifference(startDate: Date) -> (Int, Int, Int, Int) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: startDate, to: Date())
        return(components.hour!, components.minute!, components.second!, components.nanosecond!)
    }
    
    // updates the timer with how much time has passed from the start date (date when start button was tapped)
    func refresh(hours: Int, mins: Int, secs: Int, nanosecs: Int) {
        if isTimerRunning {
            counter = UserDefaults.standard.double(forKey: "counter")
            counter += Double(hours) * 3600.0
            counter += Double(mins) * 60.0
            counter += Double(secs)
            
            // only consider rounding up when the user came back from termination because a new timer is created which makes the stopwatch less accurate
            // when a user comes back from background, the same timer is used which is okay for the accuracy of the stopwatch
            if(nanosecs > 50000000 && wasTerminated) {
                counter += 1
                // reset it so any time the user goes into background, the stopwatch doesn't get affected
                wasTerminated = false
            }
            
        }
    }
    
    // removes all the break notifications that are pending
    func removeAllBreakNotifications() {
        for ident in whileWorkIdent {
            center.removePendingNotificationRequests(withIdentifiers: [ident])
        }
        whileWorkIdent = []
    }
    
    // resets the timer when the reset button is pressed
    @IBAction func resetDidTap(_ sender: Any) {
        if counter > 0 {
            workSessionAlert(time: counter)
        }
        timer.invalidate()
        isTimerRunning = false
        UserDefaults.standard.set(false, forKey: "isTimerRunning")
        counter = 0.0
        UserDefaults.standard.set(counter, forKey: "counter")
        startPauseButton.setTitle("Start", for: .normal)
        time.text = "00:00"
        removeAllBreakNotifications()
    }
    
    // sends alert to ask the user if they want to save the work session they had to the workRecord
    func workSessionAlert(time: Double) {
        let alert = UIAlertController(title: "Add Work Session", message: "Do you want to save this work session?", preferredStyle: UIAlertController.Style.alert)
        
        let no = UIAlertAction(title: "No", style: .default) { (alertAction) in }
        alert.addAction(no)
        
        let yes = UIAlertAction(title: "Yes", style: .default) { (alertAction) in
            self.workRecord[self.workRecord.count - 1] += time
            UserDefaults.standard.set(self.workRecord, forKey: "workRecord")
        }
        alert.addAction(yes)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // view the work record
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showWorkRecordSegue" {
            let temp = segue.destination as! UITableViewController
            let viewController = temp as! WorkRecordTableViewController
            viewController.workRecord = workRecord
            viewController.startDate = firstDateLogIn
        }
    }
       
    // starts the timer
    func startTimer() {
        if !isTimerRunning {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(runTimer), userInfo: nil, repeats: true)
            timer.tolerance = 0.1
            let timerID = UUID().uuidString
            UserDefaults.standard.set(timerID, forKey: "timerID")
            let dateComponents = Calendar.current.dateComponents([.nanosecond], from: Date())
            secBuffer = dateComponents.nanosecond!
            UserDefaults.standard.set(secBuffer, forKey: "buffer")
            RunLoop.current.add(timer, forMode: .common)
            isTimerRunning = true
            startPauseButton.setTitle("Pause", for: .normal)
        }
    }
    
    // starts the timer and pauses the timer
    @IBAction func startDidTap(_ sender: Any?) {
        if !isTimerRunning {
            UserDefaults.standard.set(true, forKey: "isTimerRunning")
            UserDefaults.standard.set(Date(), forKey: "startDate")
            UserDefaults.standard.set(counter, forKey: "counter")
            startTimer()
            var remindCount = 0
            center.getPendingNotificationRequests { (requests) in
                remindCount = requests.count
            }
            let max = 64 - remindCount
            // does not acocunt for edge case where there are 64 notifications in queue already
            latestDate = Date()
            if remindCount < 64 {
                var i = 1
                while i < max {
                    // handles case where the user paused to keep the notification at the right interval from the start
                    if i == 1 {
                        let timeDiff = breakInterval - counter.truncatingRemainder(dividingBy: breakInterval)
                        self.sendNotification(date: latestDate.addingTimeInterval(timeDiff))
                    } else {
                        self.sendNotification(date: latestDate.addingTimeInterval(breakInterval))
                    }
                    
                    i += 1
                }
                
            }
            UserDefaults.standard.set(whileWorkIdent, forKey: "breakIdentifiers")
            
        } else {  // user wants to pause the timer
            isTimerRunning = false
            UserDefaults.standard.set(false, forKey: "isTimerRunning")
            UserDefaults.standard.set(counter, forKey: "counter")
            timer.invalidate()
            startPauseButton.setTitle("Start", for: .normal)
            
            removeAllBreakNotifications()
        }
        
    }
    
    func registerForNotification() {
        NotificationCenter.default.addObserver(forName: .sendBreakNotification, object: nil, queue: nil) { _ in
            if self.isTimerRunning {
                self.sendNotification(date: self.latestDate.addingTimeInterval(self.breakInterval))
            }
        }
    }
    
    // sends break notification with a given date
    @objc func sendNotification(date: Date) {
        var remindCount = 0
        center.getPendingNotificationRequests { (requests) in
            remindCount = requests.count
        }
        // add notification for break when there is room in the notification queue
        if isTimerRunning && remindCount < 64 {
            let content = UNMutableNotificationContent()
            content.title = "Break time"
            //content.body = "Time to \(reminder.name!)"
            content.body = "Time to take a break"
            
            // updates the latest date
            latestDate = date
            
            // get the date of the reminder
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .nanosecond], from: date)
            dateComponents.nanosecond = secBuffer
            
            // set the trigger
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            // indentifer for request
            let uuidString = UUID().uuidString
            whileWorkIdent.append(uuidString)
            //reminder.identifier = uuidString
            let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
            
            // schedule request
            center.add(request) { (error) in
                // check error
                if error != nil {
                    // handle
                }
            }
        }
    }
    
    // increments the timer and reflects the time on the timer
    @objc func runTimer() {
        counter += 1
        //UserDefaults.standard.set(counter, forKey: "counter")
        displayTime(timeInSecs: counter)
        
    }
    
    // display the time based on the counter
    func displayTime(timeInSecs: Double) {
        // HH:MM:SS
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
            time.text = "\(hour):\(minuteString):\(secondString)"
        } else {
            time.text = "\(minuteString):\(secondString)"
        }
    }
    
    // format the input for the break
    @objc func dateChanged(datePicker: UIDatePicker) {
        let duration = datePicker.countDownDuration
        displayBreakInterval(breakTime: duration)
    }
    
    func displayBreakInterval(breakTime: TimeInterval) {
        let hour: Int = Int(breakTime) / 3600
        let min: Int = (Int(breakTime) % 3600) / 60
        breakInterval = breakTime
        UserDefaults.standard.set(breakInterval, forKey: "breakInterval")
        breakIntervalTextField.text = "Every "
        if hour == 0 {
            breakIntervalTextField.text! += "\(min) min"
        } else {
            breakIntervalTextField.text! += "\(hour) hr \(min) min"
        }
    }
    
}

extension FirstViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        //        let p = touch.location(in: view)
        //        if (freqPicker?.frame.contains(p))! {
        //            return true
        //        }
        //        return true
        return (touch.view === self.view)
    }
}

