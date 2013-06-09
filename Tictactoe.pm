package Tictactoe;

use strict;
use warnings;

use Moose;


# To play: 
# my $game = Tictactoe->new();
# $game->play;


# Contains the tic-tac-toe board
has 'board' => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { &_new_board },
);

# Contains the name of the side whose turn it is
has 'whosturn' => (
    is => 'rw',
    isa => 'Str',
    default => 'X',
    required => 1,
);

# Whether the game is over or not
has 'gameover' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    required => 1,
);

# Counts number of turns in current game
has 'turncount' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
    required => 1,
);

# Contains the name of the winner
has 'winner' => (
    is => 'rw',
    isa => 'Str',
);

# Stores scores over multiple games
has 'scoreboard' => (
    is => 'rw',
    isa => 'HashRef',
    default => sub{ {X => 0, O => 0} },
    required => 1,
);

# Plays the game.
# Controls flow between steps.
# Steps (other subroutines) themselves don't contain any flow logic;
# all the flow logic is in this sub routine.
sub play {
    my $self = shift;

    # Reset variables for next game
    $self->{board} = $self->_new_board;
    undef $self->{winner};
    $self->{gameover} = 0;
    $self->{turncount} = 0;
    
  GAME:
    while(! $self->{gameover} )
    {
	$self->{turncount}++;
	$self->move;      # Enter the move
	$self->checkwin;  # If winning move or cats, will exit GAME while loop
	$self->end_turn;
    }
    
    # Update scoreboard
    unless ($self->{winner} eq "No one")
    {
        $self->{scoreboard}{ $self->{winner} }++;
    }

    # Display end of game material
    $self->display_board;

    print "
 -- GAME OVER --
    " . $self->{winner} . " wins!\n\n";

    print "
 -- SCOREBOARD --
    X: " . $self->{scoreboard}{X}  . "
    O: " . $self->{scoreboard}{O} . " \n\n"; 

    while (1)
    {
	print "Do you want to play again? (Enter [y]es or [n]o.)  ";	
	my $response = <STDIN>;
	chomp $response;
	if ($response =~ m/y/i) 
	{
	    $self->play;
	}
	else
	{
	    print "\n\nThanks for playing!\n\n";
	    exit;
	}
    }
}


sub _new_board
{
    # Define rows for the board
    my @line_space = (((" ",)x5, "|")x2,(" ",)x5, "\n"); # 17
    my @line1 = (((" ",)x5, "|")x2,(" ",)x5, "\n"); # 17
    my @line2 = (((" ",)x5, "|")x2,(" ",)x5, "\n"); # 17
    my @line3 = (((" ",)x5, "|")x2,(" ",)x5, "\n"); # 17
    my @sep = (("-",)x17, "\n");

    # Assemble rows into an array_ref of array_refs
    my $board = [(\@line_space), (\@line1), (\@line_space), \@sep, (\@line_space), (\@line2), (\@line_space), \@sep, (\@line_space), (\@line3), (\@line_space)];

    return $board;
}


sub display_board
{
    my $self = shift;
    my $board = $self->{board};
    
    print "\n\n";
    foreach my $row ( @{$board} )
    {
        foreach my $cell (@{$row})
	{
	    print $cell;
	}
    }
    print "\n\n";
    
    return $board;
}


sub move
{
    my $self = shift;
    my ($x, $y) = $self->get_move;

    while (! $self->check_move($x, $y) )
    {
	print "Sorry, that's not a valid move.\n";	
	($x, $y) = $self->get_move;
    }
    
    $self->make_move($x, $y);
}


sub get_move
{
    my $self = shift;
    my $turn = $self->{whosturn};
    my ($x, $y);

  GETINPUT:
    while (1)
    {
	$self->display_board;
	print "\n\nIt is " . $turn . "'s turn to move.\n";
	print "\nEnter your next move as a pair of (X,Y) coordinates: ";
	
	my $move = <STDIN>;

	# Input contains two numbers
	if ($move =~ m/.*?(\d).*?(\d)/)
	{
	    $x = $1;
	    $y = $2;

	    # Check if valid numbers
	    if ($x ~~ [1..3] && $y ~~ [1..3])
	    {
		# Numbers are valid; exit loop
		last GETINPUT; 
	    }
	    else
	    {
		# Numbers are invalid; continue loop
		print "Both numbers need to be between 1 and 3.\n";
		next GETINPUT;
	    }
	}
	# Input does not contain two numbers
	else
	{
	    print "Sorry, you didn't include two numbers.\n";
	    next GETINPUT;
	}
	
    }

    return ($x, $y);
}


sub check_move
{
    my $self = shift;
    my ($x, $y) = @_;

    my ($x_t, $y_t) = &_translate_move($x, $y);
    my $cell = $self->{board}->[$y_t]->[$x_t];

    # Check if move is valid
    if ($cell =~ m/\s/)
    {
	# Move is valid
	return 1;
    }
    else
    {
	# Move is invalid
	return 0;
    }
}

sub _translate_move
{
    my ($x, $y) = @_;
    my %translate_move = (X => {1 => 2, 2 => 8, 3 => 14},
			  Y => {1 => 1, 2 => 5, 3 => 9});

    my $x_t = $translate_move{X}{$x};
    my $y_t = $translate_move{Y}{$y};

    return ($x_t, $y_t);
}


sub make_move
{
    my $self = shift;
    my ($x, $y) = @_;

    my ($x_t, $y_t) = _translate_move($x, $y);

    $self->{board}->[$y_t]->[$x_t] = $self->{whosturn};

    return $self->{board};
}


sub end_turn
{
    my $self = shift;

    # Change turn
    if ($self->{whosturn} eq "X") 
    {
	$self->{whosturn} = "O";
    }
    else 
    {
	$self->{whosturn} = "X";
    }
    return 1;
}


sub checkwin
{
    my $self = shift;
    my $turn = $self->{whosturn};

    # Winning patterns
    my @win = ([11, 12, 13], #Vertical  
	       [21, 22, 23],
	       [31, 32, 33],
	       [11, 21, 31], #Horizontal
	       [12, 22, 32],
	       [13, 23, 33],
	       [11, 22, 33], #Diagonal
	       [13, 22, 31]);

    # Get cells for each pattern and check if all match current turn
    foreach my $pattern (@win)
    {
	my @array;

	foreach my $cell (@{$pattern})
	{
	    my ($x, $y);
	    if ($cell =~ m/(\d)(\d)/)
	    {
		$x = $1;
		$y = $2;
	    }
	
	    my ($x_t, $y_t) = &_translate_move($x, $y);
	    my $cell = $self->{board}->[$y_t]->[$x_t];
	    
	    push(@array, $cell);
	}
	
	# Check for winner
	if ($array[0] eq $turn && $array[1] eq $turn && $array[2] eq $turn)
	{
	    $self->{winner} = $self->{whosturn};
	    $self->{gameover} = 1;
	    return 1;
	}
    }

    # Check for cats
    if ($self->{turncount} == 9)
    { 
        $self->{winner} = "No one";
	$self->{gameover} = 1;
	return 1;
    }
    
    return 0;
}

no Moose;
1;
