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
                if let sourceUrl = json["source_url"] as? String, let imageUrl = URL(string: sourceUrl) {
                    completion(imageUrl)
                } else {
                    completion(nil)
                }
            } else {
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
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Marketplace")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("Buy & sell agricultural products")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "cart.fill")
                                .font(.system(size: 36))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        
                        Divider()
                        
                        if apiService.isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading listings...")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(60)
                        } else if apiService.listings.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "storefront")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("No Listings Yet")
                                    .font(.headline)
                                Text("Be the first to list a product!")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(60)
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(apiService.listings, id: \.id) { listing in
                                    Button {
                                        selectedListing = listing
                                    } label: {
                                        MarketplaceGridCard(listing: listing)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(16)
                        }
                    }
                }
                .background(Color(.systemGroupedBackground))
                
                // Floating Add button
                Button(action: { showUpload = true }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.green)
                        .clipShape(Circle())
                        .shadow(color: .green.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
            .onAppear { apiService.fetchListings() }
            .refreshable { apiService.fetchListings() }
            .sheet(isPresented: $showUpload) {
                MarketplaceUploadView()
            }
            .sheet(item: $selectedListing) { listing in
                MarketplaceListingDetailView(listing: listing)
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Grid Card
struct MarketplaceGridCard: View {
    let listing: MarketplaceAPIListing
    @State private var fallbackImageUrl: URL?
    
    private var imageURL: URL? {
        // Prefer embedded featured image (from _embed), then fallback
        if let urlString = listing.featuredImageUrl, let url = URL(string: urlString) {
            return url
        }
        return fallbackImageUrl
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color(.secondarySystemBackground))
                    .frame(height: 150)
                
                if let imageURL = imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 150)
                                .clipped()
                        case .failure:
                            placeholderIcon
                        case .empty:
                            ProgressView()
                        @unknown default:
                            placeholderIcon
                        }
                    }
                    .frame(height: 150)
                } else {
                    placeholderIcon
                }
            }
            .frame(height: 150)
            .clipped()
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title.rendered.htmlStrippedSimple)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let price = listing.meta?.price, !price.isEmpty {
                    Text(price)
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                if let location = listing.meta?.location, !location.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                }
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            // Only fetch fallback if no embedded image
            if listing.featuredImageUrl == nil {
                loadFallbackImage()
            }
        }
    }
    
    private var placeholderIcon: some View {
        VStack(spacing: 6) {
            Image(systemName: "photo")
                .font(.system(size: 30))
                .foregroundColor(.gray.opacity(0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func loadFallbackImage() {
        if let imageIds = listing.meta?.images, let firstId = imageIds.first {
            MarketplaceListView.fetchFeaturedImageUrl(mediaId: firstId) { url in
                DispatchQueue.main.async { self.fallbackImageUrl = url }
            }
        } else if let mediaId = listing.featuredMedia, mediaId > 0 {
            MarketplaceListView.fetchFeaturedImageUrl(mediaId: mediaId) { url in
                DispatchQueue.main.async { self.fallbackImageUrl = url }
            }
        }
    }
}

// Simple HTML stripping helper
private extension String {
    var htmlStrippedSimple: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&#8211;", with: "–")
            .replacingOccurrences(of: "&#8217;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Detail View
struct MarketplaceListingDetailView: View {
    let listing: MarketplaceAPIListing
    @State private var imageUrls: [URL] = []
    @State private var isLoadingImages = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Image Gallery
                    if isLoadingImages {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground))
                                .frame(height: 280)
                            ProgressView()
                        }
                    } else if !imageUrls.isEmpty {
                        TabView {
                            ForEach(imageUrls, id: \.self) { url in
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(height: 280)
                                            .clipped()
                                    case .failure:
                                        imagePlaceholder
                                    case .empty:
                                        ZStack {
                                            Color(.secondarySystemBackground)
                                            ProgressView()
                                        }
                                    @unknown default:
                                        imagePlaceholder
                                    }
                                }
                            }
                        }
                        .frame(height: 280)
                        .tabViewStyle(.page(indexDisplayMode: imageUrls.count > 1 ? .always : .never))
                        .cornerRadius(16)
                    } else {
                        imagePlaceholder
                    }
                    
                    // Title
                    Text(listing.title.rendered.htmlStrippedSimple)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // Price
                    if let price = listing.meta?.price, !price.isEmpty {
                        Text(price)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    Divider()
                    
                    // Meta info
                    if let meta = listing.meta {
                        VStack(alignment: .leading, spacing: 10) {
                            if let category = meta.category, !category.isEmpty {
                                metaRow(icon: "tag.fill", label: "Category", value: category)
                            }
                            if let location = meta.location, !location.isEmpty {
                                metaRow(icon: "mappin.circle.fill", label: "Location", value: location)
                            }
                            if let email = meta.email, !email.isEmpty {
                                metaRow(icon: "envelope.fill", label: "Email", value: email)
                            }
                            if let cellphone = meta.cellphone_, !cellphone.isEmpty {
                                metaRow(icon: "phone.fill", label: "Phone", value: cellphone)
                            }
                        }
                    }
                    
                    // Description
                    if !listing.content.htmlStripped.isEmpty {
                        Divider()
                        
                        Text("Description")
                            .font(.headline)
                        
                        Text(listing.content.htmlStripped)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    // Contact buttons
                    if let meta = listing.meta {
                        Divider()
                        
                        VStack(spacing: 10) {
                            if let cellphone = meta.cellphone_, !cellphone.isEmpty {
                                Link(destination: URL(string: "tel:\(cellphone.replacingOccurrences(of: " ", with: ""))")!) {
                                    HStack {
                                        Image(systemName: "phone.fill")
                                        Text("Call Seller")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                
                                Link(destination: URL(string: "https://wa.me/\(cellphone.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "+", with: ""))")!) {
                                    HStack {
                                        Image(systemName: "message.fill")
                                        Text("WhatsApp")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color(red: 0.07, green: 0.55, blue: 0.23))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                            
                            if let email = meta.email, !email.isEmpty {
                                Link(destination: URL(string: "mailto:\(email)")!) {
                                    HStack {
                                        Image(systemName: "envelope.fill")
                                        Text("Email Seller")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear { loadImages() }
        }
    }
    
    private var imagePlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .frame(height: 280)
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
                Text("No Image")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func metaRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
        }
    }
    
    private func loadImages() {
        // First, use embedded featured image if available
        if let urlString = listing.featuredImageUrl, let url = URL(string: urlString) {
            imageUrls = [url]
            isLoadingImages = false
            
            // Also fetch additional meta images if they exist
            let imageIDs = listing.meta?.images ?? []
            if !imageIDs.isEmpty {
                var extraUrls: [URL] = []
                let group = DispatchGroup()
                for mediaId in imageIDs {
                    group.enter()
                    MarketplaceListView.fetchFeaturedImageUrl(mediaId: mediaId) { fetchedUrl in
                        if let fetchedUrl = fetchedUrl {
                            extraUrls.append(fetchedUrl)
                        }
                        group.leave()
                    }
                }
                group.notify(queue: .main) {
                    // Combine featured + meta images, removing duplicates
                    var allUrls = [url]
                    for extra in extraUrls {
                        if !allUrls.contains(extra) {
                            allUrls.append(extra)
                        }
                    }
                    imageUrls = allUrls
                }
            }
            return
        }
        
        // Fallback: fetch from media IDs
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
                isLoadingImages = false
            }
        } else if let mediaId = listing.featuredMedia, mediaId > 0 {
            MarketplaceListView.fetchFeaturedImageUrl(mediaId: mediaId) { url in
                DispatchQueue.main.async {
                    if let url = url {
                        imageUrls = [url]
                    }
                    isLoadingImages = false
                }
            }
        } else {
            isLoadingImages = false
        }
    }
}

// MARK: - Previews
struct MarketplaceListView_Previews: PreviewProvider {
    static var previews: some View {
        MarketplaceListView()
    }
}
