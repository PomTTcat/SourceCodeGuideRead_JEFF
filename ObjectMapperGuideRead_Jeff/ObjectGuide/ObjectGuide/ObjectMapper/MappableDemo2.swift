
import Foundation

class UserNew: Mappable {
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



func ObjectMapperDemoFunc1() {
    let lilei = UserNew()
    lilei.username = "李雷"
    lilei.birthday = Date()
    
    let json = lilei.toJSONString()!
    // "{\"birthday\":1562122283.4608941,\"username\":\"李雷\"}"
    print(json)
}
