//ÛßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßÛ
//Û                                                       Û
//Û      Virtual Pascal Runtime Library.  Version 2.0.    Û
//Û      OS/2, Win32 REXX interface unit                  Û
//Û      ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÛ
//Û      Copyright (C) 1995-98 fPrint UK Ltd              Û
//Û      Copyright (C) 1999 sergey korowkin               Û
//Û                                                       Û
//ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß

{$DEFINE REGINAREXX}
{$IFNDEF VIRTUALPASCAL}
fuck off, guy!
{$ENDIF}

{$StdCall+,AlignRec-,OrgName+,Use32-}

unit Rexx;

interface

{$IFDEF OS2}
uses
     Os2Def;
{$ENDIF}

{ Common }
{ This section defines return codes and constants that are the }
{ same for both 16-bit and 32-bit REXX calls.                  }

const
  rxAutoBufLen                  = 256;

{$IFDEF WIN32}
type
 ULong = Longint;
 Long = Longint;
 ApiRet = Longint;
 PFn = Pointer;
 Pid = Longint;
 Tid = Longint;
{$ENDIF}

{ Record for external interface string (RXSTRING) }

type
  PRxString = ^RxString;
  RxString = record
    strlength: ULong;           { length of string  }
    strptr:    PChar;           { pointer to string }
  end;

{ Record for system exit block (RXSYSEXIT) 32-bit }

  PRxSysExit = ^RxSysExit;
  RxSysExit = record
     sysexit_name: PChar;       { subcom enviro for sysexit  }
     sysexit_code: Long;        { sysexit function code      }
  end;

{ Call type codes for use on interpreter startup }

const
  rxCommand                     = 0;    { Program called as Command    }
  rxSubroutine                  = 1;    { Program called as Subroutine }
  rxFunction                    = 2;    { Program called as Function   }

{ Subcommand Interface defines}

{ Drop Authority for RXSUBCOM interface }

  rxsubcom_Droppable            = $00;  { handler to be dropped by all }
  rxsubcom_NonDrop              = $01;  { process with same PID as the }
                                        { registrant may drop environ  }
{ Return Codes from RXSUBCOM interface }

  rxsubcom_IsReg                = $01;  { Subcommand is registered    }
  rxsubcom_Error                = $01;  { Subcommand Ended in Error   }
  rxsubcom_Failure              = $02;  { Subcommand Ended in Failure }
  rxsubcom_BadEntry             = 1001; { Invalid Entry Conditions    }
  rxsubcom_NoEMem               = 1002; { Insuff stor to complete req }
  rxsubcom_BadType              = 1003; { Bad registration type.      }
  rxsubcom_NotInit              = 1004; { API system not initialized. }
  rxsubcom_Ok                   = 0;    { Function Complete           }
  rxsubcom_Dup                  = 10;   { Duplicate Environment Name- }
                                        { but Registration Completed  }
  rxsubcom_MaxReg               = 20;   { Cannot register more        }
                                        { handlers                    }
  rxsubcom_NotReg               = 30;   { Name Not Registered         }
  rxsubcom_NoCanDrop            = 40;   { Name not droppable          }
  rxsubcom_LoadErr              = 50;   { Could not load function     }
  rxsubcom_NoProc               = 127;  { RXSUBCOM routine - not found}

{ Shared Variable Pool Interface defines }
{ Function Codes for Variable Pool Interface (shvcode) }

  rxshv_Set                     = $00;  { Set var from given value    }
  rxshv_Fetch                   = $01;  { Copy value of var to buffer }
  rxshv_DropV                   = $02;  { Drop variable               }
  rxshv_SySet                   = $03;  { Symbolic name Set variable  }
  rxshv_SyFet                   = $04;  { Symbolic name Fetch variable}
  rxshv_SyDro                   = $05;  { Symbolic name Drop variable }
  rxshv_NextV                   = $06;  { Fetch "next" variable       }
  rxshv_Priv                    = $07;  { Fetch private information   }
  rxshv_Exit                    = $08;  { Set function exit value     }

