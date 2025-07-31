FROM gitpod/workspace-full

ENV PATH="$HOME/flutter/bin:$PATH"

USER root

# Install Chrome
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google.gpg \
  && echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/google.gpg] http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update && apt-get install -y google-chrome-stable

USER gitpod

# Install Flutter (latest stable)
RUN git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter