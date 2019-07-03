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
    
    // 已下属性用于触发 value<T>() 中三种特殊情况
    var hairLong: Float?
    var hairLongs: [Float]?
    var testProperty: [String:Float]?
    
    // init 方法被调用。就会完成对象初始化
    required init?(map: Map) {
        // 1.可以在里面做一些判断，比如用户名没有，就返回空，后续不用处理了。
        // 2.也可以在这里添加一些自定义属性。比如有时候后端接口不一致。 这个接口的"all"是字符串，有些返回的是数字。你可以把数字处理成字符串。
        if map.JSON["username"] == nil {
            return nil
        }
    }
    
    func mapping(map: Map) {
        username        <- map["username"]
        age             <- map["age"]
        hairLong        <- map["hairLong"]
        hairLongs       <- map["hairLongs"]
        testProperty    <- map["testProperty"]
    }
}

func MappableDemo() {
    let dic = ["age": 17,
               "username": "李雷",
               
               "hairLong": 5.3,
               "hairLongs" : [4.1,2.1,231.1],
               "testProperty" : ["no1":1.1,"no2":1.2],
               
        ] as [String : Any]
    
    // dict -> model
    let meimeiModel = EasyUser(JSON: dic)
    
    print("meimeiModel\n \(String(describing: meimeiModel))")
}
