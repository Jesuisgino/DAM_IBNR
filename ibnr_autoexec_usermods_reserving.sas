/*
Copyright (C) 2024-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  ibnr_autoexec_usermods_reserving
\brief   Macro to initialize cycle for reserving.


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

    libname jsonlib json fileref=vaJSON;
    %if (%sysfunc(exist(jsonLib.parameters)) eq 1) or (%sysfunc(exist(jsonLib.parameters, VIEW)) eq 1) %then %do;
       data _null_;
          set jsonLib.parameters;
          call symput('cycle_id', value);
          call symput('cycleid',upcase(value));
          where upcase(label) eq "CYCLEID";
       run;
       %let cycleid=%trim(&cycle_id.);

       data _null_;
          set jsonLib.parameters;
          call symput('caslib',upcase(value));
          where upcase(label) eq "CASLIB";
       run;
       %let caslib=%trim(&caslib.);
    %end;

    %if (%sysevalf(%superq(cycle_id) =, boolean)) %then %do;
        %let jsonlib=jsonlib;
        %let TRIANGLE_DATA=IBNR_TRIANGLE_DATA;
        %let ibnr_summary=IBNR_SUMMARY;
        %let FACTOR_SUMMARY=IBNR_FACTOR_SUMMARY;
        %let Smooth_Table=Smooth_Table;
        %let complete_triangle_data=IBNR_TRIANGLE_COMPLETE;
        %let incr_triangle_data=IBNR_TRIANGLE_INCREM;
        %let projected_cf=IBNR_PROJECTED_CF;
        %let Icg_incur_todate=IBNR_ICG_INCUR_TODATE;
        %let alloc_matrix=IBNR_ALLOC_MATRIX;
        %let projected_cf_by_icg=IBNR_PROJECTED_CF_BY_ICG;
        %let Insurance_cf_lic_claims=IBNR_INSURANCE_CF_LIC_CLAIMS;
        %let Insurance_cf_lic_expenses=IBNR_INSURANCE_CF_LIC_EXPENSES;
        %let input_icg_claim=IBNR_ICG_CLAIM;
        %let input_expense_ratio=IBNR_EXPENSE_RATIO;
    %end;
    %else %do;
        %let jsonlib=jsonlib;
        %let TRIANGLE_DATA=&cycleid._TDATA;
        %let ibnr_summary=&cycleid._IBNR_S;
        %let FACTOR_SUMMARY=&cycleid._FCTSUM;
        %let Smooth_Table=&cycleid._SM_TB;
        %let complete_triangle_data=&cycleid._T_CMPL;
        %let incr_triangle_data=&cycleid._T_INCR;
        %let projected_cf=&cycleid._FCF;
        %let Icg_incur_todate=&cycleid._ICGITD;
        %let alloc_matrix=&cycleid._ALCMAT;
        %let projected_cf_by_icg=&cycleid._FCFICG;
        %let Insurance_cf_lic_claims=&cycleid._CF_LIC_CLM;
        %let Insurance_cf_lic_expenses=&cycleid._CF_LIC_EXP;
        %let input_icg_claim=&cycleid._ICG_CLAIM;
        %let input_expense_ratio=&cycleid._EXPENSE_R;
    %end;

    options mprint symbolgen mlogic;

    options cashost="%sysfunc(getoption(cashost))" casport=5570;

    cas MySession cassessopts=(caslib=&caslib);;
        caslib _all_ assign global;
    run;
    %include resfld ('rsk_attrn.sas') / nosource2;
    %include resfld ('rsk_dsexist_cas.sas') / nosource2;
    %include resfld ('ibnr_update_factory_summary.sas') / nosource2;
    %include resfld ('ibnr_save_data.sas') / nosource2;
    %include resfld ('ibnr_factor_exclude_include.sas') / nosource2;
    %include resfld ('ibnr_cash_flow.sas') / nosource2;
    %include resfld ('ibnr_reset_data.sas') / nosource2;;
    %include resfld ('ibnr_complete_triangle_data.sas') / nosource2;
    %include resfld ('ibnr_agg_transpose_alloc_icg_claim.sas') / nosource2;
    %include resfld ('ibnr_alloc_generate_insurance_cf.sas') / nosource2;
    %include resfld ('ibnr_return_job.sas') / nosource2;;
    %include resfld ('ibnr_smooth_data.sas') / nosource2;

proc sql;
    select distinct business_unit into: business_unit_list separated by ' ' from &caslib..&FACTOR_SUMMARY.;
    select distinct reserving_class into: reserving_class_list separated by ' ' from &caslib..&FACTOR_SUMMARY.;
    select distinct Item into: item_list separated by ' ' from &caslib..&FACTOR_SUMMARY.
   where item in('Known_Loss','Incurred_Loss','Paid_Loss');
quit;
