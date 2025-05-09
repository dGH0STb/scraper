#!/bin/bash
set -e  # Exit immediately if any command fails

echo "command - npx tsc"
npx tsc

echo "command - aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 429744660197.dkr.ecr.us-west-2.amazonaws.com"
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 429744660197.dkr.ecr.us-west-2.amazonaws.com

# Check if the repository exists, create it if it doesn't
aws ecr describe-repositories --repository-names scraper --region us-west-2 || aws ecr create-repository --repository-name scraper --region us-west-2

echo "command - docker build --platform linux/amd64 --progress=plain -t scraper ."
docker build --platform linux/amd64 --progress=plain -t scraper .

echo "command - docker tag scraper:latest 429744660197.dkr.ecr.us-west-2.amazonaws.com/scraper:latest"
docker tag scraper:latest 429744660197.dkr.ecr.us-west-2.amazonaws.com/scraper:latest

echo "command - docker push 429744660197.dkr.ecr.us-west-2.amazonaws.com/scraper:latest"
docker push 429744660197.dkr.ecr.us-west-2.amazonaws.com/scraper:latest