# ----------------------------------------------
# my-angular-app/Dockerfile
# ----------------------------------------------

# Stage 1: Build Angular App
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install --legacy-peer-deps

COPY . .
RUN npm run build -- --configuration production

# Stage 2: Serve with NGINX
FROM nginx:1.27.5-alpine

# Clean default NGINX website
RUN rm -rf /usr/share/nginx/html/*

# Full nginx.conf (includes http {} wrapper — required when replacing /etc/nginx/nginx.conf)
COPY nginx.conf /etc/nginx/nginx.conf

# Angular 17+ application builder outputs browser assets to dist/{name}/browser/
COPY --from=builder /app/dist/tms-admin-web-ui/browser /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
