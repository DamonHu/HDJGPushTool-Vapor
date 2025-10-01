//
//  HDJGPushTool.swift
//  App
//
//  Created by Damon on 2020/2/27.
//

import Vapor
import NIO

public class HDJGPushTool {
    private(set) var appKey = ""
    private(set) var appSecrect = ""
    
    public required init(appKey: String, appSecrect: String) {
        self.appKey = appKey
        self.appSecrect = appSecrect
    }
    //推送通知
    @discardableResult
    public func pushNotification(_ req: Request, pushModel: HDJGPushModel) -> EventLoopFuture<[String: Any]> {
        let maskSecret = "\(self.appKey):\(self.appSecrect)"
        let base64Data = maskSecret.data(using: String.Encoding.utf8)
        let base64String: String = base64Data?.base64EncodedString() ?? ""

        return req.client.post("https://api.jpush.cn/v3/push", headers: HTTPHeaders([("Authorization" , "Basic " + base64String)])) { (req) in
            if let jsonData = pushModel.getRequestJsonData() {
                req.content.encode(String.init(data: jsonData, encoding: .utf8) ?? "")
            }
        }.map { (response) -> ([String: Any]) in
            guard var body = response.body else { return [:] }
            let bodyData = body.readData(length: body.readableBytes) ?? Data()
            let json = (try? JSONSerialization.jsonObject(with: bodyData)) as? [String: Any] ?? [:]
            return json
        }
    }

    //检测id是否正常
    @discardableResult
    public func checkDevice(_ req: Request, registrationID: String) throws -> EventLoopFuture<[String: Any]> {
        let maskSecret = "\(self.appKey):\(self.appSecrect)"
        let base64Data = maskSecret.data(using: String.Encoding.utf8)
        let base64String: String = base64Data?.base64EncodedString() ?? ""

        return req.client.get("https://api.jpush.cn/v3/devices/\(registrationID)", headers: HTTPHeaders([("Authorization" , "Basic " + base64String)])).map { (response) -> ([String: Any]) in
            guard var body = response.body else { return [:] }
            let bodyData = body.readData(length: body.readableBytes) ?? Data()
            let json = (try? JSONSerialization.jsonObject(with: bodyData)) as? [String: Any] ?? [:]
            return json
        }
    }
    
    /// 分批推送，用于匀速发送多条消息
    /// - Parameters:
    ///   - req: 请求req
    ///   - pushModelList: 消息model
    ///   - perSecond: 每秒发送的数量，建议10
    /// - Returns:
    public func sendPushesWithRateLimit(_ req: Request, pushModelList: [HDJGPushModel], perSecond: Int = 10) -> EventLoopFuture<Void> {
        var futures: [EventLoopFuture<Void>] = []
        let chunks = pushModelList._chunked(into: perSecond)
        
        for (index, batch) in chunks.enumerated() {
            // 平均分配时间间隔：每条延迟 index * (1/perSecond) 秒
            let delay = TimeAmount.milliseconds(TimeAmount.Value(Int64(Double(index) * (1000.0 / Double(perSecond)))))
            let scheduled = req.eventLoop.scheduleTask(in: delay) {
                return batch.map({ model in
                    return self.pushNotification(req, pushModel: model)
                }).flatten(on: req.eventLoop)
            }
            futures.append(scheduled.futureResult.flatMap { $0.transform(to: ()) })
        }

        return futures.flatten(on: req.eventLoop)
    }
}


extension Array {
    func _chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