{  Return Codes for Variable Pool Interface }

  rxshv_NoAvl                   = 144;  { Interface not available     }

{ Return Code Flags for Variable Pool Interface (shvret) }

  rxshv_Ok                      = $00;  { Execution was OK            }
  rxshv_NewV                    = $01;  { Variable did not exist      }
  rxshv_LVar                    = $02;  { Last var trans via SHVNEXTV }
  rxshv_Trunc                   = $04;  { Truncation occurred-Fetch   }
  rxshv_BadN                    = $08;  { Invalid variable name       }
  rxshv_MemFl                   = $10;  { Out of memory failure       }
  rxshv_BadF                    = $80;  { Invalid funct code (shvcode)}

{ Record of Shared Variable Request Block (SHVBLOCK) }
type
  PShvBlock = ^ShvBlock;
  ShvBlock = record
    shvnext:     PShvBlock;           { pointer to the next block   }
    shvname:     RxString;            { Pointer to the name buffer  }
    shvvalue:    RxString;            { Pointer to the value buffer }
    shvnamelen:  ULong;               { Length of the name value    }
    shvvaluelen: ULong;               { Length of the fetch value   }
    shvcode:     Byte;                { Function code for this block}
    shvret:      Byte;                { Individual Return Code Flags}
  end;

{ External Function Interface }
{ Registration Type Identifiers for Available Function Table }
const
  rxfunc_DynaLink               = 1;  { Function Available in DLL  }
  rxfunc_CallEntry              = 2;  { Registered as mem entry pt.}

{ Return Codes from RxFunction interface }

  rxfunc_Ok                     = 0;  { REXX-API Call Successful   }
  rxfunc_Defined                = 10; { Function Defined in AFT    }
  rxfunc_NoMem                  = 20; { Not Enough Mem to Add      }
  rxfunc_NotReg                 = 30; { Funct Not Registered in AFT}
  rxfunc_ModNotFnd              = 40; { Funct Dll Module Not Found }
  rxfunc_EntNotFnd              = 50; { Funct Entry Point Not Found}
  rxfunc_NotInit                = 60; { API not initialized        }
  rxfunc_BadType                = 70; { Bad function type          }

{ System Exits defines }
{ Drop Authority for Rexx Exit interface }

  exit_Droppable                = 0;  { handle to be dropped by all }
  exit_NonDrop                  = 1;  { process with same PID as the}
                                      { registrant may drop environ }
{ Exit return actions }

  exit_Handled                  = 0;  { Exit handled exit event     }
  exit_Not_Handled              = 1;  { Exit passes on exit event   }
  exit_Raise_Error              = -1; { Exit handler error occurred }

{ Return Codes from RXEXIT interface }

  rxexit_IsReg                  = $01;  { Exit is registered          }
  rxexit_Error                  = $01;  { Exit Ended in Error         }
  rxexit_Failure                = $02;  { Exit Ended in Failure       }
  rxexit_BadEntry               = 1001; { Invalid Entry Conditions    }
  rxexit_NoEmem                 = 1002; { Insuff stor to complete req }
  rxexit_BadType                = 1003; { Bad registration type.      }
  rxexit_NotInit                = 1004; { API system not initialized. }
  rxexit_Ok                     = 0;    { Function Complete           }
  rxexit_Dup                    = 10;   { Duplicate Exit Name-        }
                                        { but Registration Completed  }
  rxexit_MaxReg                 = 20;   { Cannot register more        }
                                        { handlers                    }
  rxexit_NotReg                 = 30;   { Name Not Registered         }
  rxexit_NoCanDrop              = 40;   { Name not droppable          }
  rxexit_LoadErr                = 50;   { Could not load function     }
  rxexit_NoProc                 = 127;  { RXEXIT routine - not found  }

