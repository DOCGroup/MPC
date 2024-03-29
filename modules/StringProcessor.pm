package StringProcessor;

# ************************************************************
# Description   : Perform various algorithms on strings
# Author        : Chad Elliott
# Create Date   : 3/07/2003
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

# ************************************************************
# Subroutine Section
# ************************************************************

sub parse_assignment {
  my($self, $line, $values) = @_;

  ## In MPC, a scope can have spaces in it.  However, it can not end
  ## in a space.
  ## Line may have embedded new lines, so using 's' modifier.
  if ($line =~ /^((\w+[-\s\w]+\w::)*\w+)\s*([\-+]?=)\s*(.*)?/s) {
    my $op = ($3 eq '+=' ? 1 : $3 eq '-=' ? -1 : 0);
    push(@$values, $op, $self->resolve_alias(lc($1)), $4);
    return 1;
  }

  return 0;
}


sub extractType {
  my($self, $name) = @_;
  my $type = $name;

  if ($name =~ /(.*)(Project|Workspace)Creator/) {
    $type = $1;
  }

  return lc($type);
}


sub process_special {
  my($self, $line) = @_;

  ## Replace all escaped double quotes and escaped backslashes
  ## with special characters
  my $escaped = ($line =~ s/\\\\/\01/g);
  $escaped |= ($line =~ s/\\"/\02/g);

  ## Remove any non-escaped double quotes
  $line =~ s/"//g;

  ## Un-escape all other characters.  Using eval allows the user to pass
  ## escaped characters that will be converted to their actual character
  ## counterpart (i.e., \n, \f, etc).
  if (index($line, '\\') != -1) {
    eval("\$line = \"$line\"");
  }

  ## Put the escaped double quotes and backslashes back in
  if ($escaped) {
    $line =~ s/\02/"/g;
    $line =~ s/\01/\\/g;
  }

  return $line;
}


sub create_array {
  my($self, $line) = @_;
  my @array;

  ## Replace all escaped double and single quotes with special
  ## characters.  We need to distinguish between doubly escaped quotes
  ## (<%equote%>) and escaped quotes (\").  We also need to retain the
  ## escaped escape characters.
  my $escaped = ($line =~ s/\\\\\"/\01/g);
  $escaped |= ($line =~ s/\\\'/\02/g);
  $escaped |= ($line =~ s/\\ /\03/g);
  $escaped |= ($line =~ s/\\\t/\04/g);
  $escaped |= ($line =~ s/\\\"/\05/g);
  $escaped |= ($line =~ s/\\\\/\06/g);
  $escaped |= ($line =~ s/\n/\07/g);

  foreach my $part (grep(!/^\s*$/,
                         split(/(\"[^\"]+\"|\'[^\']+\'|\s+)/, $line))) {
    ## Remove enclosing double and single quotes
    $part =~ s/^"(.*)"$/$1/;
    $part =~ s/^'(.*)'$/$1/;

    ## Put any escaped escaped characters back into the string, but
    ## processed to take out one of the escape sequences.
    if ($escaped) {
      $part =~ s/\01/\\"/g;
      $part =~ s/\02/\'/g;
      $part =~ s/\03/ /g;
      $part =~ s/\04/\t/g;
      $part =~ s/\05/\"/g;
      $part =~ s/\06/\\/g;
      $part =~ s/\07/\n/g;
    }

    ## Push it onto the array
    push(@array, $part);
  }

  return \@array;
}


sub crlf {
  #my $self = shift;
  return "\n";
}


sub windows_crlf {
  ## Windows and cygwin require a carriage return and line feed.
  ## However, at some point cygwin changed the way it does output and can
  ## be controlled through an environment variable.
  return ($^O eq 'MSWin32' ||
          ($^O eq 'cygwin' &&
           ($] < 5.008 || (defined $ENV{PERLIO} && $ENV{PERLIO} eq 'crlf'))) ?
           "\n" : "\r\n");
}


sub resolve_alias {
  #my $self = shift;
  #my $name = shift;
  return $_[1];
}

sub fgrep {
  my($str, $array) = @_;
  foreach my $target (@$array) {
    return 1 if ($str eq $target);
  }
  return undef;
}

sub merge {
  # Push each element of @$list on to @$into, unless it's already in @$into.
  my($into, $list) = @_;
  foreach my $in (@$list) {
    push(@$into, $in) if (!fgrep($in, $into));
  }
}

1;
