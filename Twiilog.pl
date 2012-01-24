#! /usr/bin/perl
use User::Utmp;
use Net::Twitter;
use Scalar::Util 'blessed';
use Net::XMPP;


##########################################################################################################################
######################################  User interface ############# ##################################################
#######################################################################################################################
$name_network_cart='eth0'; # name interface from which get traffic.(required)
$statuses_count = 980;
$hostname = "sqrt";  #### vps domain|hostname
$data_dump='data.dump';
$servers_count = "1"; #### vps count
$time_const = int(3600 / (int(int($statuses_count / $servers_count) / 24)));  ###### Timeout outside code
$time_const_direct = int(3600 / int(130 / $servers_count)); ######### Timeout inside code
$loglevel = 1;
$dir_mess_service = "on";
$dir_mess_stat = "on";
$dir_mess_top_proc = "off";
$dir_mess_last_user = "off";
$default_stat = "on";
$default_services = "on";
$dir_default_stat_on = "list stat on";
$dir_default_stat_off = "list stat off";
$dir_default_services_on = "list services on";
$dir_default_services_off = "list services off";
$dir_mess_proc_command = "list proc";
$dir_mess_lastuser_command = "last user";
$dir_mess_stat_command = "list stat";
$dir_mess_service_command = "list services";
$dir_timeout = "timeout=";
######  System interface #########
$cpu_path = "/proc/stat";
$mem_path = "/proc/meminfo";
$uptime_path = "/proc/uptime";
$avg_path = "/proc/loadavg";
$network_sock_path = "/proc/net/sockstat"; 
$network_dev_path = "/proc/net/dev"; 
#########  Twitter auth keys ########

my $nt = Net::Twitter->new(legacy => 0);
my $nt = Net::Twitter->new(
    traits   => [qw/OAuth API::REST/],
    consumer_key        => 'EfTt1XNeVB7Ph5eSZFYZg',
    consumer_secret     => 'lkVCIXeqWSoJrKnqPYQ9fSmXjcHyoEbPPFvTUsKHZc',
    access_token        => '399375464-N2FMhZsOo39vXPLnIJn3iecOOoqvpFdhhc2xeUmL',
    access_token_secret => '4H1OFYx4FeUW6czzB04pRXsK1YgEvxsfGYnfMxSe4c',
);


