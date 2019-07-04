//
//  ImmutableMappableDemo.swift
//  ObjectGuide
//
//  Created by PomCat on 2019/7/3.
//

import Foundation

// ImmutableMappable 这些属性是只读的，因为赋值只发生在init之中。
class immutModel: ImmutableMappable {
    
    let id: Int
    let name: String?
    
    // 为什么可能throws？因为里面的用可能有throws没有处理。
    required init(map: Map) throws {
        
        // 这里是最大的不同。 普通mappable是走操作符"<-" ，ImmutableMappable是直接赋值。
        // 此处的属性都是常量，所以只能用直接复制，不能用操作符。
        
        // 官方推荐方法
        id   = try map.value("id")
        name = try? map.value("name")
        
        // 错误示范
        // id   <- map["id"] // 为什么这种就报错，self.id 还没有被初始化。因为常量是不能被引用的（inout）！只能直接赋值。
        //Constant 'self.id' passed by reference before being initialized
        
        
        // 另类赋值方法
//        var s:Int = 0
//        s <- map["id"]
//        id = s
    }
    
    func mapping(map: Map) {
        id   >>> map["id"]
        name >>> map["name"]
    }

}

func ImmutableMappableDemo() {
    
    let dic = ["id": 15,
               "name": "李雷",
               ] as [String : Any]
    
    // dict -> model
    let mm = try! immutModel(JSON: dic)
    
    // model -> dict
    let dic2 = mm.toJSON()
    print("meimeiModel\n \(String(describing: mm)) -- \(dic2)")
    
}
