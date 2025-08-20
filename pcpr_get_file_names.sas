/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  pcpr_get_file_names
\brief   This macro is used to get a list of files from a provided folder path

\param [in] folderpath              A full folder path. It can be either on the file service or on the Viya server.
\param [in] out_var                 Output macro variable that will store the list of files

\details Get a list of file names from a provided folder path. The folder can be either located in the file service or on the Viya server.

\ingroup Macros
\author  SAS Institute Inc.
\date    2024
*/
%macro pcpr_get_file_names(folderpath=, out_var=file_list);

    /* out_var cannot be missing. Set a default value */
    %if(%sysevalf(%superq(out_var)=, boolean)) %then %let out_var=file_list;

    /* Validate folderpath is OK; if not, exit */
    %if (%sysevalf(%superq(folderpath) eq, boolean)) %then %do;
        %put ERROR: Parameter folderpath is required.;
        %abort;
    %end;

    /* First attempt: assign the fileref using the FILENAME function */
    %let fref=f_ref;
    %let rc=%sysfunc(filename(fref, "&folderpath."));
    /* Check if the assignment was successful */
    %if &rc ne 0 %then %do;
        /* If an error occurred (rc is not 0), use the FILESRVC method instead */
        filename f_ref filesrvc folderpath="&folderpath." debug=http;
    %end;

    /* Get the directory ID */
    data _null_;
        /* Open the directory */
        dir_id=dopen('f_ref');

        /* Initialize the macro variable */
        call symputx('file_names', '');

        /* If the directory was opened successfully */
        if dir_id > 0 then do;
            /* Get the number of files in the directory */
            num_files=dnum(dir_id);

            /* Loop over the files and retrieve their names */
            do i=1 to num_files;
                file_name=dread(dir_id, i);

                /* Concatenate the file names into a single macro variable */
                call symputx('file_names', catx(' ', symget('file_names'),
                    file_name));
            end;

            /* Close the directory */
            rc=dclose(dir_id);
        end;
        else put 'ERROR: Directory could not be opened.';

    run;

    %let &out_var.=&file_names.;

%mend;
