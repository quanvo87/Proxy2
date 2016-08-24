//
//  ProxyNameGenerator.swift
//  proxy
//
//  Created by Quan Vo on 8/23/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct ProxyNameGenerator {
    
    private let endingNumberRange: UInt32 = 100
    private var adjectives: [String]?
    private var nouns: [String]?
    private var _wordBankLoaded = false
    
    init() {
        let url = NSURL(string: "https://api.myjson.com/bins/1l0zf")!
        let urlRequest = NSMutableURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(urlRequest) {
            (data, response, error) -> Void in
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            if statusCode == 200 {
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                    if let adjectives = json["adjectives"] as? [String] {
                        self.adjectives = adjectives
                    }
                    if let nouns = json["nouns"] as? [String] {
                        self.nouns = nouns
                    }
                    self._wordBankLoaded = true
                } catch {
                    print("Error with JSON: \(error)")
                }
            } else {
                print("Error fetching words JSON: \(error)")
            }
        }
        task.resume()
    }
    
    var wordBankLoaded: Bool {
        return _wordBankLoaded
    }
    
    func generateProxyName() -> String {
        let adjectivesCount = UInt32(adjectives!.count)
        let nounsCount = UInt32(nouns!.count)
        
        let randomAdjective = adjectives![Int(arc4random_uniform(adjectivesCount))].lowercaseString
        let randomNoun = nouns![Int(arc4random_uniform(nounsCount))].lowercaseString.capitalizedString
        
        let endingNumber = String(Int(arc4random_uniform(endingNumberRange)))
        
        return randomAdjective + randomNoun + endingNumber
    }
}