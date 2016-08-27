//
//  SettingsItem.swift
//  proxy
//
//  Created by Quan Vo on 8/20/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct SettingsItem {
    
    private let _title: String
    
    init(title: String) {
        _title = title
    }
    
    var title: String {
        return _title
    }
}