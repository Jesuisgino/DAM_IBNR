/*
Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\anchor  pcpr_join_tbl_cas
\brief  Macro that allows the join of two tables

\param [in] caslib             Cas Library
\param [in] base_tbl           Input Cas table
\param [in] join_direction     Direction of the join operation (inner/left/right/full)
\param [in] tbl_to_join        Cas table in join
\param [in] join_key           Variable used as key
\param [in] output_tbl         Name of resulting table

\details  For columns that exist in both tables, the USING clause merges the columns from the joined tables into a single column.
\ingroup Macros
\author  SAS Institute Inc.
\date    2023
*/

%macro pcpr_join_tbl_cas(caslib=,base_tbl=,join_direction=inner,tbl_to_join=,join_key=,output_tbl=);

proc cas;
source q2;
 create table &output_tbl. {options replace=true} as
  select *
  from &base_tbl.
  &join_direction. join &tbl_to_join. using (&join_key.);
endsource;
fedSql.execDirect / query=q2;
run;
quit;

%mend pcpr_join_tbl_cas;
