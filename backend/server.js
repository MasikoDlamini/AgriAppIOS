const express = require('express');
const axios = require('axios');
const cheerio = require('cheerio');
const cors = require('cors');
const NodeCache = require('node-cache');
const admin = require('firebase-admin');

const app = express();
const PORT = process.env.PORT || 3000;

// Cache for 10 minutes
const cache = new NodeCache({ stdTTL: 600 });

// Enable CORS for iOS app
app.use(cors());
app.use(express.json());

// ============================================================
// Firebase Admin SDK Initialization
// ============================================================
// Uses GOOGLE_APPLICATION_CREDENTIALS env var (path to service account JSON)
// or FIREBASE_SERVICE_ACCOUNT env var (JSON string of service account)
let firebaseInitialized = false;
try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    firebaseInitialized = true;
    console.log('✅ Firebase Admin SDK initialized from FIREBASE_SERVICE_ACCOUNT env var');
  } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
    firebaseInitialized = true;
    console.log('✅ Firebase Admin SDK initialized from GOOGLE_APPLICATION_CREDENTIALS');
  } else {
    console.warn('⚠️  No Firebase credentials found. Push notifications disabled.');
    console.warn('   Set FIREBASE_SERVICE_ACCOUNT (JSON string) or GOOGLE_APPLICATION_CREDENTIALS (file path)');
  }
} catch (err) {
  console.error('❌ Firebase Admin SDK initialization failed:', err.message);
}

// ============================================================
// Content Tracking for Push Notifications
// ============================================================
// Store the last known IDs so we can detect new content
let lastKnownArticleId = null;
let lastKnownMagazineId = null;

// Polling interval: check every 5 minutes (300000ms)
const POLL_INTERVAL = 5 * 60 * 1000;

/**
 * Send an FCM notification to a topic
 */
