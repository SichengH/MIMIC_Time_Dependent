DROP TABLE IF EXISTS `mvte-318912.mv.cohort_final`;
CREATE TABLE `mvte-318912.mv.cohort_final` AS 

SELECT 
cohort.*,
COALESCE(death.death_outcome,0) AS death_outcome,
COALESCE(d.discharge_outcome, 0) AS discharge_outcome,
COALESCE(vent.invasive, 0) AS invasive,
COALESCE(vent.noninvasive, 0) AS noninvasive,
COALESCE(vent.highflow, 0) AS highflow,
CASE WHEN invasive = 1 or noninvasive = 1 or highflow = 1 THEN sofa_comp.fio2 ELSE NUll END as fio2,
vital.*EXCEPT(stay_id, hr),
COALESCE(pressor.vaso_dose_per_min, 0) AS vasopressor,
COALESCE(o2.o2_flow, 0) AS o2_flow,
--COALESCE(rrt, 0) AS crrt,
--COALESCE(sepsis3, 0) AS sepsis3,
--sofa.sofa_24hours,
sofa_comp.*EXCEPT(stay_id,hr,fio2),
--static.*EXCEPT(subject_id,hadm_id,stay_id),
eli.elixhauser_vanwalraven,
FROM `mvte-318912.mv.icu_720h` cohort
LEFT JOIN `mvte-318912.mv.vent_status_hr` vent
ON cohort.stay_id = vent.stay_id
AND cohort.hr = vent.hr
LEFT JOIN `mvte-318912.mv.deathtime` death
ON cohort.stay_id = death.stay_id
AND cohort.hr = death.hr
LEFT JOIN `mvte-318912.mv.discharge_outcome` d
ON cohort.stay_id = d.stay_id
AND cohort.hr = d.hr
LEFT JOIN `mvte-318912.mv.elixhauser_score` eli
ON eli.stay_id = cohort.stay_id
LEFT JOIN `mvte-318912.mv.pressors` pressor
ON pressor.stay_id = cohort.stay_id
AND pressor.hr = cohort.hr
LEFT JOIN `mvte-318912.mv.o2_flow` o2
ON o2.stay_id = cohort.stay_id
AND o2.hr = cohort.hr
--LEFT JOIN `mvte-318912.mv.sepsis3` sepsis
--ON sepsis.stay_id = cohort.stay_id
--AND sepsis.hr = cohort.hr
LEFT JOIN `mvte-318912.mv.SOFA_components` sofa_comp
ON sofa_comp.stay_id = cohort.stay_id
AND sofa_comp.hr = cohort.hr
--LEFT JOIN `physionet-data.mimiciv_derived.sofa` sofa
--ON sofa.stay_id = cohort.stay_id
--AND sofa.hr = cohort.hr
--LEFT JOIN `mvte-318912.mv.static_variables` static
--ON cohort.stay_id = static.stay_id
LEFT JOIN `mvte-318912.mv.vital` vital
ON vital.stay_id = cohort.stay_id
AND vital.hr = cohort.hr
LEFT JOIN `mvte-318912.mv.treat_limit` te
ON te.stay_id = cohort.stay_id
AND te.hr = cohort.hr
WHERE cohort.stay_id NOT IN (
  SELECT DISTINCT stay_id
  FROM `mvte-318912.mv.exclusion` 
)
--LEFT JOIN `mvte-318912.mv.crrt` crrt
--ON crrt.stay_id = cohort.stay_id
----AND crrt.hr = cohort.hr
--WHERE cohort.stay_id = 33116576
--order by hr