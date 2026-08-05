#########################################################################
#  OpenKore - Interface::Console::Win32
#
#  Copyright (c) 2004 OpenKore development team 
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#
#  $Revision$
#  $Id$
#
#########################################################################
##
# MODULE DESCRIPTION: 
#
# Support for asyncronous input on MS Windows computers

package Interface::Console::Win32;

use strict;
use warnings;

die "W32 only, this module should never be called on any other OS\n"
		unless ($^O eq 'MSWin32' || $^O eq 'cygwin');

use Carp;
use Time::HiRes qw/time sleep/;
use Text::Wrap;
use Win32::Console;
use Utils::Win32;
use utf8;
use Encode;
use I18N qw(stringToBytes);
use Translation qw(T);


use Globals;
use Settings qw(%sys);
use base qw(Interface::Console);

our %fgcolors;
our %bgcolors;

sub new {
	my $class = shift;
	my $self = {
		input_list => [],
		last_line_end => 1,
		input_lines => [],
		input_offset => 0,
		input_part => '',
	};
	bless $self, $class;
	$self->{out_con} = new Win32::Console(STD_OUTPUT_HANDLE()) 
			or die "Could not init output Console: $!\n";
	$self->{in_con} = new Win32::Console(STD_INPUT_HANDLE()) 
			or die "Could not init input Console: $!\n";
	$self->setWinDim();
	
	$self->{out_con}->Cursor(0, $self->{in_line});
	$self->{codepage} = $self->{out_con}->OutputCP;
	return $self;
}

sub DESTROY {
	my $self = shift;

	$self->color('reset');
}

sub setWinDim {
	my $self = shift;
	# start.exe + redirected stdout often has no real console → Window()/Size()
	# return undefs. Avoid "Use of uninitialized value" spam (lines ~83/85).
	my @win = eval { $self->{out_con}->Window() };
	@win = () if $@ || !@win;
	my @size = eval { $self->{out_con}->Size() };
	@size = () if $@ || !@size;
	my ($wLeft, $wTop, $wRight, $wBottom) = @win;
	my ($bCol, $bRow) = @size;
	my $have_dims =
		defined $wLeft && defined $wTop && defined $wRight && defined $wBottom
		&& defined $bCol && defined $bRow
		&& $bRow > 0 && $wRight >= $wLeft;

	if ($have_dims) {
		eval {
			$self->{out_con}->Window(1, $wLeft, $bRow - $wBottom - 1, $wRight, $bRow - 1);
		};
		my @after = eval { $self->{out_con}->Window() };
		if (!$@ && @after >= 4
			&& defined $after[0] && defined $after[1]
			&& defined $after[2] && defined $after[3]) {
			@{$self}{qw(left out_top right in_line)} = @after[0, 1, 2, 3];
		} else {
			@{$self}{qw(left out_top right in_line)} = ($wLeft, $wTop, $wRight, $wBottom);
		}
	} else {
		# Sensible fallback geometry when console dims are unavailable
		@{$self}{qw(left out_top right in_line)} = (0, 0, 79, 24);
	}
	$self->{out_bot} = $self->{in_line} - 1; #one line above the input line
	$self->{out_line} = $self->{in_line};
	$self->{out_col} = $self->{in_pos} = $self->{left};
}

sub getInput {
#	return undef unless ($enabled);
	my $self = shift;
	my $timeout = shift;
	$self->readEvents();
	my $msg;
	if ($timeout < 0) {
		until (defined $msg) {
			$self->readEvents();
			sleep 0.01;
			if (@{$self->{input_lines}}) {
				$msg = shift @{$self->{input_lines}};
			}
		}
	} elsif ($timeout > 0) {
		my $end = time + $timeout;
		until ($end < time || defined $msg) {
			$self->readEvents();
			sleep 0.01;
			if (@{$self->{input_lines}}) {
				$msg = shift @{$self->{input_lines}};
			}
		}
	} else {
		if (@{$self->{input_lines}}) {
			$msg = shift @{$self->{input_lines}};
		}
	}
	undef $msg if (defined $msg && $msg eq '');

	return $msg;
}


