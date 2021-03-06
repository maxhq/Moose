use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Moose::Meta::Role;


{
    package FooRole;
    our $VERSION = '0.01';
    sub foo {'FooRole::foo'}
}

{
    package Foo;
    use Moose;

    #two checks because the inlined methods are different when
    #there is a TC present.
    has 'foos' => ( is => 'ro', lazy_build => 1 );
    has 'bars' => ( isa => 'Str', is => 'ro', lazy_build => 1 );
    has 'bazes' => ( isa => 'Str', is => 'ro', builder => '_build_bazes' );
    sub _build_foos  {"many foos"}
    sub _build_bars  {"many bars"}
    sub _build_bazes {"many bazes"}
}

{
    my $foo_role = Moose::Meta::Role->initialize('FooRole');
    my $meta     = Foo->meta;

    is( exception { Foo->new }, undef, "lazy_build works" );
    is( Foo->new->foos, 'many foos',
        "correct value for 'foos'  before inlining constructor" );
    is( Foo->new->bars, 'many bars',
        "correct value for 'bars'  before inlining constructor" );
    is( Foo->new->bazes, 'many bazes',
        "correct value for 'bazes' before inlining constructor" );
    is( exception { $meta->make_immutable }, undef, "Foo is imutable" );
    is( exception { $meta->identifier }, undef, "->identifier on metaclass lives" );
    isnt( exception { $meta->add_role($foo_role) }, undef, "Add Role is locked" );
    is( exception { Foo->new }, undef, "Inlined constructor works with lazy_build" );
    is( Foo->new->foos, 'many foos',
        "correct value for 'foos'  after inlining constructor" );
    is( Foo->new->bars, 'many bars',
        "correct value for 'bars'  after inlining constructor" );
    is( Foo->new->bazes, 'many bazes',
        "correct value for 'bazes' after inlining constructor" );
    is( exception { $meta->make_mutable }, undef, "Foo is mutable" );
    is( exception { $meta->add_role($foo_role) }, undef, "Add Role is unlocked" );

}

my %called;

{
  package Bar;

  use Moose;

  sub BUILD { $called{+__PACKAGE__}++ }
}

{
  package Baz;

  use Moose;

  extends 'Bar';

  sub BUILD { $called{+__PACKAGE__}++ }
}

is( exception { Bar->meta->make_immutable }, undef, 'Immutable meta with single BUILD' );

is( exception { Baz->meta->make_immutable }, undef, 'Immutable meta with multiple BUILDs' );

Bar->new;
is_deeply \%called, {'Bar' => 1},
    'single BUILD called with immutable meta';

%called = ();
Baz->new;
is_deeply \%called, {'Bar' => 1, 'Baz' => 1},
    'multiple BUILD called with immutable meta';

%called = ();
Bar->new({__no_BUILD__ => 1});
is_deeply \%called, {},
    'single BUILD skipped with __no_BUILD__ with immutable meta';

%called = ();
Baz->new({__no_BUILD__ => 1});
is_deeply \%called, {},
    'multiple BUILD skipped with __no_BUILD__ with immutable meta';

=pod

Nothing here yet, but soon :)

=cut

done_testing;
