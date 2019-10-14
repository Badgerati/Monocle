FROM mcr.microsoft.com/powershell:6.2.3-ubuntu-16.04
LABEL maintainer="Matthew Kelly (Badgerati)"

# update
RUN apt-get update -y
RUN apt-get install -y unzip curl wget

# install chrome
RUN apt-get install -y libappindicator1 fonts-liberation
RUN curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o /chrome.deb
RUN dpkg -i /chrome.deb; apt-get -fy install
RUN rm /chrome.deb
RUN google-chrome-stable --no-sandbox --headless --disable-gpu --dump-dom https://www.chromestatus.com/

# install firefox
RUN apt-get install -y firefox

# copy over monocle
RUN mkdir -p /usr/local/share/powershell/Modules/Monocle
COPY ./src/ /usr/local/share/powershell/Modules/Monocle

# state that monocle should be headless
RUN export DISPLAY=:99
ENV MONOCLE_HEADLESS '1'

# set as executable on drivers
RUN chown root:root /usr/local/share/powershell/Modules/Monocle/lib/Browsers/linux/chromedriver
RUN chmod +x /usr/local/share/powershell/Modules/Monocle/lib/Browsers/linux/chromedriver

RUN chown root:root /usr/local/share/powershell/Modules/Monocle/lib/Browsers/linux/geckodriver
RUN chmod +x /usr/local/share/powershell/Modules/Monocle/lib/Browsers/linux/geckodriver