async function sendTopicNotification(topic, title, body, data = {}) {
  if (!firebaseInitialized) {
    console.log(`[FCM] Skipped (Firebase not initialized): ${topic} - ${title}`);
    return;
  }

  const message = {
    topic: topic,
    notification: {
      title: title,
      body: body,
    },
    data: {
      ...data,
      type: topic,
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
          'content-available': 1,
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(`[FCM] ✅ Sent to topic "${topic}": ${title} (${response})`);
  } catch (err) {
    console.error(`[FCM] ❌ Failed to send to topic "${topic}":`, err.message);
  }
}

/**
 * Check WordPress for new articles and send push if found
 */
async function checkForNewArticles() {
  try {
    const response = await axios.get('https://agribusinessmedia.com/wp-json/wp/v2/posts', {
      params: { per_page: 1, _embed: true },
      headers: {
        'User-Agent': 'AgribusinessNewsApp-Backend/1.0',
      },
    });

    if (!response.data || response.data.length === 0) return;

    const latestPost = response.data[0];
    const latestId = latestPost.id;

    if (lastKnownArticleId === null) {
      // First run — just record the ID, don't send notification
      lastKnownArticleId = latestId;
      console.log(`[Poll] Initialized lastKnownArticleId = ${latestId}`);
      return;
    }

    if (latestId > lastKnownArticleId) {
      // New article detected!
      const title = latestPost.title.rendered
        .replace(/<[^>]*>/g, '')
        .replace(/&#8211;/g, '–')
        .replace(/&#8217;/g, "'")
        .replace(/&#8220;/g, '"')
        .replace(/&#8221;/g, '"')
        .replace(/&amp;/g, '&');

      let category = 'News';
      if (latestPost._embedded && latestPost._embedded['wp:term']) {
        const categories = latestPost._embedded['wp:term'][0];
        if (categories && categories.length > 0) {
          category = categories[0].name || 'News';
        }
      }

      console.log(`[Poll] 🆕 New article detected: "${title}" (id: ${latestId})`);
      await sendTopicNotification(
        'new_articles',
        '📰 New Article',
        title,
        { articleId: String(latestId), category }
      );

      lastKnownArticleId = latestId;
    }
  } catch (err) {
    console.error('[Poll] Error checking articles:', err.message);
  }
}

/**
 * Check WordPress media for new magazines and send push if found
 */
async function checkForNewMagazines() {
  try {
    const response = await axios.get('https://agribusinessmedia.com/wp-json/wp/v2/media', {
      params: {
        media_type: 'application',
        per_page: 1,
        orderby: 'date',
        order: 'desc',
      },
      headers: {
        'User-Agent': 'AgribusinessNewsApp-Backend/1.0',
      },
    });

    if (!response.data || response.data.length === 0) return;

    const latestMedia = response.data[0];
    const latestId = latestMedia.id;
    const title = (latestMedia.title?.rendered || '').toUpperCase();

    // Only consider items with "ISSUE" in the title
    if (!title.includes('ISSUE')) return;

    if (lastKnownMagazineId === null) {
      lastKnownMagazineId = latestId;
      console.log(`[Poll] Initialized lastKnownMagazineId = ${latestId}`);
      return;
    }

    if (latestId > lastKnownMagazineId) {
      const cleanTitle = (latestMedia.title?.rendered || 'New Issue')
        .replace(/<[^>]*>/g, '')
        .replace(/&#8211;/g, '–')
        .replace(/&#8217;/g, "'");

      // Extract issue number
      const issueMatch = title.match(/ISSUE[\s-]*(\d+)/);
      const issueNumber = issueMatch ? `Issue ${issueMatch[1]}` : 'New Issue';

      console.log(`[Poll] 🆕 New magazine detected: "${cleanTitle}" (id: ${latestId})`);
      await sendTopicNotification(
        'new_magazines',
        '📖 New Magazine Available',
        `${issueNumber} is now available to read!`,
        { magazineId: String(latestId) }
      );

      lastKnownMagazineId = latestId;
    }
  } catch (err) {
    console.error('[Poll] Error checking magazines:', err.message);
  }
}

/**
 * Run all content checks
 */
async function pollForNewContent() {
  console.log(`[Poll] Checking for new content at ${new Date().toISOString()}`);
  await Promise.all([
    checkForNewArticles(),
    checkForNewMagazines(),
  ]);
}

// Start polling when server starts
pollForNewContent(); // initial check (records baseline IDs)
setInterval(pollForNewContent, POLL_INTERVAL);
console.log(`🔄 Content polling started (every ${POLL_INTERVAL / 1000}s)`);


// Health check endpoint
app.get('/', (req, res) => {
  res.json({ 
    status: 'running',
    message: 'Agribusiness News API',
    endpoints: {
      news: '/api/news',
      article: '/api/article/:id'
    }
  });
});

// Fetch news articles using WordPress REST API
app.get('/api/news', async (req, res) => {
  try {
    // Check cache first
    const cachedData = cache.get('news');
    if (cachedData) {
      return res.json(cachedData);
    }

    // Fetch from WordPress REST API
    const response = await axios.get('https://agribusinessmedia.com/wp-json/wp/v2/posts', {
      params: {
        per_page: 20,
        _embed: true // Include featured images and categories
      },
      headers: {
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15'
      }
    });

    const articles = response.data.map((post, index) => {
      // Extract featured image
      let image = null;
      if (post._embedded && post._embedded['wp:featuredmedia']) {
        const media = post._embedded['wp:featuredmedia'][0];
        image = media.source_url || media.media_details?.sizes?.medium?.source_url;
      }

      // Extract categories
      let category = 'News';
      if (post._embedded && post._embedded['wp:term']) {
        const categories = post._embedded['wp:term'][0];
        if (categories && categories.length > 0) {
          category = categories[0].name;
        }
      }

      // Format date
      const postDate = new Date(post.date);
      const now = new Date();
      const diffHours = Math.floor((now - postDate) / (1000 * 60 * 60));
      let dateString = 'Recent';
      if (diffHours < 1) {
        dateString = 'Just now';
      } else if (diffHours < 24) {
        dateString = `${diffHours}h ago`;
      } else if (diffHours < 48) {
        dateString = 'Yesterday';
      } else {
        const diffDays = Math.floor(diffHours / 24);
        dateString = `${diffDays}d ago`;
      }

      return {
        id: post.id,
        title: post.title.rendered.replace(/&#8211;/g, '–').replace(/&#8217;/g, "'").replace(/&#8220;/g, '"').replace(/&#8221;/g, '"'),
        link: post.link,
        excerpt: post.excerpt.rendered.replace(/<[^>]*>/g, '').trim().substring(0, 150) || '',
        image: image,
        category: category,
        date: dateString,
        timestamp: post.date
      };
    });

    const result = {
      success: true,
      count: articles.length,
      articles: articles
    };

    // Cache the result
    cache.set('news', result);

    res.json(result);
  } catch (error) {
    console.error('Error fetching news:', error.message);
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch news articles',
      message: error.message 
    });
  }
});

// Fetch single article details
app.get('/api/article/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // Get cached news to find the article
    const cachedNews = cache.get('news');
    if (cachedNews && cachedNews.articles) {
      const article = cachedNews.articles.find(a => a.id === parseInt(id));
      if (article) {
        return res.json({ success: true, article });
      }
    }

    res.status(404).json({ 
      success: false, 
      error: 'Article not found' 
    });
  } catch (error) {
    res.status(500).json({ 
      success: false,
      error: 'Failed to fetch article',
      message: error.message 
    });
  }
});

// Clear cache endpoint (for development)
app.post('/api/cache/clear', (req, res) => {
  cache.flushAll();
  res.json({ success: true, message: 'Cache cleared' });
});

// Manually trigger a content check & send notifications for any new content
app.post('/api/notifications/check', async (req, res) => {
  try {
    await pollForNewContent();
    res.json({
      success: true,
      message: 'Content check completed',
      lastKnownArticleId,
      lastKnownMagazineId,
      firebaseInitialized,
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Get notification status
app.get('/api/notifications/status', (req, res) => {
  res.json({
    firebaseInitialized,
    pollIntervalSeconds: POLL_INTERVAL / 1000,
    lastKnownArticleId,
    lastKnownMagazineId,
  });
});

app.listen(PORT, () => {
  console.log(`🚀 Agribusiness News API running on http://localhost:${PORT}`);
  console.log(`📰 News endpoint: http://localhost:${PORT}/api/news`);
  console.log(`🔔 Notification status: http://localhost:${PORT}/api/notifications/status`);
});
