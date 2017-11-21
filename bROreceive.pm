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
	'091D', '089C',	'0879', '0893',	'08AC', '0864',	'091C', '0884',	'0815', '0941',	'086C', '0892',	'0868', '0930',	'0366', '0966',	'0960', '092C',	'093B', '0889',	'091A', '094C',	'0436', '095C',	'0937', '0367',	'091B', '0863',	'0872', '0963',	'083C', '0957',	'0940', '0860',	'092A', '0891',	'085A', '0437',	'0939', '0202',	'0938', '0870',	'0871', '0899',	'096A', '087D',	'087E', '023B',	'0927', '088F',	'02C4', '0866',	'0369', '089F',	'08A5', '0811',	'087F', '0887',	'085C', '0894',	'0965', '085B',	'0865', '095D',	'0952', '0888',	'0862', '095F',	'08AB', '0969',	'093E', '0917',	'0365', '08A9',	'0881', '087A',	'087C', '086B',	'0956', '08A6',	'022D', '0895',	'0896', '092D',	'094B', '08A4',	'08A1', '0835',	'0968', '0874',	'0962', '0929',	'093F', '0936',	'088E', '0918',	'0921', '0953',	'0362', '0885',	'089A', '0922',	'0880', '094D',	'0867', '0920',	'0802', '086F',	'0838', '0360',	'0945', '0944',	'0919', '088A',	'093A', '093C',	'095A', '0955',	'08A0', '0934',	'07E4', '0958',	'088C', '088B',	'0928', '0898',	'035F', '093D',	'0878', '0931',	'0950', '0964',	'0967', '0949',	'0959', '091F',	'0875', '0935',	'0281', '0942',	'086E', '085E',	'0361', '091E',	'0861', '0954',	'0948', '08AD',	'0925', '086A',	'094E', '0926',	'0946', '0876',	'088D', '0886',	'0951', '086D',	'0932', '085D',	'0961', '085F',	'0817', '0438',	'0869', '0923',	'0364', '0943',
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
