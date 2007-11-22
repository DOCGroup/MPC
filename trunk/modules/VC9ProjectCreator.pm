package VC9ProjectCreator;

# ************************************************************
# Description   : A VC9 Project Creator
# Author        : Johnny Willemsen
# Create Date   : 4/21/2004
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use VC8ProjectCreator;

use vars qw(@ISA);
@ISA = qw(VC8ProjectCreator);

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
             'java'   => {'ext'      => '.vjsproj',
                          'dllexe'   => 'vc8java',
                          'libexe'   => 'vc8java',
                          'dll'      => 'vc8java',
                          'lib'      => 'vc8java',
                          'template' => 'vc8java',
                         },
             'vb'     => {'ext'      => '.vbproj',
                          'dllexe'   => 'vc8vb',
                          'libexe'   => 'vc8vb',
                          'dll'      => 'vc8vb',
                          'lib'      => 'vc8vb',
                          'template' => 'vc8vb',
                         },
            );

my(%config) = ('vcversion' => '9.00',
              );

# ************************************************************
# Subroutine Section
# ************************************************************

sub webapp_supported {
  #my($self) = shift;
  return 1;
}


sub require_dependencies {
  ## With vc8, they fixed it such that static libraries that depend on
  ## other static libraries will not be included into the target library
  ## by default.  Way to go Microsoft!
  return 1;
}

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

  return $self->SUPER::translate_value($key, $val);
}

1;
