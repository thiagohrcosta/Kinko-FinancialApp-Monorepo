FROM ruby:3.3

# Dependências do sistema
RUN apt-get update -qq && apt-get install -y \
  nodejs \
  postgresql-client \
  build-essential \
  && rm -rf /var/lib/apt/lists/*

# Diretório da aplicação
WORKDIR /app

# Instala gems (cache)
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copia o código da aplicação
COPY . .

# Remove PID antigo e sobe o servidor
CMD ["bash", "-c", "rm -f tmp/pids/server.pid && rails s -b 0.0.0.0"]