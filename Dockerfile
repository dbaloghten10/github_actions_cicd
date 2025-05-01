ARG NODE_VERSION=23.11.0

################################################################################
# Use node image for base image for all stages.
FROM node:${NODE_VERSION}-bullseye-slim@sha256:5cad98f91c1e3802ff3578cdcd1d9d9b8dabd876a0d0c9ca66b23727a1af0c80 AS base

# Set working directory for all build stages.
WORKDIR /usr/src/app

################################################################################
# Create a stage for installing production dependecies.
FROM base AS deps

# Run a clean install of the dependencies omitting any development dependencies
# takes advantage of docker caching
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

################################################################################
# Create a stage for building the application.
FROM deps AS build

# Download additional development dependencies before building, as some projects require
# "devDependencies" to be installed to build. If you don't need this, remove this step.
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci

# Copy the rest of the source files into the image.
COPY . .

RUN sudo chmod -R +x /usr/src/app

# Run the build script.
RUN npm run build

################################################################################
# Create a new stage to run the application with minimal runtime dependencies
# where the necessary files are copied from the build stage.
FROM cgr.dev/chainguard/node:latest AS final

# Use production node environment by default.
ENV NODE_ENV=production

# Copy the production dependencies from the deps stage and also
# the built application from the build stage.
COPY --from=deps /usr/src/app/node_modules ./node_modules
COPY --from=build /usr/src/app/dist ./dist

# Run the application.
CMD ["./dist/server.js"]