# Define custom function directory
ARG FUNCTION_DIR="/function"

FROM node:20-bookworm as build-image

# Include global arg in this stage of the build
ARG FUNCTION_DIR

# Set working directory
WORKDIR ${FUNCTION_DIR}

# Copy package files first for better caching
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source files
COPY . .

# Build TypeScript
RUN npm run build

# Install Puppeteer browser
RUN npx puppeteer browsers install chrome

FROM node:20-bookworm-slim as runtime

ARG FUNCTION_DIR
ENV NODE_ENV=production

# Install required dependencies for Chrome
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libc6 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libexpat1 \
    libfontconfig1 \
    libgbm1 \
    libgcc1 \
    libglib2.0-0 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libstdc++6 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    lsb-release \
    wget \
    xdg-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy function code from the build image
WORKDIR ${FUNCTION_DIR}
COPY --from=build-image ${FUNCTION_DIR}/node_modules ./node_modules
COPY --from=build-image ${FUNCTION_DIR}/dist ./dist
COPY --from=build-image ${FUNCTION_DIR}/package.json ./
COPY --from=build-image ${FUNCTION_DIR}/.puppeteerrc.cjs ./

# Copy Chrome from the build image
COPY --from=build-image /root/.cache/puppeteer /root/.cache/puppeteer

# Set the AWS Lambda Runtime Interface Client
RUN npm install aws-lambda-ric

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/npx", "aws-lambda-ric"]
CMD ["dist/index.handler"]