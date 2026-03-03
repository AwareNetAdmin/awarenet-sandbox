#!/bin/bash

# Fix internal links to use Firebase clean URLs (remove .html extension)

echo "🔧 Fixing internal links for Firebase clean URLs..."

for file in *.html; do
    [ -f "$file" ] || continue
    echo "  → $file"
    
    # Replace href="*.html" with href="*" (except for external URLs and PDFs)
    # Use perl for in-place editing with backup
    perl -i.bak -pe 's/href="([^"#:]+)\.html"/href="$1"/g' "$file"
    
    # Fix index references: href="index" → href="/"
    perl -i -pe 's/href="index"/href="\/"/g' "$file"
    
    # Remove backup file
    rm -f "${file}.bak"
done

echo "✅ Link fixing complete!"
