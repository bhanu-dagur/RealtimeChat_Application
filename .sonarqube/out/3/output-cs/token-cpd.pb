Òy
wD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Services\NotificationService.cs
	namespace		 	

ConnectHub		
 
.		 
Notification		 !
.		! "
API		" %
.		% &
Services		& .
;		. /
public 
class 
NotificationService  
:! " 
INotificationService# 7
{ 
private 
readonly #
INotificationRepository ,
_repo- 2
;2 3
private 
readonly 
IHubContext  
<  !
NotificationHub! 0
>0 1
_hubContext2 =
;= >
private 
readonly 
IEmailService "
_emailService# 0
;0 1
private 
readonly 
ILogger 
< 
NotificationService 0
>0 1
_logger2 9
;9 :
public 

NotificationService 
( #
INotificationRepository 
repo  $
,$ %
IHubContext 
< 
NotificationHub #
># $

hubContext% /
,/ 0
IEmailService 
emailService "
," #
ILogger 
< 
NotificationService #
># $
logger% +
)+ ,
{ 
_repo 
= 
repo 
; 
_hubContext 
= 

hubContext  
;  !
_emailService 
= 
emailService $
;$ %
_logger 
= 
logger 
; 
} 
public 

async 
Task 
< #
NotificationResponseDto -
>- .
	SendAsync/ 8
(8 9
SendNotificationDto9 L
dtoM P
)P Q
{ 
var!! 
notification!! 
=!! 
new!! 
NotificationEntity!! 1
{"" 	
RecipientId## 
=## 
dto## 
.## 
RecipientId## )
,##) *
SenderId$$ 
=$$ 
dto$$ 
.$$ 
SenderId$$ #
,$$# $
Type%% 
=%% 
dto%% 
.%% 
Type%% 
,%% 
Title&& 
=&& 
dto&& 
.&& 
Title&& 
,&& 
Message'' 
='' 
dto'' 
.'' 
Message'' !
,''! "
	RelatedId(( 
=(( 
dto(( 
.(( 
	RelatedId(( %
})) 	
;))	 

var++ 
created++ 
=++ 
await++ 
_repo++ !
.++! "
CreateAsync++" -
(++- .
notification++. :
)++: ;
;++; <
var.. 
unreadCount.. 
=.. 
await.. 
_repo..  %
...% &)
CountUnreadByRecipientIdAsync..& C
(..C D
dto..D G
...G H
RecipientId..H S
)..S T
;..T U
await00 
_hubContext00 
.00 
Clients00 !
.11 
User11 
(11 
dto11 
.11 
RecipientId11 !
.11! "
ToString11" *
(11* +
)11+ ,
)11, -
.22 
	SendAsync22 
(22 
$str22 ,
,22, -
new22. 1
{33 
Notification44 
=44 
MapToDto44 '
(44' (
created44( /
)44/ 0
,440 1
UnreadCount55 
=55 
unreadCount55 )
}66 
)66 
;66 
_logger88 
.88 
LogInformation88 
(88 
$str99 >
,99> ?
dto:: 
.:: 
RecipientId:: 
,:: 
dto::  
.::  !
Title::! &
)::& '
;::' (
return<< 
MapToDto<< 
(<< 
created<< 
)<<  
;<<  !
}== 
public?? 

async?? 
Task?? 
<?? 
IList?? 
<?? #
NotificationResponseDto?? 3
>??3 4
>??4 5
SendBulkAsync??6 C
(??C D$
BroadcastNotificationDto@@  
dto@@! $
)@@$ %
{AA 
varBB 
notificationsBB 
=BB 
newBB 
ListBB  $
<BB$ %
NotificationEntityBB% 7
>BB7 8
(BB8 9
)BB9 :
;BB: ;
varEE 
recipientIdsEE 
=EE 
dtoEE 
.EE 
RecipientIdsEE +
.EE+ ,
AnyEE, /
(EE/ 0
)EE0 1
?FF 
dtoFF 
.FF 
RecipientIdsFF 
:GG 
newGG 
ListGG 
<GG 
intGG 
>GG 
(GG 
)GG 
;GG 
foreachII 
(II 
varII 
recipientIdII  
inII! #
recipientIdsII$ 0
)II0 1
{JJ 	
notificationsKK 
.KK 
AddKK 
(KK 
newKK !
NotificationEntityKK" 4
{LL 
RecipientIdMM 
=MM 
recipientIdMM )
,MM) *
TypeNN 
=NN 
NotificationTypeNN '
.NN' (
PLATFORMNN( 0
,NN0 1
TitleOO 
=OO 
dtoOO 
.OO 
TitleOO !
,OO! "
MessagePP 
=PP 
dtoPP 
.PP 
MessagePP %
}QQ 
)QQ 
;QQ 
}RR 	
varTT 
createdTT 
=TT 
awaitTT 
_repoTT !
.TT! "
CreateManyAsyncTT" 1
(TT1 2
notificationsTT2 ?
)TT? @
;TT@ A
foreachWW 
(WW 
varWW 
recipientIdWW  
inWW! #
recipientIdsWW$ 0
)WW0 1
{XX 	
awaitYY 
_hubContextYY 
.YY 
ClientsYY %
.ZZ 
UserZZ 
(ZZ 
recipientIdZZ !
.ZZ! "
ToStringZZ" *
(ZZ* +
)ZZ+ ,
)ZZ, -
.[[ 
	SendAsync[[ 
([[ 
$str[[ -
,[[- .
new[[/ 2
{\\ 
Title]] 
=]] 
dto]] 
.]]  
Title]]  %
,]]% &
Message^^ 
=^^ 
dto^^ !
.^^! "
Message^^" )
,^^) *
SentAt__ 
=__ 
DateTime__ %
.__% &
UtcNow__& ,
}`` 
)`` 
;`` 
}aa 	
_loggercc 
.cc 
LogInformationcc 
(cc 
$strdd 6
,dd6 7
recipientIdsee 
.ee 
Countee 
,ee 
dtoee  #
.ee# $
Titleee$ )
)ee) *
;ee* +
returngg 
createdgg 
.gg 
Selectgg 
(gg 
MapToDtogg &
)gg& '
.gg' (
ToListgg( .
(gg. /
)gg/ 0
;gg0 1
}hh 
publicjj 

asyncjj 
Taskjj 
<jj 
IListjj 
<jj #
NotificationResponseDtojj 3
>jj3 4
>jj4 5
GetByRecipientAsyncjj6 I
(jjI J
intjjJ M
recipientIdjjN Y
)jjY Z
{kk 
varll 
notificationsll 
=ll 
awaitll !
_repoll" '
.ll' ("
FindByRecipientIdAsyncll( >
(ll> ?
recipientIdll? J
)llJ K
;llK L
returnmm 
notificationsmm 
.mm 
Selectmm #
(mm# $
MapToDtomm$ ,
)mm, -
.mm- .
ToListmm. 4
(mm4 5
)mm5 6
;mm6 7
}nn 
publicpp 

asyncpp 
Taskpp 
<pp 
IListpp 
<pp #
NotificationResponseDtopp 3
>pp3 4
>pp4 5
GetUnreadAsyncpp6 D
(ppD E
intppE H
recipientIdppI T
)ppT U
{qq 
varrr 
notificationsrr 
=rr 
awaitrr !
_reporr" '
.rr' ((
FindUnreadByRecipientIdAsyncrr( D
(rrD E
recipientIdrrE P
)rrP Q
;rrQ R
returnss 
notificationsss 
.ss 
Selectss #
(ss# $
MapToDtoss$ ,
)ss, -
.ss- .
ToListss. 4
(ss4 5
)ss5 6
;ss6 7
}tt 
publicvv 

asyncvv 
Taskvv 
<vv 
intvv 
>vv 
GetUnreadCountAsyncvv .
(vv. /
intvv/ 2
recipientIdvv3 >
)vv> ?
=>vv@ B
awaitww 
_repoww 
.ww )
CountUnreadByRecipientIdAsyncww 1
(ww1 2
recipientIdww2 =
)ww= >
;ww> ?
publicyy 

asyncyy 
Taskyy 
<yy #
NotificationResponseDtoyy -
>yy- .
MarkAsReadAsyncyy/ >
(yy> ?
intyy? B
notificationIdyyC Q
)yyQ R
{zz 
var{{ 
notification{{ 
={{ 
await{{  
_repo{{! &
.{{& '
FindByIdAsync{{' 4
({{4 5
notificationId{{5 C
){{C D
??|| 
throw|| 
new||  
KeyNotFoundException|| -
(||- .
$str||. G
)||G H
;||H I
notification~~ 
.~~ 
IsRead~~ 
=~~ 
true~~ "
;~~" #
notification 
. 
ReadAt 
= 
DateTime &
.& '
UtcNow' -
;- .
var
ÅÅ 
updated
ÅÅ 
=
ÅÅ 
await
ÅÅ 
_repo
ÅÅ !
.
ÅÅ! "
UpdateAsync
ÅÅ" -
(
ÅÅ- .
notification
ÅÅ. :
)
ÅÅ: ;
;
ÅÅ; <
var
ÑÑ 
unreadCount
ÑÑ 
=
ÑÑ 
await
ÑÑ 
_repo
ÑÑ  %
.
ÑÑ% &+
CountUnreadByRecipientIdAsync
ÑÑ& C
(
ÑÑC D
notification
ÖÖ 
.
ÖÖ 
RecipientId
ÖÖ $
)
ÖÖ$ %
;
ÖÖ% &
await
áá 
_hubContext
áá 
.
áá 
Clients
áá !
.
àà 
User
àà 
(
àà 
notification
àà 
.
àà 
RecipientId
àà *
.
àà* +
ToString
àà+ 3
(
àà3 4
)
àà4 5
)
àà5 6
.
ââ 
	SendAsync
ââ 
(
ââ 
$str
ââ *
,
ââ* +
unreadCount
ââ, 7
)
ââ7 8
;
ââ8 9
return
ãã 
MapToDto
ãã 
(
ãã 
updated
ãã 
)
ãã  
;
ãã  !
}
åå 
public
éé 

async
éé 
Task
éé 
MarkAllReadAsync
éé &
(
éé& '
int
éé' *
recipientId
éé+ 6
)
éé6 7
{
èè 
await
êê 
_repo
êê 
.
êê +
MarkAllReadByRecipientIdAsync
êê 1
(
êê1 2
recipientId
êê2 =
)
êê= >
;
êê> ?
await
ìì 
_hubContext
ìì 
.
ìì 
Clients
ìì !
.
îî 
User
îî 
(
îî 
recipientId
îî 
.
îî 
ToString
îî &
(
îî& '
)
îî' (
)
îî( )
.
ïï 
	SendAsync
ïï 
(
ïï 
$str
ïï *
,
ïï* +
$num
ïï, -
)
ïï- .
;
ïï. /
}
ññ 
public
òò 

async
òò 
Task
òò 
<
òò 
bool
òò 
>
òò 
DeleteAsync
òò '
(
òò' (
int
òò( +
notificationId
òò, :
)
òò: ;
=>
òò< >
await
ôô 
_repo
ôô 
.
ôô 
DeleteAsync
ôô 
(
ôô  
notificationId
ôô  .
)
ôô. /
;
ôô/ 0
public
õõ 

async
õõ 
Task
õõ 
<
õõ 
PagedResult
õõ !
<
õõ! "%
NotificationResponseDto
õõ" 9
>
õõ9 :
>
õõ: ;
GetAllAsync
õõ< G
(
õõG H
int
úú 
page
úú 
,
úú 
int
úú 
pageSize
úú 
)
úú 
{
ùù 
var
ûû 
all
ûû 
=
ûû 
await
ûû 
_repo
ûû 
.
ûû 
FindAllAsync
ûû *
(
ûû* +
)
ûû+ ,
;
ûû, -
var
üü 
paged
üü 
=
üü 
all
üü 
.
†† 
Skip
†† 
(
†† 
(
†† 
page
†† 
-
†† 
$num
†† 
)
†† 
*
†† 
pageSize
†† '
)
††' (
.
°° 
Take
°° 
(
°° 
pageSize
°° 
)
°° 
.
¢¢ 
Select
¢¢ 
(
¢¢ 
MapToDto
¢¢ 
)
¢¢ 
.
££ 
ToList
££ 
(
££ 
)
££ 
;
££ 
return
•• 
new
•• 
PagedResult
•• 
<
•• %
NotificationResponseDto
•• 6
>
••6 7
{
¶¶ 	
Items
ßß 
=
ßß 
paged
ßß 
,
ßß 

TotalCount
®® 
=
®® 
all
®® 
.
®® 
Count
®® "
,
®®" #

PageNumber
©© 
=
©© 
page
©© 
,
©© 
PageSize
™™ 
=
™™ 
pageSize
™™ 
}
´´ 	
;
´´	 

}
¨¨ 
private
ØØ 
static
ØØ %
NotificationResponseDto
ØØ *
MapToDto
ØØ+ 3
(
ØØ3 4 
NotificationEntity
ØØ4 F
n
ØØG H
)
ØØH I
=>
ØØJ L
new
ØØM P
(
ØØP Q
)
ØØQ R
{
∞∞ 
NotificationId
±± 
=
±± 
n
±± 
.
±± 
NotificationId
±± )
,
±±) *
RecipientId
≤≤ 
=
≤≤ 
n
≤≤ 
.
≤≤ 
RecipientId
≤≤ #
,
≤≤# $
SenderId
≥≥ 
=
≥≥ 
n
≥≥ 
.
≥≥ 
SenderId
≥≥ 
,
≥≥ 
Type
¥¥ 
=
¥¥ 
n
¥¥ 
.
¥¥ 
Type
¥¥ 
,
¥¥ 
Title
µµ 
=
µµ 
n
µµ 
.
µµ 
Title
µµ 
,
µµ 
Message
∂∂ 
=
∂∂ 
n
∂∂ 
.
∂∂ 
Message
∂∂ 
,
∂∂ 
	RelatedId
∑∑ 
=
∑∑ 
n
∑∑ 
.
∑∑ 
	RelatedId
∑∑ 
,
∑∑  
IsRead
∏∏ 
=
∏∏ 
n
∏∏ 
.
∏∏ 
IsRead
∏∏ 
,
∏∏ 
SentAt
ππ 
=
ππ 
n
ππ 
.
ππ 
SentAt
ππ 
,
ππ 
ReadAt
∫∫ 
=
∫∫ 
n
∫∫ 
.
∫∫ 
ReadAt
∫∫ 
}
ªª 
;
ªª 
}ºº º
xD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Services\INotificationService.cs
	namespace 	

ConnectHub
 
. 
Notification !
.! "
API" %
.% &
Services& .
;. /
public 
	interface  
INotificationService %
{ 
Task 
< 	#
NotificationResponseDto	  
>  !
	SendAsync" +
(+ ,
SendNotificationDto, ?
dto@ C
)C D
;D E
Task		 
<		 	
IList			 
<		 #
NotificationResponseDto		 &
>		& '
>		' (
SendBulkAsync		) 6
(		6 7$
BroadcastNotificationDto		7 O
dto		P S
)		S T
;		T U
Task

 
<

 	
IList

	 
<

 #
NotificationResponseDto

 &
>

& '
>

' (
GetByRecipientAsync

) <
(

< =
int

= @
recipientId

A L
)

L M
;

M N
Task 
< 	
IList	 
< #
NotificationResponseDto &
>& '
>' (
GetUnreadAsync) 7
(7 8
int8 ;
recipientId< G
)G H
;H I
Task 
< 	
int	 
> 
GetUnreadCountAsync !
(! "
int" %
recipientId& 1
)1 2
;2 3
Task 
< 	#
NotificationResponseDto	  
>  !
MarkAsReadAsync" 1
(1 2
int2 5
notificationId6 D
)D E
;E F
Task 
MarkAllReadAsync	 
( 
int 
recipientId )
)) *
;* +
Task 
< 	
bool	 
> 
DeleteAsync 
( 
int 
notificationId -
)- .
;. /
Task 
< 	
PagedResult	 
< #
NotificationResponseDto ,
>, -
>- .
GetAllAsync/ :
(: ;
int; >
page? C
,C D
intE H
pageSizeI Q
)Q R
;R S
} â
qD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Services\IEmailService.cs
	namespace 	

ConnectHub
 
. 
Notification !
.! "
API" %
.% &
Services& .
;. /
public 
	interface 
IEmailService 
{ 
Task 
SendEmailAsync	 
(  
EmailNotificationDto ,
dto- 0
)0 1
;1 2
} Ÿ%
pD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Services\EmailService.cs
	namespace 	

ConnectHub
 
. 
Notification !
.! "
API" %
.% &
Services& .
;. /
public 
class 
EmailService 
: 
IEmailService )
{		 
private

 
readonly

 
IConfiguration

 #
_config

$ +
;

+ ,
private 
readonly 
ILogger 
< 
EmailService )
>) *
_logger+ 2
;2 3
public 

EmailService 
( 
IConfiguration &
config' -
,- .
ILogger/ 6
<6 7
EmailService7 C
>C D
loggerE K
)K L
{ 
_config 
= 
config 
; 
_logger 
= 
logger 
; 
} 
public 

async 
Task 
SendEmailAsync $
($ % 
EmailNotificationDto% 9
dto: =
)= >
{ 
try 
{ 	
var 
email 
= 
new 
MimeMessage '
(' (
)( )
;) *
email 
. 
From 
. 
Add 
( 
new 
MailboxAddress -
(- .
_config 
[ 
$str *
]* +
??, .
$str/ ;
,; <
_config 
[ 
$str +
]+ ,
??- /
$str0 H
)H I
)I J
;J K
email 
. 
To 
. 
Add 
( 
new 
MailboxAddress +
(+ ,
dto, /
./ 0
ToName0 6
,6 7
dto8 ;
.; <
ToEmail< C
)C D
)D E
;E F
email!! 
.!! 
Subject!! 
=!! 
dto!! 
.!!  
Subject!!  '
;!!' (
var$$ 
bodyBuilder$$ 
=$$ 
new$$ !
BodyBuilder$$" -
{%% 
HtmlBody&& 
=&& 
$@"&& 
$str&) 
{)) 
dto))  
.))  !
Subject))! (
}))( )
$str)*) 
{** 
dto** 
.**  
Body**  $
}**$ %
$str*/% 
"// 
,// 
TextBody00 
=00 
dto00 
.00 
Body00 #
}11 
;11 
email33 
.33 
Body33 
=33 
bodyBuilder33 $
.33$ %
ToMessageBody33% 2
(332 3
)333 4
;334 5
using55 
var55 
smtp55 
=55 
new55  

SmtpClient55! +
(55+ ,
)55, -
;55- .
await77 
smtp77 
.77 
ConnectAsync77 #
(77# $
_config88 
[88 
$str88 (
]88( )
??88* ,
$str88- =
,88= >
int99 
.99 
Parse99 
(99 
_config99 !
[99! "
$str99" 2
]992 3
??994 6
$str997 <
)99< =
,99= >
SecureSocketOptions:: #
.::# $
StartTls::$ ,
)::, -
;::- .
await<< 
smtp<< 
.<< 
AuthenticateAsync<< (
(<<( )
_config== 
[== 
$str== (
]==( )
,==) *
_config>> 
[>> 
$str>> (
]>>( )
)>>) *
;>>* +
await@@ 
smtp@@ 
.@@ 
	SendAsync@@  
(@@  !
email@@! &
)@@& '
;@@' (
awaitAA 
smtpAA 
.AA 
DisconnectAsyncAA &
(AA& '
trueAA' +
)AA+ ,
;AA, -
_loggerCC 
.CC 
LogInformationCC "
(CC" #
$strCC# :
,CC: ;
dtoCC< ?
.CC? @
ToEmailCC@ G
)CCG H
;CCH I
}DD 	
catchEE 
(EE 
	ExceptionEE 
exEE 
)EE 
{FF 	
_loggerGG 
.GG 
LogErrorGG 
(GG 
exGG 
,GG  
$strGG! H
,GGH I
dtoGGJ M
.GGM N
ToEmailGGN U
)GGU V
;GGV W
}II 	
}JJ 
}KK ˆA
~D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Repositories\NotificationRepository.cs
	namespace 	

ConnectHub
 
. 
Notification !
.! "
API" %
.% &
Repositories& 2
;2 3
public 
class "
NotificationRepository #
:$ %#
INotificationRepository& =
{ 
private		 
readonly		 !
NotificationDbContext		 *
_context		+ 3
;		3 4
public 
"
NotificationRepository !
(! "!
NotificationDbContext" 7
context8 ?
)? @
{ 
_context 
= 
context 
; 
} 
public 

async 
Task 
< 
NotificationEntity (
?( )
>) *
FindByIdAsync+ 8
(8 9
int9 <
notificationId= K
)K L
=>M O
await 
_context 
. 
Notifications $
. 
FirstOrDefaultAsync  
(  !
n! "
=># %
n& '
.' (
NotificationId( 6
==7 9
notificationId: H
)H I
;I J
public 

async 
Task 
< 
IList 
< 
NotificationEntity .
>. /
>/ 0"
FindByRecipientIdAsync1 G
(G H
intH K
recipientIdL W
)W X
=>Y [
await 
_context 
. 
Notifications $
. 
Where 
( 
n 
=> 
n 
. 
RecipientId %
==& (
recipientId) 4
)4 5
. 
OrderByDescending 
( 
n  
=>! #
n$ %
.% &
SentAt& ,
), -
. 
ToListAsync 
( 
) 
; 
public 

async 
Task 
< 
IList 
< 
NotificationEntity .
>. /
>/ 0(
FindUnreadByRecipientIdAsync1 M
(M N
intN Q
recipientIdR ]
)] ^
=>_ a
await 
_context 
. 
Notifications $
. 
Where 
( 
n 
=> 
n 
. 
RecipientId %
==& (
recipientId) 4
&&5 7
!8 9
n9 :
.: ;
IsRead; A
)A B
. 
OrderByDescending 
( 
n  
=>! #
n$ %
.% &
SentAt& ,
), -
. 
ToListAsync 
( 
) 
; 
public 

async 
Task 
< 
int 
> )
CountUnreadByRecipientIdAsync 8
(8 9
int9 <
recipientId= H
)H I
=>J L
await   
_context   
.   
Notifications   $
.!! 

CountAsync!! 
(!! 
n!! 
=>!! 
n!! 
.!! 
RecipientId!! *
==!!+ -
recipientId!!. 9
&&!!: <
!!!= >
n!!> ?
.!!? @
IsRead!!@ F
)!!F G
;!!G H
public## 

async## 
Task## 
<## 
IList## 
<## 
NotificationEntity## .
>##. /
>##/ 0
FindAllAsync##1 =
(##= >
)##> ?
=>##@ B
await$$ 
_context$$ 
.$$ 
Notifications$$ $
.%% 
OrderByDescending%% 
(%% 
n%%  
=>%%! #
n%%$ %
.%%% &
SentAt%%& ,
)%%, -
.&& 
ToListAsync&& 
(&& 
)&& 
;&& 
public(( 

async(( 
Task(( 
<(( 
NotificationEntity(( (
>((( )
CreateAsync((* 5
(((5 6
NotificationEntity((6 H
notification((I U
)((U V
{)) 
_context** 
.** 
Notifications** 
.** 
Add** "
(**" #
notification**# /
)**/ 0
;**0 1
await++ 
_context++ 
.++ 
SaveChangesAsync++ '
(++' (
)++( )
;++) *
return,, 
notification,, 
;,, 
}-- 
public// 

async// 
Task// 
<// 
IList// 
<// 
NotificationEntity// .
>//. /
>/// 0
CreateManyAsync//1 @
(//@ A
IList//A F
<//F G
NotificationEntity//G Y
>//Y Z
notifications//[ h
)//h i
{00 
_context11 
.11 
Notifications11 
.11 
AddRange11 '
(11' (
notifications11( 5
)115 6
;116 7
await22 
_context22 
.22 
SaveChangesAsync22 '
(22' (
)22( )
;22) *
return33 
notifications33 
;33 
}44 
public66 

async66 
Task66 
<66 
NotificationEntity66 (
>66( )
UpdateAsync66* 5
(665 6
NotificationEntity666 H
notification66I U
)66U V
{77 
_context88 
.88 
Notifications88 
.88 
Update88 %
(88% &
notification88& 2
)882 3
;883 4
await99 
_context99 
.99 
SaveChangesAsync99 '
(99' (
)99( )
;99) *
return:: 
notification:: 
;:: 
};; 
public== 

async== 
Task== )
MarkAllReadByRecipientIdAsync== 3
(==3 4
int==4 7
recipientId==8 C
)==C D
{>> 
var?? 
unread?? 
=?? 
await?? 
_context?? #
.??# $
Notifications??$ 1
.@@ 
Where@@ 
(@@ 
n@@ 
=>@@ 
n@@ 
.@@ 
RecipientId@@ %
==@@& (
recipientId@@) 4
&&@@5 7
!@@8 9
n@@9 :
.@@: ;
IsRead@@; A
)@@A B
.AA 
ToListAsyncAA 
(AA 
)AA 
;AA 
foreachCC 
(CC 
varCC 
nCC 
inCC 
unreadCC  
)CC  !
{DD 	
nEE 
.EE 
IsReadEE 
=EE 
trueEE 
;EE 
nFF 
.FF 
ReadAtFF 
=FF 
DateTimeFF 
.FF  
UtcNowFF  &
;FF& '
}GG 	
awaitII 
_contextII 
.II 
SaveChangesAsyncII '
(II' (
)II( )
;II) *
}JJ 
publicLL 

asyncLL 
TaskLL 
<LL 
boolLL 
>LL 
DeleteAsyncLL '
(LL' (
intLL( +
notificationIdLL, :
)LL: ;
{MM 
varNN 
notificationNN 
=NN 
awaitNN  
_contextNN! )
.NN) *
NotificationsNN* 7
.NN7 8
	FindAsyncNN8 A
(NNA B
notificationIdNNB P
)NNP Q
;NNQ R
ifOO 

(OO 
notificationOO 
isOO 
nullOO  
)OO  !
returnOO" (
falseOO) .
;OO. /
_contextPP 
.PP 
NotificationsPP 
.PP 
RemovePP %
(PP% &
notificationPP& 2
)PP2 3
;PP3 4
awaitQQ 
_contextQQ 
.QQ 
SaveChangesAsyncQQ '
(QQ' (
)QQ( )
;QQ) *
returnRR 
trueRR 
;RR 
}SS 
}TT î
D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Repositories\INotificationRepository.cs
	namespace 	

ConnectHub
 
. 
Notification !
.! "
API" %
.% &
Repositories& 2
;2 3
public 
	interface #
INotificationRepository (
{ 
Task 
< 	
NotificationEntity	 
? 
> 
FindByIdAsync +
(+ ,
int, /
notificationId0 >
)> ?
;? @
Task 
< 	
IList	 
< 
NotificationEntity !
>! "
>" #(
FindUnreadByRecipientIdAsync$ @
(@ A
intA D
recipientIdE P
)P Q
;Q R
Task		 
<		 	
IList			 
<		 
NotificationEntity		 !
>		! "
>		" #"
FindByRecipientIdAsync		$ :
(		: ;
int		; >
recipientId		? J
)		J K
;		K L
Task

 
<

 	
int

	 
>

 )
CountUnreadByRecipientIdAsync

 +
(

+ ,
int

, /
recipientId

0 ;
)

; <
;

< =
Task 
< 	
IList	 
< 
NotificationEntity !
>! "
>" #
FindAllAsync$ 0
(0 1
)1 2
;2 3
Task 
< 	
NotificationEntity	 
> 
CreateAsync (
(( )
NotificationEntity) ;
notification< H
)H I
;I J
Task 
< 	
IList	 
< 
NotificationEntity !
>! "
>" #
CreateManyAsync$ 3
(3 4
IList4 9
<9 :
NotificationEntity: L
>L M
notificationsN [
)[ \
;\ ]
Task 
< 	
NotificationEntity	 
> 
UpdateAsync (
(( )
NotificationEntity) ;
notification< H
)H I
;I J
Task )
MarkAllReadByRecipientIdAsync	 &
(& '
int' *
recipientId+ 6
)6 7
;7 8
Task 
< 	
bool	 
> 
DeleteAsync 
( 
int 
notificationId -
)- .
;. /
} ¯n
bD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Program.cs
var 
builder 
= 
WebApplication 
. 
CreateBuilder *
(* +
args+ /
)/ 0
;0 1
Log 
. 
Logger 

= 
new 
LoggerConfiguration $
($ %
)% &
. 
WriteTo 
. 
Console 
( 
) 
. 
CreateLogger 
( 
) 
; 
builder 
. 
Host 
. 

UseSerilog 
( 
) 
; 
builder 
. 
Services 
. 
AddDbContext 
< !
NotificationDbContext 3
>3 4
(4 5
options5 <
=>= ?
{ 
var 
connectionString 
= 
( 
builder #
.# $
Configuration$ 1
.1 2
GetConnectionString2 E
(E F
$strF Y
)Y Z
?? 

builder 
. 
Configuration  
[  !
$str! /
]/ 0
??1 3
$str4 6
)6 7
.7 8
Trim8 <
(< =
)= >
;> ?
options 
. 
	UseNpgsql 
( 
connectionString &
,& '
npgsql 
=> 
npgsql 
. "
MigrationsHistoryTable /
(/ 0
$str0 T
)T U
)U V
;V W
} 
) 
; 
builder!! 
.!! 
Services!! 
.!! 
	AddScoped!! 
<!! #
INotificationRepository!! 2
,!!2 3"
NotificationRepository!!4 J
>!!J K
(!!K L
)!!L M
;!!M N
builder"" 
."" 
Services"" 
."" 
	AddScoped"" 
<""  
INotificationService"" /
,""/ 0
NotificationService""1 D
>""D E
(""E F
)""F G
;""G H
builder## 
.## 
Services## 
.## 
	AddScoped## 
<## 
IEmailService## (
,##( )
EmailService##* 6
>##6 7
(##7 8
)##8 9
;##9 :
var&& 
	jwtSecret&& 
=&& 
builder&& 
.&& 
Configuration&& %
[&&% &
$str&&& /
]&&/ 0
!&&0 1
;&&1 2
builder'' 
.'' 
Services'' 
.'' 
AddAuthentication'' "
(''" #
JwtBearerDefaults''# 4
.''4 5 
AuthenticationScheme''5 I
)''I J
.(( 
AddJwtBearer(( 
((( 
options(( 
=>(( 
{)) 
options** 
.** %
TokenValidationParameters** )
=*** +
new**, /%
TokenValidationParameters**0 I
{++ 	
ValidateIssuer,, 
=,, 
true,, !
,,,! "
ValidateAudience-- 
=-- 
true-- #
,--# $
ValidateLifetime.. 
=.. 
true.. #
,..# $$
ValidateIssuerSigningKey// $
=//% &
true//' +
,//+ ,
ValidIssuer00 
=00 
builder00 !
.00! "
Configuration00" /
[00/ 0
$str000 <
]00< =
,00= >
ValidAudience11 
=11 
builder11 #
.11# $
Configuration11$ 1
[111 2
$str112 @
]11@ A
,11A B
IssuerSigningKey22 
=22 
new22 " 
SymmetricSecurityKey22# 7
(227 8
Encoding33 
.33 
UTF833 
.33 
GetBytes33 &
(33& '
	jwtSecret33' 0
)330 1
)331 2
}44 	
;44	 

options77 
.77 
Events77 
=77 
new77 
JwtBearerEvents77 ,
{88 	
OnMessageReceived99 
=99 
context99  '
=>99( *
{:: 
var;; 
accessToken;; 
=;;  !
context;;" )
.;;) *
Request;;* 1
.;;1 2
Query;;2 7
[;;7 8
$str;;8 F
];;F G
;;;G H
var<< 
path<< 
=<< 
context<< "
.<<" #
HttpContext<<# .
.<<. /
Request<</ 6
.<<6 7
Path<<7 ;
;<<; <
if== 
(== 
!== 
string== 
.== 
IsNullOrEmpty== )
(==) *
accessToken==* 5
)==5 6
&&==7 9
path>> 
.>> 
StartsWithSegments>> +
(>>+ ,
$str>>, A
)>>A B
)>>B C
{?? 
context@@ 
.@@ 
Token@@ !
=@@" #
accessToken@@$ /
;@@/ 0
}AA 
returnBB 
TaskBB 
.BB 
CompletedTaskBB )
;BB) *
}CC 
}DD 	
;DD	 

}EE 
)EE 
;EE 
builderGG 
.GG 
ServicesGG 
.GG 
AddAuthorizationGG !
(GG! "
)GG" #
;GG# $
builderJJ 
.JJ 
ServicesJJ 
.JJ 
AddSingletonJJ 
<JJ 
IUserIdProviderJJ -
,JJ- .
UserIdProviderJJ/ =
>JJ= >
(JJ> ?
)JJ? @
;JJ@ A
builderMM 
.MM 
ServicesMM 
.MM 

AddSignalRMM 
(MM 
optionsMM #
=>MM$ &
{NN 
optionsOO 
.OO  
EnableDetailedErrorsOO  
=OO! "
trueOO# '
;OO' (
optionsPP 
.PP 
KeepAliveIntervalPP 
=PP 
TimeSpanPP  (
.PP( )
FromSecondsPP) 4
(PP4 5
$numPP5 7
)PP7 8
;PP8 9
optionsQQ 
.QQ !
ClientTimeoutIntervalQQ !
=QQ" #
TimeSpanQQ$ ,
.QQ, -
FromSecondsQQ- 8
(QQ8 9
$numQQ9 ;
)QQ; <
;QQ< =
}RR 
)RR 
.SS 
AddJsonProtocolSS 
(SS 
optionsSS 
=>SS 
{SS 
optionsTT 
.TT $
PayloadSerializerOptionsTT $
.TT$ % 
PropertyNamingPolicyTT% 9
=TT: ;
SystemTT< B
.TTB C
TextTTC G
.TTG H
JsonTTH L
.TTL M
JsonNamingPolicyTTM ]
.TT] ^
	CamelCaseTT^ g
;TTg h
optionsUU 
.UU $
PayloadSerializerOptionsUU $
.UU$ %

ConvertersUU% /
.UU/ 0
AddUU0 3
(UU3 4
newUU4 7
SystemUU8 >
.UU> ?
TextUU? C
.UUC D
JsonUUD H
.UUH I
SerializationUUI V
.UUV W#
JsonStringEnumConverterUUW n
(UUn o
)UUo p
)UUp q
;UUq r
}VV 
)VV 
;VV 
builder[[ 
.[[ 
Services[[ 
.[[ #
AddEndpointsApiExplorer[[ (
([[( )
)[[) *
;[[* +
builder\\ 
.\\ 
Services\\ 
.\\ 
AddSwaggerGen\\ 
(\\ 
c\\  
=>\\! #
{]] 
c^^ 
.^^ 

SwaggerDoc^^ 
(^^ 
$str^^ 
,^^ 
new^^ 
OpenApiInfo^^ &
{__ 
Title`` 
=`` 
$str`` -
,``- .
Versionaa 
=aa 
$straa 
,aa 
Descriptionbb 
=bb 
$strbb ?
}cc 
)cc 
;cc 
cdd 
.dd !
AddSecurityDefinitiondd 
(dd 
$strdd $
,dd$ %
newdd& )!
OpenApiSecuritySchemedd* ?
{ee 
Descriptionff 
=ff 
$strff 3
,ff3 4
Namegg 
=gg 
$strgg 
,gg 
Inhh 

=hh 
ParameterLocationhh 
.hh 
Headerhh %
,hh% &
Typeii 
=ii 
SecuritySchemeTypeii !
.ii! "
ApiKeyii" (
,ii( )
Schemejj 
=jj 
$strjj 
}kk 
)kk 
;kk 
cll 
.ll "
AddSecurityRequirementll 
(ll 
newll  &
OpenApiSecurityRequirementll! ;
{mm 
{nn 	
newoo !
OpenApiSecuritySchemeoo %
{pp 
	Referenceqq 
=qq 
newqq 
OpenApiReferenceqq  0
{rr 
Typess 
=ss 
ReferenceTypess (
.ss( )
SecuritySchemess) 7
,ss7 8
Idtt 
=tt 
$strtt !
}uu 
}vv 
,vv 
Arrayww 
.ww 
Emptyww 
<ww 
stringww 
>ww 
(ww  
)ww  !
}xx 	
}yy 
)yy 
;yy 
}zz 
)zz 
;zz 
builder}} 
.}} 
Services}} 
.}} 
AddCors}} 
(}} 
options}}  
=>}}! #
{~~ 
options 
. 
	AddPolicy 
( 
$str  
,  !
policy" (
=>) +
policy
ÄÄ 
.
ÅÅ 
AllowAnyMethod
ÅÅ 
(
ÅÅ 
)
ÅÅ 
.
ÇÇ 
AllowAnyHeader
ÇÇ 
(
ÇÇ 
)
ÇÇ 
.
ÉÉ 
AllowCredentials
ÉÉ 
(
ÉÉ 
)
ÉÉ 
.
ÑÑ  
SetIsOriginAllowed
ÑÑ 
(
ÑÑ  
_
ÑÑ  !
=>
ÑÑ" $
true
ÑÑ% )
)
ÑÑ) *
)
ÑÑ* +
;
ÑÑ+ ,
}ÖÖ 
)
ÖÖ 
;
ÖÖ 
builderàà 
.
àà 
Services
àà 
.
àà 
AddControllers
àà 
(
àà  
)
àà  !
.
ââ 
AddJsonOptions
ââ 
(
ââ 
options
ââ 
=>
ââ 
{
ââ  
options
ää 
.
ää #
JsonSerializerOptions
ää %
.
ää% &"
PropertyNamingPolicy
ää& :
=
ää; <
System
ää= C
.
ääC D
Text
ääD H
.
ääH I
Json
ääI M
.
ääM N
JsonNamingPolicy
ääN ^
.
ää^ _
	CamelCase
ää_ h
;
ääh i
options
ãã 
.
ãã #
JsonSerializerOptions
ãã %
.
ãã% &

Converters
ãã& 0
.
ãã0 1
Add
ãã1 4
(
ãã4 5
new
ãã5 8
System
ãã9 ?
.
ãã? @
Text
ãã@ D
.
ããD E
Json
ããE I
.
ããI J
Serialization
ããJ W
.
ããW X%
JsonStringEnumConverter
ããX o
(
ãão p
)
ããp q
)
ããq r
;
ããr s
}
åå 
)
åå 
;
åå 
varéé 
app
éé 
=
éé 	
builder
éé
 
.
éé 
Build
éé 
(
éé 
)
éé 
;
éé 
ifëë 
(
ëë 
app
ëë 
.
ëë 
Environment
ëë 
.
ëë 
IsDevelopment
ëë !
(
ëë! "
)
ëë" #
)
ëë# $
{íí 
app
ìì 
.
ìì 

UseSwagger
ìì 
(
ìì 
)
ìì 
;
ìì 
app
îî 
.
îî 
UseSwaggerUI
îî 
(
îî 
)
îî 
;
îî 
}ïï 
appóó 
.
óó &
UseSerilogRequestLogging
óó 
(
óó 
)
óó 
;
óó 
appòò 
.
òò 
UseCors
òò 
(
òò 
$str
òò 
)
òò 
;
òò 
appôô 
.
ôô 
UseAuthentication
ôô 
(
ôô 
)
ôô 
;
ôô 
appöö 
.
öö 
UseAuthorization
öö 
(
öö 
)
öö 
;
öö 
appõõ 
.
õõ 
MapControllers
õõ 
(
õõ 
)
õõ 
;
õõ 
appûû 
.
ûû 
MapHub
ûû 

<
ûû
 
NotificationHub
ûû 
>
ûû 
(
ûû 
$str
ûû 1
)
ûû1 2
;
ûû2 3
using°° 
(
°° 
var
°° 

scope
°° 
=
°° 
app
°° 
.
°° 
Services
°° 
.
°°  
CreateScope
°°  +
(
°°+ ,
)
°°, -
)
°°- .
{¢¢ 
var
££ 
db
££ 

=
££ 
scope
££ 
.
££ 
ServiceProvider
££ "
.
££" # 
GetRequiredService
££# 5
<
££5 6#
NotificationDbContext
££6 K
>
££K L
(
££L M
)
££M N
;
££N O
try
§§ 
{
•• 
db
¶¶ 

.
¶¶
 
Database
¶¶ 
.
¶¶ 
Migrate
¶¶ 
(
¶¶ 
)
¶¶ 
;
¶¶ 
}
ßß 
catch
®® 	
(
®®
 
	Exception
®® 
ex
®® 
)
®® 
{
©© 
Console
™™ 
.
™™ 
	WriteLine
™™ 
(
™™ 
$"
™™ 
$str
™™ 0
{
™™0 1
ex
™™1 3
.
™™3 4
Message
™™4 ;
}
™™; <
"
™™< =
)
™™= >
;
™™> ?
}
´´ 
}¨¨ 
appÆÆ 
.
ÆÆ 
Run
ÆÆ 
(
ÆÆ 
)
ÆÆ 	
;
ÆÆ	 
ñ
tD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Models\NotificationEntity.cs
	namespace 	

ConnectHub
 
. 
Notification !
.! "
API" %
.% &
Models& ,
;, -
public 
class 
NotificationEntity 
{ 
public 

int 
NotificationId 
{ 
get  #
;# $
set% (
;( )
}* +
[ 
Required 
] 
public 

int 
RecipientId 
{ 
get  
;  !
set" %
;% &
}' (
public 

int 
? 
SenderId 
{ 
get 
; 
set  #
;# $
}% &
public 

NotificationType 
Type  
{! "
get# &
;& '
set( +
;+ ,
}- .
=/ 0
NotificationType1 A
.A B
MESSAGEB I
;I J
[ 
Required 
, 
	MaxLength 
( 
$num 
) 
] 
public 

string 
Title 
{ 
get 
; 
set "
;" #
}$ %
=& '
string( .
.. /
Empty/ 4
;4 5
[ 
Required 
, 
	MaxLength 
( 
$num 
) 
] 
public 

string 
Message 
{ 
get 
;  
set! $
;$ %
}& '
=( )
string* 0
.0 1
Empty1 6
;6 7
public 

int 
? 
	RelatedId 
{ 
get 
;  
set! $
;$ %
}& '
public 

bool 
IsRead 
{ 
get 
; 
set !
;! "
}# $
=% &
false' ,
;, -
public 

DateTime 
SentAt 
{ 
get  
;  !
set" %
;% &
}' (
=) *
DateTime+ 3
.3 4
UtcNow4 :
;: ;
public   

DateTime   
?   
ReadAt   
{   
get   !
;  ! "
set  # &
;  & '
}  ( )
}!! î-
ÑD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Migrations\20260501085938_InitialPostgres.cs
	namespace 	

ConnectHub
 
. 
Notification !
.! "
API" %
.% &

Migrations& 0
{ 
public

 

partial

 
class

 
InitialPostgres

 (
:

) *
	Migration

+ 4
{ 
	protected 
override 
void 
Up  "
(" #
MigrationBuilder# 3
migrationBuilder4 D
)D E
{ 	
migrationBuilder 
. 
CreateTable (
(( )
name 
: 
$str %
,% &
columns 
: 
table 
=> !
new" %
{ 
NotificationId "
=# $
table% *
.* +
Column+ 1
<1 2
int2 5
>5 6
(6 7
type7 ;
:; <
$str= F
,F G
nullableH P
:P Q
falseR W
)W X
. 

Annotation #
(# $
$str$ D
,D E)
NpgsqlValueGenerationStrategyF c
.c d#
IdentityByDefaultColumnd {
){ |
,| }
RecipientId 
=  !
table" '
.' (
Column( .
<. /
int/ 2
>2 3
(3 4
type4 8
:8 9
$str: C
,C D
nullableE M
:M N
falseO T
)T U
,U V
SenderId 
= 
table $
.$ %
Column% +
<+ ,
int, /
>/ 0
(0 1
type1 5
:5 6
$str7 @
,@ A
nullableB J
:J K
trueL P
)P Q
,Q R
Type 
= 
table  
.  !
Column! '
<' (
int( +
>+ ,
(, -
type- 1
:1 2
$str3 <
,< =
nullable> F
:F G
falseH M
)M N
,N O
Title 
= 
table !
.! "
Column" (
<( )
string) /
>/ 0
(0 1
type1 5
:5 6
$str7 O
,O P
	maxLengthQ Z
:Z [
$num\ _
,_ `
nullablea i
:i j
falsek p
)p q
,q r
Message 
= 
table #
.# $
Column$ *
<* +
string+ 1
>1 2
(2 3
type3 7
:7 8
$str9 R
,R S
	maxLengthT ]
:] ^
$num_ c
,c d
nullablee m
:m n
falseo t
)t u
,u v
	RelatedId 
= 
table  %
.% &
Column& ,
<, -
int- 0
>0 1
(1 2
type2 6
:6 7
$str8 A
,A B
nullableC K
:K L
trueM Q
)Q R
,R S
IsRead 
= 
table "
." #
Column# )
<) *
bool* .
>. /
(/ 0
type0 4
:4 5
$str6 ?
,? @
nullableA I
:I J
falseK P
)P Q
,Q R
SentAt 
= 
table "
." #
Column# )
<) *
DateTime* 2
>2 3
(3 4
type4 8
:8 9
$str: T
,T U
nullableV ^
:^ _
false` e
)e f
,f g
ReadAt 
= 
table "
." #
Column# )
<) *
DateTime* 2
>2 3
(3 4
type4 8
:8 9
$str: T
,T U
nullableV ^
:^ _
true` d
)d e
} 
, 
constraints 
: 
table "
=># %
{   
table!! 
.!! 

PrimaryKey!! $
(!!$ %
$str!!% 7
,!!7 8
x!!9 :
=>!!; =
x!!> ?
.!!? @
NotificationId!!@ N
)!!N O
;!!O P
}"" 
)"" 
;"" 
migrationBuilder$$ 
.$$ 
CreateIndex$$ (
($$( )
name%% 
:%% 
$str%% 4
,%%4 5
table&& 
:&& 
$str&& &
,&&& '
column'' 
:'' 
$str'' %
)''% &
;''& '
migrationBuilder)) 
.)) 
CreateIndex)) (
())( )
name** 
:** 
$str** ;
,**; <
table++ 
:++ 
$str++ &
,++& '
columns,, 
:,, 
new,, 
[,, 
],, 
{,,  
$str,,! .
,,,. /
$str,,0 8
},,9 :
),,: ;
;,,; <
}-- 	
	protected00 
override00 
void00 
Down00  $
(00$ %
MigrationBuilder00% 5
migrationBuilder006 F
)00F G
{11 	
migrationBuilder22 
.22 
	DropTable22 &
(22& '
name33 
:33 
$str33 %
)33% &
;33& '
}44 	
}55 
}66 ¬

nD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Hubs\UserIdProvider.cs
	namespace 	

ConnectHub
 
. 
Notification !
.! "
API" %
.% &
Hubs& *
;* +
public 
class 
UserIdProvider 
: 
IUserIdProvider -
{ 
public 

string 
? 
	GetUserId 
(  
HubConnectionContext 1

connection2 <
)< =
{		 
return 

connection 
. 
User 
? 
.  
	FindFirst  )
() *
$str* /
)/ 0
?0 1
.1 2
Value2 7
?? 

connection 
. 
User 
? 
.  
	FindFirst  )
() *

ClaimTypes* 4
.4 5
NameIdentifier5 C
)C D
?D E
.E F
ValueF K
?? 

connection 
. 
User 
? 
.  
	FindFirst  )
() *
$str* /
)/ 0
?0 1
.1 2
Value2 7
;7 8
} 
} Å
oD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Hubs\NotificationHub.cs
	namespace 	

ConnectHub
 
. 
Notification !
.! "
API" %
.% &
Hubs& *
;* +
[ 
	Authorize 

]
 
public 
class 
NotificationHub 
: 
Hub "
{ 
private		 
readonly		 
ILogger		 
<		 
NotificationHub		 ,
>		, -
_logger		. 5
;		5 6
public 

NotificationHub 
( 
ILogger "
<" #
NotificationHub# 2
>2 3
logger4 :
): ;
{ 
_logger 
= 
logger 
; 
} 
public 

override 
async 
Task 
OnConnectedAsync /
(/ 0
)0 1
{ 
var 
userId 
= 
Context 
. 
User !
?! "
." #
	FindFirst# ,
(, -
$str- 2
)2 3
?3 4
.4 5
Value5 :
?? 
Context 
. 
User !
?! "
." #
	FindFirst# ,
(, -
System 
. 
Security %
.% &
Claims& ,
., -

ClaimTypes- 7
.7 8
NameIdentifier8 F
)F G
?G H
.H I
ValueI N
;N O
_logger 
. 
LogInformation 
( 
$str 8
,8 9
userId: @
)@ A
;A B
await 
base 
. 
OnConnectedAsync #
(# $
)$ %
;% &
} 
public 

override 
async 
Task 
OnDisconnectedAsync 2
(2 3
	Exception3 <
?< =
	exception> G
)G H
{ 
var 
userId 
= 
Context 
. 
User !
?! "
." #
	FindFirst# ,
(, -
$str- 2
)2 3
?3 4
.4 5
Value5 :
;: ;
_logger 
. 
LogInformation 
( 
$str   =
,  = >
userId  ? E
)  E F
;  F G
await"" 
base"" 
."" 
OnDisconnectedAsync"" &
(""& '
	exception""' 0
)""0 1
;""1 2
}## 
}$$ é
sD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\DTOs\SendNotificationDto.cs
	namespace 	

ConnectHub
 
. 
Notification !
.! "
API" %
.% &
DTOs& *
;* +
public 
class 
SendNotificationDto  
{ 
[ 
Required 
] 
public		 

int		 
RecipientId		 
{		 
get		  
;		  !
set		" %
;		% &
}		' (
public 

int 
? 
SenderId 
{ 
get 
; 
set  #
;# $
}% &
public 

NotificationType 
Type  
{! "
get# &
;& '
set( +
;+ ,
}- .
=/ 0
NotificationType1 A
.A B
MESSAGEB I
;I J
[ 
Required 
, 
	MaxLength 
( 
$num 
) 
] 
public 

string 
Title 
{ 
get 
; 
set "
;" #
}$ %
=& '
string( .
.. /
Empty/ 4
;4 5
[ 
Required 
, 
	MaxLength 
( 
$num 
) 
] 
public 

string 
Message 
{ 
get 
;  
set! $
;$ %
}& '
=( )
string* 0
.0 1
Empty1 6
;6 7
public 

int 
? 
	RelatedId 
{ 
get 
;  
set! $
;$ %
}& '
} Ï
wD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\DTOs\NotificationResponseDto.cs
	namespace 	

ConnectHub
 
. 
Notification !
.! "
API" %
.% &
DTOs& *
;* +
public 
class #
NotificationResponseDto $
{ 
public 

int 
NotificationId 
{ 
get  #
;# $
set% (
;( )
}* +
public 

int 
RecipientId 
{ 
get  
;  !
set" %
;% &
}' (
public		 

int		 
?		 
SenderId		 
{		 
get		 
;		 
set		  #
;		# $
}		% &
public

 

NotificationType

 
Type

  
{

! "
get

# &
;

& '
set

( +
;

+ ,
}

- .
public 

string 
Title 
{ 
get 
; 
set "
;" #
}$ %
=& '
string( .
.. /
Empty/ 4
;4 5
public 

string 
Message 
{ 
get 
;  
set! $
;$ %
}& '
=( )
string* 0
.0 1
Empty1 6
;6 7
public 

int 
? 
	RelatedId 
{ 
get 
;  
set! $
;$ %
}& '
public 

bool 
IsRead 
{ 
get 
; 
set !
;! "
}# $
public 

DateTime 
SentAt 
{ 
get  
;  !
set" %
;% &
}' (
public 

DateTime 
? 
ReadAt 
{ 
get !
;! "
set# &
;& '
}( )
} Æ
tD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\DTOs\EmailNotificationDto.cs
	namespace 	

ConnectHub
 
. 
Notification !
.! "
API" %
.% &
DTOs& *
;* +
public 
class  
EmailNotificationDto !
{ 
[ 
Required 
, 
EmailAddress 
] 
public 

string 
ToEmail 
{ 
get 
;  
set! $
;$ %
}& '
=( )
string* 0
.0 1
Empty1 6
;6 7
[

 
Required

 
]

 
public 

string 
ToName 
{ 
get 
; 
set  #
;# $
}% &
=' (
string) /
./ 0
Empty0 5
;5 6
[ 
Required 
] 
public 

string 
Subject 
{ 
get 
;  
set! $
;$ %
}& '
=( )
string* 0
.0 1
Empty1 6
;6 7
[ 
Required 
] 
public 

string 
Body 
{ 
get 
; 
set !
;! "
}# $
=% &
string' -
.- .
Empty. 3
;3 4
} è
xD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\DTOs\BroadcastNotificationDto.cs
	namespace 	

ConnectHub
 
. 
Notification !
.! "
API" %
.% &
DTOs& *
;* +
public 
class $
BroadcastNotificationDto %
{ 
[ 
Required 
, 
	MaxLength 
( 
$num 
) 
] 
public		 

string		 
Title		 
{		 
get		 
;		 
set		 "
;		" #
}		$ %
=		& '
string		( .
.		. /
Empty		/ 4
;		4 5
[ 
Required 
, 
	MaxLength 
( 
$num 
) 
] 
public 

string 
Message 
{ 
get 
;  
set! $
;$ %
}& '
=( )
string* 0
.0 1
Empty1 6
;6 7
public 

List 
< 
int 
> 
RecipientIds !
{" #
get$ '
;' (
set) ,
;, -
}. /
=0 1
new2 5
(5 6
)6 7
;7 8
} Æ
uD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Data\NotificationDbContext.cs
	namespace 	

ConnectHub
 
. 
Notification !
.! "
API" %
.% &
Data& *
;* +
public 
class !
NotificationDbContext "
:# $
	DbContext% .
{ 
public 
!
NotificationDbContext  
(  !
DbContextOptions! 1
<1 2!
NotificationDbContext2 G
>G H
optionsI P
)P Q
:		 	
base		
 
(		 
options		 
)		 
{		 
}		 
public 

DbSet 
< 
NotificationEntity #
># $
Notifications% 2
=>3 5
Set6 9
<9 :
NotificationEntity: L
>L M
(M N
)N O
;O P
	protected 
override 
void 
OnModelCreating +
(+ ,
ModelBuilder, 8
modelBuilder9 E
)E F
{ 
base 
. 
OnModelCreating 
( 
modelBuilder )
)) *
;* +
modelBuilder 
. 
Entity 
< 
NotificationEntity .
>. /
(/ 0
entity0 6
=>7 9
{ 	
entity 
. 
HasKey 
( 
n 
=> 
n  
.  !
NotificationId! /
)/ 0
;0 1
entity 
. 
Property 
( 
n 
=>  
n! "
." #
Title# (
)( )
. 

IsRequired 
( 
) 
. 
HasMaxLength 
(  
$num  #
)# $
;$ %
entity 
. 
Property 
( 
n 
=>  
n! "
." #
Message# *
)* +
. 

IsRequired 
( 
) 
. 
HasMaxLength 
(  
$num  $
)$ %
;% &
entity 
. 
HasIndex 
( 
n 
=>  
n! "
." #
RecipientId# .
). /
. 
HasDatabaseName "
(" #
$str# A
)A B
;B C
entity!! 
.!! 
HasIndex!! 
(!! 
n!! 
=>!!  
new!!! $
{!!% &
n!!' (
.!!( )
RecipientId!!) 4
,!!4 5
n!!6 7
.!!7 8
IsRead!!8 >
}!!? @
)!!@ A
."" 
HasDatabaseName"" "
(""" #
$str""# H
)""H I
;""I J
}## 	
)##	 

;##
 
}$$ 
}%% ˚J
}D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Controllers\NotificationController.cs
	namespace 	

ConnectHub
 
. 
Notification !
.! "
API" %
.% &
Controllers& 1
;1 2
[		 
ApiController		 
]		 
[

 
Route

 
(

 
$str

 
)

 
]

 
[ 
	Authorize 

]
 
public 
class "
NotificationController #
:$ %
ControllerBase& 4
{ 
private 
readonly  
INotificationService )
_service* 2
;2 3
public 
"
NotificationController !
(! " 
INotificationService" 6
service7 >
)> ?
{ 
_service 
= 
service 
; 
} 
[ 
HttpPost 
( 
$str 
) 
] 
public 

async 
Task 
< 
IActionResult #
># $
Send% )
() *
[* +
FromBody+ 3
]3 4
SendNotificationDto5 H
dtoI L
)L M
{ 
var 
result 
= 
await 
_service #
.# $
	SendAsync$ -
(- .
dto. 1
)1 2
;2 3
return 
Ok 
( 
ApiResponse 
< #
NotificationResponseDto 5
>5 6
.6 7
Ok7 9
(9 :
result 
, 
$str 5
)5 6
)6 7
;7 8
} 
[ 
HttpPost 
( 
$str 
) 
] 
public   

async   
Task   
<   
IActionResult   #
>  # $
	Broadcast  % .
(  . /
[  / 0
FromBody  0 8
]  8 9$
BroadcastNotificationDto  : R
dto  S V
)  V W
{!! 
var"" 
result"" 
="" 
await"" 
_service"" #
.""# $
SendBulkAsync""$ 1
(""1 2
dto""2 5
)""5 6
;""6 7
return## 
Ok## 
(## 
ApiResponse## 
<## 
IList## #
<### $#
NotificationResponseDto##$ ;
>##; <
>##< =
.##= >
Ok##> @
(##@ A
result$$ 
,$$ 
$str$$ 2
)$$2 3
)$$3 4
;$$4 5
}%% 
[(( 
HttpGet(( 
((( 
$str(( *
)((* +
]((+ ,
public)) 

async)) 
Task)) 
<)) 
IActionResult)) #
>))# $
GetByRecipient))% 3
())3 4
int))4 7
recipientId))8 C
)))C D
{** 
var++ 
result++ 
=++ 
await++ 
_service++ #
.++# $
GetByRecipientAsync++$ 7
(++7 8
recipientId++8 C
)++C D
;++D E
return,, 
Ok,, 
(,, 
ApiResponse,, 
<,, 
IList,, #
<,,# $#
NotificationResponseDto,,$ ;
>,,; <
>,,< =
.,,= >
Ok,,> @
(,,@ A
result,,A G
),,G H
),,H I
;,,I J
}-- 
[00 
HttpGet00 
(00 
$str00 '
)00' (
]00( )
public11 

async11 
Task11 
<11 
IActionResult11 #
>11# $
	GetUnread11% .
(11. /
int11/ 2
recipientId113 >
)11> ?
{22 
var33 
result33 
=33 
await33 
_service33 #
.33# $
GetUnreadAsync33$ 2
(332 3
recipientId333 >
)33> ?
;33? @
return44 
Ok44 
(44 
ApiResponse44 
<44 
IList44 #
<44# $#
NotificationResponseDto44$ ;
>44; <
>44< =
.44= >
Ok44> @
(44@ A
result44A G
)44G H
)44H I
;44I J
}55 
[88 
HttpGet88 
(88 
$str88 -
)88- .
]88. /
public99 

async99 
Task99 
<99 
IActionResult99 #
>99# $
GetUnreadCount99% 3
(993 4
int994 7
recipientId998 C
)99C D
{:: 
var;; 
count;; 
=;; 
await;; 
_service;; "
.;;" #
GetUnreadCountAsync;;# 6
(;;6 7
recipientId;;7 B
);;B C
;;;C D
return<< 
Ok<< 
(<< 
ApiResponse<< 
<<< 
int<< !
><<! "
.<<" #
Ok<<# %
(<<% &
count<<& +
)<<+ ,
)<<, -
;<<- .
}== 
[@@ 
HttpPut@@ 
(@@ 
$str@@ (
)@@( )
]@@) *
publicAA 

asyncAA 
TaskAA 
<AA 
IActionResultAA #
>AA# $

MarkAsReadAA% /
(AA/ 0
intAA0 3
notificationIdAA4 B
)AAB C
{BB 
tryCC 
{DD 	
varEE 
resultEE 
=EE 
awaitEE 
_serviceEE '
.EE' (
MarkAsReadAsyncEE( 7
(EE7 8
notificationIdEE8 F
)EEF G
;EEG H
returnFF 
OkFF 
(FF 
ApiResponseFF !
<FF! "#
NotificationResponseDtoFF" 9
>FF9 :
.FF: ;
OkFF; =
(FF= >
resultGG 
,GG 
$strGG 6
)GG6 7
)GG7 8
;GG8 9
}HH 	
catchII 
(II  
KeyNotFoundExceptionII #
exII$ &
)II& '
{JJ 	
returnKK 
NotFoundKK 
(KK 
ApiResponseKK '
<KK' (
stringKK( .
>KK. /
.KK/ 0
FailKK0 4
(KK4 5
exKK5 7
.KK7 8
MessageKK8 ?
,KK? @
$numKKA D
)KKD E
)KKE F
;KKF G
}LL 	
}MM 
[PP 
HttpPutPP 
(PP 
$strPP )
)PP) *
]PP* +
publicQQ 

asyncQQ 
TaskQQ 
<QQ 
IActionResultQQ #
>QQ# $
MarkAllReadQQ% 0
(QQ0 1
intQQ1 4
recipientIdQQ5 @
)QQ@ A
{RR 
awaitSS 
_serviceSS 
.SS 
MarkAllReadAsyncSS '
(SS' (
recipientIdSS( 3
)SS3 4
;SS4 5
returnTT 
OkTT 
(TT 
ApiResponseTT 
<TT 
stringTT $
>TT$ %
.TT% &
OkTT& (
(TT( )
$strTT) L
)TTL M
)TTM N
;TTN O
}UU 
[XX 

HttpDeleteXX 
(XX 
$strXX &
)XX& '
]XX' (
publicYY 

asyncYY 
TaskYY 
<YY 
IActionResultYY #
>YY# $
DeleteYY% +
(YY+ ,
intYY, /
notificationIdYY0 >
)YY> ?
{ZZ 
var[[ 
success[[ 
=[[ 
await[[ 
_service[[ $
.[[$ %
DeleteAsync[[% 0
([[0 1
notificationId[[1 ?
)[[? @
;[[@ A
if\\ 

(\\ 
!\\ 
success\\ 
)\\ 
return]] 
NotFound]] 
(]] 
ApiResponse]] '
<]]' (
string]]( .
>]]. /
.]]/ 0
Fail]]0 4
(]]4 5
$str]]5 N
,]]N O
$num]]P S
)]]S T
)]]T U
;]]U V
return^^ 
Ok^^ 
(^^ 
ApiResponse^^ 
<^^ 
string^^ $
>^^$ %
.^^% &
Ok^^& (
(^^( )
$str^^) M
)^^M N
)^^N O
;^^O P
}__ 
[bb 
HttpGetbb 
(bb 
$strbb 
)bb 
]bb 
publiccc 

asynccc 
Taskcc 
<cc 
IActionResultcc #
>cc# $
GetAllcc% +
(cc+ ,
[dd 	
	FromQuerydd	 
]dd 
intdd 
pagedd 
=dd 
$numdd  
,dd  !
[ee 	
	FromQueryee	 
]ee 
intee 
pageSizeee  
=ee! "
$numee# %
)ee% &
{ff 
vargg 
resultgg 
=gg 
awaitgg 
_servicegg #
.gg# $
GetAllAsyncgg$ /
(gg/ 0
pagegg0 4
,gg4 5
pageSizegg6 >
)gg> ?
;gg? @
returnhh 
Okhh 
(hh 
ApiResponsehh 
<hh 
PagedResulthh )
<hh) *#
NotificationResponseDtohh* A
>hhA B
>hhB C
.hhC D
OkhhD F
(hhF G
resulthhG M
)hhM N
)hhN O
;hhO P
}ii 
}jj 