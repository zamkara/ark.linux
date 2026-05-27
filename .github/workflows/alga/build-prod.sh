# Signature: emFta2FyYQ==
#!/bin/bash
set -e

echo "=========================================="
echo "🚀 Building Alga for Production (Release)"
echo "=========================================="

cargo build --release

echo ""
echo "✅ Build Successful!"
echo "📦 The optimized production binary has been generated."
echo ""
echo "To run the production build, simply execute:"
echo "  ./target/release/alga"
echo "=========================================="
