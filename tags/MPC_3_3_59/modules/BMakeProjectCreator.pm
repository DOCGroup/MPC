package BMakeProjectCreator;

# ************************************************************
# Description   : A BMake Project Creator
# Author        : Chad Elliott
# Create Date   : 2/03/2004
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use ProjectCreator;
use WinProjectBase;
use MakeProjectBase;

use vars qw(@ISA);
@ISA = qw(MakeProjectBase WinProjectBase ProjectCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub fill_value {
  my($self)  = shift;
  my($name)  = shift;
  my($value) = undef;
  my(%names) = ('cppdir' => 'source_files',
                'rcdir'  => 'resource_files',
               );

  if (defined $names{$name}) {
    my(%dirnames) = ('.' => 1);
    foreach my $file ($self->get_component_list($names{$name}, 1)) {
      my($dirname) = $self->mpc_dirname($file);
      if ($dirname eq '') {
        $dirname = '.';
      }
      else {
        $dirname = $self->slash_to_backslash($dirname);
      }
      $dirnames{$dirname} = 1;
    }

    ## Sort the directories to ensure that '.' comes first
    $value = join(';', sort keys %dirnames);
  }

  return $value;
}


sub get_and_symbol {
  #my($self) = shift;
  return '&$(__TRICK_BORLAND_MAKE__)&';
}

sub project_file_extension {
  #my($self) = shift;
  return '.bmak';
}


sub get_dll_exe_template_input_file {
  #my($self) = shift;
  return 'bmakedllexe';
}


sub get_lib_exe_template_input_file {
  #my($self) = shift;
  return 'bmakelibexe';
}


sub get_lib_template_input_file {
  #my($self) = shift;
  return 'bmakelib';
}


sub get_dll_template_input_file {
  #my($self) = shift;
  return 'bmakedll';
}


1;
