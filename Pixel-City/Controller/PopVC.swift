//
//  PopVC.swift
//  Pixel-City
//
//  Created by badal shah on 27/01/18.
//  Copyright © 2018 badal shah. All rights reserved.
//

import UIKit

class PopVC: UIViewController, UIGestureRecognizerDelegate {

    // Outlets
    @IBOutlet weak var popImageView: UIImageView!
    
    //Varialbes
    var passesImage:UIImage!
    
    func initData(forImage image:UIImage) {
        self.passesImage = image
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
 popImageView.image = passesImage
        // Do any additional setup after loading the view.
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dismissVC))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        view.addGestureRecognizer(doubleTap)
    }
    
  @objc  func dismissVC () {
        dismiss(animated: true, completion: nil)
    }

   

}
