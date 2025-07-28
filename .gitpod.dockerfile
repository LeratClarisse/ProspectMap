FROM gitpod/workspace-full

# Set environment variables
ENV PATH="$HOME/flutter/bin:$PATH"

USER gitpod

# Download the latest stable version of Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter

# Enable Flutter Web and run doctor
RUN flutter config --enable-web \
    && flutter precache \
    && flutter doctor
