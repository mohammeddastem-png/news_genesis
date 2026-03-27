#!/usr/bin/env python3
"""
News Genesis - VPS Web Scraper Backend
24/7 News Scraper for Al Jazeera English & Arabic channels
Deploys on cloud VPS (AWS, DigitalOcean, Linode, etc.)

Dependencies:
pip install fastapi uvicorn beautifulsoup4 requests firebase-admin python-dotenv
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
from datetime import datetime, timedelta
import asyncio
import httpx
from bs4 import BeautifulSoup
import firebase_admin
from firebase_admin import credentials, db, storage
import os
from dotenv import load_dotenv
import logging
from typing import List, Optional
import json

# ❯◄ Configure Logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/news_genesis_scraper.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()

# Firebase Configuration
FIREBASE_CREDS_PATH = os.getenv('FIREBASE_CREDS_PATH', 'firebase-credentials.json')
FIREBASE_DB_URL = os.getenv('FIREBASE_DB_URL', 'https://your-project.firebaseio.com')

# Initialize Firebase Admin SDK
try:
    firebase_admin.initialize_app(
        credentials.Certificate(FIREBASE_CREDS_PATH),
        {'databaseURL': FIREBASE_DB_URL}
    )
    logger.info('Firebase initialized successfully')
except Exception as e:
    logger.error(f'Firebase initialization failed: {e}')

# URLs for Al Jazeera English & Arabic
AL_JAZEERA_URLS = {
    'english': 'https://www.aljazeera.com/news/',
    'arabic': 'https://www.aljazeera.net/news/',
}

# HLS Stream URLs
HLS_STREAMS = {
    'english': 'https://live-qatarstream.com/hls/alijazeera_enghd/index.m3u8',
    'arabic': 'https://live-qatarstream.com/hls/alijazeera_arabhd/index.m3u8',
}

app = FastAPI(title="News Genesis VPS Scraper")


class AlJazeeraNews:
    """Al Jazeera ന്യൂസ് സ്ക്രാപർ ക്ലാസ്"""
    
    def __init__(self):
        self.session = None
        self.timeout = 10
    
    async def init_session(self):
        """HTTP സെഷൻ ഇനിഷിയലൈസ് ചെയ്യുക"""
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        }
        self.session = httpx.AsyncClient(headers=headers, timeout=self.timeout)
    
    async def close_session(self):
        """HTTP സെഷൻ ക്ലോസ് ചെയ്യുക"""
        if self.session:
            await self.session.aclose()
    
    async def scrape_articles(self, channel: str) -> List[dict]:
        """Al Jazeera ത്രിതെ നിന്ന് ന്യൂസ് സ്ക്രാപ് ചെയ്യുക"""
        try:
            if not self.session:
                await self.init_session()
            
            url = AL_JAZEERA_URLS.get(channel, AL_JAZEERA_URLS['english'])
            response = await self.session.get(url)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            articles = []
            
            # സാധാരണ ന്യൂസ് ആർട്സ്കെൾ സെലെക്ടർ (Al Jazeera ൽ സ്ട്രകൽച്ചര അനുസരിച്ച് അപ്ഡേറ്റ് ചെയ്യുക)
            for item in soup.select('article, [data-article], .article-item')[:20]:
                try:
                    title_elem = item.select_one('h3, .heading, [data-title]')
                    title = title_elem.get_text(strip=True) if title_elem else 'Untitled'
                    
                    link_elem = item.select_one('a[href]')
                    link = link_elem.get('href') if link_elem else '#'
                    
                    # എര്റി്തെ സാപേക്ഷിക URL നിർണ്ണയിക്കുക
                    if link.startswith('/'):
                        if channel == 'arabic':
                            link = f"https://www.aljazeera.net{link}"
                        else:
                            link = f"https://www.aljazeera.com{link}"
                    
                    content_elem = item.select_one('p, .summary, [data-desc]')
                    content = content_elem.get_text(strip=True) if content_elem else ''
                    
                    image_elem = item.select_one('img')
                    image_url = image_elem.get('src', '') if image_elem else ''
                    
                    article = {
                        'title': title,
                        'link': link,
                        'content': content[:500],  # സംക്ഷിപ്ത
                        'image_url': image_url,
                        'channel': channel,
                        'language': 'ar' if channel == 'arabic' else 'en',
                        'scraped_at': datetime.now().isoformat(),
                    }
                    
                    articles.append(article)
                    logger.info(f'Scraped article: {title[:50]}...')
                    
                except Exception as e:
                    logger.warning(f'Error scraping individual article: {e}')
                    continue
            
            return articles
            
        except Exception as e:
            logger.error(f'Error scraping {channel}: {e}')
            return []
    
    async def get_full_article_content(self, article_url: str) -> Optional[str]:
        """പൂർണ്ണ ആർട്സ്കെൾ കോണ്টെന്റ് ലോഡ് ചെയ്യുക"""
        try:
            if not self.session:
                await self.init_session()
            
            response = await self.session.get(article_url)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # ന്യൂസ് കോണ്টെന്റ് കേടെടൺ (Al Jazeera പ്ലാറ്റ്ഫോർ അനുസരിച്ച് അപ്ഡേറ്റ് ചെയ്യുക)
            content_elem = soup.select_one('article, [data-article-body], .article-body')
            
            if content_elem:
                # സാരാംശ അത്യാവശ്യ കേടെടൺ ബെഹാവര്
                paragraphs = content_elem.find_all('p')
                content = ' '.join([p.get_text(strip=True) for p in paragraphs])
                return content
            
            return None
            
        except Exception as e:
            logger.error(f'Error fetching full article {article_url}: {e}')
            return None


class FirebaseManager:
    """Firebase ഡാറ്റാബേസ് ോ്ബസ് ക്ലാസ്"""
    
    @staticmethod
    async def save_articles(articles: List[dict], channel: str):
        """ന്യൂസ് ആർട്സ്കെൾ Firebase-ലേക്ക് സംരക്ഷിക്കുക"""
        try:
            for article in articles:
                article_id = f"{channel}_{article['title'][:20].replace(' ', '_')}"
                ref = db.reference(f'news/{channel}/{article_id}')
                
                # عنوان ആർട്സ്കെൾ നിയന്ത്രിണ്ട് ഡാറ്റ
                ref.set({
                    'id': article_id,
                    'title': article['title'],
                    'content': article['content'],
                    'link': article['link'],
                    'imageUrl': article['image_url'],
                    'language': article['language'],
                    'channelType': channel,
                    'createdAt': article['scraped_at'],
                    'views': 0,
                    'isDubbed': False,
                })
                
                logger.info(f'Saved article to Firebase: {article_id}')
            
        except Exception as e:
            logger.error(f'Error saving articles to Firebase: {e}')
    
    @staticmethod
    async def get_article_count(channel: str) -> int:
        """ചാനൽ കണക്ട് നിർണ്ണയിക്കുക"""
        try:
            ref = db.reference(f'news/{channel}')
            data = ref.get()
            return len(data) if data else 0
        except Exception as e:
            logger.error(f'Error getting article count: {e}')
            return 0


# FastAPI Routes

@app.get('/health')
async def health_check():
    """സ്വാസ്ഥ്യ പരിശോധനാ എൻ്ഡ്ഫോയിന്ത്"""
    return {
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'service': 'News Genesis VPS Scraper'
    }


@app.post('/scrape')
async def trigger_scrape(background_tasks: BackgroundTasks, channel: str = 'english'):
    """ന്യൂസ് സ്ക്രാപിംഗ് ട്രിഗർ ചെയ്യുക"""
    try:
        if channel not in ['english', 'arabic']:
            raise HTTPException(status_code=400, detail='Invalid channel')
        
        background_tasks.add_task(run_scraper, channel)
        
        return {
            'status': 'scraping_started',
            'channel': channel,
            'timestamp': datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f'Error triggering scrape: {e}')
        raise HTTPException(status_code=500, detail=str(e))


@app.get('/articles')
async def get_articles(channel: str = 'english', limit: int = 20):
    """Firebase നിന്ന് ന്യൂസ് നിരൂപണം ലഭ്യമാക്കുക"""
    try:
        ref = db.reference(f'news/{channel}')
        articles = ref.order_by_child('createdAt').limit_to_last(limit).get()
        
        if articles:
            return list(articles.values())
        return []
    except Exception as e:
        logger.error(f'Error fetching articles: {e}')
        raise HTTPException(status_code=500, detail=str(e))


@app.get('/stats')
async def get_stats():
    """സ്ക്രാപർ സ്ത്തിതി ലഭ്യമാക്കുക"""
    try:
        english_count = await FirebaseManager.get_article_count('english')
        arabic_count = await FirebaseManager.get_article_count('arabic')
        
        return {
            'english_articles': english_count,
            'arabic_articles': arabic_count,
            'total_articles': english_count + arabic_count,
            'timestamp': datetime.now().isoformat(),
            'hls_streams': HLS_STREAMS
        }
    except Exception as e:
        logger.error(f'Error getting stats: {e}')
        raise HTTPException(status_code=500, detail=str(e))


async def run_scraper(channel: str):
    """പ്രധാന സ്ക്രാപർ ഫംഗ്‌ഷൻ"""
    logger.info(f'Starting scrape for {channel} channel')
    
    scraper = AlJazeeraNews()
    try:
        articles = await scraper.scrape_articles(channel)
        await FirebaseManager.save_articles(articles, channel)
        logger.info(f'Successfully scraped {len(articles)} articles from {channel}')
    except Exception as e:
        logger.error(f'Scraper error: {e}')
    finally:
        await scraper.close_session()


@app.on_event('startup')
async def startup_event():
    """ആപ്ലിക്കേഷൻ സ്റ്റാർട്‍അപ്പ}-സമയ കാര്യങ്ങൾ"""
    logger.info('News Genesis VPS Scraper started')
    # ആദ്യ സ്ക്രാപ് ഓണ്ട് സ്റ്റാർട്‍ ആപ്പ്
    # background_tasks.add_task(run_scraper, 'english')
    # background_tasks.add_task(run_scraper, 'arabic')


@app.shutdown_event
async def shutdown_event():
    """ആപ്ലിക്കേഷൻ ഷട്ഡൌൺ കാര്യങ്ങൾ"""
    logger.info('News Genesis VPS Scraper stopped')


# Scheduled scraping (run every 6 hours)
async def scheduled_scraper():
    """ആരംഭ സ്ക്രാപിംഗ് 6 മണിക്കൂർ കൂടെ"""
    while True:
        try:
            logger.info('Running scheduled scrape')
            await run_scraper('english')
            await run_scraper('arabic')
            await asyncio.sleep(6 * 60 * 60)  # 6 ഗണ്ടികോ കാത്തിരിക്കുക
        except Exception as e:
            logger.error(f'Scheduled scraper error: {e}')
            await asyncio.sleep(60 * 60)  # പ്രയാസത്ത്‌ 1 മണിക്കൂർ കാത്തിരിക്കുക


if __name__ == '__main__':
    import uvicorn
    
    # ഉതരിനിർ സെർവർ സ്റ്റാർട്‍ ചെയ്യുക
    uvicorn.run(
        app,
        host='0.0.0.0',
        port=8000,
        workers=4,
        log_level='info'
    )


# VPS Deployment Instructions (Ubuntu/Debian):
"""
1. SSH ൽ VPS-ലേക്ക് കണക്റ്റ് ചെയ്യുക:
   ssh root@your_vps_ip

