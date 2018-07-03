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
	'091C', '0880',	'091D', '0883',	'08AC', '0361',	'0882', '088F',	'091A', '0365',	'0438', '0891',	'0939', '0872',	'0958', '0963',	'0898', '0943',	'035F', '094D',	'0929', '0861',	'0960', '094F',	'0923', '092A',	'0899', '0892',	'095D', '0865',	'085F', '088A',	'089B', '094C',	'0955', '0870',	'0876', '086A',	'087A', '0879',	'0867', '023B',	'0934', '092F',	'0864', '092E',	'0933', '088E',	'0889', '0868',	'0885', '0948',	'08AA', '08A4',	'0956', '093F',	'0860', '0952',	'0811', '093E',	'0890', '0950',	'095B', '096A',	'0968', '092B',	'0932', '0871',	'0817', '08A6',	'0866', '086B',	'085D', '0362',	'089D', '091F',	'0953', '0887',	'094E', '0964',	'086E', '07E4',	'0921', '0951',	'095A', '095C',	'086C', '0947',	'085C', '0838',	'0202', '0919',	'0884', '0945',	'0878', '088B',	'0869', '089A',	'088C', '0962',	'0368', '095F',	'0935', '085E',	'089E', '094B',	'0949', '089C',	'087D', '0930',	'0369', '089F',	'08AB', '0966',	'093C', '08AD',	'0819', '093A',	'095E', '0897',	'022D', '0364',	'02C4', '0363',	'0942', '093D',	'0917', '0874',	'0281', '0896',	'093B', '0940',	'0926', '0967',	'0965', '094A',	'0957', '0886',	'08A7', '0944',	'08A0', '0941',	'0802', '08A8',	'0938', '0928',	'0961', '0360',	'0366', '0873',	'092D', '0895',	'085B', '087F',	'0815', '08A9',	'0931', '087B',	'091B', '088D',	'0922', '083C',	'086F', '0918',	'0863', '0925',	'087C', '0835',
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
