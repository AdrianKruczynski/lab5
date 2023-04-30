# Build stage - node
ARG VERSION
FROM scratch as node_stage

ADD alpine-minirootfs-3.17.3-aarch64.tar.gz /

WORKDIR /app

RUN apk add --no-cache nodejs npm

COPY node/package*.json ./
COPY node/server.js .

RUN npm install

ENV VERSION=${VERSION:-3.14}

EXPOSE 3000

CMD [ "npm", "start" ]

# Nginx 
FROM nginx:1.23.4 as nginx_stage
COPY default.conf /etc/nginx/conf.d/default.conf
COPY --from=node_stage /app /usr/share/nginx/html
EXPOSE 88
HEALTHCHECK --interval=60s --timeout=1s \
        CMD curl -f http://localhost:80 || exit 1
