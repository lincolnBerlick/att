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
	'0893', '0862',	'086E', '0869',	'0956', '0202',	'0924', '088B',	'089D', '023B',	'08A4', '0369',	'0895', '0898',	'0889', '022D',	'0957', '08AC',	'0817', '087C',	'089E', '08A6',	'0968', '0897',	'088F', '0955',	'0868', '0946',	'0876', '08A9',	'0951', '0923',	'094C', '091C',	'088A', '0894',	'086D', '089B',	'092B', '0896',	'093E', '096A',	'0931', '093F',	'092E', '095D',	'0954', '0947',	'085E', '0891',	'08A5', '091D',	'0367', '085D',	'0881', '0939',	'08A1', '08A8',	'0877', '0964',	'094F', '088C',	'091A', '0861',	'0918', '095A',	'0937', '093B',	'0281', '086B',	'0917', '086F',	'092D', '0870',	'08AD', '087A',	'0883', '089F',	'0838', '08AB',	'0899', '0943',	'0890', '08A7',	'0364', '0950',	'0942', '0886',	'0811', '0953',	'0926', '0928',	'0929', '0867',	'0871', '095B',	'0815', '0882',	'092F', '0363',	'085A', '087D',	'0922', '086A',	'0863', '093A',	'08A2', '085C',	'08A3', '0969',	'0949', '093C',	'087B', '0936',	'085F', '0952',	'0892', '0887',	'092A', '07E4',	'0941', '0865',	'0935', '0879',	'0962', '0366',	'095E', '0934',	'0864', '0961',	'093D', '092C',	'0933', '0965',	'089A', '0860',	'0967', '0920',	'088D', '0885',	'083C', '0966',	'0925', '0927',	'0362', '094A',	'0932', '0802',	'0959', '07EC',	'0884', '0945',	'089C', '0958',	'094B', '0919',	'0872', '0436',	'0835', '091B',	'08AA', '091F',	'091E', '0866',	'08A0', '02C4',	'086C', '0368',
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
