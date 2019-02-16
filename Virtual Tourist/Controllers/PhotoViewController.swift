//
//  PhotoViewController.swift
//  Virtual Tourist
//
//  Created by Ahmed Alsamani on 25/01/2019.
//  Copyright © 2019 Ahmed Alsamani. All rights reserved.
//


import UIKit
import MapKit
import CoreData

class PhotoViewController:  UIViewController, MKMapViewDelegate , UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var MapView: MKMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var LabelStatus: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var Button: UIButton!
    
    var fetchResult: NSFetchedResultsController<Photo>!
    
    var pin: Pin!
    var totalPages: Int? = nil
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator.stopAnimating()
        self.LabelStatus.text = ""
        
        updateFlowLayout(view.frame.size)
        
        let addPin = MKPointAnnotation()
        addPin.coordinate = CLLocationCoordinate2D(latitude: API.shared.latitude , longitude: API.shared.longitude)
        MapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2DMake(API.shared.latitude, API.shared.longitude), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)), animated: true)
        MapView.addAnnotation(addPin)
        
        pin = API.shared.pin
        fetchPhotosFromDC(pin)

        if self.fetchResult?.fetchedObjects?.count ?? 0 == 0 {
            fetchPhotosFromAPI(pin)
        }
    }
    
    
    private func fetchPhotosFromDC(_ pin: Pin) {
        
        let fr = NSFetchRequest<Photo>(entityName: "Photo")
        fr.sortDescriptors = []
        fr.predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        
        fetchResult = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)

        var error: NSError?
        do {
            try fetchResult.performFetch()
            self.collectionView.reloadData()
        } catch let error1 as NSError {
            error = error1
        }
        
        if let error = error {
            print("Error performing initial fetch: \(error)")
        }
    }
    
    private func fetchPhotosFromAPI(_ pin: Pin) {
        
        activityIndicator.startAnimating()
        self.LabelStatus.text = "Fetching photos ..."
        print("Fetching photos ...")
        API.shared.FlickrPhotosSearch(latitude: pin.latitude, longitude: pin.longitude, totalPages: totalPages) { (Flickr, error) in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.LabelStatus.text = ""
            
                if let FlickrPhotos = Flickr {
                    self.totalPages = FlickrPhotos.photos.pages
                    let totalPhotos = FlickrPhotos.photos.photo.count

                    for photo in FlickrPhotos.photos.photo  {
                        let item = Photo(context: DataController.shared.viewContext)
                        item.imageURL = photo.url()
                        item.pin = pin
                    }
                    
                    do {
                        try DataController.shared.viewContext.save()
                        
                    } catch {
                     //   print(error)
                    }
                    
                    if totalPhotos == 0 {
                        self.LabelStatus.text = "No Photos Found!"
                    }else{
                        DispatchQueue.main.async {
                        self.fetchPhotosFromDC(pin)
                        }
                    }
                } else if let error = error {
                    print("error:\(error)")
                    self.LabelStatus.text = "Opps , Please try again "
                }
            }
        }
    }

    
    func save() {
       try?  DataController.shared.viewContext.save()
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        for photos in fetchResult.fetchedObjects! {
            DataController.shared.viewContext.delete(photos)
            save()
        }
        fetchPhotosFromDC(pin!)
        fetchPhotosFromAPI(pin!)

    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchResult?.fetchedObjects?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as? PhotoViewCell else {
            return UICollectionViewCell()
        }
        cell.ActivityIndicator.startAnimating()
        let photo = self.fetchResult?.object(at: indexPath)
        if let data = photo?.imageData, let image = UIImage(data: data) {
            cell.imageView.image = image
            cell.ActivityIndicator.stopAnimating()
        } else {
            guard photo!.imageURL != nil else {
                return cell
            }
            API.shared.getImage(imageUrl: photo!.imageURL!) { (data, error) in
                guard data != nil else {
                    return
                }
                DispatchQueue.main.async {
                    cell.imageView.image = UIImage(data: data!)
                    cell.ActivityIndicator.stopAnimating()
                    photo?.imageData = data
                    try? DataController.shared.viewContext.save()
                }
                let photo = Photo(context: DataController.shared.viewContext)
                photo.imageData = data
                try? DataController.shared.viewContext.save()
                }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchResult.object(at: indexPath)
        DataController.shared.viewContext.delete(photoToDelete)
        save()
        fetchPhotosFromDC(pin)
    }
   
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateFlowLayout(size)
    }

    private func updateFlowLayout(_ withSize: CGSize) {
    
        let landscape = withSize.width > withSize.height
        
        let space: CGFloat = landscape ? 5 : 3
        let items: CGFloat = landscape ? 2 : 3
        
        let dimension = (withSize.width - ((items + 1) * space)) / items
        
        flowLayout?.minimumInteritemSpacing = space
        flowLayout?.minimumLineSpacing = space
        flowLayout?.itemSize = CGSize(width: dimension, height: dimension)
        flowLayout?.sectionInset = UIEdgeInsets(top: space, left: space, bottom: space, right: space)
    }
    
}
    
