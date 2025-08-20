/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
      \anchor pcpr_create_audit_trail_file
      \brief  Creates audit log file at provided folder path

      \param [in] folder_path               Full path to folder where audit log file should reside
      \param [in] cycle_id                    Object ID of the cycle
      \param [in] content_folder_version      Content folder version (or cadence folder) under /PC Pricing Content
      \param [in] data_table_input_names      Space separated list of input table names
      \param [in] data_table_output_names     Space separated list of output table names
   \param [in] analysis_run_creation_time  Creation time of analysis run
      \param [in] user_task                 Current claimed task in cycle

      \details Creates audit log file at provided folder path with file name user_task_mmddyy_hhmmss.txt

      An example macro invocation is as follows:

      %let cycle_id = cdtest_a;
      %let cadence = pcpricing.2023.03;
      %let output_table_names = AUTO_TPL_12312021_Q_FREQ_MDL_1 AUTOTPL12312021QFREQBKT_1 AUTOTPL12312021QFREQBKT_2 AUTO_TPL_12312021_Q_SEV_MDL_1 AUTOTPL12312021QSEVBKT_1 AUTOTPL12312021QSEVBKT_2;
      %let input_table_names = AUTO_TPL_12312021_Q_FREQ AUTO_TPL_12312021_Q_FREQ AUTO_TPL_12312021_Q_FREQ AUTO_TPL_12312021_Q_SEV AUTO_TPL_12312021_Q_SEV AUTO_TPL_12312021_Q_SEV ;
      %let analysis_run_creation_time = 2023-03-23T19:43:20.52Z;
      %let user_task = some task;

      %pcpr_create_audit_trail_file(folder_path=/Products/SAS Dynamic Actuarial Modeling/&cadence./audit_trail/&cycle_id.
                   , cycle_id=&cycle_id.
                   , content_folder_version=&cadence.
                   , data_table_output_names=&output_table_names.
                   , data_table_input_names=&input_table_names.
                   , analysis_run_creation_time=&analysis_run_creation_time.
                   , user_task=&user_task.);

   Warning: ensure that the table names passed to the "data_table_input_names" and "data_table_output_names" parameters do not contain spaces within them.

   \ingroup
      \author  SAS Institute Inc.
      \date    2023
