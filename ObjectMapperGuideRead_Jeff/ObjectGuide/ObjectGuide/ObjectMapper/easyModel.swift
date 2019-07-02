//
//  easyModel.swift
//  ObjectGuide
//
//  Created by PomCat on 2019/6/27.
//

import Foundation

class EasyUser: Mappable {

    var username: String?
    var age: Int?
    
    required init?(map: Map) {
        // 1.可以在里面做一些判断，比如用户名没有，就返回空，后续不用处理了。
        // 2.也可以在这里添加一些自定义属性。比如有时候后端接口不一致。 这个接口的"all"是字符串，有些返回的是数字。你可以把数字处理成字符串。
//        map.JSON["newProperty"] = "marry"
        if map.JSON["username"] == nil {
            return nil
        }
    }
    
    func mapping(map: Map) {
        username    <- map["username"]
        age         <- map["age"]
    }
    
    class func modelWithDict() {
        let dic = ["age": 17, "username": "李雷"] as [String : Any]
        
        let d = man()
        let x = d as human
        // dict -> model
        let meimeiModel = EasyUser(JSON: dic)
        
        var ss = 5
//        ss <- 3;
//        print("meimeiModel\n \(String(describing: meimeiModel))")
    }
}

class human {
    
}

class man: human {
    
}
