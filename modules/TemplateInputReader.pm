package TemplateInputReader;

# ************************************************************
# Description   : Reads the template input and stores the values
# Author        : Chad Elliott
# Create Date   : 5/16/2002
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

use Parser;

use vars qw(@ISA);
@ISA = qw(Parser);

# ************************************************************
# Data Section
# ************************************************************

my($mpt)  = 'mpt';

# ************************************************************
# Subroutine Section
# ************************************************************

sub new {
  my($class) = shift;
  my($inc)   = shift;
  my($self)  = Parser::new($class, $inc);

  $self->{'values'}    = {};
  $self->{'cindex'}    = 0;
  $self->{'current'}   = [ $self->{'values'} ];
  $self->{'realnames'} = {};

  return $self;
}


sub parse_line {
  my($self)        = shift;
  my($ih)          = shift;
  my($line)        = shift;
  my($status)      = 1;
  my($errorString) = undef;
  my($current)     = $self->{'current'};

  if ($line eq '') {
  }
  elsif ($line =~ /^([\w\s]+)\s*{$/) {
    ## Entering a new scope
    my($rname) = $1;
    $rname =~ s/\s+$//;
    my($name) = lc($rname);
    $self->{'realnames'}->{$name} = $rname;

    if (!defined $$current[$self->{'cindex'}]->{$name}) {
      $$current[$self->{'cindex'}]->{$name} = {};
    }
    push(@$current, $$current[$self->{'cindex'}]->{$name});
    $self->{'cindex'}++;
  }
  elsif ($line =~ /^}$/) {
    if ($self->{'cindex'} > 0) {
      pop(@$current);
      $self->{'cindex'}--;
    }
    else {
      $status = 0;
      $errorString = 'Unmatched curly brace';
    }
  }
  elsif ($line =~ /^(\w+)\s*(\+=|=)\s*(.*)?/) {
    my($name)  = lc($1);
    my($op)    = $2;
    my($value) = $3;

    if (defined $value) {
      $value = $self->create_array($value);
    }
    else {
      $value = [];
    }

    if ($op eq '+=' && defined $$current[$self->{'cindex'}]->{$name}) {
      push(@{$$current[$self->{'cindex'}]->{$name}}, @$value);
    }
    else {
      $$current[$self->{'cindex'}]->{$name} = $value;
    }
  }
  elsif ($line =~ /^conditional_include\s+"([\w\s\-\+\/\\\.]+)"$/) {
    my($file) = $self->search_include_path("$1.$mpt");
    if (defined $file) {
      my($ol) = $self->get_line_number();
      ($status, $errorString) = $self->read_file($file);
      $self->set_line_number($ol);
    }
  }
  else {
    $status = 0;
    $errorString = "Unrecognized line: $line";
  }

  return $status, $errorString;
}


sub get_value {
  my($self) = shift;
  my($tag)  = shift;
  return $self->{'values'}->{lc($tag)};
}


sub get_realname {
  my($self) = shift;
  my($tag)  = shift;
  return $self->{'realnames'}->{lc($tag)};
}


1;
