# $Header$
# RT is (c) 1996-2000 Jesse Vincent (jesse@fsck.com);

use strict;
$ENV{'PATH'} = '/bin:/usr/bin';    # or whatever you need
$ENV{'CDPATH'} = '' if defined $ENV{'CDPATH'};
$ENV{'SHELL'} = '/bin/sh' if defined $ENV{'SHELL'};
$ENV{'ENV'} = '' if defined $ENV{'ENV'};
$ENV{'IFS'} = ''          if defined $ENV{'IFS'};

package RT::Mason;
use HTML::Mason;  # brings in subpackages: Parser, Interp, etc.

use vars qw($VERSION %session);

# List of modules that you want to use from components (see Admin
# manual for details)

  
$VERSION="!!RT_VERSION!!";

use lib "!!RT_LIB_PATH!!";
use lib "!!RT_ETC_PATH!!";

#This drags in  RT's config.pm
use config;
use Carp;
use DBIx::Handle;

{  
    package HTML::Mason::Commands;
    use vars qw(%session);
    
    use RT::Ticket;
    use RT::Tickets;
    use RT::Transaction;
    use RT::Transactions;
    use RT::User;
    use RT::Users;
    use RT::CurrentUser;
    use RT::Template;
    use RT::Templates;
    use RT::Queue;
    use RT::Queues;
    use MIME::Entity;
    use CGI::Cookie;
    use HTML::Entities;
    
    #TODO: make this use DBI
    use Apache::Session::File;
}

#TODO: need to identify the database user here....


my $parser = new HTML::Mason::Parser;




#TODO: Make this draw from the config file

#We allow recursive autohandlers to allow for RT auth.
my $interp = new HTML::Mason::Interp (
            allow_recursive_autohandlers =>1, 
	    parser=>$parser,
            comp_root=>'/opt/rt/WebRT/html',
            data_dir=>'/opt/rt/WebRT/data');
my $ah = new HTML::Mason::ApacheHandler (interp=>$interp);
chown ( [getpwnam('nobody')]->[2], [getgrnam('nobody')]->[2],
        $interp->files_written );   # chown nobody

sub handler {
    my ($r) = @_;


    $RT::Handle = new DBIx::Handle;
    
    $RT::Handle->Connect(Host => $RT::DatabaseHost, 
			 Database => $RT::DatabaseName, 
			 User => $RT::DatabaseUser,
			 Password => $RT::DatabasePassword,
			 Driver => $RT::DatabaseType);
    
    # We don't need to handle non-text items
    return -1 if defined($r->content_type) && $r->content_type !~ m|^text/|io;
    
    
    
    
    #This is all largely cut and pasted from mason's session_handler.pl

    my %cookies = parse CGI::Cookie($r->header_in('Cookie'));
    
    
    eval { 
      tie %HTML::Mason::Commands::session, 'Apache::Session::File',
      ( $cookies{'AF_SID'} ? $cookies{'AF_SID'}->value() : undef );
  };
    
    if ( $@ ) {
      # If the session is invalid, create a new session.
      if ( $@ =~ m#^Object does not exist in the data store# ) {
	   tie %HTML::Mason::Commands::session, 'Apache::Session::File', undef;
	   undef $cookies{'AF_SID'};
      }
    }
    
    if ( !$cookies{'AF_SID'} ) {
      my $cookie = new CGI::Cookie(-name=>'AF_SID', 
				   -value=>$HTML::Mason::Commands::session{_session_id}, 
				   -path => '/',);
      $r->header_out('Set-Cookie', => $cookie);
    }
    
        my $status = $ah->handle_request($r);

    untie %HTML::Mason::Commands::session;
  
    return $status;

  }
1;

