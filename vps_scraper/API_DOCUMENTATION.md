# News Genesis VPS Scraper - API Documentation

**Base URL**: `http://your_vps_ip:8000`

---

## 📍 API Endpoints

### 1. Health Check
**Endpoint**: `GET /health`

**Description**: VPS scraper സർവീസ് സ്ഥിതി പരിശോധിക്കുക

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2026-03-27T10:30:00.000000",
  "service": "News Genesis VPS Scraper"
}
```

**Usage**:
```bash
curl http://localhost:8000/health
```

---

### 2. Manual Scrape Trigger
**Endpoint**: `POST /scrape`

**Parameters**:
- `channel` (query): `english` | `arabic`

**Description**: Manual സ്ക്രാപിംഗ് ട്രിഗർ ചെയ്യുക

**Response**:
```json
{
  "status": "scraping_started",
  "channel": "english",
  "timestamp": "2026-03-27T10:30:00.000000"
}
```

**Usage**:
```bash
# English channel
curl -X POST "http://localhost:8000/scrape?channel=english"

# Arabic channel
curl -X POST "http://localhost:8000/scrape?channel=arabic"
```

---

### 3. Get Featured Articles
**Endpoint**: `GET /articles`

**Parameters**:
- `channel` (query, optional): `english` | `arabic` (default: `english`)
- `limit` (query, optional): Number (default: 20)

**Description**: Firebase നിന്ന് സ്ക്രാപ് ചെയ്ത ആർട്സ്കെൾ നിരൂപണം നേടുക

**Response**:
```json
[
  {
    "id": "english_Sample_article",
    "title": "Breaking News: Crisis in Middle East",
    "link": "https://www.aljazeera.com/news/...",
    "content": "Al Jazeera..." (500 chars max),
    "image_url": "https://...",
    "channel": "english",
    "language": "en",
    "scraped_at": "2026-03-27T10:30:00",
    "views": 120,
    "isDubbed": false
  },
  ...
]
```

**Usage**:
```bash
# English channel, 10 articles
curl "http://localhost:8000/articles?channel=english&limit=10"

# Arabic channel, 20 articles
curl "http://localhost:8000/articles?channel=arabic&limit=20"
```

---

### 4. Get Scraper Statistics
**Endpoint**: `GET /stats`

**Description**: സ്ക്രാപർ സ്ത്തിതി് വിസ്തരണ സമയ്യിൽ തെളിയിക്കുക

**Response**:
```json
{
  "english_articles": 305,
  "arabic_articles": 289,
  "total_articles": 594,
  "timestamp": "2026-03-27T10:30:00",
  "hls_streams": {
    "english": "https://live-qatarstream.com/hls/alijazeera_enghd/index.m3u8",
    "arabic": "https://live-qatarstream.com/hls/alijazeera_arabhd/index.m3u8"
  }
}
```

**Usage**:
```bash
curl http://localhost:8000/stats
```

---

## 🔄 Automated Scraping Schedule

### Default Schedule
```
English Channel: Every 6 hours
Arabic Channel: Every 6 hours
Time: 00:00, 06:00, 12:00, 18:00 UTC
```

### Modify Schedule (edit main.py)
```python
async def scheduled_scraper():
    while True:
        try:
            logger.info('Running scheduled scrape')
            await run_scraper('english')
            await run_scraper('arabic')
            await asyncio.sleep(6 * 60 * 60)  # 🔧 കാലക്രമം മാറ്റുക
        except Exception as e:
            logger.error(f'Scheduled scraper error: {e}')
            await asyncio.sleep(60 * 60)
```

---

## 🧪 Testing Examples

### Using Python Requests
```python
import requests

# Health check
response = requests.get('http://localhost:8000/health')
print(response.json())

# Trigger scrape
response = requests.post('http://localhost:8000/scrape', 
                         params={'channel': 'english'})
print(response.json())

# Get articles with limit
response = requests.get('http://localhost:8000/articles',
                        params={'channel': 'english', 'limit': 10})
articles = response.json()
for article in articles:
    print(f"- {article['title']}")

# Get stats
response = requests.get('http://localhost:8000/stats')
stats = response.json()
print(f"Total articles: {stats['total_articles']}")
```

### Using cURL
```bash
#!/bin/bash

VPS_IP="your_vps_ip"
BASE_URL="http://$VPS_IP:8000"

echo "=== Health Check ==="
curl -s "$BASE_URL/health" | jq

echo "=== Trigger English Scrape ==="
curl -s -X POST "$BASE_URL/scrape?channel=english" | jq

echo "=== Trigger Arabic Scrape ==="
curl -s -X POST "$BASE_URL/scrape?channel=arabic" | jq

echo "=== Get English Articles (limit: 5) ==="
curl -s "$BASE_URL/articles?channel=english&limit=5" | jq

echo "=== Get Arabic Articles (limit: 5) ==="
curl -s "$BASE_URL/articles?channel=arabic&limit=5" | jq

echo "=== Get Statistics ==="
curl -s "$BASE_URL/stats" | jq
```

### Using JavaScript/Node.js
```javascript
const BASE_URL = 'http://localhost:8000';

// Health check
async function checkHealth() {
  const response = await fetch(`${BASE_URL}/health`);
  console.log(await response.json());
}

// Trigger scrape
async function triggerScrape(channel) {
  const response = await fetch(`${BASE_URL}/scrape?channel=${channel}`, {
    method: 'POST'
  });
  console.log(await response.json());
}

