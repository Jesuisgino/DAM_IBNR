/*
 Copyright (C) 2024-2025 SAS Institute Inc. Cary, NC, USA
*/
%macro save_data(dataname);
   proc cas;
      table.save /
      table={caslib="&caslib.",name="%upcase(&dataname.)"} name="%lowcase(&dataname.).sashdat" replace=True;
   run;
%mend;
