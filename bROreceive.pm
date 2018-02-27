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
	'035F', '0887',	'083C', '08A1',	'0363', '091C',	'0369', '08A0',	'0924', '08A8',	'0868', '0918',	'0866', '0437',	'0863', '0368',	'0888', '0362',	'0885', '0940',	'0891', '0438',	'0882', '0365',	'093A', '08AB',	'086A', '091E',	'0939', '0967',	'0436', '0861',	'092B', '08AC',	'08A9', '092D',	'0919', '0968',	'0950', '0890',	'0955', '0942',	'093D', '0962',	'0897', '094E',	'085F', '0899',	'0883', '0952',	'0876', '0937',	'095C', '08A6',	'092F', '0944',	'092C', '0964',	'0895', '07E4',	'02C4', '0948',	'0941', '0873',	'087E', '022D',	'0892', '0920',	'087B', '0917',	'085B', '0889',	'0935', '0925',	'088C', '0884',	'0930', '0945',	'0959', '095F',	'0817', '095D',	'08A7', '086B',	'087C', '0954',	'0928', '0879',	'0929', '08A2',	'094B', '0862',	'0969', '089E',	'0961', '0867',	'0958', '023B',	'08AA', '088F',	'0815', '094A',	'093C', '0963',	'0956', '0921',	'085D', '086F',	'0877', '0802',	'0886', '0896',	'091D', '0202',	'08A5', '0960',	'0819', '0875',	'0949', '095E',	'094C', '087F',	'092A', '0872',	'0926', '086C',	'0934', '092E',	'0835', '088D',	'0933', '0966',	'093F', '0898',	'0938', '089C',	'0931', '0943',	'0957', '0951',	'08A4', '086E',	'095A', '093B',	'0881', '089B',	'0922', '087D',	'093E', '0880',	'091F', '095B',	'0366', '0874',	'0923', '0838',	'0860', '089D',	'0965', '086D',	'0878', '08AD',	'0364', '0927',	'085E', '094D',	'0864', '0811',
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
