# Abstract
This is a simple example to showcase the Obsidian to LaTeX converter.

# Introduction
This document demonstrates the conversion of Markdown notes to a LaTeX document, including internal links and embedded content.

# Results

replace all double dollars with math blocks and parse with github syntax. Then in the logic recover the display equation from the fact that it is also its own paragraph.

Here is some $\sum a_i$.

```math
\sum_{i=1}^k A_i
```

$$\sum_{i=1}^n A_3$$

$$
\sum_{i=1}^n A_3
$$

We present the following lemma:

lemma::![[lemma_1#Statement]]

The main theorem is:

theorem::![[theorem_1#Statement]]

# Proofs
Here is the proof for the main theorem. The proof is specifically for [[theorem_1#Statement]]. I may or may not follow from [[@rudelsonSparseReconstructionFourier2008]].

![[theorem_1#Proof]]
