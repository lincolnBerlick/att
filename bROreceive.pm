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
	'0202', '0925',	'0878', '089F',	'085F', '0923',	'091D', '0957',	'0871', '0437',	'085C', '085A',	'092F', '0934',	'0922', '0932',	'0920', '0936',	'0967', '086D',	'092C', '091E',	'0896', '087B',	'0940', '0921',	'0942', '0894',	'0893', '0969',	'0880', '0802',	'0951', '086E',	'089D', '0879',	'0952', '0877',	'0962', '085D',	'0869', '0928',	'0838', '0895',	'08A0', '0860',	'0966', '095C',	'0884', '0949',	'093B', '0958',	'093D', '0890',	'086A', '08A3',	'0946', '088A',	'0881', '088B',	'091A', '0939',	'096A', '0965',	'091F', '0953',	'095A', '094F',	'0944', '094E',	'0933', '095D',	'094D', '0367',	'0931', '093F',	'086B', '092A',	'0886', '0938',	'08A6', '0947',	'0937', '0366',	'093A', '08A1',	'07EC', '0864',	'0959', '087F',	'091B', '092E',	'095B', '07E4',	'0364', '089C',	'092D', '0898',	'0918', '0817',	'0365', '0926',	'0961', '0950',	'0363', '088F',	'08A2', '035F',	'0930', '0935',	'083C', '0955',	'0281', '0868',	'0897', '0891',	'0943', '0867',	'0929', '087D',	'089A', '0941',	'085E', '0361',	'092B', '0917',	'0866', '0872',	'08AC', '0436',	'0883', '089B',	'089E', '0956',	'08A7', '0964',	'0873', '0362',	'094C', '0438',	'088D', '0360',	'094B', '087E',	'0870', '0811',	'087A', '0835',	'08A8', '0819',	'0960', '093E',	'0963', '0887',	'0863', '0924',	'08A9', '0892',	'0945', '086C',	'08A4', '0875',	'0369', '093C',	'08AB', '0876',	'08A5', '08AD',
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
