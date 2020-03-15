//
//  HDJGPushTool.swift
//  App
//
//  Created by Damon on 2020/2/27.
//

import Core
import Crypto

public class HDJGPushTool {
    private var appKey = ""
    private var appSecrect = ""
    
    public required init(appKey: String, appSecrect: String) {
        self.appKey = appKey
        self.appSecrect = appSecrect
    }
    //推送通知
    @discardableResult
    public func pushNotification(_ req: Request, pushModel: HDJGPushModel) throws -> Future<HTTPResponse> {
        let maskSecret = "\(self.appKey):\(self.appSecrect)"
        let base64Data = maskSecret.data(using: String.Encoding.utf8)
        let base64String: String = base64Data?.base64EncodedString() ?? ""
        
        let client = try req.make(Client.self)
        let request = Request(http: HTTPRequest(method: HTTPMethod.POST, url: URL(string: "https://api.jpush.cn/v3/push")!, headers: HTTPHeaders([("Authorization" , "Basic " + base64String)]), body: try pushModel.getRequestJsonData()), using: req)
        return client.send(request).map { (response) -> HTTPResponse in
            print(response)
            return response.http
        }
    }
}
