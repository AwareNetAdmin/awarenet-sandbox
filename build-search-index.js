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
  
  // Extract main content (remove scripts, styles, header, footer)
  let textContent = content
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    .replace(/<style\b[^<]*(?:(?!<\/style>)<[^<]*)*<\/style>/gi, '')
    .replace(/<header\b[^<]*(?:(?!<\/header>)<[^<]*)*<\/header>/gi, '')
    .replace(/<footer\b[^<]*(?:(?!<\/footer>)<[^<]*)*<\/footer>/gi, '')
    .replace(/<nav\b[^<]*(?:(?!<\/nav>)<[^<]*)*<\/nav>/gi, '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  
  return {
    id: filename.replace('.html', ''),
    title: title,
    url: filename,
    content: textContent.substring(0, 1000) // First 1000 chars
  };
});

// Write search index
fs.writeFileSync(
  path.join(__dirname, 'search-index.json'),
  JSON.stringify(searchIndex, null, 2)
);

console.log(`✅ Built search index with ${searchIndex.length} pages`);
