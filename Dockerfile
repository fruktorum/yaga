FROM crystallang/crystal:1.2.2-alpine AS build
WORKDIR /app
CMD [ "sh" ]

COPY shard.* ./

RUN mkdir -p /build && shards install

COPY . .

FROM build AS examples

RUN crystal build --no-debug --release --static --stats -o /build/horizontal_vertical examples/horizontal_vertical/horizontal_vertical.cr && \
    crystal build --no-debug --release --static --stats -o /build/quadratic_equation examples/quadratic_equation/quadratic_equation.cr && \
    crystal build --no-debug --release --static --stats -D preview_mt -o /build/snake_game examples/snake_game/snake_game.cr
