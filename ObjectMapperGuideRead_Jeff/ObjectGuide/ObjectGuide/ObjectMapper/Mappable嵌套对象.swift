//
//  Mappable高级用法.swift
//  ObjectGuide
//
//  Created by PomCat on 2019/7/3.
//  http://www.hangge.com/blog/cache/detail_1675.html

import Foundation

class highLevelModel: Mappable {
    var type: String?
    var distanceType1: Int?
    var distanceType2: Int?
    var distanceType3: Int?
    var distanceType4: Int?
    
    required init?(map: Map) { }
    
    // Mappable
    func mapping(map: Map) {
        type                <- map["type"]
        
        // 嵌套对象
        distanceType1       <- map["distanceType1.value"]                 // 默认分隔符"."
        distanceType2       <- map["distanceType2.0.value"]               // 数组 + 分隔符
        distanceType3       <- map["distanceType3.value",nested: false]   // 忽略分隔符
        
        // 遇到属性中本来就有"."，需要自定义分隔符
        distanceType4       <- map["distanceType4.Test->com.google.version", delimiter: "->"]
    }
}

func highLevelModelDemo() {
    let str = HLMString()
    
    let HLMModel = highLevelModel(JSONString: str)
    
    print("HLMModel\n \(String(describing: HLMModel))")
}

private func HLMString() -> String {

    return """
    {
        "type": "Jeff",
        "distanceType1": {
            "text": "104 ft",
            "value": 91
        },
        "distanceType2": [{
        "text": "104 ft",
        "value": 92
        },
        {
        "text": "102 ft",
        "value": 31
        }
        ],
        "distanceType3.value": 93,
        "distanceType4.Test": {
            "com.google.name": "GYJ",
            "com.google.version": 94
        }
    }
    """

}
