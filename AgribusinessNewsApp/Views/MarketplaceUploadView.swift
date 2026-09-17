import SwiftUI
import PhotosUI

struct MarketplaceUploadView: View {
    @State private var title = ""
    @State private var description = ""
    @State private var category = ""
    @State private var price = ""
    @State private var location = ""
    @State private var email = ""
    @State private var cellphone = ""
    @State private var images: [UIImage] = []
    @State private var showImagePicker = false
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var agreedToRules = false

    let isUserVerified = true
    let maxImages = 5
    let maxListingsPerDay = 3

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Product Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    TextField("Category", text: $category)
                    TextField("Price (optional)", text: $price)
                    TextField("Location", text: $location)
                }
                Section(header: Text("Contact Info")) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("Cellphone", text: $cellphone)
                        .keyboardType(.phonePad)
                }
                Section(header: Text("Photos (max \(maxImages))")) {
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(images, id: \.self) { img in
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipped()
                            }
                            if images.count < maxImages {
                                Button(action: { showImagePicker = true }) {
                                    VStack {
                                        Image(systemName: "plus")
                                            .font(.title)
                                        Text("Add Photo")
                                            .font(.caption)
                                    }
                                    .frame(width: 80, height: 80)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                }
                Section {
                    Toggle(isOn: $agreedToRules) {
                        Text("I agree to the marketplace rules and safety guidelines.")
                    }
                }
                Section {
                    Button(action: submitListing) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit Listing")
                        }
                    }
                    .disabled(!canSubmit)
                }
            }
            .navigationTitle("Upload Listing")
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(images: $images, maxImages: maxImages)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Upload"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    var canSubmit: Bool {
        isUserVerified &&
        !title.isEmpty &&
        !description.isEmpty &&
        !category.isEmpty &&
        !location.isEmpty &&
        !email.isEmpty &&
        !cellphone.isEmpty &&
        !images.isEmpty &&
        agreedToRules
    }

    func submitListing() {
        guard canSubmit else { return }
        isSubmitting = true
        Task {
            do {
                let attachmentIDs = try await uploadImagesAndGetIDs(images: images)
                print("[DEBUG] Uploaded image IDs: \(attachmentIDs)")
                try await submitListingWithImageIDs(attachmentIDs)
            } catch {
                DispatchQueue.main.async {
                    isSubmitting = false
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }

    func uploadImagesAndGetIDs(images: [UIImage]) async throws -> [Int] {
        let username = "sbumngadi"
        let appPassword = "juKM JGvc qtqN eBUi A0Lr txGS"
        let loginString = "\(username):\(appPassword)"
        let loginData = loginString.data(using: .utf8)!
        let base64Login = loginData.base64EncodedString()
        let url = URL(string: "https://agrib.10web.cloud/wp-json/wp/v2/media")!
        var ids: [Int] = []
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        let session = URLSession(configuration: config)
        for (idx, image) in images.enumerated() {
            let resizedImage = image.resized(toWidth: 1024)
            guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else { continue }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Basic \(base64Login)", forHTTPHeaderField: "Authorization")
            request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
            request.setValue("attachment; filename=\"listing-image-\(Int(Date().timeIntervalSince1970))-\(idx).jpg\"", forHTTPHeaderField: "Content-Disposition")
            request.httpBody = imageData

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 else {
                let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "ImageUpload", code: 1, userInfo: [NSLocalizedDescriptionKey: "Image upload failed: \(msg)"])
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let id = json["id"] as? Int {
                ids.append(id)
            } else {
                throw NSError(domain: "ImageUpload", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not parse image ID"])
            }
        }
        return ids
    }

    func submitListingWithImageIDs(_ imageIDs: [Int]) async throws {
        let url = URL(string: "https://agrib.10web.cloud/wp-json/wp/v2/marketplace_listing")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let username = "sbumngadi"
        let appPassword = "juKM JGvc qtqN eBUi A0Lr txGS"
        let loginString = "\(username):\(appPassword)"
        let loginData = loginString.data(using: .utf8)!
        let base64Login = loginData.base64EncodedString()
        request.setValue("Basic \(base64Login)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "title": title,
            "content": description,
            "status": "pending",
            "featured_media": imageIDs.first ?? 0,
            "meta": [
                "price": price,
                "location": location,
                "email": email,
                "cellphone_": cellphone,
                "category": category,
                "images": imageIDs
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        print("Submitting listing...")

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 180
        let session = URLSession(configuration: config)
        let (data, response) = try await session.data(for: request)
        DispatchQueue.main.async {
            isSubmitting = false
        }
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code:", httpResponse.statusCode)
            if httpResponse.statusCode == 201 {
                DispatchQueue.main.async {
                    alertMessage = "Listing submitted for review!"
                    showAlert = true
                    title = ""
                    description = ""
                    price = ""
                    location = ""
                    email = ""
                    cellphone = ""
                }
            } else {
                var serverMessage = "Failed to submit. Status code: \(httpResponse.statusCode)"
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let message = json["message"] as? String {
                    serverMessage += "\n\nServer message: \(message)"
                } else if let text = String(data: data, encoding: .utf8), !text.isEmpty {
                    serverMessage += "\n\nServer response: \(text)"
                }
                DispatchQueue.main.async {
                    alertMessage = serverMessage
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Image Picker Helper
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    let maxImages: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = maxImages - images.count
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                        if let image = object as? UIImage {
                            DispatchQueue.main.async {
                                if self.parent.images.count < self.parent.maxImages {
                                    self.parent.images.append(image)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Image Compression Helper
extension UIImage {
    func resized(toWidth width: CGFloat) -> UIImage {
        let oldWidth = size.width
        let scaleFactor = width / oldWidth
        let newHeight = size.height * scaleFactor
        let newSize = CGSize(width: width, height: newHeight)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
}
