/*This macro performs 2 tasks: 1. allocate projected cashflow based on alloc_matrix 2. generate cashflow based on projected cf*/
/***** Perform CF alloc by ICG */
/**  via Matrix multipic of Alloc_matrix by Projected_CF */


/**** Get datasets in right format for IML */
%macro alloc_generate_insurance_cf();

/*First check input table exist*/
   %rsk_dsexist_cas(cas_lib = %superq(caslib)
                      ,cas_table = %superq(Alloc_matrix)
                      );

      %if not &cas_table_exists. %then %do;
         %put ERROR: input allocation matrix does not exist, abort process;
         %abort;
      %end;
      %else %if %rsk_attrn(&caslib..&Alloc_matrix.,nlobs) eq 0 %then %do;
         %put ERROR: input allocation matrix does not contain observation, cash flow allocation will not be performed;
         %abort;
      %end;

   %rsk_dsexist_cas(cas_lib = %superq(caslib)
                      ,cas_table = %superq(Projected_CF)
                      );

      %if not &cas_table_exists. %then %do;
         %put ERROR: The projected cashflow table does not exist, abort process;
         %abort;
      %end;
      %else %if %rsk_attrn(&caslib..&Projected_CF.,nlobs) eq 0 %then %do;
         %put ERROR: The projected cashflow table does not contain observation, cash flow allocation will not be performed;
         %abort;
      %end;

   %rsk_dsexist_cas(cas_lib = %superq(caslib)
                      ,cas_table = %superq(input_expense_ratio)
                      );

      %if not &cas_table_exists. %then %do;
         %put ERROR: The expense ratio table does not exist, abort process;
         %abort;
      %end;
      %else %if %rsk_attrn(&caslib..&input_expense_ratio.,nlobs) eq 0 %then %do;
         %put ERROR: The expense ratio table does not contain observation, cash flow allocation will not be performed;
         %abort;
      %end;

/*Check if target table exist, if yes, then find out if filter condition exist, if yes, then replace. Otherwise, create new*/
   %rsk_dsexist_cas(cas_lib = %superq(caslib)
                      ,cas_table = %superq(projected_cf_by_icg)
                      );

   %if &cas_table_exists. %then %do;
      proc casutil;
         droptable casdata="_tmp_&projected_cf_by_icg." incaslib="casuser" QUIET;
      quit;

      data projected_cf_by_icg casuser._tmp_&projected_cf_by_icg.(replace=yes);
         set &caslib..&projected_cf_by_icg.;
        if upcase(business_unit) = %upcase("&_bu")
            AND upcase(reserving_class) = %upcase("&_rc")
            AND upcase(Item) = %upcase("&_item") then do;
         output projected_cf_by_icg;
        end;
        else do;
         output casuser._tmp_&projected_cf_by_icg.;
        end;
      run;

   %end;

/*Check if target table exist, if yes, then find out if filter condition exist, if yes, then replace. Otherwise, create new*/
   %rsk_dsexist_cas(cas_lib = %superq(caslib)
                      ,cas_table = %superq(Insurance_cf_lic_claims)
                      );

   %if &cas_table_exists. %then %do;
      proc casutil;
         droptable casdata="_&Insurance_cf_lic_claims." incaslib="casuser" QUIET;
      quit;

      data Insurance_cf_lic_claims casuser._&Insurance_cf_lic_claims.(replace=yes);
         set &caslib..&Insurance_cf_lic_claims.;
        if upcase(business_unit) = %upcase("&_bu")
            AND upcase(reserving_class) = %upcase("&_rc")
            AND upcase(Item) = %upcase("&_item") then do;
         output Insurance_cf_lic_claims;
        end;
        else do;
         output casuser._&Insurance_cf_lic_claims.;
        end;
      run;

   %end;

