package MakeDependencyWriter;

# ************************************************************
# Description   : Generates generic Makefile dependencies.
# Author        : Chad Elliott
# Create Date   : 2/10/2002
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
use DependencyWriter;

use vars qw(@ISA);
@ISA = qw(DependencyWriter);

# ************************************************************
# Data Section
# ************************************************************

my $cygwin = (defined $ENV{OS} && $ENV{OS} =~ /windows/i);

# ************************************************************
# Subroutine Section
# ************************************************************

sub new {
  my $self = DependencyWriter::new(@_);
  if ($ENV{MPC_DEPGEN_EXCLUDE}) {
    $self->{exclude} = [split(' ', $ENV{MPC_DEPGEN_EXCLUDE})];
  }
  return $self;
}

sub process {
  my($self, $target, $deps) = @_;

  if (exists $self->{exclude}) {
    for my $excl (@{$self->{exclude}}) {
      @$deps = grep {$_ !~ /$excl/} @$deps;
    }
  }

  ## Replace whitespace with escaped whitespace.
  map(s/(\s)/\\$1/g, @{$deps});

  ## Replace <drive letter>: with /cygdrive/<drive letter>.  The user may
  ## or may not be using Cygwin, but leaving the colon in there will
  ## cause make to fail catastrophically on the next invocation.
  map(s/([A-Z]):/\/cygdrive\/$1/gi, @{$deps}) if ($cygwin);

  ## Sort the dependencies to make them reproducible.
  return "@{$target}: \\\n  " . join(" \\\n  ", sort @{$deps}) . "\n";
}


1;
