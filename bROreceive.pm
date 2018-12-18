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
	'092E', '0802',	'0817', '087B',	'07E4', '0897',	'08AB', '089A',	'0368', '0862',	'0924', '08A1',	'0933', '0869',	'087E', '088A',	'08A0', '093A',	'08A5', '089B',	'088F', '088D',	'035F', '0920',	'0361', '0960',	'091E', '0962',	'0894', '089D',	'0437', '0927',	'0886', '094A',	'0921', '0942',	'093C', '091B',	'0884', '0880',	'0958', '0868',	'087C', '0878',	'0964', '0890',	'091C', '0959',	'02C4', '0873',	'0932', '0969',	'0929', '094F',	'089E', '08A8',	'0950', '0941',	'0935', '086E',	'023B', '095C',	'0939', '088E',	'091D', '0968',	'0922', '0875',	'091A', '0838',	'022D', '089F',	'0882', '093F',	'0967', '0917',	'0889', '0926',	'0895', '095F',	'0872', '0876',	'0885', '0955',	'091F', '0963',	'093E', '0879',	'089C', '0949',	'092D', '088C',	'0957', '0877',	'0896', '0365',	'086A', '08A9',	'0946', '083C',	'08A7', '0918',	'0953', '085D',	'08A4', '0815',	'0954', '0881',	'08AC', '0867',	'0925', '0438',	'093D', '095D',	'0865', '0947',	'0888', '0893',	'0936', '0874',	'0863', '0945',	'0930', '0899',	'092C', '0436',	'093B', '085F',	'0943', '08A6',	'094C', '0811',	'0360', '0864',	'0870', '092A',	'0923', '094D',	'08A2', '0363',	'085E', '092B',	'0940', '086D',	'086C', '07EC',	'0866', '08AD',	'0966', '0928',	'0202', '0892',	'0948', '0891',	'086B', '0952',	'0364', '0860',	'0961', '08A3',	'0883', '0367',	'0887', '087F',	'0934', '0366',	'0931', '094B',
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
