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
		'0AC4' => ['account_server_info', 'v a4 a4 a4 a4 a26 C x17 a*', [qw(len sessionID accountID sessionID2 lastLoginIP lastLoginTime accountSex serverInfo)]], #nova linha
	);
	# Sync Ex Reply Array 
	$self->{sync_ex_reply} = {
	'0897', '0361',	'091D', '0861',	'08A6', '0890',	'0943', '023B',	'091A', '0366',	'093B', '091C',	'087F', '0941',	'086A', '0802',	'0934', '0865',	'0864', '08A9',	'092B', '0919',	'0887', '085B',	'08A0', '0936',	'0876', '092D',	'0920', '0924',	'088A', '092C',	'092E', '0202',	'0935', '0878',	'0898', '0928',	'08AD', '086C',	'08A8', '0362',	'07E4', '0889',	'094A', '0944',	'085F', '022D',	'0948', '0899',	'0929', '095F',	'0940', '0895',	'0963', '0939',	'0872', '0927',	'093A', '088C',	'094F', '083C',	'0921', '08AA',	'095C', '0360',	'0930', '089E',	'0933', '0959',	'0957', '087B',	'087E', '0811',	'0922', '0891',	'086D', '0867',	'0968', '08A4',	'0369', '095B',	'0838', '0870',	'0938', '091F',	'0892', '085A',	'0954', '0860',	'093C', '0436',	'089C', '096A',	'08A3', '0956',	'0880', '0961',	'092F', '089B',	'0888', '0881',	'0942', '0931',	'02C4', '0894',	'0882', '086E',	'091E', '086B',	'0965', '0952',	'093F', '088D',	'0937', '0866',	'0967', '088F',	'0923', '089F',	'0945', '035F',	'0871', '0879',	'086F', '094D',	'087D', '0817',	'0925', '085C',	'0883', '087A',	'0932', '0953',	'0438', '0947',	'094C', '0962',	'0960', '088B',	'094B', '0815',	'094E', '091B',	'0918', '0874',	'0966', '095E',	'0946', '0862',	'095A', '0884',	'0863', '0950',	'07EC', '0885',	'0877', '0819',	'093D', '0281',	'0437', '0873',	'08A5', '0875',	'0365', '0364',	'08A2', '085D',
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
