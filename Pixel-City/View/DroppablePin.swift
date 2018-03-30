//
//  DropablePin.swift
//  Pixel-City
//
//  Created by badal shah on 10/01/18.
//  Copyright © 2018 badal shah. All rights reserved.
//

import UIKit
import MapKit

class DroppablePin: NSObject , MKAnnotation {
   dynamic var coordinate: CLLocationCoordinate2D
    var identifier: String!
    
    init(coordinate: CLLocationCoordinate2D, identifier:String) {
        self.coordinate = coordinate
        self.identifier = identifier
        super.init()
    }
}
