package AutomakeProjectCreator;

# ************************************************************
# Description   : A Automake Project Creator
# Author        : J.T. Conklin & Chad Elliott
# Create Date   : 2/26/2003
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

sub dollar_special {
  #my($self) = shift;
  return 1;
}


sub expand_variables_from_template_values {
  #my($self) = shift;
  return 0;
}


sub sort_files {
  #my($self) = shift;
  return 1;
}


sub convert_slashes {
  #my($self) = shift;
  return 0;
}


sub fill_value {
  my($self)  = shift;
  my($name)  = shift;
  my($value) = undef;

  if ($name eq 'vpath') {
    my(%vpath) = ();
    my($names) = $self->{'source_files'};
    foreach my $name (keys %$names) {
      my($comps) = $$names{$name};
      foreach my $key (keys %$comps) {
        foreach my $item (@{$$comps{$key}}) {
          my($dname) = $self->relative($self->mpc_dirname($item));
          if ($dname ne '.' && $dname !~ /^\.\.\//) {
            $vpath{$dname} = 1;
          }
        }
      }
    }
    my($str) = join(':', keys %vpath);
    if ($str ne '') {
      $value = 'VPATH = .:' . $str . $self->crlf();
    }
  }
  elsif ($name eq 'am_includes') {
    my($incs) = $self->get_assignment('includes');
    if (defined $incs) {
      my(@vec) = split(' ', $incs);
      foreach(@vec) {
        if (/^[^\$\/]/) {
          $_ = '$(srcdir)/' . $_;
        }
      }

      $value = \@vec;
    }
  }
  elsif ($name eq 'rev_avoids') {
    my($avoids) =  $self->get_assignment('avoids');
    if (defined $avoids) {
      $value = join(' ', reverse split(' ', $avoids));
    }
  }
  elsif ($name eq 'rev_requires') {
    my($requires) =  $self->get_assignment('requires');
    if (defined $requires) {
      $value = join(' ', reverse split(' ', $requires));
    }
  }
  elsif ($name eq 'tao') {
    my($incs) = $self->get_assignment('includes');
    my($libs) = $self->get_assignment('libpaths');
    if ((defined $incs && $incs =~ /tao/i) ||
        (defined $libs && $libs =~ /tao/i)) {
      $value = 1;
    }
  }
  elsif ($name eq 'am_version') {
    $value = $self->get_assignment('version');
    if (defined $value) {
      if (($value =~ tr/./:/) < 2) {
        $value .= ':0';
      }
    }
  }

  return $value;
}


sub project_file_name {
  my($self) = shift;
  my($name) = shift;

  if (!defined $name) {
    $name = $self->project_name();
  }

  return $self->get_modified_project_file_name('Makefile' .
                                               ($name eq '' ? '' : ".$name"),
                                               '.am');
}


sub get_dll_exe_template_input_file {
  #my($self) = shift;
  return 'automakeexe';
}


sub get_dll_template_input_file {
  #my($self) = shift;
  return 'automakedll';
}


sub get_template {
  #my($self) = shift;
  return 'automake';
}


1;
