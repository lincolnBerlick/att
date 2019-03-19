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
		'088D' => ['actor_action', 'a4 C', [qw(targetID type)]],
		'0365' => ['skill_use', 'v2 a4', [qw(lv skillID targetID)]],
		'0925' => ['character_move','a3', [qw(coords)]],
		'086E' => ['sync', 'V', [qw(time)]],
		'0965' => ['actor_look_at', 'v C', [qw(head body)]],
		'0954' => ['item_take', 'a4', [qw(ID)]],
		'086F' => ['item_drop', 'v2', [qw(index amount)]],
		'0888' => ['storage_item_add', 'v V', [qw(index amount)]],
		'0955' => ['storage_item_remove', 'v V', [qw(index amount)]],
		'0930' => ['skill_use_location', 'v4', [qw(lv skillID x y)]],
		'0959' => ['actor_info_request', 'a4', [qw(ID)]],
		'0367' => ['actor_name_request', 'a4', [qw(ID)]],	
		'0882' => ['buy_bulk_buyer', 'a4 a4 a*', [qw(buyerID buyingStoreID itemInfo)]], # Buying Store
		'0281' => ['buy_bulk_closeShop'],
		'0886' => ['buy_bulk_openShop', 'a4 c a*', [qw(limitZeny result itemInfo)]], # Selling Store
		'092D' => ['booking_register', 'v8', [qw(level MapID job0 job1 job2 job3 job4 job5)]], # Booking Register
		'085A' => ['item_list_res', 'v V2 a*', [qw(len type action itemInfo)]],
		'094D' => ['map_login', 'a4 a4 a4 V C', [qw(accountID charID sessionID tick sex)]],
		'095D' => ['party_join_request_by_name', 'Z24', [qw(partyName)]],
		'0890' => ['friend_request', 'a*', [qw(username)]],
		'088F' => ['homunculus_command', 'v C', [qw(commandType, commandID)]],
		'088B' => ['storage_password'],		
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
	$self->cryptKeys(1859409449, 925043704, 686505270);

	return $self;
}

1;
