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
	'0873', '0964',	'0879', '094A',	'0861', '0942',	'0934', '0930',	'0281', '0867',	'08AD', '0885',	'0878', '085C',	'0875', '088E',	'0870', '0438',	'0368', '0888',	'0362', '095A',	'0864', '0954',	'02C4', '08A3',	'088F', '0802',	'092D', '0953',	'096A', '086B',	'0202', '0950',	'0962', '0897',	'0893', '0890',	'0361', '0898',	'091A', '0957',	'093D', '0943',	'0920', '088A',	'094D', '0941',	'0872', '095E',	'0877', '0887',	'07EC', '086C',	'08A7', '094B',	'0944', '0881',	'0869', '0947',	'092F', '08AB',	'023B', '087C',	'088C', '086E',	'0936', '0918',	'093B', '0364',	'085B', '0899',	'089F', '087D',	'0937', '0895',	'0935', '089B',	'087F', '0880',	'0883', '087B',	'0868', '08AA',	'086F', '0967',	'087A', '0366',	'0838', '091F',	'0896', '092C',	'0966', '088D',	'095C', '093F',	'0811', '087E',	'0959', '091C',	'0884', '08A8',	'0360', '08A1',	'0926', '093A',	'086D', '0874',	'0968', '0963',	'0925', '0958',	'088B', '0886',	'095D', '035F',	'0929', '085F',	'092A', '092B',	'0938', '0817',	'08A0', '094F',	'08A2', '0949',	'0960', '0437',	'0919', '091B',	'0363', '08A5',	'0932', '083C',	'093C', '085A',	'0367', '0865',	'091D', '08A9',	'0892', '095F',	'08A6', '095B',	'0866', '0921',	'0948', '089D',	'089A', '0819',	'089E', '093E',	'0365', '0924',	'0894', '0951',	'0369', '091E',	'0939', '0945',	'0835', '08AC',	'0927', '0862',	'0928', '0956',	'086A', '0860',
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
