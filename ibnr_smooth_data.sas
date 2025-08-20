/*
 Copyright (C) 2024-2025 SAS Institute Inc. Cary, NC, USA
*/

%MACRO smooth_data(Smooth_RC=,Smooth_BU=,Smooth_UWY=,Smooth_Dev_Start=,Smooth_Dev_End=,Smooth_Item=,Method=);


    DATA WORK.tmp_work_data(drop = max_S) CASUSER._&TRIANGLE_DATA.(drop = max_S replace = yes);
		SET &caslib..&TRIANGLE_DATA. end = eof;
        retain max_S;
        ;
	     if _N_ eq 1 then max_S = 0;
         if business_unit = "&Smooth_BU"
				AND reserving_class = "&Smooth_RC"
				AND Item = "&Smooth_Item" then do;
                   max_S = MAX(MAX_S, S);
                   if origin_year = &Smooth_UWY and development_period ge &Smooth_Dev_Start and development_period le &Smooth_Dev_End then output tmp_work_data;
                   else output CASUSER._&TRIANGLE_DATA.;
         end;
         else output CASUSER._&TRIANGLE_DATA.;
         if eof then Call Symput("CURR_MOD_CNT",max_S);
    RUN;


	Data _Null_;
		Set tmp_work_data end = eof;
        retain max_S;
        if _N_ eq 1 then max_S = 0;
        max_S = MAX(MAX_S, S);
        if eof then
		Call Symput("MOD_CNT_FLAG",max_S);
	Run;


	%IF &MOD_CNT_FLAG = 0 %THEN
		%DO;
			/* If the smoothing has been carried out in the range of factors specified */

			%let CURR_MOD_CNT = %sysevalf(&CURR_MOD_CNT + 1);

			/* calculate growth in the rage of factors specified */

			%LET Ori_Growth = 1.0;

			%DO dev_i = &Smooth_Dev_Start %TO &Smooth_Dev_End %BY 1;
				PROC SQL NOPRINT;
					SELECT Factor
					INTO :tmp
					FROM WORK.tmp_work_data
					WHERE development_period = &dev_i;
				QUIT;

				%let Ori_Growth =%sysevalf(&Ori_Growth*&tmp);
			%END;

			/* we need to extract the Amount because it is the variable that we manipulate */
			PROC SQL NOPRINT;
				SELECT AMOUNT_NEXT format 16.2
				INTO :amnt
				FROM WORK.tmp_work_data
				WHERE development_period = &Smooth_Dev_End;
			QUIT;

			%let Calc_step 		= %sysevalf(&Smooth_Dev_End - &Smooth_Dev_Start + 1);

			/* 	Constant link ratio Method
			* 	All methods make changes to Amount_Calc and Amount_Calc_Next
			*/
			%put &Ori_Growth;
			%put &Calc_step;

			%IF &Method = Constant_Link_Ratio %THEN
				%DO;

					%put &Ori_Growth;

					%let Calc_Factor 	= %sysevalf(&Ori_Growth**(1/&Calc_Step));

					%put &Calc_Factor;
					%put &amnt;

					%DO dev_i = &Smooth_Dev_End %TO (&Smooth_Dev_Start+1) %BY -1;
						%LET amnt = %sysevalf(&amnt / &Calc_Factor);
						%put &dev_i;
						%put &amnt;

						PROC SQL;
							SELECT *
							FROM WORK.tmp_work_data
							WHERE development_period = &dev_i;
						QUIT;


						DATA WORK.tmp_work_data;
							SET WORK.tmp_work_data;
							IF development_period = &dev_i
							THEN Amount_Calc = &amnt;
						RUN;

						DATA WORK.tmp_work_data;
							SET WORK.tmp_work_data;
							IF development_period = &dev_i -1
							THEN Amount_Calc_Next = &amnt;
						RUN;
					%END;

				%END;

			%ELSE %IF &Method = Inverse_Power %THEN
				%DO;
					/* 	Inverse Power Rule Method
					* 	All methods make changes to Amount_Calc and Amount_Calc_Next
					*/

					PROC SQL;
						CREATE TABLE DF_Inv_Power_Test AS
						SELECT development_period, Factor, log(development_period) as logy, log(Factor-1) as logd
						FROM WORK.tmp_work_data;
					QUIT;

					PROC NLIN data=DF_Inv_Power_Test;
						parms Gradients = -1 Constant = -1;
						model logd = Gradients*logy + Constant;
						ods Output ParameterEstimates = InvPPest;
					RUN;

					Data _Null_;
						Set InvPPest(Where=(Parameter="Gradients"));
						Call Symput("Gradient",Estimate);
					Run;

					Data _Null_;
						Set InvPPest(Where=(Parameter="Constant"));
						Call Symput("Constant",Estimate);
					Run;

					Data DF_Inv_Power_Test;
						SET DF_Inv_Power_Test;
						Smooth_Factor = 1 + exp(&Gradient.*logy + &Constant.);
					RUN;

					%LET Smooth_Growth = 1.0;

					%DO dev_i = &Smooth_Dev_Start %TO &Smooth_Dev_End %BY 1;
						PROC SQL NOPRINT;
							SELECT Smooth_Factor
							INTO :tmp
							FROM DF_Inv_Power_Test
							WHERE development_period = &dev_i;
						QUIT;

						%let Smooth_Growth = %sysevalf(&Smooth_Growth*&tmp);
						%put Smooth_Growth;
					%END;

					DATA DF_Inv_Power_Test_out;
						SET DF_Inv_Power_Test;
						Final_Factor = Smooth_Factor*%sysevalf((&Ori_Growth / &Smooth_Growth)**(1/&Calc_Step));
					RUN;

					%DO dev_i = &Smooth_Dev_End %TO (&Smooth_Dev_Start+1) %BY -1;
						PROC SQL;
							SELECT Final_Factor
							INTO :Calc_Factor
							FROM DF_Inv_Power_Test_out
							WHERE development_period = &dev_i;
						QUIT;

						%LET amnt = %sysevalf(&amnt / &Calc_Factor);

						DATA WORK.tmp_work_data;
							SET WORK.tmp_work_data;
							IF development_period = &dev_i
							THEN Amount_Calc = &amnt;
						RUN;

						DATA WORK.tmp_work_data;
							SET WORK.tmp_work_data;
							IF development_period = &dev_i -1
							THEN Amount_Calc_Next = &amnt;
						RUN;
					%END;
				%END;

			%ELSE %IF &Method = Exponential_Decay %THEN
				%DO;
					/* 	Exponential Decay Method
					* 	All methods make changes to Amount_Calc and Amount_Calc_Next
					*/

					PROC SQL;
						CREATE TABLE DF_Exp_Decay_Test AS
						SELECT development_period, Factor, log(Factor-1) as logd
						FROM WORK.tmp_work_data;
					QUIT;

					PROC NLIN data=DF_Exp_Decay_Test;
						parms Gradients = -1 Constant = -1;
						model logd = Gradients*development_period + Constant;
						ods Output ParameterEstimates = ExpPest;
					RUN;

					Data _Null_;
						Set ExpPest(Where=(Parameter="Gradients"));
						Call Symput("Gradient",Estimate);
					Run;

					Data _Null_;
						Set ExpPest(Where=(Parameter="Constant"));
						Call Symput("Constant",Estimate);
					Run;

					Data DF_Exp_Decay_Test;
						SET DF_Exp_Decay_Test;
						Smooth_Factor = 1 + exp(&Gradient.*development_period + &Constant.);
					RUN;

					%LET Smooth_Growth = 1.0;

					%DO dev_i = &Smooth_Dev_Start %TO &Smooth_Dev_End %BY 1;
						PROC SQL NOPRINT;
							SELECT Smooth_Factor
							INTO :tmp
							FROM DF_Exp_Decay_Test
							WHERE development_period = &dev_i;
						QUIT;

						%let Smooth_Growth = %sysevalf(&Smooth_Growth*&tmp);
						%put Smooth_Growth;
					%END;

					DATA DF_Exp_Decay_Test_out;
						SET DF_Exp_Decay_Test;
						Final_Factor = Smooth_Factor*%sysevalf((&Ori_Growth / &Smooth_Growth)**(1/&Calc_Step));
					RUN;

					%DO dev_i = &Smooth_Dev_End %TO (&Smooth_Dev_Start+1) %BY -1;
						PROC SQL;
							SELECT Final_Factor
							INTO :Calc_Factor
							FROM DF_Exp_Decay_Test_out
							WHERE development_period = &dev_i;
						QUIT;

						%LET amnt = %sysevalf(&amnt / &Calc_Factor);

						DATA WORK.tmp_work_data;
							SET WORK.tmp_work_data;
							IF development_period = &dev_i
							THEN Amount_Calc = &amnt;
						RUN;

						DATA WORK.tmp_work_data;
							SET WORK.tmp_work_data;
							IF development_period = &dev_i -1
							THEN Amount_Calc_Next = &amnt;
						RUN;
					%END;

				%END;
			%ELSE %IF &Method = Spline %THEN
				%DO;
					PROC SQL;
						CREATE TABLE DF_Spline AS
						SELECT (development_period) as x,
							development_period,
							Factor,
							log(Factor) as y
						FROM WORK.tmp_work_data;
					QUIT;

					proc transreg data=DF_Spline;
						/* piecewise polynomial functions */
						/*
						model identity(y) = pspline(x);
						output out = outfile pprefix = outp;
						*/
						model identity(y) = pspline(x / nknots = 0 degree = 1);
						output out = outfile PPREFIX =outp;
					run;
