# Flutter Docker Image for Testing
FROM ubuntu:22.04

# Prevent dialog during apt install
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter SDK
ENV FLUTTER_VERSION=3.16.0
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME}

# Pre-download Flutter dependencies
RUN flutter precache
RUN flutter config --no-analytics
RUN flutter doctor

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.yaml
COPY pubspec.lock* pubspec.lock

# Get dependencies
RUN flutter pub get

# Copy the rest of the code
COPY . .

# Default command
CMD ["flutter", "test"]
