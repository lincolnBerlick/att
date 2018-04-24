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
	'0958', '0952',	'0893', '0886',	'0964', '087C',	'085F', '0878',	'086D', '0364',	'0945', '095D',	'0919', '08AB',	'0917', '0879',	'08A5', '022D',	'0922', '0923',	'0934', '0920',	'086E', '0890',	'0897', '0956',	'0838', '0921',	'089E', '0863',	'0933', '089C',	'0965', '0361',	'0870', '086B',	'0366', '08A4',	'0363', '0864',	'08A3', '0899',	'0932', '0882',	'085E', '08AA',	'0954', '0953',	'0891', '0438',	'0367', '07E4',	'0880', '07EC',	'0955', '0962',	'095F', '0959',	'08A0', '0946',	'0869', '0811',	'092E', '0931',	'091A', '089D',	'08AD', '0961',	'0927', '0874',	'0365', '0929',	'091D', '087B',	'086C', '08A6',	'0940', '092B',	'094D', '08A1',	'0967', '091C',	'0888', '0360',	'095C', '0895',	'085B', '0963',	'0935', '0871',	'08A9', '023B',	'0281', '0968',	'0939', '0944',	'0885', '0368',	'087A', '096A',	'0815', '0866',	'0437', '088B',	'086F', '02C4',	'0867', '083C',	'0950', '094B',	'0889', '089B',	'089F', '094A',	'0802', '088C',	'0872', '08A7',	'08AC', '093A',	'0926', '08A8',	'0941', '092C',	'0819', '088D',	'0896', '095B',	'08A2', '0943',	'0894', '0868',	'089A', '091B',	'0949', '0860',	'0925', '0966',	'0876', '0948',	'0937', '0898',	'0873', '087E',	'093E', '095A',	'092A', '091F',	'087D', '0918',	'0861', '092D',	'0835', '088F',	'088E', '087F',	'0957', '092F',	'0862', '0930',	'0942', '0202',	'0969', '0887',	'0951', '091E',	'0928', '0884',
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
