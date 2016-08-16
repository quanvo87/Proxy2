//
//  ProxyNameGenerator.swift
//  proxy
//
//  Created by Quan Vo on 8/16/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit

class ProxyNameGenerator: NSObject {
    
    private var adjectives = [String]()
    private var nouns = [String]()
    
    override init() {
        super.init()
        
        adjectives = ["awesome", "big", "blessed", "brave", "charming", "chubby", "clean", "cold", "cool", "cute", "dirty", "easy", "epic", "evil", "fancy", "fast", "fat", "fearless", "fine", "flirty", "fresh", "gentle", "gold", "happy", "heavy", "holy", "hot", "hungry", "insane", "joyful", "lean", "loose", "loyal", "lucky", "major", "mega", "mild", "mystic", "nice", "noble", "odd", "perfect", "playful", "prime", "pro", "proud", "quiet", "rich", "rough", "royal", "rude", "sacred", "sassy", "savage", "shiny", "silver", "slow", "small", "smart", "smooth", "spicy", "super", "sweet", "tender", "thirsty", "tough", "wet", "wild", "wise", "young"]
        
        nouns = ["angel", "babe", "baby", "bacon", "bandit", "bear", "beast", "blade", "bunny", "cat", "champ", "champion", "crab", "crush", "dancer", "darling", "demon", "dog", "dork", "dove", "dragon", "drake", "fairy", "flirt", "flower", "fox", "frog", "genius", "ghost", "goat", "god", "hawk", "hero", "honey", "hunter", "icon", "kid", "king", "kisser", "kitty", "lion", "master", "model", "money", "monster", "moon", "ninja", "nova", "ocean", "panda", "penguin", "piggy", "pirate", "pizza", "player", "poet", "punk", "pup", "puppy", "rabbit", "rose", "savage", "shark", "sheep", "singer", "smile", "song", "soul", "squirt", "star", "sushi", "swan", "sword", "thief", "thug", "thunder", "tiger", "tuna", "villain", "waffle", "whale", "wolf", "zombie"]
    }
    
    func generateProxyName() -> String {
        let adjectivesCount = UInt32(adjectives.count)
        let nounsCount = UInt32(nouns.count)
        
        let randomAdjective = adjectives[Int(arc4random_uniform(adjectivesCount))]
        let randomNoun = nouns[Int(arc4random_uniform(nounsCount))]
        
        let endingNumber = String(Int(arc4random_uniform(1000)))
        
        return randomAdjective + randomNoun.capitalizedString + endingNumber
    }
}