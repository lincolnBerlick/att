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
	'0920', '0930',	'095F', '092B',	'091E', '0943',	'086A', '089A',	'0835', '0870',	'0927', '0951',	'086C', '0934',	'0963', '094F',	'087A', '08AC',	'088F', '0876',	'0926', '0959',	'02C4', '0888',	'0924', '022D',	'089C', '0932',	'0952', '0956',	'0890', '088D',	'087D', '0961',	'086D', '0361',	'087C', '0864',	'08A0', '0933',	'088A', '08AA',	'0894', '089E',	'0919', '0879',	'0437', '0815',	'0957', '088E',	'0866', '0936',	'0899', '08A3',	'089B', '0363',	'0950', '094E',	'091B', '0865',	'0360', '0885',	'035F', '0872',	'08A8', '0897',	'0969', '0877',	'0921', '095B',	'0874', '08A9',	'0202', '08A5',	'0867', '0892',	'0884', '0281',	'08AD', '0369',	'0931', '091F',	'0878', '0882',	'0819', '0366',	'086F', '0962',	'08A2', '0367',	'0802', '08A1',	'0918', '023B',	'0861', '08A4',	'0944', '0958',	'0935', '091A',	'0860', '0873',	'0945', '0365',	'094D', '093C',	'085A', '087F',	'0964', '0889',	'0965', '0811',	'0438', '0938',	'0928', '0967',	'095C', '0917',	'092D', '0362',	'089F', '086E',	'091C', '096A',	'094B', '0948',	'08A7', '0923',	'0891', '0869',	'0868', '0875',	'083C', '087B',	'0364', '0898',	'0929', '095D',	'086B', '0937',	'094C', '092C',	'07EC', '0863',	'093F', '0880',	'092F', '0893',	'093B', '093D',	'095A', '0871',	'089D', '0942',	'0941', '092E',	'0925', '0966',	'0949', '0954',	'0881', '0940',	'0886', '085F',	'091D', '085D',	'093E', '0862',
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
