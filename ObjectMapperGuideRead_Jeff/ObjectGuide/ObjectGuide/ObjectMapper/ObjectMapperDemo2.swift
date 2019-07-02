
//  http://www.hangge.com/blog/cache/detail_1674.html

import Foundation


//交通工具
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
    let JSON = [["type": "car", "name": "奇瑞QQ"],
                ["type": "bus", "fee": 2],
                ["type": "vehicle"]]
//    /Users/guanyujie/Library/Mobile Documents/com~apple~CloudDocs/HXYL/qubeiThirdPart/qubeiThirdPart/ObjectMapper/ObjectMapperDemo2.swift:67:8: Initializer for conditional binding must have Optional type, not '[Vehicle]'
    
    let vehicles = Mapper<Vehicle>().mapArray(JSONArray: JSON)
    
    print("交通工具数量：\(vehicles.count)")
    if let car = vehicles[0] as? Car {
        print("小汽车名字：\(car.name!)")
    }
    if let bus = vehicles[1] as? Bus {
        print("公交车费用：\(bus.fee!) 元")
    }
   
}