##
# readEvents()
#
# reads low level events from the input console, for key presses it
# updates the console input variables
#
# note: most of this is commented out, it need a cordinated output
# system to use the separate input line (meaning output does not
# over write your input line)
sub readEvents {
	my $self = shift;
#	local($|) = 1;
	while ($self->{in_con}->GetEvents()) {
		my @event = $self->{in_con}->Input();

		if (@event && $event[5] < 0) {
			# Special characters are returned as unsigned integer
			# (dunno why). Fix this.
			$event[5] = 256 + $event[5];
		}
		if (@event && $event[0] == 1 && $event[1] == 0 && $event[3] == 18) {
			# Alt was released and there's an ASCII code. This is
			# a special character. Change @events as if a normal key
			# was pressed.
			$event[1] = 1;
		}

		if (@event && $event[0] == 1 && $event[1] == 1) {
			##Ctrl+U (erases entire line)
			if ($event[6] == 40 && $event[5] == 21) {
				$self->{in_pos} = 0;
				$self->{out_con}->Scroll(
					0, $self->{in_line}, $self->{right}, $self->{in_line},
					-$self->{right}, $self->{in_line}, ord(' '), $main::ATTR_NORMAL, 
					0, $self->{in_line}, $self->{right}, $self->{in_line},
				);
				$self->{out_con}->Cursor(0, $self->{in_line});
				$self->{input_part} = '';
			##Backspace
			} elsif ($event[5] == 8) {
				$self->{in_pos}-- if $self->{in_pos} > 0;
				substr($self->{input_part}, $self->{in_pos}, 1, '');
				$self->{out_con}->Scroll(
					$self->{in_pos}, $self->{in_line}, $self->{right}, $self->{in_line},
					$self->{in_pos}-1, $self->{in_line}, ord(' '), $main::ATTR_NORMAL, 
					$self->{in_pos}, $self->{in_line}, $self->{right}, $self->{in_line},
				);
				$self->{out_con}->Cursor($self->{in_pos}, $self->{in_line});
#				print "\010 \010";
			##Enter
			} elsif ($event[5] == 13) {
				my $ret = $self->{out_con}->Scroll(
					$self->{left}, 0, $self->{right}, $self->{in_line},
					0, -1, ord(' '), $main::ATTR_NORMAL, 
					$self->{left}, 0, $self->{right}, $self->{in_line}
				);
				$self->{out_con}->Cursor(0, $self->{in_line});
				$self->{in_pos} = 0;
				$self->{input_list}[0] = $self->{input_part};
				if ($self->{input_part} ne ""
				 && ( @{$self->{input_list}} < 2 || $self->{input_list}[1] ne $self->{input_part} )) {
					unshift(@{ $self->{input_list} }, "");
				}
				push @{ $self->{input_lines} }, $self->{input_part};
				$self->{out_col} = 0;
				$self->{input_offset} = 0;
				$self->{input_part} = '';
#				print "\n";
			#Other ASCII (+ ISO Latin-*)
			} elsif ($event[5] >= 32 && $event[5] != 127 && $event[5] <= 255) {
				my $char;
				eval {
					$char = Encode::decode("cp" . $self->{codepage}, chr($event[5]));
				};
				if ($@ =~ /^Unknown encoding/s) {
					$self->errorDialog(T("Your Windows's default language is not supported by OpenKore.\n" .
						"Please go to 'Start->Control Panel->Regional and language options' and set " .
						"the Windows default language to English."));
					exit 1;
				} elsif ($@) {
					die $@;
				}

				if ($self->{in_pos} < length($self->{input_part})) {
					$self->{out_con}->Scroll(
						$self->{in_pos}, $self->{in_line}, $self->{right}, $self->{in_line},
						$self->{in_pos}+1, $self->{in_line}, ord(' '), $main::ATTR_NORMAL, 
						$self->{in_pos}, $self->{in_line}, $self->{right}, $self->{in_line},
					);
				} elsif ($self->{in_pos} > length($self->{input_part})) {
					$self->{in_pos} = length($self->{input_part});
				}
				$self->{out_con}->Cursor($self->{in_pos}, $self->{in_line});
				Utils::Win32::printConsole($char);
				substr($self->{input_part}, $self->{in_pos}, 0, $char) if ($self->{in_pos} <= length($self->{input_part}));
				$self->{in_pos}++;
#			} elsif ($event[3] == 33) {
#				__PACKAGE__->writeOutput("pgup\n");
#			} elsif ($event[3] == 34) {
#				__PACKAGE__->writeOutput("pgdn\n");
			##End
			} elsif ($event[3] == 35) {
				$self->{out_con}->Cursor($self->{in_pos} = length($self->{input_part}), $self->{in_line});
			##Home
			} elsif ($event[3] == 36) {
				$self->{out_con}->Cursor($self->{in_pos} = 0, $self->{in_line});
			##Left Arrow
			} elsif ($event[3] == 37) {
				$self->{in_pos}-- if ($self->{in_pos} > 0);
				$self->{out_con}->Cursor($self->{in_pos}, $self->{in_line});
			##Up Arrow
			} elsif ($event[3] == 38) {
				unless ($self->{input_offset}) {
					$self->{input_list}[$self->{input_offset}] = $self->{input_part};
				}
				$self->{input_offset}++;
				$self->{input_offset} = $#{$self->{input_list}} if ($self->{input_offset} > $#{$self->{input_list}});
				#$self->{input_offset} -= $#{ $self->{input_list} } + 1 while $self->{input_offset} > $#{ $self->{input_list} };

				$self->{out_con}->Cursor(0, $self->{in_line});
				$self->{out_con}->Write(' ' x length($self->{input_part}));
				$self->{out_con}->Cursor(0, $self->{in_line});
				$self->{input_part} = $self->{input_list}[$self->{input_offset}];
				Utils::Win32::printConsole($self->{input_part});
				$self->{in_pos} = length($self->{input_part});
			##Right Arrow
			} elsif ($event[3] == 39) {
					$self->{in_pos}++ if $self->{in_pos} + 1 <= length($self->{input_part});
					$self->{out_con}->Cursor($self->{in_pos}, $self->{in_line});
			##Down Arrow
			} elsif ($event[3] == 40) {
				unless ($self->{input_offset}) {
					$self->{input_list}[$self->{input_offset}] = $self->{input_part};
				}
				$self->{input_offset}--;
				$self->{input_offset} = 0 if ($self->{input_offset} < 0);
				#$self->{input_offset} += $#{ $self->{input_list} } + 1 while $self->{input_offset} < 0;

				$self->{out_con}->Cursor(0, $self->{in_line});
				$self->{out_con}->Write(' ' x length($self->{input_part}));
				$self->{out_con}->Cursor(0, $self->{in_line});
				$self->{input_part} = $self->{input_list}[$self->{input_offset}];
				Utils::Win32::printConsole($self->{input_part});
				$self->{in_pos} = length($self->{input_part});
			##Insert
#			} elsif ($event[3] == 45) {
#				__PACKAGE__->writeOutput("insert\n");
			##Delete
			} elsif ($event[3] == 46) {
				substr($self->{input_part}, $self->{in_pos}, 1, '');
				$self->{out_con}->Scroll(
					$self->{in_pos}, $self->{in_line}, $self->{right}, $self->{in_line},
					$self->{in_pos} - 1, $self->{in_line}, ord(' '), $main::ATTR_NORMAL, 
					$self->{in_pos}, $self->{in_line}, $self->{right}, $self->{in_line},
				);
			##F1-F12
#			} elsif ($event[3] >= 112 && $event[3] <= 123) {
#				__PACKAGE__->writeOutput("F" . ($event[3] - 111) . "\n");
#			} else {
#				__PACKAGE__->writeOutput(join '-', @event, "\n");
			}
#		} else {
#			__PACKAGE__->writeOutput(join '-', @event, "\n");
		}
	}	
}


