//
//  ApiService.swift
//  eScooter
//
//  Created by Dove on 05/12/2020.
//  Copyright © 2020 Dove. All rights reserved.
//

import Foundation
import UIKit
class ApiService {
    static var login_url = "https://www.terasys-network.com/index.php?option=com_api&format=raw&app=users&resource=login"
    static var base_url = "https://www.terasys-network.com/plugins/api/users/users/base.php"
    
    public static let get_info = 1
    public static let save_odo = 2
    public static let check_sn = 3
    public static let upload_avatar = 4 //base 64
    public static let custom_service = 5
    public static let upload_avatar_form = 6 //form submit

    static func getPostString(params:[String:Any]) -> String {
        var data = [String]()
        for(key, value) in params {
            data.append(key + "=\(value)")
        }
        return data.map { String($0) }.joined(separator: "&")
    }
    static func _REQUEST(url:String = base_url,
                         method:String = "POST",
                         params:[String:Any],
                         userid :String? = UserDefaults.standard.string(forKey: "userid"),
                         serial_number: String? = UserDefaults.standard.string(forKey: "serial_number"),
                         callback:@escaping ([String:Any])->()){
        
        let serviceUrl = URL(string: url)!
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = method
        var tmp_params = params
        if(url != login_url){
            if(userid?.isEmpty == true || serial_number?.isEmpty == true){
                callback( ["code":403, "message":"Logout" ])
            }else{
                tmp_params.merge(["userid":userid!, "serial_number":serial_number!],  uniquingKeysWith: { (old, _) in old })
            }
        }
        let postString = self.getPostString(params: tmp_params)
        request.httpBody = postString.data(using: .utf8)
         request.timeoutInterval = 20
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
                 delegate: CustomURLSessionDelegate(),
                 delegateQueue: nil)
 
         session.dataTask(with: request) { (data, response, error) in
             if let data = data {
                 var res:[String:Any]!
                 do {
                     res = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]
                 } catch {
                     res = [
                         "code":403,
                         "userid":0,
                         "error" : error
                     ]
                 }
                 callback(res)
             }
         }.resume()
    }

    static func login(params:[String: Any], callback:@escaping ([String:Any])->()){
        return _REQUEST(url:login_url, params: params, callback: callback)
    }
    static func checkSN(serial_number:String, userid:String, callback:@escaping ([String:Any])->()){
        let params = ["type": check_sn] as [String : Any]
        return _REQUEST(params: params, userid:userid, serial_number: serial_number, callback: callback)
    }
    static func getUserInfo(callback:@escaping ([String:Any])->()){
        return _REQUEST(params: ["type":get_info], callback: callback)
    }
    static func updateOdo(){
        let difference = Calendar.current.dateComponents([.minute], from: Utils.mDate ?? Date(timeIntervalSinceReferenceDate: -123456789.0), to: Date())
        if(difference.minute ?? 0 < 20){
            return
        }
        Utils.mDate = Date()
        
        let cur_odo = Utils.mScooterInfo.odo
        if(cur_odo > 0){
            let str_odo = String(format: "%.2f", cur_odo)
            return _REQUEST(params: ["type":save_odo, "odo":str_odo]) {(result) in print(result)}
        }
    }
    static func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
                 delegate: CustomURLSessionDelegate(),
                 delegateQueue: nil)
        session.dataTask(with: url, completionHandler: completion).resume()
    }
    static func getImage(url:String?, callback: @escaping (UIImage)->()){
        if(url?.isEmpty == false){
            let url = URL(string:url!)!
            ApiService.getData(from: url) { data, response, error in
                guard let data = data, error == nil, data.count > 0, let image = UIImage(data: data) else { return }
                callback(image)
            }
        }
    }
    static func sendCustomService(params:[String: Any], callback:@escaping ([String:Any])->()){
        var tmp_params = params
        tmp_params.merge(["type":custom_service], uniquingKeysWith: { (_, new) in new })
        return _REQUEST(params: tmp_params, callback: callback)
    }

    static func uploadAvatar(image:UIImage, callback: @escaping ([String:Any])->()){
        guard let userid = UserDefaults.standard.string(forKey: "userid") else {return}
        guard let serial_number:String = UserDefaults.standard.string(forKey: "serial_number") else {return}
        let params:[String: String] = ["type":String(upload_avatar_form), "userid":userid, "serial_number":serial_number]
        let serviceUrl = URL(string: base_url)!
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        let boundary = generateBoundaryString()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let imageData = image.pngData()
        if(imageData==nil)  { return; }
        request.httpBody = createBodyWithParameters(parameters:params, filePathKey: "file", imageDataKey: imageData!, boundary: boundary)
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
                 delegate: CustomURLSessionDelegate(),
                 delegateQueue: nil)
        let task = session.dataTask(with: request) {
            data, response, error in
            if error != nil {
                print("error=\(String(describing: error))")
                return
            }
            if let data = data {
                var res:[String:Any]!
                do {
                    res = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any]
                } catch {
                    res = [
                        "code":403,
                        "userid":0,
                        "error" : error
                    ]
                }
                callback(res)
            }
        }
        task.resume()
    }
    public static func createBodyWithParameters(parameters: [String: String]?, filePathKey: String?, imageDataKey: Data, boundary: String) -> Data {
        var body = Data();
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendString(string: "--\(boundary)\r\n")
                body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString(string: "\(value)\r\n")
            }
        }
       
                let filename = "user-profile.png"
                let mimetype = "image/jpg"
                
                body.appendString(string: "--\(boundary)\r\n")
                body.appendString(string: "Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
                body.appendString(string: "Content-Type: \(mimetype)\r\n\r\n")
                body.append(imageDataKey)
                body.appendString(string: "\r\n")
        
    
        
        body.appendString(string: "--\(boundary)--\r\n")
        
        return body
    }
    public static func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }

}

class CustomURLSessionDelegate: NSObject, URLSessionDelegate {
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
          let urlCredential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
          completionHandler(.useCredential, urlCredential)
       }
}
