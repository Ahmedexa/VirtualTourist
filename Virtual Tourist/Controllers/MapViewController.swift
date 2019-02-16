//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Ahmed Alsamani on 25/01/2019.
//  Copyright © 2019 Ahmed Alsamani. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate, UIGestureRecognizerDelegate  {
    var pin = [Pin]()
    var fetchResultVC: NSFetchedResultsController<Pin>!
    
    var dataController: DataController {
        return DataController.shared
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var topButton: UIBarButtonItem!
    @IBOutlet weak var deleteView: UIView!
    
    var pinMap: MKPointAnnotation? = nil
    var removePin:Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        deleteView.isHidden = true
        LoadAllMapPins()
    }
    
    
    @IBAction func longPress(_ sender: UILongPressGestureRecognizer){
        print("long tap")
        let location = sender.location(in: mapView)
        let locCoord = mapView.convert(location, toCoordinateFrom: mapView)
        
        if sender.state == .began {
            pinMap = MKPointAnnotation()
            pinMap!.coordinate = locCoord
            mapView.addAnnotation(pinMap!)
            
        } else if sender.state == .changed {
            pinMap!.coordinate = locCoord
            
        } else if sender.state == .ended {
            addAnnotation(location: pinMap!.coordinate )
        }
    }
    
    func LoadAllMapPins() {
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchResultVC = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultVC.delegate = self
        do {
            try fetchResultVC.performFetch()
            ShowMapPins()
        } catch {
        }
    }
    
    
    func ShowMapPins() {
        guard (fetchResultVC.fetchedObjects?.count) != nil else {
            return
        }
        for pin in fetchResultVC.fetchedObjects! {
            let addPin = MKPointAnnotation()
            addPin.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            print(addPin.coordinate.latitude)
            self.mapView.addAnnotation(addPin)
            self.pin.append(pin)
        }
        mapView.showAnnotations(mapView.annotations, animated: true)
    }

    func addAnnotation(location: CLLocationCoordinate2D){
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        let savePin = Pin(context: dataController.viewContext)
        savePin.latitude = annotation.coordinate.latitude
        savePin.longitude = annotation.coordinate.longitude
        try? dataController.viewContext.save()
        
        print(savePin.latitude)
        pin.append(savePin)

        self.mapView.addAnnotation(annotation)
    }
    
    @IBAction func editPressed(_ sender: Any) {
        if topButton.title == "Done" {
            topButton.title = "Edit"
            self.deleteView.isHidden = true
            removePin = false
        }else{
            topButton.title = "Done"
            removePin = true
            self.deleteView.isHidden = false
        }
    }
}

extension MapViewController: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { print("no mkpointannotaions"); return nil }
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else {
            return
        }
        mapView.deselectAnnotation(annotation, animated: true)
        
        if removePin == true{
            let remove = self.pin.first(where: { $0.latitude == view.annotation?.coordinate.latitude && $0.longitude == view.annotation?.coordinate.longitude})
            self.mapView.removeAnnotation(view.annotation!)
            try? DataController.shared.viewContext.delete(remove!)
            try? DataController.shared.viewContext.save()
            
        } else{
            
            let tmp = self.pin.first(where: { $0.latitude == view.annotation?.coordinate.latitude && $0.longitude == view.annotation?.coordinate.longitude})
            API.shared.pin = tmp
            API.shared.latitude = (tmp?.latitude)!
            API.shared.longitude = (tmp?.longitude)!
            
            self.performSegue(withIdentifier: "ShowPhotoAlbum", sender: nil)

        }
    }
    
}


