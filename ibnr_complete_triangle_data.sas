/*This macro performs 3 tasks: 1. complete loss triangle 2. derive incremental triangle 3. project cash flows*/

/*complete loss triangle lower half*/
%macro complete_triangle_data();

   /*first check input table exist*/
   %rsk_dsexist_cas(cas_lib = %superq(caslib)
                      ,cas_table = %superq(triangle_data)
                      );

      %if not &cas_table_exists. %then %do;
         %put ERROR: triangle data does not exist, abort process;
         %abort;
      %end;
      %else %if %rsk_attrn(&caslib..&triangle_data.,nlobs) eq 0 %then %do;
         %put ERROR: triangle data does not contain observation, cash flow generation will not be performed;
         %abort;
      %end;

   %rsk_dsexist_cas(cas_lib = %superq(caslib)
                      ,cas_table = %superq(Factor_summary)
                      );

      %if not &cas_table_exists. %then %do;
         %put ERROR: factor summary table does not exist, abort process;
         %abort;
      %end;
      %else %if %rsk_attrn(&caslib..&Factor_summary.,nlobs) eq 0 %then %do;
         %put ERROR: factor summary table does not contain observation, cash flow generation will not be performed;
         %abort;
      %end;

/*Check if completed triangle exist, if yes, then find out if filter condition exist, if yes, then replace. Otherwise, create new*/
   %rsk_dsexist_cas(cas_lib = %superq(caslib)
                      ,cas_table = %superq(complete_triangle_data)
                      );

   %if &cas_table_exists. %then %do;
      proc casutil;
         droptable casdata="_tmp_&complete_triangle_data." incaslib="casuser" QUIET;
      quit;

      data completed_triangle casuser._tmp_&complete_triangle_data.(replace=yes);
         set &caslib..&complete_triangle_data.;
        if upcase(business_unit) = %upcase("&_bu")
            AND upcase(reserving_class) = %upcase("&_rc")
            AND upcase(Item) = %upcase("&_item") then do;
         output completed_triangle;
        end;
        else do;
         output casuser._tmp_&complete_triangle_data.;
        end;
      run;

   %end;

/*Check if incremental triangle exist, if yes, then find out if filter condition exist, if yes, then replace. Otherwise, create new*/
   %rsk_dsexist_cas(cas_lib = %superq(caslib)
                      ,cas_table = %superq(incr_triangle_data)
                      );

   %if &cas_table_exists. %then %do;
      proc casutil;
         droptable casdata="_tmp_&incr_triangle_data." incaslib="casuser" QUIET;
      quit;

      data triangle_increm casuser._tmp_&incr_triangle_data.(replace=yes);
         set &caslib..&incr_triangle_data.;
        if upcase(business_unit) = %upcase("&_bu")
            AND upcase(reserving_class) = %upcase("&_rc")
            AND upcase(Item) = %upcase("&_item") then do;
         output triangle_increm;
        end;
        else do;
         output casuser._tmp_&incr_triangle_data.;
        end;
      run;

   %end;

/*Check if projected cashflow exist, if yes, then find out if filter condition exist, if yes, then replace. Otherwise, create new*/
   %rsk_dsexist_cas(cas_lib = %superq(caslib)
                      ,cas_table = %superq(projected_cf)
                      );

   %if &cas_table_exists. %then %do;
      proc casutil;
         droptable casdata="_tmp_&projected_cf." incaslib="casuser" QUIET;
      quit;

      data projected_cf casuser._tmp_&projected_cf.(replace=yes);
         set &caslib..&projected_cf.;
        if upcase(business_unit) = %upcase("&_bu")
            AND upcase(reserving_class) = %upcase("&_rc")
            AND upcase(Item) = %upcase("&_item") then do;
         output projected_cf;
        end;
        else do;
         output casuser._tmp_&projected_cf.;
        end;
      run;

   %end;

/** We will work on a subset of data, namely **/
/**   BU:   **/
/**   ReservClass:    **/
/**   Item:  Known_loss **/

   data start_triangle;
      set &caslib..&triangle_data.;
        Where upcase(business_unit) = %upcase("&_bu")
            AND upcase(reserving_class) = %upcase("&_rc")
            AND upcase(Item) = %upcase("&_item");
   run;

   data Start_factor;
    set &caslib..&Factor_summary. end=last;
       Where upcase(business_unit) = %upcase("&_bu")
            AND upcase(reserving_class) = %upcase("&_rc")
            AND upcase(Item) = %upcase("&_item")
            AND upcase(Name) = "SELECTED";
      RETAIN MAX_FACTOR;
      if _n_ = 1 then max_factor = factor;
      else max_factor = max(factor,max_factor);
      if last then do;
          if max_factor in (0,.) then do;
             putlog 'ERROR: Development factors are all zerio. Please select the development factor first.';
             abort;
         end;
      end;
   run;

