#!/usr/bin/perl
#  contras.pm
package main;
use warnings;
use strict;

# *** Update this with each "release" on the Web:
# First Release Begun: 30-Dec-98
use version; our $VERSION = qv("v0.2.2");

## These are being accessed globally
## A better solution would be to pass them as part of an Object
use vars qw($debug $OFFSET $fh2 $fh3 @solution $search_step_cnt);
# Random Contra Dance Generator
# Copyright (c) 1998, 1999 Robert E. Frederking
# Copyright (c) 2017 William C. Fay
# Permission is granted to copy and distribute for non-commercial use only
##  This file is part of Contra Dance Generator.

##  Contra Dance Generator is free software: you can redistribute it
##  and/or modify it under the terms of the GNU General Public License
##  as published by the Free Software Foundation, either version 3 of
##  the License, or (at your option) any later version.

##  Contra Dance Generator is distributed in the hope that it will
##  be useful, but WITHOUT ANY WARRANTY; without even the implied
##  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
##  See the GNU General Public License for more details.

##  You should have received a copy of the GNU General Public License
##  along with Contra Dance Generator.
##  If not, see <http://www.gnu.org/licenses/>.

# Starts with a database of moves, and produces working contra dances
# (though not necessarily artistically pleasant ones).

# Have a safety valve: search is not allowed to run more than $N times (10,000??)

my $search_step_limit = 10000;
my $search_step_flag = "";

###########################################################################################
# Start with a database of moves:
# preconditions (where two people must be, genders, etc.)
# postconditions (where they end up [position (and direction?)], time incr),
# and English description (to capture intermediate activity)

