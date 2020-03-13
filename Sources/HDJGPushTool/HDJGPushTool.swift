//
//  HDJGPushTool.swift
//  App
//
//  Created by Damon on 2020/2/27.
//

import Vapor
import Crypto

class HDJGPushTool {
    private var appKey = ""
    private var appSecrect = ""
    
    required init(appKey: String, appSecrect: String) {
        self.appKey = appKey
        self.appSecrect = appSecrect
    }
    //推送通知
    @discardableResult
    func pushNotification(_ req: Request, pushModel: HDJGPushModel) throws -> Future<Res_NoDataModel> {
        let maskSecret = "\(self.appKey):\(self.appSecrect)"
        let base64Data = maskSecret.data(using: String.Encoding.utf8)
        let base64String: String = base64Data?.base64EncodedString() ?? ""
        
        let client = try req.make(Client.self)
        let request = Request(http: HTTPRequest(method: HTTPMethod.POST, url: URL(string: "https://api.jpush.cn/v3/push")!, headers: HTTPHeaders([("Authorization" , "Basic " + base64String)]), body: try pushModel.getRequestJsonData()), using: req)
        return client.send(request).map { (response) -> Res_NoDataModel in
            print(response)
            let res_NoDataModel = Res_NoDataModel()
            return res_NoDataModel
        }
    }
}