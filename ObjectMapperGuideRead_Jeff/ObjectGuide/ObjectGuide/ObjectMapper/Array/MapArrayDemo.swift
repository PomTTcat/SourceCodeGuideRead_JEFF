//
//  MapArrayDemo.swift
//  ObjectGuide
//
//  Created by PomCat on 2019/7/3.
//

import Foundation

func MapArrayDemo() {
    let JSON = [["type": "car", "name": "奇瑞QQ"],
                ["type": "bus", "fee": 2],
                ["type": "vehicle"]]
    
    // 对每个对象进行map
    let vehicles = Mapper<Vehicle>().mapArray(JSONArray: JSON)
    
    print("交通工具数量：\(vehicles.count)")
    if let car = vehicles[0] as? Car {
        print("小汽车名字：\(car.name!)")
    }
    if let bus = vehicles[1] as? Bus {
        print("公交车费用：\(bus.fee!) 元")
    }
    
}
