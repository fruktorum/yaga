# YAGA - Yet Another Genetic Algorithm

YAGA is a genetic multilayer algorithm supporting different classes between layers.

* Engine has no dependencies instead of stdlib (only specific operations use it, see the documentation about each)
* YAGA has been made to support different classes for inputs, outputs and layers (like difference between convolutional and fully connected layers in CNNs)
* Genetic model generates on compile-time and does not consume initialization resources on production
* It can be used to train your models before production with `Population` class or to run the model with `Bot` class in production
* Saving and loading the model saves and loads the state of `Operation`s in each layer into JSON

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     yaga:
       github: SlayerShadow/yaga
   ```

2. Run `shards install`

## Usage

* Please see the [examples](examples) folder with specific documentation about each use case provided by engine
* Please see the operations folder with descriptions about each `Operation` class to understand supported interfaces and etc. to architect the project for your requirements

Add requirement to your project file:

```crystal
require "yaga"
```

Operations does not loads automatically - just a core engine.<br>
You can develop your own operation for your project or use any of engine's "presets":

```crystal
require "yaga/operations/neuron"
```

Please read the documentation about the operation before adding it.<br>
They could have external dependencies that should be added to your `shard.yml` (example: MatrixMultiplicator with requiring of SimpleMatrix shard).

After that creates population and trains a model:

_EOF..._

## Development

All PRs are welcome!

* To add the operation, please add it to `src/operations` folder
* Please make sure that features compile with `--release` and (preferably) `--static` flags on Alpine Linux (see the `Dockerfile` sample for clarification)
* Please make sure that it is working correctly when composed with other existed operations when layered it in mixed way
* Please add at least one spec and at least one example to clarify its use cases
* If your operation uses secific inputs or outputs (such as YAGA::Neuron based on `BitArray`) please note about that in example documentation. It would also help users to architect interfaces more strict and less error prone.
* Please add your name to contributors list below to make a history

## Contributing

1. Fork it (<https://github.com/SlayerShadow/yaga/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [SlayerShadow](https://github.com/SlayerShadow) - creator and maintainer
