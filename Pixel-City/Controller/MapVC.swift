//
//  MapVC.swift
//  Pixel-City
//
//  Created by badal shah on 10/01/18.
//  Copyright © 2018 badal shah. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage


class MapVC: UIViewController, UIGestureRecognizerDelegate {
    
    //Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottomViewHeight: NSLayoutConstraint!
    @IBOutlet weak var bottomView: UIView!
    
    //Variables
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRadious : Double = 1000
    var spinner : UIActivityIndicatorView?
    var progressLbl : UILabel?
    
    var screenSize = UIScreen.main.bounds
    
    var collectionView : UICollectionView?
    var flowLayout = UICollectionViewLayout()
    
    var arrayImageUrls = [String]()
    var arrayImage = [UIImage]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        locationManager.delegate = self
        configureLocationService()
        addDoubleTap()
        
        //Create collectionView Programatically
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "photoCell")
        collectionView?.dataSource = self
        collectionView?.delegate = self
        collectionView?.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
        registerForPreviewing(with: self, sourceView: collectionView!)
        
        bottomView.addSubview(collectionView!)
    }
    
    func addDoubleTap () {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(MapVC.dropPin(sender:)))
        tapGesture.numberOfTapsRequired = 2
        tapGesture.delegate = self
        mapView.addGestureRecognizer(tapGesture)
    }
    
    func addSwipe() {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(MapVC.animateViewDown))
        swipeGesture.direction = .down
        bottomView.addGestureRecognizer(swipeGesture)
        
    }
    
    func animateViewUp() {
        bottomViewHeight.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func animateViewDown() {
        cancelAllSessions()
        bottomViewHeight.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    //MARK:- Add and Remove Spinner
    
    func addSpinner() {
        spinner = UIActivityIndicatorView()
        spinner?.center = CGPoint(x: (screenSize.width/2) - ((spinner?.frame.width)!/2), y: 150)
        spinner?.activityIndicatorViewStyle = .whiteLarge
        spinner?.color = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        spinner?.startAnimating()
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    //MARK:- Add and Remove progressLbl
    func addProgressLbl() {
        progressLbl = UILabel()
        progressLbl?.frame = CGRect(x: (screenSize.width/2)-120, y: 175, width: 240, height: 40)
        progressLbl?.font = UIFont(name: "Avenir Next", size: 18)
        progressLbl?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressLbl?.textAlignment = .center
        collectionView?.addSubview(progressLbl!)
    }
    
    func removeProgressLbl() {
        if progressLbl != nil {
            progressLbl?.removeFromSuperview()
        }
    }
    
  
    
   
    
    
    @IBAction func centerMapButtonWasPressed(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUsersLocation()
        }
    }
    
    
    
   
    
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({$0.cancel()})
            downloadData.forEach({$0.cancel()})
        }
    }
    
    
    
}

extension MapVC: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    func centerMapOnUsersLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return  }
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, regionRadious * 2.0, regionRadious * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @objc  func dropPin(sender: UITapGestureRecognizer) {
        removePin() // It will remove pin from the map before adding new Pin
        removeSpinner() // It will remove Spinner from the bottomView before adding new Spinner
        removeProgressLbl()
        cancelAllSessions()
        
        arrayImageUrls = []
        arrayImage = []
        
        collectionView?.reloadData()
        
        animateViewUp()
        addSwipe()
        addSpinner()
        addProgressLbl()
        
        //Drop the pin on the Map
        let touchPoint = sender.location(in: mapView)
        //print(touchPoint)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: "droppablePin")
        mapView.addAnnotation(annotation)
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, regionRadious * 2.0, regionRadious * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        
        retriveUrls(forAnnotation: annotation) { (finished) in
            if finished {
                self.retriveImages(handler: { (finished) in
                    if finished {
                        self.removeSpinner()  //stop spinner
                        self.removeProgressLbl() // hide lablel
                        self.collectionView?.reloadData()
                        
                    }
                })
            }
        }
    }
    
    func removePin() {
        for annotation in mapView.annotations {
            mapView.removeAnnotation(annotation)
        }
    }
    
    
    func retriveUrls(forAnnotation annotation:DroppablePin, handler: @escaping (_ success: Bool) -> ())  {
        Alamofire.request(flickerUrl(forApiKey: apiKey, withAnnotation: annotation, andNumberofPhotos: 40)).responseJSON { (response) in
            guard let json = response.result.value as? Dictionary<String, AnyObject> else {return}
            let photosDictionary = json["photos"] as! Dictionary<String, AnyObject>
            let photosDictArray = photosDictionary["photo"] as! [Dictionary<String, AnyObject>]
            for photo in photosDictArray {
                let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                self.arrayImageUrls.append(postUrl)
            }
            handler(true)
        }
        
    }
    
    func retriveImages(handler: @escaping (_ status: Bool) -> ()){
        for url in arrayImageUrls {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                guard let image = response.result.value else {return}
                self.arrayImage.append(image)
                self.progressLbl?.text = "\(self.arrayImage.count)/40 Images Downloaded"
                
                if self.arrayImage.count == self.arrayImageUrls.count {
                    handler(true)
                }
            })
        }
    }
    
    
}

extension MapVC: CLLocationManagerDelegate {
    func configureLocationService() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUsersLocation()
    }
    
}

extension MapVC: UICollectionViewDelegate , UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {  //Number of item in Arry
        print(arrayImage.count)
        return arrayImage.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        let imageFromIndex = arrayImage[indexPath.row]
        let imageView = UIImageView(image: imageFromIndex)
        imageView.backgroundColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
        cell.addSubview(imageView)
        return cell
        }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        guard let popVc = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else {return}
        popVc.initData(forImage: arrayImage[indexPath.item])
        present(popVc, animated: true, completion: nil)
        
    }
      
}

extension MapVC: UIViewControllerPreviewingDelegate {  //Method for 3D Touch
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        //Where we are Pessing , from where need 3d Touch
        guard let indexPath = collectionView?.indexPathForItem(at: location) , let cell = collectionView?.cellForItem(at: indexPath) else {return nil}
        
        guard let popVc = storyboard?.instantiateViewController(withIdentifier: "PopVC") as? PopVC else {return nil}
        popVc.initData(forImage: arrayImage[indexPath.item])
        previewingContext.sourceRect = cell.contentView.frame
        return popVc
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}

