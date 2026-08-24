FROM elixir:1.18-alpine

WORKDIR /app
COPY mix.exs ./
COPY lib ./lib
COPY test ./test

RUN mix compile --warnings-as-errors && mix test \
    && addgroup -S app && adduser -S -G app -u 10001 app \
    && chown -R app:app /app

USER 10001:10001
CMD ["elixir", "-e", "IO.puts(\"sky-mesh library image ready\")"]
