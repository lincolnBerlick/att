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
	'0864', '095E',	'0894', '091A',	'0920', '0819',	'089F', '0817',	'095A', '0957',	'0884', '0898',	'085E', '0961',	'0966', '0879',	'08A1', '0950',	'087C', '0922',	'0869', '0362',	'07E4', '087B',	'0893', '08A4',	'08A9', '094A',	'087A', '094F',	'0366', '085B',	'091B', '083C',	'0940', '0870',	'07EC', '08AC',	'0927', '0965',	'0880', '092D',	'0815', '092E',	'0934', '095D',	'0835', '0956',	'0875', '094E',	'0877', '088E',	'08A6', '0964',	'0892', '089B',	'08AA', '0811',	'0962', '095B',	'0942', '089D',	'0931', '0365',	'0369', '091C',	'0281', '0944',	'093D', '0890',	'022D', '0959',	'091E', '0935',	'0881', '093C',	'0926', '092B',	'0939', '0955',	'088A', '0967',	'095F', '0933',	'092A', '094D',	'0866', '0861',	'0951', '0941',	'086F', '0360',	'0925', '087D',	'0947', '0969',	'0883', '092F',	'0945', '088B',	'094C', '0963',	'094B', '092C',	'0952', '0921',	'0436', '035F',	'0932', '0865',	'0863', '08A5',	'0929', '0938',	'02C4', '0886',	'0899', '0202',	'0802', '08A3',	'08A8', '0918',	'0873', '08AB',	'08A7', '0871',	'0437', '096A',	'0868', '086B',	'093B', '085C',	'088F', '0882',	'089E', '0917',	'0948', '095C',	'08AD', '0919',	'0949', '0364',	'0860', '089C',	'0862', '0888',	'0874', '085D',	'093E', '0896',	'0954', '0923',	'085A', '0368',	'0968', '0895',	'08A0', '087F',	'0937', '0943',	'0953', '086C',	'0928', '086E',	'088D', '0872',	'0878', '091D',
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
