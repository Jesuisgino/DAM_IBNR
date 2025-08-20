/*
 Copyright (C) 2024-2025 SAS Institute Inc. Cary, NC, USA
*/
/* Prepare temporary cas table for factor summary calculation
* rc_var
* bu_var
* item
* init
*/

%MACRO factor_exclude_include(rc_var=,bu_var=,item=,yr=,dev=,post=);

   %IF &post = Exclude %THEN
      %DO;
         %let x_val = 1;
         %let x_txt = cats(put(today(),DDMMYY8.),", &SYS_COMPUTE_SESSION_OWNER", ", removed DF from calculation");
      %END;
   %ELSE %IF &post = Include %THEN
      %DO;
         %let x_val = 0;
         %let x_txt = '';
      %END;

   proc casutil;
      droptable casdata="_tmp_work_data" incaslib="casuser" quiet;
   quit;

   DATA casuser._tmp_work_data(replace=yes);
      SET &caslib..&triangle_data.;
      IF business_unit EQ "&_bu"
         AND reserving_class EQ "&_rc"
         AND Item EQ "&_item"
         AND Origin_Year EQ &_yr
         AND Development_Period EQ &_dev
      THEN
         DO;
            X = &x_val;
            Amount_Dscr = &x_txt;
         END;
   RUN;

   DATA casuser._tmp_work_data(replace=yes);
      SET casuser._tmp_work_data;
      IF business_unit EQ "&_bu"
         AND reserving_class EQ "&_rc"
         AND Item EQ "&_item"
         AND Origin_Year EQ &_yr
         AND Development_Period EQ %sysevalf(&_dev - 1)
      THEN
         DO;
            X_Next = &x_val;
         END;
   RUN;

   proc casutil;
      droptable casdata="_&triangle_data." incaslib="casuser" QUIET;
   quit;

   DATA CASUSER._&triangle_data.;
      SET casuser._tmp_work_data;
   RUN;

   proc casutil;
      droptable casdata="&triangle_data." incaslib="&caslib." QUIET;
       promote casdata="_&triangle_data." incaslib="CASUSER" casout="&triangle_data." outcaslib="&caslib.";
   run;
    %save_data(&triangle_data.);
   run;
%MEND;
