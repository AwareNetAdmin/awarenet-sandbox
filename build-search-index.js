#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// Read all HTML files and build search index
const htmlFiles = fs.readdirSync(__dirname)
  .filter(f => f.endsWith('.html') && !f.startsWith('404'));

const searchIndex = htmlFiles.map(filename => {
  const content = fs.readFileSync(path.join(__dirname, filename), 'utf-8');
  
  // Extract title
  const titleMatch = content.match(/<title>(.*?)<\/title>/i);
  const title = titleMatch ? titleMatch[1].replace(' - AwareNet', '').trim() : filename;
  
  // Extract main content (remove scripts, styles, header, footer, drawer UI)
  let textContent = content
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    .replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, '')
    .replace(/<header\b[^<]*(?:(?!<\/header>)<[^<]*)*<\/header>/gi, '')
    .replace(/<footer\b[^<]*(?:(?!<\/footer>)<[^<]*)*<\/footer>/gi, '')
    .replace(/<nav\b[^<]*(?:(?!<\/nav>)<[^<]*)*<\/nav>/gi, '')
    .replace(/<div class="drawer-overlay"[^>]*>[\s\S]*?<\/div>/gi, '')
    .replace(/<div class="drawer"[^>]*>[\s\S]*?<\/div>\s*<\/div>/gi, '')
    .replace(/<div[^>]*class="[^"]*modal[^"]*"[^>]*>[\s\S]*?<\/div>/gi, '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&times;/g, '')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, ' ')
    .trim();
  
  // Remove title duplication from content start
  const titlePattern = new RegExp(`^${title.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\s*[-–—]?\\s*AwareNet\\s*`, 'i');
  textContent = textContent.replace(titlePattern, '').trim();
  
  return {
    id: filename.replace('.html', ''),
    title: title,
    url: filename.replace('.html', ''), // Clean URL without .html
    content: textContent.substring(0, 10000) // First 10000 chars
  };
});

// Write search index
fs.writeFileSync(
  path.join(__dirname, 'search-index.json'),
  JSON.stringify(searchIndex, null, 2)
);

console.log(`✅ Built search index with ${searchIndex.length} pages`);
