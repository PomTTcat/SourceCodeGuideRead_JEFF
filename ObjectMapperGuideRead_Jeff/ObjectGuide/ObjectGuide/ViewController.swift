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
//        MappableDemo()
//        StaticMappableDemo()
        
        // 数组使用
//        MapArrayDemo()
        
        // 嵌套对象使用
//        highLevelModelDemo()
        
        // transformOf使用
//        transformOfDemo()
        
//        ImmutableMappableDemo()
        
        // 普通模型转字典
        ObjectMapperModelToJSON()
    }
}

