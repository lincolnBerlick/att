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
	'088D', '093E',	'0815', '087B',	'092A', '08A2',	'086F', '0861',	'0898', '08A7',	'0940', '08A4',	'023B', '091F',	'0897', '0925',	'0838', '0929',	'086B', '0957',	'0369', '0871',	'0943', '091D',	'0866', '0956',	'086C', '0967',	'094F', '0863',	'0872', '092D',	'0868', '0947',	'093D', '094C',	'093A', '0882',	'0895', '085D',	'08AD', '0961',	'089F', '086E',	'0919', '0202',	'0937', '0436',	'095E', '0924',	'088A', '0879',	'087D', '08A0',	'022D', '08A3',	'095C', '0876',	'0942', '093F',	'094D', '089E',	'0950', '0962',	'0888', '094B',	'0933', '088B',	'091B', '0864',	'0935', '0965',	'08A9', '0362',	'0862', '085E',	'088E', '08A6',	'0437', '02C4',	'0953', '0869',	'0889', '091E',	'092C', '092B',	'0281', '0936',	'0819', '035F',	'091C', '0368',	'088F', '095F',	'0893', '092F',	'0958', '0835',	'0948', '0952',	'08AA', '088C',	'0366', '095B',	'0896', '08A5',	'093C', '094E',	'0363', '0945',	'0954', '0438',	'0946', '095D',	'0894', '0917',	'0870', '0874',	'0921', '07E4',	'0892', '0877',	'093B', '0365',	'0367', '0881',	'0966', '083C',	'0934', '089C',	'0959', '0932',	'0873', '0964',	'07EC', '087F',	'0883', '0931',	'0955', '0885',	'0884', '0944',	'087E', '0920',	'0951', '0939',	'0938', '085B',	'08A1', '092E',	'087A', '0918',	'0926', '085F',	'0941', '096A',	'0890', '086D',	'08AC', '0360',	'0878', '085A',	'087C', '085C',	'091A', '0811',	'089D', '0960',
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
