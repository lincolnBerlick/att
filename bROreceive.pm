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
	'0943', '087B',	'0885', '0944',	'093D', '08A9',	'0934', '0947',	'0887', '0871',	'0869', '086D',	'086B', '089D',	'0918', '0815',	'08A3', '0867',	'0931', '093C',	'0950', '0862',	'0281', '0891',	'0941', '0897',	'0932', '0952',	'0967', '085E',	'094C', '0895',	'0873', '0202',	'0949', '095B',	'0890', '0835',	'0893', '0819',	'08A7', '094A',	'0365', '0956',	'08AB', '0955',	'088E', '095A',	'091A', '0936',	'0879', '0962',	'0874', '091B',	'088B', '0368',	'0968', '096A',	'0917', '08AD',	'0811', '0964',	'0969', '08A1',	'0939', '0875',	'0872', '095D',	'07EC', '0961',	'0958', '092B',	'0437', '095F',	'092A', '087A',	'0866', '0884',	'092C', '0882',	'0965', '0361',	'022D', '0438',	'093F', '07E4',	'08AA', '086A',	'0860', '0942',	'0922', '0899',	'089F', '0886',	'088A', '085F',	'093E', '08A0',	'0940', '095E',	'0960', '0920',	'0937', '02C4',	'0951', '023B',	'085C', '0954',	'087D', '0963',	'086E', '0935',	'0888', '085D',	'08A8', '0366',	'089A', '091E',	'08A6', '0957',	'087C', '085B',	'091C', '0959',	'093B', '094E',	'0933', '0864',	'093A', '0883',	'0930', '088F',	'094D', '0877',	'0938', '08A4',	'0878', '0364',	'092D', '0865',	'0880', '0881',	'0948', '0966',	'088C', '0363',	'0369', '0894',	'086C', '091D',	'0898', '0924',	'087E', '089C',	'0921', '0870',	'0925', '0817',	'083C', '035F',	'089E', '0929',	'0953', '085A',	'0896', '0923',	'0946', '0919',
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
