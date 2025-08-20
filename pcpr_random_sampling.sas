/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
   \anchor  pcpr_random_sampling
   \brief   Analytical macro to create partition index column, which will be used to filter and create tables for modeling, backtesting, and business backtesting, by
            performing simple random sampling and stratified random sampling based on SAMPLING_METHOD;

   \param [in] INCASLIB                Input cas library name
   \param [in] INCASTABLE               Input cas table name
   \param [in] OUTCASLIB                Output cas library name
   \param [in] OUTCASTABLE              Ouput cas table name
   \param [in] MDLPCT                   Modeling output sample percentage
   \param [in] BKTPCT                   Backtesting output sample percentage
   \param [in] SAMPLING_METHOD          SIMPLE vs STRATIFY
   \param [in] STRATIFY_VARIABLES       List of variables used as groupby for stratified sampling
   \param [in] PARTINDNAME              Name of the index variable


   \details Save the table to caslib

   \ingroup Macros
   \author  SAS Institute Inc.
   \date    2022
*/

%macro pcpr_random_sampling(INCASLIB=,INCASTABLE=, OUTCASLIB=,OUTCASTABLE=, MDLPCT=, BKTPCT= , SAMPLING_METHOD=, STRATIFY_VARIABLES=, PARTINDNAME= );
            *=======================================================================================;
            *  If sampling method is not specified, then use simple
            *=======================================================================================;

            %if &SAMPLING_METHOD= %then %do;
                %let m_sampling_method=SIMPLE;
            %end;
            %else %do;
                 %let m_sampling_method=&SAMPLING_METHOD.;
            %end;
            *=======================================================================================;
            *  Perform Simple Random Sampling by Creating a partition variable
            *=======================================================================================;
            %if %upcase(&m_sampling_method.) = SIMPLE %then %do;
                        proc cas;
                           loadactionset "sampling";
                           action srs result=r/table={name="&INCASTABLE.",caslib="&INCASLIB."}
                              samppct=&MDLPCT. samppct2=&BKTPCT. partind="TRUE"  seed=0
                              output={casout={caslib="&OUTCASLIB.",name="&OUTCASTABLE.",replace="TRUE"},
                                      copyVars="ALL",partindname="&PARTINDNAME."};
                           run;
                        quit;
            %end;
            %else %if  %upcase(&m_sampling_method.) = STRATIFY %then %do;
                        *=======================================================================================;
                        *  Perform Stratified Random Sampling by Creating a partition variable
                        *=======================================================================================;
                        /*Need to check if groupby variable is selected*/
                        proc cas;
                            loadactionset "sampling";
                            action stratified result=r/table={name="&INCASTABLE.",caslib="&INCASLIB.",groupby=&STRATIFY_VARIABLES.}
                            samppct=&MDLPCT. samppct2=&BKTPCT.  seed=0
                            output={casout={caslib="&OUTCASLIB.",name="&OUTCASTABLE.",replace="TRUE"},
                                    copyVars="ALL",partindname="&PARTINDNAME."};
                            run;
                        print r.STRAFreq; run;
                        quit;


            %end;
            %else %do;
                %put WARNING: the specified sampling method is not currently supported;
            %end;

%mend pcpr_random_sampling;
