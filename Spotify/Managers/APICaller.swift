//
//  APICaller.swift
//  Spotify
//
//  Created by Mounika Madishetti on 31/07/21.
//

import Foundation

final class APICaller {
    static let shared = APICaller()
    private init() {}
    
    struct Constants {
        static let baseAPIURL = "https://api.spotify.com/v1"
    }
    
    enum APIError: Error {
        case failedToGetData
    }
    
    public func getCurrentUserProfile(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/me"), type: .GET) { baseRequest in
            URLSession.shared.dataTask(with: baseRequest) { (data, response, error) in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let json = try JSONDecoder().decode(UserProfile.self, from: data)
                    print("SUCCESS: \(json)")
                    completion(.success(json))
                } catch let error {
                    print(error)
                    completion(.failure(APIError.failedToGetData))
                }
                
            }.resume()
        }
    }
    enum HTTPMethod: String {
        case GET
        case POST
    }
    private func createRequest(with url: URL?,type: HTTPMethod, completion: @escaping (URLRequest) -> Void) {
        AuthManager.shared.withValidToken { token in
            guard let url = url else { return }
            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpMethod = type.rawValue
            request.timeoutInterval = 30
            completion(request)
        }
    }
}
