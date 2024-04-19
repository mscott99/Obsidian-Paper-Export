---
author: Matthew Scott
---
# Abstract
This is a simple example to showcase the Obsidian to LaTeX converter.

# Introduction
This document demonstrates the conversion of Markdown notes to a LaTeX document, including internal links and embedded content.

![[download.jpeg|This is the caption]]

remark::
  I remark that this plugin is awesome.
::remark
# Results

#longform

> a quote; ignore it
>
$$
Given suitable definitions, the following follows.
\begin{align*}
  \|\hat x - x_0\|_2
  \leq \|x^\perp\|_2 + 3\|\tilde{F}x^\perp\|_2 + 3 \|\eta\|_2 + \frac{3}{2}\hat\varepsilon.
\end{align*}
$$

where $\sum a_i = 0$. See~[[lemma_1#Proof]].

$$
\sum_{i=1}^k A_i
$$

We also present the following lemma:

lemma::![[lemma_1#Statement]]

proof::![[lemma_1#Proof]]

The main theorem is:

theorem::![[theorem_1#Statement]]

# Proofs
Here is the proof for the main theorem. The proof is specifically for [[theorem_1#Statement]]. I may or may not follow from [[@rudelsonSparseReconstructionFourier2008]].

![[theorem_1#Proof]]
