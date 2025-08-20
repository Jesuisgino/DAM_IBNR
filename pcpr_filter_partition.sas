/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
   \anchor  pcpr_filter_partition
   \brief   This macro is used to create modeling, backtesting, and/or business backtesting based on user specified filter conditions through generic table.
            Before calling this macro, create a configuraiton table by calling a function ${function:GetSASDSCode(Params.spreadsheet.rowState, "&generic_lib..&generic_table_name.")}
   \param [in] CONFIG_TABLE_LIB         Configuration table library
   \param [in] CONFIG_TABLE_NM          Configuration table name
   \param [in] REQUIRED_COL_LIST        List of columns required by this macro in the configuration table, space separated
   \param [in] PARTITION_TABLE_LIB      CAS library for the input and output partition tables

   \details create modeling, backtesting, and bsuiness backtsting tables by filtering input tables.
   \Note   This macro is called by filter partition script

   \ingroup Macros
   \author  SAS Institute Inc.
   \date    2023
*/

%macro pcpr_filter_partition(CONFIG_TABLE_LIB=, CONFIG_TABLE_NM=, REQUIRED_COL_LIST=, PARTITION_TABLE_LIB=);

    /*Make sure config table exist*/
    %if not %rsk_dsexist(&CONFIG_TABLE_LIB..&CONFIG_TABLE_NM.) %then %do;
        %PUT ERROR: Configuration table &CONFIG_TABLE_LIB..&CONFIG_TABLE_NM. does not exist.;
        %abort;
    %end;

    %if &REQUIRED_COL_LIST eq %then %do;
       %PUT ERROR: A list of required columns needs to be specified.;
       %abort;
    %end;

    %global SUCCESS_FLG MISSING_VAR  ;

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

      /* Define the macro to check column type */
      %macro checkColumnType(libname=, tablename=, columnname=,columninfotable=);
         proc cas;
            table.columninfo result = ci /table={caslib="&libname.",name="&tablename."};
            tableci=findtable(ci);
            saveresult tableci replace caslib="&libname." casout="ColumnInfo";
            run;

            data column_info_table(keep=lib_name table_name Column column_type);
               set &libname..ColumnInfo;
              format lib_name $32. table_name $32. Column $32. column_type $10.;
             lib_name="&libname.";
             table_name="&tablename.";
               if Column = "&columnname" then do;
                  if upcase(Type) = 'VARCHAR' then column_type="CHAR";
                  else if upcase(Type) = 'DOUBLE' then column_type="NUM";
                output;
               end;
            run;

            proc append base=&columninfotable. data=column_info_table force;
            run;

      %mend checkColumnType;
      /*Save the information to table VarInfoTable*/
      %if %sysfunc(exist(VarInfoTable)) %then %do;
         proc datasets lib=work nolist;
            delete VarInfoTable;
         quit;
         %put Table VarInfoTable has been deleted.;
      %end;
      data &CONFIG_TABLE_LIB..&CONFIG_TABLE_NM.;
         format inputTableName $32. targetFilterName $32.;
         set &CONFIG_TABLE_LIB..&CONFIG_TABLE_NM.;
         format cas_lib $32.;
         cas_lib="&PARTITION_TABLE_LIB.";
      run;

      proc sort data=&CONFIG_TABLE_LIB..&CONFIG_TABLE_NM. out=&CONFIG_TABLE_NM._KEY nodupkey;
      by cas_lib inputTableName targetFilterName;
      run;

      data _null_;
         set &CONFIG_TABLE_NM._KEY;
         call symputx('cas_lib', cas_lib);
         call symputx('cas_table', inputTableName);
         call symputx('column_name',targetFilterName);
         call execute(cats('%nrstr(%checkColumnType)(tablename=', strip(inputTableName),
                                                      ',libname=', strip(cas_lib),
                                                      ',columnname=', strip(targetFilterName),
                                                      ',columninfotable=VarInfoTable',
                                                      ');'));
      run;
      /*Merge it back to the configuration table*/
      proc sort data=&CONFIG_TABLE_LIB..&CONFIG_TABLE_NM. out=config_table_sorted;
      by cas_lib inputTableName targetFilterName;
      run;

      proc sort data=VarInfoTable;
      by lib_name table_name Column;
      run;

      data config_table_w_type;
         merge config_table_sorted(in=a) VarInfoTable(in=b rename=(lib_name=cas_lib table_name=inputTableName Column=targetFilterName));
         if a;
         by cas_lib inputTableName targetFilterName;
      run;

     /*Handle different cases for operator IN and NOT IN*/
      data config_table_w_type;
         set config_table_w_type;
         format format_targetFilterValue $128.;
         if upcase(Operator) in ("IN","NOT_IN") then do;
            if upcase(column_type)="CHAR" then do;
               do i = 1 to countw(targetFilterValue, ' ');
                  if i=1 then format_targetFilterValue=quote(scan(targetFilterValue, i, ' '));
                  else format_targetFilterValue = catx(format_targetFilterValue, ',',quote(scan(targetFilterValue, i, ' ')));
               end;
                  drop i;
               format_targetFilterValue=strip(catx('','(',format_targetFilterValue,')'));
            end;
            else do;
               do i = 1 to countw(targetFilterValue, ' ');
                  if i=1 then format_targetFilterValue=scan(targetFilterValue, i, ' ');
                  else format_targetFilterValue = catx(format_targetFilterValue, ',',scan(targetFilterValue, i, ' '));
               end;
                  drop i;
               format_targetFilterValue=strip(catx('','(',format_targetFilterValue,')'));
            end;
         end;
         else do;
            if upcase(column_type)="CHAR" then do;
               format_targetFilterValue=strip(quote(targetFilterValue));
            end;
            else do;
               format_targetFilterValue=strip(targetFilterValue);
            end;
         end;
      run;
         /*Add additional information column*/
        data config_table_w_type_new;
            set config_table_w_type;
            format filter_expression $256.;
           filter_expression=cat(strip(targetFilterName),' ', strip(tranwrd(Operator,"_"," ")),' ', strip(format_targetFilterValue));
        run;

        /*create file to run code from the configuration table*/
        filename filter filesrvc folderPath='/Products/SAS Dynamic Actuarial Modeling' filename= "filter_code.sas" debug=http lrecl = 33000;

        data _NULL_;
            length STATEMENT $2000. ;
                set config_table_w_type_new;
                file filter;
                STATEMENT =  cat('%pcpr_filter_cas_table(INCASTABLE=',strip(InputTableName),
                                                    ',INCASLIB=',strip(cas_lib),
                                                    ',OUTCASTABLE=',strip(OutputTableName),
                                                    ',OUTCASLIB=',strip(cas_lib),
                                                    ', FILTER_EXPRESSION=%str(',%bquote(trim(filter_expression)),
                                                    '));'
                                );

                put STATEMENT ;
        run;

        /*run code if code file is created sucessfully then delete it*/
        %if %sysfunc(fexist(filter)) %then %do ;
            %inc filter ;
            %let delete_file_code=%sysfunc(fdelete(filter));
        %end ;
    %end;
    %else %do;
        %PUT NOTE: There are no observations in the configuration table &CONFIG_TABLE_LIB..&config_table_nm..;
    %end;
%mend pcpr_filter_partition;
