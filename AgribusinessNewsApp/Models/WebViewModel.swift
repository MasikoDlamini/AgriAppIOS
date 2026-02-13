//
//  WebViewModel.swift
//  AgribusinessNewsApp
//
//  Created on 29 November 2025.
//

import Foundation
import Combine

class WebViewModel: ObservableObject {
    @Published var urlString: String
    @Published var isLoading = false
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var shouldGoBack = false
    @Published var shouldGoForward = false
    @Published var shouldReload = false
    
    init(urlString: String = "https://agribusinessmedia.com") {
        self.urlString = urlString
    }
    
    func goBack() {
        shouldGoBack = true
    }
    
    func goForward() {
        shouldGoForward = true
    }
    
    func reload() {
        shouldReload = true
    }
}
