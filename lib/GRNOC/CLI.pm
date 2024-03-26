package GRNOC::CLI;

use strict;
use warnings;

use lib '/opt/grnoc/venv/perl-GRNOC-CLI/lib/perl5';
use Carp;

use Term::ProgressBar;
use Term::ReadKey;

our $VERSION = "1.0.3";

=head1 NAME

GRNOC::CLI - A standardize library for common CLI script actions

=head1 SYNOPSIS

The purpose of this module is to standardize and make easy common operations in CLI
run scripts, such as getting user input, showing progress, or clearing the screen.

    use GRNOC::CLI;

    my $cli = GRNOC::CLI->new();

    $cli->clear_screen();

    my $username = $cli->get_input("Username");
    my $password = $cli->get_password("Password");
    my $database = $cli->get_input("Database Name", default => "grnocdb");

    .....

    $cli->start_progress(name  => "Updating Picture Data",
                         count => $num_rows);

    for (my $i = 0; $i < $num_rows; $i++){       
        ....
        $cli->update_progress($i);

        if ($i % 100 == 00){
           $cli->progress_message("Done with $i");
        }
    }

    .....

    my $ok = $cli->confirm("This script is going to delete stuff from " .
                           "the database and can't be undone, are you sure?");

    if(! $ok){
        die "Exiting due to user input";
    }

=cut


=head2 new

Returns an instance of GRNOC::CLI.

=cut

sub new {
    my $that  = shift;
    my $class = ref($that) || $that;

    my %args = (@_);

    my $self = \%args;
   
    bless $self, $class;

    return $self;
}


=head2 clear_screen

Clears the screen on the terminal.

=cut

sub clear_screen {
    my $self = shift;
    system "clear";
}

=head2 get_input

Interactively prompts the user for input on STDIN. Input is read and checked
against the options sent for validation. Input is only returned when it is considered
correct based on options, otherwise user will be automatically reprompted with a note saying why.

=over

=item prompt

A string representing the text to show the user. If options such as noecho or required are given, this text will be automatically expanded to indicate that.

=item options

An optional object of options to control behavior. These are:

=over

=item noecho

Changes terminal mode to 'noecho' so that what is typed by the user is not shown, useful for passwords.

=item default

Provides a default choice for the user. If they do not enter anything this is what the return value will be.

=item pattern

A regex to match input against.

=item required

A boolean indicating whether or not this value is required, ie whether "" is an acceptable value. Defaults to true.

=back

=back

=cut

sub get_input {
    my $self   = shift;
    my $prompt = shift;
    my %opts   = @_;

    my $noecho     = $opts{'noecho'};
    my $default    = $opts{'default'};
    my $pattern    = $opts{'pattern'};
    my $required   = defined $opts{'required'} ? $opts{'required'} : 1;

    while (1){
        print $prompt;
        
        if ($noecho){
            print " (noecho)";
            ReadMode 'noecho';
        }

        if (defined $default){
            print " (default: $default)";
        }

        if ($required){
            print " (required)";
        }

        print ": ";

        my $value = <STDIN>;

        ReadMode 'normal';

        chomp $value;

        if ($value eq ""){
            if (defined $default){
                return $default;
            }

            if ($required){
                print "This value is required and cannot be empty. Try again.\n";
                next;
            }
        }

        if ($pattern){
            if ($value =~ /$pattern/){
                return $value;
            }
            print "Sorry, value must be like \"$pattern\". Try again.\n";
            next;
        }

        return $value;
    }
}


=head2 get_password

A convenience method that calls get_input with the noecho option enabled.

=over

=item prompt

A string representing the text to show the user. If options such as noecho or required are given, this text will be automatically expanded to indicate that.

=back

=cut

sub get_password {
    my $self    = shift;
    my $prompt  = shift;
    my %opts    = @_;

    $opts{'noecho'} = 1;

    my $password = $self->get_input($prompt, %opts);

    print "\n";

    return $password;
}

=head2 confirm

Takes a message in the form of a "yes or no" question and returns 1 or 0 depending on the user's
input. Forces the user to enter "y" or "n" as the response.

=over

=item message

The message to display. This should be in the form of a yes or no question because that is what the
user will be asked to enter.

=item options

An optional object of options to further refine behavior. These are the same set of options as the
"get_input" method takes. The "pattern" option is automatically set to "y|n".

=back

=cut

sub confirm {
    my $self    = shift;
    my $message = shift;
    my %opts    = @_;

    $opts{'pattern'} = '^(y|n|yes|no)$';
    $opts{'default'} = $opts{'default'} || 'n';

    my $answer = $self->get_input($message, %opts);

    if ($answer =~ /y/i){
        return 1;
    }

    return 0;
}

=head2 start_progress

Begins a progress bar display like what you would see with using "yum" command.

=over

=item count

The total number of things to do, such as the number of rows to update or the number of files to scan and process.

=item options

An optional object of options to further refine behavior. These are:

=over

=item name

The title to put near the bar. If not given, defaults to "Progress"

=item eta

A setting for the Term::ProgressBar's ETA option. This can be set to undef to remove the progress bar. This defaults to 'linear' if nothing is given.

=back

=back

=cut

sub start_progress {
    my $self  = shift;
    my $count = shift;
    my %args  = @_;
    
    my %bar_args;
    
    $bar_args{'count'} = $count;
    $bar_args{'name' } = $args{'name'} || "Progress";
    
    if (! exists $args{'eta'}){
        $bar_args{'ETA'} = 'linear';
    }
    else {
        $bar_args{'ETA'} = $args{'eta'};
    }    

    $self->{'progress_bar'} = Term::ProgressBar->new(\%bar_args);
    $self->{'next_update'}  = 0;
}


=head2 update_progress

Updates the progress bar with a new current value. This must be called after start_progress has been called or it will croak. This method transparently handles updating too frequently and is safe to call as often as desired in the script.

=over

=item value

The new value to update to. This must be less than or equal to the count given in start_progress.

=item message

An optional message to print to the screen with this update.

=back

=cut

sub update_progress {
    my $self    = shift;
    my $value   = shift;
    my $message = shift;

    my $bar = $self->{'progress_bar'};

    if (! $bar){
        croak "Cannot call update_progress before start_progress";
    }

    if ($value >= $self->{'next_update'}){
        $self->{'next_update'} = $bar->update($value);
    }

    if ($message){
        $self->progress_message($message);
    }

    return $self->{'next_update'};
}

=head2 progress_message

A method to print a message to the screen without disrupting the progress bar. This method must be called after start_progress or it will croak.

=over

=item message

The string to print

=back

=cut

sub progress_message {
    my $self    = shift;
    my $message = shift;

    my $bar = $self->{'progress_bar'};

    if (! $bar){
        croak "Cannot call progress_messsage before start_progress";
    }

    $bar->message($message);
}

1;
