# Etapa de build
FROM hexpm/elixir:1.18.0-erlang-27.0.1-debian-bullseye-20241223-slim AS builder

RUN apt-get update -y && apt-get install -y build-essential git \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

ENV MIX_ENV=prod
ENV ELIXIR_COMPILER_OPTIONS="--no-parallel"

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
COPY config config
COPY lib lib

RUN mix deps.get
RUN mix compile
RUN mix release

# Etapa final (runtime)
FROM debian:bullseye-20241223-slim

RUN apt-get update -y && apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    MIX_ENV=prod

WORKDIR /app
RUN chown nobody /app

COPY --from=builder --chown=nobody:root /app/_build/prod/rel/payment_dispatcher ./

USER nobody

CMD ["/app/bin/server"]