sub writeOutput {
	my ($self, $type, $message, $domain) = @_;

	#wrap the text
	# Text::Wrap requires columns >= 2; left/right can be undef under start.exe /
	# redirected stdout before Window() dims are ready — caused customer log spam.
	my $left = defined $self->{left} ? $self->{left} : 0;
	my $right = defined $self->{right} ? $self->{right} : 79;
	my $cols = $right - $left + 1;
	$cols = 2 if !defined $cols || $cols < 2;
	local($Text::Wrap::columns) = $cols;
	my ($endspace) = $message =~ /(\s*)$/; #Save trailing whitespace: wrap kills spaces near wraps, especialy at the end of stings, so "\n" becomes "", not what we want
	$message = wrap('', '', $message);
	$message =~ s/\s*$/$endspace/; #restore the whitespace
	
	my $lines = $message =~ s/\r?\n/\n/g; #fastest? way to count newlines
	
	#this paragraph is all about handleing lines that don't end in a newline. I have no clue how it works, even though I wrote it, but it does. =)
	$lines++ if (!$lines && $self->{last_line_end});
	if ($lines && !$self->{last_line_end}) {
		$lines--;
		$self->{out_line}--;
	} elsif (!$self->{last_line_end}) {
		$self->{out_line}--;
	}
	$self->{last_line_end} = ($message =~ /\n$/) ? 1 : 0;

	# Reuse clamped wrap dims so Scroll/Cursor never see undef (spam ~320/326).
	my $out_bot = defined $self->{out_bot} ? $self->{out_bot} : 23;
	my $out_line = defined $self->{out_line} ? $self->{out_line} : $out_bot;
	my $out_col = defined $self->{out_col} ? $self->{out_col} : $left;

	my $ret = eval {
		$self->{out_con}->Scroll(
			$left, 0, $right, $out_bot,
			0, 0-$lines, ord(' '), $main::ATTR_NORMAL,
			$left, 0, $right, $out_bot
		);
	};

	my ($ocx, $ocy) = eval { $self->{out_con}->Cursor() };
	$ocx = 0 unless defined $ocx;
	$ocy = 0 unless defined $ocy;
	eval { $self->{out_con}->Cursor($out_col, $out_line - $lines) };
	$self->setColor($type, $domain);
	#$self->{out_con}->Write($message);
	Utils::Win32::printConsole($message);
	$self->color('reset');
	my @cur = eval { $self->{out_con}->Cursor() };
	if (!$@ && @cur >= 2 && defined $cur[0] && defined $cur[1]) {
		($self->{out_col}, $self->{out_line}) = @cur;
	} else {
		$self->{out_col} = $out_col;
		$self->{out_line} = $out_line;
	}
	$self->{out_line} -= $self->{last_line_end} - 1;
	eval { $self->{out_con}->Cursor($ocx, $ocy) };
}

