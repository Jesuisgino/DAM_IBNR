/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
   \anchor  pcpr_analytic_partition
   \brief   This macro is used to perform SIMPLE or STRATIFY sampling and then create modeling, backtesting, and/or business backtesting
         It includes the following steps: 1. re-calculate modeling and backtesting percentage based on user selected options so that the re--calculated modeling, backtesting and business backtesting add up to 1
                                2. call %pcpr_random_sampling to create PARTINDNAME variable
                                3. call %pcpr_filter_cas_table to create modeling, backtesting, and/or business backtesting table

   \param [in] INCASLIB                 Input cas library name
   \param [in] INCASTABLE               Input cas table name
   \param [in] OUTCASLIB                Output cas library name
   \param [in] OUTPUT_SAMPLING          Ouput table from random sampling with partition index
   \param [in] OUTPUT_MDL               Ouput modeling table from filtering partition index
   \param [in] OUTPUT_BKT               Ouput backtesting table from filtering partition index
   \param [in] OUTPUT_BBKT              Ouput business backtesting table from filtering partition index
   \param [in] MDLPCT                   User selected modeling percentage
   \param [in] MDLBKT                   User selected backtesting percentage
   \param [in] MDLBBKT                  User selected business backtesting percentage
   \param [in] SAMPLING_METHOD          Sample method: SIMPLE vs STRATIFY
   \param [in] STRATIFY_VARIABLES       The variable list that will used for stratify sampling
   \param [in] PARTINDNAME              The partition index variable
   \param [in] OUTPUT_TABLE_LIST        The macro variable name that hold the list of output tables
   \param [in] cas_session_name         Cas session name optional


   \details Perform randm/stratified sampling and create modeling, backtesting, and bsuiness backtsting tables.
   \Note   This macro is called by analytic partition script

   \ingroup Macros
   \author  SAS Institute Inc.
   \date    2023
*/

%macro pcpr_analytic_partition(INCASLIB=, INCASTABLE=, OUTCASLIB=, OUTPUT_SAMPLING=,OUTPUT_MDL=, OUTPUT_BKT=, OUTPUT_BBKT=,MDLPCT=0, BKTPCT=0, BBKTPCT=0, SAMPLING_METHOD=, STRATIFY_VARIABLES=, PARTINDNAME=,  OUTPUT_TABLE_LIST=, cas_session_name=&casSessionName.);

    /*First need to re-calculate the sampling percentage to partition input table*/
    %if %sysfunc(sum(&MDLPCT.,&BKTPCT.,&BBKTPCT.)) > 0 %then %do;
        %let modelPerc=%sysevalf(&MDLPCT./%sysfunc(sum(&MDLPCT.,&BKTPCT.,&BBKTPCT.)));
        %let bktPerc=%sysevalf(&BKTPCT./%sysfunc(sum(&MDLPCT.,&BKTPCT.,&BBKTPCT.)));
    %end;
    %else %do;
        %let modelPerc=0;
        %let bktPerc=0;
    %end;
    %if not %symexist(&OUTPUT_TABLE_LIST.) %then
    %do;
        %global &OUTPUT_TABLE_LIST.;
    %end;

%let &OUTPUT_TABLE_LIST. =;
%let set =;

/* To ensure we set str_set_out */
%if (%sysevalf(%superq(OUTPUT_TABLE_LIST) eq, boolean)) %then
    %do;
        data _null_;
            _set="OUTPUT_TABLE_LIST";
            %put WARNING: Parameter OUTPUT_TABLE_LIST is empty. Setting OUTPUT_TABLE_LIST to a default value: OUTPUT_TABLE_LIST .;
            call symput("set", _set);
        run;
        %let &OUTPUT_TABLE_LIST. = &set.;
        %return;
    %end;


    %pcpr_random_sampling( INCASLIB= &INCASLIB.
                                    , INCASTABLE= &INCASTABLE.
                                    , OUTCASLIB= &OUTCASLIB.
                                    , OUTCASTABLE=&OUTPUT_SAMPLING.
                                     , MDLPCT= &MDLPCT.
                                    , BKTPCT= &BKTPCT.
                                    , SAMPLING_METHOD=&SAMPLING_METHOD.
                                    , STRATIFY_VARIABLES= &STRATIFY_VARIABLES.
                                    , PARTINDNAME= &PARTINDNAME.);

      %let filter_mdl=%bquote(&PARTINDNAME.=1);
      %let filter_bkt=%bquote(&PARTINDNAME.=2);
      %let filter_bbkt=%bquote(&PARTINDNAME.=0);

    %if &MDLPCT.>0 %then %do;
        %pcpr_filter_cas_table(INCASLIB=&INCASLIB.
                            , INCASTABLE=&OUTPUT_SAMPLING.
                            , OUTCASLIB=&OUTCASLIB.
                            , OUTCASTABLE=&OUTPUT_MDL.
                            , FILTER_EXPRESSION=&filter_mdl.
                            , DROP_COL_LIST=&PARTINDNAME.);
        %let set = &set. &OUTPUT_MDL.;
    %end;
    %if &BKTPCT.>0 %then %do;
        %pcpr_filter_cas_table(INCASLIB=&INCASLIB.
                            , INCASTABLE=&OUTPUT_SAMPLING.
                            , OUTCASLIB=&OUTCASLIB.
                            , OUTCASTABLE=&OUTPUT_BKT.
                            , FILTER_EXPRESSION=&filter_bkt.
                            ,DROP_COL_LIST=&PARTINDNAME.);
        %let set = &set. &OUTPUT_BKT.;
     %end;
    %if %sysevalf(1-&MDLPCT.-&BKTPCT.) >0 %then %do;
        %pcpr_filter_cas_table( INCASLIB=&INCASLIB.
                            ,INCASTABLE=&OUTPUT_SAMPLING.
                            , OUTCASLIB=&OUTCASLIB.
                            ,OUTCASTABLE=&OUTPUT_BBKT.
                            , FILTER_EXPRESSION=&filter_bbkt.
                            ,DROP_COL_LIST=&PARTINDNAME.);
        %let set = &set. &OUTPUT_BBKT.;
    %end;

    %let &OUTPUT_TABLE_LIST. = &set.;

%put The following output tables are created for input table &INCASTABLE.: &&&OUTPUT_TABLE_LIST.;
%mend pcpr_analytic_partition;
