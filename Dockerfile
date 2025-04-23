ARG FUNCTION_DIR="/function"

FROM public.ecr.aws/docker/library/node:20-bookworm as build-image

ARG FUNCTION_DIR

WORKDIR ${FUNCTION_DIR}

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

RUN npx puppeteer browsers install chrome

FROM public.ecr.aws/docker/library/node:20-bookworm-slim as runtime

ARG FUNCTION_DIR
ENV NODE_ENV=production

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    cmake \
    autoconf \
    automake \
    libtool \
    build-essential \
    python3 \
    python-is-python3 \
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

WORKDIR ${FUNCTION_DIR}
COPY --from=build-image ${FUNCTION_DIR}/node_modules ./node_modules
COPY --from=build-image ${FUNCTION_DIR}/dist ./dist
COPY --from=build-image ${FUNCTION_DIR}/package.json ./
COPY --from=build-image ${FUNCTION_DIR}/.puppeteerrc.cjs ./

COPY --from=build-image /root/.cache/puppeteer /root/.cache/puppeteer

# Install aws-lambda-ric using the node-gyp python parameter directly
RUN PYTHON=/usr/bin/python3 npm install aws-lambda-ric

ENTRYPOINT ["/usr/local/bin/npx", "aws-lambda-ric"]
CMD ["dist/index.handler"]