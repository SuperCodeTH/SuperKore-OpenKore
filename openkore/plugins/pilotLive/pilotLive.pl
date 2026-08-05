#############################################################################
# pilotLive - emit current coords while walking so SuperKore Live can track
#             the character marker (OpenKore only prints coords on map enter).
#             Also emits compact HP/SP/Base/Job/Zeny and AI status/target for
#             Live meta (filtered from Pilot Log tab display).
#############################################################################
package OpenKore::Plugins::pilotLive;

use strict;
use Plugins;
use Globals qw( $char $field $net %monsters );
use Network;
use Utils qw( calcPosition timeOut );
use Log qw( message );
use Translation qw( TF );
use AI;

Plugins::register( 'pilotLive', 'coords + status for SuperKore Live', \&onUnload );

my $hooks = Plugins::addHooks(
	[ 'mainLoop_pre' => \&onMainLoop ],
);

my $timeout = { time => 0, timeout => 1 };
my ( $lastX, $lastY );
my ( $lastHp, $lastHpMax, $lastSp, $lastSpMax, $lastBase, $lastJob, $lastZeny );
my ( $lastAiStatus, $lastAiTarget );

sub onUnload {
	Plugins::delHooks($hooks);
}

sub onMainLoop {
	return unless $net && $net->getState() == Network::IN_GAME;
	return unless $char && $field;
	return unless timeOut($timeout);
	$timeout->{time} = time;

	my $pos = calcPosition($char);
	if ( defined $pos->{x} && defined $pos->{y} ) {
		# Only log when the cell changes — quiet while standing, updates while walking.
		if ( !defined $lastX || $lastX != $pos->{x} || !defined $lastY || $lastY != $pos->{y} ) {
			$lastX = $pos->{x};
			$lastY = $pos->{y};
			# Same msgid as Network::Receive map-enter (th.po → พิกัดของคุณคือ) so Live parse works.
			message TF( "Your Coordinates: %s, %s\n", $pos->{x}, $pos->{y} ), 'info', 1;
		}
	}

	emitStatusIfChanged();
	emitAiIfChanged();
}

sub emitStatusIfChanged {
	return unless defined $char->{hp} && defined $char->{hp_max};
	return unless defined $char->{sp} && defined $char->{sp_max};
	return unless defined $char->{lv} && defined $char->{lv_job};
	return unless defined $char->{zeny};

	my $hp     = int( $char->{hp} );
	my $hpMax  = int( $char->{hp_max} );
	my $sp     = int( $char->{sp} );
	my $spMax  = int( $char->{sp_max} );
	my $base   = int( $char->{lv} );
	my $job    = int( $char->{lv_job} );
	my $zeny   = int( $char->{zeny} );

	if (
		defined $lastHp
		&& $lastHp == $hp
		&& $lastHpMax == $hpMax
		&& $lastSp == $sp
		&& $lastSpMax == $spMax
		&& $lastBase == $base
		&& $lastJob == $job
		&& $lastZeny == $zeny
	) {
		return;
	}

	$lastHp    = $hp;
	$lastHpMax = $hpMax;
	$lastSp    = $sp;
	$lastSpMax = $spMax;
	$lastBase  = $base;
	$lastJob   = $job;
	$lastZeny  = $zeny;

	# Compact English line for SuperKore Live parse (hidden from Pilot Log tab).
	message sprintf(
		"PilotStatus: HP %d/%d SP %d/%d Base %d Job %d Zeny %d\n",
		$hp, $hpMax, $sp, $spMax, $base, $job, $zeny
	), 'info', 1;
}

sub resolveAttackTargetName {
	my $idx = AI::findAction('attack');
	return '' unless defined $idx;
	my $args = AI::args($idx);
	return '' unless $args && ref($args) eq 'HASH';
	my $ID = $args->{ID};
	return '' unless defined $ID;
	if ( exists $monsters{$ID} && $monsters{$ID}{name} ) {
		return $monsters{$ID}{name};
	}
	return '';
}

sub currentAiState {
	# Attack in queue (including approach route) → attacking + target.
	if ( AI::inQueue('attack') ) {
		return ( 'attacking', resolveAttackTargetName() );
	}
	# Active movement without attack target.
	if ( AI::is( 'route', 'mapRoute', 'move' ) || AI::inQueue('route') || AI::inQueue('mapRoute') || AI::inQueue('move') ) {
		return ( 'moving', '' );
	}
	return ( 'idle', '' );
}

sub emitAiIfChanged {
	my ( $status, $target );
	eval {
		( $status, $target ) = currentAiState();
		1;
	} or do {
		my $err = $@ || 'unknown';
		$err =~ s/\s+/ /g;
		message "PilotAI: idle\n", 'info', 1;
		message "PilotAI-error: $err\n", 'info', 1;
		$lastAiStatus = 'idle';
		$lastAiTarget = '';
		return;
	};

	$status = 'idle' unless defined $status && $status ne '';
	$target = '' unless defined $target;

	if (
		defined $lastAiStatus
		&& $lastAiStatus eq $status
		&& ( defined $lastAiTarget ? $lastAiTarget : '' ) eq $target
	) {
		return;
	}

	$lastAiStatus = $status;
	$lastAiTarget = $target;

	# Compact line for SuperKore Live parse (hidden from Pilot Log tab).
	# Avoid sprintf with target names (may contain %).
	if ( $status eq 'attacking' && $target ne '' ) {
		message "PilotAI: attacking $target\n", 'info', 1;
	} else {
		message "PilotAI: $status\n", 'info', 1;
	}
}

1;
