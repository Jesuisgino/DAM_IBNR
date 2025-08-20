/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file    pcpr_init_insurance_solution
   \anchor
   \brief   This macro initializes the PC PRICING content environment and the following two tasks are performed:
            (1) Create message files
            (2) Compile macros based on Insurance solution macro path
   Note: sasauto is not used in this case

   \ingroup development

   \param [in] source_path Path to the root folder of the source code not including 'source' folder
   \param [in] version version name of the solution, this is the level of "source" if use repo code


   \details

   <b>Example:</b>


   \code
      %let source_path = <Path to the root folder of the source code>;
      %let version_nm =v07.2022
      %include "&source_path./source/Insurance Solution/macros/pcpr_init_insurance_solution.sas";
      %pcpr_init_insurance_solution(
                  source_path = &source_path.
                 ,version = &version_nm.
                 );
   \endcode

   \author  SAS Institute Inc.
   \date    2022
*/

%macro pcpr_init_insurance_solution(source_path =&m_cr_version_folder_path/&m_cr_insur_solution_folder_nm.);

   /********************************************************/
   /*  Set macro variables of file locations               */
   /********************************************************/
   %global m_pc_insurance_ddl_path
           m_pc_insurance_sampledata_path
           m_pc_insurance_macro_path;
   %let m_pc_insurance_ddl_path = &source_path./ddl;
   %let m_pc_insurance_sampledata_path = &source_path./sampledata;
   %let m_pc_insurance_macro_path = &source_path./spre/sas/ucmacros;

   /********************************************************/
   /*  Define compile insurance content macros utility     */
   /********************************************************/
   %macro pcpr_compile_macro(m_macro_cd_nm=);

      %let m_macro_cd_nm = &m_macro_cd_nm.;

      filename macr_cd filesrvc folderpath="&m_pc_insurance_macro_path./" filename= "&m_macro_cd_nm" debug=http; /* i18nOK:Line */

      %if "&_FILESRVC_macr_cd_URI" eq "" %then %do;
         /* %let job_rc = 1012; */
      /*   %put %sysfunc(sasmsg(work.PCPR_MESSAGE_DETAIL, PCPR_SOLUTION_MSG.INIT_CODE1.1, noquote,&m_macro_cd_nm.,&m_pc_insurance_macro_path.));*/
      %end;

      %else %do;
         %include macr_cd / lrecl=64000; /* i18nOK:Line */
      %end;

      filename macr_cd clear;

   %mend pcpr_compile_macro;

   /********************************************************/
   /*  Compile insurance content macros                    */
   /********************************************************/
   %pcpr_compile_macro (m_macro_cd_nm=core_cas_drop_table.sas)
   %pcpr_compile_macro (m_macro_cd_nm=core_cas_initiate_session.sas)
   %pcpr_compile_macro (m_macro_cd_nm=core_cas_terminate_session.sas)
   %pcpr_compile_macro (m_macro_cd_nm=pcpr_check_table_scope.sas)
   %pcpr_compile_macro (m_macro_cd_nm=pcpr_drop_promoted_table.sas)
   %pcpr_compile_macro (m_macro_cd_nm=lf_create_dg_cashflow.sas)
   %pcpr_compile_macro (m_macro_cd_nm=lf_create_dg_curve.sas)
   %pcpr_compile_macro (m_macro_cd_nm=lf_create_dg_disc.sas)
   %pcpr_compile_macro (m_macro_cd_nm=lf_create_dg_mortality.sas)
   %pcpr_compile_macro (m_macro_cd_nm=lf_enrich_dg_curve.sas)
   %pcpr_compile_macro (m_macro_cd_nm=pcpr_gen_sample_data.sas)
   %pcpr_compile_macro (m_macro_cd_nm=pcpr_create_sample_data.sas)
   %pcpr_compile_macro (m_macro_cd_nm=pcpr_gen_ddl.sas)
   %pcpr_compile_macro (m_macro_cd_nm=pcpr_gen_sample_data.sas)
   %pcpr_compile_macro (m_macro_cd_nm=pcpr_get_message.sas)
   %pcpr_compile_macro (m_macro_cd_nm=pcpr_load_csv_sample_data.sas)
   %pcpr_compile_macro (m_macro_cd_nm=pcpr_promote_table_to_cas.sas)
   %pcpr_compile_macro (m_macro_cd_nm=pcpr_save_table_to_cas.sas)
   %pcpr_compile_macro (m_macro_cd_nm=rsk_attrn.sas)
   %pcpr_compile_macro (m_macro_cd_nm=rsk_dsexist_cas.sas)
   %pcpr_compile_macro (m_macro_cd_nm=rsk_quote_list.sas)
   %pcpr_compile_macro (m_macro_cd_nm=rsk_wordcount.sas)
   %pcpr_compile_macro (m_macro_cd_nm=update_caslib_permissions.sas)
   %pcpr_compile_macro (m_macro_cd_nm=lf_prepare_map_config.sas)
   %pcpr_compile_macro (m_macro_cd_nm=pcpr_join_tbl_cas.sas)
   %pcpr_compile_macro (m_macro_cd_nm=pcpr_check_ds_status.sas)
   %pcpr_compile_macro (m_macro_cd_nm=pcpr_check_var_list.sas)

%mend pcpr_init_insurance_solution;