sub setColor {
	return if (!$consoleColors{''}{'useColors'});
	my $self = shift;
	my ($type, $domain) = @_;
	my $color;
	$color = $consoleColors{$type}{$domain} if (defined $type && defined $domain && defined $consoleColors{$type});
	$color = $consoleColors{$type}{'default'} if (!defined $color && defined $type);
	$self->color($color) if (defined $color);
}

sub color {
	my $self = shift;
	my $color = shift;
	my ($bgcolor, $fgcode, $bgcode);
	$color =~ s/\/(.*)//;
	$bgcolor = $1 || "default";

	$fgcode = $fgcolors{$color} || $fgcolors{'default'};
	$bgcode = $bgcolors{$bgcolor} || $bgcolors{'default'};
	$self->{out_con}->Attr($fgcode | $bgcode);
}

sub title {
	my ($self, $title) = @_;

	if (defined $title) {
		if (!defined $self->{currentTitle} || $self->{currentTitle} ne $title) {
			Utils::Win32::setConsoleTitle($title);
			$self->{currentTitle} = $title;
		}
	} else {
		return $self->{out_con}->Title();
	}
}

# IRGB
# 8421

# Deal with ActivePerl version incompatibilities
if (defined($main::ATTR_NORMAL)) {
	%fgcolors = (
	'reset'		=> $main::ATTR_NORMAL,
	'default'	=> $main::ATTR_NORMAL,
	'black'		=> $main::FG_BLACK,
	'darkgray'	=> FOREGROUND_INTENSITY(),
	'darkgrey'	=> FOREGROUND_INTENSITY(),
	'darkred'	=> $main::FG_RED,
	'red'		=> $main::FG_LIGHTRED,
	'darkgreen'	=> $main::FG_GREEN,
	'green'		=> $main::FG_LIGHTGREEN,
	'brown'		=> $main::FG_BROWN,
	'yellow'	=> $main::FG_YELLOW,
	'darkblue'	=> $main::FG_BLUE,
	'blue'		=> $main::FG_LIGHTBLUE,
	'darkmagenta'	=> $main::FG_MAGENTA,
	'magenta'	=> $main::FG_LIGHTMAGENTA,
	'darkcyan'	=> $main::FG_CYAN,
	'cyan'		=> $main::FG_LIGHTCYAN,
	'gray'		=> $main::FG_GRAY,
	'grey'		=> $main::FG_GRAY,
	'white'		=> $main::FG_WHITE,
	);
} else {
	%fgcolors = (
	'reset'		=> $Win32::Console::ATTR_NORMAL,
	'default'	=> $Win32::Console::ATTR_NORMAL,
	'black'		=> $Win32::Console::FG_BLACK,
	'darkgray'	=> FOREGROUND_INTENSITY(),
	'darkgrey'	=> FOREGROUND_INTENSITY(),
	'darkred'	=> $Win32::Console::FG_RED,
	'red'		=> $Win32::Console::FG_LIGHTRED,
	'darkgreen'	=> $Win32::Console::FG_GREEN,
	'green'		=> $Win32::Console::FG_LIGHTGREEN,
	'brown'		=> $Win32::Console::FG_BROWN,
	'yellow'	=> $Win32::Console::FG_YELLOW,
	'darkblue'	=> $Win32::Console::FG_BLUE,
	'blue'		=> $Win32::Console::FG_LIGHTBLUE,
	'darkmagenta'	=> $Win32::Console::FG_MAGENTA,
	'magenta'	=> $Win32::Console::FG_LIGHTMAGENTA,
	'darkcyan'	=> $Win32::Console::FG_CYAN,
	'cyan'		=> $Win32::Console::FG_LIGHTCYAN,
	'gray'		=> $Win32::Console::FG_GRAY,
	'grey'		=> $Win32::Console::FG_GRAY,
	'white'		=> $Win32::Console::FG_WHITE,
	);
}

