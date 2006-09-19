package GHSProjectCreator;

# ************************************************************
# Description   : A GHS project creator for version 4.x.
#                 By default, this module assumes Multi will
#                 be used on Windows.  If it is not, you must
#                 set the MPC_GHS_UNIX environment variable.
# Author        : Chad Elliott
# Create Date   : 4/19/2002
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

my($startre) = undef;
my($ghsunix) = 'MPC_GHS_UNIX';

# ************************************************************
# Subroutine Section
# ************************************************************

sub convert_slashes {
  return (defined $ENV{$ghsunix} ? 0 : 1);
}


sub case_insensitive {
  return (defined $ENV{$ghsunix} ? 0 : 1);
}


sub use_win_compatibility_commands {
  return (defined $ENV{$ghsunix} ? 0 : 1);
}


sub post_file_creation {
  my($self) = shift;

  ## These special files are only used if it is a custom only project or
  ## there are no source files in the project.
  if ((defined $self->get_assignment('custom_only') ||
       !defined $self->get_assignment('source_files')) &&
      defined $self->get_assignment('custom_types')) {
    my($fh) = new FileHandle();
    if (open($fh, ">.custom_build_rule")) {
      print $fh ".empty_html_file\n";
      close($fh);
    }
    if (open($fh, ">.empty_html_file")) {
      close($fh);
    }
  }
}

sub compare_output {
  #my($self) = shift;
  return 1;
}


sub project_file_extension {
  #my($self) = shift;
  return '.gpj';
}


sub fill_value {
  my($self)  = shift;
  my($name)  = shift;
  my($value) = undef;

  if (!defined $startre) {
    $startre = $self->escape_regex_special($self->getstartdir());
  }

  if ($name =~ /^reltop_(\w+)/) {
    $value = $self->relative($self->get_assignment($1));
    if (defined $value) {
      my($part) = $self->getcwd();
      $part =~ s/^$startre[\/]?//;
      if ($part ne '') {
        if ($value eq '.') {
          $value = $part;
        }
        else {
          $value = $part . '/' . $value;
        }
      }
    }
  }
  elsif ($name eq 'reltop') {
    $value = $self->getcwd();
    $value =~ s/^$startre[\/]?//;
    if ($value eq '') {
      $value = '.';
    }
  }
  elsif ($name eq 'slash') {
    $value = (defined $ENV{$ghsunix} ? '/' : '\\');
  }
  else {
    if (!defined $ENV{$ghsunix}) {
      if ($name eq 'postmkdir') {
        $value = ' || type nul';
      }
    }
  }

  return $value;
}

sub get_dll_exe_template_input_file {
  #my($self) = shift;
  return 'ghsdllexe';
}


sub get_lib_exe_template_input_file {
  #my($self) = shift;
  return 'ghslibexe';
}


sub get_lib_template_input_file {
  #my($self) = shift;
  return 'ghslib';
}


sub get_dll_template_input_file {
  #my($self) = shift;
  return 'ghsdll';
}


1;
