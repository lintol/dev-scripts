#!/bin/bash

source ./settings.sh
source ./settings-calculated.sh


# NGINX

echo
echo
echo "INSTALL NGINX REVERSE PROXY"
echo

sudo apt-get install -y nginx

sudo rm -f /etc/nginx/sites-available/default
echo "
server {
    index index.html index.htm index.nginx-debian.html;
    server_name $LINTOL_SITE;


	location / {
		proxy_pass http://localhost:8082/;
		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-Proto \$scheme;
	}

    listen 80;
}
server {
    index index.html index.htm index.nginx-debian.html;
    server_name $CKAN_SITE;


    location / {
    	proxy_pass http://localhost:5000/;
    	proxy_set_header Host \$host;
    	proxy_set_header X-Real-IP \$remote_addr;
    	proxy_set_header X-Forwarded-Proto https;
    }
}
" > /tmp/default
sudo mv /tmp/default /etc/nginx/sites-available/default

sudo add-apt-repository -y ppa:certbot/certbot
sudo apt-get update
sudo apt-get install -y python-certbot-nginx
# THIS MAY NEED THE 1 REMOVED FOR A FRESH SERVER (it's whether the cert is reinstalled/renewed with remote throttling)
echo "
1
2
" | sudo certbot --nginx --agree-tos -m info@flaxandteal.co.uk
