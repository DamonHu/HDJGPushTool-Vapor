//
//  HDJGPushModel.swift
//  App
//
//  Created by Damon on 2020/3/12.
//

import Foundation

//推送的平台
public enum HDJGPushPlatform {
    case all
    case ios
    case android
    case winphone
}

public class HDJGPushModel {
    public var platform: HDJGPushPlatform = .all //推送的平台
    public var audience: HDJGPushAudienceModel?  //推送的目标，如果为NULL则推送全部，全部每天通知10次
    public var apnsProduction = false //是否推送正式环境
    private var alertTitle = ""     //推送的标题
    private var alertContent = ""   //推送的内容
    
    
    public init(alertTitle: String, alertContent: String) {
        self.alertTitle = alertTitle
        self.alertContent = alertContent
    }
    //通过内容转为json数据
    func getRequestJsonData() throws -> Data {
        var jsonObject = [String: Any]()
        //平台
        switch self.platform {
        case .all:
            jsonObject["platform"] = "all"
        case .ios:
            jsonObject["platform"] = "ios"
        case .android:
            jsonObject["platform"] = "android"
        case .winphone:
            jsonObject["platform"] = "winphone"
        }
        //标签
        var audienceObject = [String : [String]]()
        if let tag = self.audience?.tag {
            audienceObject["tag"] = tag
        }
        if let tagAnd = self.audience?.tagAnd {
            audienceObject["tag_and"] = tagAnd
        }
        if let tagNot = self.audience?.tagNot {
            audienceObject["tag_not"] = tagNot
        }
        if let alias = self.audience?.alias {
            audienceObject["alias"] = alias
        }
        if let registrationId = self.audience?.registrationId {
            audienceObject["registration_id"] = registrationId
        }
        jsonObject["audience"] = audienceObject
        if audienceObject.keys.count == 0 {
            jsonObject["audience"] = "all"
        }
        
        //内容
        var jsonMessageObject = [String : Any]()
        jsonMessageObject["ios"] = ["alert":["title": alertTitle, "body": alertContent]]
        jsonMessageObject["android"] = ["title": alertTitle, "alert": alertContent]
        jsonObject["notification"] = jsonMessageObject
        //附加参数
        jsonObject["options"] = ["apns_production": self.apnsProduction]
        let requestData: Data = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions.prettyPrinted)
        return requestData
    }
}
