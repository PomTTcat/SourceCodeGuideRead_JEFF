//
//  ViewController.swift
//  ObjectGuide
//
//  Created by PomCat on 2019/6/27.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Do any additional setup after loading the view.
    }


    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        EasyUser.modelWithDict()
        
        //        User.modelWithDict()
        //        User.modelWithJSONString()
        //        StaticMappableDemo()
        //        ObjectMapperDemoFunc1()
        
    }
}

