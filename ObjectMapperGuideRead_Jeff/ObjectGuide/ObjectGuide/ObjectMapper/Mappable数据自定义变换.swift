//
//  Mappable数据自定义变换.swift
//  ObjectGuide
//
//  Created by PomCat on 2019/7/3.
//

import Foundation

fileprivate class User2: Mappable {
    var username: String?
    var birthday: Date?
    
    init(){
    }
    
    required init?(map: Map) {
    }
    
    // Mappable
    func mapping(map: Map) {
        username    <- map["username"]
        birthday    <- (map["birthday"], DateTransform())
    }
}

func transformOfDemo() {
    let lilei = User2()
    lilei.username = "李雷"
    lilei.birthday = Date()
    
    let json = lilei.toJSONString()!
    
    let li = User2(JSONString: json)
    
    print(json)
}


