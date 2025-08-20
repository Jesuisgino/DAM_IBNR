/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
      \anchor pcpr_write_to_audit_trail_table
      \brief  Creates or updates audit log table in the provided cas library

   \param [in] cas_session_name         Current cas session name
   \param [in] cas_lib                   Caslib where audit table should reside
      \param [in] cycle_id                    Object ID of the cycle
      \param [in] data_table_input_names      Space separated list of input table names
      \param [in] data_table_output_names     Space separated list of output table names. To each an input table must be provided.
   \param [in] analysis_run_creation_time  Creation time of analysis run
      \param [in] user_task                 Current claimed task in cycle
    \param [in] user_name                 Current user modifier of the cycle


      \details Creates or updates audit log table <cycle_id>_audit at provided caslib storing tables created in the cycle, by which user, at what time and specific task

      An example macro invocation is as follows:

      %let cycle_id = cdtest_a;
      %let output_table_names = AUTO_TPL_12312021_Q_FREQ_MDL_1 AUTOTPL12312021QFREQBKT_1 AUTOTPL12312021QFREQBKT_2 AUTO_TPL_12312021_Q_SEV_MDL_1 AUTOTPL12312021QSEVBKT_1 AUTOTPL12312021QSEVBKT_2;
      %let input_table_names = AUTO_TPL_12312021_Q_FREQ AUTO_TPL_12312021_Q_FREQ AUTO_TPL_12312021_Q_FREQ AUTO_TPL_12312021_Q_SEV AUTO_TPL_12312021_Q_SEV AUTO_TPL_12312021_Q_SEV ;
      %let analysis_run_creation_time = 2023-03-23T19:43:20.52Z;
      %let user_task = some task;
        %let user_name = sasadm;

      %pcpr_write_to_audit_trail_table(cas_session_name=CASAUTO
                   , cas_lib=PCPRFM
                   , cycle_id=&cycle_id.
                   , data_table_output_names=&output_table_names.
                   , data_table_input_names=&input_table_names.
                   , analysis_run_creation_time=&analysis_run_creation_time.
                   , user_task=&user_task.
                        , user_name=&user_name.);


   \ingroup
      \author  SAS Institute Inc.
      \date    2023
