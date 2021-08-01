//
//  Settings.swift
//  Spotify
//
//  Created by Mounika Madishetti on 01/08/21.
//

import Foundation
struct Section {
    let title: String
    let options: [Option]
}
struct Option {
    let title: String
    let handler: () -> Void
}
