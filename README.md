# perlC
Bob Frederking's original Perl program to generate Random Contra Dances.

Options:
--dance - List of moves from Possible Moves Table
--debug - Turns on tracing
--generate - Relative number used in creating reproducible random number used as seed for generating permutations of moves
--version (optional) - allows different versions of Possible Moves Table

Examples:
perl contraswrap.pl --generate 574026564
perl contraswrap.pl --dance "6, 3, 16, 11, 5, 7, 9, 8, 2"
or
perl contraswrap.pl --dance "6 3 16 11 5 7 9 8 2"

Revisions:
Converted to strict syntax for perl v5.24

API:
Move: the Ordinal of a Move in Possible Move Table
Dance: An Ordered List of Moves in Possible Move Table
Floor Plan: a 2x2 array showing which dancer is in which position.
It is actually the mapping of two arrays; Positions & People.
(L1, R1, L2, R2) & (M1, W1, M2, W2)
There are 24 permutations in this mapping, but not all of them 
are valid for improper Contra Dances. Probably only 8.

Observations:
There are a large number of possible permutations of the possible moves.
It is not easy to be sure exactly how many there are because some dances have more 
moves than others. Not all permutations are valid dances.
That said, there should be a very large number of possible dances.
for 20 moves it would be <= 20!
Assuming on average 8 moves, it isa more like 20!-12!

Wish List:
It would be nice to keep a table of generated dances.

Problem Areas:
Floor Plan is not well defined.
It only works for simple Improper dances;
This will not work for Diagonal moves

Current logic mis-handles Swings. There should be at most one Partner Swing
and one Neighbor Swing.
Balance, Gypsy and Dosido are common modifiers of long Swings

Code Problems:
random_permute 367 - 402
Scalar value @indices[$i] better written as $indices[$i] at contras.pm line 387.
random_permute_0 409 - 424
Scalar value @indices[$i] better written as $indices[$i] at contras.pm line 428.

