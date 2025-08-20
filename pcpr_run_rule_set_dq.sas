/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
   \anchor  pcpr_run_rule_set_dq
   \brief   This macro is used to run rule set for data quality based on user specified filter conditions through generic table.
            Before calling this macro, create a configuraiton table by calling the parser function ${function:GetSASDSCode(Params.spreadsheet.rowState, "&generic_lib..&generic_table_name.")}.
            The parser function transforms the data in json format from the generic table component into sas format.

   \param [in] CONFIG_TABLE_LIB         Configuration table library
   \param [in] CONFIG_TABLE_NM          Configuration table name
   \param [in] REQUIRED_COL_LIST        List of columns required by this macro in the configuration table, space separated
   \param [in] TARGET_LIB               CAS library for the input and output data quality tables


   \details run data quality rule sets.
   \Note   This macro is called by check data quality scripts

   \ingroup Macros
   \author  SAS Institute Inc.
   \date    2023
*/

%macro pcpr_run_rule_set_dq(CONFIG_TABLE_LIB=, CONFIG_TABLE_NM=, REQUIRED_COL_LIST=, TARGET_LIB=);

    /*Make sure config table exist*/
    %if not %rsk_dsexist(&CONFIG_TABLE_LIB..&CONFIG_TABLE_NM.) %then %do;
        %PUT ERROR: Configuration table &CONFIG_TABLE_LIB..&CONFIG_TABLE_NM. does not exist.;
        %abort;
    %end;

    %if &REQUIRED_COL_LIST eq %then %do;
       %PUT ERROR: A list of required columns needs to be specified.;
       %abort;
    %end;

    %global SUCCESS_FLG MISSING_VAR;

    %rsk_verify_ds_col(REQUIRED_COL_LIST=&REQUIRED_COL_LIST., IN_DS_LIB =&CONFIG_TABLE_LIB., IN_DS_NM =&CONFIG_TABLE_NM., OUT_SUCCESS_FLG =SUCCESS_FLG, OUT_MISSING_VAR =MISSING_VAR);

    %if &SUCCESS_FLG.=N %then %do;
        %PUT ERROR: The following variable "&MISSING_VAR." is not present in &CONFIG_TABLE_LIB..&CONFIG_TABLE_NM..;
        %abort;
    %end;

    %if %rsk_attrn(&CONFIG_TABLE_LIB..&CONFIG_TABLE_NM., nobs) %then %do;
        /*Check missing values in the table*/
        %let n_col=%rsk_wordcount(&REQUIRED_COL_LIST.);
        %let check_list=;
        %do i=1 %to &n_col;
              %let check_col=%scan(&REQUIRED_COL_LIST.,&i);
              %if &i=&n_col %then %do;
                 %let check_list=&check_list missing(&check_col);
              %end;
              %else %do;
                 %let check_list=&check_list missing(&check_col) or;
              %end;
        %end;
        %put &check_list.;
        data &CONFIG_TABLE_LIB..&CONFIG_TABLE_NM._MISSING;
             set &CONFIG_TABLE_LIB..&CONFIG_TABLE_NM.;
             if &check_list.;
        run;
        %if %rsk_attrn(&CONFIG_TABLE_LIB..&CONFIG_TABLE_NM._MISSING, nobs) %then %do;
             %PUT ERROR: There are missing values in &CONFIG_TABLE_LIB..&config_table_nm..;
             %abort;
        %end;

         /*Add additional information column*/
        data &CONFIG_TABLE_LIB..&CONFIG_TABLE_NM.;
            set &CONFIG_TABLE_LIB..&CONFIG_TABLE_NM.;
            cas_lib="&TARGET_LIB.";
        run;

        /*create file to run code from the configuration table*/
        filename rulesDQ filesrvc folderPath='/Products/SAS Dynamic Actuarial Modeling' filename= "rule_set_code.sas" debug=http lrecl = 33000;

        data _NULL_;
            length STATEMENT $10000. ;
                set &CONFIG_TABLE_LIB..&CONFIG_TABLE_NM.;
                file rulesDQ;
                STATEMENT =  cat('%core_rest_get_rule_set(
                    ruleSetId =', strip(RuleSetName),
                    ', outds_ruleSetInfo = work.ruleset_info
                    , outds_ruleSetData = work.ruleset_data
                    , outVarToken = accessToken
                    , outSuccess = httpSuccess
                    , outResponseStatus = responseStatus
                    , solution = PCPRICING
					, ruleSetSSC = PCPRICING
                    , debug = &debug.
                    );

                    /*Add source and target table to the parsed rule set data*/
                    data ruleset_data;
                        set ruleset_data;
                        source_table =', '"',strip(catx('.', cas_lib, InputTableName)),'"',';
                        target_table =', '"',strip(catx('.', cas_lib, OutputTableName)),'"',';
                    run;

                    %pcpr_drop_promoted_table(caslib_nm=', strip(cas_lib),
                        ',table_nm=', strip(OutputTableName),
                        ');

                    %core_run_rules(ds_rule_def = ruleset_data
                                    , outCasLib = &TARGET_LIB.
                                    , ds_out_summary = ruleset_summary
                                    ) ;

                    %pcpr_promote_table_to_cas(input_caslib_nm=', strip(cas_lib),
                                                ',input_table_nm=', strip(OutputTableName),
                                                ',output_caslib_nm=', strip(cas_lib),
                                                ',output_table_nm=', strip(OutputTableName),
                                                ',drop_sess_scope_tbl_flg=Y);

                    %pcpr_save_table_to_cas(in_caslib_nm=', strip(cas_lib),
                                                ',in_table_nm=', strip(OutputTableName),
                                                ',out_caslib_nm=', strip(cas_lib),
                                                ',out_table_nm=', strip(OutputTableName),
                                                ',replace_flg=true);'
        );

                put STATEMENT ;
        run;

        /*run code if code file is created sucessfully then delete it*/
        %if %sysfunc(fexist(rulesDQ)) %then %do ;
            %inc rulesDQ ;
            %let delete_file_code=%sysfunc(fdelete(rulesDQ));
        %end ;
    %end;
    %else %do;
        %PUT NOTE: There are no observations in the configuration table &CONFIG_TABLE_LIB..&config_table_nm..;
    %end;

%mend pcpr_run_rule_set_dq;
