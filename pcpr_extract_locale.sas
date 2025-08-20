/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  pcpr_extract_locale
\brief   This macro is used to extract the locale from a list of files that have the locale in the following form <FileName>_<Locale>.<Extension>

\param [in] file_list              List of files separated by blanks. E.g. file1.sas file2.sas file3.sas
\param [in] ext                    File extension. E.g. .smd, .sas, .xlsx
\param [in] out_var                Output macro variable that will store the list of locales

\details Extract the locale from a list of files that have the locale in the following form <FileName>_<Locale>.<Extension>. E.g. file1_zh_CN.smd will see an extracted locale of zh_CN.

\ingroup Macros
\author  SAS Institute Inc.
\date    2024
 */
%macro pcpr_extract_locale(file_list=,ext=,out_var=locale_list);

    /* out_var cannot be missing. Set a default value */
    %if(%sysevalf(%superq(out_var)=, boolean)) %then %let out_var=locale_list;

    /* Validate folderpath is OK; if not, exit */
    %if (%sysevalf(%superq(file_list) eq, boolean)) %then %do;
        %put ERROR: Parameter file_list is required.;
        %abort;
    %end;

    /* Validate folderpath is OK; if not, exit */
    %if (%sysevalf(%superq(ext) eq, boolean)) %then %do;
        %put ERROR: Parameter ext is required.;
        %abort;
    %end;

    %let num_files=%sysfunc(countw(&file_list, %str( )));
    %let locales=;

    %do i=1 %to &num_files;
        %let filename=%scan(&file_list, &i, %str( ));

        /* Extract the locale */
        %if %index(&filename, _) > 0 %then %do;
            %let start_pos=%eval(%index(&filename, _) + 1);
            %let end_pos=%eval(%index(&filename, &ext) - 1);
            %let locale=%substr(&filename, &start_pos, %eval(&end_pos -
                &start_pos + 1));
        %end;
        %else %do;
            %let locale=;
        %end;

        /* Append the extracted locale to the list */
        %let locales=&locales &locale;
    %end;

    /* Save the extracted locales to the output variables */
    %let &out_var=&locales.;

%mend;