{ System Exit function and sub-function definitions }

  rxEndLst                      = 0;    { End of exit list.           }
  rxFnc                         = 2;    { Process external functions. }
  rxFncCal                      = 1;    { subcode value.              }
  rxCmd                         = 3;    { Process host commands.      }
  rxCmdHst                      = 1;    { subcode value.              }
  rxMsq                         = 4;    { Manipulate queue.           }
  rxMsqPll                      = 1;    { Pull a line from queue      }
  rxMsqPsh                      = 2;    { Place a line on queue       }
  rxMsqSiz                      = 3;    { Return num of lines on queue}
  rxMsqNam                      = 20;   { Set active queue name       }
  rxSio                         = 5;    { Session I/O.                }
  rxSioSay                      = 1;    { SAY a line to STDOUT        }
  rxSioTrc                      = 2;    { Trace output                }
  rxSioTrd                      = 3;    { Read from char stream       }
  rxSioDtr                      = 4;    { DEBUG read from char stream }
  rxSioTll                      = 5;    { Return linelength(N/A OS/2) }
  rxHlt                         = 7;    { Halt processing.            }
  rxHltClr                      = 1;    { Clear HALT indicator        }
  rxHltTst                      = 2;    { Test HALT indicator         }
  rxTrc                         = 8;    { Test ext trace indicator.   }
  rxTrcTst                      = 1;    { subcode value.              }
  rxIni                         = 9;    { Initialization processing.  }
  rxIniExt                      = 1;    { subcode value.              }
  rxTer                         = 10;   { Termination processing.     }
  rxTerExt                      = 1;    { subcode value.              }
  rxNoOfExits                   = 11;   { 1 + largest exit number.    }

type
  PExit = ^Byte;                        { ptr to exit parameter block }

{ Asynchronous Request Interface defines }
{ Return Codes from Asynchronous Request interface }
const
  rxari_Ok                      = 0;    { Interface completed         }
  rxari_Not_Found               = 1;    { Target program not found    }
  rxari_Processing_Error        = 2;    { Error processing request    }

{  Macro Space Interface defines }
{  Registration Search Order Flags }

  rxmacro_Search_Before         = 1; { Beginning of search order   }
  rxmacro_Search_After          = 2; { End of search order         }


{ Return Codes from RxMacroSpace interface }

  rxmacro_Ok                    = 0; { Macro interface completed   }
  rxmacro_No_Storage            = 1; { Not Enough Storage Available}
  rxmacro_Not_Found             = 2; { Requested function not found}
  rxmacro_Extension_Required    = 3; { File ext required for save  }
  rxmacro_Already_Exists        = 4; { Macro functions exist       }
  rxmacro_File_Error            = 5; { File I/O error in save/load }
  rxmacro_Signature_Error       = 6; { Incorrect format for load   }
  rxmacro_Source_Not_Found      = 7; { Requested cannot be found   }
  rxmacro_Invalid_Position      = 8; { Invalid search order pos    }
  rxmacro_Not_Init              = 9; { API not initialized         }

{ 32-bit }
{ Main Entry Point to the REXXSAA Interpreter }

function RexxStart (
         ArgC:     Long;        { Num of args passed to rexx }
         ArgV:     PRxString;   { Array of args passed to rex}
         FileName: PChar;       { [d:][path] filename[.ext]  }
         Proc:     PRxString;   { Loc of rexx proc in memory }
         Env:      PChar;       { ASCIIZ initial environment.}
         rType:    Long;        { type (command,subrtn,funct)}
         Exit:     PRxSysExit;  { SysExit env. names &  codes}
     var Ret:      Word;        { Ret code from if numeric   }
     var RetVal:   RxString     { Retvalue from the rexx proc}
         ): Long;

{ Subcommand Interface }
{ RexxRegisterSubcomDll -- Register a DLL entry point }
{ as a Subcommand handler }

function RexxRegisterSubcomDll(
         HName:    PChar;       { Name of subcom handler     }
         DllName:  PChar;       { Name of DLL                }
         ProcName: PChar;       { Name of procedure in DLL   }
         UserArea: Pointer;     { User area                  }
         Drop: ULong): ApiRet;  { Drop authority.            }

