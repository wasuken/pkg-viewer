FROM ruby:2.7.3

WORKDIR /tmp

RUN apt update -y
RUN apt install -y build-essential gcc make mariadb-client openssl curl gnupg

RUN curl -sL https://deb.nodesource.com/setup_12.x  | bash -
RUN apt-get -y install nodejs

WORKDIR /app

COPY app/Gemfile app/Gemfile.lock app/package.json app/create.rb /app/

RUN bundle install

# ENTRYPOINT ["/bin/sh", "-c", "while :; do sleep 10; done"]

COPY ./run.sh /run.sh
RUN chmod +x /run.sh

COPY ./wait.sh /wait.sh
RUN chmod +x /wait.sh

ENTRYPOINT [ "/wait.sh" ]
