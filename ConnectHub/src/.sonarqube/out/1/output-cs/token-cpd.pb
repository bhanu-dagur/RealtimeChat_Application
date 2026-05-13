ÿ
aD:\Projects\RealtimeChatApplication\ConnectHub\src\Shared\ConnectHub.Shared\Models\PagedResult.cs
	namespace 	

ConnectHub
 
. 
Shared 
. 
Models "
;" #
public 
class 
PagedResult 
< 
T 
> 
{ 
public 

IList 
< 
T 
> 
Items 
{ 
get 
;  
set! $
;$ %
}& '
=( )
new* -
List. 2
<2 3
T3 4
>4 5
(5 6
)6 7
;7 8
public 

int 

TotalCount 
{ 
get 
;  
set! $
;$ %
}& '
public 

int 

PageNumber 
{ 
get 
;  
set! $
;$ %
}& '
public 

int 
PageSize 
{ 
get 
; 
set "
;" #
}$ %
public		 

int		 

TotalPages		 
=>		 
(		 
int		 !
)		! "
Math		" &
.		& '
Ceiling		' .
(		. /
(		/ 0
double		0 6
)		6 7

TotalCount		7 A
/		B C
PageSize		D L
)		L M
;		M N
}

 í
aD:\Projects\RealtimeChatApplication\ConnectHub\src\Shared\ConnectHub.Shared\Models\ApiResponse.cs
	namespace 	

ConnectHub
 
. 
Shared 
. 
Models "
;" #
public 
class 
ApiResponse 
< 
T 
> 
{ 
public 

bool 
Success 
{ 
get 
; 
set "
;" #
}$ %
public 

T 
? 
Data 
{ 
get 
; 
set 
; 
}  
public 

string 
Message 
{ 
get 
;  
set! $
;$ %
}& '
=( )
string* 0
.0 1
Empty1 6
;6 7
public 

int 

StatusCode 
{ 
get 
;  
set! $
;$ %
}& '
public

 

static

 
ApiResponse

 
<

 
T

 
>

  
Ok

! #
(

# $
T

$ %
data

& *
,

* +
string

, 2
message

3 :
=

; <
$str

= F
)

F G
=>

H J
new 
( 
) 
{ 
Success 
= 
true 
, 
Data  $
=% &
data' +
,+ ,
Message- 4
=5 6
message7 >
,> ?

StatusCode@ J
=K L
$numM P
}Q R
;R S
public 

static 
ApiResponse 
< 
T 
>  
Fail! %
(% &
string& ,
message- 4
,4 5
int6 9

statusCode: D
=E F
$numG J
)J K
=>L N
new 
( 
) 
{ 
Success 
= 
false 
,  
Message! (
=) *
message+ 2
,2 3

StatusCode4 >
=? @

statusCodeA K
}L M
;M N
} è
]D:\Projects\RealtimeChatApplication\ConnectHub\src\Shared\ConnectHub.Shared\Enums\RoomType.cs
	namespace 	

ConnectHub
 
. 
Shared 
. 
Enums !
;! "
public 
enum 
RoomType 
{ 
PUBLIC 

,
 
PRIVATE 
, 
DIRECT 

} Ú
eD:\Projects\RealtimeChatApplication\ConnectHub\src\Shared\ConnectHub.Shared\Enums\NotificationType.cs
	namespace 	

ConnectHub
 
. 
Shared 
. 
Enums !
;! "
public 
enum 
NotificationType 
{ 
MESSAGE 
, 
MENTION 
, 
ROOM_INVITE 
, 
ROLE_CHANGE 
, 
PLATFORM		 
}

 ±
`D:\Projects\RealtimeChatApplication\ConnectHub\src\Shared\ConnectHub.Shared\Enums\MessageType.cs
	namespace 	

ConnectHub
 
. 
Shared 
. 
Enums !
;! "
public 
enum 
MessageType 
{ 
TEXT 
, 	
IMAGE 	
,	 

FILE 
, 	
AUDIO 	
}		 î
_D:\Projects\RealtimeChatApplication\ConnectHub\src\Shared\ConnectHub.Shared\Enums\MemberRole.cs
	namespace 	

ConnectHub
 
. 
Shared 
. 
Enums !
;! "
public 
enum 

MemberRole 
{ 
ADMIN 	
,	 

	MODERATOR 
, 
MEMBER 

} 