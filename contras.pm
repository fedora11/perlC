#!/usr/bin/perl
#  contras.pm

# Random Contra Dance Generator
# Copyright (c) 1998, 1999 Robert E. Frederking
# Permission is granted to copy and distribute for non-commercial use only

# *** Update this with each "release" on the Web:
# First Release Begun: 30-Dec-98
$version = "0.1";

# Starts with a database of moves, and produces working contra dances
# (though not necessarily artistically pleasant ones).

# Have a safety valve: search is not allowed to run more than $N times (10,000??)

$search_step_limit = 10000;

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
@possible_moves = (
  [[\&couples_on_side], \&status_quo, 16, "Hey for Four", "Hey", 2],
# This pretends we stay in normal improper contra position:
  [[\&couples_on_side], \&status_quo, 16, "Down the Hall in Lines of Four and<BR> 
    Turn as a Couple and Come Back to Place", "DHL4/turn_couple", 2],
  [[\&men_across_set], \&exchange_men_across_set, 4, "Men pass Left across set", "Men_cross", 10],
  [[\&with_P_on_side], \&change_sides_to_facing_in, 8, "Swing your Partner", "Swing_P/in", 1],    # end facing in?
  [[\&with_P_on_side], \&change_sides_to_facing_in, 12, "Swing your Partner (12 counts)", "Swing_P/in/12", 2],    # end facing in?
  [[\&with_P_on_side], \&change_sides_to_facing_in, 16, "Balance and Swing Partner", "B+S_N/in", 1],    # end facing in?
  [[], \&rotate_R_1_place, 8, "Circle Left three places", "Circle_L_3", 1],
  [[], \&status_quo, 4, "Balance the circle", "Bal_circle", 5],
  [[\&with_P], \&exchange_Ps, 4, "Box the Gnat with your Partner", "Box_Gnat_P", 10],
  [[\&with_N], \&exchange_Ns, 4, "Box the Gnat with your Neighbor", "Box_Gnat_N", 10],
  [[\&with_P], \&exchange_Ps, 8, "Balance and Box the Gnat with your Partner", "B+Box_Gnat_P", 10],
  [[\&with_N], \&exchange_Ns, 8, "Balance and Box the Gnat with your Neighbor", "B+Box_Gnat_N", 10],
  [[\&with_P_at_heads],\&switch_places_at_heads, 4, "California Twirl Partner", "CA_twirl", 5],
  [[\&with_N_on_side], \&change_sides_to_facing_in, 8, "Swing your Neighbor", "Swing_P/in", 1],    # end facing in?
  [[\&with_N_on_side], \&change_sides_to_facing_in, 12, "Swing your Neighbor (12 counts)", "Swing_P/in/12", 2],    # end facing in?
  [[\&with_N_on_side], \&change_sides_to_facing_in, 16, "Balance and Swing Neighbor", "B+S_N/in", 1],    # end facing in?
  [[\&with_P], \&status_quo, 8, "Do-si-do your Partner", "Dosido_P", 5],
  [[\&with_N], \&status_quo, 8, "Do-si-do your Neighbor", "Dosido_N", 5],
  [[], \&status_quo, 8, "Men Do-si-do", "Dosido_M", 10],
  [[], \&status_quo, 8, "Women Do-si-do", "Dosido_W", 10],
);
#>>>
# This gets us the size of the move array:
$number_of_moves = @possible_moves;

# Compute total "P" mass across all possible moves:
$total_P_sum = 0;
for ($i = 0 ; $i < $number_of_moves ; $i++) {
  $total_P_sum += $possible_moves[$i][5];
}

# Have a parameter that makes it print out list of available moves!
# This prints each move, and the number of steps it takes:
sub print_out_moves {
  my $handle = pop @_;

  # *** Would be prettier if a "(" prevented the step count from printing:
  print $handle
    "There are $number_of_moves contra dance moves defined in version $version:<P>\n\n";
  foreach $move (@possible_moves) {
    print $handle "${$move}[3] (${$move}[2] steps)<BR>\n";
  }
}

$max_dance_len = 64;

# Have an indicator of type of dance (improper, Becket, proper, etc.)
# This selects the initial floorplan
$floorplan_type    = improper;
@initial_floorplan = (
  [{gender => lady, direction => 1}, {gender => gent, direction => 1}],
  [{gender => gent, direction => 2}, {gender => lady, direction => 2}]
);

# This tests the predicates:
# print &{$possible_moves[0][0][0]}(@initial_floorplan); print " (couples on side)\n";
# print &{$possible_moves[1][0][0]}(@initial_floorplan); print " (with N on side)\n";

# Puts a blank line between As/Bs, and labels them
sub print_dance {
  my ($handle, @dance) = @_;
  my $move_cntr;

  print $handle "<DL COMPACT><DT><B>A1:</B>";
  foreach $i (@dance) {
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
@initial_state = ([], \@initial_floorplan, 0);

sub print_floorplan {
  my ($handle, @floorplan) = @_;

## print $handle "Rows: ", @floorplan, "\n";
  foreach $i (0, 1) {
    print $handle $floorplan[$i][0]{gender}, " ", $floorplan[$i][0]{direction},
      "    ";
    print $handle $floorplan[$i][1]{gender}, " ", $floorplan[$i][1]{direction},
      "\n";
  }
}

sub print_dance_w_floorplans {
  my ($handle, @dance) = @_;
  my $move_cntr;
  my @floorplan = @initial_floorplan;

  print $handle "A1: ";
  foreach $i (@dance) {
    if ($move_cntr == 16)     {print $handle "\nA2: "}
    if ($move_cntr == 32)     {print $handle "\nB1: "}
    if ($move_cntr == 48)     {print $handle "\nB2: "}
    if ($move_cntr % 16 != 0) {print $handle "    "}

    print $handle $possible_moves[$i][3], "\n";

    @floorplan = &{$possible_moves[$i][1]}(@floorplan);
    &print_floorplan($handle, @floorplan);

    $move_cntr = $move_cntr + $possible_moves[$i][2];
  }
}

###########################################################################################
## This provides answers for fake move selection at each step of test run!
## @test = ([4],[3,4]);
# Main program

sub main_contra_generator {
  my $handle = pop @_;

  open(TRACE, ">contra_trace.log");

  $search_step_cnt = 0;

  # This prints initial floorplan
  &print_floorplan(TRACE, @initial_floorplan);
  print TRACE "\n";

# set seed from time or from user input, print seed out with answer as dance number
# subtract/add 910200000 from/to time

  # Disable input for the Web for the moment:
  #     print $handle "Dance number? [random] ";
  #     if (($input = <>) eq "\n")
  {$seed = time};

  #     else
  #     {$seed = $input+910200000};
  srand($seed);

  #     print $handle "\n";

  # This shows that original dance (Piece o' Cake) is done correctly:
  # (using possibly obsolete move numbers, and no prec checking!)
  # &print_dance_w_floorplans(TRACE, (7,0,1,3,4,5,6)); print TRACE "\n";

  # This is here in case things really die later:
  print TRACE "Dance number ", $seed - 910200000, " (version $version)\n";

  &random_dfs(@initial_state);

  if ($search_step_flag eq "TOODEEP") {
    print TRACE "Dance search exceeded limit, ", $search_step_limit,
      " search steps!\n\n";
    print $handle "Dance search exceeded limit, ", $search_step_limit,
      " search steps!\n<BR>\n";
  } else {
    &print_dance_w_floorplans(TRACE, @{$solution[0]});
    print TRACE "\n";
    &print_floorplan(TRACE, @{$solution[1]});
    print TRACE "\n";
    print TRACE "steps: ", $solution[2];
    print TRACE "\n\n";

    &print_dance($handle, @{$solution[0]});
    print $handle "\n<BR>";
  }

  print TRACE "Dance number ", $seed - 910200000, " (version $version)\n";
  print $handle "<P><I>Dance number ", $seed - 910200000,
    " (version $version)</I>\n";
}

###########################################################################################
## This debugging stub replaces random_permute with number from list
## Need to also tell it to fail at some point?  Not so far.
sub fake_random_permute {
  return @{$test[$search_step_cnt - 1]};
}

# Recursive random DFS function!
sub random_dfs {
  my @search_state = @_;
  my (@children_order, @temp);

  # This prevents infinite searches
  $search_step_cnt++;
  if ($search_step_cnt >= $search_step_limit) {
    $search_step_flag = "TOODEEP";
    return 0;
  }
  print TRACE "\nSearch step count: $search_step_cnt \n";

  if (&solution_p(@search_state)) {
    @solution = @search_state;
    return @solution;
  }
  if ($search_state[2] >= $max_dance_len) {
    return 0;
  }

  @children_order = &random_permute($number_of_moves);

  foreach $child_move (@children_order) {
    if (&applicable_to_state($child_move, @search_state)) {
      @temp = &apply($child_move, @search_state);
      &random_dfs(@temp);
    }
    if (@solution) {return @solution;}
    elsif ($search_step_flag eq "TOODEEP") {return 0}
  }

}

# This will be a test for 64 steps and correct progression:
sub solution_p {
  my @search_state = @_;

  if ($search_state[2] == 64) {
    foreach $i (0 .. 1) {
      if ( (${$search_state[1]}[0][$i]{direction} != 2)
        or (${$search_state[1]}[1][$i]{direction} != 1)
        or (${$search_state[1]}[$i][$i]{gender} ne gent)
        or (${$search_state[1]}[1 - $i][$i]{gender} ne lady))
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
  foreach $old_move (@previous_moves) {
    if ($old_move == $move_number) {return 0}
  }

  foreach $prec (@{$possible_moves[$move_number][0]}) {

    # print TRACE "for $prec : ", &{$prec}(@{$search_state[1]}), "\n";
    if (!&{$prec}(@{$search_state[1]})) {return 0;}
  }

  print TRACE "Start cnt: $search_state[2]  End cnt: ";
  print TRACE ($search_state[2] + $possible_moves[$move_number][2]);
  print TRACE " Boundary: ", (16 * (1 + int($search_state[2] / 16))), "\n";

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
## 	my @floorplancopy;

  print TRACE " " x $search_state[2];
  print TRACE
    "applying move $move_number $possible_moves[$move_number][4] to state @search_state\n";

## print TRACE "Before action floorplancopy: ", \@floorplancopy, "\n";
## &print_floorplan(TRACE, @floorplancopy);
## print TRACE "Before action search_state: ", \@{$search_state[1]}, "\n";
## &print_floorplan(TRACE, @{$search_state[1]});
## print TRACE "\n";

  # Need to copy the array (or something) due to destructive ops!!!
  @dancecopy = @{$search_state[0]};

## 	$floorplancopy[0][0] = ${$search_state[1]}[0][0];
## 	$floorplancopy[0][1] = ${$search_state[1]}[0][1];
## 	$floorplancopy[1][0] = ${$search_state[1]}[1][0];
## 	$floorplancopy[1][1] = ${$search_state[1]}[1][1];

  @newfloorplan = &{$possible_moves[$move_number][1]}(@{$search_state[1]});
  push(@dancecopy, ($move_number));

  return (\@dancecopy, \@newfloorplan,
    $search_state[2] + $possible_moves[$move_number][2]);
}

# Generate random permutations of N integers
# Used to generate random search trees
# Uses P dist of moves to affect P of picking a move (ADDED 12-27-98 -- ref)
# Since first move chosen is last tried, large P of being chosen == low priority!!
sub random_permute {
  my $n = pop @_;
  my $X;
  ($tsum, $psum) = ($total_P_sum, 0);

  for ($i = $n - 1 ; $i >= 0 ; $i--) {
    @indices[$i] = $i;
  }

  for ($i = $n - 1 ; $i >= 0 ; $i--) {

    #print TRACE "tsum is $tsum \n";
    $X    = rand;
    $psum = 0;

    #print TRACE "i is $i  and  X is $X \n";
  CHOOSE:
    for ($j = 0 ; $j <= $i ; $j++) {

      # Calculate $psum in same loop as $X comparison:
      $psum += $possible_moves[$indices[$j]][5] / $tsum;

      #print TRACE "j is $j  and  psum is $psum \n";
      if ($X < $psum) {$choice = $j; last CHOOSE}
    }

    #print TRACE "choice is $choice \n";

    @temp = splice(@indices, $choice, 1);
    $permutation[$i] = $temp[0];

    # update $tsum: remove P mass of the move just chosen:
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
  my $n = pop @_;

  for ($i = $n - 1 ; $i >= 0 ; $i--) {
    @indices[$i] = $i;
  }

  for ($i = $n - 1 ; $i >= 0 ; $i--) {
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
sub couples_on_side {
  my @floorplan = @_;

        ($floorplan[1][1]{gender} eq gent)
    and ($floorplan[0][1]{gender} eq lady)
    and ($floorplan[1][0]{gender} eq lady)
    and ($floorplan[0][0]{gender} eq gent)

}

# This tests that the men are across the set from each other
# This may have to get more complicated later
sub men_across_set {
  my @floorplan = @_;

  if   ($floorplan[0][0]{gender} eq $floorplan[1][0]{gender}) {return 0}
  else                                                        {return 1}
}

sub with_P {
  &with_P_on_side or &with_P_at_heads;
}

# This tests that you and your partner are together on the side
sub with_P_on_side {
  my @floorplan = @_;

        ($floorplan[0][0]{direction} eq $floorplan[1][0]{direction})
    and ($floorplan[0][1]{direction} eq $floorplan[1][1]{direction})
    and ($floorplan[0][0]{gender} ne $floorplan[1][0]{gender})
    and (
    $floorplan[0][1]{gender} ne $floorplan[1][1]{gender}
    );
}

# This tests that you and your partner are together at the heads
sub with_P_at_heads {
  my @floorplan = @_;

        ($floorplan[0][0]{direction} eq $floorplan[0][1]{direction})
    and ($floorplan[1][0]{direction} eq $floorplan[1][1]{direction})
    and ($floorplan[0][0]{gender} ne $floorplan[0][1]{gender})
    and (
    $floorplan[1][0]{gender} ne $floorplan[1][1]{gender}
    );
}

sub with_N {
  &with_N_on_side or &with_N_at_heads;
}

# This tests that you and your (opposite sex) neighbor are together on the side
sub with_N_on_side {
  my @floorplan = @_;

        ($floorplan[0][0]{direction} ne $floorplan[1][0]{direction})
    and ($floorplan[0][1]{direction} ne $floorplan[1][1]{direction})
    and ($floorplan[0][0]{gender} ne $floorplan[1][0]{gender})
    and (
    $floorplan[0][1]{gender} ne $floorplan[1][1]{gender}
    );
}

# This tests that you and your (opposite sex) neighbor are together at the heads
sub with_N_at_heads {
  my @floorplan = @_;

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
  my @floorplan = @_;

  return @floorplan;
}

# End up facing in with (whoever you started with!) at the side
#	works the same for N or P!!
# Ah, but who are 1s and 2s depends on starting condition!!
# only two possible states: man above (swap man and woman) or man below (do nothing)
# 	but each side might be different!!
sub change_sides_to_facing_in {
  my @floorplan = @_;
  my @newfloorplan;

  foreach $i (0 .. 1) {
    if ($floorplan[$i][$i]{gender} eq lady) {
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
  my @floorplan = @_;
  my @newfloorplan;

  $newfloorplan[1][0] = $floorplan[0][0];
  $newfloorplan[0][0] = $floorplan[0][1];
  $newfloorplan[0][1] = $floorplan[1][1];
  $newfloorplan[1][1] = $floorplan[1][0];

  return @newfloorplan;
}

# Men trade places (they started on opposite sides)
sub exchange_men_across_set {
  my @floorplan = @_;
  my @newfloorplan;
  my ($man0row, $man1row);

  # Find man in column 0
  foreach $i (0 .. 1) {
    if ($floorplan[$i][0]{gender} eq gent) {$man0row = $i}
  }

  # Find man in column 1
  foreach $i (0 .. 1) {
    if ($floorplan[$i][1]{gender} eq gent) {$man1row = $i}
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
  my @floorplan = @_;
  my @newfloorplan;

  if ($floorplan[0][0]{direction} == $floorplan[0][1]{direction}) {

    # swap heads
    foreach $i (0 .. 1) {
      $newfloorplan[$i][1] = $floorplan[$i][0];
      $newfloorplan[$i][0] = $floorplan[$i][1];
    }
  } else {

    # swap sides
    foreach $i (0 .. 1) {
      $newfloorplan[0][$i] = $floorplan[1][$i];
      $newfloorplan[1][$i] = $floorplan[0][$i];
    }
  }

  return @newfloorplan;
}

# Neighbors trade places (they started together)
sub exchange_Ns {
  my @floorplan = @_;
  my @newfloorplan;

  if ($floorplan[0][0]{direction} != $floorplan[0][1]{direction}) {

    # swap heads
    foreach $i (0 .. 1) {
      $newfloorplan[$i][1] = $floorplan[$i][0];
      $newfloorplan[$i][0] = $floorplan[$i][1];
    }
  } else {

    # swap sides
    foreach $i (0 .. 1) {
      $newfloorplan[0][$i] = $floorplan[1][$i];
      $newfloorplan[1][$i] = $floorplan[0][$i];
    }
  }

  return @newfloorplan;
}

# As in CA Twirl (if we start tracking face direction, it changes)
sub switch_places_at_heads {
  my @floorplan = @_;
  my @newfloorplan;

  foreach $i (0 .. 1) {
    $newfloorplan[$i][1] = $floorplan[$i][0];
    $newfloorplan[$i][0] = $floorplan[$i][1];
  }

  return @newfloorplan;
}

###########################################################################################

1;
