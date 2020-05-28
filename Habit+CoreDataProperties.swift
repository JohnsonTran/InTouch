//
//  Habit+CoreDataProperties.swift
//  InTouch
//
//  Created by Johnson Tran on 5/14/20.
//  Copyright © 2020 Johnson Tran. All rights reserved.
//
//

import Foundation
import CoreData


extension Habit {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Habit> {
        return NSFetchRequest<Habit>(entityName: "Habit")
    }

    @NSManaged public var goal: Double
    @NSManaged public var name: String?
    @NSManaged public var units: String?
    // daily record of how much the user accomplished for the habit
    // the size is amount of days since the startDate 
    @NSManaged public var recordTrack: [Double]?
    @NSManaged public var startDate: Date?

}
