import SwiftUI

struct MarketplaceUploadAPIForm: View {
    @State private var title = ""
    @State private var description = ""
    @State private var price = ""
    @State private var location = ""
    @State private var contact = ""
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Product Details")) {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    TextField("Price", text: $price)
                    TextField("Location", text: $location)
                }
                Section(header: Text("Contact Info")) {
                    TextField("Phone/WhatsApp", text: $contact)
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
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Upload"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    var canSubmit: Bool {
        !title.isEmpty && !description.isEmpty && !location.isEmpty && !contact.isEmpty
    }
    
    func submitListing() {
        guard canSubmit else { return }
        isSubmitting = true
        let url = URL(string: "https://agribusinessmedia.com/wp-json/wp/v2/marketplace_listing")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // TODO: Add authentication (JWT or Application Password)
        // request.setValue("Bearer YOUR_JWT_TOKEN", forHTTPHeaderField: "Authorization")
        let body: [String: Any] = [
            "title": title,
            "content": description,
            "status": "pending",
            "fields": [
                "price": price,
                "location": location,
                "contact": contact
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
            }
            if let error = error {
                DispatchQueue.main.async {
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else { return }
            if httpResponse.statusCode == 201 {
                DispatchQueue.main.async {
                    alertMessage = "Listing submitted for review!"
                    showAlert = true
                    title = ""
                    description = ""
                    price = ""
                    location = ""
                    contact = ""
                }
            } else {
                DispatchQueue.main.async {
                    alertMessage = "Failed to submit. Status code: \(httpResponse.statusCode)"
                    showAlert = true
                }
            }
        }.resume()
    }
}

struct MarketplaceUploadAPIForm_Previews: PreviewProvider {
    static var previews: some View {
        MarketplaceUploadAPIForm()
    }
}
