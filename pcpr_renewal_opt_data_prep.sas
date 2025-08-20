/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
   \anchor pcpr_renewal_opt_data_prep
   \brief   Data Preparation for Renewal Optimization

   \param [in] cas_session_nm                   CAS session name
   \param [in] caslib_nm                        CAS library name for inputs and outputs
   \param [in] in_train_nm                      Input training cas table name for renewal optimization
   \param [in] in_rate_inc_nm                   Input cas table name for rate increase
   \param [in] map_record_id                    Input variable to map column RECORD_ID
   \param [in] map_previous_premium_amt         Input variable to map column PREVIOUS_PREMIUM_AMT
   \param [in] map_increase_id                  Input variable to map column INCREASE_ID
   \param [in] map_probability_nm               Input variable to map column PROBABILITY_NM
   \param [in] map_increase_rt                  Input variable to map column INCREASE_RT
   \param [in] out_train_nm                     Output training cas table name
   \param [in] out_rate_inc_nm                  Output rate increase table name

   \details Data Preparation for Renewal Optimization
*/
%macro pcpr_renewal_opt_data_prep(cas_session_nm =
                                 ,caslib_nm =
                                 ,in_train_nm =
                                 ,in_rate_inc_nm =
                                 ,map_record_id = RECORD_ID
                                 ,map_previous_premium_amt = PREVIOUS_PREMIUM_AMT
                                 ,map_increase_id = INCREASE_ID
                                 ,map_probability_nm = PROBABILITY_NM
                                 ,map_increase_rt = INCREASE_RT
                                 ,out_train_nm =
                                 ,out_rate_inc_nm =);

   /*Checks*/
   /*1.1 check if the out_train_nm is not the same as the in_train_nm, otherwise output error message*/
   %if (&in_train_nm. eq &out_train_nm.) or (&in_rate_inc_nm. eq &out_train_nm.) or (&in_train_nm. eq &out_rate_inc_nm.) or (&in_rate_inc_nm. eq &out_rate_inc_nm.) %then %do;
       %put ERROR: Please use a different cas table name for the input and output tables;
       %abort;
   %end;
   /*1.2 check if the output training table or output rate increase table is already exist and promoted, if so, delete it. Otherwise it may cause error in promotion*/
   %pcpr_drop_promoted_table(caslib_nm=&caslib_nm.,table_nm=&out_train_nm.,CAS_SESSION_NAME=&cas_session_nm.)

   %pcpr_drop_promoted_table(caslib_nm=&caslib_nm.,table_nm=&out_rate_inc_nm.,CAS_SESSION_NAME=&cas_session_nm.)
   /*2.1.1 check whether column &MAP_RECORD_ID exists in training table*/
   %if %rsk_varexist(&caslib_nm..&in_train_nm.,&MAP_RECORD_ID.) eq 0 %then %do;
      %put ERROR: Column &MAP_RECORD_ID. does not exist in table &caslib_nm..&in_train_nm;
      %abort;
   %end;

   /*2.1.2 check whether column &MAP_PREVIOUS_PREMIUM_AMT exists in training table*/
   %if %rsk_varexist(&caslib_nm..&in_train_nm.,&MAP_PREVIOUS_PREMIUM_AMT.) eq 0 %then %do;
      %put ERROR: Column &MAP_PREVIOUS_PREMIUM_AMT. does not exist in table &caslib_nm..&in_train_nm;
      %abort;
   %end;

   /*2.2.1 check whether the column &MAP_INCREASE_RT exists in rate_increase table*/
   %if %rsk_varexist(&caslib_nm..&in_rate_inc_nm.,&MAP_INCREASE_RT.) eq 0 %then %do;
      %put ERROR: Column &MAP_INCREASE_RT. does not exist in table &caslib_nm..&in_rate_inc_nm;
      %abort;
   %end;

   /*2.2.1 check whether the column &MAP_INCREASE_ID exists in rate_increase table*/
   %if %rsk_varexist(&caslib_nm..&in_rate_inc_nm.,&MAP_INCREASE_ID.) eq 0 %then %do;
      %put ERROR: Column &MAP_INCREASE_ID. does not exist in table &caslib_nm..&in_rate_inc_nm;
      %abort;
   %end;

   /*2.3 check whether contents in in_rate_inc_ds.probability_nm exist in table in_train_ds*/
   %if %rsk_varexist(&caslib_nm..&in_rate_inc_nm.,&MAP_PROBABILITY_NM.) eq 0 %then %do;
      %put ERROR: Column &MAP_PROBABILITY_NM. does not exist in table &caslib_nm..&in_rate_inc_nm;
      %abort;
   %end;
   %local probability_nm_list;
   %let probability_nm_list = ;
   data rate_table;
      set &caslib_nm..&in_rate_inc_nm.;
   run;
   data _null_;
        set rate_table end=last;
        length probability_nm_list varchar(*);
        retain probability_nm_list;
        if _N_ = 0 then probability_nm_list='';
        probability_nm_list = catx(" ", probability_nm_list, &MAP_PROBABILITY_NM.);
        if last then do;
           call symputx('probability_nm_list',probability_nm_list);
        end;
   run;

   %do j = 1 %to %sysfunc(countw(&probability_nm_list., %str( )));
       %let var_nm = %scan(&probability_nm_list.,&j.,%str( ));
       %if %rsk_varexist(&caslib_nm..&in_train_nm.,&var_nm) eq 0 %then %do;
          %put ERROR: Column &var_nm does not exist in table &caslib_nm..&in_train_nm;
          %abort;
       %end;
   %end;

   /*3. Check whether RECORD_ID is unique and renewal_probability_*** columns and increase_rt are numeric*/

   /*Generate sas code table to be used to get desired profile data*/
   data &caslib_nm.._code;
      length modelName varchar(128) dataStepSrc varchar(*);
      modelName   = "DATA step";
      dataStepSrc = "length description $32;
                     if rowID eq 1000 then do;  DESCRIPTION='Column_Name';  VALUE = UPCASE(CHARVALUE);output;end;
                     if rowID eq 1003 then do;  DESCRIPTION='Data_Type'; VALUE = CHARVALUE; output; end;
                     if rowID eq 1040 then do;  DESCRIPTION='Null_Percent'; VALUE = put(DOUBLEVALUE,best.);output;end;
                     if rowID eq 1041 then do;  DESCRIPTION='Unique_Percent'; VALUE = put(DOUBLEVALUE,best.); output; end;";
   run;
   data &caslib_nm.._code_inc;
      length modelName varchar(128) dataStepSrc varchar(*);
      modelName   = "DATA step";
      dataStepSrc = "length description $32;
                     if rowID eq 1000 then do;  DESCRIPTION='Column_Name';  VALUE = UPCASE(CHARVALUE);output;end;
                     if rowID eq 1040 then do;  DESCRIPTION='Null_Percent'; VALUE = put(DOUBLEVALUE,best.);output;end;
                     if rowID eq 1003 then do;  DESCRIPTION='Data_Type'; VALUE = CHARVALUE; output; end;";
   run;
   %let probability_nm_list_comma = %rsk_quote_list(list=%str(&probability_nm_list.));
   proc cas;
      /*get profile of the training table*/
      dataDiscovery.profile result= r   /
         table=
            {caslib="&caslib_nm.", name="&in_train_nm."},
         columns=
            {"&MAP_RECORD_ID.","&MAP_PREVIOUS_PREMIUM_AMT.",&probability_nm_list_comma.},
         casout =
            {caslib="&caslib_nm.", name="trainprofile", replace = true};
      run;

      dataStep.runCodetable /
         codeTable=
            {caslib="&caslib_nm.",name="_code"},
         casout=
            {caslib="&caslib_nm.",name="_trainprofile"},
         dropvars={"count charvalue doublevalue"},
         table=
            {caslib="&caslib_nm.",name="trainprofile"}
         ;
      run;

      transpose.transpose
         table ={ groupBy = {"ColumnId"}, name="_trainprofile" caslib="&caslib_nm."},
         casout = {replace=1, name="trainprofile_trans" caslib="&caslib_nm."},
         id = {"DESCRIPTION"},
         transpose = {"VALUE"};

      table.fetch result=ci /
          to=1000,
          table =
              {name="trainprofile_trans", caslib="&caslib_nm."};
       run;
       do row over ci.fetch;
          if strip(upcase(row.column_name)) = %rsk_quote_list(list=%str(&MAP_RECORD_ID.)) then do;
             if put(row.Unique_Percent,best.) ne 100 then print(ERROR) "Identifier column &MAP_RECORD_ID. is not unique.";
             if put(row.Null_Percent,best.) > 0 then print(WARN) "Some of the observations has missing &MAP_RECORD_ID..";
          end;
          else do;
             if strip(upcase(row.column_name)) = %rsk_quote_list(list=%str(&MAP_PREVIOUS_PREMIUM_AMT)) then do;
                if strip(upcase(row.Data_Type)) ne 'DOUBLEVALUE' then print(ERROR) "Column " || strip(row.column_name) || " is not numeric, it shall be numeric, othereise it will cause error running pricing optimization node.";
             end;
             else do;
                if strip(upcase(row.Data_Type)) ne 'DOUBLEVALUE' then print(ERROR) "Column " || strip(row.column_name) || " is not numeric, it shall be numeric.";
                if put(row.Null_Percent,best.) > 0 then print(WARN) "Some of the observations has missing " || strip(row.column_name) || ".";
             end;
          end;
       end;

       /*Check whether increase_rt is numeric*/
      /*get profile of the training table*/
      dataDiscovery.profile result= r   /
         table=
            {caslib="&caslib_nm.", name="&in_rate_inc_nm."},
         columns=
            {"&MAP_INCREASE_RT."},
         casout =
            {caslib="&caslib_nm.", name="trprofile_inc", replace = true};
      run;

      dataStep.runCodetable /
         codeTable=
            {caslib="&caslib_nm.",name="_code_inc"},
         casout=
            {caslib="&caslib_nm.",name="_trprofile_inc"},
         dropvars={"count charvalue doublevalue"},
         table=
            {caslib="&caslib_nm.",name="trprofile_inc"}
         ;
      run;

      transpose.transpose
         table ={ groupBy = {"ColumnId"}, name="_trprofile_inc" caslib="&caslib_nm."},
         casout = {replace=1, name="_trprofile_inc_tr" caslib="&caslib_nm."},
         id = {"DESCRIPTION"},
         transpose = {"VALUE"};

      table.fetch result=ci /
          to=1000,
          table =
              {name="_trprofile_inc_tr", caslib="&caslib_nm."};
       run;
       do row over ci.fetch;
          if strip(upcase(row.column_name)) = %rsk_quote_list(list=%str(&MAP_INCREASE_RT.)) then do;
             if strip(upcase(row.Data_Type)) ne 'DOUBLEVALUE' then print(ERROR) "Column " || strip(row.column_name) || " is not numeric, it shall be numeric.";
             if put(row.Null_Percent,best.) > 0 then print(WARN) "Some of the observations has missing " || strip(row.column_name) || ".";
          end;
       end;
       run;
   quit;

   /*Generate output training table*/
   data &caslib_nm..&out_train_nm.;
      set &caslib_nm..&in_train_nm.;
      %if %rsk_varexist(&caslib_nm..&in_train_nm.,RECORD_ID) and %upcase(&MAP_RECORD_ID.) ne RECORD_ID %THEN %DO;
         DROP RECORD_ID;
      %END;
      %if %rsk_varexist(&caslib_nm..&in_train_nm.,PREVIOUS_PREMIUM_AMT) and %upcase(&MAP_PREVIOUS_PREMIUM_AMT.) ne PREVIOUS_PREMIUM_AMT %THEN %DO;
         DROP PREVIOUS_PREMIUM_AMT;
      %END;
      RENAME &MAP_RECORD_ID.=RECORD_ID  &MAP_PREVIOUS_PREMIUM_AMT.=PREVIOUS_PREMIUM_AMT;
      length new_premium_amt 8;
      new_premium_amt=0;
   run;

   /*Generate output rate increase table*/
   data &caslib_nm..&out_rate_inc_nm.;
      set &caslib_nm..&in_rate_inc_nm.;
      %if %rsk_varexist(&caslib_nm..&in_rate_inc_nm.,PROBABILITY_NM) and  %upcase(&MAP_PROBABILITY_NM.) ne PROBABILITY_NM %then %do;
         DROP PROBABILITY_NM;
      %end;
      %if %rsk_varexist(&caslib_nm..&in_rate_inc_nm.,INCREASE_ID) and  %upcase(&MAP_INCREASE_ID.) ne INCREASE_ID %then %do;
         DROP INCREASE_ID;
         %end;
      %if %rsk_varexist(&caslib_nm..&in_rate_inc_nm.,INCREASE_RT) and  %upcase(&MAP_INCREASE_RT.) ne INCREASE_RT %then %do;
         DROP INCREASE_RT;
      %end;
      RENAME &MAP_INCREASE_ID. = INCREASE_ID  &MAP_PROBABILITY_NM. = PROBABILITY_NM  &MAP_INCREASE_RT.= INCREASE_RT;
   run;

   %pcpr_promote_table_to_cas(input_caslib_nm =&caslib_nm,input_table_nm =&out_train_nm,output_caslib_nm =&caslib_nm,output_table_nm =&out_train_nm);
   %pcpr_save_table_to_cas(in_caslib_nm=&caslib_nm., in_table_nm=&out_train_nm.,out_caslib_nm=&caslib_nm., out_table_nm=&out_train_nm., cas_session_name=&cas_session_nm.);

   %pcpr_promote_table_to_cas(input_caslib_nm =&caslib_nm,input_table_nm =&out_rate_inc_nm,output_caslib_nm =&caslib_nm,output_table_nm =&out_rate_inc_nm);
   %pcpr_save_table_to_cas(in_caslib_nm=&caslib_nm., in_table_nm=&out_rate_inc_nm.,out_caslib_nm=&caslib_nm., out_table_nm=&out_rate_inc_nm., cas_session_name=&cas_session_nm.);

%mend;
