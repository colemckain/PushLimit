import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    case serverError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        case .serverError(let message):
            return message
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

class NetworkService {
    static let shared = NetworkService()
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Generic Request Method
    func request<T: Codable>(_ endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        guard let url = URL(string: endpoint.url) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add body if needed
        if let body = endpoint.body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.serverError("Invalid response")
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw NetworkError.serverError("HTTP \(httpResponse.statusCode)")
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(T.self, from: data)
                return decodedResponse
            } catch {
                throw NetworkError.decodingError
            }
        } catch {
            throw NetworkError.networkError(error)
        }
    }
}

// MARK: - API Endpoint Protocol
protocol APIEndpoint {
    var url: String { get }
    var method: HTTPMethod { get }
    var body: [String: Any]? { get }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

// MARK: - Codable Extension
extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NetworkError.decodingError
        }
        return dictionary
    }
} 