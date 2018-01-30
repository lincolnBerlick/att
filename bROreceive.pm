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
	);
	# Sync Ex Reply Array 
	$self->{sync_ex_reply} = {
	'07EC', '0938',	'093F', '08A1',	'095F', '0940',	'091E', '0873',	'095D', '086E',	'086B', '085E',	'0361', '0860',	'083C', '086C',	'0896', '0891',	'0893', '0883',	'086A', '088A',	'0951', '0878',	'091F', '0861',	'085A', '035F',	'0952', '0811',	'0947', '0936',	'094A', '091A',	'0927', '0281',	'0932', '087F',	'0965', '0917',	'091B', '0881',	'0935', '0944',	'0918', '092D',	'095E', '07E4',	'0899', '087C',	'089C', '0968',	'087D', '0949',	'0897', '08A3',	'0877', '0930',	'0961', '089A',	'0928', '087B',	'086F', '08A0',	'08A7', '0934',	'088B', '0360',	'0835', '0885',	'087E', '0436',	'0815', '0962',	'0369', '0889',	'095B', '0945',	'0922', '0956',	'0937', '088E',	'0920', '085D',	'093C', '089D',	'0919', '085C',	'0929', '0868',	'0939', '0923',	'0964', '0437',	'022D', '092E',	'08A5', '092C',	'08A9', '0958',	'0942', '0880',	'0931', '095A',	'08A2', '0202',	'086D', '0819',	'0941', '0368',	'0862', '0887',	'0967', '0888',	'0969', '092A',	'0924', '0953',	'093D', '085F',	'0960', '0921',	'0926', '094E',	'089F', '08A8',	'0933', '023B',	'0957', '0367',	'0950', '0959',	'085B', '094B',	'088D', '0871',	'0362', '091C',	'094F', '088F',	'0894', '0892',	'0943', '0884',	'0438', '091D',	'0876', '0866',	'089B', '093A',	'094C', '0895',	'08AD', '08AC',	'092B', '0802',	'095C', '0869',	'08A4', '0966',	'0963', '0890',	'0363', '0875',	'0865', '087A',	'0879', '0864',
	};
		
	foreach my $key (keys %{$self->{sync_ex_reply}}) { $packets{$key} = ['sync_request_ex']; }
	foreach my $switch (keys %packets) { $self->{packet_list}{$switch} = $packets{$switch}; }
	
	my %handlers = qw(
		received_characters 099D
		received_characters_info 082D
		sync_received_characters 09A0
	);

	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;
	
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
