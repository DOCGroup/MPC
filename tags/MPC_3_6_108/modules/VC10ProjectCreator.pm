package VC10ProjectCreator;

# ************************************************************
# Description   : A VC10 Project Creator
# Author        : Johnny Willemsen
# Create Date   : 11/10/2008
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use VC8ProjectCreator;

use vars qw(@ISA);
@ISA = qw(VC8ProjectCreator);

my %config = ('vcversion' => '9.00');

# ************************************************************
# Subroutine Section
# ************************************************************

sub get_configurable {
  my($self, $name) = @_;
  return $config{$name};
}

1;
