//
//  TabViewModel.swift
//  AgribusinessNewsApp
//
//  Created on 30 November 2025.
//

import Foundation

class TabViewModel: ObservableObject {
    @Published var homeWebViewModel = WebViewModel(urlString: "https://agribusinessmedia.com")
    @Published var newsWebViewModel = WebViewModel(urlString: "https://agribusinessmedia.com/news")
    @Published var magazinesWebViewModel = WebViewModel(urlString: "https://agribusinessmedia.com/magazines")
}
