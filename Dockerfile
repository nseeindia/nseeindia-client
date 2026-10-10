
FROM nginx:alpine
RUN echo '<h1>NSEE GHCR Test Successful!</h1>' > /usr/share/nginx/html/index.html
