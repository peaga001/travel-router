FROM ubuntu:22.04

ARG USER_ID=1000
ARG GROUP_ID=1000
ARG FLUTTER_CHANNEL=stable
# Update from: https://developer.android.com/studio#command-tools
ARG CMDLINE_TOOLS_VERSION=11076708

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV ANDROID_HOME=/opt/android-sdk
ENV FLUTTER_HOME=/opt/flutter
ENV PUB_CACHE=/home/flutterdev/.pub-cache
ENV PATH="${FLUTTER_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    wget \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    android-tools-adb \
    usbutils \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user matching host UID/GID
RUN groupadd -g "${GROUP_ID}" flutterdev \
    && useradd -u "${USER_ID}" -g "${GROUP_ID}" -m -s /bin/bash flutterdev

# Install Flutter SDK
RUN git clone \
        --depth 1 \
        --branch "${FLUTTER_CHANNEL}" \
        https://github.com/flutter/flutter.git \
        "${FLUTTER_HOME}" \
    && chown -R "${USER_ID}:${GROUP_ID}" "${FLUTTER_HOME}"

# Install Android command-line tools
RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" \
    && wget -q \
        "https://dl.google.com/android/repository/commandlinetools-linux-${CMDLINE_TOOLS_VERSION}_latest.zip" \
        -O /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip -d "${ANDROID_HOME}/cmdline-tools" \
    && mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest" \
    && rm /tmp/cmdline-tools.zip \
    && chown -R "${USER_ID}:${GROUP_ID}" "${ANDROID_HOME}"

USER flutterdev

# Pre-create Gradle home so the Docker volume initialises with correct ownership
RUN mkdir -p /home/flutterdev/.gradle

# Accept licenses and install required SDK components
RUN yes | sdkmanager --licenses > /dev/null 2>&1 || true \
    && sdkmanager \
        "platform-tools" \
        "platforms;android-34" \
        "build-tools;34.0.0"

# Pre-cache Flutter artifacts (Android + Web)
RUN flutter precache --android --web \
    && flutter config \
        --android-sdk "${ANDROID_HOME}" \
        --no-analytics \
        --enable-web

WORKDIR /app

CMD ["/bin/bash"]
