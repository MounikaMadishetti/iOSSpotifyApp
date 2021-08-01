//
//  AuthManager.swift
//  Spotify
//
//  Created by Mounika Madishetti on 31/07/21.
//

import Foundation
final class AuthManager {
    static let shared = AuthManager()
    private init() {}
    var refreshingToken = false
    struct Constants {
        static let clientID = "f05bc0a839b9437d8acb45367083c975"
        static let clientSecret = "37a5d8a9c02d4ea68ea318eaf05132d0"
        static let tokenAPIURL = "https://accounts.spotify.com/api/token"
        static let redirectURI = "https://www.iosacademy.io"
        static let scopes = "user-read-private%20playlist-modify-public%20playlist-read-private%20playlist-modify-private%20user-follow-read%20user-library-modify%20user-library-read%20user-read-email"
    }
    public var signInURL: URL? {
       
       
        let base = "https://accounts.spotify.com/authorize"
        let string = "\(base)?response_type=code&client_id=\(Constants.clientID)&scope=\(Constants.scopes)&redirect_uri=\(Constants.redirectURI)&show_dialog=true"
          
        return URL(string: string)
    }
    var isSignedIn: Bool {
        return accessToken != nil
    }
    private var accessToken: String? {
        return UserDefaults.standard.string(forKey: "access_token")
    }
    private var refreshToken: String? {
        return UserDefaults.standard.string(forKey: "refresh_token")
    }
    private var tokenExpirationDate: Date? {
        return  UserDefaults.standard.object(forKey: "expirationDate") as? Date
    }
    private var shouldRefreshToken: Bool {
        guard let expirationDate = tokenExpirationDate else { return false }
        let currentDate = Date()
        let fiveMins: TimeInterval = 300
        return currentDate.addingTimeInterval(fiveMins) >= expirationDate
    }
    public func exchangeCodeForToken(code: String, completion: @escaping ((Bool) -> Void)) {
        //get token
        guard let url = URL(string: Constants.tokenAPIURL) else {
            completion(false)
            return
            
        }
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI)
            
        ]
        let basicToken = Constants.clientID+":"+Constants.clientSecret
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpBody = components.query?.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            guard let data = data, error == nil else {
                completion(false)
                return
            }
            do {
                let json = try JSONDecoder().decode(AuthResponse.self, from: data)
                print("SUCCESS: \(json)")
                self?.cacheToken(result: json)
                completion(true)
                
                
            } catch {
                print(error.localizedDescription)
                completion(false)
            }
            
        }.resume()
        
        
        
    }
    private var onRefreshBlocks = [((String) -> Void)]()
    //supplies valid token to be used with api calls
    public func withValidToken(completion: @escaping (String) -> Void) {
        guard !refreshingToken else {
            //append the completion
            onRefreshBlocks.append(completion)
            return
        }
        if shouldRefreshToken {
            refreshAccessTokenIfNeeded { [weak self] success in
                if success {
                    if let token = self?.accessToken {
                        completion(token)
                    }
                    
                }
            }
        } else if let token = accessToken {
            completion(token)
        }
        
        
    }
    public func refreshAccessTokenIfNeeded(completion: @escaping (Bool) -> Void) {
        guard !refreshingToken else {
            return
        }
        guard shouldRefreshToken else {
            return
        }
        guard let refreshToken = self.refreshToken else {
            return
            
        }
        //refresh the token
        refreshingToken = true
        guard let url = URL(string: Constants.tokenAPIURL) else {
            completion(false)
            return
            
        }
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI)
            
        ]
        let basicToken = Constants.clientID+":"+Constants.clientSecret
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpBody = components.query?.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            self?.refreshingToken = false
            guard let data = data, error == nil else {
                completion(false)
                return
            }
            do {
                let json = try JSONDecoder().decode(AuthResponse.self, from: data)
                print("SUCCESS REFRESH: \(json)")
                self?.onRefreshBlocks.forEach { $0(json.access_token) }
                self?.onRefreshBlocks.removeAll()
                self?.cacheToken(result: json)
                completion(true)
                
                
            } catch {
                print(error.localizedDescription)
                completion(false)
            }
            
        }.resume()
        
    }
    private func cacheToken(result: AuthResponse) {
        UserDefaults.standard.setValue(result.access_token, forKey: "access_token")
        if let refresh = result.refresh_token {
        UserDefaults.standard.setValue(refresh, forKey: "refresh_token")
        }
        UserDefaults.standard.setValue(Date().addingTimeInterval(TimeInterval(result.expires_in)), forKey: "expirationDate")
    }
}
