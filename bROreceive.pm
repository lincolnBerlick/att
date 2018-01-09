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
	'07E4', '022D',	'0870', '0281',	'0961', '08AC',	'0886', '0930',	'093F', '091B',	'0860', '0949',	'0923', '0366',	'0881', '08A9',	'089F', '08A2',	'0819', '085D',	'0932', '088D',	'091A', '091E',	'07EC', '087B',	'0966', '0920',	'0956', '085C',	'0939', '0957',	'0964', '089C',	'0861', '0918',	'0934', '089A',	'0367', '0952',	'0925', '08A7',	'0926', '0947',	'0437', '092F',	'087C', '0969',	'0438', '088A',	'0955', '0929',	'089B', '093C',	'0965', '0875',	'0361', '0946',	'092E', '093B',	'0817', '0877',	'0876', '086F',	'0863', '0962',	'087D', '0436',	'0933', '0953',	'0943', '0960',	'0954', '086C',	'0888', '086E',	'08A4', '0363',	'0938', '0885',	'0867', '095C',	'023B', '094A',	'0894', '0369',	'0927', '094D',	'0878', '0919',	'0959', '093D',	'0968', '0892',	'0945', '095B',	'092A', '0364',	'0951', '0963',	'0940', '0879',	'08AB', '087A',	'089D', '0368',	'0935', '085F',	'094C', '094B',	'0895', '0365',	'08A3', '0896',	'094E', '0835',	'088E', '088B',	'094F', '0887',	'0862', '092C',	'0871', '0873',	'091C', '0891',	'0942', '0884',	'08A6', '0898',	'0893', '0941',	'093E', '0866',	'0360', '085A',	'08A5', '0838',	'083C', '0921',	'095E', '085E',	'0936', '096A',	'086D', '0937',	'0802', '035F',	'086A', '02C4',	'0931', '0864',	'08A8', '0944',	'0874', '0872',	'0950', '087E',	'095F', '0917',	'091F', '0883',	'085B', '08A0',	'092D', '0922',	'0897', '089E',
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
