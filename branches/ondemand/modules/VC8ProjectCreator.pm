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
             'csharp' => {'ext'      => '.csproj',
                          'dllexe'   => 'vc8csharp',
                          'libexe'   => 'vc8csharp',
                          'dll'      => 'vc8csharp',
                          'lib'      => 'vc8csharp',
                          'template' => 'vc8csharp',
                         },
            );

my(%config) = ('vcversion' => '8.00',
              );

# ************************************************************
# Subroutine Section
# ************************************************************

sub post_file_creation {
  my($self) = shift;
  my($file) = shift;

  ## VC8 stores information in a .user file that may conflict
  ## with information stored in the project file.  If we have
  ## created a new project file, we will remove the corresponding
  ## .user file to avoid strange conflicts.
  unlink("$file.user");
}

sub get_configurable {
  my($self)   = shift;
  my($name)   = shift;
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

sub translate_value {
  my($self) = shift;
  my($key)  = shift;
  my($val)  = shift;

  if ($key eq 'platform' && $val eq 'AnyCPU') {
    ## Microsoft uses AnyCPU in the project file, but
    ## uses Any CPU in the solution file.
    $val = 'Any CPU';
  }

  return $val;
}

1;