*/
%macro pcpr_write_to_audit_trail_table(cas_session_name=
                           , cas_lib=
                                    , cycle_id=
                                    , data_table_input_names=
                                    , data_table_output_names=
                                    , analysis_run_creation_time=
                                    , user_task=
                                    , user_name=);

   /* Validate cas_session_name is OK; if not, exit */
   %if (%sysevalf(%superq(cas_session_name) eq, boolean)) %then
   %do;
      %put ERROR: Parameter cas_session_name is required.;
      %abort;
   %end;


   /* Validate cas_lib is OK; if not, exit */
    %if (%sysevalf(%superq(cas_lib) eq, boolean)) %then
    %do;
        %put ERROR: Parameter cas_lib is required.;
        %abort;
    %end;

    /* Validate cycle_id is OK; if not, exit */
    %if (%sysevalf(%superq(cycle_id) eq, boolean)) %then
    %do;
        %put ERROR: Parameter cycle_id is required.;
        %abort;
    %end;

    /* Validate user_task is OK; if not, exit */
    %if (%sysevalf(%superq(user_task) eq, boolean)) %then
    %do;
        %put ERROR: Parameter user_task is required.;
        %abort;
    %end;

    /* Validate user_name is OK; if not, exit */
    %if (%sysevalf(%superq(user_name) eq, boolean)) %then
    %do;
        %put ERROR: Parameter user_name is required.;
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

    /* Validate data tables length is the same meaning that to each input table corresponds an output table; if not, exit */
    %let input_tables = %superq(data_table_input_names);

    %let output_tables_no_dup =;
    %pcpr_remove_dups_from_list(str_list=%superq(data_table_output_names), str_set_out=output_tables_no_dup);
   %let output_tables = %sysfunc(tranwrd(%nrbquote(&output_tables_no_dup.),%str(, ),%str( )));

    %let input_tables_count = %sysfunc(countw(&input_tables.,%str( )));
    %let output_tables_count = %sysfunc(countw(&output_tables.,%str( )));
    %if (%eval(&input_tables_count. eq &output_tables_count.) eq 0) %then
        %do;
            /* Handle case where there's only one provided input table. We assume it's the only input table. */
            %if &input_tables_count. eq 1 %then
            %do;
               %do i=1 %to %eval(&output_tables_count.-1);
                  %let input_tables = %sysfunc(catx(%str( ), &input_tables., %superq(data_table_input_names)));
               %end;
            %end;
            /* Handle case where there's only one provided output table. We assume it's the only output table. */
            %else %if &output_tables_count. eq 1 %then
                %do;
                    %do i=1 %to %eval(&input_tables_count.-1);
                        %let output_tables = %sysfunc(catx(%str( ), &output_tables., &output_tables_no_dup.));
                    %end;
                    %let output_tables_count=%sysfunc(max(&input_tables_count.,&output_tables_count.));
                %end;
         %else
            %do;
                     %let output_tables_count=%sysfunc(max(&input_tables_count.,&output_tables_count.));
            %end;
        %end;


    %let default_str = no value provided;
    %let final_table_name = %upcase(%sysfunc(catx(%str(_), %superq(cycle_id), %str(audit))));
    %let final_creation_date_str =;

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

    /* Check if audit table already exists in caslib */
    %rsk_dsexist_cas(cas_lib=%superq(cas_lib), cas_table=&final_table_name.);

    /* If table does not exist we create it */
    %if &cas_table_exists. eq 0 %then
        %do;
            /* NOTE: We are creating it in work directory then moving it to cas_lib because otherwise we are not able to update it */
            proc sql ;
                create table &final_table_name. (cycle_id char(32), input_table_name char(128), output_table_name char(32), user_task char(128), user_name char(128), analysis_run_creation_time char(128));

                %do i=1 %to &output_tables_count.;
                    %let input_table = %scan(&input_tables,&i," ");
                    %let output_table = %scan(&output_tables,&i," ");

                    insert into &final_table_name. values ("%superq(cycle_id)", "&input_table.", "&output_table.", "%superq(user_task)", "%superq(user_name)", "%superq(final_creation_date_str)");

                %end;
            quit;

            data &cas_lib..&final_table_name.;
                set work.&final_table_name.;
            run;

            %pcpr_drop_promoted_table(caslib_nm=&cas_lib.,table_nm=&final_table_name.,CAS_SESSION_NAME=%superq(cas_session_name));
            %pcpr_promote_table_to_cas(input_caslib_nm =&cas_lib.,input_table_nm =&final_table_name.,output_caslib_nm =&cas_lib.,output_table_nm =&final_table_name. ,cas_session_name=%superq(cas_session_name),drop_sess_scope_tbl_flg=N);
            %pcpr_save_table_to_cas(in_caslib_nm=&cas_lib., in_table_nm=&final_table_name., out_caslib_nm=&cas_lib., out_table_nm=&final_table_name., cas_session_name=%superq(cas_session_name), replace_flg=true);
        %end;
    /* If table exists we update it */
    %else
        %do;
            data &cas_lib..&final_table_name._tmp;
                set &cas_lib..&final_table_name.;
            run;
                %do i=1 %to &output_tables_count.;
                    %let input_table = %scan(&input_tables.,&i.," ");
                    %let output_table = %scan(&output_tables.,&i.," ");
                    proc cas;
                        datastep.runCode /
                        code =  "data &cas_lib..&final_table_name._tmp;
                        set &cas_lib..&final_table_name._tmp end=eof;
                            output;
                            if eof then do;
                                cycle_id='%superq(cycle_id)';
                                input_table_name='&input_table.';
                                output_table_name='&output_table.';
                                user_task='%superq(user_task)';
                                user_name='%superq(user_name)';
                                analysis_run_creation_time= '%superq(final_creation_date_str)';
                                output;
                            end;
                        run;" ;
                    run;
                %end;

            %pcpr_drop_promoted_table(caslib_nm=&cas_lib.,table_nm=&final_table_name.,CAS_SESSION_NAME=%superq(cas_session_name));
            %pcpr_promote_table_to_cas(input_caslib_nm =&cas_lib.,input_table_nm =&final_table_name._tmp,output_caslib_nm =&cas_lib.,output_table_nm =&final_table_name. ,cas_session_name=%superq(cas_session_name),drop_sess_scope_tbl_flg=N);
            %pcpr_save_table_to_cas(in_caslib_nm=&cas_lib., in_table_nm=&final_table_name._tmp, out_caslib_nm=&cas_lib., out_table_nm=&final_table_name., cas_session_name=%superq(cas_session_name), replace_flg=true);
        %end;

%mend pcpr_write_to_audit_trail_table;
