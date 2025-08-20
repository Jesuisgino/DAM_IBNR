%macro pcpr_get_code_lib_path(cycle_code_lib_paths, out_sol_path=sol_path, out_core_path=core_path);

%if(%sysevalf(%superq(cycle_code_lib_paths)=, boolean)) %then %put ERROR: cycle_code_lib_paths parameter is required;
 /* out_sol_path and out_core_path cannot be missing. Set a default value */
   %if(%sysevalf(%superq(out_sol_path) =, boolean)) %then
      %let out_sol_path = sol_path;
    %if(%sysevalf(%superq(out_core_path) =, boolean)) %then
      %let out_core_path = core_path;

%let cycle_code_lib_paths = %sysfunc(prxchange(s/\\u0026/%nrstr(&)/, -1, %superq(cycle_code_lib_paths)));
%let cycle_code_lib_paths = %sysfunc(prxchange(s/(\s*(\[|\])\s*)|(%str(,))/ /, -1, %superq(cycle_code_lib_paths)));

/* Get the solution and Core path */
%let sol_path = %sysfunc(kcompress(%kscan(&cycle_code_lib_paths.,1,' '),'"'));
%let core_path = %sysfunc(compress(%scan(&cycle_code_lib_paths.,2,' '),'"'));
%mend;
