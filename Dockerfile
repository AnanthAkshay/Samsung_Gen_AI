# syntax=docker/dockerfile:1
FROM python:3.10-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Install system audio and build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    git \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# Install primary python dependencies
RUN pip install --upgrade pip && \
    pip install \
    "livekit-agents[google]~=1.3" \
    "livekit-plugins-google==1.8.3" \
    "livekit[crypto]~=1.0" \
    "pydub==0.25.1" \
    "ffmpeg-python==0.2.0" \
    "python-dotenv==1.2.3" \
    "numpy>=1.24.0"

# Copy repository code
COPY . /workspace

# Make reproduction script executable
RUN chmod +x /workspace/reproduce.sh

# Default container entrypoint executes the automated benchmark & verification
ENTRYPOINT ["/bin/bash"]
CMD ["./reproduce.sh"]
