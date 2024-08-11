library(data.table)
library(tidyr)
library(tidyverse)
library(readxl)
library(gdata)
library(lubridate)
library(comorbidity)

library(bigrquery)
library(tidyr)
library(DBI)
library(dbplyr)
library(dplyr)

'%!in%' <- function(x,y)!('%in%'(x,y))

#### Connect to BigQuery#####
#bq_auth(use_oob = TRUE)

projectid = "mvte-318912"#replace with your own project id
bigrquery::bq_auth()#login with google account associated with physionet account

# sql <- "
# SELECT *except(gender,anchor_age,anchor_year_group,insurance,language,marital_status,
# race,first_careunit,los)
# FROM `mvte-318912.mv.cohort_final`
# "

sql <- "
SELECT *except(subject_id,hadm_id,starttime,endtime,sbp_ni,dbp_ni,mbp_ni)
FROM `mvte-318912.mv.cohort_final`
"
bq_data <- bq_project_query(projectid, query = sql)

df = bq_table_download(bq_data)
#fwrite(df,file = 'cohort.csv')
save(bq_data,file = 'cohort.RData')
