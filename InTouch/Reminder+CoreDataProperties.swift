//
//  Reminder+CoreDataProperties.swift
//  InTouch
//
//  Created by Johnson Tran on 3/7/20.
//  Copyright © 2020 Johnson Tran. All rights reserved.
//
//

import UIKit
import CoreData


extension Reminder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Reminder> {
        let request:NSFetchRequest<Reminder> = NSFetchRequest<Reminder>(entityName: "Reminder")
        return request
    }

    @NSManaged public var name: String?
    @NSManaged public var time: Date?
    @NSManaged public var identifier: String?
    @NSManaged public var type: String?
    // only for while working reminders
    @NSManaged public var timeInterval: Double
    
    
}
