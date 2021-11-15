package VS2022ProjectCreator;

# ************************************************************
# Description   : vs2022 (Visual Studio 2022) Project Creator
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
                                     'dllexe'   => 'vs2022exe',
                                     'libexe'   => 'vs2022libexe',
                                     'dll'      => 'vs2022dll',
                                     'lib'      => 'vs2022lib',
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
