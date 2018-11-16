# AddABWrapper

# Modes
## Mode 2 (List of _af Tables):
* __./addABWrapper.tcsh 2 \<Listofaf_Tables.txt\> \<versionID\> \<mdexInputPath\> \<af_InputPath\> \<msk_InputPath\> \<OutputPath\>__
## Mode 3 (Single _af Table)
* __./addABWrapper.tcsh 3 \<af_Table\> \<versionID\> \<mdexInputPath\> \<af_InputPath\> \<msk_InputPath\> \<OutputPath\>__

TODO:
Write README

NOTES:
* The reason we have both \<mdexInputPath\> \<af_InputPath\> is because we need 1) the flags in the "af-table" and 2) the precision in the original "mdex-tables" that is lost in the "af-tables" from stilts.
