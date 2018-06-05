es (64 sloc)  4.1 KB
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
	'0878', '0933',	'095B', '0862',	'08A5', '0968',	'0895', '08AC',	'0924', '0863',	'0939', '0364',	'0961', '0944',	'0948', '0917',	'094E', '08AA',	'091C', '0960',	'0959', '0938',	'0367', '0436',	'0369', '085A',	'0877', '0932',	'0437', '089F',	'0929', '089A',	'0882', '0958',	'0969', '023B',	'087A', '094A',	'086A', '094B',	'08A8', '0954',	'091E', '0889',	'0945', '0941',	'08A9', '0883',	'0925', '085D',	'094F', '08A6',	'088A', '08A3',	'0890', '0950',	'0893', '091A',	'089D', '0835',	'0940', '091D',	'089E', '0930',	'0867', '0965',	'0927', '087E',	'093D', '0921',	'0896', '0876',	'0951', '087B',	'0861', '086D',	'08A0', '091F',	'08A7', '0873',	'0365', '088D',	'092E', '07E4',	'095C', '0870',	'0923', '0869',	'0899', '0957',	'092A', '086E',	'087F', '0942',	'0879', '0928',	'088E', '086C',	'0880', '095F',	'08AD', '0368',	'092F', '0860',	'0871', '095A',	'0886', '091B',	'092D', '092C',	'093E', '0943',	'0919', '0918',	'086B', '0946',	'0955', '095D',	'0438', '0281',	'093F', '0868',	'092B', '095E',	'0887', '094C',	'0360', '0865',	'08AB', '0947',	'0952', '0866',	'085F', '087C',	'0898', '0819',	'0891', '083C',	'07EC', '085B',	'0366', '0838',	'0926', '0815',	'0922', '0949',	'094D', '0362',	'022D', '086F',	'0892', '093A',	'089B', '0363',	'0956', '0894',	'02C4', '085E',	'0885', '08A4',	'0864', '093C',	'0931', '0963',	'0935', '096A',	'085C', '0884',
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
