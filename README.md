# sre.service-definition

Use the script 'generate-schema-files-by-scanning.ps1' to update the schema by scanning all repos before doing manual modification:

 * cd to sre.service-definition
 * . .\generate-schema-files-by-scanning.ps1
 * Generate-LatestSchema "absolute path to where all repos to scan are located"  EX: C:\Users\chmi\source\search
 * Now review the detected fields in latest/foundation/schema.json, once done issue the new command:
 * Generate-SubSchema, which will generate the api/ui/job/consumer schema's based on latest/foundation/schema.json
* 