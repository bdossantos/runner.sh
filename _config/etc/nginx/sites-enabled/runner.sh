server {
  listen 80;

  server_name www.runner.sh;

  return 301 $scheme://runner.sh$request_uri;
}

server {
  listen 80;

  server_name runner.sh;

  root /usr/src/app/_build/;

  charset utf-8;

  etag on;

  gzip_static on;

  # Custom 404 page
  error_page 404 /404.html;

  access_log /var/log/nginx/runner.sh.access.log combined;
  error_log /var/log/nginx/runner.sh.error.log;

  # Include the basic h5bp config set
  include h5bp/basic.conf;
}
