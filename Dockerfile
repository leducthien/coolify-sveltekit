# Build stage

# Node image from here: https://hub.docker.com/_/node
FROM node:22.19-alpine3.22 AS builder

# By default, the Docker Node image includes a non-root node user that you can use to avoid running your application container as root. It is a recommended security practice to avoid running containers as root and to restrict capabilities within the container to only those required to run its processes. We will therefore use the node user’s home directory as the working directory for our application and set them as our user inside the container
RUN mkdir -p /home/node/app && chown -R node:node /home/node/app

WORKDIR /home/node/app

# Next, copy the package.json and package-lock.json (for npm 5+) files:
COPY --chown=node:node package*.json ./

# To ensure that all of the application files are owned by the non-root node user, including the contents of the node_modules directory, switch the user to node before running npm install
USER node

RUN npm install

# Next, copy your application code with the appropriate permissions to the application directory on the container. 
COPY --chown=node:node . .

RUN npm run build

# Remove development dependencies
RUN npm prune --omit=dev

# Final stage

FROM node:22.19-alpine3.22

# Install curl for the healthcheck
RUN apk add --no-cache curl

RUN mkdir -p /home/node/app && chown -R node:node /home/node/app

WORKDIR /home/node/app

USER node

COPY --chown=node:node --from=builder /home/node/app/package.json ./
COPY --chown=node:node --from=builder /home/node/app/build ./build/
COPY --chown=node:node --from=builder /home/node/app/node_modules ./node_modules/

# Sveltekit runs on port 3000 by default
EXPOSE 3000

ENV NODE_ENV=production

# Healthcheck: fail if the endpoint isn’t reachable
HEALTHCHECK --interval=30s --timeout=30s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1

# Run index.js in the build folder
CMD ["node", "build"]