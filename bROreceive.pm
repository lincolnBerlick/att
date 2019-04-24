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
	'095C', '089B',	'092B', '091A',	'0936', '0897',	'0939', '08A1',	'0952', '085E',	'087E', '0969',	'08A5', '08AD',	'0920', '0877',	'0862', '0951',	'0943', '0957',	'091B', '0927',	'0947', '08AB',	'094F', '0281',	'091F', '0955',	'093A', '0886',	'0887', '0817',	'0966', '0967',	'0872', '089C',	'0919', '0922',	'0946', '089F',	'085D', '0892',	'08A6', '08A7',	'0366', '093D',	'092C', '092F',	'0365', '0835',	'0870', '094D',	'0875', '0361',	'092E', '0963',	'0876', '095E',	'0925', '0899',	'0882', '094A',	'08A4', '094C',	'0941', '094B',	'0866', '07E4',	'08A9', '095F',	'092A', '0961',	'0958', '0891',	'089D', '023B',	'0890', '0436',	'085C', '07EC',	'088F', '0878',	'088B', '0964',	'0962', '0933',	'0934', '091D',	'087B', '0938',	'0360', '091E',	'0369', '0949',	'08AC', '0968',	'08A2', '085B',	'092D', '086C',	'0880', '087F',	'022D', '0888',	'093F', '087A',	'0956', '0868',	'0367', '0861',	'0883', '08A3',	'0944', '035F',	'0863', '086A',	'0363', '095D',	'0917', '0368',	'0811', '0815',	'089E', '0954',	'08A0', '0879',	'087C', '093B',	'0893', '0438',	'0935', '0362',	'088E', '0819',	'0924', '0926',	'0885', '0923',	'0918', '0896',	'0929', '093C',	'0945', '0364',	'0838', '088C',	'0202', '0948',	'0802', '0884',	'089A', '0867',	'093E', '0931',	'0960', '0937',	'0965', '086B',	'0874', '0932',	'0871', '0864',	'083C', '095B',	'086D', '0942',	'0889', '0940',
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
