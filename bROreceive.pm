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
	'0962', '0364',	'085E', '089D',	'086C', '0360',	'0930', '095F',	'087F', '088D',	'0876', '08A0',	'093C', '094D',	'094E', '0887',	'0815', '0838',	'0920', '092D',	'091D', '0365',	'085B', '0956',	'0885', '08AA',	'0938', '08A5',	'0935', '0866',	'086A', '0202',	'0835', '0890',	'0367', '0926',	'0867', '091C',	'0932', '092F',	'0919', '0895',	'0871', '0819',	'085F', '0892',	'087B', '0940',	'089B', '0880',	'0968', '0888',	'089A', '08AD',	'094A', '0864',	'0882', '023B',	'0879', '0877',	'085D', '093A',	'0917', '088C',	'07E4', '0961',	'035F', '088B',	'0931', '0953',	'07EC', '0436',	'091B', '095A',	'0863', '089C',	'0899', '086F',	'0897', '08A8',	'0928', '089E',	'0941', '088A',	'0878', '0963',	'083C', '0939',	'096A', '0944',	'0438', '0802',	'093D', '087E',	'092C', '0955',	'092B', '0943',	'0875', '0369',	'0954', '0368',	'08A1', '092A',	'08A7', '0362',	'02C4', '08A9',	'0934', '0862',	'08A2', '0817',	'0950', '0942',	'095D', '092E',	'0893', '091A',	'095B', '0361',	'087A', '0896',	'0964', '0951',	'0281', '087D',	'0873', '0366',	'0945', '0918',	'0923', '0966',	'0946', '093E',	'0874', '0949',	'094C', '0881',	'0894', '0960',	'0868', '0891',	'0927', '085C',	'088E', '0969',	'08AB', '086E',	'0884', '087C',	'08AC', '0936',	'0967', '08A6',	'0947', '089F',	'093F', '095E',	'0869', '0865',	'085A', '0861',	'0363', '091F',	'0958', '094B',	'0952', '0933',
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
