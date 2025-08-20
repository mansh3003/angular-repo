# Stage 1: Build the Angular application
FROM node:22-alpine AS build

# Set the working directory
WORKDIR /app

# Copy package files and install dependencies
# Use package*.json to cover both package.json and package-lock.json
COPY package*.json ./
RUN npm install 

# Copy the rest of your application source code (including nginx.conf)
COPY . .

# Generate the production build using the script from your package.json
# The output will be in /app/dist/control-tower-angular/browser
#RUN npm run build
RUN npm run ng build -- --configuration=development

# Stage 2: Serve the application with Nginx
FROM nginx:alpine AS final

# --- CRITICAL CHANGES BELOW ---

# 1. Remove default Nginx config to avoid conflicts and ensure yours is used
#    This is important as Nginx might load default configs before custom ones.
RUN rm /etc/nginx/conf.d/default.conf

# 2. Copy your custom Nginx configuration file
#    This was commented out in your original Dockerfile!
#    Ensure nginx.conf is in the same directory as your Dockerfile.
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 3. Copy the static files from the build stage to the Nginx public HTML directory
#    Your `outputPath` in angular.json is "dist/control-tower-angular".
#    The `npm run build-prod` script will produce files under /app/dist/control-tower-angular/browser
#    So, the source path in COPY --from=build should be /app/dist/control-tower-angular/browser
COPY --from=build /app/dist/control-tower-angular/browser /usr/share/nginx/html

# Expose port 80, which is the default HTTP port Nginx listens on
EXPOSE 80

# The default Nginx command starts the server. This is for clarity.
CMD ["nginx", "-g", "daemon off;"]