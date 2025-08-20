%macro pcpr_check_library_exist(libref=,out_var=libref_exists);

    /* out_var cannot be missing. Set a default value */
    %if(%sysevalf(%superq(out_var)=, boolean)) %then %let out_var=libref_exists;

    /* Declare the output variable as global if it does not exist */
    %if(not %symexist(&out_var.)) %then %global &out_var.;

    %let &out_var.=0;

    %if (%sysfunc(libref(sashelp))=0) %then %let &out_var.=1;

%mend;
