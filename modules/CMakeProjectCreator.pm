package CMakeProjectCreator;

# ************************************************************
# Description   : A CMake Project Creator
# Author        : Chad Elliott
# Create Date   : 10/10/2022
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use ProjectCreator;

use vars qw(@ISA);
@ISA = qw(ProjectCreator);

# ************************************************************
# Subroutine Section
# ************************************************************

sub pre_generation {
  my $self = shift;

  ## For CMake, we are expecting a hybrid of custom types and modules.
  ## We are turning off all automatic output so that the modules defined
  ## for CMake can handle these artifacts.
  foreach my $gentype (keys %{$self->{'generated_exts'}}) {
    $self->{'generated_exts'}->{$gentype}->{'automatic_out'} = 0;
  }
}

sub default_to_library {
  ## In case there are only generated source files...
  return 1;
}

sub need_to_write_project {
  my $self = shift;

  ## Because we do not automatically add custom output, it is possible that
  ## the project only has generated source files and expects them to cause
  ## an automatic library name to be chosen.  If the base
  ## need_to_write_project() tells us that it's only generated source files
  ## but the user didn't mark this project as "custom only", then we have to
  ## override it back to 1 to retain the user provided target name.
  my $status = $self->SUPER::need_to_write_project();
  if ($status == 2 && !$self->get_assignment('custom_only')) {
    $status = 1;
  }

  return $status;
}

sub get_use_env {
  ## Override the option getter so that, for CMake, MPC always functions as
  ## if the -use_env option was supplied on the command line.
  return 1;
}

sub pre_write_output_file {
  my $self = shift;
  return $self->combine_custom_types();
}

sub dollar_special {
  return 1;
}

sub project_file_prefix {
  return "CMakeLists.";
}

sub escape_spaces {
  #my $self = shift;
  return 1;
}

sub get_dll_exe_template_input_file {
  return 'cmakeexe';
}

sub get_dll_template_input_file {
  return 'cmakedll';
}

sub fill_value {
  my($self, $name) = @_;

  if ($name eq 'language') {
    ## Currently, we only support C++
    return 'CXX' if ($self->get_language() eq Creator::cplusplus());
  }
  elsif ($name =~ /^env_(\w+)/) {
    my $dotdir = '${CMAKE_CURRENT_SOURCE_DIR}' .
                 ($1 eq 'libpaths' ? ' ${CMAKE_CURRENT_BINARY_DIR}' : '');
    my $paths = $self->get_assignment($1);
    if (defined $paths) {
      $paths = $self->create_array($paths);
      foreach my $path (@$paths) {
        if ($path eq '.') {
          $path = $dotdir;
        }
        else {
          $path =~ s/\$\(([^\)]+)\)/\${$1}/g;
        }
      }
      return "@$paths";
    }
  }

  return undef;
}

1;
