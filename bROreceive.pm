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
	'0877', '093C',	'0881', '0931',	'092A', '08AD',	'0891', '093A',	'0922', '0951',	'0941', '0882',	'0932', '0898',	'0968', '094A',	'091C', '088F',	'0437', '0896',	'0939', '0956',	'08A0', '088C',	'08A7', '0943',	'0952', '087C',	'087B', '0880',	'0928', '0929',	'089F', '0962',	'0888', '095D',	'0924', '0364',	'085A', '0954',	'0921', '0953',	'0946', '095E',	'0889', '087A',	'0884', '08AC',	'0883', '0872',	'0933', '093F',	'0957', '0436',	'092E', '0918',	'08A5', '087D',	'089A', '08A6',	'092F', '0802',	'0936', '0861',	'0363', '0945',	'0897', '0938',	'092C', '0969',	'089C', '087E',	'023B', '0930',	'08A3', '0926',	'092B', '086C',	'07EC', '022D',	'0925', '0875',	'089E', '088E',	'088A', '0947',	'08A1', '0202',	'0887', '085B',	'094D', '091A',	'0369', '095B',	'086D', '091E',	'089B', '0917',	'0934', '0960',	'0965', '086B',	'085D', '096A',	'0958', '095F',	'0955', '0923',	'089D', '083C',	'08AA', '0940',	'0963', '094B',	'0864', '0948',	'094C', '085F',	'0867', '0937',	'0899', '0935',	'0360', '0838',	'093B', '088B',	'0367', '085E',	'0919', '0819',	'0874', '0966',	'035F', '0944',	'08A2', '0817',	'094F', '07E4',	'0964', '02C4',	'0885', '0368',	'0815', '0949',	'086E', '091D',	'0860', '0967',	'086A', '0886',	'08AB', '0878',	'0365', '08A8',	'0281', '085C',	'08A4', '0893',	'086F', '0361',	'0869', '091F',	'0362', '0873',	'094E', '088D',	'0871', '095A',
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