/*Check if target table exist, if yes, then find out if filter condition exist, if yes, then replace. Otherwise, create new*/
   %rsk_dsexist_cas(cas_lib = %superq(caslib)
                      ,cas_table = %superq(Insurance_cf_lic_expenses)
                      );

   %if &cas_table_exists. %then %do;
      proc casutil;
         droptable casdata="_&Insurance_cf_lic_expenses." incaslib="casuser" QUIET;
      quit;

      data Insurance_cf_lic_expenses casuser._&Insurance_cf_lic_expenses.(replace=yes);
         set &caslib..&Insurance_cf_lic_expenses.;
        if upcase(business_unit) = %upcase("&_bu")
            AND upcase(reserving_class) = %upcase("&_rc")
            AND upcase(Item) = %upcase("&_item") then do;
         output Insurance_cf_lic_expenses;
        end;
        else do;
         output casuser._&Insurance_cf_lic_expenses.;
        end;
      run;

   %end;

   /*Transpose alloc_matrix to get ready to merge with projected CF*/
   data work.Alloc_matrix_selected;
    set &caslib..&Alloc_matrix.;
   run;

   data Alloc_matrix_selected_trans_new(drop=AY );
      set Alloc_matrix_selected;
        length ORIGIN_YEAR 8;
      ORIGIN_YEAR=AY;
      if missing(ALLOC_PCT) then ALLOC_PCT=0;
   run;

   /*Get the cashflow from projected_cf*/
   data projected_cf_selected;
      set &caslib..&Projected_CF.;
      where upcase(business_unit) = %upcase("&_bu")
            AND upcase(reserving_class) = %upcase("&_rc")
            AND upcase(Item) = %upcase("&_item");
   run;

   /*Merge the alloc matrxi with project cashflow*/
   proc sort data=Alloc_matrix_selected_trans_new;
   by ORIGIN_YEAR;
   run;

   proc sort data=projected_cf_selected;
   by Business_Unit Reserving_class Item Origin_Year;
   run;

    /*Transpose Projected_cf_selected*/
    proc transpose data = projected_cf_selected out = projected_cf_trans
       PREFIX=CF_;
       by Business_Unit Reserving_class Item Origin_Year;
       id CASHFLOW_DATE;
    run;
   data Proj_CF_by_ICG_merged;
      merge Alloc_matrix_selected_trans_new(in=a) projected_cf_trans(in=b);
      by ORIGIN_YEAR;
      if a and b;
   run;

   /*Multiply each CF with its allocation pct*/
   data Proj_CF_by_ICG_selec;
      set Proj_CF_by_ICG_merged;
      %do i=1 %to &Max_dev_period;
         CF_01JAN%sysevalf(&Max_Origin_Year.+&i.)=CF_01JAN%sysevalf(&Max_Origin_Year.+&i.)*ALLOC_PCT;
      %end;
   run;

   /*Summary up by ICG_ID*/
   proc means data=Proj_CF_by_ICG_selec noprint nway missing;
      output out=projected_cf_by_icg (drop= _type_ _freq_) sum=;
      var CF_01JAN: ;
      class business_unit reserving_class item sortorder_icg ICG_id;
   run ;

   /*Generate insurance cashflows based on ifrs17 insurance cashflow structure*/
/******** Getting generated CF's in SAS IFRS17 INSURANCE_CASHFLOW format **/

/** Create template of INSURANCE_CASHFLOW_temp */
   proc sql noprint ;
   CREATE TABLE work.INSURANCE_CASHFLOW_temp (
        REPORTING_DT                DATE FORMAT=date9. INFORMAT=date9. label='Reporting Date',
        ENTITY_ID                   VARCHAR(36) label='Reporting Entity',
        INSURANCE_CONTRACT_GROUP_ID VARCHAR(36) label='Position Identifier',
        CASHFLOW_LEG_NM             VARCHAR(32) label='Cash flow Leg Name',
        CEDED_FLG                   VARCHAR(1) label='Ceded flag',
        CASHFLOW_TYPE_CD            VARCHAR(10) label='Cash flow type code',
        CURRENCY_CD                 VARCHAR(3) label='Currency code',
        INCURRED_CLAIM_DT           DATE FORMAT=date9. INFORMAT=date9. label='Incurred claims date',
        CASHFLOW_DT                 DATE FORMAT=date9. INFORMAT=date9. label='Date of Cash flow',
        CASHFLOW_AMT                NUMERIC(18,5) FORMAT=comma18.2 INFORMAT=NLNUM18.5 label='Cash flow Amount',
       BUSINESS_UNIT           VARCHAR(36),
       RESERVING_CLASS         VARCHAR(36),
       ITEM                 VARCHAR(36)
        );
   quit ;


