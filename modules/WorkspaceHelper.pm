package WorkspaceHelper;

# ************************************************************
# Description   : Base class and factory for all workspace helpers
# Author        : Chad Elliott
# Create Date   : 9/01/2004
# ************************************************************

# ************************************************************
# Pragmas
# ************************************************************

use strict;

# ************************************************************
# Data Section
# ************************************************************

my(%required) = ();

# ************************************************************
# Subroutine Section
# ************************************************************

sub get {
  my($type) = shift;

  ## Create the helper name
  $type =~ s/Creator/Helper/;
  $type =~ s/=HASH.*//;

  ## If we can find a helper with this name, we will
  ## create a singleton of that type and return it.
  if (!$required{$type}) {
    foreach my $inc (@INC) {
      if (-r "$inc/$type.pm") {
        require "$type.pm";
        $required{$type} = $type->new();
        last;
      }
    }

    ## If we can't find the helper, we just create an
    ## empty helper and return that.
    if (!$required{$type}) {
      $required{$type} = new WorkspaceHelper();
    }
  }

  return $required{$type};
}


sub new {
  my($class) = shift;
  my($self)  = bless {
                     }, $class;
  return $self;
}


sub modify_value {
  my($self)  = shift;
  my($name)  = shift;
  my($value) = shift;
  return $value;
}


sub write_settings {
  return 1, undef;
}


1;
