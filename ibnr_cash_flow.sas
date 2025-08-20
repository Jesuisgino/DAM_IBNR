/*
 Copyright (C) 2024-2025 SAS Institute Inc. Cary, NC, USA
*/


%macro Select_Row();

   proc casutil;
      droptable casdata="_&ibnr_summary." incaslib="casuser" QUIET;
   quit;

   data casuser._&ibnr_summary.(replace=yes);
      set &caslib..&IBNR_SUMMARY.;
   run;

   /*instead of looping through, we can merge data*/

   /*check if Selected_Final exist in the factor summary table, if so update it*/
   PROC SQL NOPRINT;
      SELECT count(*)
      INTO :n_selected_final
      FROM   &caslib..&FACTOR_SUMMARY.
       Where (upcase(business_unit) = %upcase("&_bu")
            AND upcase(reserving_class) = %upcase("&_rc")
            AND upcase(Item) = %upcase("&_item")
            AND upcase(Name) = "SELECTED_FINAL")
   ;

   SELECT max(ORIGIN_YEAR)
   INTO :max_origin_year
   FROM &caslib..&IBNR_SUMMARY.
   Where upcase(business_unit) = %upcase("&_bu")
         AND upcase(reserving_class) = %upcase("&_rc")
         AND upcase(Item) = %upcase("&_item")
   ;
   QUIT;

   %if &n_selected_final > 0 %then %do;

      proc casutil;
         droptable casdata="_&factor_summary." incaslib="casuser" QUIET;
      quit;

      data tmp_factor_summary tmp_factor_summary_final casuser._&factor_summary.;
         set &caslib..&FACTOR_SUMMARY.;
            if (upcase(business_unit) = %upcase("&_bu")
               AND upcase(reserving_class) = %upcase("&_rc")
               AND upcase(Item) = %upcase("&_item")
               AND upcase(Name) = %upcase("&_name")) then do ;
            ORIGIN_YEAR=&max_origin_year.-Development_Period+1;
            output tmp_factor_summary;
         end;
         else if (upcase(business_unit) = %upcase("&_bu")
               AND upcase(reserving_class) = %upcase("&_rc")
               AND upcase(Item) = %upcase("&_item")
               AND upcase(Name) = "SELECTED_FINAL") then do ;
            output tmp_factor_summary_final;
         end;
         else do;
            output casuser._&factor_summary.;
         end;

      run;

      proc sort data=tmp_factor_summary;
      by BUSINESS_UNIT RESERVING_CLASS ITEM Development_Period;
      run;

      proc sort data=tmp_factor_summary_final;
      by BUSINESS_UNIT RESERVING_CLASS ITEM Development_Period;
      run;

      data tmp_factor_summary_merged(drop=ORIGIN_YEAR);
         merge tmp_factor_summary(in=a keep=BUSINESS_UNIT RESERVING_CLASS ITEM Development_Period FACTOR CASHFLOW) tmp_factor_summary_final(in=b drop=FACTOR CASHFLOW);
         if a and b;
         by BUSINESS_UNIT RESERVING_CLASS ITEM Development_Period;
      run;

      data casuser._&factor_summary.(append=force);
         set tmp_factor_summary tmp_factor_summary_merged;
      run;

      proc casutil;
         droptable casdata="&FACTOR_SUMMARY." incaslib="&caslib." quiet;
         save casdata="_&factor_summary." incaslib="casuser" casout="&FACTOR_SUMMARY." outcaslib="&caslib." replace;
         promote casdata="_&factor_summary." incaslib="casuser" casout="&FACTOR_SUMMARY." outcaslib="&caslib.";
      run;

   %end;

   /*check if this macro is called to set claims pattern*/
   /*In this case, BU can't set to ALL*/

   %if %upcase(&_bu) ne ALL and (%upcase(&_post) = CLAIMS) %then %do;

      data tmp_ibnr_summary casuser._&ibnr_summary.;
         set casuser._&ibnr_summary.;
           if (upcase(business_unit) = %upcase("&_bu")
            AND upcase(reserving_class) = %upcase("&_rc")
         AND upcase(Item) = %upcase("&_item")) then output tmp_ibnr_summary;
         else output casuser._&ibnr_summary.;
      run;

      data tmp_factor_summary;
         set &caslib..&FACTOR_SUMMARY.;
            where (upcase(business_unit) = %upcase("&_bu")
               AND upcase(reserving_class) = %upcase("&_rc")
               AND upcase(Item) = %upcase("&_item")
               AND upcase(Name) = %upcase("&_name"));
            ORIGIN_YEAR=&max_origin_year.-Development_Period+1;
      run;

   /*check if the filtered summary data has valid observations*/
      %if %rsk_attrn(tmp_ibnr_summary,nlobs) eq 0 %then %do;
         %put ERROR: the IBNR_SUMMARY table does not contain observation, IBNR calculation will not be performed.;
         %abort;
      %end;
      %if %rsk_attrn(tmp_factor_summary,nlobs) eq 0 %then %do;
         %put ERROR: the IBNR_FACTOR_SUMMARY table does not contain observation, IBNR calculation will not be performed.;
         %abort;
      %end;

   /*Update the LOSS_CASHFLOW in ibnr_summary table*/
      proc sort data=tmp_factor_summary;
      by ORIGIN_YEAR;
      run;

      data tmp_ibnr_summary_1 (drop=rc CASHFLOW);
         length CASHFLOW 8.;
         if _n_=1 then do;
            declare hash S(dataset:'tmp_factor_summary');
            S.defineKey('BUSINESS_UNIT','RESERVING_CLASS','ITEM','ORIGIN_YEAR');
            S.defineData('CASHFLOW');
            S.defineDone();
            call missing(CASHFLOW);
         end;
         set tmp_ibnr_summary;
         rc=S.find();
         if rc = 0 then do;
            LOSS_CASHFLOW=CASHFLOW;
         end;
      run;

   /*Calculate process error and estimation error for Mack chain-ladder Model*/


   /*Step 1: need triangle_data besides ibnr_summary and ibnr_factor_summary*/
     data tmp_triangle_data(keep=BUSINESS_UNIT RESERVING_CLASS ITEM ORIGIN_YEAR DEVELOPMENT_PERIOD AMOUNT FACTOR MIN_ORIGIN_YEAR MAX_DEVELOPMENT_PERIOD) ;
         set &caslib..&TRIANGLE_DATA.;
            where upcase(business_unit) = %upcase("&_bu")
               AND upcase(reserving_class) = %upcase("&_rc")
               AND upcase(Item) = %upcase("&_item")
         ;
      run;

      %if %rsk_attrn(tmp_triangle_data,nlobs) eq 0 %then %do;
         %put ERROR: the IBNR_TRIANGLE_DATA table does not contain any observation, Mack model calculation will not be performed.;
         %abort;
      %end;

      /*Merge triangle data with ibnr factor summary to get selected factor w.r.t DEVELOPMENT_PERIOD*/
      proc sort data=tmp_triangle_data;
      by BUSINESS_UNIT RESERVING_CLASS ITEM DEVELOPMENT_PERIOD;
      run;

      proc sort data=tmp_factor_summary;
      by BUSINESS_UNIT RESERVING_CLASS ITEM DEVELOPMENT_PERIOD;
      run;

      data tmp_triangle_summary;
         merge tmp_triangle_data(in=a) tmp_factor_summary(in=b keep=BUSINESS_UNIT RESERVING_CLASS ITEM DEVELOPMENT_PERIOD FACTOR rename=(FACTOR=SELECTED_FACTOR));
         by BUSINESS_UNIT RESERVING_CLASS ITEM DEVELOPMENT_PERIOD;
         if a and b;
      run;


      /*Step 2: calculate S_i^2*/
      data tmp_triangle_summary_1 tmp_sigma(drop=ORIGIN_YEAR);
         set tmp_triangle_summary;
         where sum(ORIGIN_YEAR,DEVELOPMENT_PERIOD) < sum(MIN_ORIGIN_YEAR,MAX_DEVELOPMENT_PERIOD);
         retain sum_sigma_ij count ;
         by DEVELOPMENT_PERIOD;
         /*S_ij*/
         sigma_ij=AMOUNT*(FACTOR-SELECTED_FACTOR)**2;
         /*Sum(S_ij)*/
         if first.DEVELOPMENT_PERIOD then do;
            sum_sigma_ij=sigma_ij;
            count=1;
         end;
         else do;
            sum_sigma_ij=sum_sigma_ij+sigma_ij;
            count=count+1;
            if last.DEVELOPMENT_PERIOD then do;
               sigma_i=sum_sigma_ij/(count-1);
               output tmp_sigma;
            end;
         end;
         output tmp_triangle_summary_1;
      run;

      /*The sigma_i for last DEVELOPMENT_PERIOD is calculated using formula: N69*MIN(M69,N69)/MAX(M69,N69)*/
      data tmp_sigma_1(keep=BUSINESS_UNIT RESERVING_CLASS ITEM DEVELOPMENT_PERIOD sigma_i MIN_ORIGIN_YEAR MAX_DEVELOPMENT_PERIOD);
         set tmp_sigma end=eof;
         lag_sigma_i=lag(sigma_i);
         output;
         if eof then do;
            sigma_i=sigma_i*min(lag_sigma_i,sigma_i)/max(lag_sigma_i,sigma_i);
            DEVELOPMENT_PERIOD=DEVELOPMENT_PERIOD+1;
            output;
         end;
      run;

      /*Step 3: calculate process error multiplication factor*/
      /*Get FACTOR, AGE_TO_ULTIMATE, and CASHFLOW from factor summary*/
      proc sort data=tmp_sigma_1;
      by BUSINESS_UNIT RESERVING_CLASS ITEM DEVELOPMENT_PERIOD;
      run;

      proc sort data=tmp_factor_summary;
      by BUSINESS_UNIT RESERVING_CLASS ITEM DEVELOPMENT_PERIOD;
      run;

      data tmp_sigma_final;
         merge tmp_sigma_1(in=a) tmp_factor_summary(in=b keep=BUSINESS_UNIT RESERVING_CLASS ITEM DEVELOPMENT_PERIOD FACTOR CASHFLOW);
         by BUSINESS_UNIT RESERVING_CLASS ITEM DEVELOPMENT_PERIOD;
         if a and b;
      run;

      /*calculate process error multiplication factor and sum of the factor*/
      proc sort data =tmp_sigma_final;
      by descending DEVELOPMENT_PERIOD;
      run;

      data sigma_process_error;
         set tmp_sigma_final end=eof;
         retain SUM_PROCESS_ERROR_MULTI AGE_TO_ULTIMATE;
         if _n_=1 then do;
            AGE_TO_ULTIMATE=factor;
             PROCESS_ERROR_MULTI=sigma_i*AGE_TO_ULTIMATE/FACTOR**2;
            SUM_PROCESS_ERROR_MULTI=PROCESS_ERROR_MULTI;
         end;
         else do;
            AGE_TO_ULTIMATE=AGE_TO_ULTIMATE*factor;
            PROCESS_ERROR_MULTI=sigma_i*AGE_TO_ULTIMATE/FACTOR**2;
            SUM_PROCESS_ERROR_MULTI=SUM_PROCESS_ERROR_MULTI+PROCESS_ERROR_MULTI;
         end;
      run;

      /*Step 4: calculate estimation error multiplication factor*/
      /*calculate sum of cumulative loss from 1 to l-k*/
      proc sort data=tmp_triangle_data;
      by  BUSINESS_UNIT RESERVING_CLASS ITEM DEVELOPMENT_PERIOD ORIGIN_YEAR;
      run;

      data sum_loss(keep=BUSINESS_UNIT RESERVING_CLASS ITEM DEVELOPMENT_PERIOD SUM_CUMULATIVE_LOSS);
         set tmp_triangle_data;
         retain SUM_CUMULATIVE_LOSS;
         by DEVELOPMENT_PERIOD;
         cut_off_year=(MIN_ORIGIN_YEAR+(MAX_DEVELOPMENT_PERIOD-DEVELOPMENT_PERIOD)-1);
         if first.DEVELOPMENT_PERIOD then do;
            SUM_CUMULATIVE_LOSS=AMOUNT;
            if ORIGIN_YEAR=cut_off_year then do;
                output sum_loss;
            end;
         end;
         else do;
            SUM_CUMULATIVE_LOSS=SUM_CUMULATIVE_LOSS+AMOUNT;
            if ORIGIN_YEAR=cut_off_year then do;
                output sum_loss;
            end;
         end;
      run;

      /*Calculate estimation error multiplication factor from sigma_process_error*/
        /*first get the sum of cumulative loss from the sum_loss table*/
      data tmp_sigma_loss (drop=rc SUM_CUMULATIVE_LOSS);
         length SUM_CUMULATIVE_LOSS 8.;
         if _n_=1 then do;
            declare hash S(dataset:'sum_loss');
            S.defineKey('BUSINESS_UNIT','RESERVING_CLASS','ITEM','DEVELOPMENT_PERIOD');
            S.defineData('SUM_CUMULATIVE_LOSS');
            S.defineDone();
            call missing(SUM_CUMULATIVE_LOSS);
         end;
         set sigma_process_error;
         rc=S.find();
         if rc = 0 then do;
            LOSS_SUM=SUM_CUMULATIVE_LOSS;
         end;
      run;

      proc sort data=tmp_sigma_loss;
      by descending DEVELOPMENT_PERIOD;
      run;

      data sigma_process_estimation_error;
         set tmp_sigma_loss end=eof;
         retain SUM_ESTIMATION_ERROR_MULTI;
         ORIGIN_YEAR=MIN_ORIGIN_YEAR+(MAX_DEVELOPMENT_PERIOD-DEVELOPMENT_PERIOD);
         if _n_=1 then do;
             ESTIMATION_ERROR_MULTI=(sigma_i/FACTOR**2)/LOSS_SUM;
            SUM_ESTIMATION_ERROR_MULTI=ESTIMATION_ERROR_MULTI;
         end;
         else do;
            ESTIMATION_ERROR_MULTI=(sigma_i/FACTOR**2)/LOSS_SUM;
            SUM_ESTIMATION_ERROR_MULTI=SUM_ESTIMATION_ERROR_MULTI+ESTIMATION_ERROR_MULTI;
         end;
      run;

      /*Step 5: Calculate process error and estimation error*/
      /*Merge process and estimation error multipler back with ibnr_summary*/

    data tmp_ibnr_summary_2 (drop=rc SUM_PROCESS_ERROR_MULTI SUM_ESTIMATION_ERROR_MULTI PROCESS_ERROR ESTIMATION_ERROR CL_ULTIMATE rename=(NEW_PROCESS_ERROR=PROCESS_ERROR NEW_ESTIMATION_ERROR=ESTIMATION_ERROR));
         length SUM_PROCESS_ERROR_MULTI SUM_ESTIMATION_ERROR_MULTI 8.;
         if _n_=1 then do;
            declare hash S(dataset:'sigma_process_estimation_error');
            S.defineKey('BUSINESS_UNIT','RESERVING_CLASS','ITEM','ORIGIN_YEAR');
            S.defineData('SUM_PROCESS_ERROR_MULTI','SUM_ESTIMATION_ERROR_MULTI');
            S.defineDone();
            call missing(SUM_PROCESS_ERROR_MULTI);
         call missing(SUM_ESTIMATION_ERROR_MULTI);
         end;
         set tmp_ibnr_summary_1;
         rc=S.find();
       CL_ULTIMATE=CUMULATIVE_LOSS/LOSS_CASHFLOW;
       NEW_PROCESS_ERROR=sqrt(CL_ULTIMATE*SUM_PROCESS_ERROR_MULTI);
       NEW_ESTIMATION_ERROR=CL_ULTIMATE*sqrt(SUM_ESTIMATION_ERROR_MULTI);
      run;


     data casuser._&ibnr_summary.(append=force);
         set tmp_ibnr_summary_2;
      run;

   %end;
   /* Calculate C_FACTOR */
   /*This calculation shall not be done for Bu=All*/
   /*This calculation shall be calculated after loss_cashflow is assigned*/
   %if %upcase(&_bu) ne ALL %then %do;

      data _null_;
         set casuser._&ibnr_summary. end=eof;
         retain Known_loss_sum Estimated_loss_sum;
         where upcase(BUSINESS_UNIT)=%upcase("&_bu")
         and upcase(RESERVING_CLASS)=%upcase("&_rc")
       and upcase(Item) = %upcase("&_item");
         if _n_=1 then do;
            known_loss_sum=Cumulative_Loss;
            Estimated_loss_sum=Estimated_Premium*Apriori_Loss_Ratio*Loss_Cashflow;
         end;
         else do;
            known_loss_sum=sum(known_loss_sum,Cumulative_Loss);
            Estimated_loss_sum=sum(Estimated_loss_sum,Estimated_Premium*Apriori_Loss_Ratio*Loss_Cashflow);
         end;
         if eof and (Estimated_loss_sum ne 0) then do;
            call symputx("C_FACTOR",known_loss_sum/Estimated_loss_sum);
         end;
      run;

      %if %symexist(c_factor) %then %do;

      DATA casuser._&ibnr_summary.(replace=yes);
         SET casuser._&ibnr_summary.;
         IF upcase(business_unit) = %upcase("&_bu")
         AND upcase(reserving_class) = %upcase("&_rc")
           AND upcase(Item) = %upcase("&_item")
         THEN
            DO;
               c_factor = &c_factor;
            END;
      RUN;

      %end;

   %end;

   proc casutil;
      droptable casdata="&IBNR_SUMMARY." incaslib="&caslib." quiet;
      save casdata="_&ibnr_summary." incaslib="casuser" casout="&IBNR_SUMMARY." outcaslib="&caslib." replace;
      promote casdata="_&ibnr_summary." incaslib="casuser" casout="&IBNR_SUMMARY." outcaslib="&caslib.";
   run;


