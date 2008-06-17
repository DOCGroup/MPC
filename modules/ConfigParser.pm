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
  my($class, $valid) = @_;
  my $self = $class->SUPER::new();

  ## Set the values associative array
  $self->{'values'} = {};
  $self->{'valid'}  = $valid;
  $self->{'warned'} = {};

  return $self;
}


sub parse_line {
  my($self, $if, $line) = @_;
  my $status = 1;
  my $error;

  if ($line eq '') {
  }
  elsif ($line =~ /^([^=]+)\s*=\s*(.*)$/) {
    my $name  = $1;
    my $value = $2;
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
  my @names = keys %{$_[0]->{'values'}};
  return \@names;
}


sub get_value {
  my($self, $tag) = @_;
  return $self->{'values'}->{$tag} || $self->{'values'}->{lc($tag)};
}


sub preprocess {
  my($self, $str) = @_;
  while($str =~ /\$([\(\w\)]+)/) {
    my $name = $1;
    $name =~ s/[\(\)]//g;
    my $val = $ENV{$name};
    if (!defined $val) {
      $val = '';
      if (!defined $self->{'warned'}->{$name}) {
        $self->diagnostic("$name was used in the configuration file, " .
                          "but was not defined.");
        $self->{'warned'}->{$name} = 1;
      }
    }
    $str =~ s/\$([\(\w\)]+)/$val/;
  }
  return $str;
}

1;
