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
package Network::Send::bRO;
use strict;
use base 'Network::Send::ServerType0';

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	
	my %packets = (
		'0918' => ['actor_action', 'a4 C', [qw(targetID type)]],
		'0437' => ['skill_use', 'v2 a4', [qw(lv skillID targetID)]],
		'0861' => ['character_move','a3', [qw(coords)]],
		'091E' => ['sync', 'V', [qw(time)]],
		'088E' => ['actor_look_at', 'v C', [qw(head body)]],
		'086F' => ['item_take', 'a4', [qw(ID)]],
		'0895' => ['item_drop', 'v2', [qw(index amount)]],
		'094D' => ['storage_item_add', 'v V', [qw(index amount)]],
		'0864' => ['storage_item_remove', 'v V', [qw(index amount)]],
		'0965' => ['skill_use_location', 'v4', [qw(lv skillID x y)]],
		'035F' => ['actor_info_request', 'a4', [qw(ID)]],
		'089F' => ['actor_name_request', 'a4', [qw(ID)]],	
		'093E' => ['buy_bulk_buyer', 'a4 a4 a*', [qw(buyerID buyingStoreID itemInfo)]], # Buying Store
		'091F' => ['buy_bulk_closeShop'],
		'0948' => ['buy_bulk_openShop', 'a4 c a*', [qw(limitZeny result itemInfo)]], # Selling Store
		'08AD' => ['booking_register', 'v8', [qw(level MapID job0 job1 job2 job3 job4 job5)]], # Booking Register
		'08A3' => ['item_list_res', 'v V2 a*', [qw(len type action itemInfo)]],
		'0939' => ['map_login', 'a4 a4 a4 V C', [qw(accountID charID sessionID tick sex)]],
		'0897' => ['party_join_request_by_name', 'Z24', [qw(partyName)]],
		'085B' => ['friend_request', 'a*', [qw(username)]],
		'0957' => ['homunculus_command', 'v C', [qw(commandType, commandID)]],
		'093D' => ['storage_password'],		
	);
	
	$self->{packet_list}{$_} = $packets{$_} for keys %packets;
	
	my %handlers = qw(
		master_login 02B0
		buy_bulk_vender 0801
		party_setting 07D7
		send_equip 0998
	);
	
	while (my ($k, $v) = each %packets) { $handlers{$v->[0]} = $k}
	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;
	$self->cryptKeys(504719639, 1117290297, 2037476795);

	return $self;
}

1;
