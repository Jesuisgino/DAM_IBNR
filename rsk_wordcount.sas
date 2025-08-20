/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
\file
\brief    returns the number of words in a string

\param[in]               str         :  (pos) unquoted string
\param[in]               dlm = %str():  delimiter, default to space

\details


USAGE: %rsk_wordcount(str, dlm=)

\ingroup macros
\author  SAS Institute Inc.
\date    2022
*/

%macro rsk_wordcount(str, dlm=%str( ));

    %local i;

    %let i=1;

    %do %while(%length(%scan(&str,&i,&dlm)) GT 0);
        %let i=%eval(&i + 1);
    %end;

    %eval(&i - 1)

%mend rsk_wordcount;
