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
	'0875', '08A1',	'0962', '093D',	'0367', '086E',	'085D', '088F',	'0872', '096A',	'0360', '091B',	'086B', '0918',	'0864', '093B',	'08A0', '0942',	'0924', '0939',	'0966', '087B',	'087C', '0893',	'086C', '08A9',	'0874', '0884',	'0926', '0868',	'089B', '0945',	'07EC', '0892',	'08A7', '08A5',	'0923', '0863',	'0920', '0956',	'0436', '0873',	'0888', '0921',	'0937', '0922',	'0883', '094D',	'0952', '091F',	'0898', '0365',	'0880', '094C',	'092B', '0889',	'0963', '089C',	'08A6', '0948',	'0943', '0891',	'095E', '0881',	'0941', '08AD',	'092F', '0879',	'087A', '0947',	'0899', '0938',	'089F', '0957',	'091A', '023B',	'0944', '0953',	'08A2', '0935',	'0882', '0927',	'088A', '0363',	'0865', '0936',	'089E', '0961',	'07E4', '0929',	'0968', '0960',	'0967', '095C',	'087D', '0894',	'0802', '0958',	'0896', '0878',	'0362', '0819',	'0928', '086F',	'089A', '094E',	'0931', '0861',	'095B', '094A',	'092D', '085F',	'0969', '0925',	'095A', '0368',	'0890', '0869',	'0871', '0917',	'0951', '093E',	'08AC', '088D',	'087E', '0366',	'0877', '022D',	'0930', '0817',	'091D', '0933',	'095D', '092A',	'0940', '0946',	'0965', '0361',	'0811', '0949',	'0281', '0955',	'083C', '0932',	'085A', '0838',	'0870', '092C',	'093A', '094F',	'091E', '0866',	'089D', '08AA',	'086D', '095F',	'0364', '08A4',	'0835', '0867',	'0815', '0202',	'087F', '0437',	'0885', '085E',	'0919', '0876',
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
