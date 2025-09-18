//
//  HDJGPushTool.swift
//  App
//
//  Created by Damon on 2020/2/27.
//

import Vapor

public class HDJGPushTool {
    private var appKey = ""
    private var appSecrect = ""

    public required init(appKey: String, appSecrect: String) {
        self.appKey = appKey
        self.appSecrect = appSecrect
    }
    //推送通知
    @discardableResult
    public func pushNotification(_ req: Request, pushModel: HDJGPushModel) throws -> EventLoopFuture<[String: Any]> {
        let maskSecret = "\(self.appKey):\(self.appSecrect)"
        let base64Data = maskSecret.data(using: String.Encoding.utf8)
        let base64String: String = base64Data?.base64EncodedString() ?? ""

        return req.client.post("https://api.jpush.cn/v3/push", headers: HTTPHeaders([("Authorization" , "Basic " + base64String)])) { (req) in
            if let jsonData =  try? pushModel.getRequestJsonData() {
                try req.content.encode(String.init(data: jsonData, encoding: .utf8) ?? "")
            }
        }.map { (response) -> ([String: Any]) in
            let bodyData = response.body?.readData(length: response.body?.readableBytes ?? 0) ?? Data()
            let json = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any] ?? [:]
            return json
        }
    }
}
