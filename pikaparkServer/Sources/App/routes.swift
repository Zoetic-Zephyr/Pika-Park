import Routing
import Vapor

/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ router: Router) throws {
    router.get("spot",String.parameter,Double.parameter,Double.parameter,Int.parameter) { req -> String in
        
        let userN = try req.parameters.next(String.self)
        print("Driver Name: \(userN)")
        let x = try req.parameters.next(Double.self)
        print("Coordinate X: \(x)")
        let y = try req.parameters.next(Double.self)
        print("Coordinate Y: \(y)")
        let price = try req.parameters.next(Int.self)
        print("Price: \(price)")
        
        
        //two side matching algorithm
        
        
        //get result
        let pX = 23424563.2323
        let pY = 52345262.2134
        
        return "Dear \(userN), Pika Park has received your request! Your assigned parking spot is \(pX), \(pY)."
    }
}