/* Clean out master dataset Triangle_complete */
   proc datasets lib=work nolist;
     delete Triangle_complete  ;
   run; quit;


   proc sort data=work.Start_factor  out=Start_factor_sorted ;
    by Business_Unit Reserving_class Item Development_Period;
   run;

   proc sort data=work.Start_triangle   out=Start_triangle_sorted ;
    by Business_Unit Reserving_class Item Origin_Year Development_Period;
   run;


/*** Complete the triangle for the selected dimension */
%global Max_dev_period Max_Origin_Year;
   /* get dimension Dev_period */
   proc sql noprint;
     select max(Development_Period) into :Max_dev_period
       from Start_triangle;
    select max(origin_year) into :Max_Origin_Year
     from Start_triangle;
   quit;
   %let Max_dev_period = %sysfunc(strip(&Max_dev_period));
   %put Max_dev_period = &Max_dev_period ;

   %let Max_Origin_Year = %sysfunc(strip(&Max_Origin_Year));
   %put Max_Origin_Year = &Max_Origin_Year ;

   /**** Put Triangle data in arrays  */

   proc transpose data=work.Start_triangle_sorted
        out=work.Triangle_trans(where=(upcase(_name_)="AMOUNT_CALC"))
        prefix=devyear;
       id Development_Period ;
     by Business_Unit Reserving_class Item Origin_year;
   run;

   /*** Put Factor data as array */

   proc transpose data=work.start_factor_sorted (rename=(name=type_average))
      out=work.Factor_trans  (where=(upcase(_name_)="FACTOR") drop=type_average)
      prefix=devperiod_factor;
     id Development_Period ;
     by Business_Unit Reserving_class Item Type_average;
   run;

   /*** Merge Triangle_trans and Factor_trans, and Complete the triangle */
   data work.Triangle_merged ;
     merge    work.Triangle_trans  (in=intriangle drop=_NAME_)
      work.Factor_trans(drop=_NAME_) ;
     by Business_Unit Reserving_class Item ;
     if intriangle ;
   run;

   /*** Complete the triangle, if completed_triangle already exist, then overwrite it*/
   data work.completed_triangle_trans  (drop= i devperiod_factor: )  ;
     set work.Triangle_merged ;
        array  Loss_Yr[*]              devyear: ;
        array  Factor[*]              devperiod_factor: ;

      do i=1 to &Max_dev_period ;
      if Loss_Yr[i] = . then do ;
           if i > 1  then Loss_Yr[i] = Loss_Yr[i-1] * Factor[i-1] ;
         else  Loss_Yr[i] = Loss_Yr[i];
      end;
      end;
     format devyear1-devyear&Max_dev_period   comma18.2;
   run;

   /*Calculate incremental triangle, if already exist, then overwrite it*/
   data Triangle_increm_trans (drop= i devyear:);
    set completed_triangle_trans ;
    array  Loss_Yr[*]           devyear: ;
    array  Loss_Incr_Yr[*]        incrdevyear1-incrdevyear&Max_dev_period ;

     do i=1 to &Max_dev_period ;
       if i = 1  then Loss_Incr_Yr[i] = Loss_Yr[i];
        else  Loss_Incr_Yr[i] = sum(Loss_Yr[i], -Loss_Yr[i-1]) ;
     end;
     format incrdevyear1-incrdevyear&Max_dev_period   comma18.2;

   run;

   /*Project cashflows*/
   data projected_cf_trans  (drop= k index incrdevyear:);
     set Triangle_increm_trans;
     array  Loss_Incr_Yr[*]        incrdevyear: ;
     array    Proj_CF[*]            projCFyear1-projCFyear&Max_dev_period ;

     do k=1 to &Max_dev_period ;  /* ColNr */
       index = - _n_ + k +1 ;
       if index > 0 then Proj_CF[k] = 0 ;
      else Proj_CF[k] = Loss_Incr_Yr[&Max_dev_period + index] ;
     end;
     format projCFyear1-projCFyear&Max_dev_period   comma18.2;
   run;

    data projected_cf_trans ;
          set projected_cf_trans ;
         rename
        %do i=1 %to &Max_dev_period;
        projCFyear&i = CF_1JAN%sysevalf(&Max_Origin_Year+&i)
        %end;
      ;
   run;

   /*Transpose data sets*/

   proc sort data=work.completed_triangle_trans;
    by Business_Unit Reserving_class Item Origin_Year;
   run;

   proc transpose data=work.completed_triangle_trans
      out=work.completed_triangle(rename = (_NAME_ = Dev_Year COL1 = AMOUNT));
     by Business_Unit Reserving_class Item Origin_Year;
     var devyear1-devyear&Max_dev_period;
   run;

   proc sort data=work.Triangle_increm_trans;
    by Business_Unit Reserving_class Item Origin_Year;
   run;
   proc transpose data=work.Triangle_increm_trans
      out=work.Triangle_increm(rename = (_NAME_ = Inc_Dev_Year COL1 = AMOUNT));
     by Business_Unit Reserving_class Item Origin_Year;
     var incrdevyear1-incrdevyear&Max_dev_period;
   run;


   proc sort data=work.projected_cf_trans;
    by Business_Unit Reserving_class Item Origin_Year;
   run;
   proc transpose data=work.projected_cf_trans
      out=work.projected_cf(rename = (_NAME_ = CF_DATE COL1 = AMOUNT));
     by Business_Unit Reserving_class Item Origin_Year;
     var  CF:;
   run;

   /*Append back to cas data*/
   data casuser._completed_triangle(drop = Dev_Year BUSINESS_UNIT RESERVING_CLASS ITEM RENAME = (_BUSINESS_UNIT = BUSINESS_UNIT _ITEM=ITEM _RESERVING_CLASS = RESERVING_CLASS));
       set completed_triangle;
      length DEVELOPMENT_PERIOD 8 _BUSINESS_UNIT VARCHAR(36)
           _RESERVING_CLASS VARCHAR(36) _ITEM VARCHAR(36);
      DEVELOPMENT_PERIOD = input(substr(Dev_Year,8), 6.0);
      _ITEM = ITEM;
      _BUSINESS_UNIT = BUSINESS_UNIT;
      _RESERVING_CLASS = RESERVING_CLASS;
      label DEVELOPMENT_PERIOD = "Development Period";
   run;

   data casuser._tmp_&complete_triangle_data.(APPEND=FORCE);
      set casuser._completed_triangle;
   RUN;

   data casuser._tmp_&incr_triangle_data.(drop = Inc_Dev_Year append=force);
      set Triangle_increm;
      length development_period 8;
      development_period = input(substr(Inc_Dev_Year,12), 6.0)  ;
      label development_period = "Development Period";
   run;

   data casuser._tmp_&projected_cf.(drop = CF_DATE append=force);
      set projected_cf;
      length Cashflow_Date 8;
      Cashflow_Date = input(substr(CF_DATE,4), anydtdte12.)  ;
      label Cashflow_Date = "Cashflow Date";
      format Cashflow_Date date9.;
   run;

/***** Store in CAS */

   proc casutil;
      droptable casdata="&complete_triangle_data." incaslib="&caslib." quiet;
      save casdata="_tmp_&complete_triangle_data." incaslib="casuser" casout="&complete_triangle_data." outcaslib="&caslib." replace;
      promote casdata="_tmp_&complete_triangle_data." incaslib="casuser" casout="&complete_triangle_data." outcaslib="&caslib.";
   run;

   proc casutil;
      droptable casdata="&incr_triangle_data." incaslib="&caslib." quiet;
      save casdata="_tmp_&incr_triangle_data." incaslib="casuser" casout="&incr_triangle_data." outcaslib="&caslib." replace;
      promote casdata="_tmp_&incr_triangle_data." incaslib="casuser" casout="&incr_triangle_data." outcaslib="&caslib.";
   run;

   proc casutil;
      droptable casdata="&projected_cf." incaslib="&caslib." quiet;
      save casdata="_tmp_&projected_cf." incaslib="casuser" casout="&projected_cf." outcaslib="&caslib." replace;
      promote casdata="_tmp_&projected_cf." incaslib="casuser" casout="&projected_cf." outcaslib="&caslib.";
   run;

%mend;
