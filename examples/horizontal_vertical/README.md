# Horizontal - Vertical Recognition

Assume that we need to find horizontal and vertical lines existence in the 3x3 image.

* There are 9 inputs, each for the pixel
* There are 2 outputs, horizontals detector and verticals detector

Assume that we have to make it within 1 hidden layer with 4 activators.

## Code first

TODO: Describe the code

## (TL;DR) Data explanation

We can represent the data (input images and correspond outputs right after) like this:

```
_______       _______       _______       _______
|x|x|x|  1    | | | |  1    | | | |  1    |x| | |  0
| | | |  0    |x|x|x|  0    | | | |  0    |x| | |  1
|_|_|_|       |_|_|_|       |x|x|x|       |x|_|_|

_______       _______       _______       _______
| |x| |  0    | | |x|  0    |x|x|x|  1    |x| | |  1
| |x| |  1    | | |x|  1    |x| | |  1    |x|x|x|  1
|_|x|_|       |_|_|x|       |x|_|_|       |x|_|_|

_______       _______       _______       _______
|x| | |  1    |x|x|x|  1    | |x| |  1    | |x| |  1
|x| | |  1    | |x| |  1    |x|x|x|  1    | |x| |  1
|x|x|x|       |_|x|_|       |_|x|_|       |x|x|x|

_______       _______       _______       _______
|x|x|x|  1    | | |x|  1    | | |x|  1    | | | |  0
| | |x|  1    |x|x|x|  1    | | |x|  1    | | | |  0
| | |x|       |_|_|x|       |x|x|x|       |_|_|_|

```

* Outputs are binary array with 2 bits
* Inputs are the same but with 9 bits

We can use binary logic to solve the problem. This leads to the use of Neuron operation.

## Functions declaration

Let's declare probably needed functions:

![Binary operations](https://latex.codecogs.com/gif.latex?%5Cbegin%7Bmatrix%7D%20%26%20%26%20Sum%20%26%20Multiplication%20%28Mul%29%20%26%20Xor%20%26%20Inverse%20Sum%20%28InvSum%29%20%26%20Inverse%20Multiplication%20%28InvMul%29%5C%5C%20A%20%26%20B%20%26%20A%20&plus;%20B%20%26%20A%20*%20B%20%26%20A%20%5Coplus%20B%20%26%20%5Coverline%7BA%7D%20&plus;%20%5Coverline%7BB%7D%20%26%20%5Coverline%7BA%7D%20*%20%5Coverline%7BB%7D%5C%5C%200%20%26%200%20%26%200%20%26%200%20%26%200%20%26%201%20%26%201%5C%5C%200%20%26%201%20%26%201%20%26%200%20%26%201%20%26%201%20%26%200%5C%5C%201%20%26%200%20%26%201%20%26%200%20%26%201%20%26%201%20%26%200%5C%5C%201%20%26%201%20%26%201%20%26%201%20%26%200%20%26%200%20%26%200%20%5Cend%7Bmatrix%7D "Binary operations")

## Solving manually

Now let's try to solve the problem manually.

First, we need to split images into 1D array. Each image now looks like:

* `[1 1 1 0 0 0 0 0 0]` - horizontal (image 1, activation - `1, 0`)
* `[1 0 0 1 0 0 1 0 0]` - vertical (image 4, activation - `0, 1`)
* `[1 1 1 1 0 0 1 0 0]` - both (image 7, activation - `1, 1`)
* `[0 0 0 0 0 0 0 0 0]` - None (image 16, activation - `0, 0`)

1. "Neuron" 1 should activate when image has a horizontal line. It can be achived when bits responded to horizontals are multiplied among themselves.
2. "Neuron" 2 should activate when image has a vertical line. The same way, it can be achived when bits responded to verticals are multiplied among themselves.

In the boolean algebra it looks like this:

```
out1 = Mul( in0, in1, in2 ) - first horizontal
out2 = Mul( in3, in4, in5 ) - second horizontal
out3 = Mul( in6, in7, in8 ) - third horizontal

out4 = Mul( in0, in3, in6 ) - first vertical
out5 = Mul( in1, in4, in7 ) - second vertical
out6 = Mul( in2, in5, in8 ) - third vertical
```

Now we have 6 outputs instead of one. We should use the second layer to calculate final result.

1. "Horizontal" bit activates when one of horizontals are active. We have to sum all previous "horizontal" outputs.
1. "Vertical" bit activates when one of verticals are active. We have to sum previous results.

```
horizontal = Sum( out1, out2, out3 )
vertical   = Sum( out4, out5, out6 )
```

## So simple? Why do we need to use YAGA?!

In the previous step we built model with 9 inputs, 6 "hidden neurons" and 2 "output neurons".

Let's try to remove 2 "hidden neurons" to match the original task.

Well... We still can solve this manually but logic will be much more complicated.<br>
Instead, let's see what solutions does YAGA offer.

## Genetic solutions

The conclusions of the layers are presented sequentially.

The last layer takes results from the first, indexed from 0.

### Compressed sum and multiplication

Hidden layer:

```
out1 = Sum( in0, in1, in2, in4, in5 )
out2 = Sum( in0, in3, in6 )
out3 = Sum( in1, in4, in5, in8 )
out4 = Sum( in6, in7, in8 )
```

Output layer:

```
horizontal = Mul( out1, out2 )
vertical   = Mul( out0, out3 )
```

### Inverse Multiplication (InvMul) only

Found solution made with the single command.

Hidden layer:

```
out1 = InvMul( in3, in6, in7, in8 )
out2 = InvMul( in0, in3, in6 )
out3 = InvMul( in0, in1, in2 )
out4 = InvMul( in1, in4, in5, in7 )
```

Output layer:

```
horizontal = InvMul( out1, out3 )
vertical   = InvMul( out0, out2 )
```
