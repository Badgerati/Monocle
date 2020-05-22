# make sure to build this with --no-cache
FROM mcr.microsoft.com/powershell:7.0.0-ubuntu-16.04
LABEL maintainer="Matthew Kelly (Badgerati)"

# update
RUN apt-get update -y \
    && apt-get install -y unzip curl wget libappindicator1 fonts-liberation

# install chrome
RUN curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o /chrome.deb \
    && dpkg -i /chrome.deb; apt-get -fy install \
    && rm /chrome.deb \
    && google-chrome-stable --no-sandbox --headless --disable-gpu --dump-dom https://www.chromestatus.com/

# install firefox
RUN apt-get install -y firefox

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
