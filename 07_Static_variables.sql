DROP TABLE IF EXISTS `mvte-318912.mv.static_variables`;
CREATE TABLE `mvte-318912.mv.static_variables` AS (
WITH static_variables AS
    (
      SELECT
      patients.subject_id,
      patients.gender,
      patients.anchor_age,
      --patients.anchor_year,
      patients.anchor_year_group,
      patients.dod,
      admissions.hadm_id,
      admissions.insurance,
      admissions.language,
      admissions.marital_status,
      admissions.race,
      CASE WHEN stay_id IN (
         SELECT DISTINCT stay_id FROM `mvte-318912.mv.vent_status`
         WHERE ventilation_status = "Invasive"
      ) THEN 1 ELSE 0 END AS invasive_overall,
      admissions.hospital_expire_flag,
      --admissions.admittime,
      --admissions.dischtime,
      --admissions.deathtime,
      admissions.admission_type, 
      CASE WHEN admissions.admission_type = 'ELECTIVE' Then 1 
      ELSE 0 END AS admissions_elective,
      admissions.admission_location,
      admissions.discharge_location,
      icu_stay.stay_id,
      icu_stay.first_careunit, --icu_stay.last_careunit,
      --icu_stay.intime, icu_stay.outtime, 
      icu_stay.los AS ICU_los,
      TIMESTAMP_DIFF(admissions.dischtime,admissions.admittime,hour) AS HOSP_los
      FROM `physionet-data.mimiciv_hosp.patients` patients    
      INNER JOIN `physionet-data.mimiciv_hosp.admissions` admissions  
         ON patients.subject_id =admissions.subject_id
      INNER JOIN `physionet-data.mimiciv_icu.icustays` icu_stay 
         ON admissions.hadm_id = icu_stay.hadm_id
         AND admissions.subject_id = icu_stay.subject_id
      ORDER BY subject_id
    )

    SELECT * FROM static_variables )
