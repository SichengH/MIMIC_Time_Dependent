# Background

This code repo is a summarization rather than an innovation. It simply contained too many people's wisdom and effort to be listed here. The main contributors are lab members from LCP MIT and authors from the two publications below: 

Wanis, K. N., Madenci, A. L., Hao, S., Moukheiber, M., Moukheiber, L., Moukheiber, D., ... & Celi, L. A. (2023). Emulating target trials comparing early and delayed intubation strategies. Chest, 164(4), 885-891.

Mellado-Artigas, R., Borrat, X., Ferreyro, B. L., Yarnell, C., Hao, S., Wanis, K. N., ... & Brochard, L. (2024). Effect of immediate initiation of invasive ventilation on mortality in acute hypoxemic respiratory failure: a target trial emulation. Critical Care, 28(1), 157.


# Method

(TODO)

# Technical Details

## Requirement: 
- PhysioNet.org credential
- DUA MIMIC-IV
- Google BigQuery Access for MIMIC-IV
- Some experience with Google BigQuery

## Compatiple data version
- MIMIC_IV v2.2 (does not support the current version: v3.0)

## Usage note
- Create your own BigQuery project and make proper changes to the file (mainly project and dataset names)
- Run the .sql code one by one. (01,02,...)
- Option: load the data into R using the "Export_data.R" file. 