{ RexxRegisterSubcomExe -- Register an EXE entry point }
{ as a Subcommand handler }

function RexxRegisterSubcomExe (
         HName:       PChar;            { Name of subcom handler     }
         HandlerAddr: PFn;              { address of handler in EXE  }
         UserArea:    Pointer): ApiRet; { User area                  }

{ RexxQuerySubcom - Query an environment for Existance }

function RexxQuerySubcom(
         EnvName: PChar;                { Name of the Environment    }
         DllName: PChar;                { DLL Module Name            }
     var ExCode:  Word;                 { Stor for existance code    }
     var User:    Word): ApiRet;        { Stor for user word         }

{ RexxDeregisterSubcom - Drop registration of a Subcommand environment }

function RexxDeregisterSubcom(
         EnvName: PChar;                { Name of the Environment    }
         DllName: PChar): ApiRet;       { DLL Module Name            }

{ Shared Variable Pool Interface }

{ RexxVariablePool - Request Variable Pool Service }

function RexxVariablePool(var Pool: ShvBlock): ApiRet; { Pointer to list of SHVBLOCKs}

{ External Function Interface }
{ RexxRegisterFunctionDll - Register a function in the AFT }

function RexxRegisterFunctionDll (
        FnName:  PChar;                 { Name of function to add    }
        DllName: PChar;                 { Dll file name (if in dll)  }
        Entry:   PChar): ApiRet;        { Entry in dll               }

{ RexxRegisterFunctionExe - Register a function in the AFT }

function RexxRegisterFunctionExe (
        FnName: PChar;                  { Name of function to add    }
        Entry:  PFn): ApiRet;           { Entry point in EXE         }

{ RexxDeregisterFunction - Delete a function from the AFT }

function RexxDeregisterFunction(FnName: PChar): ApiRet; { Name of function to remove }

{ RexxQueryFunction - Scan the AFT for a function }

function RexxQueryFunction(FnName: PChar): ApiRet; { Name of function to find }

{ System Exits }
{ Subfunction RXFNCCAL - External Function Calls }

const
{ rxfnc_flags flags }
  rxfferr                       = $01;  { Invalid call to routine.   }
  rxffnfnd                      = $02;  { Function not found.        }
  rxffsub                       = $04;  { Called as a subroutine     }
type

  RxFnCCal_Parm = record
    rxfnc_flags: Byte;          { function flags             }
    rxfnc_name:  PChar;         { Pointer to function name.  }
    rxfnc_namel: Word;          { Length of function name.   }
    rxfnc_que:   PChar;         { Current queue name.        }
    rxfnc_quel:  Word;          { Length of queue name.      }
    rxfnc_argc:  Word;          { Number of args in list.    }
    rxfnc_argv:  PRxString;     { Pointer to argument list.  }
    rxfnc_retc:  RxString;      { Return value.              }
  end;

{ Subfunction RXCMDHST -- Process Host Commands }
const
{ rxcmd_flags flags }
  rxfcfail                      = $01;  { Command failed.            }
  rxfcerr                       = $02;  { Command ERROR occurred.    }
type
  RxCmdHst_Parm = record
    rxcmd_flags:    Byte;               { error/failure flags        }
    rxcmd_address:  PChar;              { Pointer to address name.   }
    rxcmd_addressl: Word;               { Length of address name.    }
    rxcmd_dll:      PChar;              { dll name for command.      }
    rxcmd_dll_len:  Word;               { Length of dll name.        }
    rxcmd_command:  RxString;           { The command string.        }
    rxcmd_retc:     RxString;           { Pointer to return buffer   }
  end;

{ Subfunction RXMSQPLL -- Pull Entry from Queue }

  RxMsqPll_Parm = record
    rxmsq_retc: RxString;               { Pointer to dequeued entry  }
  end;                                  { buffer.  User allocated.   }

