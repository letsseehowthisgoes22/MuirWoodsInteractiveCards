# GitHub Copilot Instructions for Interactive Card Reader Muir Wood

## Project Overview
This is a white-labeled business card scanner application branded for "Interactive Card Reader Muir Wood". It's a serverless web application that digitizes business cards using AI-powered OCR and provides contact management with network analysis.

**Architecture:**
- **Frontend**: Static web app (HTML/CSS/JS) in `FrontendBucket/` served via S3/CloudFront
- **Backend**: AWS SAM stack (keep unchanged unless explicitly required):
  - API Gateway → Lambda application (OCR pipeline & contact parsing)
  - Storage: DynamoDB for contacts, S3 for uploads
  - OCR: AWS Textract with DeepSeek AI post-processing
  - Auth: AWS Cognito (custom modal authentication)
  - Timeouts: Lambda up to 900s, API Gateway integration 60s for long OCR processing

**DO NOT** change infrastructure (template.yaml, SAM config) unless absolutely necessary to fix a blocking issue. If infra changes are required, propose minimal diff and stop for approval.

## Branding & UX Requirements (Frontend Only)
- **Product name**: Interactive Card Reader Muir Wood
- **Header**: Show Muir Wood logo ABOVE the product name
- **Tabs** (labels): Scan, Contacts, Insights, Assistant
- **Footer**: Bottom-left on every page → B-Health Ventures LLC logo + text "B-Health Ventures LLC"
- **Theme**: Clean white, high-contrast. CSS variables for brand colors with sane defaults. Runtime overrides allowed.
- **vCard filenames**: Must end with `-InteractiveHealth.vcf`
- **Colors**: Primary #4a815a (Muir Wood green), Secondary #7ca7ad (Muir Wood blue)

## Runtime Configuration
File: `FrontendBucket/app-config.js`
```javascript
window.__APP_CONFIG__ = {
  apiBaseUrl: "", // blank = use relative "/api"
  brandName: "Interactive Card Reader Muir Wood",
  cognito: { userPoolId: "", clientId: "", domain: "muirwood-cards" }
};
```
- Frontend reads APP_CONFIG, applies colors to `:root`, sets app name
- Use `apiBaseUrl` **only** when code hardcodes a demo domain. Keep relative paths as-is.
- This file is auto-generated during deployment. Manual edits will be overwritten.

## Core Features & Behaviors

### 1. Scan/Upload
- Accept image/PDF (drag/drop + file picker)
- Client-side validation: size/type checks, progress UI
- Call backend `/api/upload` (or existing relative path)
- Robust error states with user-friendly messages and retry

### 2. Parse & Normalize
- Backend returns OCR text + structured fields (name, company, title, phones, emails, website, address)
- Normalize: E.164 phone, lowercase emails, strip punctuation, basic URL cleanup

### 3. Deduplication
- Detect duplicates by email or phone; fuzzy match name+company when missing
- Show merge suggestion UI; never silently drop data

### 4. Contacts
- List, search/filter, pagination or virtualized list
- Single contact view: raw OCR + parsed fields, quick edit, "Export vCard"
- Bulk export: single `.vcf` with multiple cards (filename: `*-InteractiveHealth.vcf`)

### 5. Insights
- Lightweight aggregates: top companies, common titles, recent scans
- No heavy visualizations required

### 6. Assistant
- Embed help/chat UI inside the **Assistant** tab (not floating button)
- If no chat backend, show static help/FAQ and usage tips

## Quality Standards (Non-Negotiable)

### Accessibility
- Keyboard navigation, focus states, labels
- ARIA roles on tabs/panels
- WCAG AA color contrast

### Resilience
- No uncaught exceptions
- Defensive checks for undefined/empty fields
- Graceful API failure handling

### Network/CORS
- Keep relative paths working
- If hardcoded absolute URL exists, gate behind `APP_CONFIG.apiBaseUrl`

### Security
- Never use `eval`
- Sanitize rendered text
- Never embed secrets in frontend

### Performance
- Don't block UI on large uploads; show progress
- Avoid massive DOM reflows for lists

### Licensing
- Keep upstream LICENSE
- Maintain NOTICE if exists
- Non-commercial internal use

## File Structure

