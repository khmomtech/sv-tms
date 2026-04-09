#!/bin/bash

# Extract incident-detail files
echo "Processing incident-detail component..."
sed -n '12,298p' incident-detail.component.ts.backup | sed '1d' > incident-detail.component.html
sed -n '300,957p' incident-detail.component.ts.backup | sed '1d' | sed '$s/  `\]$//' > incident-detail.component.css

# Extract incident-form files  
echo "Processing incident-form component..."
sed -n '20,257p' incident-form.component.ts.backup | sed '1d' > incident-form.component.html
sed -n '259,514p' incident-form.component.ts.backup | sed '1d' | sed '$s/  `\]$//' > incident-form.component.css

echo "Done extracting templates and styles!"