// Get articles
async function getArticles(channel, limit = 20) {
  const response = await fetch(
    `${BASE_URL}/articles?channel=${channel}&limit=${limit}`
  );
  const articles = await response.json();
  articles.forEach(article => {
    console.log(`- ${article.title}`);
  });
}

// Get stats
async function getStats() {
  const response = await fetch(`${BASE_URL}/stats`);
  console.log(await response.json());
}

// Test functions
(async () => {
  await checkHealth();
  await triggerScrape('english');
  await getArticles('english', 10);
  await getStats();
})();
```

---

## 🔒 Security Considerations

### Authentication (Future Enhancement)
```python
from fastapi.security import HTTPBearer, HTTPAuthCredential

security = HTTPBearer()

@app.post("/scrape", security_scopes=security)
async def trigger_scrape(credentials: HTTPAuthCredential):
    # Verify the token
    if credentials.credentials != valid_token:
        raise HTTPException(status_code=403, detail="Invalid token")
```

### Rate Limiting
```python
from fastapi_limiter import FastAPILimiter
from fastapi_limiter.util import get_remote_address

@app.post("/scrape")
@limiter.limit("5/minute")
async def trigger_scrape(request: Request):
    # Only 5 requests per minute per IP
    pass
```

### CORS Configuration (if needed)
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://your-app.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)
```

---

## 📊 Database Schema

### Firebase Realtime Database Structure

```
news/
  english/
    english_Breaking_News_Crisis: {
      "id": "english_Breaking_News_Crisis",
      "title": "Breaking News: Crisis in Middle East",
      "content": "Al Jazeera brings you...",
      "link": "https://www.aljazeera.com/news/...",
      "imageUrl": "https://...",
      "language": "en",
      "channelType": "english",
      "createdAt": "2026-03-27T10:30:00",
      "views": 120,
      "isDubbed": false
    }
  arabic/
    arabic_أخبار_عاجلة: {
      "id": "arabic_أخبار_عاجلة",
      "title": "أخبار عاجلة: أزمة في الشرق الأوسط",
      "content": "تحدث الجزيرة...",
      ...
    }

dubbed_audio/
  english_Breaking_News_Crisis/
    malayalam/
      {
        "id": "english_Breaking_News_Crisis_malayalam",
        "articleId": "english_Breaking_News_Crisis",
        "language": "malayalam",
        "audioUrl": "gs://bucket/dubbed_audio/...",
        "duration": 45,
        "createdAt": "2026-03-27T11:00:00"
      }
```

---

## ⚠️ Error Handling

### Common HTTP Status Codes

| Status | ആർതം് | പരിഹാരം |
|--------|--------|---------|
| 200 | OK | ✅ വിജയകരമായ അനുരോധം |
| 400 | Bad Request | ❌ Invalid channel (use 'english' or 'arabic') |
| 500 | Internal Server | ❌ Firebase connection issue |
| 503 | Service Unavailable | ⏳ Scraper busy, retry later |

### Example Error Response
```json
{
  "detail": "Invalid channel"
}
```

---

## 🚀 Performance Optimization

### Caching Strategy
```python
from functools import lru_cache
from datetime import datetime, timedelta

# Cache stats for 5 minutes
last_stats_cache = None
stats_cache_time = None

@app.get("/stats")
async def get_stats():
    global last_stats_cache, stats_cache_time
    
    now = datetime.now()
    if (stats_cache_time and 
        (now - stats_cache_time).seconds < 300):
        return last_stats_cache
    
    # Fetch fresh stats...
```

### Pagination (Future)
```python
@app.get("/articles")
async def get_articles(
    channel: str = 'english',
    limit: int = 20,
    offset: int = 0  # New parameter
):
    # Skip 'offset' articles and return 'limit' articles
    pass
```

---

## 📝 Logging & Monitoring

### View Real-time Logs
```bash
# Follow logs as they generate
sudo journalctl -u news-genesis-scraper -f

# Last 50 lines
sudo journalctl -u news-genesis-scraper -n 50

# Logs from last hour
sudo journalctl -u news-genesis-scraper --since "1 hour ago"

# Export to file
sudo journalctl -u news-genesis-scraper > scraper_logs.txt
```

### Log Levels
```
DEBUG: Detailed debugging info
INFO: General informational messages
WARNING: Warning messages
ERROR: Error messages
CRITICAL: Critical errors
```

---

## 🔄 Integration with Flutter App

### Example Dart Code
```dart
import 'package:http/http.dart' as http;

class ScraperAPI {
  final String baseUrl = 'http://your_vps_ip:8000';
  
  Future<List<dynamic>> getArticles(String channel) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/articles?channel=$channel&limit=20')
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load articles');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
  
  Future<void> triggerScrape(String channel) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/scrape?channel=$channel')
      );
    } catch (e) {
      throw Exception('Scrape failed: $e');
    }
  }
}
```

---

## 📞 Support & Troubleshooting

### Service Won't Start
```bash
# Check service status
sudo systemctl status news-genesis-scraper

# View error logs
journalctl -u news-genesis-scraper --no-pager | tail -20

# Restart service
sudo systemctl restart news-genesis-scraper
```

### Connection Refused
```bash
# Check if service is running
sudo lsof -i :8000

# Check firewall
sudo ufw status

# Allow port
sudo ufw allow 8000/tcp
```

### Firebase Connection Error
```bash
# Verify credentials file
ls -la /root/news_genesis_scraper/firebase-credentials.json

# Test Firebase connectivity
curl https://your-project.firebaseio.com/test.json
```

---

**Version**: 1.0  
**Last Updated**: March 27, 2026  
**API Status**: ✅ Production Ready
