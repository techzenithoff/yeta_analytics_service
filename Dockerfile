FROM ruby:3.2.3

# Dépendances système + Node 20 + Yarn 1
RUN apt-get update -qq && apt-get install -y \
  curl gnupg build-essential libpq-dev \
  && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y nodejs \
  && npm install -g yarn@1.22.22 \
  && gem install bundler -v 2.5.23 \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Optimisation du cache des gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

# Pré-compilation des assets (si applicable, sinon tu peux commenter)
# RUN bundle exec rake assets:precompile

EXPOSE 3000

# Commande simplifiée : on lance uniquement le serveur.
# Les migrations sont gérées par le Job Kubernetes indépendant.
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0", "-p", "3000"]