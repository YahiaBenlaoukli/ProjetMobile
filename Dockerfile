# Stage 1: Build the Flutter web application
FROM ghcr.io/cirruslabs/flutter:stable AS build-env

# Set the working directory
WORKDIR /app

# Copy the app files to the container
COPY . .

# Get dependencies and build for web
RUN flutter pub get
RUN flutter build web

# Stage 2: Serve the application using Nginx
FROM nginx:alpine

# Copy the built web files from the build stage
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