*/
%macro pcpr_create_audit_trail_file(folder_path=
              , cycle_id=
              , content_folder_version=
              , data_table_input_names=
              , data_table_output_names=
              , analysis_run_creation_time=
              , user_task=);

   /* Validate folder_path is OK; if not, exit */
   %if (%sysevalf(%superq(folder_path) eq, boolean)) %then
   %do;
      %put ERROR: Parameter folder_path is required.;
      %abort;
   %end;

   /* Validate cycle_id is OK; if not, exit */
   %if (%sysevalf(%superq(cycle_id) eq, boolean)) %then
   %do;
      %put ERROR: Parameter cycle_id is required.;
      %abort;
   %end;

   /* Validate content_folder_version is OK; if not, exit */
   %if (%sysevalf(%superq(content_folder_version) eq, boolean)) %then
   %do;
      %put ERROR: Parameter content_folder_version is required.;
      %abort;
   %end;

   /* Validate user_task is OK; if not, exit */
   %if (%sysevalf(%superq(user_task) eq, boolean)) %then
   %do;
      %put ERROR: Parameter user_task is required.;
      %abort;
   %end;

   /* Validate data_table_input_names is OK; if not, set default value */
   %if (%sysevalf(%superq(data_table_input_names) eq, boolean)) %then
   %do;
      %put WARNING: Parameter data_table_input_names is empty. Setting it to a default value: no value provided.;
      %let data_table_input_names = no value provided;
   %end;

   /* Validate data_table_output_names is OK; if not, set default value */
   %if (%sysevalf(%superq(data_table_output_names) eq, boolean)) %then
   %do;
      %put WARNING: Parameter data_table_output_names is empty. Setting it to a default value: no value provided.;
      %let data_table_output_names = no value provided;
   %end;

   /* Validate analysis_run_creation_time is OK; if not, set default value */
   %if (%sysevalf(%superq(analysis_run_creation_time) eq, boolean)) %then
   %do;
      %put WARNING: Parameter analysis_run_creation_time is empty. Setting it to a default value: no value provided.;
      %let analysis_run_creation_time = no value provided;
   %end;

   %let input_tables =;
   %let output_tables =;
   %let newline_char = "0A"x;
   %let default_str = no value provided;
   %let final_file_name =;
   %let final_creation_date_str =;

   %pcpr_remove_dups_from_list(str_list=&data_table_input_names., str_set_out=input_tables);
   %pcpr_remove_dups_from_list(str_list=&data_table_output_names., str_set_out=output_tables);

   /* Prepare final file name */
   proc format;
      picture datefmt (default=32) other='%0m%0d%y_%0H%0M%0S' (datatype=datetime);
   run;

   data _null_;
      file_name=lowcase(tranwrd("&user_task.", " ", "_"));
      file_ext="txt";
      file_date=put(datetime(), datefmt.);
      _final_file_name=cats(file_name, "_", file_date, ".", file_ext);
      call symputx('final_file_name', _final_file_name, "L");
   run;

   /* Prepare final creation date str */
   %if "&analysis_run_creation_time." ^= "&default_str." %then
      %do;
         data _null_;
            yymmdd=scan("&analysis_run_creation_time.", 1, "T");
            hhmmss=scan("&analysis_run_creation_time.", -1, "T");
            hhmmss=scan(hhmmss, 1, ".");
            new_date_str=cat(strip(yymmdd), " ", strip(hhmmss));
            call symputx("final_creation_date_str", new_date_str, "L");
         run;
      %end;
   %else %if "&analysis_run_creation_time." = "&default_str." %then
      %do;
         data _null_;
            new_date_str="&default_str.";
            call symputx("final_creation_date_str", new_date_str, "L");
         run;
      %end;

   /* Create table that holds modified audit trail content */
   data audit_file_content;
      length cycle_id_key $16 cycle_id_value $32 content_folder_key $32
         content_folder_value $32 user_task_key $16 user_task_value $32
         input_table_key $32 input_table_value $512 output_table_key $32
         output_table_value $512 analysis_time_key $32 analysis_time_value $32;

      cycle_id_key=cats("Cycle ID:", &newline_char.);
      cycle_id_value=cats("&cycle_id.", repeat(&newline_char., 1));
      content_folder_key=cats("Content folder version:", &newline_char.);
      content_folder_value=cats("&content_folder_version.", repeat(&newline_char., 1));

      user_task_key=cats("User task:", &newline_char.);
      user_task_value=cats(tranwrd("&user_task.", "_", " "), repeat(&newline_char., 1));
      input_table_key=cats("Data table input names:", &newline_char.);
      input_table_value=cats("&input_tables.", repeat(&newline_char., 1));

      output_table_key=cats("Data table output names:", &newline_char.);
      output_table_value=cats("&output_tables.", repeat(&newline_char., 1));
      analysis_time_key=cats("Analysis run creation time:", &newline_char.);
      analysis_time_value=cats("&final_creation_date_str.", repeat(&newline_char., 1));
   run;

   /* Create audit trail file at given path */
   filename audit filesrvc
      folderPath="&folder_path." filename=%lowcase("&final_file_name.") debug=http;

   /* Concat & write audit trail content to audit trail path file */
   data _null_;
      length result_content $2048.;
      set audit_file_content;
      file audit;
      result_content=cat(strip(cycle_id_key)
             , trim((trim(" ") || cycle_id_value))
             , strip(content_folder_key)
             , trim((trim(" ") || content_folder_value))
             , strip(user_task_key)
             , trim((trim(" ") || user_task_value))
             , strip(input_table_key)
             , trim((trim(" ") || input_table_value))
             , strip(output_table_key)
             , trim((trim(" ") || output_table_value))
             , strip(analysis_time_key)
             , trim((trim(" ") || analysis_time_value)));
      put result_content;
   run;

%mend pcpr_create_audit_trail_file;
