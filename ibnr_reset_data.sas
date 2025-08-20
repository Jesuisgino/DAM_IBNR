/*
Copyright (C) 2024-2025 SAS Institute Inc. Cary, NC, USA
 */

/* Prepare temporary cas table for factor summary calculation
 * rc_var
 * bu_var
 * item
 * init
 */
%MACRO reset_data() / minoperator;

   %let tables_to_reset=&TRIANGLE_DATA &FACTOR_SUMMARY &ibnr_summary &complete_triangle_data;

   %local i table_to_reset;
   %do i=1 %to %sysfunc(countw(&tables_to_reset));
      %let table_to_reset=%scan(&tables_to_reset, &i);

      proc cas;

         table.droptable / caslib="&caslib.", name="&table_to_reset." quiet=TRUE;

      quit;

      data &caslib..&table_to_reset.;
         set &caslib..&table_to_reset._ORIG;
      run;

      proc cas;

         table.promote / caslib="&caslib.", name="&table_to_reset.",
            target="&table_to_reset.", targetLib="&caslib.", drop=TRUE;

         table.save/caslib="&caslib." name="&table_to_reset."
            table={caslib="&caslib.", name="&table_to_reset."} replace=TRUE;

      quit;

   %end;

%MEND;