#   I  R  G  B
# 128 64 32 16
if (defined($main::BG_BLACK)) {
	%bgcolors = (
	''		=> $main::BG_BLACK,
	'default'	=> $main::BG_BLACK,
	'black'		=> $main::BG_BLACK,
	'darkgray'	=> BACKGROUND_INTENSITY(),
	'darkgrey'	=> BACKGROUND_INTENSITY(),
	'darkred'	=> $main::BG_RED,
	'red'		=> $main::BG_LIGHTRED,
	'darkgreen'	=> $main::BG_GREEN,
	'green'		=> $main::BG_LIGHTGREEN,
	'brown'		=> $main::BG_BROWN,
	'yellow'	=> $main::BG_YELLOW,
	'darkblue'	=> $main::BG_BLUE,
	'blue'		=> $main::BG_LIGHTBLUE,
	'darkmagenta'	=> $main::BG_MAGENTA,
	'magenta'	=> $main::BG_LIGHTMAGENTA,
	'darkcyan'	=> $main::BG_CYAN,
	'cyan'		=> $main::BG_LIGHTCYAN,
	'gray'		=> $main::BG_GRAY,
	'grey'		=> $main::BG_GRAY,
	'white'		=> $main::BG_WHITE,
	);
} else {
	%bgcolors = (
	''		=> $Win32::Console::BG_BLACK,
	'default'	=> $Win32::Console::BG_BLACK,
	'black'		=> $Win32::Console::BG_BLACK,
	'darkgray'	=> BACKGROUND_INTENSITY(),
	'darkgrey'	=> BACKGROUND_INTENSITY(),
	'darkred'	=> $Win32::Console::BG_RED,
	'red'		=> $Win32::Console::BG_LIGHTRED,
	'darkgreen'	=> $Win32::Console::BG_GREEN,
	'green'		=> $Win32::Console::BG_LIGHTGREEN,
	'brown'		=> $Win32::Console::BG_BROWN,
	'yellow'	=> $Win32::Console::BG_YELLOW,
	'darkblue'	=> $Win32::Console::BG_BLUE,
	'blue'		=> $Win32::Console::BG_LIGHTBLUE,
	'darkmagenta'	=> $Win32::Console::BG_MAGENTA,
	'magenta'	=> $Win32::Console::BG_LIGHTMAGENTA,
	'darkcyan'	=> $Win32::Console::BG_CYAN,
	'cyan'		=> $Win32::Console::BG_LIGHTCYAN,
	'gray'		=> $Win32::Console::BG_GRAY,
	'grey'		=> $Win32::Console::BG_GRAY,
	'white'		=> $Win32::Console::BG_WHITE,
	);
}


1 #end of module
