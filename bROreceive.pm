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
	'022D', '0366',	'089E', '094D',	'0967', '087F',	'0861', '086A',	'094A', '089D',	'0932', '094E',	'0941', '0949',	'0927', '089B',	'0930', '0364',	'086F', '0802',	'08A0', '0869',	'0960', '092E',	'0946', '0951',	'0367', '08AA',	'093D', '0923',	'0281', '0926',	'0890', '08A2',	'08A7', '0956',	'0889', '086C',	'0885', '095E',	'0870', '0969',	'094C', '0925',	'0876', '088E',	'091D', '094F',	'095F', '0929',	'093A', '0437',	'093E', '0817',	'089F', '0938',	'0893', '085D',	'0898', '0872',	'0815', '0958',	'0868', '091E',	'0935', '0968',	'0878', '0940',	'086B', '088A',	'085F', '023B',	'0881', '07EC',	'0959', '0933',	'0888', '08A6',	'0865', '095C',	'0942', '088B',	'0931', '08A9',	'0877', '095B',	'092F', '0436',	'08A1', '0950',	'0838', '08AD',	'092A', '0892',	'092B', '0948',	'0944', '0866',	'0936', '0873',	'087E', '085C',	'0899', '0957',	'087D', '0811',	'0919', '087C',	'0862', '0360',	'0202', '094B',	'088C', '0819',	'0879', '08A8',	'093B', '08A5',	'087B', '07E4',	'0962', '08A3',	'0860', '0928',	'0864', '086E',	'092C', '085E',	'0920', '0963',	'0937', '087A',	'091F', '0874',	'0939', '085A',	'088D', '0954',	'0955', '0961',	'0952', '0922',	'0943', '0887',	'0895', '0891',	'0924', '0365',	'0871', '0896',	'091C', '0917',	'093C', '088F',	'0894', '0368',	'096A', '035F',	'0875', '086D',	'091A', '0966',	'095D', '083C',	'089A', '0965',	'0362', '0867',
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
