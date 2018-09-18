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
	'095E', '0917',	'0918', '0929',	'0895', '086F',	'0943', '08A5',	'0896', '0962',	'0870', '0364',	'096A', '092E',	'0926', '0939',	'0925', '085D',	'0888', '0866',	'0880', '0938',	'0960', '0947',	'07EC', '0811',	'0965', '0897',	'086B', '08AA',	'02C4', '0881',	'091F', '08A1',	'089A', '0963',	'022D', '0863',	'094D', '035F',	'0931', '0932',	'087C', '08A6',	'088B', '0948',	'085C', '0861',	'0815', '0835',	'093F', '0945',	'0883', '08AC',	'0889', '0934',	'092F', '0968',	'0882', '088E',	'0865', '0958',	'095C', '093A',	'0961', '0956',	'0877', '0838',	'0969', '0921',	'08AD', '0950',	'086E', '095D',	'0879', '0868',	'091A', '0873',	'093B', '0894',	'0871', '0885',	'088C', '085F',	'0867', '0438',	'0437', '0360',	'0951', '0944',	'0966', '0363',	'093C', '091E',	'089E', '0802',	'093D', '08A0',	'087D', '0872',	'0920', '095B',	'0878', '07E4',	'0899', '0952',	'0436', '095A',	'0927', '089C',	'0362', '094C',	'091D', '092A',	'094E', '0937',	'083C', '0955',	'0924', '092D',	'0887', '094A',	'0817', '0366',	'092C', '087A',	'0940', '0890',	'0893', '085B',	'0949', '089D',	'0936', '0954',	'085A', '0819',	'0862', '085E',	'0919', '0202',	'0930', '0933',	'08A3', '091C',	'094F', '0967',	'087F', '092B',	'089B', '086C',	'0928', '0923',	'0369', '08AB',	'08A2', '0361',	'08A9', '095F',	'0942', '0941',	'0953', '0367',	'0959', '0869',	'08A8', '0864',	'0892', '088A',
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
