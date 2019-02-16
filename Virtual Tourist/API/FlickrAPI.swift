//
//  FlickrAPI.swift
//  Virtual Tourist
//
//  Created by Ahmed Alsamani on 25/01/2019.
//  Copyright © 2019 Ahmed Alsamani. All rights reserved.
//

import UIKit
import CoreData
 
class API {
    static var shared = API()
    private init() {}
    
    var latitude:Double = 0.0
    var longitude:Double = 0.0
    var pin: Pin!
    
    private  let flickrEndpoint  = "https://api.flickr.com/services/rest/"
    private  let flickrAPIKey    = "2a2ad0534c538cea62c640e0d2520400"
    private  let flickrSearch    = "flickr.photos.search"
    private  let searchRangeKM   = 10
    private  let PhotosPerPage = 30
    
    func FlickrPhotosSearch(latitude:Double, longitude:Double,totalPages : Int?, completion: @escaping (_ object: Flickr? ,_ error: Error?) -> Void) {
        
        var page: Int {
            if let totalPages = totalPages {
                let page = min(totalPages, 4000/PhotosPerPage)
                return Int(arc4random_uniform(UInt32(page)) + 1)
            }
            return 1
        }
        let url = "\(flickrEndpoint)?method=\(flickrSearch)&page=\(page)&per_page=\(PhotosPerPage)&format=json&api_key=\(flickrAPIKey)&lat=\(latitude)&lon=\(longitude)&radius=\(searchRangeKM)"
        let method = "GET"
        request(url: url, method: method, completion: completion)
    }
    
    func request<SomeType: Decodable>(url: String, method: String, parameters: Data? = nil, completion: @escaping (_ object: SomeType?,_ error: Error?) -> Void) {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = method
        request.httpBody = parameters
        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            guard let data = data else {
                print(error!)
                completion(nil,error)
                return
            }
            
            do {
                let range = Range(uncheckedBounds: (14, data.count - 1))
                let data = data.subdata(in: range)
                let result = try JSONDecoder().decode(SomeType.self, from: data)
                completion(result,error)
            } catch DecodingError.dataCorrupted(let context) {
                print(context.debugDescription)
            } catch DecodingError.keyNotFound(let key, let context) {
                print("Key '\(key)' not Found")
                print("Debug Description:", context.debugDescription)
            } catch DecodingError.valueNotFound(let value, let context) {
                print("Value '\(value)' not Found")
                print("Debug Description:", context.debugDescription)
            } catch DecodingError.typeMismatch(let type, let context)  {
                print("Type '\(type)' mismatch")
                print("Debug Description:", context.debugDescription)
            } catch {
                print("error: ", error)
            }
            completion(nil,error)

            }.resume()
        
    }
    
    func getImage(imageUrl: String, completion: @escaping (_ result: Data?, _ error: Error?) -> Void) {
        
        var request = URLRequest(url: URL(string: imageUrl)!)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else{
                completion(nil, nil)
                return
            }
            completion(data, nil)
        }
        task.resume()
    }

}
