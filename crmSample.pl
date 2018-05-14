use FindBin;
use lib $FindBin::Bin;
use Bin::CrmWebApiAccessor;

use Win32::Console;

my $OUT = Win32::Console->new(STD_OUTPUT_HANDLE);
my $clear_string = $OUT->Cls;
print $clear_string;


my $crmUrl = "https://xxxxxxxx.crm.dynamics.com/";
my $crmApiUrl = $crmUrl . "api/data/V8.2/";

my $clientId="00000000-0000-0000-0000-000000000000";
my $clientSecret="yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy";

my $c = new CrmWebApiAccessor('crmUrl' => $crmUrl, 'crmApiUrl' => $crmApiUrl, 'clientId' => $clientId,  'clientSecret' => $clientSecret, 'debug' => 1, 'traceLevel' => 2);

my (@data) = $c->getData('systemusers?$top=2&$select=fullname');

##### data returned looks like this:
# [
  # {
	# 'ownerid' => 'xxxxxxxxxxxxxxxxxxxxxxx',
	# 'fullname' => 'John Doe',
	# 'systemuserid' => 'xxxxxxxxxxxxxxxxxxxxx',
	# '@odata.etag' => 'W/"178489354"'
  # },
  # {
	# '@odata.etag' => 'W/"179879533"',
	# 'systemuserid' => 'xxxxxxxxxxxxxxxx',
	# 'fullname' => 'Jane Doe',
	# 'ownerid' => 'xxxxxxxxxxxxxxxxxx'
  # }
# ]

#accessing the data
for my $item( @data ){
	print $item->{"fullname"} . " {" . $item->{"systemuserid"} ."}". "\n";
};

my (@data) = $c->getData('accounts?$select=accountid,name&$top=2');

$c->printData(@data);