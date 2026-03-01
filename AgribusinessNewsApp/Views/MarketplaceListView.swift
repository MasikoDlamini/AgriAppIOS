// Helper to fetch WordPress media image URL by media ID
extension MarketplaceListView {
    static func fetchFeaturedImageUrl(mediaId: Int, completion: @escaping (URL?) -> Void) {
        let url = URL(string: "https://agribusinessmedia.com/wp-json/wp/v2/media/\(mediaId)")!
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("[DEBUG] Error fetching media: \(error)")
            }
            guard let data = data else {
                print("[DEBUG] No data returned from media endpoint.")
                completion(nil)
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("[DEBUG] Media JSON: \(json)")
                if let sourceUrl = json["source_url"] as? String, let imageUrl = URL(string: sourceUrl) {
                    completion(imageUrl)
                } else {
                    print("[DEBUG] No source_url found in media JSON.")
                    completion(nil)
                }
            } else {
                print("[DEBUG] Could not parse media JSON.")
                completion(nil)
            }
        }.resume()
    }
}

import SwiftUI


struct MarketplaceListView: View {
    @StateObject private var apiService = MarketplaceAPIService()
    @State private var selectedListing: MarketplaceAPIListing?
    @State private var showUpload = false
    
    var body: some View {
        VStack {
            if apiService.isLoading {
                ProgressView("Loading listings...")
                    .padding()
            } else if apiService.listings.isEmpty {
                Text("No listings available.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List(apiService.listings, id: \.id) { listing in
                    Button(action: { selectedListing = listing }) {
                        VStack(alignment: .leading) {
                            Text(listing.title.rendered)
                                .font(.headline)
                            Text(listing.content.htmlStripped)
                                .font(.subheadline)
                                .lineLimit(2)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            Spacer()
            Button(action: { showUpload = true }) {
                Label("Add Listing", systemImage: "plus")
                    .padding()
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.bottom)
        }
        .navigationTitle("Marketplace")
        .onAppear { apiService.fetchListings() }
        .sheet(isPresented: $showUpload) {
            MarketplaceUploadView()
        }
        .sheet(item: $selectedListing) { listing in
            MarketplaceListingDetailView(listing: listing)
        }
        // You can implement a detail view for API listings if needed
    }
    
    // Simple detail view for a listing
    struct MarketplaceListingDetailView: View {
        let listing: MarketplaceAPIListing
        @State private var imageUrls: [URL] = []

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Show all uploaded images or fallback to featured image
                    if !imageUrls.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(imageUrls, id: \ .self) { url in
                                    AsyncImage(url: url) { image in
                                        image.resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 120, height: 120)
                                            .clipped()
                                            .cornerRadius(16)
                                    } placeholder: {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.gray.opacity(0.2))
                                                .frame(width: 120, height: 120)
                                            Image(systemName: "photo")
                                                .font(.system(size: 32))
                                                .foregroundColor(.gray)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        // Fallback: Show featured image if available
                        if let mediaId = listing.featuredMedia {
                            FeaturedImageView(mediaId: mediaId)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 180)
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    // ...existing code...
                    Text(listing.title.rendered)
                        .font(.system(size: 32, weight: .bold))
                        .padding(.top, 8)

                    if let meta = listing.meta {
                        if let price = meta.price, !price.isEmpty {
                            Text("Price: \(price)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                                .padding(.vertical, 2)
                        }
                        if let category = meta.category, !category.isEmpty {
                            HStack {
                                Text("Category:")
                                    .fontWeight(.medium)
                                Text(category)
                            }
                            .font(.body)
                        }
                        if let location = meta.location, !location.isEmpty {
                            HStack {
                                Text("Location:")
                                    .fontWeight(.medium)
                                Text(location)
                            }
                            .font(.body)
                        }
                        if let email = meta.email, !email.isEmpty {
                            HStack {
                                Text("Email:")
                                    .fontWeight(.medium)
                                Text(email)
                            }
                            .font(.body)
                        }
                        if let cellphone = meta.cellphone_, !cellphone.isEmpty {
                            HStack {
                                Text("Cellphone:")
                                    .fontWeight(.medium)
                                Text(cellphone)
                            }
                            .font(.body)
                        }
                    }

                    if !listing.content.htmlStripped.isEmpty {
                        Divider().padding(.vertical, 8)
                        Text(listing.content.htmlStripped)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .onAppear {
                    // Debug: Print the featuredMedia ID and meta.images
                    print("[DEBUG] featuredMedia ID: \(String(describing: listing.featuredMedia))")
                    print("[DEBUG] meta.images: \(String(describing: listing.meta?.images))")
                    // Fetch all image URLs
                    let imageIDs = listing.meta?.images ?? []
                    if !imageIDs.isEmpty {
                        var urls: [URL] = []
                        let group = DispatchGroup()
                        for mediaId in imageIDs {
                            group.enter()
                            MarketplaceListView.fetchFeaturedImageUrl(mediaId: mediaId) { url in
                                if let url = url {
                                    urls.append(url)
                                }
                                group.leave()
                            }
                        }
                        group.notify(queue: .main) {
                            imageUrls = urls
                        }
                    } else if let mediaId = listing.featuredMedia {
                        MarketplaceListView.fetchFeaturedImageUrl(mediaId: mediaId) { url in
                            if let url = url {
                                imageUrls = [url]
                            }
                        }
                    }
                }
            }
        }

        // Helper view for featured image
        struct FeaturedImageView: View {
            let mediaId: Int
            @State private var url: URL?
            var body: some View {
                Group {
                    if let url = url {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 180)
                                .clipped()
                                .cornerRadius(16)
                        } placeholder: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 180)
                                Image(systemName: "photo")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray)
                            }
                        }
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 180)
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .onAppear {
                    MarketplaceListView.fetchFeaturedImageUrl(mediaId: mediaId) { fetchedUrl in
                        url = fetchedUrl
                    }
                }
            }
        }
    }
    // You can implement a detail view for MarketplaceAPIListing if needed
    
    struct MarketplaceListView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationView {
                MarketplaceListView()
            }
        }
    }
    
}
