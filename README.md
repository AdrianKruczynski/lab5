# Technologie Chmurowe

## Server Node + Express

```
const express = require('express')
const os = require('os')
const app = express()

//const PORT = process.env.PORT
const PORT = '3000'
const hostname = os.hostname();

const getIPAddress = () => {
  const ifaces = os.networkInterfaces()
  let ipAddress

  Object.keys(ifaces).forEach((ifname) => {
    ifaces[ifname].forEach((iface) => {
      if (iface.family === 'IPv4' && !iface.internal) {
        ipAddress = iface.address
      }
    })
  })

  return ipAddress
}
const address = getIPAddress()

const data = `<h1>TEST IP: ${address}:${PORT} </h1> <h1> Hostname: ${hostname} </h1> <h1> Version: ${process.env.VERSION} </h1> `

app.get("/", (req, res) => {
        res.send(data)
})

app.listen(PORT, () => {
  console.log(`Server running at http://${hostname}:${PORT}/`);
});
```

## package.json

```
{
  "name": "node",
  "version": "1.0.0",
  "description": "",
  "main": "server.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1",
    "start": "node server.js"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "express": "^4.18.2",
    "os": "^0.1.2",
    "request": "^2.88.2"
  }
}
```

## Dockerfile

```
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
```

## Network

```
docker network create -d bridge --subnet=10.10.10.0/24 node_network
```

## Build
node

```
docker build -t node_app:1.0.0 --target node_stage .
```
nginx

```
docker build -t nginx_app:1.0.0 --target nginx_stage .
```

## Run
node

```
docker run -itd --rm --name node_app -p 3000:3000 --network node_network --ip=10.10.10.10 node_app:1.0.0
```
nginx

```
docker run -itd --rm --name nginx_app -p 88:80 --network node_network --ip=10.10.10.20 nginx_app:1.0.0
```

`lub` 

node (+ VERSION)

```
docker run -itd --rm --name node_app -p 3000:3000 --network node_network --ip=10.10.10.10 -e VERSION=1.2.3 node_app:1.0.0
```

## Curl

```
➜ curl http://localhost:88
<h1>TEST IP: 10.10.10.10:3000 </h1> <h1> Hostname: e4020c5aa105 </h1> <h1> Version: 3.14 </h1>
```

`lub`

```
➜ curl http://localhost:88
<h1>TEST IP: 10.10.10.10:3000 </h1> <h1> Hostname: bfa9f27081a9 </h1> <h1> Version: 3.2.1 </h1>
```

## docker images

```
REPOSITORY        TAG       IMAGE ID       CREATED          SIZE
nginx_app         1.0.0     4aa8d537df0d   22 minutes ago   148MB
node_app          1.0.0     1585932774b6   4 hours ago      72.1MB
```

## docker ps

```
➜ docker ps
CONTAINER ID   IMAGE             COMMAND                  CREATED              STATUS                        PORTS                        NAMES
b3ac386be0e8   nginx_app:1.0.0   "/docker-entrypoint.…"   About a minute ago   Up About a minute (healthy)   88/tcp, 0.0.0.0:88->80/tcp   nginx_app
bfa9f27081a9   node_app:1.0.0    "npm start"              6 minutes ago        Up 6 minutes                  0.0.0.0:3000->3000/tcp       node_app
```
