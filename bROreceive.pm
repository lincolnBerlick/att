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
	'0966', '0360',	'088B', '0838',	'086A', '095D',	'089F', '095F',	'0897', '0941',	'086D', '0954',	'0959', '0936',	'0958', '08AB',	'08AC', '0365',	'0922', '0955',	'0953', '08AA',	'091B', '0875',	'092B', '08A4',	'0862', '087D',	'093A', '088F',	'0965', '0868',	'0923', '0874',	'0878', '083C',	'0944', '094C',	'0817', '094E',	'086E', '0879',	'08A0', '0881',	'0920', '0871',	'0926', '0898',	'095A', '0436',	'094D', '094F',	'0815', '08A7',	'0863', '0940',	'0811', '0956',	'092D', '085F',	'08A3', '0887',	'0939', '08A9',	'091F', '0933',	'093E', '0438',	'093B', '0952',	'095C', '0877',	'095E', '0931',	'0925', '0949',	'035F', '091C',	'0892', '088E',	'085C', '0364',	'0867', '0896',	'0921', '0918',	'089A', '0870',	'089C', '085A',	'0367', '08A5',	'093D', '0864',	'0888', '0938',	'092E', '094A',	'093F', '0860',	'085D', '0368',	'0962', '07E4',	'0957', '0948',	'086C', '0876',	'0929', '0951',	'0883', '087F',	'08A1', '0919',	'089D', '095B',	'0882', '0963',	'0964', '0872',	'023B', '0899',	'0895', '0968',	'0281', '085E',	'091E', '0880',	'093C', '0819',	'02C4', '092F',	'0928', '0362',	'086F', '0969',	'0932', '0363',	'0369', '0967',	'0361', '0802',	'0917', '0866',	'0869', '0835',	'0893', '0884',	'0930', '088A',	'087E', '0960',	'0935', '0890',	'0202', '087C',	'0942', '0366',	'0950', '022D',	'086B', '0885',	'092C', '091A',	'087A', '0889',	'08AD', '087B',
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
