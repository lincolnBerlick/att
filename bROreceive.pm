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
	'096A', '0874',	'0931', '0895',	'089A', '0969',	'092E', '0897',	'0437', '0875',	'0868', '0952',	'023B', '088C',	'0366', '0863',	'0962', '086D',	'091E', '086E',	'092D', '094A',	'0934', '08A9',	'088A', '085C',	'087E', '02C4',	'085B', '0888',	'094C', '0953',	'0362', '089B',	'08A4', '0882',	'0932', '08A2',	'0919', '091B',	'086C', '08A3',	'0886', '0893',	'091A', '0878',	'0929', '0889',	'088E', '022D',	'0935', '087D',	'0811', '085F',	'0944', '094D',	'0925', '08A6',	'0438', '085A',	'0866', '0921',	'093A', '0817',	'0961', '089F',	'095B', '0869',	'07E4', '0948',	'08AC', '0945',	'0876', '0956',	'0368', '0885',	'0887', '093E',	'08AD', '0923',	'0955', '093D',	'086F', '0369',	'089E', '086B',	'0937', '087B',	'08A0', '095F',	'0364', '0861',	'088D', '0862',	'095C', '0360',	'0922', '0860',	'0865', '0881',	'0880', '0819',	'091D', '035F',	'0957', '0950',	'088F', '091F',	'086A', '0946',	'0815', '085D',	'0867', '0896',	'095E', '0879',	'0891', '0967',	'095A', '0930',	'0959', '07EC',	'0202', '08A8',	'0899', '0964',	'0943', '093C',	'0365', '08A7',	'085E', '0958',	'0835', '0892',	'0939', '092A',	'0884', '0963',	'094E', '088B',	'0942', '094F',	'091C', '0933',	'0940', '08AB',	'0281', '0361',	'087A', '095D',	'08A5', '0920',	'092C', '083C',	'0928', '0367',	'0966', '0838',	'0436', '0927',	'092B', '0918',	'0802', '0926',	'0954', '0872',	'0917', '089D',
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
