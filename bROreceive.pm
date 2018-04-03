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
	'0436', '089C',	'0920', '091D',	'092E', '0959',	'091F', '0815',	'0866', '087C',	'0965', '096A',	'094B', '087D',	'0891', '0955',	'0363', '0860',	'0364', '08A1',	'092A', '0898',	'089E', '0945',	'0877', '0899',	'095E', '08A3',	'02C4', '088A',	'0811', '086C',	'085F', '0892',	'0890', '0895',	'089A', '07E4',	'085A', '085D',	'095F', '0886',	'0368', '0961',	'0933', '0934',	'08A4', '0865',	'0863', '0956',	'086E', '0938',	'0969', '0947',	'07EC', '089F',	'0951', '0928',	'0884', '0861',	'0936', '087E',	'092D', '08A6',	'0887', '093E',	'0819', '0867',	'0923', '08AC',	'091E', '0940',	'095A', '086D',	'0960', '022D',	'085C', '0922',	'092F', '089B',	'0894', '08AA',	'0942', '094A',	'0366', '085E',	'087A', '0930',	'0802', '088B',	'0926', '0950',	'087B', '035F',	'0953', '0281',	'08A7', '0835',	'0862', '0838',	'0937', '0958',	'0893', '08A5',	'093A', '091B',	'0896', '0817',	'0897', '086F',	'0954', '0949',	'0369', '0885',	'088C', '0362',	'093C', '0875',	'08A8', '0882',	'0948', '0878',	'0935', '0925',	'094F', '0917',	'086A', '092C',	'023B', '08AB',	'092B', '0879',	'0944', '0932',	'0939', '0438',	'091A', '0360',	'0919', '0957',	'0943', '08AD',	'0968', '0880',	'087F', '0872',	'094D', '0871',	'0946', '08A2',	'0966', '086B',	'0869', '0964',	'094C', '0870',	'0437', '0931',	'088D', '093D',	'0888', '0881',	'0963', '0874',	'094E', '0365',	'0967', '093F',
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
