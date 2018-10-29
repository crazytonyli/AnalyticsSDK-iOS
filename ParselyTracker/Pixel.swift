//
//  pixel.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation
import SwiftHTTP
import os.log

class Pixel {
    var _baseURL: String?
    var configData: Dictionary<String, Any?>
    
    init() {
        self._baseURL = nil
        self.configData = [
            "idsite": Parsely.sharedInstance.apikey,
            "data": [:]
        ]
    }
    
    func buildPixelURL(now: Date) -> String {
        if self._baseURL == nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HH"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            let dateString = dateFormatter.string(from: now)
            self._baseURL = "https://srv-\(dateString).pixel.parsely.com/mobileproxy/"
        }
        return self._baseURL!
    }
    
    func beacon(additionalParams: Event, shouldNotSetLastRequest: Bool) {
        os_log("Fired beacon", log: OSLog.default, type: .debug)
        let session = Session().get(extendSession: true)
        let rand = Date().millisecondsSince1970
        var data: Dictionary<String,Any?> = ["rand": rand]
        data = data.merging(self.configData, uniquingKeysWith: { (old, _new) in old })
        data = data.merging(session, uniquingKeysWith: { (old, _new) in old })
        data = data.merging(additionalParams.toDict(), uniquingKeysWith: { (old, _new) in old })
        let visitorInfo = Parsely.sharedInstance.visitorManager?.getVisitorInfo(shouldExtendExisting: true)
        var dataString = ""
        let subData = data["data"] ?? [:] as Dictionary<String, Any?>
        do {
            let subData = try JSONSerialization.data(withJSONObject: subData ?? [:], options: .prettyPrinted)
            dataString = String(data: subData, encoding: .ascii) ?? ""
        } catch {
            dataString = ""
        }
        data["data"] = dataString
        if (shouldNotSetLastRequest) {
            Parsely.sharedInstance.lastRequest = data
        }
        Parsely.sharedInstance.config["uuid"] = visitorInfo?["id"]!
        Parsely.sharedInstance.eventQueue.push(Event(params: data))
    }
}
