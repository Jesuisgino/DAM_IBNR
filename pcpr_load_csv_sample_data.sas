/*
 Copyright (C) 2022-2025 SAS Institute Inc. Cary, NC, USA
*/

/**
   \file
   \brief   Load sample data in csv file to a target library

   \param [in] tgt_lib      Intermediate libref where the sample data will be loaded
   \param [in] dir          Path to the sample data files
   \param [in] csv_table_list   The list of tables in the sample data directory
   \param [in] caslib       caslib name that table will be loaded to

   \details This macro loops through all .csv files found in the input directory {dir} or from a csv table list and upload them.

   \ingroup development
   \author  SAS Institute Inc.
   \date    2022
*/
%macro pcpr_load_csv_sample_data(tgt_lib =
                            , dir =
                            , csv_table_list=
                            , caslib=
                            );

               /*Directory can't be empty*/
               %if %length(&dir.)=0 %then %do;
                  %return;
               %end;
               %if %length(&caslib) ^=0 %then %do;
                   %let caslib_nm=&caslib;
               %end;
               %else %do;
                   %let caslib_nm=public;
               %end;

               options validvarname=any;
               %if %length(&csv_table_list.)^=0 %then %do;
                  %local csv_table_cnt l m;
                  %let l=1;
                  %let m=1;
                  %let csv_table_cnt=%rsk_wordcount(&csv_table_list.);
                  %do l = 1 %to &csv_table_cnt.;
                      %let csv_curr_table=%scan(&csv_table_list.,&l);
                      %let input=;
                      %let length=;
                      %let format=;
                      %let label=;
                      %if %upcase(&csv_curr_table)=PC_PRICING_ABT_RAW %then %do;
                          %let length="Policy number"n varchar(36) LINE_OF_BUSINESS_ID varchar(36) COVERAGE_CD varchar(20) "Policy uw year"n 8. BEGIN_COV_DT 8. END_COV_DT 8. CANCELLATION_DT 8. NEW_POLICY_FLG varchar(1) Exposure 8. Frequency 8. Severity 8. CUST_AREA_CD varchar(10) CUST_REGION_CD varchar(10) CUST_POP_DENSITY_AMT 8. CUST_AGE_AMT 8. CUST_BONUS_MALUS_LEVEL_AMT 8. VEH_FUEL_TYPE_CD varchar(10) VEH_MAKE_MODEL_CD varchar(20) VEH_AGE_AMT 8. VEH_POWER_LEVEL_AMT 8.;
                          %let input="Policy number"n :$36. LINE_OF_BUSINESS_ID :$36. COVERAGE_CD :$20. "Policy uw year"n BEGIN_COV_DT :anydtdte12. END_COV_DT :anydtdte12. CANCELLATION_DT :anydtdte12. NEW_POLICY_FLG :$1. Exposure Frequency Severity CUST_AREA_CD :$10. CUST_REGION_CD :$10. CUST_POP_DENSITY_AMT CUST_AGE_AMT CUST_BONUS_MALUS_LEVEL_AMT VEH_FUEL_TYPE_CD :$10. VEH_MAKE_MODEL_CD :$20. VEH_AGE_AMT VEH_POWER_LEVEL_AMT;
                      %end;
                      %else %if %upcase(&csv_curr_table)=PC_PRICING_ABT_HOME_RAW %then %do;
                          %let length="Policy number"n varchar(36) LINE_OF_BUSINESS_ID varchar(36) COVERAGE_CD varchar(20) "Policy uw year"n 8. BEGIN_COV_DT 8. END_COV_DT 8. CANCELLATION_DT 8. NEW_POLICY_FLG varchar(1) Exposure 8. Frequency 8. Severity 8. PERSONAL_PROPERTY_CAP_AMT 8. DWELLING_CAPITAL_AMT 8. LIABILITY_CAPITAL_AMT 8.   ASSISTANCE_PREMIUM_AMT 8.  PERSONAL_PROPERTY_PREM_AMT 8. DWELLING_PREMIUM_AMT 8. LIABILITY_PREMIUM_AMT 8.   PAYMENT_METHOD_CD varchar(36) PREMIUM_AMT 8. PREMIUM_FRACTIONARY_FLG varchar(1)  PREVIOUS_PREMIUM_AMT 8. POPULATION_TYPE_CD varchar(20)   RISK_BUILDING_SQM_AMT 8.   RISK_DWELLING_TYPE_CD varchar(20)   RISK_INHABITANTS_NO 8.  RISK_NOT_FLAMMABLE_FLG varchar(1)   RISK_PET_FLG varchar(1) RISK_PROPERTY_FLG varchar(1)  RISK_USAGE_CD varchar(20) CUST_AGE_AMT 8. CUST_REGION_CD varchar(10);
                          %let input="Policy number"n :$36. LINE_OF_BUSINESS_ID :$36. COVERAGE_CD :$20. "Policy uw year"n BEGIN_COV_DT :anydtdte12. END_COV_DT :anydtdte12. CANCELLATION_DT :anydtdte12. NEW_POLICY_FLG :$1. Exposure Frequency Severity PERSONAL_PROPERTY_CAP_AMT  DWELLING_CAPITAL_AMT LIABILITY_CAPITAL_AMT   ASSISTANCE_PREMIUM_AMT  PERSONAL_PROPERTY_PREM_AMT DWELLING_PREMIUM_AMT LIABILITY_PREMIUM_AMT   PAYMENT_METHOD_CD :$36. PREMIUM_AMT PREMIUM_FRACTIONARY_FLG :$1.  PREVIOUS_PREMIUM_AMT POPULATION_TYPE_CD :$20.   RISK_BUILDING_SQM_AMT   RISK_DWELLING_TYPE_CD :$20.   RISK_INHABITANTS_NO  RISK_NOT_FLAMMABLE_FLG :$1.   RISK_PET_FLG :$1. RISK_PROPERTY_FLG :$1.  RISK_USAGE_CD :$20. CUST_AGE_AMT CUST_REGION_CD :$10.;
                      %end;
                      %else %if %upcase(&csv_curr_table)=PC_PRICING_DETL_CLAIM_RAW %then %do;
                          %let length=CLAIM_ID varchar(36) "Policy number"n varchar(36) COVERAGE_CD varchar(20) Severity 8.;
                          %let input=CLAIM_ID :$36. "Policy number"n :$36. COVERAGE_CD :$20. Severity;
                      %end;
                      %else %if %upcase(&csv_curr_table)=PC_PRICING_DETL_CUSTOMER_RAW %then %do;
                          %let length=CUST_ID varchar(36) "Policy Num"n varchar(36)  CUST_DRIVING_LICENSE_DT 8. CUST_GENDER_CD varchar(1) CUST_STATE_CD varchar(20) CUST_MARRIAGE_STATUS_CD varchar(40) CUST_JOB_TYPE_TXT varchar(100) CUST_ED_LEVEL_TYPE_TXT varchar(100) "Cust Age"n 8.;
                          %let input=CUST_ID :$36. "Policy Num"n :$36. CUST_DRIVING_LICENSE_DT :anydtdte12. CUST_GENDER_CD :$1. CUST_STATE_CD :$20. CUST_MARRIAGE_STATUS_CD :$40. CUST_JOB_TYPE_TXT :$100. CUST_ED_LEVEL_TYPE_TXT :$100. "Cust Age"n;
                      %end;
                      %else %if %upcase(&csv_curr_table)=PC_PRICING_DETL_POLICY_RAW %then %do;
                          %let length="Num of Policy"n varchar(36) LINE_OF_BUSINESS_ID varchar(36) "Policy uw year"n 8. BEGIN_COV_DT 8. END_COV_DT 8. CANCELLATION_DT 8. NEW_POLICY_FLG varchar(1) Exposure 8. VEH_AGE_AMT 8. VEH_MAKE_MODEL_CD varchar(20) VEH_OWNER_TYPE_CD varchar(20) VEH_CUBIC_CAPACITY_AMT 8. VEH_SI_GROSS_AMT 8. VEH_SI_WS_AMT 8. VEH_SALE_CHANNELS_TYPE_TXT varchar(100) CUST_BONUS_MALUS_LEVEL_AMT 8.;
                          %let input="Num of Policy"n :$36. LINE_OF_BUSINESS_ID :$36. "Policy uw year"n BEGIN_COV_DT :anydtdte12. END_COV_DT :anydtdte12. CANCELLATION_DT :anydtdte12. NEW_POLICY_FLG :$1. Exposure VEH_AGE_AMT VEH_MAKE_MODEL_CD :$20. VEH_OWNER_TYPE_CD :$20. VEH_CUBIC_CAPACITY_AMT VEH_SI_GROSS_AMT VEH_SI_WS_AMT VEH_SALE_CHANNELS_TYPE_TXT :$100. CUST_BONUS_MALUS_LEVEL_AMT;
                      %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_FACTOR_SUMMARY %then %do;
                          %let length=BUSINESS_UNIT varchar(36) RESERVING_CLASS varchar(36) ITEM varchar(36) DEVELOPMENT_PERIOD 8. NAME varchar(32) FACTOR 8. CASHFLOW 8. ID 8. FACTOR_FLAG 8. CASHFLOW_FLAG 8. FACTOR_DSCR varchar(256) CASHFLOW_DSCR varchar(256);
                          %let input=BUSINESS_UNIT :$36. RESERVING_CLASS :$36. ITEM :$36. DEVELOPMENT_PERIOD NAME :$32. FACTOR CASHFLOW ID FACTOR_FLAG CASHFLOW_FLAG FACTOR_DSCR :$256. CASHFLOW_DSCR :$256.;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_SCHEDULE %then %do;
                          %let length=START_DATE 8. END_DATE 8. TASK varchar(36) "GROUP"n varchar(32);
                          %let input=START_DATE :anydtdte12. END_DATE :anydtdte12. TASK :$36. "GROUP"n :$32.;
                          %let format=START_DATE DATE9. END_DATE DATE9.;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_STATUS_SUMMARY %then %do;
                          %let length=BUSINESS_UNIT varchar(36) RESERVING_CLASS varchar(36) ITEM varchar(36) STATUS varchar(32) RESPONSIBLE varchar(32);
                          %let input=BUSINESS_UNIT :$36. RESERVING_CLASS :$36. ITEM :$36. STATUS :$32. RESPONSIBLE :$32.;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_SUMMARY %then %do;
                          %let length=BUSINESS_UNIT varchar(36) RESERVING_CLASS varchar(36) ITEM varchar(36) ORIGIN_YEAR 8. ESTIMATED_PREMIUM 8. APRIORI_LOSS_RATIO 8. PREVIOUS_IBNR 8. IBNR_BOOKED 8. C_FACTOR 8. SELECTED_ULTIMATE 8. LOSS_CASHFLOW 8. AUDIT_TRAIL varchar(128) CUMULATIVE_LOSS 8. PROCESS_ERROR 8. ESTIMATION_ERROR 8.;
                          %let input=BUSINESS_UNIT :$36. RESERVING_CLASS :$36. ITEM :$36. ORIGIN_YEAR APRIORI_LOSS_RATIO ESTIMATED_PREMIUM CUMULATIVE_LOSS PREVIOUS_IBNR LOSS_CASHFLOW IBNR_BOOKED C_FACTOR AUDIT_TRAIL :$128. SELECTED_ULTIMATE PROCESS_ERROR ESTIMATION_ERROR;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_TRIANGLE_DATA %then %do;
                          %let length=BUSINESS_UNIT varchar(36) RESERVING_CLASS varchar(36) ORIGIN_YEAR 8. DEVELOPMENT_PERIOD 8. ITEM varchar(36) AMOUNT_INC 8. AMOUNT 8. AMOUNT_CALC 8. LAST 8. FACTOR 8. X 8. S 8. X_NEXT 8. AMOUNT_DSCR varchar(256) AMOUNT_NEXT 8. AMOUNT_CALC_NEXT 8. MIN_ORIGIN_YEAR 8. MAX_DEVELOPMENT_PERIOD 8.;
                          %let input=BUSINESS_UNIT :$36. RESERVING_CLASS :$36. ORIGIN_YEAR DEVELOPMENT_PERIOD ITEM :$36. AMOUNT_INC AMOUNT AMOUNT_CALC LAST FACTOR X S X_NEXT AMOUNT_DSCR :$256. AMOUNT_NEXT AMOUNT_CALC_NEXT MIN_ORIGIN_YEAR MAX_DEVELOPMENT_PERIOD;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_VECTOR_DATA %then %do;
                          %let length=BUSINESS_UNIT varchar(36) RESERVING_CLASS varchar(36) ITEM varchar(36) ORIGIN_YEAR 8. ESTIMATED_PREMIUM 8. APRIORI_LOSS_RATIO 8. PREVIOUS_IBNR 8. IBNR_BOOKED 8.;
                          %let input=BUSINESS_UNIT :$36. RESERVING_CLASS :$36. ITEM :$36. ORIGIN_YEAR ESTIMATED_PREMIUM APRIORI_LOSS_RATIO PREVIOUS_IBNR IBNR_BOOKED;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_EXPENSE_RATIO %then %do;
                          %let length=PARAMETER varchar(36) APPLICATION_FIELD varchar(36) VALUE 8.;
                          %let input=PARAMETER :$36. APPLICATION_FIELD :$36. VALUE;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_ICG_CLAIM %then %do;
                          %let length=POLICY_ID varchar(36) ICG_ID varchar(36) ACCIDENTYEAR 8. CLAIM_AMOUNT 8. CLAIM_DATE 8.;
                          %let input=POLICY_ID :$36. ICG_ID :$36. ACCIDENTYEAR :anydtdte12. CLAIM_AMOUNT CLAIM_DATE :anydtdte12.;
                          %let format=ACCIDENTYEAR DATE9. CLAIM_DATE DATE9.;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_TRIANGLE_COMPLETE %then %do;
                          %let length=BUSINESS_UNIT varchar(36) RESERVING_CLASS varchar(36) ORIGIN_YEAR 8. DEVELOPMENT_PERIOD 8. ITEM varchar(36) AMOUNT 8.;
                          %let input=BUSINESS_UNIT :$36. RESERVING_CLASS :$36. ORIGIN_YEAR  DEVELOPMENT_PERIOD ITEM :$36. AMOUNT ;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_TRIANGLE_INCREM %then %do;
                          %let length=BUSINESS_UNIT varchar(36) RESERVING_CLASS varchar(36) ITEM varchar(36) ORIGIN_YEAR 8. AMOUNT 8. DEVELOPMENT_PERIOD 8. ;
                          %let input=BUSINESS_UNIT :$36. RESERVING_CLASS :$36. ITEM :$36. ORIGIN_YEAR  AMOUNT DEVELOPMENT_PERIOD;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_PROJECTED_CF %then %do;
                          %let length=BUSINESS_UNIT varchar(36) RESERVING_CLASS varchar(36) ITEM varchar(36) ORIGIN_YEAR 8. AMOUNT 8. CASHFLOW_DATE 8. ;
                          %let input=BUSINESS_UNIT :$36. RESERVING_CLASS :$36. ITEM :$36. ORIGIN_YEAR  AMOUNT CASHFLOW_DATE :anydtdte12.;
                          %let format=CASHFLOW_DATE DATE9.;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_PROJECTED_CF_BY_ICG %then %do;
                          %let length=BUSINESS_UNIT varchar(36) RESERVING_CLASS varchar(36) ITEM varchar(36) SORTORDER_ICG varchar(36) ICG_ID varchar(36)  CASHFLOW_AMT 8. CASHFLOW_DATE 8. ;
                          %let input=BUSINESS_UNIT :$36. RESERVING_CLASS :$36. ITEM :$36. SORTORDER_ICG :$36. ICG_ID :$36.  CASHFLOW_AMT CASHFLOW_DATE :anydtdte12.;
                          %let format=CASHFLOW_DATE DATE9.;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_ICG_INCUR_TODATE %then %do;
                          %let length= ICG_ID varchar(36) SORTORDER_ICG varchar(36)   AMOUNT 8. AY 8. ;
                          %let input=ICG_ID :$36.  SORTORDER_ICG :$36.  AMOUNT  AY ;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_ALLOC_MATRIX %then %do;
                          %let length= ICG_ID varchar(36) ICG_TECHID varchar(36) SORTORDER_ICG varchar(36)   ALLOC_PCT 8. AY 8. ;
                          %let input=ICG_ID :$36. ICG_TECHID :$36. SORTORDER_ICG :$36.  ALLOC_PCT  AY ;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_INSURANCE_CF_LIC_CLAIMS %then %do;
                          %let length= REPORTING_DT 8 ENTITY_ID varchar(36) INSURANCE_CONTRACT_GROUP_ID varchar(36) CASHFLOW_LEG_NM varchar(36) CEDED_FLG varchar(1) CASHFLOW_TYPE_CD varchar(36) CURRENCY_CD varchar(10) INCURRED_CLAIM_DT 8
                          CASHFLOW_DT 8 CASHFLOW_AMT 8 BUSINESS_UNIT varchar(36) RESERVING_CLASS varchar(36) ITEM varchar(36);
                          %let input=REPORTING_DT :anydtdte12. ENTITY_ID :$36. INSURANCE_CONTRACT_GROUP_ID :$36. CASHFLOW_LEG_NM :$36. CEDED_FLG :$1. CASHFLOW_TYPE_CD :$36. CURRENCY_CD :$10. INCURRED_CLAIM_DT :anydtdte12.
                          CASHFLOW_DT :anydtdte12. CASHFLOW_AMT BUSINESS_UNIT :$36. RESERVING_CLASS :$36. ITEM :$36. ;
                          %let format=REPORTING_DT DATE9. INCURRED_CLAIM_DT DATE9. CASHFLOW_DT DATE9.;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_INSURANCE_CF_LIC_EXPENSES %then %do;
                          %let length= REPORTING_DT 8 ENTITY_ID varchar(36) INSURANCE_CONTRACT_GROUP_ID varchar(36) CASHFLOW_LEG_NM varchar(36) CEDED_FLG varchar(1) CASHFLOW_TYPE_CD varchar(36) CURRENCY_CD varchar(10) INCURRED_CLAIM_DT 8
                          CASHFLOW_DT 8 CASHFLOW_AMT 8 BUSINESS_UNIT varchar(36) RESERVING_CLASS varchar(36) ITEM varchar(36);
                          %let input=REPORTING_DT :anydtdte12. ENTITY_ID :$36. INSURANCE_CONTRACT_GROUP_ID :$36. CASHFLOW_LEG_NM :$36. CEDED_FLG :$1. CASHFLOW_TYPE_CD :$36. CURRENCY_CD :$10. INCURRED_CLAIM_DT :anydtdte12.
                          CASHFLOW_DT :anydtdte12. CASHFLOW_AMT BUSINESS_UNIT :$36. RESERVING_CLASS :$36. ITEM :$36. ;
                          %let format=REPORTING_DT DATE9. INCURRED_CLAIM_DT DATE9. CASHFLOW_DT DATE9.;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_CONFIG %then %do;
                          %let length=CYCLE_ID varchar(20) CAS_LIB varchar(20);
                          %let input=CYCLE_ID :$20. CAS_LIB :$20.;
                       %end;
                      %else %if %upcase(&csv_curr_table)=PC_PRICING_DQ_CLAIMS %then %do;
                          %let length= CLIENTNAME varchar(36) DEALERPOLICYNUMBER varchar(36) PRODUCERCODE varchar(36) CLAIMNUMBER varchar(36) CLAIMNUMBERSUFFIX 8. CURRENCY varchar(10) TRANSACTIONDATE 8. DATEOFLOSS 8. DATECLAIMISREPORTED 8.
                          DATEPAID 8. CLAIMSTATE varchar(10) CLAIMCOUNTRY varchar(10) CLAIMSTATUS varchar(1) CAUSEOFLOSS varchar(36) CLAIMTYPE varchar(36) TOTALPAIDAMOUNT 8. TOTALPENDINGAMOUNT 8. ;
                          %let input= CLIENTNAME :$36. DEALERPOLICYNUMBER :$36. PRODUCERCODE :$36. CLAIMNUMBER :$36. CLAIMNUMBERSUFFIX CURRENCY :$10. TRANSACTIONDATE :anydtdte12. DATEOFLOSS :anydtdte12. DATECLAIMISREPORTED :anydtdte12.
                          DATEPAID :anydtdte12. CLAIMSTATE :$10. CLAIMCOUNTRY :$10. CLAIMSTATUS :$1. CAUSEOFLOSS :$36. CLAIMTYPE :$36. TOTALPAIDAMOUNT TOTALPENDINGAMOUNT  ;
                          %let format= TRANSACTIONDATE DATE9. DATEOFLOSS DATE9. DATECLAIMISREPORTED DATE9. DATEPAID DATE9. ;
                       %end;
                      %else %if %upcase(&csv_curr_table)=PC_PRICING_DQ_PREMIUM %then %do;
                          %let length= CLIENTNAME varchar(36) DEALERPOLICYNUMBER varchar(36) PRODUCERCODE varchar(36) PROGRAMNAME varchar(36) INSURANCETYPE varchar(10) CONTRACTSTATUS varchar(1) WARRANTYDESCRIPTION varchar(36)
                         WARRANTYTYPE varchar(36) WARRANTYSUBTYPE varchar(36) COVERAGEGROUP varchar(1) PRODUCTTYPE varchar(36) PRODUCTSUBTYPE varchar(36) TRANSACTIONDATE 8. CONTRACTPURCHASEDATE 8. RENEWALDATE 8.
                          TERMMONTHS 8. STARTOFRISKTYPE varchar(10) COVERAGEEFFECTIVEDATE 8. COVERAGEEXPIRATIONDATE 8. PRODUCTPURCHASEPRICE 8. USETYPE varchar(36) CLAIMLIMITOFLIABILITY 8. CONTRACTLIMITOFLIABILITY 8.
                          CLAIMTYPE varchar(36) DEDUCTIBLE 8. RETAILAMOUNT 8. ADMINAMOUNT 8. INSURANCEPREMIUM 8. RESERVEAMOUNT 8. CEDING_RISK_FEE 8. PREMIUMTAX 8. CURRENCY varchar(10) ADMINISTRATOR varchar(36)
                          INSURANCECOMPANYNAME varchar(10) OBLIGORCODE varchar(10);
                          %let input=  CLIENTNAME :$36. DEALERPOLICYNUMBER :$36. PRODUCERCODE :$36. PROGRAMNAME :$36. INSURANCETYPE :$10. CONTRACTSTATUS :$1. WARRANTYDESCRIPTION :$36. WARRANTYTYPE :$36. WARRANTYSUBTYPE :$36.
                          COVERAGEGROUP :$1. PRODUCTTYPE :$36. PRODUCTSUBTYPE :$36. TRANSACTIONDATE :anydtdte12. CONTRACTPURCHASEDATE :anydtdte12. RENEWALDATE :anydtdte12. TERMMONTHS STARTOFRISKTYPE :$10.
                          COVERAGEEFFECTIVEDATE :anydtdte12. COVERAGEEXPIRATIONDATE :anydtdte12. PRODUCTPURCHASEPRICE USETYPE :$36. CLAIMLIMITOFLIABILITY CONTRACTLIMITOFLIABILITY CLAIMTYPE :$36.  DEDUCTIBLE RETAILAMOUNT
                          ADMINAMOUNT INSURANCEPREMIUM RESERVEAMOUNT CEDING_RISK_FEE PREMIUMTAX CURRENCY :$10. ADMINISTRATOR :$36.  INSURANCECOMPANYNAME :$10. OBLIGORCODE :$10. ;
                          %let format= TRANSACTIONDATE DATE9. CONTRACTPURCHASEDATE DATE9. RENEWALDATE DATE9. COVERAGEEFFECTIVEDATE DATE9. COVERAGEEXPIRATIONDATE DATE9. ;
                       %end;
                      %else %if %upcase(&csv_curr_table)=PC_PRICING_DQ_PRODUCER %then %do;
                          %let length= ACCOUNTNAME varchar(36) PRODUCERCODE varchar(36) PRODUCERNAME varchar(36) PRODUCERTYPE 8. PRODUCERSTATE varchar(10) PRODUCERCOUNTRY varchar(10) AGENTCODE varchar(36) AGENTNAME varchar(36) PRODUCERSTARTDATE 8. ;
                          %let input=ACCOUNTNAME :$36. PRODUCERCODE :$36. PRODUCERNAME :$36. PRODUCERTYPE PRODUCERSTATE :$10. PRODUCERCOUNTRY :$10. AGENTCODE :$36. AGENTNAME :$36. PRODUCERSTARTDATE :anydtdte12. ;
                          %let format=PRODUCERSTARTDATE DATE9. ;
                       %end;
                      %else %if %upcase(&csv_curr_table)=PC_PRICING_DQ_CONFIG_CLAIM %then %do;
                          %let length= FIELD_NAME varchar(36) FIELD_TYPE varchar(10)FIELD_LENGTH varchar(10) REQUIRED_FIELD_DESIGNATION varchar(36) ;
                          %let input=  FIELD_NAME :$36. FIELD_TYPE :$10. FIELD_LENGTH :$10. REQUIRED_FIELD_DESIGNATION :$36. ;
                       %end;
                      %else %if %upcase(&csv_curr_table)=PC_PRICING_DQ_CONFIG_PREMIUM %then %do;
                          %let length= FIELD_NAME varchar(36) FIELD_TYPE varchar(10)FIELD_LENGTH varchar(10) REQUIRED_FIELD_DESIGNATION varchar(36) ;
                          %let input=  FIELD_NAME :$36. FIELD_TYPE :$10. FIELD_LENGTH :$10. REQUIRED_FIELD_DESIGNATION :$36. ;
                       %end;
                      %else %if %upcase(&csv_curr_table)=PC_PRICING_DQ_CONFIG_PRODUCER %then %do;
                          %let length= FIELD_NAME varchar(36) FIELD_TYPE varchar(10)FIELD_LENGTH varchar(10) REQUIRED_FIELD_DESIGNATION varchar(36) ;
                          %let input=  FIELD_NAME :$36. FIELD_TYPE :$10. FIELD_LENGTH :$10. REQUIRED_FIELD_DESIGNATION :$36. ;
                       %end;
                      %else %if %upcase(&csv_curr_table)=IBNR_CLAIM_DATA %then %do;
                          %let length=BUSINESS_UNIT varchar(36) RESERVING_CLASS varchar(36) RESERVING_ITEM varchar(36) ORIGIN_YEAR 8. CLAIM_DATE 8. CLAIM_AMOUNT 8. ;
                          %let input=BUSINESS_UNIT :$36. RESERVING_CLASS :$36. RESERVING_ITEM :$36. ORIGIN_YEAR CLAIM_DATE :anydtdte12. CLAIM_AMOUNT ;
                          %let format=CLAIM_DATE DATE9.;
                       %end;
                       %else %if %upcase(&csv_curr_table)=ANNUITY_PRICING_RST %then %do;
                          %let length=PathID varchar(38) ruleFiredFlags varchar(1) rulesFiredForRecordCount 8. _recordCorrelationKey varchar(36) AnnuityAmount 8. AnnuityRate 8. CSM 8. MCVNB 8. PVAcqCost 8. PVClaims 8. PVFCF 8. PVPremium 8. PVSttlmtCost 8. Premium 8. PurePremium 8. RA 8. RoCapital 8. VNB 8. VNB_Margin 8. ISSUE_AGE 8. SALES_MIX_AMT 8. CHANNEL_ID varchar(36) INDEX_CD varchar(36) ISSUE_GENDER_CD varchar(1) ISSUE_UW_CLASS_CD varchar(1) PRODUCT_CD varchar(36) PRODUCT_ID varchar(36) RATE_ID varchar(36) SCENARIO_ID varchar(36);
                          %let input=PathID :$38. ruleFiredFlags :$1. rulesFiredForRecordCount _recordCorrelationKey :$36. AnnuityAmount AnnuityRate CSM MCVNB PVAcqCost PVClaims PVFCF PVPremium PVSttlmtCost Premium PurePremium RA RoCapital VNB VNB_Margin ISSUE_AGE SALES_MIX_AMT CHANNEL_ID :$36. INDEX_CD :$36. ISSUE_GENDER_CD :$1. ISSUE_UW_CLASS_CD :$1. PRODUCT_CD :$36. PRODUCT_ID :$36. RATE_ID :$36. SCENARIO_ID :$36. ;
                          %let format=;
                       %end;
                       %else %if %upcase(&csv_curr_table)=AUTO_COMP_RBCTAB or %upcase(&csv_curr_table)=HOME_COMP_RBCTAB or %upcase(&csv_curr_table)=AUTO_FREQ_RBFTAB or %upcase(&csv_curr_table)=AUTO_SEV_RBSTAB %then %do;
                          %let length=_VARIABLE_  VARCHAR(36) _VARIABLE2_ VARCHAR(36) _GROUP_  8. _GROUP2_ 8. _SPLIT_VALUE_ VARCHAR(36) _SPLIT_VALUE2_ VARCHAR(36) _LABEL_ VARCHAR(256) _LABEL2_  VARCHAR(256) Coefficient 8. _LEVEL_ VARCHAR(36) _LEVEL2_ VARCHAR(36) BINFLAG 8. BINFLAG2 8. InteractionFlag 8.;
                          %let input=_VARIABLE_  :$char. _VARIABLE2_   :$char. _GROUP_  _GROUP2_  _SPLIT_VALUE_  :$char. _SPLIT_VALUE2_  :$char. _LABEL_  :$char. _LABEL2_  :$char. Coefficient  _LEVEL_ :$char. _LEVEL2_ :$char. BINFLAG  BINFLAG2  InteractionFlag;
                          %let format=;
                       %end;
                       %else %if %upcase(&csv_curr_table)=ENRICHED_ANNUITY_CFG_ABT   %then %do;
                          %let length=PRODUCT_CD varchar(36) SCENARIO_ID varchar(36) RATE_ID varchar(36)  POLICY_ID varchar(36)  CHANNEL_ID varchar(36) PRODUCT_ID varchar(36) INDEX_CD varchar(8) ISSUE_AGE 8. ISSUE_GENDER_CD varchar(1) ISSUE_UW_CLASS_CD varchar(1) UW_IMPROV_ALFA_AMT 8. UW_IMPROV_BETA_AMT 8. PREMIUM_AMT 8. DEF_PRD_AMT 8. COV_PRD_AMT 8.  PYMT_INC_RT 8. PAYMENT_MODE_CD varchar(8)  ANNUITY_AMT 8. LOADING_PCT 8. ACQ_COST_AMT 8. ACQ_COST_RT 8. STMT_COST_RT 8. MAX_ATTAINED_AGE 8. FRAC_METHOD_CD varchar(36) INTRP_METH_CD varchar(36) DG_DISC_CURVE varchar(32767) DG_MORTALITY varchar(32767)  VALUATION_DT 8. INDEX_NO 8. ;
                          %let input=PRODUCT_CD :$36. SCENARIO_ID :$36. RATE_ID :$36. POLICY_ID :$36.  CHANNEL_ID :$36. PRODUCT_ID :$36. INDEX_CD :$8. ISSUE_AGE ISSUE_GENDER_CD :$1. ISSUE_UW_CLASS_CD :$36. UW_IMPROV_ALFA_AMT UW_IMPROV_BETA_AMT PREMIUM_AMT DEF_PRD_AMT COV_PRD_AMT PYMT_INC_RT PAYMENT_MODE_CD :$8. ANNUITY_AMT LOADING_PCT ACQ_COST_AMT ACQ_COST_RT STMT_COST_RT MAX_ATTAINED_AGE FRAC_METHOD_CD :$36. INTRP_METH_CD :$36. DG_DISC_CURVE :$32767. DG_MORTALITY :$32767. VALUATION_DT :anydtdte12. INDEX_NO;
                          %let format=VALUATION_DT DATE9.;
                       %end;
                      filename cdata_&l. filesrvc folderpath="&sample_data_path/" filename= "&csv_curr_table..csv" debug=http;
                      data &tgt_lib.._&csv_curr_table.;
                          length &length.;
                          %if %upcase(&format)^=  %then %do;
                             format &format.;
                          %end;
                          %if %upcase(&label)^=  %then %do;
                             label &label.;
                          %end;
                          infile cdata_&l. dsd truncover firstobs=2;
                          input &input. ;
                      run;
                      options minoperator;
                      %if %upcase(&csv_curr_table) IN (IBNR_FACTOR_SUMMARY IBNR_SUMMARY IBNR_TRIANGLE_DATA IBNR_TRIANGLE_COMPLETE) %then %do;
                      data &tgt_lib.._&csv_curr_table._ORIG;
                        set &tgt_lib.._&csv_curr_table.;
                      run;
                      %pcpr_promote_table_to_cas(cas_session_name=load_sampledata, input_caslib_nm =&tgt_lib.,input_table_nm =_&csv_curr_table._ORIG,output_caslib_nm =&caslib_nm.,output_table_nm =&csv_curr_table._ORIG ,drop_sess_scope_tbl_flg=N);
                      %pcpr_save_table_to_cas(in_caslib_nm=&caslib_nm., in_table_nm=&&csv_curr_table._ORIG,out_caslib_nm=&caslib_nm., out_table_nm=&csv_curr_table._ORIG, replace_flg=true);
                      %end;


                  %pcpr_promote_table_to_cas(cas_session_name=load_sampledata, input_caslib_nm =&tgt_lib.,input_table_nm =_&csv_curr_table.,output_caslib_nm =&caslib_nm.,output_table_nm =&csv_curr_table. ,drop_sess_scope_tbl_flg=N);
                  %pcpr_save_table_to_cas(in_caslib_nm=&caslib_nm., in_table_nm=&csv_curr_table.,out_caslib_nm=&caslib_nm., out_table_nm=&csv_curr_table., replace_flg=true);
                  %end;
               %end;

%mend pcpr_load_csv_sample_data;
