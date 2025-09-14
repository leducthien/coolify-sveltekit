# Build stage
# https://hub.docker.com/_/node
FROM node:22.19-alpine3.22 AS builder

RUN mkdir -p /home/node/app/node_modules && chown -R node:node /home/node/app

WORKDIR /home/node/app

# Next, copy the package.json and package-lock.json (for npm 5+) files:
COPY --chown=node:node package*.json ./

# To ensure that all of the application files are owned by the non-root node user, including the contents of the node_modules directory, switch the user to node before running npm install
USER node

RUN npm install

# Next, copy your application code with the appropriate permissions to the application directory on the container. 
COPY --chown=node:node . .

RUN npm run build

# Production stage
FROM node:22.19-alpine3.22

RUN mkdir -p /home/node/app/build && chown -R node:node /home/node/app

WORKDIR /home/node/app

COPY --chown=node:node --from=builder /home/node/app/package*.json ./

USER node

RUN npm ci --omit dev

COPY --chown=node:node --from=builder /home/node/app/build ./build/

ENV PORT=3000
EXPOSE $PORT

# Run index.js in the build folder
CMD ["node", "build"]