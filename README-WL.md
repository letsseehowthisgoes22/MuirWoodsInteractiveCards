# White-Label Configuration Guide: Interactive Card Reader Muir Wood

This document describes how to configure and deploy the white-labeled "Interactive Card Reader Muir Wood" application.

## Overview

This is a white-labeled version of the Business Card Scanner app, rebranded for Muir Wood Teen Treatment Centers.

**Key Changes:**
- App name: "Interactive Card Reader Muir Wood"
- Tabs: Scan, Contacts, Insights, Assistant
- Primary color: #4a815a (Muir Wood green)
- Secondary color: #7ca7ad (Muir Wood blue)
- Domain: cards.muirwood.internal

## Configuration

### 1. App Configuration (app-config.js)

The `FrontendBucket/app-config.js` file contains runtime configuration. During deployment, `deploy.sh` automatically injects:
- `apiBaseUrl`: API Gateway endpoint
- `cognito.userPoolId`: Cognito User Pool ID
- `cognito.clientId`: Cognito User Pool Client ID
- `cognito.domain`: Reserved Cognito domain prefix (muirwood-cards) for future Hosted UI

**Note:** This file is auto-generated during deployment. Manual edits will be overwritten.

### 2. Domain Configuration (template.yaml)

Update the `DomainName` parameter in `template.yaml`:
```yaml
Parameters:
  DomainName:
    Default: "cards.muirwood.internal"
```

This domain is used for:
- Frontend S3 bucket name
- CloudFront distribution alias
- CORS allowed origins

### 3. CORS Configuration

CORS is configured to allow only the specified domain:
- **BackendBucket S3 CORS**: `https://cards.muirwood.internal`
- **API Gateway CORS**: `https://cards.muirwood.internal`

To change the allowed origin, update the `DomainName` parameter.

### 4. SSL Certificate

Update the `ACMCertificateArn` parameter in `template.yaml` with your ACM certificate ARN for the domain.

### 5. Branding Assets

**Logo & Favicon:**
Replace the following files in `FrontendBucket/`:
- `favicon.ico` - Browser favicon
- `favicon-16x16.png` - 16x16 favicon
- `favicon-32x32.png` - 32x32 favicon
- `apple-touch-icon.png` - Apple touch icon (180x180)
- `android-chrome-192x192.png` - Android icon (192x192)
- `android-chrome-512x512.png` - Android icon (512x512)

Optionally add:
- `logo.svg` - Application logo (reference in index.html if needed)

### 6. Progressive Web App (PWA)

The app is now installable as a PWA on mobile devices, providing an app-like experience:

**Features:**
- **Install to Home Screen**: Users can add the app to their mobile home screen via browser menu
- **Offline Access**: Previously viewed contacts remain accessible without internet
- **App-like UI**: Runs in standalone mode without browser chrome
- **Fast Loading**: Static assets are cached for instant loading

**Technical Details:**
- `site.webmanifest`: App metadata with Muir Wood branding, colors (#4a815a theme, #f7f5ef background)
- `service-worker.js`: Caches static assets (HTML, CSS, JS, icons, CDN libraries) for offline use
- PWA meta tags: Theme color, Apple web app capable, mobile viewport

**Installation:**
- **iOS**: Safari → Share → Add to Home Screen
- **Android**: Chrome → Menu → Add to Home Screen / Install App

The service worker uses a cache-first strategy for static assets and a network-first strategy with cache fallback for API requests, ensuring the app works offline while keeping data fresh when online.

## Deployment

### Prerequisites
- AWS CLI configured with appropriate credentials
- AWS SAM CLI installed
- ACM certificate for your domain
- API Gateway timeout limit increased to 60000ms (see original README)

### Deploy Steps

1. **Build the application:**
   ```bash
   sam build
   ```

2. **Deploy the stack:**
   ```bash
   ./deploy.sh
   ```

   The deploy script will:
   - Deploy CloudFormation stack
   - Inject configuration into app-config.js
   - Sync frontend assets to S3
   - Create test user
   - Invalidate CloudFront cache

### Verification

After deployment:
1. Access the site at `https://cards.muirwood.internal`
2. Sign in with test credentials (username: testUser, password: 12345678!)
3. Navigate through all tabs: Scan, Contacts, Insights, Assistant
4. Upload a test business card → verify it appears in Contacts
5. Test the Assistant tab (formerly chat interface)

## Features

- **Scan Tab**: Upload business card images for processing
- **Contacts Tab**: View, edit, download contacts as vCards
- **Insights Tab**: Network analysis and visualizations
- **Assistant Tab**: AI assistant for querying your contact database

## Architecture

Infrastructure remains unchanged from the original:
- Lambda function (900s timeout)
- API Gateway (60s integration timeout)
- DynamoDB for contacts storage
- S3 for image storage
- Cognito for authentication
- CloudFront for content delivery

## License

Original project: CC BY-NC-SA 4.0
White-label customization: Maintains functionality per license requirements.

## Support

For deployment issues, refer to the original [README.md](README.md) troubleshooting section.
