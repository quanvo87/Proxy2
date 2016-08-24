//
//  SideBarItem.swift
//  proxy
//
//  Created by Quan Vo on 8/20/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct SideBarItem {
    
    private var _title = ""
    
    init(title: String) {
        _title = title
    }
    
    var title: String {
        return _title
    }
}