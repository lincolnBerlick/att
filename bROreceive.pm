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
	'092B', '094F',	'0917', '0953',	'089C', '0893',	'0920', '095B',	'091B', '0954',	'087B', '0944',	'086C', '0947',	'0968', '0943',	'088E', '0360',	'0892', '0899',	'0934', '0874',	'0956', '0897',	'08A5', '0891',	'0883', '0938',	'0884', '0202',	'093F', '083C',	'094D', '0882',	'0880', '087A',	'0436', '0928',	'085F', '0946',	'0962', '0871',	'092C', '0936',	'0864', '094B',	'0877', '0898',	'08A4', '0966',	'0364', '0894',	'0933', '092D',	'0969', '0887',	'0922', '092A',	'088C', '0873',	'08A0', '08A7',	'0865', '08A9',	'0959', '0964',	'0927', '0958',	'0937', '08A3',	'08A8', '0866',	'0930', '0838',	'0926', '0367',	'087C', '087F',	'07E4', '07EC',	'088B', '0890',	'0881', '093B',	'086B', '0945',	'0811', '088A',	'0931', '0924',	'0921', '035F',	'095F', '096A',	'0940', '0919',	'08AD', '0895',	'0870', '0875',	'0885', '085C',	'089E', '086D',	'0876', '08A6',	'0932', '022D',	'0963', '0363',	'0437', '0961',	'091C', '095E',	'0951', '0952',	'086F', '0965',	'094C', '0939',	'0923', '089F',	'0281', '089D',	'0929', '0815',	'08A1', '0872',	'085A', '091E',	'02C4', '086E',	'093A', '0868',	'0867', '089A',	'0860', '0948',	'0869', '0366',	'023B', '0863',	'08A2', '0879',	'091A', '0950',	'08AB', '085B',	'091F', '0878',	'0817', '08AC',	'0361', '087D',	'0888', '092F',	'089B', '0369',	'086A', '093D',	'0889', '085D',	'0925', '094A',	'092E', '0918',	'091D', '0935',
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
