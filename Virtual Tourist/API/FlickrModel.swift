//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Ahmed Alsamani on 25/01/2019.
//  Copyright © 2019 Ahmed Alsamani. All rights reserved.
//

import Foundation
import UIKit

struct Photox: Codable {
    var id:String
    var secret:String
    var server:String
    var farm:Int
    //var url: String?
    
    func url() -> String {
        return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_q.jpg"
    }
}

struct Photos: Codable {
    var page: Int
    var pages: Int
    var perpage: Int
    var total: String
    var photo: [Photox]
}

struct Flickr: Codable {
    let photos: Photos
    let stat: String
}
