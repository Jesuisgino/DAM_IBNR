/*
 Copyright (C) 2024-2025 SAS Institute Inc. Cary, NC, USA
*/
/* Prepare temporary cas table for factor summary calculation
* rc_var
* bu_var
* item
* init
*/


/* Remember MySession cas session */

%global id_list;
%let id_list = 3 4 5;

%MACRO update_factory_summary(rc_var=,bu_var=,item=,init=);

   /* Prepare temporary cas table for factor summary calculation
   */
   proc casutil ;
      droptable casdata="_tmp_&FACTOR_SUMMARY." incaslib="casuser" QUIET;
   quit;

   /* determine the maximum development period in iteration
   */
   /*Bug fix remove +1 from maxDev*/
   PROC SQL NOPRINT;
      SELECT MAX(Development_Period)
      INTO :MaxDev
      FROM  &caslib..&TRIANGLE_DATA.
      WHERE upcase(business_unit) = %upcase("&bu_var")
         AND upcase(reserving_class) = %upcase("&rc_var")
         AND upcase(Item)= %upcase("&item");
   QUIT;

   %let n_id = %sysfunc(countw(&id_list));


   data triangle_data_selected;
      set &caslib..&TRIANGLE_DATA.;
            where upcase(business_unit) = %upcase("&bu_var")
               AND upcase(reserving_class) = %upcase("&rc_var")
               AND upcase(Item)= %upcase("&item")
               AND X EQ 0
               AND X_Next EQ 0
               AND NOT MISSING(Amount_Calc_Next);
   run;

   proc sort data=triangle_data_selected;
   by DEVELOPMENT_PERIOD descending ORIGIN_YEAR;
   run;

   proc datasets library=work nolist;
          delete triangle_data_final;
   quit;


   %do i=1 %to &n_id;

   %let id=%scan(&id_list,&i);

      data triangle_data_selected_&id.(drop=count_id);
         set triangle_data_selected;
         retain count_id;
         by DEVELOPMENT_PERIOD;
         if first.DEVELOPMENT_PERIOD then do;
            count_id=1;
            ID=&id;
            output;
         end;
         else if count_id lt &id then do;
            count_id=count_id+1;
            ID=&id;
            output;
         end;
      run;

      proc append base=triangle_data_final data=triangle_data_selected_&id.;
      run;
   %end;

      proc sort data=triangle_data_final;
      by ID DEVELOPMENT_PERIOD ORIGIN_YEAR;
      run;

      data triangle_data_factor(keep=BUSINESS_UNIT RESERVING_CLASS DEVELOPMENT_PERIOD ID FACTOR_CALC);
         set triangle_data_final;
         by ID DEVELOPMENT_PERIOD;
         retain sum_calc_next_amt sum_calc_amt;
         if first.DEVELOPMENT_PERIOD then do;
            sum_calc_next_amt=Amount_Calc_Next;
            sum_calc_amt=Amount_Calc;
         end;
         else do;
            sum_calc_next_amt=sum(sum_calc_next_amt,Amount_Calc_Next);
            sum_calc_amt=sum(sum_calc_amt,Amount_Calc);
         end;
         if last.DEVELOPMENT_PERIOD then do;
            if sum_calc_amt ne 0 then do;
               FACTOR_CALC=sum_calc_next_amt/sum_calc_amt;
            end;
            else do;
               FACTOR_CALC=0;
            end;
            output;
         end;
      run;

      /*Factor_calc dimension is up to maxdev-1*/
      /*For the maxdev factor, if init>0, use init as tail factor, otherwise, set it to 1*/

      data triangle_data_factor_tail;
            set triangle_data_factor(obs=1);
            %do i=1 %to &n_id;

               %let id=%scan(&id_list,&i);
               BUSINESS_UNIT="&bu_var";
               RESERVING_CLASS="&rc_var";
               ID=&id;
               DEVELOPMENT_PERIOD=&MaxDev.;
               %if &init >0 %then %do;
                  FACTOR_CALC=&init;
               %end;
               %else %do;
                  FACTOR_CALC=1;
               %end;
               output;
            %end;
      run;

      proc append base=triangle_data_factor data=triangle_data_factor_tail;
      run;

      proc sort data=triangle_data_factor;
      by ID descending DEVELOPMENT_PERIOD;
      run;

      data triangle_data_factor(drop=age_to_ultimate);
         set triangle_data_factor;
         retain age_to_ultimate;
         by ID;
         if first.ID then do;
            age_to_ultimate=factor_calc;
         end;
         else do;
            age_to_ultimate=age_to_ultimate*factor_calc;
         end;
            CASHFLOW_CALC=1/age_to_ultimate;
      run;

      data tmp_factor_summary casuser._tmp_&factor_summary.;
         set &caslib..&FACTOR_SUMMARY.;
            if (upcase(business_unit) = %upcase("&bu_var")
               AND upcase(reserving_class) = %upcase("&rc_var")
               AND upcase(Item) = %upcase("&item")
               AND ID in (&id_list.)) then do ;
            output tmp_factor_summary;
         end;
         else do;
            output casuser._tmp_&factor_summary.;
         end;
      run;

      data tmp_factor_summary_new (drop=rc FACTOR_CALC CASHFLOW_CALC);
         length FACTOR_CALC 8. CASHFLOW_CALC 8.;
         if _n_=1 then do;
            declare hash S(dataset:'triangle_data_factor');
            S.defineKey('BUSINESS_UNIT','RESERVING_CLASS','ID','DEVELOPMENT_PERIOD');
            S.defineData('FACTOR_CALC','CASHFLOW_CALC');
            S.defineDone();
            call missing(FACTOR_CALC,CASHFLOW_CALC);
         end;
         set tmp_factor_summary;
         rc=S.find();
         if rc = 0 then do;
            FACTOR=FACTOR_CALC;
            CASHFLOW=CASHFLOW_CALC;
         end;
      run;

      data casuser._tmp_&factor_summary.(append=force);
         set tmp_factor_summary_new;
      run;

      proc casutil;
         droptable casdata="&FACTOR_SUMMARY." incaslib="&caslib." quiet;
         save casdata="_tmp_&factor_summary." incaslib="casuser" casout="&FACTOR_SUMMARY." outcaslib="&caslib." replace;
         promote casdata="_tmp_&factor_summary." incaslib="casuser" casout="&FACTOR_SUMMARY." outcaslib="&caslib.";
      run;
%MEND;

%macro update_full;
%local i1 i2 i3 bu rc it;
%do i1=1 %to %sysfunc(countw(&business_unit_list));
   /*cas casSession&i1; */ /* Implement Multisession processing in future release*/
    %let bu=%scan(&business_unit_list,&i1,%str( ));
    %do i2=1 %to %sysfunc(countw(&reserving_class_list));
      %let rc=%scan(&reserving_class_list,&i2,%str( ));
      %do i3=1 %to %sysfunc(countw(&item_list));
         %let it=%scan(&item_list,&i3,%str( ));
         %update_factory_summary(rc_var=&rc,bu_var=&bu,item=&it,init=0); run;
      %end;
   %end;
%end;

%mend;
