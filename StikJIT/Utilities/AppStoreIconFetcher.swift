//
//  AppStoreIconFetcher.swift
//  StikJIT
//
//  Created by neoarz on 3/28/25.
//

import UIKit

class AppStoreIconFetcher {
    static private var iconCache: [String: UIImage] = [:]
    
    static func getIcon(for bundleID: String, completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cachedIcon = iconCache[bundleID] {
            completion(cachedIcon)
            return
        }
        
        // Hit the App Store API
        let baseURLString = "https://itunes.apple.com/lookup?bundleId="
        let urlString = baseURLString + bundleID
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   !results.isEmpty,
                   let firstApp = results.first,
                   let iconURLString = firstApp["artworkUrl512"] as? String ?? firstApp["artworkUrl100"] as? String,
                   let iconURL = URL(string: iconURLString) {
                    
                    // Download the icon image
                    downloadImage(from: iconURL) { image in
                        if let image = image {
                            // Cache the icon
                            iconCache[bundleID] = image
                        }
                        DispatchQueue.main.async {
                            completion(image)
                        }
                    }
                } else {
                    DispatchQueue.main.async { completion(nil) }
                }
            } catch {
                DispatchQueue.main.async { completion(nil) }
            }
        }.resume()
    }
    
    private static func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
} 