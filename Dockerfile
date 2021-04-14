FROM ruby:2.7.3

WORKDIR /app

RUN bundle config set path 'vendor/bundle'

RUN bundle exec ruby create.rb

RUN bundle exec ruby cve.rb cve.csv

ENTRYPOINT bundle exec ruby srv.rb