2. Dependency ഇൻസ്റ്റാൾ ചെയ്യുക:
   apt-get update && apt-get install python3.11 python3-pip git

3. Project clone ചെയ്യുക:
   git clone https://github.com/yourusername/news_genesis_scraper.git
   cd news_genesis_scraper

4. Virtual environment സൃഷ്ടി ചെയ്യുക:
   python3 -m venv venv
   source venv/bin/activate

5. Dependencies ഇൻസ്റ്റാൾ ചെയ്യുക:
   pip install -r requirements.txt

6. Environment variables സെറ്റ് ചെയ്യുക:
   nano .env
   # Add:
   # FIREBASE_CREDS_PATH=/path/to/firebase-credentials.json
   # FIREBASE_DB_URL=https://your-project.firebaseio.com

7. Systemd service സെറ്റ് ചെയ്യുക (24/7 running):
   sudo nano /etc/systemd/system/news-genesis-scraper.service
   
   [Unit]
   Description=News Genesis VPS Scraper
   After=network.target

   [Service]
   Type=simple
   User=www-data
   WorkingDirectory=/root/news_genesis_scraper
   ExecStart=/root/news_genesis_scraper/venv/bin/python main.py
   Restart=always
   RestartSec=10

   [Install]
   WantedBy=multi-user.target

8. Service എൻഎബ്ൽ ചെയ്യുക:
   sudo systemctl daemon-reload
   sudo systemctl enable news-genesis-scraper
   sudo systemctl start news-genesis-scraper

9. സ്ത്തിതി പരിശോധിക്കുക:
   sudo systemctl status news-genesis-scraper
   
10. നാട്ട് ബ്രൗസ് ഉപയോഗിച്ച് Health check:
    curl http://your_vps_ip:8000/health
"""
