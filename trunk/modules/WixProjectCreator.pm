package WixProjectCreator;

# ************************************************************
# Description   : A Wix Project Creator
# Author        : James H. Hill
# Create Date   : 6/23/2009
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
use ProjectCreator;
use XMLProjectBase;
use GUID;

use vars qw(@ISA);
@ISA = qw(ProjectCreator);

# ************************************************************
# Data Section
# ************************************************************

my %names = ('cppdir' => 'source_files',
             'rcdir'  => 'resource_files');

# ************************************************************
# Subroutine Section
# ************************************************************

sub expand_variables_from_template_values {
  return 1;
}

sub convert_slashes {
  return 0;
}

sub fill_value {
  my($self, $name) = @_;

  if ($name eq 'guid') {
    ## Return a repeatable GUID for use within the template.  The values
    ## provided will be hashed and returned in a format expected by Wix.
    return GUID::generate($self->project_file_name(),
                          $self->{'current_input'}, $self->getcwd());
  }
  elsif ($name eq 'source_directory') {
    my($source);

    if ($self->get_assignment('sharedname')) {
      $source = $self->get_assignment('dllout');

      if ($source eq '') {
        $source = $self->get_assignment('libout');
      }
    }
    elsif ($self->get_assignment('staticname')) {
      $source = $self->get_assignment('libout');
    }
    else {
      $source = $self->get_assignment('install');
    }

    ## Check for a variable in the source directory. We have to make
    ## sure we transform this correctly for WIX by adding the correct
    ## prefix. Otherwise, WIX will complain.
    if ($source =~ /.*?\$\((.+?)\).*/) {
      my($prefix);
      my($varname) = $1;

      if ($ENV{$varname}) {
        $prefix = "env";
      }
      else {
        $prefix = "var";
      }

      ## Add the correct prefix to the variable.
      $_ = $source;
      s/$1/$prefix.$varname/g;
      $source = $_;
    }

    return $source;
  }
  elsif (defined $names{$name}) {
    my %dirnames = ('.' => 1);
    foreach my $file ($self->get_component_list($names{$name}, 1)) {
      my $dirname = $self->mpc_dirname($file);
      if ($dirname eq '') {
        $dirname = '.';
      }
      else {
        $dirname =~ s/\//\\/g;
      }
      $dirnames{$dirname} = 1;
    }

    ## Sort the directories to ensure that '.' comes first
    return join(';', sort keys %dirnames);
  }

  return undef;
}

sub project_file_extension {
  return '.wxi';
}


sub get_dll_exe_template_input_file {
  #my $self = shift;
  return 'wix';
}


sub get_lib_exe_template_input_file {
  #my $self = shift;
  return 'wix';
}


sub get_lib_template_input_file {
  #my $self = shift;
  return 'wix';
}


sub get_dll_template_input_file {
  #my $self = shift;
  return 'wix';
}

sub get_template {
  return 'wix';
}

1;
