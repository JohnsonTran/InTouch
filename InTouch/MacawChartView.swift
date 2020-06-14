//
//  MacawChartView.swift
//  InTouch
//
//  Created by Johnson Tran on 5/27/20.
//  Copyright © 2020 Johnson Tran. All rights reserved.
//

import Foundation
import Macaw

class MacawChartView: MacawView {
    
    var lastSevenDays: [Double]?
    var maxValue: Double?
    var goal: Double?
    let maxValueLineHeight: Double = 180
    let lineWidth: Double = 275
    
    var dataDivisor: Double?
    var adjustedData: [Double]?
    var animations: [Animation] = []
    var textColor: Color?
    
    // combines all the elements to make the chart
    private func createChart() {
        var items: [Node] = addYAxisItems() + addXAxisItems()
        items.append(createBars())
        items.append(addBarLabels())
        
        self.node = Group(contents: items, place: .identity)
    }
    
    // adds the interval lines and y-axis to the chart
    private func addYAxisItems() -> [Node] {
        let maxLines = findOptimalLines(maxValue: maxValue!)
        let lineInterval = maxValue!/Double(maxLines)
        let yAxisHeight: Double = 200
        let lineSpacing: Double = maxValueLineHeight / Double(maxLines)
        
        var newNodes: [Node] = []
        
//        for i in 1...maxLines {
//            let y = yAxisHeight - (Double(i) * lineSpacing)
//
//            let valueLine = Line(x1: -5, y1: y, x2: lineWidth, y2: y).stroke(fill: textColor!.with(a: 0.10))
//            let valueText = Text(text: "\(Int((Double(i) * lineInterval).rounded()))", align: .max, baseline: .mid, place: .move(dx: -10, dy: y))
//            valueText.fill = textColor
//
//            newNodes.append(valueLine)
//            newNodes.append(valueText)
//        }
        
        if self.goal != -1.0 {
            let height = yAxisHeight - (maxValueLineHeight * goal! / maxValue!)
            let goalLine = Line(x1: -15, y1: height, x2: lineWidth, y2: height).stroke(fill: Color.red)
            let goalValue = Text(text: "\(Int(goal!))", fill: Color.red, align: .max, baseline: .mid, place: .move(dx: -20, dy: height))
            let goalText = Text(text: "Goal", fill: Color.red, align: .max, baseline: .mid, place: .move(dx: -20, dy: height + 18))
            newNodes.append(goalLine)
            newNodes.append(goalValue)
            newNodes.append(goalText)
        }
        
        let yAxis = Line(x1: -10, y1: 0, x2: -10, y2: yAxisHeight).stroke(fill: textColor!.with(a: 0.25))
        newNodes.append(yAxis)
        
        return newNodes
    }
    
    // method to find an optimal amount of lines for the y-axis given the max value of the data set
    private func findOptimalLines(maxValue: Double) -> Int {
        if maxValue < 13 {
            return Int(maxValue)
        }
        var best = 1
        var smallestDiff = 1.0
        for i in 3...10 {
            if Int(maxValue) % i == 0 {
                best = i
                smallestDiff = 0.0
            } else {
                let diff = abs(round(maxValue/Double(i))-maxValue/Double(i))
                if diff < smallestDiff {
                    smallestDiff = diff
                    best = i
                }
            }
        }
        return best
    }
    
    // adds the day labels and x-axis to the chart
    private func addXAxisItems() -> [Node] {
        let chartBaseY: Double = 200
        var newNodes: [Node] = []
        
        let today: Date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EE"
        
        for i in 1...adjustedData!.count {
            let x = (Double(i-1) * 40 + 10)
            let valueText = Text(text: dateFormatter.string(from: today.addingTimeInterval(TimeInterval((i-7) * 86400))), align: .mid, baseline: .mid, place: .move(dx: x, dy: chartBaseY + 15))
            valueText.fill = textColor
            newNodes.append(valueText)
        }
        
        let xAxis = Line(x1: -10, y1: chartBaseY, x2: lineWidth, y2: chartBaseY).stroke(fill: textColor!.with(a: 0.25))
        newNodes.append(xAxis)
        
        return newNodes
    }
    
    // creates the bars for the chart and their animations
    private func createBars() -> Group {
        let fill = LinearGradient(degree: 90, from: Color.blue, to: Color.blue.with(a: 0.50))
        var items = [Group]()
        items = adjustedData!.map { _ in Group() }
        
        animations = items.enumerated().map { (i: Int, item: Group) in
            item.contentsVar.animation(delay: Double(i) * 0.2) { t in
                let height = self.adjustedData![i] * t
                let rect = Rect(x: (Double(i) * 40), y: 200 - height, w: 20, h: height)
                return [rect.fill(with: fill)]
            }
        }
        return items.group()
    }
    
    private func addBarLabels() -> Group {
        var items = [Group]()
        items = adjustedData!.map { _ in Group() }
        let yAxisHeight: Double = 200
        
        animations += items.enumerated().map { (i: Int, item: Group) in
            item.contentsVar.animation(delay: 1.1 + Double(i) * 0.2) { t in
                let x = (Double(i) * 40 + 10)
                let labelText = Text(text: "\(Int(self.lastSevenDays![i]))", align: .mid, baseline: .mid, place: .move(dx: x, dy: yAxisHeight - self.adjustedData![i] - 12))
                labelText.fill = self.textColor
                return [labelText]
            }
        }
        return items.group()
    }
    
    // takes in data and creates a chart out of it
    func playAnimations(trackRecord: [Double], goal: Double, currColorMode: UIUserInterfaceStyle) {
        backgroundColor = .clear
        if currColorMode == .light {
            textColor = Color.black
        } else {
            textColor = Color.white
        }
        lastSevenDays = formatData(data: trackRecord)
        self.goal = goal
        if self.goal != -1.0 {
            maxValue = max(goal, lastSevenDays!.max()!)
        } else {
            maxValue = lastSevenDays!.max()
        }
        
        dataDivisor = maxValue!/maxValueLineHeight
        adjustedData = lastSevenDays!.map({ $0 / dataDivisor!})
        
        createChart()
        animations.combine().play()
    }
    
    // only gets the last 7 days of data
    private func formatData(data: [Double]) -> [Double] {
        if data.count <= 7 {
            return data
        } else {
            return Array(data.suffix(7))
        }
    }
    
}
