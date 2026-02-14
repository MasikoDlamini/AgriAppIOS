# Backend Deployment Guide

Your app needs the backend API deployed to work on devices without WiFi connection. Here are 3 easy deployment options:

## Option 1: Railway.app (Recommended - Free & Easiest)

1. **Sign up at [Railway.app](https://railway.app)**
   - Use GitHub to sign in (free account)

2. **Deploy via Web Dashboard:**
   - Click "New Project" → "Deploy from GitHub repo"
   - Connect your GitHub and select the repo
   - Railway will auto-detect Node.js and deploy
   - Or click "Empty Project" → "Deploy from local files"

3. **Deploy via CLI:**
   ```bash
   # Install Railway CLI
   npm install -g @railway/cli
   
   # Login
   railway login
   
   # Deploy from backend folder
   cd "/Users/masikodlamini/Documents/Agribusiness app/backend"
   railway init
   railway up
   
   # Get your URL
   railway domain
   ```

4. **Get your API URL:**
   - After deployment, Railway provides a URL like: `https://your-app.railway.app`
   - Your API will be at: `https://your-app.railway.app/api/news`

## Option 2: Render.com (Free Tier Available)

1. **Sign up at [Render.com](https://render.com)**

2. **Create a new Web Service:**
   - Click "New +" → "Web Service"
   - Connect your GitHub repo or use "Deploy without GitHub"
   - Build Command: `npm install`
   - Start Command: `node server.js`
   - Choose "Free" plan

3. **Your API URL:**
   - Render provides: `https://your-app.onrender.com`
   - API endpoint: `https://your-app.onrender.com/api/news`

## Option 3: Vercel (Free)

1. **Sign up at [Vercel.com](https://vercel.com)**

2. **Deploy:**
   ```bash
   # Install Vercel CLI
   npm install -g vercel
   
   # Deploy
   cd "/Users/masikodlamini/Documents/Agribusiness app/backend"
   vercel
   ```

3. **Follow prompts and get your URL**

## After Deployment

Once deployed, update your iOS app:

**File:** `AgribusinessNewsApp/Models/NewsService.swift`

Change line 19 from:
```swift
private let baseURL = "http://192.168.110.63:3000/api"
```

To your deployed URL:
```swift
private let baseURL = "https://your-app.railway.app/api"  // Replace with your actual URL
```

## Quick Deploy (No Account Needed)

If you just want to test quickly, you can use Ngrok:

```bash
# Install ngrok
brew install ngrok

# Start your backend
cd "/Users/masikodlamini/Documents/Agribusiness app/backend"
node server.js

# In another terminal, expose it
ngrok http 3000
```

Ngrok will give you a public URL like `https://abc123.ngrok.io` - use this in NewsService.swift:
```swift
private let baseURL = "https://abc123.ngrok.io/api"
```

**Note:** Ngrok free URLs expire after 8 hours and change each restart. Use Railway/Render for permanent deployment.

## Verify Deployment

Test your deployed API:
```bash
curl https://your-deployed-url.com/api/news
```

You should see JSON with your articles!
