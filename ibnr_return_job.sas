/*
 Copyright (C) 2024-2025 SAS Institute Inc. Cary, NC, USA
*/
%macro Return_error();
/* init*/

proc json out=_webout nosastags nopretty nokeys;
  write open object;
  write values "success" true;
  write values "retcode" &syscc;
  write values "message" "&SYSERRORTEXT";
  write close;
run;

%mend;
