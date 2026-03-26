#!/bin/bash

# Setup Vercel for auto-deploying EPG XML
# Works with private repos and auto-updates

REPO_DIR="/Users/ah/CascadeProjects/windsurf-project"

cd "$REPO_DIR"

echo "Setting up Vercel for EPG hosting..."
echo ""
echo "Steps:"
echo "1. Create Vercel account: https://vercel.com"
echo "2. Connect your GitHub account"
echo "3. Import this repository: r56wdvm6d5-cloud/epguk"
echo "4. Configure deployment settings:"
echo "   - Build Command: echo 'No build needed'"
echo "   - Output Directory: ."
echo "   - Install Command: echo 'No install needed'"
echo "5. Deploy"
echo ""
echo "Vercel will automatically redeploy when you push to GitHub!"
echo ""

# Create vercel.json configuration
cat > vercel.json << 'EOF'
{
  "version": 2,
  "builds": [
    {
      "src": "epg.xml",
      "use": "@vercel/static"
    }
  ],
  "routes": [
    {
      "src": "/epg.xml",
      "dest": "/epg.xml"
    },
    {
      "src": "/",
      "dest": "/index.html"
    }
  ]
}
EOF

echo "Created vercel.json configuration"
echo "After setting up Vercel, your EPG will be available at:"
echo "https://your-project-name.vercel.app/epg.xml"
echo ""
echo "And it will AUTO-UPDATE when you push to GitHub!"