{  Subfunction RXMSQPSH -- Push Entry on Queue }
const
{ rxmsq_flags flags }
   rxfmlifo                     = $01;  { Stack entry LIFO if set    }
type
  RxMsqPsh_Parm = record
     rxmsq_flags: Byte;                 { LIFO/FIFO flag             }
     rxmsq_value: RxString              { The entry to be pushed.    }
  end;

{  Subfunction RXMSQSIZ -- Return the Current Queue Size }

  RxMsqSiz_Parm = record
    rxmsq_size: ULong;                  { Number of Lines in Queue   }
  end;

{ Subfunction RXMSQNAM -- Set Current Queue Name }

  RxMsqNam_Parm = record
    rxmsq_name: RxString;               { RxString containing        }
  end;                                  { queue name.                }

{ Subfunction RXSIOSAY -- Perform SAY Clause }

  RxSioSay_Parm = record
    rxsio_string: RxString;             { String to display.         }
  end;

{ Subfunction RXSIOTRC -- Write Trace Output }

  RxSioTrc_Parm = record
    rxsio_string: RxString;             { Trace line to display.     }
  end;

{ Subfunction RXSIOTRD -- Read Input from the Terminal }

  RxSioTrd_Parm = record
    rxsiotrd_retc: RxString;            { RxString for output.       }
  end;

{ Subfunction RXSIODTR -- Read Debug Input from the Terminal }

  RxSioDtr_Parm = record
    rxsiodtr_retc: RxString;            { RxString for output.       }
  end;

{ Subfunction RXHSTTST -- Test for HALT Condition }
const
{ rxhlt_flags flags }
  rxfhhalt                      = $01;  { Set if HALT occurred.      }
type
  RxHltTst_Parm = record
    rxhlt_flags: Byte;                  { Set if HALT occurred       }
  end;

{ Subfunction RXTRCTST -- Test for TRACE Condition }
const
{ rxtrc_flags flags }
  rxftrace                      = $01;  { Set to run external trace. }
type
  RxTrcTst_Parm = record
    rxtrc_flags: Byte;                  { Set to run external trace  }
  end;

{ RexxRegisterExitDll - Register a system exit. }

function RexxRegisterExitDll (
         HExit:    PChar;               { Name of the exit handler   }
         DllName:  PChar;               { Name of the DLL            }
         ProcName: PChar;               { Name of the procedure      }
         UserArea: Pointer;             { User area                  }
         Drop:     ULong): ApiRet;      { Drop authority             }

{ RexxRegisterExitExe - Register a system exit. }

function RexxRegisterExitExe (
         HExit: PChar;                  { Name of the exit handler   }
         HandlerAddr: PFn;              { Address of exit handler    }
         UserArea: Pointer): ApiRet;    { User area                  }

{ RexxDeregisterExit - Drop registration of a system exit. }

function RexxDeregisterExit (
         ExitName: PChar;               { Exit name                  }
         DllName:  PChar): ApiRet ;     { DLL module name            }

{ RexxQueryExit - Query an exit for existance. }

function RexxQueryExit (
         ExitName: PChar;               { Exit name                  }
         DllName:  PChar;               { DLL Module name.           }
     var ExFlag:   Word;                { Existance flag.            }
         UserArea: Pointer): ApiRet;    { User data.                 }

{ Asynchronous Request Interface }
{ RexxSetHalt - Request Program Halt }

function RexxSetHalt(
         Pid: Pid;                      { Process Id                  }
         Tid: Tid): ApiRet;             { Thread Id                   }

{ RexxSetTrace - Request Program Trace }

function RexxSetTrace(
         Pid: Pid;                      { Process Id                  }
         Tid: Tid): ApiRet;             { Thread Id                   }

{ RexxResetTrace - Turn Off Program Trace }

function RexxResetTrace(
         Pid: Pid;                      { Process Id                  }
         Tid: Tid): ApiRet;             { Thread Id                   }

{ Macro Space Interface }
{ RexxAddMacro - Register a function in the Macro Space }

