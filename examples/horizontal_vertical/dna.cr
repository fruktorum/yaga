YAGA::Genome.compile(
  # Generated genome class           Inputs type (array)       Inputs size
  BinaryGenome, BitArray, 9,

  # Activator                        Activations type (array)  Outputs size
  {YAGA::Chromosomes::BinaryNeuron, BitArray, 4},
  {YAGA::Chromosomes::BinaryNeuron, BitArray, 2}
)
