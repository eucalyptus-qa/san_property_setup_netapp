#!/usr/bin/perl
use strict;
use Cwd;

$ENV{'PWD'} = getcwd();

# does_It_Have( $arg1, $arg2 )
# does the string $arg1 have $arg2 in it ??
sub does_It_Have{
	my ($string, $target) = @_;
	if( $string =~ /$target/ ){
		return 1;
	};
	return 0;
};



#################### APP SPECIFIC PACKAGES INSTALLATION ##########################

my @ip_lst;
my @distro_lst;
my @source_lst;
my @roll_lst;

my %cc_lst;
my %sc_lst;
my %nc_lst;

my $clc_index = -1;
my $cc_index = -1;
my $sc_index = -1;
my $ws_index = -1;

my $clc_ip = "";
my $cc_ip = "";
my $sc_ip = "";
my $ws_ip = "";

my $nc_ip = "";

my $rev_no = 0;

my $max_cc_num = 0;

$ENV{'EUCALYPTUS'} = "/opt/eucalyptus";

#### read the input list

my $index = 0;

open( LIST, "../input/2b_tested.lst" ) or die "$!";

my $is_memo = 0;
my $memo = "";

my $line;
while( $line = <LIST> ){
	chomp($line);

	if( $is_memo ){
		if( $line ne "END_MEMO" ){
			$memo .= $line . "\n";
		}else{
			$is_memo = 0;
		};
	}elsif( $line =~ /^([\d\.]+)\s+(.+)\s+(.+)\s+(\d+)\s+(.+)\s+\[([\w\s\d]+)\]/ ){
		print "IP $1 with $2 distro is built from $5 as Eucalyptus-$6\n";
		push( @ip_lst, $1 );
		push( @distro_lst, $2 );
		push( @source_lst, $5 );
		push( @roll_lst, $6 );

		my $this_roll = $6;

		if( does_It_Have($this_roll, "CLC") ){
			$clc_index = $index;
			$clc_ip = $1;
		};

		if( does_It_Have($this_roll, "CC") ){
			$cc_index = $index;
			$cc_ip = $1;

			if( $this_roll =~ /CC(\d+)/ ){
				$cc_lst{"CC_$1"} = $cc_ip;
				if( $1 > $max_cc_num ){
					$max_cc_num = $1;
				};
			};			
		};

		if( does_It_Have($4, "SC") ){
			$sc_index = $index;
			$sc_ip = $1;

			if( $this_roll =~ /SC(\d+)/ ){
                                $sc_lst{"SC_$1"} = $sc_ip;
                        };
		};

		if( does_It_Have($4, "WS") ){
                        $ws_index = $index;
                        $ws_ip = $1;
                };

		if( does_It_Have($4, "NC") ){
                        #$nc_ip = $nc_ip . " " . $1;
			$nc_ip = $1;
			if( $this_roll =~ /NC(\d+)/ ){
				if( $nc_lst{"NC_$1"} eq	 "" ){
                                	$nc_lst{"NC_$1"} = $nc_ip;
				}else{
					$nc_lst{"NC_$1"} = $nc_lst{"NC_$1"} . " " . $nc_ip;
				};
                        };
                };


		$index++;
        }elsif( $line =~ /^BZR_REVISION\s+(\d+)/  ){
		$rev_no = $1;
		print "REVISION NUMBER is $rev_no\n";
	}elsif( $line =~ /^BZR_BRANCH\s+(.+)/ ){
			my $temp = $1;
			if( $temp =~ /eucalyptus\/(.+)/ ){
				$ENV{'QA_BZR_DIR'} = $1; 
			};
	}elsif( $line =~ /^MEMO/ ){
		$is_memo = 1;
	}elsif( $line =~ /^END_MEMO/ ){
		$is_memo = 0;
	};
};

close( LIST );

$ENV{'QA_MEMO'} = $memo;

if( $source_lst[0] eq "PACKAGE" || $source_lst[0] eq "REPO" ){
	$ENV{'EUCALYPTUS'} = "";
};

if( $rev_no == 0 ){
	print "Could not find the REVISION NUMBER\n";
};

if( $clc_ip eq "" ){
	print "Could not find the IP of CLC\n";
};

if( $cc_ip eq "" ){
        print "Could not find the IP of CC\n";
};

if( $sc_ip eq "" ){
        print "Could not find the IP of SC\n";
};

if( $ws_ip eq "" ){
        print "Could not find the IP of WS\n";
};

if( $nc_ip eq "" ){
        print "Could not find the IP of NC\n";
};

