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
	'0881', '0949',	'091E', '0954',	'093C', '08A5',	'087F', '094D',	'0967', '0878',	'092C', '088D',	'0936', '086E',	'0890', '0815',	'092A', '0367',	'023B', '085F',	'094B', '0862',	'07E4', '0944',	'0281', '0920',	'0802', '0861',	'092B', '0940',	'085E', '087C',	'094E', '0879',	'095B', '0917',	'0923', '086F',	'0898', '094C',	'08AD', '0960',	'087B', '08A9',	'089D', '02C4',	'0884', '0867',	'093F', '0874',	'0958', '08A2',	'0924', '0950',	'0945', '08A6',	'0957', '0876',	'095E', '095D',	'0873', '087E',	'0947', '0872',	'091B', '0935',	'0922', '08A1',	'091D', '0365',	'095F', '0368',	'0961', '0888',	'0880', '0966',	'088C', '0931',	'092D', '08AC',	'086A', '0959',	'0885', '086D',	'0969', '085D',	'093A', '085C',	'089F', '0838',	'085B', '085A',	'088F', '092E',	'0930', '089A',	'0438', '0883',	'0895', '088B',	'094A', '089C',	'0894', '08A0',	'092F', '0869',	'0369', '0926',	'0436', '08A8',	'0863', '0363',	'0921', '035F',	'0864', '0928',	'0875', '0953',	'0882', '0918',	'0932', '0965',	'087D', '091F',	'0937', '0933',	'0897', '093D',	'07EC', '0942',	'083C', '0927',	'096A', '0952',	'0963', '0877',	'086B', '0835',	'0362', '0934',	'022D', '0955',	'0941', '094F',	'0817', '095C',	'0948', '091C',	'08AB', '08A4',	'0811', '093E',	'0946', '0929',	'0968', '0819',	'0951', '0360',	'0943', '0871',	'0868', '0866',	'0925', '0938',	'08AA', '08A7',	'0202', '0889',
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
