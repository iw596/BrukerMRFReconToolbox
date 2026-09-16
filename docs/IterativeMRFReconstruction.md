# Iterative MRF reconstruction

The iterative pipeline uses one regularizer: locally low-rank (LLR). The unknown is a volume of temporal subspace coefficients, `x`, with size `[nx ny nz K]`.

## Forward model

The dictionary is compressed with an SVD. If `Phi` is the retained temporal basis with size `[Nt K]`, the coefficient images are projected to the time series with

`images = x * Phi'`.

The measured k-space model is

`d = A(x) = P F (x Phi')`,

where `F` is an explicitly unitary spatial FFT and `P` multiplies by the binary sampling mask. Because `Phi` and `F` are orthonormal/unitary, the adjoint is

`A'(d) = Phi F' P(d)`.

`buildMRFSubspaceOperators` implements these operations and `Tests/TestIterativeMRFOperators.m` checks the adjoint identity numerically.

## ADMM updates

The solver minimizes

`0.5 * ||A(x) - d||_2^2 + lambda * R_LLR(x)`.

Introducing `z = x` and a scaled dual variable `u` gives

```text
x = solve((A' A + rho I) x = A' d + rho (z - u))
z = prox_(lambda/rho R_LLR)(x + u)
u = u + x - z
```

The x equation is solved with conjugate gradients. `InnerIterations` is the maximum CG iteration count. This is different from averaging toward an inverse FFT: undersampling and temporal projection remain in the data-consistency equation.

## LLR proximal operator

Each spatial block is reshaped to `[number of voxels, K]`. Singular-value soft-thresholding is applied with threshold `lambda/rho`, then overlapping blocks are averaged. With non-overlapping blocks this is the exact proximal operator of the sum of block nuclear norms. With overlap it is the standard practical LLR denoiser and is an approximation to the exact proximal operator of the overlapping sum.

## Examples

- [2-D iterative example](../examples/RunReconstructionCLI_LLROnly_Example.m)
- [3-D iterative example](../examples/RunReconstructionCLI_LLROnly3D_Example.m)
- [Block-size example](../examples/RunReconstructionCLI_LLR_Block8_Example.m)

Update the scan and dictionary paths in the examples before running them. Set `Dimensionality` to `2D` or `3D`, use one `Locally-low rank` mode, and choose block sizes in spatial order `[x y]` or `[x y z]`.
