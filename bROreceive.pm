###########################################################################
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
		'0AC4' => ['account_server_info', 'v a4 a4 a4 a4 a26 C x17 a*', [qw(len sessionID accountID sessionID2 lastLoginIP lastLoginTime accountSex serverInfo)]], #nova linha
	);
	# Sync Ex Reply Array 
	$self->{sync_ex_reply} = {
	'0898', '0931',	'0926', '0940',	'0872', '096A',	'0946', '0935',	'094F', '095B',	'0811', '0881',	'0875', '088E',	'0918', '093C',	'0869', '0871',	'0363', '0938',	'0862', '0896',	'0835', '0360',	'0870', '087B',	'0364', '0957',	'0874', '08A2',	'0883', '089B',	'092F', '093D',	'091A', '0892',	'0942', '095C',	'095A', '08A1',	'0802', '089C',	'0864', '0436',	'093E', '093B',	'0969', '0941',	'0876', '0937',	'0437', '08A9',	'0894', '0947',	'0960', '087D',	'0943', '0368',	'0948', '092C',	'07E4', '0951',	'0953', '093F',	'091F', '0939',	'085D', '0889',	'0880', '0936',	'089E', '0838',	'0919', '08A4',	'0961', '023B',	'0964', '0366',	'086A', '08AC',	'0917', '094E',	'091C', '0920',	'088C', '094A',	'0860', '0369',	'0932', '0967',	'085F', '0956',	'0863', '085C',	'08A3', '089F',	'0928', '08AA',	'0927', '0944',	'0865', '086D',	'0861', '0924',	'087C', '0899',	'0817', '088A',	'0958', '0963',	'0891', '0884',	'0815', '0922',	'022D', '02C4',	'086C', '095E',	'0945', '092A',	'092B', '094B',	'093A', '085B',	'095F', '08AB',	'087A', '0897',	'0362', '0879',	'091B', '08A8',	'07EC', '0202',	'08A0', '087E',	'08A7', '0949',	'0929', '094C',	'0868', '092E',	'087F', '0885',	'0873', '091E',	'0923', '0962',	'0867', '035F',	'08AD', '0966',	'0895', '0893',	'085E', '0950',	'0952', '089A',	'0361', '0933',	'0968', '0866',	'0877', '089D',	'091D', '0878',	'086B', '0934',
	};
		
	foreach my $key (keys %{$self->{sync_ex_reply}}) { $packets{$key} = ['sync_request_ex']; }
	foreach my $switch (keys %packets) { $self->{packet_list}{$switch} = $packets{$switch}; }
	
	my %handlers = qw(		
		received_characters 099D
		received_characters_info 082D
		sync_received_characters 09A0
		account_server_info 0AC4 #nova linha
	);

	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;
	$self->{vender_items_list_item_pack} = 'V v2 C v C3 a8 a25'; #nova linha
	
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
