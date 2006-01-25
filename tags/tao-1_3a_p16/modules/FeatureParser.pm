package FeatureParser;

# ************************************************************
# Description   : Reads the feature files and store the values
# Author        : Chad Elliott
# Create Date   : 5/21/2003
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;
use File::Basename;

use Parser;

use vars qw(@ISA);
@ISA = qw(Parser);

# ************************************************************
# Subroutine Section
# ************************************************************

sub new {
  my($class)    = shift;
  my($features) = shift;
  my(@files)    = @_;
  my($self)     = $class->SUPER::new();

  ## Set the values associative array
  $self->{'values'} = {};

  ## Process each feature file
  foreach my $f (@files) {
    if (defined $f) {
      my($status, $warn) = $self->cached_file_read($f);
      if (!$status) {
        ## We only want to warn the user about problems
        ## with the feature file.
        my($lnumber) = $self->get_line_number();
        $self->warning(basename($f) . ": line $lnumber: $warn");
      }
    }
  }

  ## Process each feature definition
  foreach my $feature (@$features) {
    my($status, $warn) = $self->parse_line(undef, $feature);
    if (!$status) {
      ## We only want to warn the user about problems
      ## with the -feature option.
      $self->warning("-features parameter: $warn");
    }
  }

  return $self;
}


sub parse_line {
  my($self)   = shift;
  my($if)     = shift;
  my($line)   = shift;
  my($status) = 1;
  my($error)  = undef;

  if ($line eq '') {
  }
  elsif ($line =~ /^(\w+)\s*=\s*(\d+)$/) {
    $self->{'values'}->{lc($1)} = $2;
  }
  else {
    $status = 0;
    $error  = "Unrecognized line: $line";
  }

  return $status, $error;
}


sub get_names {
  my($self)  = shift;
  my(@names) = keys %{$self->{'values'}};
  return \@names;
}


sub get_value {
  my($self) = shift;
  my($tag)  = shift;
  return $self->{'values'}->{lc($tag)};
}


1;
