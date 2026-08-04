#############################################################################
# wsbridge - route OpenKore server connections through SuperKore connector
#            (local TCP → gateway WSS → RoPlay).
#############################################################################
package OpenKore::Plugins::wsbridge;

use strict;
use IO::Socket::INET;
use Globals qw( %config $net $incomingMessages );
use Log qw( message warning error );
use Plugins;
use Network;

Plugins::register( 'wsbridge', 'route RO connection through SuperKore connector', \&onUnload );

my $hooks = Plugins::addHooks(
	[ 'Network::connectTo' => \&onConnectTo ],
);

sub onUnload {
	Plugins::delHooks($hooks);
}

sub onConnectTo {
	my ( undef, $args ) = @_;

	return unless $config{wsBridge};

	my $host  = $args->{host};
	my $port  = $args->{port};
	my $bhost = $config{wsBridge_host} || '127.0.0.1';
	my $bport = $config{wsBridge_port} || 9900;

	message "[wsbridge] routing $host:$port through connector $bhost:$bport\n", "connection";

	my $sock = new IO::Socket::INET(
		PeerAddr => $bhost,
		PeerPort => $bport,
		Proto    => 'tcp',
		Timeout  => 5,
	);

	if ( !$sock || !$sock->connected ) {
		error "[wsbridge] cannot reach connector at $bhost:$bport — is SuperKore connector running?\n", "connection";
		return;
	}

	$sock->autoflush(1);
	my $proxy = $config{wsBridge_proxy};
	$sock->send( $proxy ? "$host:$port $proxy\n" : "$host:$port\n" );

	${ $args->{socket} } = $sock;
	${ $args->{return} } = 1;

	if ( $net && $net->getState() != Network::NOT_CONNECTED ) {
		$incomingMessages->nextMessageMightBeAccountID() if $incomingMessages;
	}

	message "[wsbridge] connected via SuperKore tunnel\n", "connection";
}

1;
