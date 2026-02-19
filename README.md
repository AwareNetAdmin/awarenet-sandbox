# AwareNet Sandbox Website

Sandbox site for testing AwareNet homepage designs and content.

**Live Site:** https://sandbox.awarenet.us

## Deployment

The site is automatically deployed to Google Cloud Storage bucket `sandbox.awarenet.us`.

To deploy changes:
```bash
./deploy.sh
```

## Files

- `index.html` - Main homepage
- `404.html` - Error page
- `deploy.sh` - Deployment script
- `assets/` - Images, CSS, JS files

## Development

1. Make changes to HTML/CSS files
2. Test locally by opening `index.html` in browser
3. Commit changes to git
4. Run deployment script to update live site

## Domain

- **Sandbox:** sandbox.awarenet.us (CNAME → c.storage.googleapis.com)
- **Production:** www.awarenet.us (Squarespace)