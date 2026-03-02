#!/bin/bash

# Add search scripts to all HTML files (except search.html which already has them)
for file in *.html; do
    if [ "$file" = "search.html" ]; then
        continue
    fi
    
    # Check if search scripts are already added
    if grep -q "lunr.min.js" "$file"; then
        echo "✓ $file already has search"
        continue
    fi
    
    # Add search scripts before </body>
    sed -i '' 's|</body>|    <!-- Lunr.js Search -->\
    <script src="https://cdn.jsdelivr.net/npm/lunr@2.3.9/lunr.min.js"></script>\
    <script src="search.js"></script>\
</body>|' "$file"
    
    echo "✓ Added search to $file"
done

echo ""
echo "✅ Search added to all pages!"
