//
//  SideMenuView.swift
//  AgribusinessNewsApp
//
//  Created on 15 February 2026.
//

import SwiftUI

struct SideMenuView: View {
    @Binding var isPresented: Bool
    @Binding var selectedCategory: ArticleCategory?
    @StateObject private var categoryService = CategoryService()
    let onCategorySelected: (ArticleCategory?) -> Void
    @State private var showAbout = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }
            
            // Menu content
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Categories")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isPresented = false
                                }
                            }) {
                                Image(systemName: "xmark")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("Browse by topic")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    
                    Divider()
                    
                    // All Articles option
                    Button(action: {
                        selectedCategory = nil
                        onCategorySelected(nil)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.green)
                                .frame(width: 28)
                            
                            Text("All Articles")
                                .font(.body)
                                .fontWeight(selectedCategory == nil ? .semibold : .regular)
                            
                            Spacer()
                            
                            if selectedCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(selectedCategory == nil ? Color.green.opacity(0.1) : Color.clear)
                    }
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    // Category List
                    if categoryService.isLoading && categoryService.categories.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(0..<8, id: \.self) { _ in
                                HStack(spacing: 12) {
                                    SkeletonShape(height: 28, width: 28, cornerRadius: 6)
                                    SkeletonShape(height: 18, width: 120)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.top, 8)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(categoryService.categories) { category in
                                    CategoryMenuItem(
                                        category: category,
                                        isSelected: selectedCategory?.id == category.id,
                                        onTap: {
                                            selectedCategory = category
                                            onCategorySelected(category)
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                isPresented = false
                                            }
                                        }
                                    )
                                    
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // About Us Button
                    Divider()
                    
                    Button(action: {
                        showAbout = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                                .frame(width: 28)
                            
                            Text("About Us")
                                .font(.body)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .padding(.bottom, 30)
                }
                .frame(width: 280)
                .background(Color(.systemBackground))
                
                Spacer()
            }
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .task {
            if categoryService.categories.isEmpty {
                try? await categoryService.fetchCategories()
            }
        }
    }
}

struct CategoryMenuItem: View {
    let category: ArticleCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .green : .secondary)
                    .frame(width: 28)
                
                Text(category.displayName)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)
                
                Spacer()
                
                Text("\(category.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(isSelected ? Color.green.opacity(0.1) : Color.clear)
        }
    }
}

#Preview {
    SideMenuView(
        isPresented: .constant(true),
        selectedCategory: .constant(nil),
        onCategorySelected: { _ in }
    )
}
