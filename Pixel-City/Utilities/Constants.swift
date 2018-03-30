//
//  Constants.swift
//  Pixel-City
//
//  Created by badal shah on 20/01/18.
//  Copyright © 2018 badal shah. All rights reserved.
//

import Foundation

let apiKey = "0e8323c72b991aacd8424aa01531af96"
let secretKey = "c23a85b5f9e75835"

func flickerUrl(forApiKey key:String , withAnnotation annotation:DroppablePin, andNumberofPhotos number:Int) ->String {
    let url = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=15&radius_units=km&per_page=\(number)&format=json&nojsoncallback=1"
    return url
}
