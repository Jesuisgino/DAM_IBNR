/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
   \brief   Load DDL files into a target library

   \param [in] tgt_lib Target libref where the tables will be created
   \param [in] dir Path to the ddl files
   \param [in] table_list the list of tables in the ddl directory
   \param [in] dttmfmt Format used for datetime columns (Default: NLDATM21.)
   \param [in] tmfmt Format used for time columns (Default: NLTIMAP11.)
   \param [in] dtfmt Format used for date columns (Default: DATE9.)
   \param [in] pctfmt Format used for percentage columns (Default: PERCENT12.4)
   \param [in] fmtrk Format used for retained key columns (Default: 12.)
   \param [in] fmtid Format used for id columns (Default: 12.)

   \details This macro loops through all .sas files found in the input directory {dir} and executes them.
   Each file must contain a valid SQL statement (without proc/quit statement) as follows:
      CREATE TABLE &LIBREF..\<TABLE_NAME\> (
         ...
      )
   The macro variable &LIBREF will be resolved with the value of input parameter &tgt_lib.

   \ingroup macro
   \author  SAS Institute Inc.
   \date    2022
*/
%macro pcpr_gen_ddl(tgt_lib =
                    , dir =
                    , table_list=
                    , dttmfmt = NLDATM21.
                    , tmfmt = NLTIMAP11.
                    , dtfmt = NLDATE9.
                    , pctfmt = PERCENT12.4
                    , fmtrk = 12.
                    , fmtid = 12.
                    );

   /*Directory can't be empty*/
   %if %length(&dir.)=0 %then %do;
      %return;
   %end;
   /*If table list if provided, then directly use the table list*/
   %if %length(&table_list.)^=0 %then %do;
      %local table_cnt i j l;
      %let table_cnt=%rsk_wordcount(&table_list.);
      %do i = 1 %to &table_cnt.;
            %let curr_table=%scan(&table_list.,&i);
            filename ddl_&i. filesrvc folderpath="&dir./" filename= "&curr_table..sas" debug=http;
      %end;

      %let libref = &tgt_lib.;
      proc fedsql sessref=load_sampledata ;
         /* Loop through all ddl files */
         %do j = 1 %to &table_cnt.;
            %include ddl_&j.;
         %end;
      quit;

      /*Rename ddl file into a different name so that sample data could append*/
      %do l = 1 %to &table_cnt.;
         %let curr_table=%scan(&table_list.,&l);
         data &libref.._&curr_table.;
            set &libref..&curr_table.;
         run;
      %end;
   %end;

%mend pcpr_gen_ddl;
