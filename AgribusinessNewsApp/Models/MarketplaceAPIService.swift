import Foundation


struct MarketplaceACF: Codable {
    let price: String?
    let location: String?
    let email: String?
    let cellphone_: String?
    let category: String?
    let images: [Int]? // Store image IDs as Int for easier use
}

struct MarketplaceAPIListing: Codable, Identifiable {
    let id: Int
    let title: RenderedText
    let content: RenderedText
    let meta: MarketplaceACF?
    let date: String
    let status: String
    let featuredMedia: Int?

    enum CodingKeys: String, CodingKey {
        case id, title, content, meta, date, status, featuredMedia = "featured_media"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(RenderedText.self, forKey: .title)
        content = try container.decode(RenderedText.self, forKey: .content)
        date = try container.decode(String.self, forKey: .date)
        status = try container.decode(String.self, forKey: .status)
        meta = try? container.decode(MarketplaceACF.self, forKey: .meta)
        featuredMedia = try? container.decode(Int.self, forKey: .featuredMedia)
    }
}

struct RenderedText: Codable {
    let rendered: String

    /// Returns the HTML-stripped version of the rendered string
    var htmlStripped: String {
        rendered.htmlStripped
    }
}

// Helper for decoding dynamic ACF fields
struct AnyCodable: Codable {}

class MarketplaceAPIService: ObservableObject {
    @Published var listings: [MarketplaceAPIListing] = []
    @Published var isLoading = false
    
    let baseURL = "https://agribusinessmedia.com/wp-json/wp/v2/marketplace_listing"
    
    func fetchListings() {
        guard let url = URL(string: baseURL + "?status=publish") else { return }
        DispatchQueue.main.async {
            self.isLoading = true
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            guard let data = data, error == nil else { return }
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let listings = try decoder.decode([MarketplaceAPIListing].self, from: data)
                DispatchQueue.main.async {
                    self.listings = listings
                }
            } catch {
                print("API decode error:", error)
            }
        }.resume()
    }
}
