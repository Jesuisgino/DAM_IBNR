/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
   \brief   Append sample data to a target library

   \param [in] tgt_lib      Target libref where the sample data will be appended (where ddl is generated)
   \param [in] dir          Path to the sample data files
   \param [in] table_list   The list of tables in the sample data directory
   \param [in] caslib       caslib name that table will be loaded to
   \param [in] low_date     Lowest date (slowly changing dimensions)
   \param [in] high_date    Highest date (slowly changing dimensions)

   \details This macro loops through all .sas files found in the input directory {dir} or from a table list and executes them.
   Each file must create a table (named like the file) in the WORK library. The table is then appended to the target library

   \ingroup development
   \author  SAS Institute Inc.
   \date    2022
*/
%macro pcpr_gen_sample_data(tgt_lib =
                            , dir =
                            , table_list=
                            , caslib=
                            , low_date = '01JAN2000:00:00:00'dt
                            , high_date = '31DEC9999:23:59:59'dt
                            );

   /*Directory can't be empty*/
   %if %length(&dir.)=0 %then %do;
      %return;
   %end;
   %if %length(&caslib) ^=0 %then %do;
       %let caslib_nm=&caslib;
   %end;
   %else %do;
       %let caslib_nm=public;
   %end;

   %let libref = &tgt_lib.;

   %if %length(&table_list.)^=0 %then %do;
      %local table_cnt i j;
      %let i=1;
      %let j=1;
      %let table_cnt=%rsk_wordcount(&table_list.);
      %do i = 1 %to &table_cnt.;
            %let curr_table=%scan(&table_list.,&i);
            filename data_&i. filesrvc folderpath="&dir./" filename= "&curr_table..sas" debug=http;
      %end;

      /* Load sample data to work */
      %do j = 1 %to &table_cnt.;
         %let curr_table=%scan(&table_list.,&j);
         %include data_&j;

         /* Append sample data to the ddl in the target library which is renamed as _&current_table*/
         data &tgt_lib.._&curr_table.(append=force);
               set &tgt_lib..&curr_table.;
         run;

         /*Load table to cas library with original name*/
         %pcpr_promote_table_to_cas(cas_session_name=load_sampledata, input_caslib_nm =&tgt_lib.,input_table_nm =_&curr_table.,output_caslib_nm =&caslib_nm.,output_table_nm =&curr_table. ,drop_sess_scope_tbl_flg=N);
         %pcpr_save_table_to_cas(in_caslib_nm=&caslib_nm., in_table_nm=&curr_table.,out_caslib_nm=&caslib_nm., out_table_nm=&curr_table., replace_flg=true)
      %end;
   %end;

%mend pcpr_gen_sample_data;