%mend;



%macro tail_factor(rc=&_rc,bu=&_bu,item=&_item,name=&_name);;

      proc casutil;
         droptable casdata="_tmp_&factor_summary." incaslib="casuser" QUIET;
      quit;


      DATA tmp_factor_summary casuser._tmp_&factor_summary.(replace=yes);
         SET &caslib..&factor_summary.;
         IF upcase(business_unit) = %upcase("&bu")
            AND upcase(reserving_class) = %upcase("&rc")
            AND upcase(Item) = %upcase("&item")
            AND Name = "Selected"
         THEN do;
         if Development_Period = &_dev then do;
            Factor= &SelFact;
         end;
         output tmp_factor_summary;
        end;
        else do;
         output casuser._tmp_&factor_summary.;
        end;
      RUN;

      proc sort data=tmp_factor_summary;
      by descending DEVELOPMENT_PERIOD;
      run;

      data tmp_factor_summary(drop=age_to_ultimate);
         set tmp_factor_summary;
         retain age_to_ultimate;
         if _n_=1 then do;
            age_to_ultimate=Factor;
         end;
         else do;
            age_to_ultimate=age_to_ultimate*Factor;
         end;
            CASHFLOW=1/age_to_ultimate;
      run;

      data casuser._tmp_&factor_summary.(append=force);
         set tmp_factor_summary;
       run;

   proc casutil;
      droptable casdata="&factor_summary." incaslib="&caslib." quiet;
      promote casdata="_tmp_&factor_summary." incaslib="casuser" casout="&factor_summary." outcaslib="&caslib.";
   run;

