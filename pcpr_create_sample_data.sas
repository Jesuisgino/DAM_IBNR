/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
   \anchor pcpr_create_sample_data
   \brief   Create sample data for pc pricing

   \param [in] ddl_path                       Path to the ddl folder
   \param [in] sample_data_path               Path to the sampledata folder
   \param [in] caslib_stg                     Cas library that sample data will be generated to
   \param [in] table_list                     The list of tables that will be generated as sample data
   \param [in] load_csv_flg                   Flag if csv data files will be loaded into sample data
   \param [in] csv_table_list                 The list of csv tables that will be uploaded as sample data

   \details Create sample data

   An example macro invocation is as follows:

        %pcpr_create_sample_data(
             ddl_path = <ddl_path>
            ,sample_data_path=<sampledata_path>
            );

   \ingroup Installation
   \author  SAS Institute Inc.
   \date    2022
*/

%macro pcpr_create_sample_data(ddl_path=&m_pc_insurance_ddl_path.
                              , sample_data_path=&m_pc_insurance_sampledata_path.
                              , caslib_stg=
                              , table_list=
                              , load_csv_flg=
                              , csv_table_list=
                              ) / minoperator;

   /*If not specified, use public caslib*/
   %local caslib_stg_nm;
   %if %length(&caslib_stg) ^=0 %then %do;
       %let caslib_stg_nm=&caslib_stg;
   %end;
   %else %do;
       %let caslib_stg_nm=public;
   %end;

   %local table_list_nm csv_table_list_nm;
   %let table_list_nm=&table_list;
   %let csv_table_list_nm=&csv_table_list;

      /* Initialize the environment */
      %core_cas_initiate_session(cas_session_name = load_sampledata
                        , cas_session_options = %bquote(caslib=public)
                        , cas_assign_librefs = Y);

      /* Generate ddl in the work library */
      %pcpr_gen_ddl(tgt_lib=public, dir=&m_pc_insurance_ddl_path., table_list=&table_list_nm.);

      /* Generate sample data and load to cas library */
      %pcpr_gen_sample_data(tgt_lib=public, caslib=&caslib_stg_nm., dir=&m_pc_insurance_sampledata_path., table_list=&table_list_nm.);

      /* Upload csv data files into cas library */
      %if %upcase(&load_csv_flg)=Y %then %do;
          options validvarname=any casdatalimit=200M;
          %pcpr_load_csv_sample_data(tgt_lib=public, caslib=&caslib_stg_nm., dir=&m_pc_insurance_sampledata_path., csv_table_list=&csv_table_list_nm.);
      %end;

      /*Terminate the enviroment*/
      %core_cas_terminate_session(cas_session_name = load_sampledata);

   %EXIT:

%mend pcpr_create_sample_data;
