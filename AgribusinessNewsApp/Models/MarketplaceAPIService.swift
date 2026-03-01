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
    let embedded: MarketplaceEmbedded?

    enum CodingKeys: String, CodingKey {
        case id, title, content, meta, date, status
        case featuredMedia = "featured_media"
        case embedded = "_embedded"
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
        embedded = try? container.decode(MarketplaceEmbedded.self, forKey: .embedded)
    }
    
    /// Returns the featured image URL from _embedded data (most reliable)
    var featuredImageUrl: String? {
        if let media = embedded?.featuredMedia?.first {
            // Prefer medium_large or large for performance
            if let mediumLarge = media.mediaDetails?.sizes?.mediumLarge?.sourceUrl {
                return mediumLarge
            }
            if let large = media.mediaDetails?.sizes?.large?.sourceUrl {
                return large
            }
            if let medium = media.mediaDetails?.sizes?.medium?.sourceUrl {
                return medium
            }
            return media.sourceUrl
        }
        return nil
    }
}

// MARK: - Embedded media from _embed
struct MarketplaceEmbedded: Codable {
    let featuredMedia: [MarketplaceMediaItem]?
    
    enum CodingKeys: String, CodingKey {
        case featuredMedia = "wp:featuredmedia"
    }
}

struct MarketplaceMediaItem: Codable {
    let id: Int?
    let sourceUrl: String?
    let mediaDetails: MarketplaceMediaDetails?
    
    enum CodingKeys: String, CodingKey {
        case id
        case sourceUrl = "source_url"
        case mediaDetails = "media_details"
    }
}

struct MarketplaceMediaDetails: Codable {
    let sizes: MarketplaceMediaSizes?
}

struct MarketplaceMediaSizes: Codable {
    let medium: MarketplaceMediaSize?
    let mediumLarge: MarketplaceMediaSize?
    let large: MarketplaceMediaSize?
    let full: MarketplaceMediaSize?
    
    enum CodingKeys: String, CodingKey {
        case medium
        case mediumLarge = "medium_large"
        case large, full
    }
}

struct MarketplaceMediaSize: Codable {
    let sourceUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case sourceUrl = "source_url"
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
        // Use _embed to get featured image URLs directly in the response
        guard let url = URL(string: baseURL + "?status=publish&_embed=true") else { return }
        DispatchQueue.main.async {
            self.isLoading = true
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }
            guard let data = data, error == nil else { return }
            do {
                // Don't use convertFromSnakeCase — CodingKeys handle it explicitly
                let decoder = JSONDecoder()
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
