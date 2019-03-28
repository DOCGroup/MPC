package VS2019ProjectCreator;

# ************************************************************
# Description   : A vs2019 (Visual Studio 2019) Project Creator
# Author        : Johnny Willemsen
# Create Date   : 28/03/2010
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
                                     'dllexe'   => 'vs2019exe',
                                     'libexe'   => 'vs2019libexe',
                                     'dll'      => 'vs2019dll',
                                     'lib'      => 'vs2019lib',
                                     'template' => [ 'vc10', 'vc10filters' ],
                                    },
           );

my %config = ('vcversion' => '16.00',
              'toolsversion' => '16.0',
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
