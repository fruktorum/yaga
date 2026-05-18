# YAGA — Project Map

```
yaga/
├── src/
│   ├── version.cr                          # Shard version constant
│   └── yaga/
│       ├── yaga.cr                         # Entry point — requires only population + version
│       ├── genome.cr                       # YAGA::Genome.compile macro (compile-time genome builder)
│       ├── population.cr                   # YAGA::Population(T, V) — generic population manager
│       ├── bot.cr                          # YAGA::Bot(T, V) — individual bot instance
│       ├── chromosome.cr                   # YAGA::Chromosome(T, U, V) — base module for custom chromosomes
│       └── chromosomes/                    # Preset chromosomes (NOT auto-loaded, must require explicitly)
│           ├── binary_neuron.cr            # BinaryNeuron — BitArray input/output, simple activation
│           ├── matrix.cr                   # MatrixMultiplicator — requires simple_matrix shard
│           ├── equation.cr                 # EquationBuilder — syntax tree equation builder
│           └── equation_parser/
│               ├── node.cr                 # AST node types
│               ├── parser.cr               # Equation syntax parser
│               └── tree.cr                 # Expression tree builder
│
├── spec/
│   ├── spec_helper.cr                      # TestGenome — minimal chromosome for specs
│   ├── population_spec.cr                  # Only spec file: tests #prepare_selection
│   └── equation/
│       └── syntax_parser_spec.cr           # Equation parser tests
│
├── examples/                               # Usage examples (lessons)
│   ├── README.md                           # Example index with descriptions
│   ├── shared/
│   │   └── progress_patch.cr               # Shared progress bar utility
│   ├── horizontal_vertical/                # Lesson 1 — line recognition (2 layers, BinaryNeuron)
│   ├── quadratic_equation/                 # Lesson 2 — equation fitting (1 layer, EquationBuilder)
│   ├── snake_game/                         # Lesson 3 — Snake AI (5 layers, includes Matrix)
│   └── interpolation/                      # Bonus — interpolation function coefficients
│
├── shard.yml                               # Shard manifest (Crystal 1.20.2, dev deps: progress, simple_matrix, tilerender)
├── shard.lock                              # Locked dependency versions (gitignored)
├── Dockerfile                              # Alpine-based build: dev + examples stages
├── docker-compose.yml                      # dev / examples services
├── .editorconfig                           # 2-space indent, LF, UTF-8
├── .gitignore                              # bin/, lib/, .shards/, core, shard.lock, *.dwarf
└── AGENTS.md                               # Agent instructions (this file references project-map.md)
```

## Key Paths to Know

| What | Path |
|------|------|
| Entry point | `src/yaga.cr` |
| Genome macro | `src/yaga/genome.cr` |
| Population class | `src/yaga/population.cr` |
| Bot class | `src/yaga/bot.cr` |
| Chromosome base | `src/yaga/chromosome.cr` |
| Preset chromosomes | `src/yaga/chromosomes/` |
| Test genome helper | `spec/spec_helper.cr` |
| Only population spec | `spec/population_spec.cr` |
| Example index | `examples/README.md` |
| Shard manifest | `shard.yml` |

## Important Notes

- `require "yaga"` loads **only** `population` and `version`. Chromosomes must be required individually.
- `YAGA::Genome.compile` is a **macro** — genome structure is fixed at compile time.
- `spec/spec_helper.cr` defines `TestGenome` — reuse it or define inline for new specs.
- `shard.lock` is gitignored; run `shards install` to regenerate.
