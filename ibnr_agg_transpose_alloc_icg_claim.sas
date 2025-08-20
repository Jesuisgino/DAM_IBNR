/*This macro completes 2 tasks: 1. create ICG_INCUR_TODATE 2. create ALLOC_MATRIX */
/*** Aggregate and transpose Input_ICG_Claims */
%macro agg_transpose_alloc_icg_claim();

   /*first check input table exist*/
   %rsk_dsexist_cas(cas_lib = %superq(caslib)
                      ,cas_table = %superq(input_icg_claim)
                      );

      %if not &cas_table_exists. %then %do;
         %put ERROR: input ICG claim table does not exist, abort process;
         %abort;
      %end;
      %else %if %rsk_attrn(&caslib..&input_icg_claim.,nlobs) eq 0 %then %do;
         %put ERROR: input ICG claim table does not contain observation, cash flow allocation will not be performed;
         %abort;
      %end;

      proc casutil;
         droptable casdata="_tmp_&Icg_incur_todate." incaslib="casuser" QUIET;
      quit;

      proc casutil;
         droptable casdata="_tmp_&alloc_matrix." incaslib="casuser" QUIET;
      quit;


   proc means data=&caslib..&input_icg_claim. noprint nway missing;
      output out=work.Icg_claims_agg (drop= _type_ _freq_) sum=;
      var Claim_amount ;
      class ICG_Id AccidentYear ;
   run ;

   data work.Icg_claims_agg;
    set work.Icg_claims_agg ;
    AY = year(AccidentYear) ;
    sortorder_icg=substr(ICG_Id ,7,4);
    format Claim_amount   comma18.2;
   run;

   proc sort data=work.Icg_claims_agg ;
    by  sortorder_icg ICG_Id ;
   run;
   proc transpose data=work.Icg_claims_agg
     out=work.Icg_incur_todate  (drop= _name_ )
     prefix=AY ;
     var Claim_amount;
     id AY;
    by sortorder_icg ICG_Id;
   run;

   /* Create mapping table for ICG names */
   data work.ICG_id_map ;
    set work.Icg_incur_todate (keep=ICG_Id)  ;
    ICG_techid = compress("ICGtechid" || _n_) ;
   run;

   /* First do alternative transpose to make things easier */
   proc sort data=work.Icg_claims_agg ;
    by AY ;
   run;
   proc transpose data=work.Icg_claims_agg
     out=work.Icg_incur_todate_alt  (drop= _name_ )  ;
     var Claim_amount;
     id ICG_Id;
    by  AY;
   run;


   /* get nbr of ICG*/
   proc sql noprint;
    select count(ICG_Id) into :Nmbr_icg
     from work.Icg_incur_todate  ;
   quit;
   %let Nmbr_icg = %sysfunc(strip(&Nmbr_icg));
   %put Nmbr_icg = &Nmbr_icg ;


   /* Calc transp Alloc matrix */
   data work.alloc_matrix_trans (drop= i tot_claim_ay  ICG_:);
    set  work.Icg_incur_todate_alt ;
    array  Claim_amt[*]          ICG: ;
    array   Claim_pct[*]            ICGpct1-ICGpct&Nmbr_icg ;

    tot_claim_ay = 0;
    do i=1 to &Nmbr_icg ;
      tot_claim_ay = sum(tot_claim_ay, Claim_amt[i]) ;
    end;
    do i=1 to &Nmbr_icg ;
      Claim_pct[i] =  Claim_amt[i] / tot_claim_ay;
    end;
   format ICGpct1-ICGpct&Nmbr_icg percent9.2 ;
   run;

   /* Transpose to get desired form */
   proc transpose data=work.alloc_matrix_trans
     out=work.alloc_matrix   (drop= _name_)
      prefix=AY ;
    id AY ;
   run;

   /* get back orig ICG_ID */
   data work.alloc_matrix (drop= rc );
    length ICG_ID  $12;
    set work.alloc_matrix  ;
    ICG_TECHID = compress("ICGtechid" || _n_) ;
    if _n_ eq 1 then do;
     declare hash h(hashexp:6 , dataset: "work.icg_id_map");
     rc = h.defineKey(/*'Business_Unit','Reserving_class','Item',*/'ICG_TECHID');
     rc = h.defineData('ICG_ID');
     rc = h.defineDone();
    end;
    rc = h.find();
    SORTORDER_ICG=substr(ICG_ID ,7,4);
   run;

   /*Transpose data sets*/

   proc sort data=alloc_matrix;
   by ICG_ID ICG_TECHID SORTORDER_ICG;
   run;

   proc transpose data=alloc_matrix out=alloc_matrix_trans_by_ay(rename = (_NAME_ = Accident_Year COL1=ALLOC_PCT));
   var AY:;
   by ICG_ID ICG_TECHID SORTORDER_ICG;
   run;

   proc sort data=Icg_incur_todate;
   by ICG_ID SORTORDER_ICG;
   run;

    proc transpose data=work.Icg_incur_todate
      out=work.Icg_incur_todate_by_ay(rename = (_NAME_ = Accident_Year  COL1=AMOUNT));
   var AY:;
   by ICG_ID SORTORDER_ICG;
    run;

   /* Store in CAS */

      data casuser._tmp_&Icg_incur_todate.(DROP = Accident_Year replace=yes);
         set Icg_incur_todate_by_ay;
          LENGTH AY 8;
          AY = input(substr(Accident_Year,3),4.0);
      run;

      data casuser._tmp_&alloc_matrix.(DROP = Accident_Year replace=yes);
         set alloc_matrix_trans_by_ay;
          LENGTH AY 8;
          AY = input(substr(Accident_Year,3),4.0);
      run;

      proc casutil;
         droptable casdata="&Icg_incur_todate." incaslib="&caslib." quiet;
         promote casdata="_tmp_&Icg_incur_todate." incaslib="casuser" casout="&Icg_incur_todate." outcaslib="&caslib.";
      run;

      proc casutil;
         droptable casdata="&alloc_matrix." incaslib="&caslib." quiet;
         promote casdata="_tmp_&alloc_matrix." incaslib="casuser" casout="&alloc_matrix." outcaslib="&caslib.";
      run;

   %save_data(&Icg_incur_todate.);
    %save_data(&alloc_matrix.);

%mend;
