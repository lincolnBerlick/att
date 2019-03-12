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
	'0875', '0969',	'087A', '0967',	'02C4', '089E',	'0880', '0928',	'089F', '0887',	'086D', '0957',	'0877', '0946',	'0879', '0934',	'0867', '095F',	'0360', '083C',	'0965', '0962',	'0950', '0860',	'089D', '085C',	'086E', '0958',	'0942', '0955',	'035F', '023B',	'088E', '088B',	'08A9', '0941',	'0919', '0897',	'0881', '0936',	'0926', '0369',	'0878', '092F',	'0281', '08A7',	'0361', '085F',	'08A4', '0886',	'095C', '0968',	'0884', '0939',	'0932', '091D',	'0888', '0964',	'091E', '0885',	'0947', '0865',	'0438', '0960',	'0922', '089B',	'08A5', '0898',	'085E', '08A0',	'086B', '0917',	'0956', '0929',	'0883', '088D',	'0363', '086F',	'0838', '0893',	'092E', '093D',	'0872', '0890',	'08A8', '0802',	'0896', '087F',	'085B', '094C',	'093C', '092D',	'022D', '0927',	'0925', '0933',	'092C', '08A1',	'094D', '0940',	'0949', '0368',	'0945', '07EC',	'0920', '0866',	'0436', '0870',	'08AB', '095A',	'0365', '0899',	'0954', '0961',	'0362', '0862',	'094F', '0935',	'0894', '0924',	'0367', '091C',	'095D', '0948',	'089C', '0931',	'0921', '094E',	'093F', '085D',	'087E', '0918',	'089A', '0923',	'0951', '0966',	'086C', '0366',	'0437', '091F',	'093A', '086A',	'0869', '091B',	'0835', '0863',	'07E4', '096A',	'0202', '093E',	'092A', '091A',	'0943', '0864',	'0952', '095B',	'0817', '088C',	'085A', '087C',	'08AA', '093B',	'0892', '0959',	'0873', '088A',	'0868', '0895',
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
