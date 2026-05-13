ÚZ
PD:\Projects\RealtimeChatApplication\ConnectHub\src\ConnectHub.Gateway\Program.cs
var 
builder 
= 
WebApplication 
. 
CreateBuilder *
(* +
args+ /
)/ 0
;0 1
Log 
. 
Logger 

= 
new 
LoggerConfiguration $
($ %
)% &
. 
WriteTo 
. 
Console 
( 
) 
. 
CreateLogger 
( 
) 
; 
builder 
. 
Host 
. 

UseSerilog 
( 
) 
; 
builder 
. 
Services 
. 
AddReverseProxy  
(  !
)! "
. 
LoadFromConfig 
( 
builder 
. 
Configuration )
.) *

GetSection* 4
(4 5
$str5 C
)C D
)D E
;E F
var 
	jwtSecret 
= 
builder 
. 
Configuration %
[% &
$str& /
]/ 0
!0 1
;1 2
builder 
. 
Services 
. 
AddAuthentication "
(" #
JwtBearerDefaults# 4
.4 5 
AuthenticationScheme5 I
)I J
. 
AddJwtBearer 
( 
options 
=> 
{ 
options 
. %
TokenValidationParameters )
=* +
new, /%
TokenValidationParameters0 I
{ 	
ValidateIssuer 
= 
true !
,! "
ValidateAudience 
= 
true #
,# $
ValidateLifetime 
= 
true #
,# $$
ValidateIssuerSigningKey $
=% &
true' +
,+ ,
ValidIssuer 
= 
builder !
.! "
Configuration" /
[/ 0
$str0 <
]< =
,= >
ValidAudience   
=   
builder   #
.  # $
Configuration  $ 1
[  1 2
$str  2 @
]  @ A
,  A B
IssuerSigningKey!! 
=!! 
new!! " 
SymmetricSecurityKey!!# 7
(!!7 8
Encoding"" 
."" 
UTF8"" 
."" 
GetBytes"" &
(""& '
	jwtSecret""' 0
)""0 1
)""1 2
}## 	
;##	 

options&& 
.&& 
Events&& 
=&& 
new&& 
JwtBearerEvents&& ,
{'' 	
OnMessageReceived(( 
=(( 
context((  '
=>((( *
{)) 
var** 
accessToken** 
=**  !
context**" )
.**) *
Request*** 1
.**1 2
Query**2 7
[**7 8
$str**8 F
]**F G
;**G H
var++ 
path++ 
=++ 
context++ "
.++" #
HttpContext++# .
.++. /
Request++/ 6
.++6 7
Path++7 ;
;++; <
if,, 
(,, 
!,, 
string,, 
.,, 
IsNullOrEmpty,, )
(,,) *
accessToken,,* 5
),,5 6
&&,,7 9
path-- 
.-- 
StartsWithSegments-- +
(--+ ,
$str--, 3
)--3 4
)--4 5
{.. 
context// 
.// 
Token// !
=//" #
accessToken//$ /
;/// 0
}00 
return11 
Task11 
.11 
CompletedTask11 )
;11) *
}22 
}33 	
;33	 

}44 
)44 
;44 
builder66 
.66 
Services66 
.66 
AddAuthorization66 !
(66! "
)66" #
;66# $
builder99 
.99 
Services99 
.99 
AddMemoryCache99 
(99  
)99  !
;99! "
builder:: 
.:: 
Services:: 
.:: 
	Configure:: 
<:: 
IpRateLimitOptions:: -
>::- .
(::. /
builder;; 
.;; 
Configuration;; 
.;; 

GetSection;; $
(;;$ %
$str;;% 5
);;5 6
);;6 7
;;;7 8
builder<< 
.<< 
Services<< 
.<< 
AddSingleton<< 
<<< 
IIpPolicyStore<< ,
,<<, -$
MemoryCacheIpPolicyStore<<. F
><<F G
(<<G H
)<<H I
;<<I J
builder== 
.== 
Services== 
.== 
AddSingleton== 
<== "
IRateLimitCounterStore== 4
,==4 5,
 MemoryCacheRateLimitCounterStore>> $
>>>$ %
(>>% &
)>>& '
;>>' (
builder?? 
.?? 
Services?? 
.?? 
AddSingleton?? 
<?? #
IRateLimitConfiguration?? 5
,??5 6"
RateLimitConfiguration??7 M
>??M N
(??N O
)??O P
;??P Q
builder@@ 
.@@ 
Services@@ 
.@@ 
AddSingleton@@ 
<@@ 
IProcessingStrategy@@ 1
,@@1 2*
AsyncKeyLockProcessingStrategy@@3 Q
>@@Q R
(@@R S
)@@S T
;@@T U
builderAA 
.AA 
ServicesAA 
.AA #
AddInMemoryRateLimitingAA (
(AA( )
)AA) *
;AA* +
varHH 
corsOriginsHH 
=HH 
builderHH 
.HH 
ConfigurationHH '
[HH' (
$strHH( =
]HH= >
?II 
.II 
SplitII 
(II 
$charII 
,II 
StringSplitOptionsII #
.II# $
RemoveEmptyEntriesII$ 6
|II7 8
StringSplitOptionsII9 K
.IIK L
TrimEntriesIIL W
)IIW X
??JJ 
newJJ 

[JJ
 
]JJ 
{JJ 
$strJJ &
,JJ& '
$strJJ( @
,JJ@ A
$strJJB P
}JJQ R
;JJR S
varLL 
exactOriginsLL 
=LL 
corsOriginsLL 
.LL 
WhereLL $
(LL$ %
oLL% &
=>LL' )
!LL* +
oLL+ ,
.LL, -
ContainsLL- 5
(LL5 6
$strLL6 :
)LL: ;
)LL; <
.LL< =
	ToHashSetLL= F
(LLF G
StringComparerLLG U
.LLU V
OrdinalIgnoreCaseLLV g
)LLg h
;LLh i
varMM 
wildcardSuffixesMM 
=MM 
corsOriginsMM "
.NN 
WhereNN 

(NN
 
oNN 
=>NN 
oNN 
.NN 
ContainsNN 
(NN 
$strNN 
)NN  
)NN  !
.OO 
SelectOO 
(OO 
oOO 
=>OO 
oOO 
[OO 
(OO 
oOO 
.OO 
IndexOfOO 
(OO 
$strOO "
)OO" #
+OO$ %
$numOO& '
)OO' (
..OO( *
]OO* +
)OO+ ,
.PP 
ToListPP 
(PP 
)PP 
;PP 
boolRR 
IsAllowedOriginRR 
(RR 
stringRR 
originRR "
)RR" #
=>RR$ &
exactOriginsSS 
.SS 
ContainsSS 
(SS 
originSS  
)SS  !
||SS" $
(TT 
UriTT 
.TT 	
	TryCreateTT	 
(TT 
originTT 
,TT 
UriKindTT "
.TT" #
AbsoluteTT# +
,TT+ ,
outTT- 0
varTT1 4
uriTT5 8
)TT8 9
&&TT: <
wildcardSuffixesUU 
.UU 
AnyUU 
(UU 
sufUU 
=>UU  
uriUU! $
.UU$ %
HostUU% )
.UU) *
EndsWithUU* 2
(UU2 3
sufUU3 6
,UU6 7
StringComparisonUU8 H
.UUH I
OrdinalIgnoreCaseUUI Z
)UUZ [
)UU[ \
)UU\ ]
;UU] ^
builderWW 
.WW 
ServicesWW 
.WW 
AddCorsWW 
(WW 
optionsWW  
=>WW! #
{XX 
optionsYY 
.YY 
	AddPolicyYY 
(YY 
$strYY %
,YY% &
policyZZ 
=>ZZ 
policyZZ 
.[[ 
SetIsOriginAllowed[[ 
([[  
IsAllowedOrigin[[  /
)[[/ 0
.\\ 
AllowAnyHeader\\ 
(\\ 
)\\ 
.]] 
AllowAnyMethod]] 
(]] 
)]] 
.^^ 
AllowCredentials^^ 
(^^ 
)^^ 
)^^  
;^^  !
}__ 
)__ 
;__ 
varaa 
appaa 
=aa 	
builderaa
 
.aa 
Buildaa 
(aa 
)aa 
;aa 
appgg 
.gg 
UseWebSocketsgg 
(gg 
newgg 
WebSocketOptionsgg &
{hh 
KeepAliveIntervalii 
=ii 
TimeSpanii  
.ii  !
FromSecondsii! ,
(ii, -
$numii- /
)ii/ 0
}jj 
)jj 
;jj 
appll 
.ll 
UseMiddlewarell 
<ll $
RequestLoggingMiddlewarell *
>ll* +
(ll+ ,
)ll, -
;ll- .
appnn 
.nn 
UseIpRateLimitingnn 
(nn 
)nn 
;nn 
apppp 
.pp 
UseCorspp 
(pp 
$strpp 
)pp 
;pp 
apprr 
.rr 
UseAuthenticationrr 
(rr 
)rr 
;rr 
appss 
.ss 
UseAuthorizationss 
(ss 
)ss 
;ss 
appvv 
.vv 
MapGetvv 

(vv
 
$strvv 
,vv 
(vv 
)vv 
=>vv 
newvv 
{ww 
Statusxx 

=xx 
$strxx 
,xx 
Serviceyy 
=yy 
$stryy "
,yy" #
	Timestampzz 
=zz 
DateTimezz 
.zz 
UtcNowzz 
,zz  
Routes{{ 

={{ 
new{{ 
[{{ 
]{{ 
{|| 
$str}} 2
,}}2 3
$str~~ 2
,~~2 3
$str 2
,2 3
$str
ÄÄ 5
,
ÄÄ5 6
$str
ÅÅ 5
,
ÅÅ5 6
$str
ÇÇ 2
,
ÇÇ2 3
$str
ÉÉ 2
,
ÉÉ2 3
$str
ÑÑ 1
,
ÑÑ1 2
$str
ÖÖ ;
,
ÖÖ; <
$str
ÜÜ D
,
ÜÜD E
$str
áá ;
,
áá; <
$str
àà 3
}
ââ 
}ää 
)
ää 
;
ää 
appêê 
.
êê 
MapReverseProxy
êê 
(
êê 
)
êê 
.
êê 
RequireCors
êê !
(
êê! "
$str
êê" 1
)
êê1 2
;
êê2 3
appíí 
.
íí 
Run
íí 
(
íí 
)
íí 	
;
íí	 
ø
oD:\Projects\RealtimeChatApplication\ConnectHub\src\ConnectHub.Gateway\Middleware.cs\RequestLoggingMiddleware.cs
	namespace 	

ConnectHub
 
. 
Gateway 
. 

Middleware '
;' (
public 
class $
RequestLoggingMiddleware %
{ 
private 
readonly 
RequestDelegate $
_next% *
;* +
private 
readonly 
ILogger 
< $
RequestLoggingMiddleware 5
>5 6
_logger7 >
;> ?
public		 
$
RequestLoggingMiddleware		 #
(		# $
RequestDelegate

 
next

 
,

 
ILogger 
< $
RequestLoggingMiddleware (
>( )
logger* 0
)0 1
{ 
_next 
= 
next 
; 
_logger 
= 
logger 
; 
} 
public 

async 
Task 
InvokeAsync !
(! "
HttpContext" -
context. 5
)5 6
{ 
var 
start 
= 
DateTime 
. 
UtcNow #
;# $
_logger 
. 
LogInformation 
( 
$str 4
,4 5
context 
. 
Request 
. 
Method "
," #
context 
. 
Request 
. 
Path  
,  !
context 
. 

Connection 
. 
RemoteIpAddress .
). /
;/ 0
await 
_next 
( 
context 
) 
; 
var 
elapsed 
= 
( 
DateTime 
.  
UtcNow  &
-' (
start) .
). /
./ 0
TotalMilliseconds0 A
;A B
_logger 
. 
LogInformation 
( 
$str   ?
,  ? @
context!! 
.!! 
Response!! 
.!! 

StatusCode!! '
,!!' (
elapsed"" 
."" 
ToString"" 
("" 
$str"" !
)""! "
,""" #
context## 
.## 
Request## 
.## 
Path##  
)##  !
;##! "
}$$ 
}%% 