# Started with very simple dance: Bal and Swing N; then three Hey for fours!!
# Then added the moves for "A Piece o' Cake" (Carol Kopp)
# Then random other stuff
# 12-Dec-98: took out "end facing in" from text, to avoid confusion if next move is DHiL4
# 27-Dec-98: Added weight to move selection: bigger means tried later in random sequence on average
#	Currently, 1=very common, 2=not unusual, 10=as unusual as possible
#<<< Tells PerlTidy to skip this section
my @possible_moves = (
  ["couples_on_side", "status_quo", 16, "Hey for Four", "Hey", 2],
# This pretends we stay in normal improper contra position:
  ["couples_on_side", "status_quo", 16, "Down the Hall in Lines of Four and<BR> 
    Turn as a Couple and Come Back to Place", "DHL4/turn_couple", 2],
  ["men_across_set", "exchange_men_across_set", 4, "Men pass Left across set", "Men_cross", 10],
  ["with_P_on_side", "change_sides_to_facing_in", 8, "Swing your Partner", "Swing_P/in", 1],
# end facing in?
  ["with_P_on_side", "change_sides_to_facing_in", 12, "Swing your Partner (12 counts)",
    "Swing_P/in/12", 2],
# end facing in?
  ["with_P_on_side", "change_sides_to_facing_in", 16, "Balance and Swing Partner", "B+S_P/in", 1],
# end facing in?
  ["applies_to_any", "rotate_R_1_place", 8, "Circle Left three places", "Circle_L_3", 1],
  ["applies_to_any", "status_quo", 4, "Balance the circle", "Bal_circle", 5],
  ["with_P", "exchange_Ps", 4, "Box the Gnat with your Partner", "Box_Gnat_P", 10],
  ["with_N", "exchange_Ns", 4, "Box the Gnat with your Neighbor", "Box_Gnat_N", 10],
  ["with_P", "exchange_Ps", 8, "Balance and Box the Gnat with your Partner", "B+Box_Gnat_P", 10],
  ["with_N", "exchange_Ns", 8, "Balance and Box the Gnat with your Neighbor", "B+Box_Gnat_N", 10],
  ["with_P_at_heads", "switch_places_at_heads", 4, "California Twirl Partner", "CA_twirl", 5],
  ["with_N_on_side", "change_sides_to_facing_in", 8, "Swing your Neighbor", "Swing_N/in", 1],
# end facing in?
  ["with_N_on_side", "change_sides_to_facing_in", 12, "Swing your Neighbor (12 counts)",
    "Swing_N/in/12", 2],
# end facing in?
  ["with_N_on_side", "change_sides_to_facing_in", 16, "Balance and Swing Neighbor", "B+S_N/in", 1],
# end facing in?
  ["with_P", "status_quo", 8, "Do-si-do your Partner", "Dosido_P", 5],
  ["with_N", "status_quo", 8, "Do-si-do your Neighbor", "Dosido_N", 5],
  ["applies_to_any", "status_quo", 8, "Men Do-si-do", "Dosido_M", 10],
  ["applies_to_any", "status_quo", 8, "Women Do-si-do", "Dosido_W", 10],
);
#>>>
# This gets us the size of the move array:
my $number_of_moves = @possible_moves;

our $dt_required ||= {
  couples_on_side => \&couples_on_side,
  men_across_set  => \&men_across_set,
  with_P_on_side  => \&with_P_on_side,
  applies_to_any  => \&applies_to_any,
  with_P          => \&with_P,
  with_N          => \&with_N,
  with_P_at_heads => \&with_P_at_heads,
  with_N_at_heads => \&with_N_at_heads,
  with_N_on_side  => \&with_N_on_side,
};

our $dt_transform ||= {
  status_quo                => \&status_quo,
  exchange_men_across_set   => \&exchange_men_across_set,
  change_sides_to_facing_in => \&change_sides_to_facing_in,
  rotate_R_1_place          => \&rotate_R_1_place,
  exchange_Ps               => \&exchange_Ps,
  exchange_Ns               => \&exchange_Ns,
  switch_places_at_heads    => \&switch_places_at_heads,
};

# Compute total "P" mass across all possible moves:
my $total_P_sum = 0;
for (my $i = 0 ; $i < $number_of_moves ; $i++) {
  $total_P_sum += $possible_moves[$i][5];
}

# Have a parameter that makes it print out list of available moves!
# This prints each move, and the number of steps it takes:
sub print_out_moves {
  my ($handle) = @_;

  # *** Would be prettier if a "(" prevented the step count from printing:
  print $handle
    "There are $number_of_moves contra dance moves defined in version $VERSION:<P>\n\n";
  foreach my $move (@possible_moves) {
    print $handle "${$move}[3] (${$move}[2] steps)<BR>\n";
  }
}

my $max_dance_len = 64;

# Have an indicator of type of dance (improper, Becket, proper, etc.)
# This selects the initial floorplan
my $floorplan_type    = "improper";
my @initial_floorplan = (
  [{gender => "W", direction => 1}, {gender => "M", direction => 1}],
  [{gender => "M", direction => 2}, {gender => "W", direction => 2}]
);

# This tests the predicates:
# print &{$possible_moves[0][0][0]}(@initial_floorplan); print " (couples on side)\n";
# print &{$possible_moves[1][0][0]}(@initial_floorplan); print " (with N on side)\n";

# Puts a blank line between As/Bs, and labels them
sub print_dance {
  my ($handle, @dance) = @_;
  my $move_cntr = 0;

  print $handle "<DL COMPACT><DT><B>A1:</B>";
  foreach my $i (@dance) {
    if ($move_cntr == 16)     {print $handle "\n<BR><DT><B>A2:</B> "}
    if ($move_cntr == 32)     {print $handle "\n<BR><DT><B>B1:</B> "}
    if ($move_cntr == 48)     {print $handle "\n<BR><DT><B>B2:</B> "}
    if ($move_cntr % 16 != 0) {print $handle "    "}

    print $handle "<DD>", $possible_moves[$i][3], "\n<BR>";

    $move_cntr = $move_cntr + $possible_moves[$i][2];
  }
  print $handle "</DL COMPACT>";
}

# search state consists of (dance_moves, floorplan, stepcount)
# dance_moves is the sequence of instantiated possible moves
# 	that will produce the floorplan shown.
# When a solution is found, set @solution to abort further searching
my @initial_state = ([], \@initial_floorplan, 0);

sub print_floorplan {
  my ($handle, @floorplan) = @_;

## print $handle "Rows: ", @floorplan, "\n";
  foreach my $i (0, 1) {
    print $handle $floorplan[$i][0]{gender}, $floorplan[$i][0]{direction},
      " ";
    print $handle $floorplan[$i][1]{gender}, $floorplan[$i][1]{direction},
      "\n";
  }
}

sub print_dance_w_floorplans {
  my ($handle, @dance) = @_;
  my $move_cntr = 0;
  my @floorplan = @initial_floorplan;

## This prints initial floorplan
  print_floorplan($fh3, @initial_floorplan) if $debug;
  print $fh3 "\n" if $debug;

  print $handle "A1: ";
  foreach my $i (@dance) {
    if ($move_cntr == 16)     {print $handle "\nA2: "}
    if ($move_cntr == 32)     {print $handle "\nB1: "}
    if ($move_cntr == 48)     {print $handle "\nB2: "}
    if ($move_cntr % 16 != 0) {print $handle "    "}

    print $handle $possible_moves[$i][3], "\n";

##    @floorplan = &{$possible_moves[$i][1]}(@floorplan);
    @floorplan = $dt_transform->{$possible_moves[$i][1]}(@floorplan);
    print_floorplan($handle, @floorplan);

    $move_cntr = $move_cntr + $possible_moves[$i][2];
  }
}

###########################################################################################
## This provides answers for fake move selection at each step of test run!
## @test = ([4],[3,4]);
# Main program

sub main_contra_generator {
  my ($handle, $seed) = @_;

  $search_step_cnt = 0;

## This prints initial floorplan
##  print_floorplan($fh3, @initial_floorplan) if $debug;
##  print $fh3 "\n" if $debug;

  srand($seed);

  # This shows that original dance (Piece o' Cake) is done correctly:
  # (using possibly obsolete move numbers, and no prec checking!)
  # print_dance_w_floorplans(*DATA, (7,0,1,3,4,5,6)); print DATA "\n";

  # This is here in case things really die later:
  print $fh3 "Dance number ", $seed - $OFFSET, " (version $VERSION)\n" if $debug;

  random_dfs(@initial_state);

  if ($search_step_flag eq "TOODEEP") {
    print $fh3 "Dance search exceeded limit, ", $search_step_limit,
      " search steps!\n\n" if $debug;
    print $handle "Dance search exceeded limit, ", $search_step_limit,
      " search steps!\n<BR>\n";
  } else {
    print_dance_w_floorplans($fh3, @{$solution[0]}) if $debug;
    print $fh3 "\n" if $debug;
##    print_floorplan($fh3, @{$solution[1]}) if $debug;
##    print $fh3 "\n" if $debug;
    print $fh3 "steps: ", $solution[2] if $debug;
    print $fh3 "\n\n" if $debug;

    print_dance($handle, @{$solution[0]});
    print $handle "\n<BR>";
  }

  print $fh3 "Dance number ", $seed - $OFFSET, 
    " = @{$solution[0]} (version $VERSION)\n" if $debug;
  print $fh2 "Dance number ", $seed - $OFFSET, 
    " = @{$solution[0]} (version $VERSION)\n";
  print $handle "<P><I>Dance number ", $seed - $OFFSET,
    " = @{$solution[0]} (version $VERSION)</I>\n";

## This makes this routine re-entrant.
  undef  @solution;
}

###########################################################################################
## This debugging stub replaces random_permute with number from list
## Need to also tell it to fail at some point?  Not so far.
sub fake_random_permute {
  my @test = ([4],[3,4]);
  return @{$test[$search_step_cnt - 1]};
}

# Recursive random DFS function!
sub random_dfs {
  my (@search_state) = @_;
  my (@children_order, @temp);

  # This prevents infinite searches
  $search_step_cnt++;
  if ($search_step_cnt >= $search_step_limit) {
    $search_step_flag = "TOODEEP";
    return 0;
  }
  print $fh3 "\nSearch step count: $search_step_cnt \n" if $debug;

  if (solution_p(@search_state)) {
    @solution = @search_state;
    return @solution;
  }
  if ($search_state[2] >= $max_dance_len) {
    return 0;
  }

  @children_order = random_permute($number_of_moves);
  print $fh3 "\@children_order: @children_order\nTry \$child_move: " if $debug;

  foreach my $child_move (@children_order) {
    print $fh3 "$child_move, " if $debug;
    if (applicable_to_state($child_move, @search_state)) {
      @temp = apply($child_move, @search_state);
      random_dfs(@temp);
    }
    if (@solution) {return @solution;}
    elsif ($search_step_flag eq "TOODEEP") {return 0}
  }
  print $fh3 "\nReturning from random_dfs()\n" if $debug;
}

# Test_for_valid_dance
sub dance_valid {
  my (@solution) = @_;
  my @search_state = @initial_state;
  foreach my $move (@solution) {
    if (applicable_to_state($move, @search_state)) {
      @search_state = apply($move, @search_state);
    }
  }
  if (solution_p(@search_state)) {
    return 1;
  } else {return 0;}

}

# This will be a test for 64 steps and correct progression:
sub solution_p {
  my (@search_state) = @_;

  if ($search_state[2] == 64) {
    foreach my $i (0 .. 1) {
      if ( (${$search_state[1]}[0][$i]{direction} != 2)
        or (${$search_state[1]}[1][$i]{direction} != 1)
        or (${$search_state[1]}[$i][$i]{gender} ne "M")
        or (${$search_state[1]}[1 - $i][$i]{gender} ne "W"))
      {
        return 0;
      }
    }
    return 1;
  } else {
    return 0;
  }
}

# This will test all preconditions of a chosen move:
# Also make sure it wouldn't exceed 64 dance steps.
# Also make sure it doesn't roll across an A part or B part boundary!
sub applicable_to_state {
  my ($move_number, @search_state) = @_;
  my @previous_moves = @{$search_state[0]};
  my $num_of_moves   = @previous_moves;
  my $last_move      = $previous_moves[$num_of_moves - 1];

  # We may want to relax this condition later:
  # *** Index via move: some moves can't repeat immediately,
  #                     some can't occur twice in one dance, etc.
  foreach my $old_move (@previous_moves) {
    if ($old_move == $move_number) {return 0}
  }

##  foreach my $prec (@{$possible_moves[$move_number][0]}) {
##    my $prec = $possible_moves[$move_number][0];
##    $dispatch_table->{$action}->(@args);
##    $dt_required->{$possible_moves[$move_number][0]}->(@{$search_state[1]})
##    print $fh3 "for $prec\n" if $debug;
##    if (!&{$prec}(@{$search_state[1]})) {return 0;}
##  }
  if (!$dt_required->{$possible_moves[$move_number][0]}->(@{$search_state[1]})) {
    return 0;
  }

  print $fh3 "\nStart cnt: $search_state[2] End cnt: " if $debug;
  print $fh3 ($search_state[2] + $possible_moves[$move_number][2]) if $debug;
  print $fh3 " Boundary: ", (16 * (1 + int($search_state[2] / 16))) if $debug;
  print $fh3 " move $move_number $possible_moves[$move_number][4]\n" if $debug;

  # This tests for crossing A/B boundary (and max size, as a side effect!)
  if (($search_state[2] + $possible_moves[$move_number][2]) <=
    (16 * (1 + int($search_state[2] / 16))))
  {
    return 1;
  } else {
    return 0;
  }
}

# This will produce a new state by applying selected move to old state:
sub apply {
  my ($move_number, @search_state) = @_;
  my (@dancecopy, @newfloorplan);

  print $fh3 " " x ($search_state[2] / 4) if $debug;
  print $fh3
    "applying move $move_number $possible_moves[$move_number][4] to state\n" if $debug;
##    "applying move $move_number $possible_moves[$move_number][4] to state @{$search_state[0]} " if $debug;
  print_floorplan($fh3, @{$search_state[1]}) if $debug;
## print $fh3 "Before action floorplancopy: ", \@floorplancopy, "\n" if $debug;
## print_floorplan($fh3, @floorplancopy) if $debug;
## print $fh3 "Before action search_state: ", \@{$search_state[1]}, "\n" if $debug;
## print_floorplan($fh3, @{$search_state[1]}) if $debug;
## print $fh3 "\n" if $debug;

## Need to copy the array (or something) due to destructive ops!!!
  @dancecopy = @{$search_state[0]};

## 	$floorplancopy[0][0] = ${$search_state[1]}[0][0];
## 	$floorplancopy[0][1] = ${$search_state[1]}[0][1];
## 	$floorplancopy[1][0] = ${$search_state[1]}[1][0];
## 	$floorplancopy[1][1] = ${$search_state[1]}[1][1];

##  @newfloorplan = &{$possible_moves[$move_number][1]}(@{$search_state[1]});
##    $dispatch_table->{$action}->(@args);
##    $dt_required->{$possible_moves[$move_number][0]}->(@{$search_state[1]})
  @newfloorplan = $dt_transform->{$possible_moves[$move_number][1]}(@{$search_state[1]});
  push(@dancecopy, ($move_number));
  print $fh3 "new dance seq @dancecopy\n" if $debug;

  return (\@dancecopy, \@newfloorplan,
    $search_state[2] + $possible_moves[$move_number][2]);
}

# Generate random permutations of N integers
# Used to generate random search trees
# Uses P dist of moves to affect P of picking a move (ADDED 12-27-98 -- ref)
# Since first move chosen is last tried, large P of being chosen == low priority!!
sub random_permute {
  my ($n) = @_;
  my (@permutation, @indices, @temp, $choice, $X);
  my ($tsum, $psum) = ($total_P_sum, 0);

  for (my $i = $n - 1 ; $i >= 0 ; $i--) {
    $indices[$i] = $i;
  }

  for (my $i = $n - 1 ; $i >= 0 ; $i--) {

##  print $fh3 "tsum is $tsum \n" if $debug;
    $X    = rand;
    $psum = 0;

##  print $fh3 "i is $i  and  X is $X \n" if $debug;
  CHOOSE:
    for (my $j = 0 ; $j <= $i ; $j++) {

      # Calculate $psum in same loop as $X comparison:
      $psum += $possible_moves[$indices[$j]][5] / $tsum;

      #print $fh3 "j is $j  and  psum is $psum \n" if $debug;
      if ($X < $psum) {$choice = $j; last CHOOSE}
    }

##  print $fh3 "choice is $choice \n" if $debug;

    @temp = splice(@indices, $choice, 1);
    $permutation[$i] = $temp[0];

##  update $tsum: remove P mass of the move just chosen:
    $tsum -= $possible_moves[$permutation[$i]][5];
  }
  return @permutation;
}

# Generate random permutations of N integers
# Used to generate random search trees
# It works by physically chopping a particular element out of @indices,
#  so that for each n from N down to 1 you can take a uniform distribution on @indices.
# (OBSOLETE: replaced by above)
sub random_permute_0 {
  my ($n) = @_;
  my (@permutation, @indices, @temp, $choice);

  for (my $i = $n - 1 ; $i >= 0 ; $i--) {
##    @indices[$i] = $i;
    $indices[$i] = $i;
  }

  for (my $i = $n - 1 ; $i >= 0 ; $i--) {
    $choice          = int(($i + 1) * rand);
    @temp            = splice(@indices, $choice, 1);
    $permutation[$i] = $temp[0];
  }
  return @permutation;
}

###########################################################################################
# Here start the predicates used in the dance move rules!!
# We need to test both couples!
# This tests that the pairs of people on the side are normal couples (facing in)

sub applies_to_any {
  my (@floorplan) = @_;
  return 1;
}

sub couples_on_side {
  my (@floorplan) = @_;

        ($floorplan[1][1]{gender} eq "M")
    and ($floorplan[0][1]{gender} eq "W")
    and ($floorplan[1][0]{gender} eq "W")
    and ($floorplan[0][0]{gender} eq "M")

}

# This tests that the men are across the set from each other
# This may have to get more complicated later
sub men_across_set {
  my (@floorplan) = @_;

  if   ($floorplan[0][0]{gender} eq $floorplan[1][0]{gender}) {return 0}
  else                                                        {return 1}
}

sub with_P {
  my (@floorplan) = @_;
  with_P_on_side(@floorplan) or with_P_at_heads(@floorplan);
}

# This tests that you and your partner are together on the side
sub with_P_on_side {
  my (@floorplan) = @_;

        ($floorplan[0][0]{direction} eq $floorplan[1][0]{direction})
    and ($floorplan[0][1]{direction} eq $floorplan[1][1]{direction})
    and ($floorplan[0][0]{gender} ne $floorplan[1][0]{gender})
    and (
    $floorplan[0][1]{gender} ne $floorplan[1][1]{gender}
    );
}

# This tests that you and your partner are together at the heads
sub with_P_at_heads {
  my (@floorplan) = @_;

        ($floorplan[0][0]{direction} eq $floorplan[0][1]{direction})
    and ($floorplan[1][0]{direction} eq $floorplan[1][1]{direction})
    and ($floorplan[0][0]{gender} ne $floorplan[0][1]{gender})
    and (
    $floorplan[1][0]{gender} ne $floorplan[1][1]{gender}
    );
}

sub with_N {
  my (@floorplan) = @_;
  with_N_on_side(@floorplan) or with_N_at_heads(@floorplan);
}

# This tests that you and your (opposite sex) neighbor are together on the side
sub with_N_on_side {
  my (@floorplan) = @_;

        ($floorplan[0][0]{direction} ne $floorplan[1][0]{direction})
    and ($floorplan[0][1]{direction} ne $floorplan[1][1]{direction})
    and ($floorplan[0][0]{gender} ne $floorplan[1][0]{gender})
    and (
    $floorplan[0][1]{gender} ne $floorplan[1][1]{gender}
    );
}

# This tests that you and your (opposite sex) neighbor are together at the heads
sub with_N_at_heads {
  my (@floorplan) = @_;

        ($floorplan[0][0]{direction} ne $floorplan[0][1]{direction})
    and ($floorplan[1][0]{direction} ne $floorplan[1][1]{direction})
    and ($floorplan[0][0]{gender} ne $floorplan[0][1]{gender})
    and (
    $floorplan[1][0]{gender} ne $floorplan[1][1]{gender}
    );
}

###########################################################################################
# Here start the actions used in the dance move rules!!
# Do nothing
sub status_quo {
  my (@floorplan) = @_;

  return @floorplan;
}

# End up facing in with (whoever you started with!) at the side
#	works the same for N or P!!
# Ah, but who are 1s and 2s depends on starting condition!!
# only two possible states: man above (swap man and woman) or man below (do nothing)
# 	but each side might be different!!
sub change_sides_to_facing_in {
  my (@floorplan) = @_;
  my @newfloorplan;

  foreach my $i (0 .. 1) {
    if ($floorplan[$i][$i]{gender} eq "W") {
      $newfloorplan[0][$i] = $floorplan[1][$i];
      $newfloorplan[1][$i] = $floorplan[0][$i];
    } else {
      $newfloorplan[0][$i] = $floorplan[0][$i];
      $newfloorplan[1][$i] = $floorplan[1][$i];
    }
  }

  return @newfloorplan;
}

# Circle Left three places
sub rotate_R_1_place {
  my (@floorplan) = @_;
  my @newfloorplan;

  $newfloorplan[1][0] = $floorplan[0][0];
  $newfloorplan[0][0] = $floorplan[0][1];
  $newfloorplan[0][1] = $floorplan[1][1];
  $newfloorplan[1][1] = $floorplan[1][0];

  return @newfloorplan;
}

# Men trade places (they started on opposite sides)
sub exchange_men_across_set {
  my (@floorplan) = @_;
  my @newfloorplan;
  my ($man0row, $man1row);

  # Find man in column 0
  foreach my $i (0 .. 1) {
    if ($floorplan[$i][0]{gender} eq "M") {$man0row = $i}
  }

  # Find man in column 1
  foreach my $i (0 .. 1) {
    if ($floorplan[$i][1]{gender} eq "M") {$man1row = $i}
  }

  # Swap men
  $newfloorplan[$man0row][0] = $floorplan[$man1row][1];
  $newfloorplan[$man1row][1] = $floorplan[$man0row][0];

  # Copy ladies
  $newfloorplan[$man0row][1] = $floorplan[$man0row][1];
  $newfloorplan[$man1row][0] = $floorplan[$man1row][0];

  return @newfloorplan;
}

# Partners trade places (they started together)
# Ps are either at heads or sides
sub exchange_Ps {
  my (@floorplan) = @_;
  my @newfloorplan;

  if ($floorplan[0][0]{direction} == $floorplan[0][1]{direction}) {

    # swap heads
    foreach my $i (0 .. 1) {
      $newfloorplan[$i][1] = $floorplan[$i][0];
      $newfloorplan[$i][0] = $floorplan[$i][1];
    }
  } else {

    # swap sides
    foreach my $i (0 .. 1) {
      $newfloorplan[0][$i] = $floorplan[1][$i];
      $newfloorplan[1][$i] = $floorplan[0][$i];
    }
  }

  return @newfloorplan;
}

# Neighbors trade places (they started together)
sub exchange_Ns {
  my (@floorplan) = @_;
  my @newfloorplan;

  if ($floorplan[0][0]{direction} != $floorplan[0][1]{direction}) {

    # swap heads
    foreach my $i (0 .. 1) {
      $newfloorplan[$i][1] = $floorplan[$i][0];
      $newfloorplan[$i][0] = $floorplan[$i][1];
    }
  } else {

    # swap sides
    foreach my $i (0 .. 1) {
      $newfloorplan[0][$i] = $floorplan[1][$i];
      $newfloorplan[1][$i] = $floorplan[0][$i];
    }
  }

  return @newfloorplan;
}

# As in CA Twirl (if we start tracking face direction, it changes)
sub switch_places_at_heads {
  my (@floorplan) = @_;
  my @newfloorplan;

  foreach my $i (0 .. 1) {
    $newfloorplan[$i][1] = $floorplan[$i][0];
    $newfloorplan[$i][0] = $floorplan[$i][1];
  }

  return @newfloorplan;
}

###########################################################################################

1;
