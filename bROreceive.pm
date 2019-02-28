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
	'0882', '0889',	'086F', '095B',	'08A4', '0860',	'086A', '0898',	'0925', '08A9',	'0969', '0891',	'08A6', '0815',	'0869', '0819',	'086D', '093A',	'0917', '0932',	'0960', '0935',	'0955', '0926',	'0861', '0890',	'094E', '089F',	'0888', '0872',	'0967', '0919',	'0885', '091E',	'085B', '0867',	'0920', '0930',	'035F', '0866',	'093C', '0802',	'0944', '0362',	'07E4', '095E',	'08A2', '094A',	'0874', '0811',	'087B', '096A',	'095F', '0871',	'0931', '0873',	'092B', '086B',	'0951', '0923',	'0950', '0949',	'0887', '08A1',	'0835', '092D',	'0879', '0942',	'0865', '0958',	'088F', '0366',	'085A', '091B',	'094F', '0369',	'0945', '0964',	'091C', '023B',	'0361', '087C',	'0943', '0941',	'0952', '0934',	'0927', '0878',	'0436', '0838',	'0929', '0868',	'091A', '092C',	'0880', '086E',	'091D', '0862',	'08A0', '0877',	'092F', '094C',	'07EC', '0876',	'0959', '0893',	'0956', '08AA',	'0363', '085F',	'0360', '08AB',	'0918', '093B',	'0892', '0939',	'095A', '087F',	'0938', '089A',	'091F', '0953',	'087E', '0897',	'085E', '0921',	'085C', '0922',	'089D', '0948',	'089E', '0364',	'0437', '0963',	'086C', '087D',	'095D', '0202',	'093E', '0940',	'0924', '08A5',	'0367', '089B',	'0894', '0817',	'0896', '0365',	'093F', '0884',	'08AC', '094B',	'093D', '0281',	'0946', '092E',	'0947', '0438',	'0937', '022D',	'0936', '08A7',	'089C', '088A',	'0883', '0957',	'0881', '094D',
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
