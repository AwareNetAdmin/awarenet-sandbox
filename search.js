// AwareNet Search powered by Lunr.js
(function() {
    let searchIndex = null;
    let lunrIndex = null;
    
    // Load search index
    async function loadSearchIndex() {
        if (searchIndex) return searchIndex;
        
        try {
            const response = await fetch('/search-index.json');
            searchIndex = await response.json();
            
            // Build Lunr index
            lunrIndex = lunr(function() {
                this.ref('id');
                this.field('title', { boost: 10 });
                this.field('content');
                
                searchIndex.forEach(doc => {
                    this.add(doc);
                });
            });
            
            return searchIndex;
        } catch (error) {
            console.error('Failed to load search index:', error);
            return [];
        }
    }
    
    // Perform search
    async function performSearch(query) {
        if (!query || query.trim().length < 2) return [];
        
        await loadSearchIndex();
        if (!lunrIndex) return [];
        
        try {
            const results = lunrIndex.search(query);
            return results.map(result => {
                const doc = searchIndex.find(d => d.id === result.ref);
                return {
                    ...doc,
                    score: result.score
                };
            });
        } catch (error) {
            console.error('Search error:', error);
            return [];
        }
    }
    
    // Initialize search box in drawer
    function initSearchBox() {
        const drawerNav = document.querySelector('.drawer nav');
        if (!drawerNav) return;
        
        // Check if already added
        if (document.querySelector('.drawer-search')) return;
        
        const searchForm = document.createElement('form');
        searchForm.className = 'drawer-search';
        searchForm.innerHTML = `
            <input 
                type="search" 
                placeholder="Search..." 
                class="drawer-search-input"
                id="drawer-search-input"
            />
        `;
        
        searchForm.addEventListener('submit', (e) => {
            e.preventDefault();
            const query = document.getElementById('drawer-search-input').value;
            if (query.trim()) {
                window.location.href = `/search?q=${encodeURIComponent(query)}`;
            }
        });
        
        drawerNav.parentNode.insertBefore(searchForm, drawerNav);
    }
    
    // Display search results (for search.html page)
    async function displaySearchResults() {
        const params = new URLSearchParams(window.location.search);
        const query = params.get('q');
        
        if (!query) {
            document.getElementById('search-results').innerHTML = '<p>Enter a search query to find content.</p>';
            return;
        }
        
        document.getElementById('search-query').textContent = query;
        document.getElementById('search-results').innerHTML = '<p>Searching...</p>';
        
        const results = await performSearch(query);
        
        if (results.length === 0) {
            document.getElementById('search-results').innerHTML = `
                <p>No results found for "<strong>${escapeHtml(query)}</strong>".</p>
                <p>Try different keywords or check your spelling.</p>
            `;
            return;
        }
        
        const resultsHTML = results.map(result => `
            <div class="search-result">
                <h3><a href="${result.url}">${escapeHtml(result.title)}</a></h3>
                <p>${escapeHtml(result.content.substring(0, 200))}...</p>
            </div>
        `).join('');
        
        document.getElementById('search-results').innerHTML = `
            <p>Found ${results.length} result${results.length === 1 ? '' : 's'} for "<strong>${escapeHtml(query)}</strong>"</p>
            ${resultsHTML}
        `;
    }
    
    function escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
    
    // Initialize on page load
    document.addEventListener('DOMContentLoaded', () => {
        initSearchBox();
        
        // If on search results page
        if (window.location.pathname.includes('search')) {
            displaySearchResults();
        }
    });
    
    // Export for global access
    window.AwareNetSearch = {
        search: performSearch
    };
})();
