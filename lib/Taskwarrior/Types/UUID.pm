package Taskwarrior::Types::UUID;

use Type::Library -base;
use Type::Tiny ();
use Types::Standard qw( Str );
use UUID::Tiny qw( is_uuid_string );

our @EXPORT = qw( Uuid );

my $type = __PACKAGE__->add_type(

  name       => 'Uuid',
  parent     => Str,
  constraint => \&is_uuid_string,
  inlined    => sub { Str->inline_check($_), "UUID::Tiny::is_uuid_string($_)" },

);
