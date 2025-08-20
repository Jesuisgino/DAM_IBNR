/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
      \anchor pcpr_remove_dups_from_list
      \brief  Removes duplicates from a space-separated character list

      \param [in] str_list      Space-separated list
      \param [out] str_set_out    Holds a set of str_list

      \details Removes duplicates from a space-separated character list

      An example macro invocation is as follows:

      %let tables = table1 table2 table3 table1 table2 table3 table1;
      %let out_tables =;
      %pcpr_remove_dups_from_list(str_list=&tables., str_set_out=out_tables);
      %put &out_tables.;

      expected output of out_tables: table1, table2, table3

   \ingroup
      \author  SAS Institute Inc.
      \date    2023
*/
%macro pcpr_remove_dups_from_list(str_list=, str_set_out=);
   %if not %symexist(&str_set_out.) %then
      %do;
         %global &str_set_out.;
      %end;

   %let &str_set_out. =;
   %let set =;

   /* To ensure we set str_set_out */
   %if (%sysevalf(%superq(str_list) eq, boolean)) or "&str_list." = "no value provided" %then
      %do;
         data _null_;
            _set="no value provided";
            %put WARNING: Parameter str_list is empty. Setting str_set_out to a default value: no value provided.;
            call symput("set", _set);
         run;
         %let &str_set_out. = &set.;
         %return;
      %end;

   /* Iterate over space-separated list to create a comma-and-space-separated set */
   data _null_;
      length _set $512 name $32;
      _set=scan("&str_list.", 1, " ");
      do i=2 to countw("&str_list.", " ");
         name=scan("&str_list.", i, " ");
         found=find(tranwrd(_set, ", ", " "), name, "it");
         if found=0 then
            do;
               _set=catx(", ", _set, name);
            end;
      end;
      call symput("set", _set);
   run;

   %let &str_set_out. = &set.;

%mend pcpr_remove_dups_from_list;
