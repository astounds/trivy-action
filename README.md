# Trivy Image Scan

## Description

Trivy Image Scan is a tool for scanning Docker images for vulnerabilities using Trivy. It integrates seamlessly into CI/CD workflows to perform vulnerability scans on Docker images before deployment.

## Example Usage

Here is a complete example of how to use this action in a GitHub Actions workflow:

```yaml
# .github/workflows/trivy.yml

name: Docker Image Security Scan

on:
  push:
    branches:
      - main

jobs:
  trivy-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Run Trivy scan
        uses: astounds/trivy-action@v1
        with:
          image: 'your-docker-image:latest'
          db-repository: 'ghcr.io/aquasecurity/trivy-db:2'
          java-db-repository: 'ghcr.io/aquasecurity/trivy-java-db:1'
          severity: 'CRITICAL,HIGH'
          pkg-types: 'os'
          format: 'table'
          exit-code: '1'
          version: 'v0.58.2' # eg. latest, v0.57.1, etc
```
