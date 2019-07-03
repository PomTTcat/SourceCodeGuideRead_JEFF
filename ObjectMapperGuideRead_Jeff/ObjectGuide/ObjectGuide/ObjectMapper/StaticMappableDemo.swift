
//  http://www.hangge.com/blog/cache/detail_1674.html

import Foundation

class Vehicle: StaticMappable {
    //类型
    var type: String?
    
    // 依据type属性获取相应的映射对象。（用不同的对象去映射，去初始化）
    class func objectForMapping(map: Map) -> BaseMappable? {
        if let type: String = map["type"].value() {
            switch type {
            case "car":
                return Car()
            case "bus":
                return Bus()
            default:
                return Vehicle()
            }
        }
        return nil
    }
    
    // 这个是默认的init方法。如果想和Mappable一样走 init?(map: Map) 方法。在objectForMapping指定init方法即可。
    init(){
        
    }
    
    func mapping(map: Map) {
        type <- map["type"]
    }
}

//小汽车
class Car: Vehicle {
    //名字
    var name: String?
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        name <- map["name"]
    }
}

//公交车
class Bus: Vehicle {
    //费用
    var fee: Int?
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        fee <- map["fee"]
    }
}

func StaticMappableDemo() {
    StaticMappableDemo1()

}

func StaticMappableDemo1() {
    let JSON = ["type": "car", "name": "奇瑞QQ"]
    
    // 观察objectForMapping方法。
    let car = Car(JSON: JSON)
    
    print(car)
}