%mend;



%MACRO tail_extrapolation_tail(_rc=,_bu=,_item=,_dev=);
      proc casutil;
         droptable casdata="_&Smooth_Table._All" incaslib="CASUSER" QUIET;
      quit;

      PROC SQL;
         SELECT MAX(Development_Period)
         INTO :_max_dev
         FROM &caslib..&factor_summary.
         WHERE business_unit = "&_bu"
            AND reserving_class = "&_rc"
            AND Item = "&_item"
            AND Name = "Selected";
      QUIT;

      /* want to include the last dev period in case the development factor
         increases until the diagonal
      */

      PROC SQL;
         SELECT COUNT(*)
         INTO :Inc_Cnt
         FROM &caslib..&factor_summary.
         WHERE business_unit = "&_bu"
            AND reserving_class = "&_rc"
            AND Item = "&_item"
            AND Name = "Selected"
            AND Development_period BETWEEN &_dev and %sysevalf(&_max_dev - 1)
            AND FACTOR > 1;
      QUIT;

      PROC SQL;
         SELECT COUNT(*)
         INTO :Rev_Cnt
         FROM &caslib..&factor_summary.
         WHERE business_unit = "&_bu"
            AND reserving_class = "&_rc"
            AND Item = "&_item"
            AND Name = "Selected"
            AND Development_period BETWEEN &_dev and %sysevalf(&_max_dev - 1)
            AND FACTOR < 1;
      QUIT;

      %IF %sysevalf(&Inc_Cnt > &Rev_Cnt) %THEN
         %DO;
            DATA CASUSER._&Smooth_Table._Inc;
               SET &caslib..&factor_summary.;
                  source_item = "&_item";
                  dev_part = Factor - 1;
                  ln_dev_part = log(Factor - 1);
                  ln_y = log(Development_Period);
                  Smooth_From = 0;
                  Smooth_To = 0;
               WHERE business_unit = "&_bu"
                  AND reserving_class = "&_rc"
                  AND Item = "&_item"
                  AND Name = "Selected"
                  AND Development_period BETWEEN &_dev and %sysevalf(&_max_dev );
            RUN;
         %END;
      %ELSE
         %DO;
            DATA CASUSER._&Smooth_Table._Inc;
               SET &caslib..&factor_summary.;
                  source_item = "&_item";
                  dev_part = Factor - 1;
                  ln_dev_part = log(1/Factor - 1);
                  ln_y = log(Development_Period);
                  Smooth_From = 0;
                  Smooth_To = 0;
               WHERE business_unit = "&_bu"
                  AND reserving_class = "&_rc"
                  AND Item = "&_item"
                  AND Name = "Selected"
                  AND Development_period BETWEEN &_dev and %sysevalf(&_max_dev );
            RUN;
         %END;

      PROC SQL;
      SELECT *
      FROM CASUSER._&Smooth_Table._Inc;
      QUIT;

      %LET ori_inc = 1;

      %DO dev_var = 1 %TO %sysevalf(&_max_dev-1) %BY 1;
         Data _Null_;
            Set CASUSER._&Smooth_Table._Inc(WHERE=(Name = 'Selected' AND Development_Period=&dev_var));
            Call Symput("ori_inc",(&ori_inc * Factor));
         Run;
      %END;

      /* Inverse Power Law */

      proc nlin data=CASUSER._&Smooth_Table._Inc(where=(Name = 'Selected' AND Development_Period NE &_max_dev));
      parms Gradients = -1 Constant = -1;
      model ln_dev_part = Gradients*ln_y + Constant;
      ods Output ParameterEstimates = InvPowExpPest;
      RUN;

      Data _Null_;
      Set InvPowExpPest(Where=(Parameter="Gradients"));
      Call Symput("Gradient",Estimate);
      Run;

      Data _Null_;
      Set InvPowExpPest(Where=(Parameter="Constant"));
      Call Symput("Constant",Estimate);
      Run;

            DATA CASUSER._&Smooth_Table._IncIP;
               SET CASUSER._&Smooth_Table._Inc(where=(Name = 'Selected'));
               Name = 'Inverse_Power';
               Factor =  exp(&Gradient.*ln_y + &Constant.) + 1.0;
            RUN;

      PROC SQL;
         SELECT *
         FROM CASUSER._&Smooth_Table._IncIP;
      QUIT;

      %IF %sysevalf(&Inc_Cnt < &Rev_Cnt) %THEN
         %DO;
            DATA CASUSER._&Smooth_Table._IncIP;
               SET CASUSER._&Smooth_Table._IncIP;
               Factor = 1/Factor;
            RUN;
         %END;

      DATA CASUSER._&Smooth_Table._Inc;
         SET CASUSER._&Smooth_Table._IncIP CASUSER._&Smooth_Table._Inc;
      RUN;

      PROC SQL;
         SELECT *
         FROM CASUSER._&Smooth_Table._IncIP;
      QUIT;


      %LET invp_inc = 1;

      %DO dev_var = 1 %TO %sysevalf(&_max_dev-1) %BY 1;
         Data _Null_;
            Set CASUSER._&Smooth_Table._Inc(WHERE=(Name = 'Inverse_Power' AND Development_Period=&dev_var));
            Call Symput("invp_inc",(&invp_inc * Factor));
         Run;
      %END;


      PROC SQL;
         SELECT *
         FROM CASUSER._&Smooth_Table._IncIP;
      QUIT;

      DATA CASUSER._&Smooth_Table._Inc;
         SET CASUSER._&Smooth_Table._Inc;
         IF Name = 'Inverse_Power' THEN Factor = Factor * (&ori_inc / &invp_inc)**(1/(&_max_dev - &_dev));
      RUN;

      /* Exponential Decay */

      proc nlin data=CASUSER._&Smooth_Table._Inc(where=(Name = 'Selected' AND Development_Period NE &_max_dev));
      parms Gradients = -1 Constant = -1;
      model ln_dev_part = Gradients*Development_Period + Constant;
      ods Output ParameterEstimates = ExpDecExpPest;
      RUN;

      Data _Null_;
      Set ExpDecExpPest(Where=(Parameter="Gradients"));
      Call Symput("Gradient",Estimate);
      Run;

      Data _Null_;
      Set ExpDecExpPest(Where=(Parameter="Constant"));
      Call Symput("Constant",Estimate);
      Run;

            DATA CASUSER._&Smooth_Table._IncED;
               SET CASUSER._&Smooth_Table._Inc(where=(Name = 'Selected'));
               Name = 'Exponential_Decay';
               Factor = exp(&Gradient.*Development_Period + &Constant.) + 1.0;
            RUN;

      %IF %sysevalf(&Inc_Cnt < &Rev_Cnt) %THEN
         %DO;
            DATA CASUSER._&Smooth_Table._IncED;
               SET CASUSER._&Smooth_Table._IncED;
               Factor = 1/Factor;
            RUN;
         %END;

      DATA CASUSER._&Smooth_Table._Inc;
         SET CASUSER._&Smooth_Table._IncED CASUSER._&Smooth_Table._Inc;
      RUN;

      %LET expd_inc = 1;

      %DO dev_var = 1 %TO %sysevalf(&_max_dev-1) %BY 1;
         Data _Null_;
            Set CASUSER._&Smooth_Table._Inc(WHERE=(Name = 'Exponential_Decay' AND Development_Period=&dev_var));
            Call Symput("expd_inc",(&expd_inc * Factor));
         Run;
      %END;

      DATA CASUSER._&Smooth_Table._Inc;
         SET CASUSER._&Smooth_Table._Inc;
         IF Name = 'Exponential_Decay' THEN Factor = Factor * (&ori_inc / &expd_inc)**(1/(&_max_dev - &_dev));
      RUN;

      /*    To review:
         we take the power to (&_max_dev - &_cut_off - 1) because of the definition of
          &_cut_off and we do not include last term
      */

      proc casutil;
         droptable casdata="_tmp_&factor_summary." incaslib="CASUSER" QUIET;
      quit;

      data CASUSER._tmp_&factor_summary.(replace=yes);
         set &caslib..&factor_summary.;
      run;


