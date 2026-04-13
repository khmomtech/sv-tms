# ----------------------------------------------
# my-angular-app/Dockerfile
# ----------------------------------------------

# Stage 1: Build Angular App
FROM node:20-alpine AS builder

WORKDIR /app
ENV CI=true
ENV NODE_OPTIONS=--max-old-space-size=1536

COPY package*.json ./
RUN npm install --legacy-peer-deps

COPY . .
RUN npx ng build --configuration production

# Stage 2: Serve with NGINX
FROM nginx:1.27.5-alpine

# Clean default NGINX website
RUN rm -rf /usr/share/nginx/html/*

# Full nginx.conf (includes http {} wrapper — required when replacing /etc/nginx/nginx.conf)
COPY nginx.conf /etc/nginx/nginx.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Angular 17+ application builder outputs browser assets to dist/{name}/browser/
COPY --from=builder /app/dist/tms-admin-web-ui/browser /usr/share/nginx/html

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
