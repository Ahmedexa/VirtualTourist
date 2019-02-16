//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Ahmed Alsamani on 25/01/2019.
//  Copyright © 2019 Ahmed Alsamani. All rights reserved.
//

import UIKit

class PhotoViewCell: UICollectionViewCell {
    static let identifier = "PhotoCell"
    
    var imageURL: String = ""
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    
}



