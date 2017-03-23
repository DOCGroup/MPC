package VS2017ProjectCreator;

# ************************************************************
# Description   : A vs2017 (Visual Studio 2017) Project Creator
# Author        : Johnny Willemsen
# Create Date   : 1/04/2016
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use VC12ProjectCreator;

use vars qw(@ISA);
@ISA = qw(VC12ProjectCreator);

## NOTE: We call the constant as a function to support Perl 5.6.
my %info = (Creator::cplusplus() => {'ext'      => '.vcxproj',
                                     'dllexe'   => 'vs2017exe',
                                     'libexe'   => 'vs2017libexe',
                                     'dll'      => 'vs2017dll',
                                     'lib'      => 'vs2017lib',
                                     'template' => [ 'vc10', 'vc10filters' ],
                                    },
           );

my %config = ('vcversion' => '15.00',
              'toolsversion' => '15.0',
             );

# ************************************************************
# Subroutine Section
# ************************************************************

sub get_info_hash {
  my($self, $key) = @_;

  ## If we have the setting in our information map, then use it.
  return $info{$key} if (defined $info{$key});

  ## Otherwise, see if our parent type can take care of it.
  return $self->SUPER::get_info_hash($key);
}

sub get_configurable {
  my($self, $name) = @_;

  ## If we have the setting in our config map, then use it.
  return $config{$name} if (defined $config{$name});

  ## Otherwise, see if our parent type can take care of it.
  return $self->SUPER::get_configurable($name);
}

1;
