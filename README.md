# Prisoners' Dilemma Agent Based Model

This is a model I'm playing with to replicate [Evolutionary Phenomena in Simple Dynamics](https://publications.lib.chalmers.se/records/fulltext/140676/local_140676.pdf) (Lindgren, 1991). 

This model is pretty heavy, so run it on cold winter nights for best results if you want to see results for large populations.

Turtles play iterated prisoners dilemmas with partners for 200 rounds. Each turtle decides whether to cooperate or defect based on the previous few plays. Different turtles can have different memory lengths, but they call all at least remember what their partner did last. (Assuming I coded that right, which I should double check.) Each turtle has a strategy emboddied in a binary string of length $2 ^ memory-length$. Their memory is a binary string that we can use to choose the $i-th$ element of their strategy string when the sequence of moves in their game is $i$.

There are two buttons you can press to get details about the population of strategies at the current round or about a randomly selected agent. "
There are two buttons you can press to get details about the simulation. "check out a turtle" will select a random turtle and display some information about it at the Command Center. "Show tally of different strategies" shows you the different strategies in the current generation in order of population share.

The default probability setting are mostly in line with Lindgren's paper, but you can change them if you'd like. The population is set to 100 by default because 1000 takes a long time to compute.
Each probabalistic parameter is split into an order of magnitude and a "fine tuning" knob. If those variables for $p_x$ are $y$ and $z$, then $p_x = z / 10^y$. 
That's a slightly annoying interface, but it means it's much easier to compare a 1 in 1000 error from a 1 in 100000 and also to compare 1% from 5%. 

Another important difference (among at least several) between this model and the original is that this one doesn't impose an upper bound on memory size. Lindgren much more sensibly restricts the maximum memory length to the 5 most recent moves. I, instead, impose a cost of memory that discourages it's growth, but doesn't prevent monster strategies the size of feral floppy discs. 
