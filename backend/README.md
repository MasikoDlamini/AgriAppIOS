# Agribusiness News API

Backend API server for the Agribusiness News iOS App.

## Features

- Scrapes news articles from agribusinessmedia.com
- Caches results for 10 minutes
- Provides JSON API for iOS app
- CORS enabled for mobile app access

## Installation

```bash
cd backend
npm install
```

## Running the Server

**Development (with auto-reload):**
```bash
npm run dev
```

**Production:**
```bash
npm start
```

The server will run on `http://localhost:3000`

## API Endpoints

### Get All News Articles
```
GET /api/news
```

Response:
```json
{
  "success": true,
  "count": 15,
  "articles": [
    {
      "id": 1,
      "title": "Article Title",
      "link": "https://agribusinessmedia.com/news/article-url",
      "excerpt": "Article excerpt...",
      "image": "https://agribusinessmedia.com/image.jpg",
      "category": "Technology",
      "date": "2 hours ago",
      "timestamp": "2025-11-30T12:00:00.000Z"
    }
  ]
}
```

### Get Single Article
```
GET /api/article/:id
```

### Clear Cache
```
POST /api/cache/clear
```

## Deployment

### Option 1: Railway.app (Recommended - Free)
1. Create account at railway.app
2. Connect your GitHub repo
3. Deploy automatically
4. Get public URL

### Option 2: Heroku
1. Create Heroku account
2. Install Heroku CLI
3. Deploy:
```bash
heroku create agribusiness-news-api
git push heroku main
```

### Option 3: Vercel
1. Install Vercel CLI: `npm i -g vercel`
2. Deploy: `vercel`

### Option 4: Local Network (Testing)
- Run on your Mac
- Use your Mac's local IP (e.g., `http://192.168.1.X:3000`)
- Both Mac and iPhone must be on same WiFi

## Environment Variables

Create `.env` file:
```
PORT=3000
```

## Notes

- The scraper selectors may need adjustment based on the website's HTML structure
- Cache duration is 10 minutes (can be adjusted in server.js)
- Rate limiting should be added for production use
