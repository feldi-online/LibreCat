#!/usr/bin/env perl

use lib qw(./lib);
use Catmandu;
use Catmandu::Util;
use App::Helper;
use App::Validator::Department;
use Log::Log4perl;
use Log::Any::Adapter;
use Getopt::Long;
use Carp;
use namespace::clean;

Log::Log4perl::init('log4perl.conf');
Log::Any::Adapter->set('Log4perl');

my $logger = Log::Log4perl->get_logger('department_admin');
my $h      = App::Helper::Helpers->new;

my $cmd = shift;

usage() unless $cmd;

my $ret;

if ($cmd eq 'list') {
    $ret = cmd_list(@ARGV);
}
elsif ($cmd eq 'add') {
    $ret = cmd_add(@ARGV);
}
elsif ($cmd eq 'get') {
    $ret = cmd_get(@ARGV);
}
elsif ($cmd eq 'delete') {
    $ret = cmd_delete(@ARGV);
}
else {
    print STDERR "unknown command - $cmd\n";
    usage();
}

exit($ret);

sub cmd_list {
    my $count = $h->department->each(sub {
        my ($item) = @_;
        my $id       = $item->{_id};
        my $name     = $item->{name};
        my $display  = $item->{display};
        my $layer    = $item->{layer};

        printf "%-2.2d %5d %-40.40s %s\n" 
                    , $layer
                    , $id
                    , $name
                    , $display; 
    });
    print "count: $count\n";
    
    return 0;
}

sub cmd_get {
    my ($id) = @_;

    croak "usage: $0 get <id>" unless defined($id);

    my $data = $h->get_department($id);

    Catmandu->export($data, 'YAML') if $data;

    return $data ? 0 : 2;
}

sub cmd_add {
    my ($file) = @_;

    croak "usage: $0 add <FILE>" unless defined($file) && -r $file;

    my $ret = 0;

    Catmandu->importer('YAML', file => $file)->each( sub {
        my $item = $_[0];
        $ret += _cmd_add($item);        
    });

    return $ret == 0;
}

sub _cmd_add {
    my ($data) = @_;
    
    my $validator = App::Validator::Department->new;

    if ($validator->is_valid($data)) {
        my $result = $h->update_record('department', $data);
        if ($result) {
            print "added " . $data->{_id} . "\n";
            return 0;
        }
        else {
            print "ERROR: add " . $data->{_id} . " failed\n";
            return 2; 
        }
    }
    else {
        print STDERR "ERROR: not a valid researcher\n";
        print STDERR join("\n",@{$validator->last_errors}) , "\n";
        return 2;
    }
}

sub cmd_delete {
    my ($id) = @_;

    croak "usage: $0 delete <id>" unless defined($id);

    my $result = $h->department->delete($id);

    if ($h->department->commit) {
        print "deleted $id\n";
        return 0;
    }
    else {
        print STDERR "ERROR: delete $id failed";
        return 2;
    }
}

sub usage {
    print STDERR <<EOF;
usage: $0 [options] cmd

cmds:
    list
    get <id>
    add <FILE>
    delete <id>

options:

EOF
    exit 1;
}