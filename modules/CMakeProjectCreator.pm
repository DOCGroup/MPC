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
# Data Section
# ************************************************************

## NOTE: We call the constant as a function to support Perl 5.6.
my %info = (Creator::cplusplus() => {'template' => 'cmake'});

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

sub dollar_special {
  return 1;
}

sub project_file_prefix {
  return "CMakeLists.";
}

sub languageSupported {
  return defined $info{$_[0]->get_language()};
}

sub escape_spaces {
  #my $self = shift;
  return 1;
}

sub get_template {
  return $info{$_[0]->get_language()}->{'template'};
}

sub fill_value {
  my($self, $name) = @_;

  if ($name eq 'language') {
    ## Currently, we only support C++
    return 'CXX' if ($self->get_language() eq Creator::cplusplus());
  }
  elsif ($name =~ /^env_(\w+)/) {
    my $dotdir = ($1 eq 'libpaths' ? '${CMAKE_CURRENT_BIN_DIR}' :
                                     '${CMAKE_CURRENT_SOURCE_DIR}');
    my $paths = $self->get_assignment($1);
    if (defined $paths) {
      $paths = $self->create_array($paths);
      foreach my $path (@$paths) {
        if ($path eq '.') {
          $path = $dotdir;
        }
        else {
          $path =~ s/\$\(([^\)]+)\)/\$ENV{$1}/g;
        }
      }
      return "@$paths";
    }
  }

  return undef;
}

1;
