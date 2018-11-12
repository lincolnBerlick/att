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
	'08A6', '0918',	'089A', '0364',	'0936', '0917',	'0367', '0872',	'091E', '0938',	'0863', '08A8',	'087B', '08AA',	'0867', '0925',	'0817', '0362',	'0927', '0899',	'0926', '0878',	'095E', '0891',	'0365', '0835',	'087F', '0961',	'094F', '0862',	'0945', '085E',	'091A', '02C4',	'088D', '0886',	'092E', '08A2',	'0879', '083C',	'0957', '07EC',	'08A4', '08A0',	'0920', '0896',	'0967', '0953',	'0949', '08AD',	'0873', '086F',	'0940', '0860',	'094B', '092D',	'094E', '0870',	'092F', '0815',	'089C', '0866',	'088E', '0937',	'089E', '0969',	'093A', '08AC',	'0360', '085C',	'0363', '085A',	'091B', '093F',	'0929', '0942',	'0890', '086D',	'0954', '0361',	'094C', '0946',	'022D', '096A',	'035F', '0921',	'0893', '088B',	'087E', '091C',	'092C', '0881',	'093C', '086C',	'095B', '0438',	'0281', '085D',	'0869', '086B',	'0883', '0960',	'089B', '0968',	'0956', '0943',	'0868', '0928',	'0887', '0966',	'093B', '092A',	'0871', '0880',	'091F', '0819',	'085B', '093D',	'087D', '0897',	'0958', '0882',	'0884', '0934',	'095F', '0898',	'0931', '095D',	'0368', '0888',	'088C', '08AB',	'0950', '08A1',	'0811', '095C',	'087A', '023B',	'0947', '094A',	'0923', '0962',	'08A9', '0861',	'0959', '0895',	'0922', '08A3',	'0965', '0437',	'0951', '086E',	'0369', '0948',	'088A', '0939',	'08A7', '0894',	'091D', '0941',	'0919', '0865',	'0876', '0366',	'085F', '088F',	'0952', '0892',
	};
		
	foreach my $key (keys %{$self->{sync_ex_reply}}) { $packets{$key} = ['sync_request_ex']; }
	foreach my $switch (keys %packets) { $self->{packet_list}{$switch} = $packets{$switch}; }
	
	my %handlers = qw(
		received_characters 099D
		received_characters_info 082D
		sync_received_characters 09A0
		account_server_info 0AC4
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
