#!/bin/bash

# Script to update golden screenshot files for Tamil Setu app
# Run this script from the repository root directory

set -e

echo "🖼️  Updating golden screenshot files..."
echo ""

cd tamil_setu

# Update golden files
flutter test --update-goldens test/screenshots/generate_screenshots_test.dart

echo ""
echo "✅ Golden files updated successfully!"
echo ""
echo "📝 Next steps:"
echo "   1. Review the updated golden images in:"
echo "      tamil_setu/metadata/en-US/images/"
echo "   2. Commit the changes:"
echo "      git add metadata/"
echo "      git commit -m 'Update golden screenshot files for new Dashboard UI'"
echo "   3. Push to your branch:"
echo "      git push"
echo ""
