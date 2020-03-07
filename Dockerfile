FROM mcr.microsoft.com/powershell:6.2.3-ubuntu-16.04
LABEL maintainer="Matthew Kelly (Badgerati)"

# update
RUN apt-get update -qqy \
    && apt-get -qqy --no-install-recommends install \
        curl \
        bzip2 \
        unzip \
        wget

# install chrome
RUN apt-get install -y libappindicator1 fonts-liberation

ARG CHROME_VERSION="google-chrome-stable"
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update -qqy \
    && apt-get -qqy install \
        ${CHROME_VERSION:-google-chrome-stable} \
    && rm /etc/apt/sources.list.d/google-chrome.list \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN /opt/google/chrome/google-chrome --no-sandbox --headless --disable-gpu --dump-dom https://www.chromestatus.com/

# install firefox
ARG FIREFOX_VERSION=73.0.1
RUN apt-get update -qqy \
    && apt-get -qqy --no-install-recommends install firefox \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/* \
    && wget --no-verbose -O /tmp/firefox.tar.bz2 https://download-installer.cdn.mozilla.net/pub/firefox/releases/$FIREFOX_VERSION/linux-x86_64/en-US/firefox-$FIREFOX_VERSION.tar.bz2 \
    && apt-get -y purge firefox \
    && rm -rf /opt/firefox \
    && tar -C /opt -xjf /tmp/firefox.tar.bz2 \
    && rm /tmp/firefox.tar.bz2 \
    && mv /opt/firefox /opt/firefox-$FIREFOX_VERSION \
    && ln -fs /opt/firefox-$FIREFOX_VERSION/firefox /usr/bin/firefox

# copy over monocle
RUN mkdir -p /usr/local/share/powershell/Modules/Monocle
COPY ./src/ /usr/local/share/powershell/Modules/Monocle

# state that monocle should be headless
RUN export DISPLAY=:99
ENV MONOCLE_HEADLESS '1'

# set as executable on drivers
RUN chown root:root /usr/local/share/powershell/Modules/Monocle/lib/Browsers/linux/chromedriver \
    && chmod +x /usr/local/share/powershell/Modules/Monocle/lib/Browsers/linux/chromedriver \
    && chown root:root /usr/local/share/powershell/Modules/Monocle/lib/Browsers/linux/geckodriver \
    && chmod +x /usr/local/share/powershell/Modules/Monocle/lib/Browsers/linux/geckodriver