while(1)
{
$ttime = 0;
###########   Direct message functions ######### 
while($ttime <= $time_const)
{

$dir_mess_service = "off";
$dir_mess_stat = "off";
$dir_mess_top_proc = "off";
$dir_mess_last_user = "off";

$kk = 0;
eval {
my $direct = $nt->direct_messages({ since_id => '2011-01-01', count => 100 });
 for my $status ( @$direct ) {
        #print "$status->{created_at} <$status->{user}{screen_name}> $status->{text}\n";
	$direct_mass_text[$kk] = $status->{'text'};
	$direct_mass[$kk] = $status->{'id'};
	$kk++; 
    }
};
for($ii=0; $ii<$kk; $ii++) 
 {  
  if($direct_mass_text[$ii] eq $dir_mess_lastuser_command)    
   {    
    $dir_mess_last_user = "on";  
   }
  if($direct_mass_text[$ii] eq $dir_mess_proc_command)
   {
    $dir_mess_top_proc = "on";
   }
  if($direct_mass_text[$ii] eq $dir_mess_stat_command)
   {
    $dir_mess_stat = "on";
   }
  if($direct_mass_text[$ii] eq $dir_mess_service_command)
   {
    $dir_mess_service = "on";
   }
  @new_timeout=split(/\s+/,$direct_mass_text[$ii]);
  if($new_timeout['0'] eq $dir_timeout)
   {
   $user_timeout = $new_timeout['1'];   
   $statuses_count = int((3600*24)/$user_timeout);    
   }
if($direct_mass[$ii]) 
 { 
  my $destroy_direct = $nt->destroy_direct_message( { id => $direct_mass[$ii]} );
  $direct_mass = undef;
  $statuses_count--;
  $time_const = int(3600 / (int(int($statuses_count / $servers_count) / 24)));
 }

}
$ii = 0; 
$kk = 0;
##############   direct message commands #########
if($dir_mess_last_user eq "on")
 {
  $rand = int(rand(9999));
  $temp_last = `last|awk '{print \$1,\$3}'|head -n5>last.txt`;
  open(FILE,"last.txt");
  @strings_last=<FILE>;
  $last_str_out = "|LAST|";
  for($gg=0; $gg<=4; $gg++)
   {
    $temp_array = @strings_last[$gg];
    @last_array=split(/\s+/,$temp_array);
    $last_str_out = $last_str_out.$last_array['0'].":".$last_array['1']."|";
    $last_array = undef;
    $temp_array = undef;
   }
  my $message = $last_str_out.$rand;
 eval { $nt->update($message) };
  @top = undef;
  $last_str_out = undef;
  $message = undef;
  $result = undef;
  $rand = undef;
 }
if($dir_mess_top_proc eq "on") 
 {
  $rand = int(rand(9999));
  @top = getTopProc(5);
  $top_str = "|PROC|"; 
  for($j=0; $j<5; $j++) { $top_str = $top_str.$top[$j]."|"; }  
  $current_overral = $top_str.$rand;
  my $message = $current_overral;
  eval { $nt->update($message) };  
  $top_str = undef;
  @top = ();
  undef $top;
  $current_overral = undef;
  $message = undef;
  $result = undef;
  $rand = undef;
 }

if($dir_mess_stat eq "on")
 { 
  @mem=getMemory();
  $mem_used = $mem[0];
  $swap_ok = $mem[1];

  $net_connection=numberOpenNetSockets();
  @traff=getTraffic();
  $banwidth_transmit = sprintf("%.1f",($traff[0]/(1024*1024*1024)));

  $cpu = getCpu();
  $la1 = getLoadavg();
  $uptime = getUptime();
 # @top=getTopProc(5); 
  
  @req_sec =  apache_nginx_req();
  
  $online_usr = onlineUsr();
  $count_visit = countVisit();
  
  $rand = int(rand(9999));  

  $current_overral = "SYS"."|".$hostname."|"."cpu:".$cpu."%"."|"."mem:".$mem_used."%"."|"."swp:".$swap_ok."%"."|"."avg:".$la1."|"."Up:".$uptime."d"."|"."Sock:".$net_connection."|"."BW:".$banwidth_transmit."GB"."|"."ApacheReq/sec:".$req_sec['0']."|"."NginxReq/sec:".$req_sec['1']."|"."usrOnline:".$online_usr."|"."visits:".$count_visit."|".$rand;

  my $message = $current_overral;
  eval { $nt->update($message) };
  $current_overral = undef;
  $message = undef;
  $result = undef;
  $top = undef;
  $rand = undef;
 } 
if($dir_mess_service eq "on")
 {
  $etc_check = etcCheck();
  $www_check = wwwCheck();
  if($etc_check eq "") { $etc_check = "/etc nonmodify"; }
  else { $etc_check = "/etc MODIFY"; }
  if($www_check eq "") { $www_check = "/www nonmodify"; }
  else { $www_check = "/www MODIFY"; }
  @services = getserviceok();
  $serv_out = "|SERVICE|"."apache:".$services['0']."|"."Nginx:".$services['1']."|"."Mysql:".$services['2'];
  @users=getUsers();
  $usr_from = $serv_out."|".$etc_check."|".$www_check."|";
  print "### Users login: ###\n";
  for($i=0; $i<=$#users; $i++) {  $usr_from = $usr_from.$users[$i]."|"; }
  $rand = int(rand(9999));
  $current_overral = $usr_from."|".$rand;
  my $message = $current_overral;
  eval { $nt->update($message) };
  $top_str = undef;
  $usr_from = undef;
  $serv_out = undef;
  $current_overral = undef;
  $message = undef;
  $result = undef;
  $usr_from = undef;
  $serv_out = undef;
  $users = undef;
  $rand = undef;
 }

sleep $time_const_direct;
$ttime = $ttime + $time_const_direct; 
}
############## main function #############

@mem=getMemory();
$mem_used = $mem[0];
$swap_ok = $mem[1];

$net_connection=numberOpenNetSockets();
@traff=getTraffic();
$banwidth_transmit = sprintf("%.1f",($traff[0]/(1024*1024*1024)));

$cpu = getCpu();
$la1 = getLoadavg();
$uptime = getUptime();
#@top=getTopProc(5); 

@req_sec =  apache_nginx_req();

$online_usr = onlineUsr();
$count_visit = countVisit();

$rand = int(rand(9999));

$current_overral = "SYS"."|".$hostname."|"."cpu:".$cpu."%"."|"."mem:".$mem_used."%"."|"."swp:".$swap_ok."%"."|"."avg:".$la1."|"."Up:".$uptime."d"."|"."Sock:".$net_connection."|"."BW:".$banwidth_transmit."GB"."|"."ApacheReq/sec:".$req_sec['0']."|"."NginxReq/sec:".$req_sec['1']."|"."usrOnline:".$online_usr."|"."visits:".$count_visit."|".$rand;
print $current_overral;
my $message = $current_overral;
eval { $nt->update($message) };
$current_overral = undef;
$message = undef;
$result = undef;
##############  Service function  ############
@services = getserviceok();
$etc_check = etcCheck();
$www_check = wwwCheck();
if($etc_check eq "") { $etc_check = "/etc nonmodify"; }
else { $etc_check = "/etc MODIFY"; }
if($www_check eq "") { $www_check = "/www nonmodify"; }
else { $www_check = "/www MODIFY"; }
$serv_out = "|SERVICE|"."apache:".$services['0']."|"."Nginx:".$services['1']."|"."Mysql:".$services['2'];
@users=getUsers();
$usr_from = $serv_out."|".$etc_check."|".$www_check."|";
print "### Users login: ###\n";
for($i=0; $i<=$#users; $i++) {  $usr_from = $usr_from.$users[$i]."|"; }
$rand = int(rand(9999));
$current_overral = $usr_from.$rand;
print $current_overral;
my $message = $current_overral;
eval { $nt->update($message) };
$top_str = undef;
$usr_from = undef;
$serv_out = undef;
$rand = undef;
$current_overral = undef;
$message = undef;
$result = undef;
#eval {
#    my $statuses = $nt->friends_timeline({ since_id => '2011-01-01', count => 100 });
#    for my $status ( @$statuses ) {
#        print "$status->{created_at} <$status->{user}{screen_name}> $status->{text}\n";
#    }
#};

#############   Twitter error handler  ######################################################################
#############################################################################################################


#if ( my $err = $@ ) {
#     $@ unless blessed $err && $err->isa('Net::Twitter::Error');
#
#    warn "HTTP Response Code: ", $err->code, "\n",
#         "HTTP Message......: ", $err->message, "\n",
#         "Twitter error.....: ", $err->error, "\n";
#}
#if ( $@ ) {
#        warn "update failed because: $@\n";
#    }




print "tweet created";
sleep 1;

}

sub etcCheck
{
 $temp_etc_check = `find /etc -mtime  1 -print>etccheck.txt`;
 open(FILE,"etccheck.txt");
 @strings_etc_check=<FILE>;
 $etc_check = @strings_etc_check['0'];
 return $etc_check; 
}

sub wwwCheck
{
 $temp_etc_check = `find /var/www -mtime  1 -print>wwwcheck.txt`;
 open(FILE,"wwwcheck.txt");
 @strings_www_check=<FILE>;
 $www_check = @strings_www_check['0'];
 return $www_check;
}

sub countVisit
{
 $temp_count_visit = `cat /var/log/apache2/access.log|awk '{print \$1}'|sort|uniq -c|awk '{print \$2}'|wc -l>count_visit.txt`;
 open(FILE,"count_visit.txt");
 @strings_count_visit=<FILE>;
 $count_visit = @strings_count_visit['0'];
 return $count_visit;
}

sub onlineUsr
{
 $temp_online_usr = `netstat -n|grep 80|awk '{print \$5}'|sort|uniq|awk -F: '{print \$1}'|sort|uniq|wc -l>online_usr.txt`;
 open(FILE,"online_usr.txt");
 @strings_online_usr=<FILE>;
 $online_usr = @strings_online_usr['0'];
 return $online_usr;
}


sub apache_nginx_req
{
 $temp_req = `tail -n0 -f /var/log/apache2/access.log>/tmp/tmp.log & sleep 2; kill \$! ; wc -l /tmp/tmp.log| cut -c-2>apache_req.txt 2>/dev/null`;  
   open(FILE,"apache_req.txt");
   @strings_apache_req=<FILE>;
   $apache_req = @strings_apache_req['0'];
     
   $temp_req = `tail -n0 -f /var/log/nginx/access.log>/tmp/tmp.log & sleep 2; kill \$! ; wc -l /tmp/tmp.log| cut -c-2>nginx_req.txt 2>/dev/null`;  
   open(FILE,"nginx_req.txt");
    @strings_nginx_req=<FILE>;
    $nginx_req = @strings_nginx_req['0']; 
    @out = ();
    $out['0'] = $apache_req;
    $out['1'] = $nginx_req;
    return @out;
}

sub getserviceok
{
  my $apache_out, $nginx_out, $mysql_out;
  my @out=();
  $apache_proc = `pgrep apache>apache.txt`;
  $nginx_proc = `pgrep nginx>nginx.txt`;
  $mysql_proc = `pgrep mysql>mysql.txt`;
  open(FILE,"apache.txt");
  @strings=<FILE>;
  if(@strings['0'] eq "") 
    { 
      $apache_out = "fail"; 
    }
  else 
    {
      $apache_out = "ok";
    }
  @strings = undef;
  open(FILE,"nginx.txt");
  @strings=<FILE>;
  if(@strings['0'] eq "") 
    {
      $nginx_out = "fail";
    }
  else 
    {
      $nginx_out = "ok";
    }
  @strings = undef;
   open(FILE,"mysql.txt");
  @strings=<FILE>;
  if(@strings['0'] eq "") 
    {
      $mysql_out = "fail";
    }
  else 
    {
      $mysql_out = "ok";
    }
  @strings = undef;
  $out['0'] = $apache_out;
  $out['1'] = $nginx_out;
  $out['2'] = $mysql_out;
  return @out;
}

sub getCpu
{
  my $cpu_avg;
    open(FIL,$cpu_path);
    @strings=<FIL>;
    $cpu_array = @strings['0'];
    @cpu1=split(/\s+/,$cpu_array); 
    sleep 4;
    open(FIL,$cpu_path);
    @strings1=<FIL>;
    $cpu_array1 = @strings1['0'];
    @cpu2=split(/\s+/,$cpu_array1); 
    
    $cpudu = abs(@cpu1['1'] - @cpu2['1']);  
    $cpudn = abs(@cpu1['2'] - @cpu2['2']);
    $cpuds = abs(@cpu1['3'] - @cpu2['3']);
    $cpudi = abs(@cpu1['4'] - @cpu2['4']);
    $total = $cpudu + $cpudn + $cpuds + $cpudi;
    $cpuu = $cpudu/$total;
    $cpun = $cpudn/$total;
    $cpus = $cpuds/$total;
    $cpu_avg = int(($cpuu+$cpun+$cpus)*100);
  return $cpu_avg;
}

sub getUptime
{
  my $uptime_value;
    open(FILE,$uptime_path);
    @upt=<FILE>;
    $upt_array = @upt['0'];
    @upt_val=split(/\s+/,$upt_array); 
    $uptime_value = int($upt_val['0']/86400);
    close(FILE);
  return $uptime_value;

}


sub getLoadavg
{
  my $avg_value;
    open(FILE,$avg_path);
    @avg=<FILE>;
    $avg_array = @avg['0'];
    @avg_val=split(/\s+/,$avg_array); 
    $avg_value =$avg_val['0'];
    close(FILE);
  return $avg_value;
}



sub getMemory
{
  my $total, $free, $swap_total, $swap_used, $used, $str;
  my @out=();
  
  open(FILE, "< ".$mem_path);
  while(<FILE>)
  {
    $str=$_;
    if($str =~ /^MemTotal:/)
    {
      ($undef, $total)=split(' ',$str);
    }
    if($str =~ /^MemFree:/)
    {
      ($undef, $free)=split(' ',$str);
    }
    if($str =~ /^Cached:/)
    {
      ($undef, $swap_total)=split(' ',$str);
    }
    if($str =~ /^SwapCached:/)
    {
      ($undef, $swap_used)=split(' ',$str);
    }
  }
#  print "out=$out[0]\t$out[1]\n";
  close(FILE);
  $out[0]=int(($total-$free)*100/$total);
  $out[1]=int($swap_used*100/$swap_total);
  return @out;
}

### Get number network sockets. Output: number_sockets ###
sub numberOpenNetSockets()
{
  my $tcp, $udp, $number;
  
  open(COMMAND, "< ".$network_sock_path);
  while(<COMMAND>)
  {
    $str=$_;
    if($str =~ /^TCP: inuse/)
    {
      ($undef, $undef, $tcp)=split(' ',$str);
    }
    if($str =~ /^UDP: inuse/)
    {
      ($undef, $undef, $udp)=split(' ',$str);
    }
    
    
#    print $str;
  } 
  $number=$tcp+$udp; 
  return $number;
}

### Get Users login. Output: (users) ###
sub getUsers
{
  my $user;
  my @out=();
  
  @utmp=User::Utmp::getut();

  $i=0;
  foreach my $entry (@utmp)
  {
    while(my ($key, $value) = each(%$entry))
    {
      if($key eq "ut_type" && $value == 7)
      {
#        print "$key, $value\n";
#        print $entry->{"ut_user"}."\n";
        $out[$i]=$entry->{"ut_user"};
        $out1[$i] = $entry->{"ut_host"};
        $out_fin[$i] = $out[$i].":".$out1[$i];
        $i++;
      }
    }
  }

  
  %ucnt=();
  for($i=0; $i<=$#out_fin; $i++)
  {
    $ucnt{$out_fin[$i]}++;
    @users = sort keys %ucnt;
  }

#  print "users=$users[0]\n";
  return @users;
}

### Get Traffic. Output: receive(Bytes), transmit(Bytes) ###
sub getTraffic
{
  my $receive, $transmit;
  @out=();
  
  open(DEV,"< ".$network_dev_path) || die("Error!!!");
  while(<DEV>)
  {
    $str=$_;
    if($str =~ /$name_network_cart:/)
    {
      ($undef,$receive,$undef,$undef,$undef,$undef,$undef,$undef,$undef,$transmit)=split(' ',$str);
    }
  }
  close(DEV);
  $out[0]=$undef;
  $out[1]=$undef1;
  return @out;
}

### Store and get traffic day, month. ###
### Output: (input_day, output_day, input_month, output_month) ### 
sub getSummarizeTraffic
{
  my ($file, $input, $output) = @_;
  my $input_day=0; my $output_day=0;
  my $input_mon=0; my $output_mon=0;
  my $input_sum, $output_sum;
  @out=(); 

  ($day, $mon, $year) = (localtime)[3,4,5];
#  print "$day/$mon\n";
  ($mtime)  = (stat($file))[9];
  ($day_file, $mon_file, $year_file) = (localtime($mtime))[3,4,5]; 
#  print "$day_file/$mon_file\n";


  if(-e $file)
  {
    open(FILE, "<$file");
    $str=<FILE>;
    ($undef, $input_day, $output_day)=split(' ', $str);
    $str=<FILE>;
    ($undef, $input_mon, $output_mon)=split(' ', $str);
    close(FILE);
  }

  if($day ne $day_file) { $input_day=0; $output_day=0; }
  if($mon ne $mon_file) { $input_mon=0; $output_mon=0; }


  open(FILE, ">$file");
  $input_sum=$input_day+$input;
  $output_sum=$output_day+$output;
  print FILE "Day:\t$input_sum\t$output_sum\n";
  $out[0]=$input_sum; $out[1]=$output_sum;
  $input_sum=$input_mon+$input;
  $output_sum=$output_mon+$output;
  print FILE "Month:\t$input_sum\t$output_sum\n";
  $out[2]=$input_sum; $out[3]=$output_sum;
  close(FILE);
  return @out;
}

### Get top 3 process. Output: (String, String, String). String: (process) ###
sub getTopProc
{
  my @out=();
  my ($number_top)=@_;
  my $period=3;
  my $dir='/proc';

  opendir(DIR, $dir) || die $!;

  my %hash1 = ();
  while(my $file = readdir(DIR))
  {
    next unless(-d "$dir/$file");
    if($file =~ /\d+/)
    {
      open(FILE, "< $dir/$file/stat");
      $str=<FILE>;
      close(FILE);
      @list=split(' ',$str);
      $proc_time=$list[14]+$list[15];#+$list[16]+$list[17];
  #    open(FILE, "< $dir/$file/comm");
   #   $name_proc=<FILE>;
    #  chomp $name_proc;
     # close(FILE);
    $name_proc = $list[1];
      $hash1{$name_proc}=$proc_time;
print $proc_time."zamer nomer 1 \n";
    }
  }
  closedir(DIR);

  sleep($period);
  opendir(DIR, $dir) || die $!;

  my %hash2 = ();
  while(my $file = readdir(DIR))
  {
    next unless(-d "$dir/$file");
    if($file =~ /\d+/)
    {
      open(FILE, "< $dir/$file/stat");
      $str=<FILE>;
      close(FILE);
      @list=split(' ',$str);
      $proc_time=$list[14]+$list[15];#+$list[16]+$list[17];
    #  open(FILE, "< $dir/$file/comm");
    #  $name_proc=<FILE>;
    #  chomp $name_proc;
    #  close(FILE);
    $name_proc = $list[1];
      $hash2{$name_proc}=$proc_time;
print $proc_time."zamer nomer2 \n";
    }
  }
  closedir(DIR);

  my %hash = ();
  while(($key,$value) = each %hash1)
  {
    $hash{$key}=abs($hash1{$key}-$hash2{$key});
#   print $key;
    $hash1{$key};
  }

  $i=0;
  for(sort { $hash{$b} <=> $hash{$a} } keys %hash)
  {
    $out[$i]=$_;
#   print "$_: $hash{$_}\n";
#print "$key\n";
    if($number_top <= $i+1) { last; }
    $i++;
  }
  return @out;
}