/** Starting from the Projected_CF_by_ICG we will transform data to SAS IFRS17 INSURANCE_CASHFLOW format */
/**  for LIC Claims  => CASHFLOW_LEG_NM =  LCL_CLAIMS_AMT */


   proc sort data=work.Projected_CF_by_ICG;
     by Business_Unit Reserving_Class Item sortorder_icg ICG_id ; run;

    proc transpose data = projected_cf_by_icg out =projected_cf_by_icg_trans (rename = (_NAME_ = CF_DATE COL1=Cashflow_Amt));
       BY business_unit reserving_class item sortorder_icg ICG_id;
         var CF_01JAN: ;
    run;
   proc transpose data=work.Projected_CF_by_ICG
     out=work.Ins_cf_claims  ;
    by Business_Unit Reserving_Class Item sortorder_icg ICG_id ;
     var CF_01JAN: ;
   run;

   /* get in right format for LIC Claims */
   data work.Ins_cf_claims (drop= sortorder_icg _name_)  ;
    set work.Ins_cf_claims  (rename=(ICG_ID=INSURANCE_CONTRACT_GROUP_ID  COL1=Cashflow_Amt )) ;
    Reporting_dt = "1jan2020"d ;
    Entity_id = Business_Unit ;
    CEDED_FLG = "N" ;
    CURRENCY_CD = "EUR" ;
    CASHFLOW_LEG_NM =  "LCL_CLAIMS_AMT" ;
    Cashflow_Amt = -Cashflow_Amt;
    CASHFLOW_TYPE_CD = "EXI" ;
    CASHFLOW_DT = input(substr(_name_,4), date9.)  ;
    INCURRED_CLAIM_DT = CASHFLOW_DT ;
    format Reporting_dt INCURRED_CLAIM_DT CASHFLOW_DT date9.;
    if Cashflow_Amt not in (0,.) ;  /* delete the CF with zero of missing amount */
   run;

   /* push to pixel-perfect format */
   data work.Insurance_cf_lic_claims ;
    set work.insurance_cashflow_temp (obs=0) ;
   run;
   proc append base=work.Insurance_cf_lic_claims data=work.Ins_cf_claims force; run;


   /** Starting from the Insurance_cf_lic_claims get the Expense ratio and calculate LIC Expenses */
   /**  for LIC Expenses  => CASHFLOW_LEG_NM =  LCL_SETTL_COSTS_AMT */

   /* libname Inputjan  "/home/sasdemo/jan/" ; */

   /* get the Expense ration from inputjan.Input_Expense_ratio */
   data _null_ ;
    set &caslib..&input_expense_ratio. ;
    where Parameter="Accident_expenses" ;
    call symput('Accident_exp_pct',Value) ;
   run;
   %put Accident_exp_pct=&Accident_exp_pct ;

   data  work.Insurance_cf_lic_expenses ;
    set work.Insurance_cf_lic_claims ;
    CASHFLOW_LEG_NM =  "LCL_SETTL_COSTS_AMT" ;
    Cashflow_Amt = Cashflow_Amt * &Accident_exp_pct ;
   run;


   /*store back to CAS*/
   data casuser._tmp_&projected_cf_by_icg.(DROP = CF_DATE append=force);
      set projected_cf_by_icg_trans;
      length Cashflow_Date 8;
      Cashflow_Date = input(substr(CF_DATE,4), anydtdte12.)  ;
      label Cashflow_Date = "Cashflow Date";
      format Cashflow_Date date9.;
   run;

   data casuser._&Insurance_cf_lic_claims.(append=force);
      set Insurance_cf_lic_claims;
   run;

   data casuser._&Insurance_cf_lic_expenses.(append=force);
      set Insurance_cf_lic_expenses;
   run;

   proc casutil;
      droptable casdata="&projected_cf_by_icg." incaslib="&caslib." quiet;
      save casdata="_tmp_&projected_cf_by_icg." incaslib="casuser" casout="&projected_cf_by_icg." outcaslib="&caslib." replace;
      promote casdata="_tmp_&projected_cf_by_icg." incaslib="casuser" casout="&projected_cf_by_icg." outcaslib="&caslib.";
   run;

   proc casutil;
      droptable casdata="&Insurance_cf_lic_claims." incaslib="&caslib." quiet;
      save casdata="_&Insurance_cf_lic_claims." incaslib="casuser" casout="&Insurance_cf_lic_claims." outcaslib="&caslib." replace;
      promote casdata="_&Insurance_cf_lic_claims." incaslib="casuser" casout="&Insurance_cf_lic_claims." outcaslib="&caslib.";
   run;

   proc casutil;
      droptable casdata="&Insurance_cf_lic_expenses." incaslib="&caslib." quiet;
      save casdata="_&Insurance_cf_lic_expenses." incaslib="casuser" casout="&Insurance_cf_lic_expenses." outcaslib="&caslib." replace;
      promote casdata="_&Insurance_cf_lic_expenses." incaslib="casuser" casout="&Insurance_cf_lic_expenses." outcaslib="&caslib.";
   run;


%mend;
