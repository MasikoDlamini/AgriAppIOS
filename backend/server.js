const express = require('express');
const axios = require('axios');
const cheerio = require('cheerio');
const cors = require('cors');
const NodeCache = require('node-cache');

const app = express();
const PORT = process.env.PORT || 3000;

// Cache for 10 minutes
const cache = new NodeCache({ stdTTL: 600 });

// Enable CORS for iOS app
app.use(cors());
app.use(express.json());

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

app.listen(PORT, () => {
  console.log(`🚀 Agribusiness News API running on http://localhost:${PORT}`);
  console.log(`📰 News endpoint: http://localhost:${PORT}/api/news`);
});
