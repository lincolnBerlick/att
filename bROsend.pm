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
		'0880' => ['actor_action', 'a4 C', [qw(targetID type)]],
		'0927' => ['skill_use', 'v2 a4', [qw(lv skillID targetID)]],
		'0928' => ['character_move','a3', [qw(coords)]],
		'086A' => ['sync', 'V', [qw(time)]],
		'0887' => ['actor_look_at', 'v C', [qw(head body)]],
		'0968' => ['item_take', 'a4', [qw(ID)]],
		'089B' => ['item_drop', 'v2', [qw(index amount)]],
		'089A' => ['storage_item_add', 'v V', [qw(index amount)]],
		'0923' => ['storage_item_remove', 'v V', [qw(index amount)]],
		'0963' => ['skill_use_location', 'v4', [qw(lv skillID x y)]],
		'08A8' => ['actor_info_request', 'a4', [qw(ID)]],
		'0860' => ['actor_name_request', 'a4', [qw(ID)]],	
		'0949' => ['buy_bulk_buyer', 'a4 a4 a*', [qw(buyerID buyingStoreID itemInfo)]], # Buying Store
		'0930' => ['buy_bulk_closeShop'],
		'0865' => ['buy_bulk_openShop', 'a4 c a*', [qw(limitZeny result itemInfo)]], # Selling Store
		'0817' => ['booking_register', 'v8', [qw(level MapID job0 job1 job2 job3 job4 job5)]], # Booking Register
		'0922' => ['item_list_res', 'v V2 a*', [qw(len type action itemInfo)]],
		'094A' => ['map_login', 'a4 a4 a4 V C', [qw(accountID charID sessionID tick sex)]],
		'0364' => ['party_join_request_by_name', 'Z24', [qw(partyName)]],
		'0969' => ['friend_request', 'a*', [qw(username)]],
		'0802' => ['homunculus_command', 'v C', [qw(commandType, commandID)]],
		'08AB' => ['storage_password'],		
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
	$self->cryptKeys(1733955113, 435290416, 1220507378);

	return $self;
}

1;
