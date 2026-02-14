# Backend API Setup Guide

## Quick Start

### Step 1: Install Node.js
If you don't have Node.js installed:
- Download from https://nodejs.org (LTS version)
- Or install via Homebrew: `brew install node`

### Step 2: Install Dependencies
```bash
cd "/Users/masikodlamini/Documents/Agribusiness app/backend"
npm install
```

### Step 3: Start the Server
```bash
npm start
```

You should see:
```
🚀 Agribusiness News API running on http://localhost:3000
📰 News endpoint: http://localhost:3000/api/news
```

### Step 4: Test the API
Open your browser or use curl:
```bash
curl http://localhost:3000/api/news
```

You should see JSON data with news articles.

### Step 5: Run the iOS App
1. Keep the backend server running
2. Open Xcode and build the app (⌘+B)
3. Run on simulator or device (⌘+R)
4. Navigate to the News tab

## For Production Deployment

### Railway.app (Recommended - Free Tier)
1. Go to https://railway.app
2. Sign up with GitHub
3. Click "New Project" → "Deploy from GitHub repo"
4. Select your repository
5. Railway will auto-detect Node.js and deploy
6. Copy your deployment URL (e.g., `https://your-app.up.railway.app`)
7. Update `NewsService.swift`: Change `baseURL` to your Railway URL

### Alternative: Heroku
```bash
# Install Heroku CLI
brew install heroku/brew/heroku

# Login
heroku login

# Create app
heroku create agribusiness-news-api

# Deploy
git push heroku main

# Get URL
heroku open
```

### Update iOS App with Production URL
In `NewsService.swift`, change:
```swift
private let baseURL = "http://localhost:3000/api"
```
to:
```swift
private let baseURL = "https://your-deployed-url.com/api"
```

## Troubleshooting

### iOS App shows "Failed to load news"
- Make sure backend server is running
- Check that localhost is allowed in Info.plist
- For device testing, use your Mac's IP address instead of localhost

### Backend not scraping articles
- The HTML selectors may need adjustment
- Check server.js console for error messages
- Visit https://agribusinessmedia.com/news in a browser and inspect the HTML structure

### CORS errors
- Already configured in server.js
- If issues persist, check your deployment platform's settings

## Architecture

```
iOS App (SwiftUI)
    ↓
NewsService (API Client)
    ↓
Backend API (Node.js/Express)
    ↓
Web Scraper (Cheerio)
    ↓
Agribusinessmedia.com
```

## Features
- ✅ Auto-caching (10 minutes)
- ✅ Pull-to-refresh in app
- ✅ Error handling
- ✅ Loading states
- ✅ Image loading
- ✅ Native iOS design
