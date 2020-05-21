//
//  AddHabitViewController.swift
//  InTouch
//
//  Created by Johnson Tran on 5/14/20.
//  Copyright © 2020 Johnson Tran. All rights reserved.
//

import UIKit
import UserNotifications
import SwiftUI
import CoreData


class AddHabitViewController: UIViewController, UITextFieldDelegate {
    
    var habit: Habit!
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var unitsTextField: UITextField!
    
    @IBOutlet weak var goalTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped(gestureRecognizer:)))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        view.addGestureRecognizer(tap)
        
        saveButton.isEnabled = false
        nameTextField.delegate = self
        unitsTextField.delegate = self
        goalTextField.delegate = self
        goalTextField.keyboardType = .decimalPad
        
    }
    
    @objc func viewTapped(gestureRecognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    
    //MARK - UITextField methods
    func checkName() {
        // disable save button if text field is empty
        if !(nameTextField.text!.isEmpty || unitsTextField.text!.isEmpty || goalTextField.text!.isEmpty) {
            saveButton.isEnabled = true
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        checkName()
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
            habit = Habit(context: PersistenceService.context)
            PersistenceService.saveContext()
            habit.name = nameTextField.text
            habit.units = unitsTextField.text
            habit.goal = (goalTextField.text! as NSString).doubleValue
            habit.recordTrack = [0.0]
            habit.startDate = Date()
            PersistenceService.saveContext()
        }
    }
}

extension AddHabitViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        //        let p = touch.location(in: view)
        //        if (freqPicker?.frame.contains(p))! {
        //            return true
        //        }
        //        return true
        return (touch.view === self.view)
    }
}


