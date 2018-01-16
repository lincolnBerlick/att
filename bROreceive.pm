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
	'0892', '0868',	'087F', '094B',	'0930', '0363',	'0927', '085A',	'0951', '091C',	'0952', '0959',	'089F', '087E',	'086F', '0964',	'091F', '0943',	'0960', '0957',	'094C', '093E',	'0874', '08A9',	'022D', '0969',	'0929', '08A1',	'095E', '0876',	'0863', '08A2',	'0926', '0956',	'085F', '092B',	'0860', '0967',	'091A', '0894',	'0935', '02C4',	'088D', '085C',	'092C', '0281',	'088E', '092F',	'094D', '095C',	'092E', '08AC',	'089E', '0962',	'0946', '0945',	'0917', '08A6',	'0942', '0933',	'0883', '086B',	'0922', '0815',	'0881', '095D',	'0936', '089A',	'088A', '094F',	'093F', '089D',	'0884', '0878',	'0899', '0939',	'0897', '0871',	'089B', '095F',	'0867', '085B',	'088B', '0918',	'0873', '0369',	'0890', '0887',	'0366', '0963',	'0965', '0202',	'0838', '0865',	'0361', '087C',	'0949', '086A',	'0819', '095A',	'08AB', '0966',	'0364', '092A',	'0436', '0948',	'0931', '0950',	'096A', '0953',	'091E', '085E',	'0802', '0961',	'0934', '0817',	'023B', '091D',	'0880', '086C',	'0864', '035F',	'0958', '08A5',	'0938', '095B',	'0895', '087A',	'0875', '0437',	'08A4', '093C',	'0932', '083C',	'0870', '08A8',	'0889', '0362',	'0954', '0928',	'086D', '0947',	'0898', '087D',	'0937', '0862',	'0893', '087B',	'0365', '0882',	'0888', '0360',	'08AD', '08A0',	'0896', '0367',	'0968', '086E',	'088C', '091B',	'0879', '0877',	'093B', '0941',	'0885', '0925',	'085D', '088F',
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
