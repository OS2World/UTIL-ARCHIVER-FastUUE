const
{$IFDEF DPMI}  OS_Type = 'DOS';   OS_Name = 'DOS';     OS_Short = 'DOS'; OS_ID = $C0DEDEAD; {$DEFINE DOS} {$ENDIF}
{$IFDEF MSDOS} OS_Type = 'DOS';   OS_Name = 'DOS';     OS_Short = 'DOS'; OS_ID = $0BAD0ACE; {$DEFINE DOS} {$ENDIF}
{$IFDEF OS2}   OS_Type = '2';     OS_Name = 'OS/2';    OS_Short = 'OS2'; OS_ID = $0BAD0BED; {$ENDIF}
{$IFDEF WIN32} OS_Type = 'Win32'; OS_Name = 'Windows'; OS_Short = 'W32'; OS_ID = $0BAD0BAD; {$ENDIF}

{$I DATE.INC}