PROC SQL;
   SELECT *
   FROM CASUSER._&Smooth_Table._Inc
   ORDER BY Development_Period, Name;
QUIT;

      %DO dev_var = 1 %TO %sysevalf(&_dev-1) %BY 1;
         Data _Null_;
            Set CASUSER._tmp_&factor_summary.(
               WHERE=(business_unit = "&_bu"
                  AND reserving_class = "&_rc"
                  AND Item = "&_item"
                  AND Development_Period = &dev_var
                  AND Name = 'Selected'));
            Call Symput("_factor",Factor);
         Run;

         DATA CASUSER._tmp_&factor_summary.;
            SET CASUSER._tmp_&factor_summary.;
            IF business_unit = "&_bu"
               AND reserving_class = "&_rc"
               AND Item = "&_item"
               AND Development_Period = &dev_var
               AND Name = 'Inverse_Power'
            THEN DO;
               Factor = &_factor;
            END;
         RUN;

         DATA CASUSER._tmp_&factor_summary.;
            SET CASUSER._tmp_&factor_summary.;
            IF business_unit = "&_bu"
               AND reserving_class = "&_rc"
               AND Item = "&_item"
               AND Development_Period = &dev_var
               AND Name = 'Exponential_Decay'
            THEN DO;
               Factor = &_factor;
            END;
         RUN;
      %END;

      %DO dev_var = &_max_dev %TO &_dev %BY -1;
         Data _Null_;
            Set CASUSER._&Smooth_Table._Inc(WHERE=(Name = 'Inverse_Power' AND Development_Period=&dev_var));
            Call Symput("_factor",Factor);
         Run;

         %put _factor;

         DATA CASUSER._tmp_&factor_summary.;
            SET CASUSER._tmp_&factor_summary.;
            IF business_unit = "&_bu"
               AND reserving_class = "&_rc"
               AND Item = "&_item"
               AND Development_Period = &dev_var
               AND Name = 'Inverse_Power'
            THEN DO;
               Factor = &_factor;
            END;
         RUN;

         Data _Null_;
            Set CASUSER._&Smooth_Table._Inc(WHERE=(Name = 'Exponential_Decay' AND Development_Period=&dev_var));
            Call Symput("_factor",Factor);
         Run;

         %put _factor;

         DATA CASUSER._tmp_&factor_summary.;
            SET CASUSER._tmp_&factor_summary.;
            IF business_unit = "&_bu"
               AND reserving_class = "&_rc"
               AND Item = "&_item"
               AND Development_Period = &dev_var
               AND Name = 'Exponential_Decay'
            THEN DO;
               Factor = &_factor;
            END;
         RUN;
      %END;

      %LET InvPowerDev = 1;
      %LET ExpDecayDev = 1;

      %DO dev_var = &_max_dev %TO 1 %BY -1;
         Data _Null_;
            Set CASUSER._tmp_&factor_summary.(
               WHERE=(business_unit = "&_bu"
                  AND reserving_class = "&_rc"
                  AND Item = "&_item"
                  AND Development_Period = &dev_var
                  AND Name = 'Inverse_Power'));
            Call Symput("_factor",Factor);
         Run;

         %LET InvPowerDev = %sysevalf(&InvPowerDev * &_factor);

         DATA CASUSER._tmp_&factor_summary.;
            SET CASUSER._tmp_&factor_summary.;
            IF business_unit = "&_bu"
               AND reserving_class = "&_rc"
               AND Item = "&_item"
               AND Development_Period = &dev_var
               AND Name = 'Inverse_Power'
            THEN DO;
               Cashflow = %sysevalf(1/&InvPowerDev);
            END;
         RUN;

         Data _Null_;
            Set CASUSER._tmp_&factor_summary.(
               WHERE=(business_unit = "&_bu"
                  AND reserving_class = "&_rc"
                  AND Item = "&_item"
                  AND Development_Period = &dev_var
                  AND Name = 'Exponential_Decay'));
            Call Symput("_factor",Factor);
         Run;

         %LET ExpDecayDev = %sysevalf(&ExpDecayDev * &_factor);

         DATA CASUSER._tmp_&factor_summary.;
            SET CASUSER._tmp_&factor_summary.;
            IF business_unit = "&_bu"
               AND reserving_class = "&_rc"
               AND Item = "&_item"
               AND Development_Period = &dev_var
               AND Name = 'Exponential_Decay'
            THEN DO;
               Cashflow = %sysevalf(1/&ExpDecayDev);
            END;
         RUN;
      %END;

      PROC SQL;
      SELECT *
      FROM CASUSER._tmp_&factor_summary.
      WHERE business_unit = "&_bu"
         AND reserving_class = "&_rc"
         AND Item = "&_item"
         AND Name in ("Selected","Exponential_Decay","Inverse_Power");
      QUIT;

      proc casutil;
         droptable casdata="_&factor_summary." incaslib="casuser" QUIET;
      quit;

      DATA CASUSER._&factor_summary.;
         SET CASUSER._tmp_&factor_summary.;
      RUN;

      proc casutil;
         droptable casdata="&factor_summary." incaslib="&caslib." QUIET;
         promote casdata="_&factor_summary." incaslib="CASUSER"  casout="&factor_summary." outcaslib="&caslib.";
      run;



%MEND;
