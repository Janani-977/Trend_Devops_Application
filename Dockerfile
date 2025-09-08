# Use lightweight Nginx image
FROM nginx:alpine

# Remove default Nginx files
RUN rm -rf /usr/share/nginx/html/*

# Copy your static site into Nginx's web root
COPY dist/ /usr/share/nginx/html

# Expose port 80 inside container
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]