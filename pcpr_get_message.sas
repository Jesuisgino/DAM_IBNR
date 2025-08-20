%macro pcpr_get_message(key,s1, s2, s3, s4, s5, s6, s7);

    /* Force the key to be lowercase */
    %let key=%lowcase(&key.);

    /* Figure out the message file name */
    %local msgfile;
    %if (%ksubstr(&key., 1, 17)=pcpricingutilmsg_ ) %then %do;
        %let msgfile=pcpricingutilmsg;
    %end;
    %else %do;
        %put ERROR: Cannot determine message file for key=&key.;
        %return;
    %end;

    /* Retrieve the message */
    %local text;
    %if (%bquote(&S7) ne ) %then %do;
        %let text=%sysfunc(sasmsg(&msgfile, &key., NOQUOTE, &s1, &s2, &s3, &s4,
            &s5, &s6, &s7));
    %end;
    %else %if (%bquote(&s6) ne ) %then %do;
        %let text=%sysfunc(sasmsg(&msgfile, &key., NOQUOTE, &s1, &s2, &s3, &s4,
            &s5, &s6));
    %end;
    %else %if (%bquote(&s5) ne ) %then %do;
        %let text=%sysfunc(sasmsg(&msgfile, &key., NOQUOTE, &s1, &s2, &s3, &s4,
            &s5));
    %end;
    %else %if (%bquote(&s4) ne ) %then %do;
        %let text=%sysfunc(sasmsg(&msgfile, &key., NOQUOTE, &s1, &s2, &s3,
            &s4));
    %end;
    %else %if (%bquote(&s3) ne ) %then %do;
        %let text=%sysfunc(sasmsg(&msgfile, &key., NOQUOTE, &s1, &s2, &s3));
    %end;
    %else %if (%bquote(&s2) ne ) %then %do;
        %let text=%sysfunc(sasmsg(&msgfile, &key., NOQUOTE, &s1, &s2));
    %end;
    %else %if (%bquote(&s1) ne ) %then %do;
        %let text=%sysfunc(sasmsg(&msgfile, &key., NOQUOTE, &s1));
    %end;
    %else %do;
        %let text=%sysfunc(sasmsg(&msgfile, &key., NOQUOTE));
    %end;

    /* Write the text to the input buffer */
    &text.

%mend;