function RexxAddMacro (
         FnName:   PChar;               { Function to add or change   }
         FileName: PChar;               { Name of file to get function}
         SrchPos:  ULong): ApiRet;      { Flag indicating search pos  }

{ RexxDropMacro - Remove a function from the Macro Space }

function RexxDropMacro(FnName: PChar): ApiRet; { Name of function to remove }

{ RexxSaveMacroSpace - Save Macro Space functions to a file }

function RexxSaveMacroSpace (
         ArgC: ULong;                   { Argument count (0==save all)}
     var NameLst: PChar;                { List of funct names to save }
         FileName: PChar): ApiRet;      { File to save functions in   }

{ RexxLoadMacroSpace - Load Macro Space functions from a file  }

function RexxLoadMacroSpace (
         ArgC:     ULong;               { Argument count (0==load all)}
     var NameLst:  PChar;               { List of funct names to load }
         FileName: PChar): ApiRet;      { File to load functions from }

{ RexxQueryMacro - Find a function's search-order position }

function RexxQueryMacro (
         FnName: PChar;                 { Function to search for       }
     var PtrPos: Word): ApiRet;         { Ptr for position flag return }

{ RexxReorderMacro - Change a function's search-order position }

function RexxReorderMacro(
         FnName: PChar;                 { Name of funct change order  }
         NewPos: ULong): ApiRet;        { New position for function   }

{ RexxClearMacroSpace - Remove all functions from a MacroSpace }

function RexxClearMacroSpace: ApiRet;   { No Arguments.               }

procedure RexxWaitForTermination;

{ additional services -- by sk }

{$StdCall-}
procedure MakeRxString(var Rx: RxString; const Source: String);
procedure DestroyRxString(var Rx: RxString);
{$StdCall+}

implementation
uses
     Strings;

const
{$IFDEF REGINAREXX}
 RexxDLL = 'REGINA.DLL';
 RexxAPIDLL = 'REGINA.DLL';
{$ELSE}
 RexxDLL = 'REXX.DLL';
 RexxAPIDLL = 'REXXAPI.DLL';
{$ENDIF}

{$StdCall+}

function RexxAddMacro;            external RexxDLL;
function RexxClearMacroSpace;     external RexxDLL;
function RexxDeregisterExit;      external RexxDLL;
function RexxDeregisterFunction;  external RexxAPIDLL;
function RexxDeregisterSubcom;    external RexxDLL;
function RexxDropMacro;           external RexxDLL;
function RexxLoadMacroSpace;      external RexxDLL;
function RexxQueryExit;           external RexxDLL;
function RexxQueryFunction;       external RexxDLL;
function RexxQueryMacro;          external RexxDLL;
function RexxQuerySubcom;         external RexxDLL;
function RexxRegisterExitDll;     external RexxDLL;
function RexxRegisterExitExe;     external RexxDLL;
function RexxRegisterFunctionDll; external RexxAPIDLL;
function RexxRegisterFunctionExe; external RexxDLL;
function RexxRegisterSubcomDll;   external RexxDLL;
function RexxRegisterSubcomExe;   external RexxDLL;
function RexxReorderMacro;        external RexxDLL;
function RexxResetTrace;          external RexxDLL;
function RexxSaveMacroSpace;      external RexxDLL;
function RexxSetHalt;             external RexxDLL;
function RexxSetTrace;            external RexxDLL;
function RexxStart;               external RexxDLL;
function RexxVariablePool;        external RexxDLL;
procedure RexxWaitForTermination; external RexxDLL;

{ additional services -- by sk }

{$StdCall-}

procedure MakeRxString(var Rx: RxString; const Source: String);
 begin
  Rx.strlength:=Length(Source);

  GetMem(Rx.strptr, Rx.strlength + 1);

  StrPCopy(Rx.strptr, Source);
 end;

procedure DestroyRxString(var Rx: RxString);
 begin
  FreeMem(Rx.strptr, Rx.strlength + 1);
 end;

end.
