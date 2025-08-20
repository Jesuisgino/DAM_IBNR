/*
Copyright (C) 2024-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  es_autoexec_usermods
\brief   Macro to initialize cycle for experience study.


\details

\ingroup Macros
\author  SAS Institute Inc.
\date    2024
*/

    /**** Json Data From VA *****/
    filename vaJSON temp;

    data _null_;
        file vaJSON;
        length str $32767;
        str = resolve(symget('vaJSON'));
        put str;
    run;

    %let cycle_id = ;
    %let cycleid=;
    %let caslib=;
    %let ADJ_TYPE=;
    libname jsonlib json fileref=vaJSON;
    %if (%sysfunc(exist(jsonLib.parameters)) eq 1) or (%sysfunc(exist(jsonLib.parameters, VIEW)) eq 1) %then %do;
       data _null_;
          set jsonLib.parameters;
          call symput('cycle_id', value);
          call symput('cycleid',upcase(value));
          where upcase(label) eq "CYCLEID";
       run;
       %let cycleid=%trim(&cycle_id.);
%put &cycleid.;
       data _null_;
          set jsonLib.parameters;
          call symput('caslib',upcase(value));
          where upcase(label) eq "CASLIB";
       run;
       %let caslib=%trim(&caslib.);
%put &caslib.;
       data _null_;
          set jsonLib.parameters;
          call symput('ADJ_TYPE',upcase(value));
          where upcase(label) eq "ADJTYPE";
       run;
       %let ADJ_TYPE=%trim(&ADJ_TYPE.);
%put &ADJ_TYPE.;
    %end;

        %let jsonlib=jsonlib;
        %let es_val=&cycleid._VAL;
        %let es_parm=&cycleid._PARM;
        %let es_config=&cycleid._CONFIG;
        %let es_res=&cycleid._RST;
        %let es_var=&cycleid._VARIMP;

    options mprint symbolgen mlogic;

    options cashost="%sysfunc(getoption(cashost))" casport=5570;

    cas MySession cassessopts=(caslib=&caslib);;
        caslib _all_ assign global;
    run;
    %include resfld ('ibnr_return_job.sas') / nosource2;
    %include resfld ('es_adj_lapse_rt.sas') / nosource2;
    %include resfld ('es_remove_lapse_adj.sas') / nosource2;
