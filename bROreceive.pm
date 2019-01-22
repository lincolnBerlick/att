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
	'0919', '094E',	'0957', '089E',	'0918', '08A0',	'0932', '0861',	'086A', '089F',	'092A', '094B',	'091F', '088B',	'092B', '089B',	'0930', '022D',	'0954', '092F',	'0940', '093C',	'0894', '089D',	'08A2', '08AA',	'088C', '0928',	'096A', '0924',	'0960', '08A3',	'095F', '035F',	'0946', '0878',	'0884', '0947',	'086D', '023B',	'091D', '0926',	'0921', '0964',	'087B', '0897',	'0879', '087F',	'0436', '0368',	'0944', '0874',	'0876', '0802',	'0886', '088D',	'095C', '0959',	'08A9', '088A',	'087C', '091C',	'091B', '0877',	'0955', '0967',	'086B', '085A',	'0945', '0953',	'0922', '0360',	'087A', '0873',	'094F', '095D',	'0202', '0938',	'08AB', '0835',	'0881', '0872',	'0819', '0838',	'0962', '0948',	'0870', '083C',	'094D', '0365',	'086E', '092C',	'087D', '0949',	'0862', '093D',	'0868', '0890',	'0963', '0863',	'0968', '0917',	'0898', '0895',	'0892', '08A5',	'089C', '089A',	'0931', '07EC',	'0939', '0860',	'0369', '0362',	'095A', '0965',	'0923', '095E',	'0891', '08AD',	'085E', '0866',	'08A8', '0367',	'08A7', '0438',	'07E4', '0875',	'094A', '085C',	'091E', '0366',	'093F', '0937',	'02C4', '086C',	'0935', '091A',	'0888', '0883',	'087E', '085F',	'0936', '08AC',	'092D', '0969',	'0951', '0899',	'08A6', '0361',	'0889', '0865',	'0437', '0364',	'0363', '0966',	'0958', '0815',	'0880', '085B',	'086F', '0893',	'093E', '0942',	'0934', '0933',	'088E', '088F',
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
