# YAGA — Agent Instructions

## Project Map

See `project-map.md` for the full directory tree and key file paths.

## Project

Crystal library (shard) implementing a genetic multilayer algorithm. Crystal 1.20.2. No runtime dependencies beyond stdlib.

## Commands

```
shards install          # install dev dependencies
crystal spec            # run tests
crystal build --release # compile examples (add --static for Alpine, -D preview_mt for snake_game)
```

No CI, no Makefile, no task runner. Docker available via `docker compose run dev` or `docker compose run examples`.

## Architecture

- `src/yaga.cr` — entry point, requires `population` and `version` only. Chromosomes are **not** auto-loaded; users must `require "yaga/chromosomes/*"` explicitly.
- `src/yaga/genome.cr` — `YAGA::Genome.compile` macro, builds genome at compile-time using `StaticArray`s.
- `src/yaga/population.cr` — `YAGA::Population(T, V)` generic class. `T` = genome type, `V` = fitness value type (any `Number`).
- `src/yaga/bot.cr` — `YAGA::Bot(T, V)` individual bot instance.
- `src/yaga/chromosome.cr` — base `YAGA::Chromosome(T, U, V)` module for custom chromosomes.
- `src/yaga/chromosomes/` — preset chromosomes: `binary_neuron`, `matrix`, `equation` (+ equation_parser subdirectory).

## Key Design Constraints

- **Compile-time genome**: `YAGA::Genome.compile` is a macro. Layer types and sizes are fixed at compile time.
- **Chromosomes must be explicitly required** — only the core engine loads with `require "yaga"`.
- **Some chromosomes have external deps**: `matrix` requires `simple_matrix` shard; check each chromosome's docs.
- **JSON serialization**: `Bot#to_json` / `Bot.from_json` work reliably only on `YAGA::Bot` itself, not on user-defined subclasses. To restore a genome across a population, load into a `Bot` then call `population.bots.each &.replace(loaded_bot)`.

## Testing

- Standard Crystal specs: `crystal spec`
- `spec/spec_helper.cr` defines `TestGenome` — a minimal chromosome used by `population_spec.cr`.
- Two spec files: `spec/population_spec.cr` (tests `#prepare_selection` behavior) and `spec/equation/syntax_parser_spec.cr` (tests equation parser).
- When adding specs, follow the existing pattern: define a test genome in spec_helper or inline, compile it with `YAGA::Genome.compile`, then describe.

## Code Style

From `.editorconfig`: 2-space indent, LF line endings, UTF-8, trailing newline, trim trailing whitespace.

## Development Workflow

1. Features must compile with `--release` and preferably `--static` on Alpine Linux.
2. New chromosomes go in `src/yaga/chromosomes/`.
3. Each new chromosome needs at least one spec and one example.
4. Examples live in `examples/` — see `examples/README.md` for per-example docs.
