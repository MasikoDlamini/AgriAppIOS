# Testing Guide for Agribusiness News App

## The Problem
The app was loading but timing out because the backend API wasn't finding any news articles. This has been **FIXED** ✅

## What Was Fixed
1. **Backend scraper updated** - Now correctly parses the agribusinessmedia.com HTML structure
2. **API is working** - Now returns 6 news articles successfully
3. **Info.plist updated** - Added your Mac's IP address for device testing

## Testing Options

### Option 1: Test in Xcode Simulator (Recommended for Quick Testing)

1. **Keep the backend running:**
   ```bash
   cd "/Users/masikodlamini/Documents/Agribusiness app/backend"
   node server.js
   ```
   You should see:
   ```
   🚀 Agribusiness News API running on http://localhost:3000
   📰 News endpoint: http://localhost:3000/api/news
   ```

2. **Open and run the app:**
   ```bash
   open "/Users/masikodlamini/Documents/Agribusiness app/AgribusinessNewsApp.xcodeproj"
   ```
   
3. **In Xcode:**
   - Select iPhone 15 (or any simulator) as the target
   - Press ⌘+R to build and run
   - Navigate to the **News** tab
   - You should see 6 real news articles from the website! 🎉

### Option 2: Test on Physical iPhone/iPad (Same WiFi)

**Prerequisites:**
- Your Mac and iPhone must be on the **same WiFi network**
- Backend server must be running on your Mac

**Steps:**

1. **Update NewsService.swift:**
   Open `AgribusinessNewsApp/Models/NewsService.swift` and change line 14:
   ```swift
   // FROM:
   private let baseURL = "http://localhost:3000/api"
   
   // TO:
   private let baseURL = "http://192.168.110.63:3000/api"
   ```

2. **Start backend on Mac:**
   ```bash
   cd "/Users/masikodlamini/Documents/Agribusiness app/backend"
   node server.js
   ```

3. **Build to your device:**
   - Connect iPhone/iPad via USB or WiFi
   - Select your device in Xcode
   - Press ⌘+R to build and run
   - Navigate to News tab

### Option 3: Deploy Backend to Production

For the app to work anywhere without your Mac running, deploy the backend to a cloud service:

**Recommended: Railway.app (Free tier available)**

1. **Install Railway CLI:**
   ```bash
   npm install -g @railway/cli
   ```

2. **Deploy:**
   ```bash
   cd "/Users/masikodlamini/Documents/Agribusiness app/backend"
   railway login
   railway init
   railway up
   ```

3. **Get your URL:**
   Railway will give you a URL like: `https://your-app.railway.app`

4. **Update NewsService.swift:**
   ```swift
   private let baseURL = "https://your-app.railway.app/api"
   ```

5. **Remove localhost exception from Info.plist** (optional for production)

## Verifying Backend is Working

Test the API directly in Terminal:
```bash
curl http://localhost:3000/api/news
```

You should see JSON with 6 articles including titles like:
- "PM SETS NATIONWIDE CLIMATE MARCH IN MOTION"
- "TEMVELO AWARDS 2025: ESWATINI HONOURS ITS EARTH GUARDIANS"
- etc.

## Troubleshooting

### "Failed to load news" error in app

**Simulator:**
- ✅ Check backend is running: `curl http://localhost:3000/api/news`
- ✅ Verify `baseURL = "http://localhost:3000/api"` in NewsService.swift

**Physical Device:**
- ✅ Check both devices on same WiFi
- ✅ Use Mac's IP: `baseURL = "http://192.168.110.63:3000/api"`
- ✅ Check Info.plist has exception for 192.168.110.63
- ✅ Test from device: `curl http://192.168.110.63:3000/api/news`

### Backend returns 0 articles

The scraper has been fixed, but if the website structure changes:
1. Check `backend/server.js` selectors (lines 36-55)
2. Inspect the website HTML
3. Update Cheerio selectors accordingly

### Find your Mac's IP (if it changes)
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
```

## Current Status

✅ Backend API working - returning 6 real articles  
✅ Scraper correctly parsing agribusinessmedia.com  
✅ Info.plist configured for localhost and your Mac's IP  
✅ Ready to test in Xcode Simulator  
⚠️ Need to update IP for physical device testing  
⚠️ Consider deploying to Railway for production use

## Next Steps

1. **Test in simulator first** - Should work immediately with localhost
2. **Test on device** - Update to use 192.168.110.63
3. **Deploy backend** - Use Railway or Heroku for production
4. **Update to production URL** - Once deployed, update NewsService.swift

---

**Need help?** Check the logs:
- Backend logs: In the terminal where `node server.js` is running
- iOS logs: Xcode debug console (⇧⌘Y)
