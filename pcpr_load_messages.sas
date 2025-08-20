%macro pcpr_load_messages(source_dir=,file_name=);

    %let exist_flag=0;
    %let file_list=;
    %let locale_list=;
    /* source_dir cannot be missing. Set a default value */
    %if(%sysevalf(%superq(source_dir)=, boolean)) %then %do;
        %let sol_path=;
        %pcpr_get_code_lib_path(cycle_code_lib_paths=&CYCLE_CODE_LIB_PATHS.,out_sol_path=&sol_path.); /* This is a global macro assigned in the script with a parser function */
        %let source_dir=&sol_path./sas/smd;
    %end;

    /* file_name cannot be missing. Set a default value */
    %if(%sysevalf(%superq(file_name)=, boolean)) %then %let
        file_name=pcpricingutilmsg;

    /* Check the message file table exists */
    %if (%sysfunc(exist(&file_name.))=0) %then %do;
        /* Get file names into the smd folder to use when we extract the available locales */
        %pcpr_get_file_names(folderpath=&source_dir.,out_var=&file_list.);
        /* Extract the locale from the file names*/
        %pcpr_extract_locale(file_list=&file_list.,ext=.smd,out_var=&locale_list.);
		/* Load the messages for the selected locales */
        %smd2ds(dir=&source_dir.,basename=&file_name.,locale=&locale_list.);
    %end;

    %if %sysfunc(exist(&file_name.))=1 %then %let exist_flag=1;

%mend;