chomp($nc_ip);


### Download Admin Credentials

print "$clc_ip :: rm -f /root/admin_cred.zip\n";
system("ssh -o StrictHostKeyChecking=no root\@$clc_ip \"rm -f /root/admin_cred.zip\" ");
sleep(1);


print "$clc_ip :: $ENV{'EUCALYPTUS'}/usr/sbin/euca_conf --get-credentials admin_cred.zip; unzip -o ./admin_cred.zip\n";
system("ssh -o StrictHostKeyChecking=no root\@$clc_ip \"cd /root; $ENV{'EUCALYPTUS'}/usr/sbin/euca_conf --get-credentials admin_cred.zip; unzip -o ./admin_cred.zip\" ");
sleep(5);


### Check SAN option

my $san_provider = "NO-SAN";

if( is_san_provider_from_memo() == 1 ){
	$san_provider = $ENV{'QA_MEMO_SAN_PROVIDER'};
};

my $bzr = $ENV{'QA_BZR_DIR'};

#if( $bzr =~ /eee-2\.0/ ){

if( $san_provider eq "NetappProvider" ){

	print "$clc_ip :: source /root/eucarc; $ENV{'EUCALYPTUS'}/usr/sbin/euca-modify-property -p PARTI00.storage.sanhost=192.168.5.191\n";
	system("ssh -o StrictHostKeyChecking=no root\@$clc_ip \"source /root/eucarc; $ENV{'EUCALYPTUS'}/usr/sbin/euca-modify-property -p PARTI00.storage.sanhost=192.168.5.191\" ");
	sleep(1);


	print "$clc_ip :: source /root/eucarc; $ENV{'EUCALYPTUS'}/usr/sbin/euca-modify-property -p PARTI00.storage.sanuser=root\n";
	system("ssh -o StrictHostKeyChecking=no root\@$clc_ip \"source /root/eucarc; $ENV{'EUCALYPTUS'}/usr/sbin/euca-modify-property -p PARTI00.storage.sanuser=root\" ");
	sleep(1);


	print "$clc_ip :: source /root/eucarc; $ENV{'EUCALYPTUS'}/usr/sbin/euca-modify-property -p PARTI00.storage.sanpassword=zoomzoom\n";
	system("ssh -o StrictHostKeyChecking=no root\@$clc_ip \"source /root/eucarc; $ENV{'EUCALYPTUS'}/usr/sbin/euca-modify-property -p PARTI00.storage.sanpassword=zoomzoom\" ");
	sleep(1);

}elsif( $san_provider eq "EquallogicProvider" ){

	print "$clc_ip :: source /root/eucarc; $ENV{'EUCALYPTUS'}/usr/sbin/euca-modify-property -p PARTI00.storage.sanhost=192.168.7.189\n";
	system("ssh -o StrictHostKeyChecking=no root\@$clc_ip \"source /root/eucarc; $ENV{'EUCALYPTUS'}/usr/sbin/euca-modify-property -p PARTI00.storage.sanhost=192.168.7.189\" ");
	sleep(1);


	print "$clc_ip :: source /root/eucarc; $ENV{'EUCALYPTUS'}/usr/sbin/euca-modify-property -p PARTI00.storage.sanuser=grpadmin\n";
	system("ssh -o StrictHostKeyChecking=no root\@$clc_ip \"source /root/eucarc; $ENV{'EUCALYPTUS'}/usr/sbin/euca-modify-property -p PARTI00.storage.sanuser=grpadmin\" ");
	sleep(1);


	print "$clc_ip :: source /root/eucarc; $ENV{'EUCALYPTUS'}/usr/sbin/euca-modify-property -p PARTI00.storage.sanpassword=zoomzoom\n";
	system("ssh -o StrictHostKeyChecking=no root\@$clc_ip \"source /root/eucarc; $ENV{'EUCALYPTUS'}/usr/sbin/euca-modify-property -p PARTI00.storage.sanpassword=zoomzoom\" ");
	sleep(1);

}else{
	print "NO-SAN setup needed";
};




print "\nDONE\n";

exit(0);

1;



sub is_san_provider_from_memo{
	if( $ENV{'QA_MEMO'} =~ /SAN_PROVIDER=(.+)\n/ ){
		my $extra = $1;
		$extra =~ s/\r//g;
		print "FOUND in MEMO\n";
		print "SAN_PROVIDER=$extra\n";
		$ENV{'QA_MEMO_SAN_PROVIDER'} = $extra;
		return 1;
	};
	return 0;
};


1;

