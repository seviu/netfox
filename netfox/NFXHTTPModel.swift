//
//  NFXHTTPModel.swift
//  netfox
//
//  Copyright © 2015 kasketis. All rights reserved.
//

import Foundation

class NFXHTTPModel: NSObject
{

    
    var requestURL: String?
    var requestMethod: String?
    var requestCachePolicy: String?
    var requestDate: NSDate?
    var requestTime: String?
    var requestTimeout: String?
    var requestHeaders: Dictionary<String, String>?
    var requestBodyLength: Int?
    var requestType: String?
    
    var responseStatus: Int?
    var responseType: String?
    var responseDate: NSDate?
    var responseTime: String?
    var responseHeaders: Dictionary<NSObject, AnyObject>?
    var responseBodyLength: Int?
    
    var timeInterval: String?
    
    var randomHash: NSString?
    
    var shortType: NSString?
    
    func saveRequest(request: NSURLRequest)
    {
        self.requestDate = NSDate()
        self.requestTime = getTimeFromDate(self.requestDate!)
        self.requestURL = request.getNFXURL()
        self.requestMethod = request.getNFXMethod()
        self.requestCachePolicy = request.getNFXCachePolicy()
        self.requestTimeout = request.getNFXTimeout()
        self.requestHeaders = request.getNFXHeaders()
        self.requestType = requestHeaders?["Content-Type"]
        saveRequestBodyData(request.getNFXBody())
    }
    
    func saveResponse(response: NSURLResponse, data: NSData)
    {
        self.responseDate = NSDate()
        self.responseTime = getTimeFromDate(self.responseDate!)
        self.responseStatus = response.getNFXStatus()
        self.responseHeaders = response.getNFXHeaders()
        saveResponseBodyData(data)
        
        if let contentType = response.getNFXHeaders()["Content-Type"] as? String {
            self.responseType = contentType.componentsSeparatedByString(";")[0]
            self.shortType = getShortTypeFrom(self.responseType!).rawValue
        }
        
        self.timeInterval = NSString(format: "%.2fs", Double(self.responseDate!.timeIntervalSinceDate(self.requestDate!))) as String
    }
    
    
    func saveRequestBodyData(data: NSData)
    {
        let tempBodyString = NSString.init(data: data, encoding: NSUTF8StringEncoding)
        self.requestBodyLength = tempBodyString?.length
        if (tempBodyString != nil) {
            saveData(tempBodyString!, toFile: getRequestBodyFilepath())
        }
    }
    
    func saveResponseBodyData(data: NSData)
    {
        let tempBodyString = NSString.init(data: data, encoding: NSUTF8StringEncoding)
        self.responseBodyLength = tempBodyString?.length
        if (tempBodyString != nil) {
            saveData(tempBodyString!, toFile: getResponseBodyFilepath())
        }
    }
    
    private func prettyOutput(rawData: NSData, contentType: String? = nil) -> NSString
    {
        if let contentType = contentType {
            let shortType = getShortTypeFrom(contentType)
            if let output = prettyPrint(rawData, type: shortType) {
                return output
            }
        }
        return NSString(data: rawData, encoding: NSUTF8StringEncoding) ?? ""
    }

    func getRequestBody() -> NSString
    {
        guard let data = readRawData(getRequestBodyFilepath()) else {
            return ""
        }
        return prettyOutput(data, contentType: requestType)
    }
    
    func getResponseBody() -> NSString
    {
        guard let data = readRawData(getResponseBodyFilepath()) else {
            return ""
        }
        
        return prettyOutput(data, contentType: responseType)
    }
    
    func getRandomHash() -> NSString
    {
        if !(self.randomHash != nil) {
            self.randomHash = NSUUID().UUIDString
        }
        return self.randomHash!
    }
    
    func getRequestBodyFilepath() -> String
    {
        let dir = getDocumentsPath() as NSString
        return dir.stringByAppendingPathComponent(getRequestBodyFilename())
    }
    
    func getRequestBodyFilename() -> String
    {
        return String("nfx_request_body_").stringByAppendingString("\(self.requestTime!)_\(getRandomHash() as String)")
    }
    
    func getResponseBodyFilepath() -> String
    {
        let dir = getDocumentsPath() as NSString
        return dir.stringByAppendingPathComponent(getResponseBodyFilename())
    }
    
    func getResponseBodyFilename() -> String
    {
        return String("nfx_response_body_").stringByAppendingString("\(self.requestTime!)_\(getRandomHash() as String)")
    }
    
    func getDocumentsPath() -> String
    {
        return NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true).first!
    }
    
    func saveData(dataString: NSString, toFile: String)
    {
        do {
            try dataString.writeToFile(toFile, atomically: false, encoding: NSUTF8StringEncoding)
        } catch {}
    }
    
    func readRawData(fromFile: String) -> NSData?
    {
        return NSData(contentsOfFile: fromFile)
    }
    
    func getTimeFromDate(date: NSDate) -> String
    {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Hour, .Minute], fromDate: date)
        let hour = components.hour
        let minutes = components.minute
        if minutes < 10 {
            return "\(hour):0\(minutes)"
        } else {
            return "\(hour):\(minutes)"
        }
    }
    
    func getShortTypeFrom(contentType: String) -> HTTPModelShortType
    {
        if contentType == "application/json" {
            return .JSON
        }
        
        if contentType == "application/xml" {
            return .XML
        }
        
        if contentType == "text/html" {
            return .HTML
        }
        
        if contentType.hasPrefix("image/") {
            return .Image
        }
        
        return .Other
    }
    
    func prettyPrint(rawData: NSData, type: HTTPModelShortType) -> String?
    {
        switch type {
        case .JSON:
            do {
                let rawJsonData = try NSJSONSerialization.JSONObjectWithData(rawData, options: [.AllowFragments])
                let prettyPrintedString = try NSJSONSerialization.dataWithJSONObject(rawJsonData, options: [.PrettyPrinted])
                return NSString(data: prettyPrintedString, encoding: NSUTF8StringEncoding) as? String
            } catch {
                return nil
            }
        
        default:
            return nil
            
        }
    }
}
