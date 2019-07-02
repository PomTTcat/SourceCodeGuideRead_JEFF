
/*
 Swift - 使用ObjectMapper实现模型转换1
 http://www.hangge.com/blog/cache/detail_1673.html
 */

import Foundation


class User: Mappable {
    var username: String?
    var age: Int?
    var weight: Double!
    var bestFriend: User?        // User对象
    var friends: [User]?         // Users数组
    var birthday: Date?
    var array: [AnyObject]?
    var dictionary: [String : AnyObject] = [:]
    
    init(){
    }
    
    required init?(map: Map) {
        // 在对象序列化之前验证 JSON 合法性。在不符合的条件时，返回 nil 阻止映射发生。
        if map.JSON["username"] == nil {
            return nil
        }
        
        /*
         let json = "[{\"age\":18,\"username\":\"李雷\"},{\"age\":17}]"
         let users:[User] = Mapper<User>().mapArray(JSONString: json)!
         print(users.count) // 1
         */
    }
    
    // Mappable
    func mapping(map: Map) {
        username    <- map["username"]
        age         <- map["age"]
        weight      <- map["weight"]
        bestFriend  <- map["best_friend"]
        friends     <- map["friends"]
        birthday    <- (map["birthday"], DateTransform())
        array       <- map["arr"]
        dictionary  <- map["dict"]
    }
    
    //MARK: Model -> Dictionary
    class func modelWithDict() {
        let lilei = User()
        lilei.username = "李雷"
        lilei.age = 18
        
        let meimei = User()
        meimei.username = "梅梅"
        meimei.age = 17
        meimei.bestFriend = lilei
        
//        // model -> dict
//        let meimeiDic:[String: Any] = meimei.toJSON()
//        print("meimeiDic\n \(meimeiDic)")
//
//        // [model] -> [dict]
//        let users = [lilei, meimei]
//        let usersArray:[[String: Any]]  = users.toJSON()
//        print("usersArray\n \(usersArray)")
        
        
        let dic = ["age": 17, "best_friend": ["dict": [:], "age": 18, "username": "李雷"], "username": "梅梅", "dict": [:]] as [String : Any]
        
        // dict -> model
        let meimeiModel = User(JSON: dic)
        print("meimeiModel\n \(String(describing: meimeiModel))")
        
        // [dict] -> [model]
//        let usersArray2:[User] = Mapper<User>().mapArray(JSONArray: usersArray)
//        print("usersArray2\n \(String(describing: usersArray2))")
    }
    
    //MARK: Model -> JSONString
    class func modelWithJSONString() {
        
        let lilei = User()
        lilei.username = "李雷"
        lilei.age = 18
        
        let meimei = User()
        meimei.username = "梅梅"
        meimei.age = 17
        meimei.bestFriend = lilei
        
        // model to json string
        let meimeiJSON:String = meimei.toJSONString()!
        print(meimeiJSON)
        
        // [model] to json string
        let users = [lilei, meimei]
        let json:String  = users.toJSONString()!
        print(json)
        
        // json string to model
        let meimei2 = User(JSONString: meimeiJSON)
        print(meimei2)
        
        // json string to [model]
        let users2:[User] = Mapper<User>().mapArray(JSONString: json)!
        print(users2)
    }
}
