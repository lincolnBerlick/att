#############################################################################
#  OpenKore - Network subsystem												#
#  This module contains functions for sending messages to the server.		#
#																			#
#  This software is open source, licensed under the GNU General Public		#
#  License, version 2.														#
#  Basically, this means that you're allowed to modify and distribute		#
#  this software. However, if you distribute modified versions, you MUST	#
#  also distribute the source code.											#
#  See http://www.gnu.org/licenses/gpl.html for the full license.			#
#############################################################################
# bRO (Brazil)
package Network::Receive::bRO;
use strict;
use Log qw(warning debug);
use base 'Network::Receive::ServerType0';
use Globals qw(%charSvrSet $messageSender $monstersList);
use Translation qw(TF);

# Sync_Ex algorithm developed by Fr3DBr
sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	
	my %packets = (
		'0097' => ['private_message', 'v Z24 V Z*', [qw(len privMsgUser flag privMsg)]], # -1
		'0A36' => ['monster_hp_info_tiny', 'a4 C', [qw(ID hp)]],
		'09CB' => ['skill_used_no_damage', 'v v x2 a4 a4 C', [qw(skillID amount targetID sourceID success)]],
	);
	# Sync Ex Reply Array 
	$self->{sync_ex_reply} = {
	'093B', '0895',	'0947', '0873',	'091D', '0948',	'0945', '089B',	'0891', '0892',	'08A6', '0942',	'0958', '0930',	'087F', '088D',	'0866', '0861',	'0869', '0802',	'0944', '0875',	'085C', '08A5',	'0963', '085F',	'092C', '0893',	'0882', '0959',	'094A', '0896',	'083C', '088F',	'0954', '0921',	'08A7', '0872',	'094C', '0918',	'0925', '086B',	'089D', '02C4',	'0838', '094D',	'087B', '0870',	'087A', '0438',	'089E', '08A1',	'0883', '0898',	'08A2', '0871',	'0369', '0952',	'085D', '035F',	'088B', '095A',	'0950', '0890',	'0885', '0887',	'0879', '0922',	'0927', '0360',	'0962', '0366',	'0932', '0436',	'0437', '095B',	'092A', '08A4',	'0929', '07E4',	'096A', '0862',	'07EC', '0937',	'091A', '0969',	'089F', '0955',	'0926', '0949',	'092B', '086A',	'0868', '0934',	'0886', '095E',	'0281', '0863',	'0367', '0919',	'093D', '0946',	'0365', '095D',	'0968', '0364',	'0368', '0923',	'022D', '092E',	'086C', '08A8',	'0363', '092D',	'091B', '0874',	'0956', '092F',	'0964', '0967',	'08A0', '0878',	'0362', '0899',	'093A', '0864',	'0897', '0951',	'0940', '0935',	'0965', '0819',	'091C', '0931',	'0957', '08AC',	'093C', '087E',	'0928', '08AA',	'0938', '0961',	'093E', '08AB',	'088A', '0920',	'08A9', '0966',	'086D', '0865',	'088E', '0933',	'0960', '0888',	'0884', '091F',	'0936', '089A',	'087C', '0877',	'085A', '0953',	'094E', '0815',	'023B', '094B',	'085E', '086E',
	};
		
	foreach my $key (keys %{$self->{sync_ex_reply}}) { $packets{$key} = ['sync_request_ex']; }
	foreach my $switch (keys %packets) { $self->{packet_list}{$switch} = $packets{$switch}; }
	
	my %handlers = qw(
		received_characters 099D
		received_characters_info 082D
		sync_received_characters 09A0
	);

	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;
	
	return $self;
}
	
sub sync_received_characters {
	my ($self, $args) = @_;

	$charSvrSet{sync_Count} = $args->{sync_Count} if (exists $args->{sync_Count});
	
	# When XKore 2 client is already connected and Kore gets disconnected, send sync_received_characters anyway.
	# In most servers, this should happen unless the client is alive
	# This behavior was observed in April 12th 2017, when Odin and Asgard were merged into Valhalla
	for (1..$args->{sync_Count}) {
		$messageSender->sendToServer($messageSender->reconstruct({switch => 'sync_received_characters'}));
	}
}

# 0A36
sub monster_hp_info_tiny {
	my ($self, $args) = @_;
	my $monster = $monstersList->getByID($args->{ID});
	if ($monster) {
		$monster->{hp} = $args->{hp};
		
		debug TF("Monster %s has about %d%% hp left
", $monster->name, $monster->{hp} * 4), "parseMsg_damage"; # FIXME: Probably inaccurate
	}
}

*parse_quest_update_mission_hunt = *Network::Receive::ServerType0::parse_quest_update_mission_hunt_v2;
*reconstruct_quest_update_mission_hunt = *Network::Receive::ServerType0::reconstruct_quest_update_mission_hunt_v2;

1;