/*
					DATA outfile;
						SET outfile;
						expoutpy = exp(outpy);
					RUN;
	*/
					proc sql;
						select *
						from outfile;
					quit;

					%DO dev_i = &Smooth_Dev_End %TO (&Smooth_Dev_Start+1) %BY -1;

						PROC SQL NOPRINT;
							SELECT exp(outpy)
							INTO :Calc_Factor
							FROM outfile
							WHERE x = &dev_i;
						QUIT;

						%put &dev_i;
						%put &Calc_Factor;

						%LET amnt = %sysevalf(&amnt / &Calc_Factor);

						DATA WORK.tmp_work_data;
							SET WORK.tmp_work_data;
							IF development_period = &dev_i
							THEN Amount_Calc = &amnt;
						RUN;

						DATA WORK.tmp_work_data;
							SET WORK.tmp_work_data;
							IF development_period = &dev_i -1
							THEN Amount_Calc_Next = &amnt;
						RUN;
					%END;

				%END;

			/* Calculate the smoothing factor */

			%DO dev_i = &Smooth_Dev_End %TO &Smooth_Dev_Start %BY -1;

			%let Msg=&sysdate9. &systime &SYS_COMPUTE_SESSION_OWNER,smoothed DF using constant factor method between dev period &Smooth_Dev_Start and &Smooth_Dev_End in &CURR_MOD_CNT smoothing group.;
			%if &_audittrail=
						%then %do;
							%let Msg="&Msg.";
						%end;
						%else %do;
							%let Msg="&Msg.  comment:&_audittrail.";
						%end;

				DATA WORK.tmp_work_data(replace=yes);
					SET WORK.tmp_work_data;
					IF development_period = &dev_i
					THEN
						DO;
							Factor = Amount_Calc_Next/Amount_Calc;
							S = &CURR_MOD_CNT;
							Amount_Dscr = &Msg;
						END;
				RUN;

			%END;
	%END;

	DATA CASUSER._&TRIANGLE_DATA.(append = force);
		SET WORK.tmp_work_data;
	RUN;

	proc casutil;
		droptable casdata="&TRIANGLE_DATA." incaslib="&caslib." QUIET;
        save casdata="_&TRIANGLE_DATA." incaslib="CASUSER" casout="&TRIANGLE_DATA." outcaslib="&caslib." replace;
    	promote casdata="_&TRIANGLE_DATA." incaslib="CASUSER" casout="&TRIANGLE_DATA." outcaslib="&caslib.";

	run;

%MEND;