### Frontend (`FrontendBucket/`)
- `index.html`: Title, header stack (logo above name), tabs, footer, loads `app-config.js` before `script.js`
- `styles.css`: White theme, CSS vars, header/tabs/footer, responsive
- `script.js`: Config consumption, tab logic, upload flow, API calls, vCard export helper
- `app-config.js`: Runtime configuration (created/updated as shown above)
- `service-worker.js`: PWA caching for offline access
- `site.webmanifest`: PWA metadata
- Assets: `muirwood-logo.png` (header), `bhealth-logo.png` (footer), favicons

### Backend (`application/`)
- `app.py`: Lambda handler for API endpoints
- `requirements.txt`: Python dependencies (boto3, openai)
- `layer/`: Python dependencies packaged for Lambda layer

### Infrastructure
- `template.yaml`: AWS SAM template (DO NOT modify unless absolutely necessary)
- `samconfig.toml`: SAM CLI configuration
- `deploy.sh`: Deployment automation script
- `nuke.sh`: Resource cleanup script

## Common Tasks & Fixes

### What to Fix (Even If Not Mentioned)
- Broken tab switching, missing panels, stale selectors
- vCard naming not following `-InteractiveHealth.vcf` suffix
- Hardcoded API bases → use APP_CONFIG fallback
- Missing error handling for upload/OCR timeouts
- Unbounded file sizes and MIME types → add client-side checks
- Contacts table issues: sorting, filtering, pagination
- Layout regressions on mobile/tablet
- Leftover brand strings from upstream project

### Build & Test Commands
```bash
# Build SAM application
sam build

# Deploy (requires env vars: DEEPSEEK_API_KEY, DOMAIN_NAME, ACM_CERTIFICATE_ARN)
./deploy.sh

# Local testing
sam local start-api

# Frontend testing: open index.html in browser or use local server
python -m http.server 8000 --directory FrontendBucket
```

### Testing Checklist
- Title + header show Muir Wood logo correctly
- Tabs switch with keyboard and persist active styling
- Upload works for common image/PDF (jpg/png/pdf)
- Rejection message for >10MB or invalid types
- After upload, parsed contact renders
- Dedupe suggestions show when appropriate
- Contacts list supports search and bulk export
- Exported filename ends with `-InteractiveHealth.vcf`
- Insights panel renders without crashing on empty data
- Assistant tab loads inside the tab (not floating)
- No 404s for logo/icon files
- Mobile responsive layout works
- No infrastructure file edits

## Development Guidelines

### Code Style
- Match existing code style and patterns
- Don't add comments unless they match existing style
- Use existing libraries; only add new ones if absolutely necessary
- Keep changes minimal and surgical

### API Integration
- Backend endpoints are already implemented in `application/app.py`
- Frontend calls via `API_URL` variable set from `window.__APP_CONFIG__?.apiBaseUrl`
- All endpoints return JSON responses
- Authentication uses AWS Cognito (handled in script.js)

### State Management
- In-memory array `contactsData` stores contacts
- Chart.js for visualizations (`window.companyDistributionChart`, `window.industryInsightsChart`)
- Tab state managed via classes and hidden attribute

### Error Handling Pattern
```javascript
try {
    // API call or operation
} catch (error) {
    console.error('Operation failed:', error);
    showToast('User-friendly error message', 'error');
}
```

## Security & Privacy
- Don't share sensitive data with 3rd party systems
- Don't commit secrets to source code
- Don't violate copyrights
- Don't generate harmful content
- Follow the repository's CC BY-NC-SA 4.0 license

## Deployment Notes
- `deploy.sh` automatically injects configuration into `app-config.js`
- CloudFront cache invalidation runs after deployment
- Test user (testUser/12345678!) created automatically
- Domain configured in template.yaml (cards.muirwood.internal)
- ACM certificate required for HTTPS

## Resources
- Original README: [README.md](../README.md)
- White-label guide: [README-WL.md](../README-WL.md)
- AWS SAM documentation: https://docs.aws.amazon.com/serverless-application-model/
- Cognito identity JS: https://github.com/aws-amplify/amplify-js/tree/main/packages/amazon-cognito-identity-js

## When Stuck
- Review existing code patterns in `FrontendBucket/script.js`
- Check `README-WL.md` for white-label configuration details
- Check `README.md` for troubleshooting common issues
- Ensure changes are frontend-only unless explicitly approved
- Propose minimal infrastructure changes separately if truly required
