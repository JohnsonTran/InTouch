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
    let maxValueLineHeight: Double = 180
    let lineWidth: Double = 275
    
    var dataDivisor: Double?
    var adjustedData: [Double]?
    var animations: [Animation] = []
    var textColor: Color?
    
    private func createChart() {
        var items: [Node] = addYAxisItems() + addXAxisItems()
        items.append(createBars())
        
        self.node = Group(contents: items, place: .identity)
    }
    
    private func addYAxisItems() -> [Node] {
        let maxLines = 5
        let lineInterval = Int(maxValue!/Double(maxLines))
        let yAxisHeight: Double = 200
        let lineSpacing: Double = maxValueLineHeight / Double(maxLines)
        
        var newNodes: [Node] = []
        
        for i in 1...maxLines {
            let y = yAxisHeight - (Double(i) * lineSpacing)
            
            let valueLine = Line(x1: -5, y1: y, x2: lineWidth, y2: y).stroke(fill: textColor!.with(a: 0.10))
            let valueText = Text(text: "\(i * lineInterval)", align: .max, baseline: .mid, place: .move(dx: -10, dy: y))
            valueText.fill = textColor
            
            newNodes.append(valueLine)
            newNodes.append(valueText)
        }
        
        let yAxis = Line(x1: 0, y1: 0, x2: 0, y2: yAxisHeight).stroke(fill: textColor!.with(a: 0.25))
        newNodes.append(yAxis)
        
        return newNodes
    }
    
    private func addXAxisItems() -> [Node] {
        let chartBaseY: Double = 200
        var newNodes: [Node] = []
        
        let today: Date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EE"
        
        for i in 1...adjustedData!.count {
            let x = (Double(i-1) * 40 + 20)
            let valueText = Text(text: dateFormatter.string(from: today.addingTimeInterval(TimeInterval((i-7) * 86400))), align: .mid, baseline: .mid, place: .move(dx: x, dy: chartBaseY + 15))
            valueText.fill = textColor
            newNodes.append(valueText)
        }
        
        let xAxis = Line(x1: 0, y1: chartBaseY, x2: lineWidth, y2: chartBaseY).stroke(fill: textColor!.with(a: 0.25))
        newNodes.append(xAxis)
        
        return newNodes
    }
    
    private func createBars() -> Group {
        let fill = LinearGradient(degree: 90, from: Color.red, to: Color.red.with(a: 0.50))
        var items = [Group]()
        items = adjustedData!.map { _ in Group() }
        
        animations = items.enumerated().map { (i: Int, item: Group) in
            item.contentsVar.animation(delay: Double(i) * 0.1) { t in
                let height = self.adjustedData![i] * t
                let rect = Rect(x: Double(i) * 40 + 10, y: 200 - height, w: 20, h: height)
                return [rect.fill(with: fill)]
            }
        }
        return items.group()
    }
    
    func playAnimations(trackRecord: [Double], currColorMode: UIUserInterfaceStyle) {
        backgroundColor = .clear
        if currColorMode == .light {
            textColor = Color.black
        } else {
            textColor = Color.white
        }
        lastSevenDays = formatData(data: trackRecord)
        maxValue = lastSevenDays!.max()
        dataDivisor = maxValue!/maxValueLineHeight
        adjustedData = lastSevenDays!.map({ $0 / dataDivisor!})
        
        createChart()
        animations.combine().play()
    }
    
    
    private func formatData(data: [Double]) -> [Double] {
        if data.count <= 7 {
            return data
        } else {
            return Array(data.suffix(7))
        }
    }
    
}
