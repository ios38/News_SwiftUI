//
//  NewsAPI.swift
//  News
//
//  Created by Maksim Romanov on 28.05.2021.
//

import Foundation
import Combine

struct APIConstants {
    static let apiKey: String = "6002257cbc2347fb9a7d5d66a3bf6773"
    
    static let jsonDecoder: JSONDecoder = {
     let jsonDecoder = JSONDecoder()
     jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
     let dateFormatter = DateFormatter()
     dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
     jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
      return jsonDecoder
    }()
    
     static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}


enum Endpoint {
    case topHeadLines
    case articlesFromCategory(_ category: String)
    case articlesFromSource(_ source: String)
    case search (searchFilter: String)
    case sources (country: String)
    
    var baseURL:URL {URL(string: "https://newsapi.org/v2/")!}
    
    func path() -> String {
        switch self {
        case .topHeadLines, .articlesFromCategory:
            return "top-headlines"
        case .search,.articlesFromSource:
            return "everything"
        case .sources:
            return "sources"
        }
    }
    
    var absoluteURL: URL? {
        let queryURL = baseURL.appendingPathComponent(self.path())
        let components = URLComponents(url: queryURL, resolvingAgainstBaseURL: true)
        guard var urlComponents = components else {
            return nil
        }
        switch self {
        case .topHeadLines:
            urlComponents.queryItems = [URLQueryItem(name: "country", value: region),
                                        URLQueryItem(name: "apikey", value: APIConstants.apiKey)]
        case .articlesFromCategory(let category):
            urlComponents.queryItems = [URLQueryItem(name: "country", value: region),
                                        URLQueryItem(name: "category", value: category),
                                        URLQueryItem(name: "apikey", value: APIConstants.apiKey)]
        case .sources (let country):
            urlComponents.queryItems = [URLQueryItem(name: "country", value: country),
                                        URLQueryItem(name: "language", value: countryLang[country]),
                                        URLQueryItem(name: "apikey", value: APIConstants.apiKey)]
        case .articlesFromSource (let source):
            urlComponents.queryItems = [URLQueryItem(name: "sources", value: source),
                                        /*  URLQueryItem(name: "language", value: locale),*/
                                        URLQueryItem(name: "apikey", value: APIConstants.apiKey)]
        case .search (let searchFilter):
            urlComponents.queryItems = [URLQueryItem(name: "q", value: searchFilter.lowercased()),
                                        /*URLQueryItem(name: "language", value: locale),*/
                                        /* URLQueryItem(name: "country", value: region),*/
                                        URLQueryItem(name: "apikey", value: APIConstants.apiKey)]
        }
        return urlComponents.url
    }

    init? (index: Int, text: String = "sports") {
        switch index {
        case 0: self = .topHeadLines
        case 1: self = .search(searchFilter: text)
        case 2: self = .articlesFromCategory(text)
        case 3: self = .articlesFromSource(text)
        case 4: self = .sources (country: text)
        default: return nil
        }
    }

    var locale: String {
        return  Locale.current.languageCode ?? "en"
    }
    
    var region: String {
        return  Locale.current.regionCode?.lowercased() ?? "us"
    }
    
    var countryLang : [String: String]  {return [
      "ar": "es",  // argentina
      "au": "en",  // australia
      "br": "es",  // brazil
      "ca": "en",  // canada
      "cn": "cn",  // china
      "de": "de",  // germany
      "es": "es",  // spain
      "fr": "fr",  // france
      "gb": "en",  // unitedKingdom
      "hk": "cn",  // hongKong
      "ie": "en",  // ireland
      "in": "en",  // india
      "is": "en",  // iceland
      "il": "he",  // israil for sources - language
      "it": "it",  // italy
      "nl": "nl",  // netherlands
      "no": "no",  // norway
      "ru": "ru",  // russia
      "sa": "ar",  // saudiArabia
      "us": "en",  // unitedStates
      "za": "en"   // southAfrica
      ]
    }
}

class NewsAPI {
    static let shared = NewsAPI()
    
    // Асинхронная выборка статей
    //func fetchArticles(from endpoint: Endpoint) -> AnyPublisher<[Article], Never> {
    //    guard let url = endpoint.absoluteURL else {
    //        return Just([Article]()).eraseToAnyPublisher()
    //    }
    //    // Returns a publisher that wraps a URL session data task for a given URL request
    //    let dataTaskWrapped = URLSession.shared.dataTaskPublisher(for: url)
    //    let json = dataTaskWrapped.map{ $0.data }
    //    let response = json.decode(type: NewsResponse.self, decoder: APIConstants.jsonDecoder)
    //        //.handleEvents { _ in
    //        //} receiveOutput: { print("newsResponse: \($0.articles)") }
    //    let articles = response.map { $0.articles }
    //
    //    return articles
    //        .replaceError(with:[])
    //        .receive(on: RunLoop.main)
    //        .eraseToAnyPublisher()
    //}

    // Асинхронная выборка статей
    func fetchArticles(from endpoint: Endpoint) -> AnyPublisher<[Article], Never> {
        guard let url = endpoint.absoluteURL else {
            return Just([Article]()).eraseToAnyPublisher()
        }
        return fetch(url)
            .map { (response: NewsResponse) -> [Article] in
                return response.articles }
            .replaceError(with: [Article]())
            .eraseToAnyPublisher()
    }

    // Асинхронная выборка источников
    func fetchSources(for country: String) -> AnyPublisher<[Source], Never> {
        guard let url = Endpoint.sources(country: country).absoluteURL else {
            return Just([Source]()).eraseToAnyPublisher()
        }
        return fetch(url)
            .map { (response: SourcesResponse) -> [Source] in
                response.sources }
            .replaceError(with: [Source]())
            .eraseToAnyPublisher()
    }

    // Асинхронная выборка на основе URL
    func fetch<T: Decodable>(_ url: URL) -> AnyPublisher<T, Error> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data}
            .decode(type: T.self, decoder: APIConstants.jsonDecoder)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

}
