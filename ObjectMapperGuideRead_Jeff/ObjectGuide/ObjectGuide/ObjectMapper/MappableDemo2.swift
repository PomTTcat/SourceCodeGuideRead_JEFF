
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



func ObjectMapperModelToJSON() {
    let lilei = UserNew()
    lilei.username = "李雷"
    lilei.birthday = Date()
    
    // model -> dict
    let json = lilei.toJSON()
    // "{\"birthday\":1562122283.4608941,\"username\":\"李雷\"}"
    print(json)
}
