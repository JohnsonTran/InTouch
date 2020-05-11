//
//  Notification.Name+Extensions.swift
//  InTouch
//
//  Created by Johnson Tran on 3/24/20.
//  Copyright © 2020 Johnson Tran. All rights reserved.
//

import Foundation

extension Notification.Name {
    
    static let sendBreakNotification = Notification.Name("sendBreakNotification")
}

@objc extension NSNotification {
    public static let sendBreakNotification = Notification.Name.sendBreakNotification
}
