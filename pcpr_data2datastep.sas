/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
   \brief   Create datastep from dataset

   \param [in] dsn Name of the dataset to be converted. Required.
   \param [in] lib LIBREF of the original dataset. (Optional - if DSN is not fully qualified)
   \param [in] outlib LIBREF for the output dataset. (Optional - default is WORK)
   \param [in] file Fully qualified filename for the DATA step code produced. (Optional - Default is %nrstr(create_&outlib._&dsn._data.sas))
   \param [in] folder Fully qualified folder name for the DATA step code produced. (Optional - Default is "/Users/sasadm");
   \param [in] obs Max observations to include the created dataset. (Optional - Defaults to all obs)
   \param [in] fmt Format the numeric variables in the output dataset [YES|NO] (Optional - Default is YES )
   \param [in] lbl Reproduce column labels in the output dataset [YES|NO] (Optional - Default is YES)

   \details This macro creates a file with a SAS datastep from a provided dataset. The file is saved in the provided folder. The file can be ran to recreate the dataset in any other SAS environment.

   \ingroup macro
   \author  SAS Institute Inc.
   \date    2024
*/

%macro data2datastep(dsn,lib,outlib,file,folder,obs,fmt,lbl);
    %local varlist fmtlist inputlist msgtype ;

    %if %superq(obs)=%then %let obs=MAX;

    %let msgtype=NOTE;
    %if %superq(dsn)=%then %do;
        %let msgtype=ERROR;
        %put &msgtype: You must specify a data set name;
        %put;
        %goto syntax;
    %end;
    %let dsn=%qupcase(%superq(dsn));
    %if %superq(dsn)=!HELP %then %do;
        %syntax:

        data _null_;
            call symput ('LS',getoption('LS','startupvalue'));
        run;
        options ls=100;
        %put &msgtype: &SYSMACRONAME macro help document:;
        %put &msgtype- Purpose: Converts a data set to a SAS DATA step.;
        %put &msgtype- Syntax:
            %nrstr(%%)&SYSMACRONAME(dsn<,lib,outlib,file,obs,fmt,lbl>);
        %put &msgtype- dsn: Name of the dataset to be converted. Required.;
        %put &msgtype- lib: LIBREF of the original dataset. (Optional - if DSN
            is not fully qualified);
        %put &msgtype- outlib: LIBREF for the output dataset. (Optional -
            default is WORK);
        %put &msgtype- file: Fully qualified filename for the DATA step code
            produced. (Optional);
        %put &msgtype- Default is %nrstr(create_&outlib._&dsn._data.sas) in the
            SAS default directory.;
        %put &msgtype- folder: Fully qualified folder name for the DATA step
            code produced. (Optional);
        %put &msgtype- Default is "/Users/sasadm";
        %put &msgtype- obs: Max observations to include the created dataset.;
        %put &msgtype- (Optional) Default is MAX (all observations);
        %put &msgtype- fmt: Format the numeric variables in the output dataset
            like the original data set? ;
        %put &msgtype- (YES|NO - Optional) Default is YES;
        %put &msgtype- lbl: Reproduce column labels in the output dataset? ;
        %put &msgtype- (YES|NO - Optional) Default is YES;
        %put;
        %put NOTE: &SYSMACRONAME cannot be used in-line - it generates code.;
        %put NOTE- Every FORMAT in the original data must have a corresponding
            INFORMAT of the same name.;
        %put NOTE- Data set label is automatically re-created.;
        %put NOTE- Only numeric column formats can be re-created, character
            column formats are ingnored.;
        %put NOTE- Use !HELP to print these notes.;
        options ls=&ls;
        %return;
    %end;
    %if %superq(fmt)=%then %let fmt=YES;
    %let fmt=%qupcase(&fmt);
    %if %superq(lbl)=%then %let lbl=YES;
    %let lbl=%qupcase(&lbl);

    %if %superq(lib)=%then %do;
        %let lib=%qscan(%superq(dsn),1,.);
        %if %superq(lib)=%superq(dsn) %then %let lib=WORK;
        %else %let dsn=%qscan(&dsn,2,.);
    %end;
    %if %superq(outlib)=%then %let outlib=WORK;
    %let lib=%qupcase(%superq(lib));
    %let dsn=%qupcase(%superq(dsn));

    %if %sysfunc(exist(&lib..&dsn)) ne 1 %then %do;
        %put ERROR: (&SYSMACRONAME) - Dataset &lib..&dsn does not exist.;
        %let msgtype=NOTE;
        %GoTo syntax;
    %end;

    %if %superq(file)=%then %do;
        %let file=create_&outlib._&dsn._data.sas;
    %end;

    %if %superq(folder)=%then %do;
        %let folder=/Users/sasadm;
    %end;

    proc sql noprint;
        select Name into :varlist separated by ' ' from dictionary.columns where
            libname="&lib" and memname="&dsn" ;
        select case type when 'num' then case when missing(format) then
            cats(Name,':32.') else cats(Name,':',format) end else
            cats(Name,':$',length,'.') end into :inputlist separated by ' ' from
            dictionary.columns where libname="&lib" and memname="&dsn" ;
        %if %qsubstr(%superq(lbl),1,1)=Y %then %do;
            select strip(catx('=',Name,put(label,$quote.))) into : lbllist
                separated by ' ' from dictionary.columns where libname="&lib"
                and memname="&dsn" and label is not null ;
        %end;
        %else %let lbllist=;
        select memlabel into :memlabel trimmed from dictionary.tables where
            libname="&lib" and memname="&dsn" ;
        %if %qsubstr(%superq(fmt),1,1)=Y %then %do;
            select strip(catx(' ',Name,format)) into :fmtlist separated by ' '
                from dictionary.columns where libname="&lib" and memname="&dsn"
                and format is not null and format not like '$%' ;
        %end;
        %else %let fmtlist=;
    quit;

    %put _local_;
    filename out filesrvc folderPath="&folder." filename=%lowcase("&file.")
        debug=http;

    data _null_;
        file out dsd;
        if _n_=1 then do;
            %if %superq(memlabel)=%then %do;
                put "data &outlib..&dsn;";
            %end;
            %else %do;
                put "data &outlib..&dsn(label=%tslit(%superq(memlabel)));";
            %end;
            put @3 "infile datalines dsd truncover;";
            put @3 "input %superq(inputlist);";
            %if not (%superq(fmtlist)=) %then %do;
                put @3 "format %superq(fmtlist);";
            %end;
            %if not (%superq(lbllist)=) %then %do;
                put @3 "label %superq(lbllist);";
            %end;
            put "datalines4;";
        end;
        set &lib..&dsn(obs=&obs) end=last_line;
        put &varlist @;
        if last_line then do;
            put;
            put ';;;;';
            put 'run;';
        end;
        else put;
    run;
%mend;
