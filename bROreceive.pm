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
	'088D', '085A',	'094D', '0958',	'089C', '0891',	'0364', '0802',	'0935', '089F',	'0860', '0946',	'0929', '0437',	'089D', '087B',	'093F', '0965',	'095E', '0942',	'092B', '0955',	'0959', '091F',	'0945', '0924',	'0951', '0952',	'0885', '08A6',	'0896', '093E',	'08A8', '08A4',	'08A9', '0967',	'091B', '086F',	'0881', '0876',	'087C', '087A',	'0949', '092A',	'0964', '0888',	'0866', '0874',	'0960', '08A2',	'0889', '087E',	'087F', '0878',	'0926', '0815',	'0879', '0281',	'091A', '0892',	'0943', '088C',	'0863', '0811',	'089E', '0938',	'0835', '0931',	'0867', '0950',	'0925', '07EC',	'0969', '0877',	'092D', '08AD',	'093B', '08AB',	'07E4', '0884',	'0368', '0939',	'0920', '0202',	'0887', '0869',	'08A3', '0365',	'023B', '091D',	'094A', '0961',	'0872', '0895',	'0366', '086D',	'088E', '0436',	'085D', '0957',	'0968', '083C',	'0369', '08AA',	'094B', '0941',	'0897', '0890',	'0934', '0930',	'0947', '086E',	'095F', '085B',	'0873', '093D',	'095A', '0953',	'0954', '086C',	'0865', '08A0',	'0882', '094E',	'092F', '0917',	'0928', '085C',	'0438', '0940',	'0966', '089B',	'0367', '0962',	'02C4', '022D',	'08AC', '095B',	'08A1', '0819',	'088B', '088A',	'0921', '035F',	'0919', '0918',	'0862', '088F',	'0927', '091E',	'086A', '089A',	'0963', '094F',	'0870', '0875',	'0944', '0922',	'0893', '0948',	'0880', '0883',	'0923', '0360',	'094C', '0864',	'085E', '087D',
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
