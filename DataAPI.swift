//  DataAPI.swift
//
//  A service class written for Swift 4.x, to work with the FileMaker 17 Data API
//
//  Created by Brian Hamm on 9/16/18.
//  Copyright © 2018 Brian Hamm. All rights reserved.

//TODO: https://www.swiftbysundell.com/posts/constructing-urls-in-swift

import Foundation


class DataAPI {    
    
    let auth = UserDefaults.standard.string(forKey: "fm-auth")      // fetch from CloudKit at launch, or...
//  static let auth = "xxxxxabcdefg1234567"
    
    let path = UserDefaults.standard.string(forKey: "fm-db-path")   // fetch from CloudKit at launch, or...
//  static let path = "https://<hostName>/fmi/data/v1/databases/<databaseName>"
    
    
    
    // active token?
    class func isActiveToken() -> Bool {
        
        let token   = UserDefaults.standard.string(forKey: "fm-token")
        let expiry  = UserDefaults.standard.object(forKey: "fm-token-expiry") as? Date ?? Date(timeIntervalSince1970: 0)
        
        if let _ = token, expiry > Date() {
            return true
        } else {
            return false
        }
    }
    
    
    
    // refresh token -> (token, expiry, error)
    class func refreshToken(for auth: String, completion: @escaping (String, Date, String) -> Void) {
        
        guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
                let baseURL = URL(string: path) else { return }
        
        let url = baseURL.appendingPathComponent("/sessions")
        let expiry = Date(timeIntervalSinceNow: 900)   // 15 minutes
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(auth)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            
            guard   let data      = data, error == nil,
                    let json      = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                    let response  = json["response"] as? [String: Any],
                    let messages  = json["messages"] as? [[String: Any]],
                    let code      = messages[0]["code"] as? String else { return }
            
            guard let token = response["token"] as? String else {
                print(messages)
                return
            }
            
            UserDefaults.standard.set(token, forKey: "fm-token")
            UserDefaults.standard.set(expiry, forKey: "fm-token-expiry")
            
            completion(token, expiry, code)
            
        }.resume()
    }
    
    
    
    
    // get records -> ([records], error)
    class func getRecords(token: String, layout: String, limit: Int, completion: @escaping ([[String: Any]], String) -> Void) {
        
        guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
                let baseURL = URL(string: path) else { return }
        
        let url = baseURL.appendingPathComponent("/layouts/\(layout)/records?_offset=1&_limit=\(limit)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            
            guard   let data      = data, error == nil,
                    let json      = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                    let response  = json["response"] as? [String: Any],
                    let messages  = json["messages"] as? [[String: Any]],
                    let code      = messages[0]["code"] as? String else { return }
            
            guard let records = response["data"] as? [[String: Any]] else {
                print(messages)
                return
            }
            
            completion(records, code)
            
        }.resume()
    }

    
    
    
    // find request -> ([records], error)
    class func findRequest(token: String, layout: String, payload: [String: Any], completion: @escaping ([[String: Any]], String) -> Void) {
        
        //  payload = ["query": [             payload = ["query": [
        //      ["firstName": "Brian"],           "firstName": "Brian",
        //      ["firstName": Geoff"]             "lastName": "Hamm"
        //  ]]                                ]]
        
        guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
                let baseURL = URL(string: path),
                let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        
        let url = baseURL.appendingPathComponent("/layouts/\(layout)/_find")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            
            guard   let data      = data, error == nil,
                    let json      = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                    let response  = json["response"] as? [String: Any],
                    let messages  = json["messages"] as? [[String: Any]],
                    let code      = messages[0]["code"] as? String else { return }
            
            guard let records = response["data"] as? [[String: Any]] else {
                print(messages)
                return
            }
            
            completion(records, code)
            
        }.resume()
    }
    
    
    
    
    // get record with id -> (record, error)
    class func getRecordWith(id: Int, token: String, layout: String, completion: @escaping ([String: Any], String) -> Void) {
        
        guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
                let baseURL = URL(string: path) else { return }
        
        let url = baseURL.appendingPathComponent("/layouts/\(layout)/records/\(id)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            
            guard   let data      = data, error == nil,
                    let json      = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                    let response  = json["response"] as? [String: Any],
                    let messages  = json["messages"] as? [[String: Any]],
                    let code      = messages[0]["code"] as? String else { return }
            
            guard let records = response["data"] as? [[String: Any]] else {
                print(messages)
                return
            }
            
            completion(records[0], code)
            
        }.resume()
    }
    
    
    
    
    // delete record with id -> (error)
    class func deleteRecordWith(id: Int, token: String, layout: String, completion: @escaping (String) -> Void) {
        
        guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
                let baseURL = URL(string: path) else { return }
        
        let url = baseURL.appendingPathComponent("/layouts/\(layout)/records/\(id)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            
            guard   let data      = data, error == nil,
                    let json      = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                    let messages  = json["messages"] as? [[String: Any]],
                    let code      = messages[0]["code"] as? String else { return }
            
            guard code == "0" else {
                print(messages)
                return
            }
            
            completion(code)
            
        }.resume()
    }
    
    
    
    
    // edit record with id -> (error)
    class func editRecordWith(id: Int, token: String, layout: String, payload: [String: Any], modID: Int?, completion: @escaping (String) -> Void) {
        
        //  payload = ["fieldData": [
        //      "firstName": "newValue",
        //      "lastName": "newValue"
        //  ]]  
        
        guard   let path = UserDefaults.standard.string(forKey: "fm-db-path"),
                let baseURL = URL(string: path),
                let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        
        let url = baseURL.appendingPathComponent("/layouts/\(layout)/records/\(id)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            
            guard   let data      = data, error == nil,
                    let json      = try? JSONSerialization.jsonObject(with: data) as! [String: Any],
                    let messages  = json["messages"] as? [[String: Any]],
                    let code      = messages[0]["code"] as? String else { return }
            
            guard code == "0" else {
                print(messages)
                return
            }
            
            completion(code)
            
        }.resume()
    }
}
