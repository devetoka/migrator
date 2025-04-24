FROM ruby:3.2.2 AS base

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  libvips \
  nodejs \
  yarn

WORKDIR /app

RUN gem install bundler

COPY ./app/Gemfile ./

RUN bundle install

COPY ./app .
