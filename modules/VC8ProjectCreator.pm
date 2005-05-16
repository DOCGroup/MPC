package VC8ProjectCreator;

# ************************************************************
# Description   : A VC8 Project Creator
# Author        : Johnny Willemsen
# Create Date   : 4/21/2004
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use VC7ProjectCreator;

use vars qw(@ISA);
@ISA = qw(VC7ProjectCreator);

my(%info) = ('cplusplus' => {'ext'      => '.vcproj',
                             'dllexe'   => 'vc8exe',
                             'libexe'   => 'vc8libexe',
                             'dll'      => 'vc8dll',
                             'lib'      => 'vc8lib',
                             'template' => 'vc8',
                            },
            );

# ************************************************************
# Subroutine Section
# ************************************************************

sub get_configurable {
  my($self)   = shift;
  my($name)   = shift;
  my(%config) = ('vcversion' => '8.00',
                );
  return $config{$name};
}

sub get_info_hash {
  my($self) = shift;
  my($key)  = shift;

  if (defined $info{$key})  {
    return $info{$key};
  }
  return $self->SUPER::get_info_hash($key);
}

1;
