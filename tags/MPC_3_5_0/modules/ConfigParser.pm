package ConfigParser;

# ************************************************************
# Description   : Reads a generic config file and store the values
# Author        : Chad Elliott
# Create Date   : 6/12/2006
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use Parser;

use vars qw(@ISA);
@ISA = qw(Parser);

# ************************************************************
# Subroutine Section
# ************************************************************

sub new {
  my($class) = shift;
  my($valid) = shift;
  my($self)  = $class->SUPER::new();

  ## Set the values associative array
  $self->{'values'} = {};
  $self->{'valid'}  = $valid;

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
  elsif ($line =~ /^([^=]+)\s*=\s*(.*)$/) {
    my($name)  = $1;
    my($value) = $2;
    $name =~ s/\s+$//;

    ## Pre-process the name and value
    $name = $self->preprocess($name);
    $value = $self->preprocess($value);
    $name =~ s/\\/\//g;

    ## Store the name value pair
    if (!defined $self->{'valid'}) {
      $self->{'values'}->{$name} = $value if ($name ne '');
    }
    elsif (defined $self->{'valid'}->{lc($name)}) {
      $self->{'values'}->{lc($name)} = $value;
    }
    else {
      $status = 0;
      $error  = "Invalid keyword: $name";
    }
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
  return $self->{'values'}->{$tag} || $self->{'values'}->{lc($tag)};
}


sub preprocess {
  my($self) = shift;
  my($str)  = shift;
  while($str =~ /\$([\(\w\)]+)/) {
    my($name) = $1;
    $name =~ s/[\(\)]//g;
    my($val) = $ENV{$name};
    if (!defined $val) {
      $val = '';
      $self->diagnostic("$name was used in the configuration file, " .
                        "but was not defined.");
    }
    $str =~ s/\$([\(\w\)]+)/$val/;
  }
  return $str;
}

1;
