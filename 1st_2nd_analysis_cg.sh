#!/bin/bash
#  Created by Mu Li on 2024-04-23.

###########################################################################################
'''
This script is used to run the first and second level analysis for the seed-to-wholebrain FC maps for the VTA ROI.
Seeds are set to cg25_2 and cg_3.
Please note that the first-level analysis output is saved under the $DIR_cg25 and $DIR_cg3.
And second level analysis output is saved under the $DIR_sec1 and $DIR_sec2.
Please make sure you have the access to the output files (already chmod -R 777). If not, please contact by email: mu.li@icahn.mssm.edu.
All the analysis are using the normlized data with 3 mm FWHM smoothing: a12anat_tlrc_blur3.nii under each subject folder in $DIR_rest.
Before running this script, please make sure you have access for $DIR_rest.
'''
###########################################################################################
ml libGLw
ml libpng/12
# ml afni/22.3.03
ml afni/21.0.02
ml python/2.7.17

# First-level analysis: getting seed-to-wholebrain FC maps
DIR_rest=/sc/arion/projects/K01_VTA/users/lim39/rest
DIR_roi=$DIR_rest/ROI
# mkdir $DIR_roi

# Seed 1: cg25
cd $DIR_rest

roi_seed=cg25_2
DIR_cg25=$DIR_rest/${roi_seed}_blur3
mkdir $DIR_cg25
DIR_sec1=$DIR_cg25/secondlevel
mkdir $DIR_sec1

while IFS= read -r subj; do
    echo "Processing subject: $subj"
    source_dir=$DIR_rest/$subj/ManualNorm_Mu
    
    # Ensure the source directory exists
    if [ ! -d "$source_dir" ]; then
        echo "Error: Source directory not found for subject $subj"
        continue  # Skip to the next subject
    fi
    
    # chmod -R +rx $source_dir
    cd ${source_dir}
    
    # Only need to do once
    # 3dcopy a12anat_tlrc_blur.nii ${subj}_a12anat_tlrc_blur3.nii -overwrite
    
    #Resample ROI to functional space
    3dresample -master ${subj}_a12anat_tlrc_blur3.nii -prefix ${roi_seed}_s -input $DIR_roi/${roi_seed}.nii -overwrite

    #Get the time series from the ROI
    3dmaskave -quiet -mask ${roi_seed}_s+tlrc.BRIK ${subj}_a12anat_tlrc_blur3.nii > ${subj}_${roi_seed}.txt -overwrite

    #Run a correlation between that time series and the rest of the brain
    3dfim+ -input ${subj}_a12anat_tlrc_blur3.nii -polort 2 -ideal_file ${subj}_${roi_seed}.txt -out Correlation -bucket ${subj}_${roi_seed}_blur3 -overwrite

    #Covert the output to a Z score map
    3dcalc -a ${subj}_${roi_seed}_blur3+tlrc.BRIK -expr 'log ( ( 1+a ) / ( 1-a ) ) /2' -prefix ${subj}_${roi_seed}_blur3_Corr -overwrite

    cp ${subj}_${roi_seed}_blur3_Corr* $DIR_cg25

done < "subj_folders.txt"

# Seed 2: cg_3
cd $DIR_rest

roi_seed=cg_3
DIR_cg3=$DIR_rest/${roi_seed}_blur3
mkdir $DIR_cg3
DIR_sec2=$DIR_cg3/secondlevel
mkdir $DIR_sec2

while IFS= read -r subj; do
    echo "Processing subject: $subj"
    source_dir=$DIR_rest/$subj/ManualNorm_Mu
    
    # Ensure the source directory exists
    if [ ! -d "$source_dir" ]; then
        echo "Error: Source directory not found for subject $subj"
        continue  # Skip to the next subject
    fi
    
    # chmod -R +rx $source_dir
    cd ${source_dir}
    
    # Only need to do once
    # 3dcopy a12anat_tlrc_blur.nii ${subj}_a12anat_tlrc_blur3.nii -overwrite
    
    #Resample ROI to functional space
    3dresample -master ${subj}_a12anat_tlrc_blur3.nii -prefix ${roi_seed}_s -input $DIR_roi/${roi_seed}.nii -overwrite

    #Get the time series from the ROI
    3dmaskave -quiet -mask ${roi_seed}_s+tlrc.BRIK ${subj}_a12anat_tlrc_blur3.nii > ${subj}_${roi_seed}.txt -overwrite

    #Run a correlation between that time series and the rest of the brain
    3dfim+ -input ${subj}_a12anat_tlrc_blur3.nii -polort 2 -ideal_file ${subj}_${roi_seed}.txt -out Correlation -bucket ${subj}_${roi_seed}_blur3 -overwrite

    #Covert the output to a Z score map
    3dcalc -a ${subj}_${roi_seed}_blur3+tlrc.BRIK -expr 'log ( ( 1+a ) / ( 1-a ) ) /2' -prefix ${subj}_${roi_seed}_blur3_Corr -overwrite

    cp ${subj}_${roi_seed}_blur3_Corr* $DIR_cg3

done < "subj_folders.txt"

###########################################################################################
# Second-level analysis: comparing first-analysis results with covariates
DIR_rest=/sc/arion/projects/K01_VTA/users/lim39/rest
roi_seed=cg25_2 # cg_3
DIR_seed=$DIR_rest/${roi_seed}_blur3
DIR_sec=$DIR_seed/secondlevel

cd $DIR_seed
chmod -R 777 ./

# MDD vs HC
3dttest++ -setA '4*Corr*BRIK' -setB '5*Corr*BRIK' -prefix $DIR_sec/${roi_seed}_MDD-HC_N78_rs -covariates $DIR_sec/ExCov.txt -mask $DIR_sec/MNI152_T1_2009c_gm_mask_rs.nii

3dttest++ -setA '4*Corr*BRIK' -covariates $DIR_sec/TEPSA.txt -prefix $DIR_sec/${roi_seed}_tepsA_MDD_rs -mask $DIR_sec/MNI152_T1_2009c_gm_mask_rs.nii
3dttest++ -setA '4*Corr*BRIK' -covariates $DIR_sec/TEPSC.txt -prefix $DIR_sec/${roi_seed}_tepsC_MDD_rs -mask $DIR_sec/MNI152_T1_2009c_gm_mask_rs.nii
3dttest++ -setA '4*Corr*BRIK' -covariates $DIR_sec/SHAPS.txt -prefix $DIR_sec/${roi_seed}_SHAPS_MDD_rs -mask $DIR_sec/MNI152_T1_2009c_gm_mask_rs.nii

3dttest++ -setA '5*Corr*BRIK' -covariates $DIR_sec/TEPSA.txt -prefix $DIR_sec/${roi_seed}_tepsA_HC_rs -mask $DIR_sec/MNI152_T1_2009c_gm_mask_rs.nii
3dttest++ -setA '5*Corr*BRIK' -covariates $DIR_sec/TEPSC.txt -prefix $DIR_sec/${roi_seed}_tepsC_HC_rs -mask $DIR_sec/MNI152_T1_2009c_gm_mask_rs.nii
3dttest++ -setA '5*Corr*BRIK' -covariates $DIR_sec/SHAPS.txt -prefix $DIR_sec/${roi_seed}_SHAPS_HC_rs -mask $DIR_sec/MNI152_T1_2009c_gm_mask_rs.nii

3dttest++ -setA '*Corr*BRIK' -covariates $DIR_sec/TEPSA.txt -prefix $DIR_sec/${roi_seed}_tepsA_all_rs -mask $DIR_sec/MNI152_T1_2009c_gm_mask_rs.nii
3dttest++ -setA '*Corr*BRIK' -covariates $DIR_sec/TEPSC.txt -prefix $DIR_sec/${roi_seed}_tepsC_all_rs -mask $DIR_sec/MNI152_T1_2009c_gm_mask_rs.nii
3dttest++ -setA '*Corr*BRIK' -covariates $DIR_sec/SHAPS.txt -prefix $DIR_sec/${roi_seed}_SHAPS_all_rs -mask $DIR_sec/MNI152_T1_2009c_gm_mask_rs.nii

3dttest++ -setA '4*Corr*BRIK' -setB '5*Corr*BRIK' -prefix $DIR_sec/${roi_seed}_MDD-HC_tepsA_rs -covariates $DIR_sec/TEPSA.txt -mask $DIR_sec/MNI152_T1_2009c_gm_mask_rs.nii
3dttest++ -setA '4*Corr*BRIK' -setB '5*Corr*BRIK' -prefix $DIR_sec/${roi_seed}_MDD-HC_tepsC_rs -covariates $DIR_sec/TEPSC.txt -mask $DIR_sec/MNI152_T1_2009c_gm_mask_rs.nii
3dttest++ -setA '4*Corr*BRIK' -setB '5*Corr*BRIK' -prefix $DIR_sec/${roi_seed}_MDD-HC_SHAPS_rs -covariates $DIR_sec/SHAPS.txt -mask $DIR_sec/MNI152_T1_2009c_gm_mask_rs.nii

###########################################################################################
# Second-level analysis: getting the seed-to-wholebrain FC maps
# Extract out FC values with certain regions 
ind_seed=cg25_2 # cg_3
DIR_rest=/sc/arion/projects/K01_VTA/users/lim39/rest
DIR_roi=/sc/arion/projects/K01_VTA/users/lim39/rest/ROI
DIR_seed=$DIR_rest/${ind_seed}_blur3
DIR_sec=$DIR_seed/secondlevel

cp $DIR_rest/subj_folders.txt $DIR_sec
cd $DIR_sec

for area in bil-IFC DCaud dmPFC3 antPFC2 hipp_thr sgACC5 dACC2 VTA_mni; do
    while IFS= read -r subj; do
        echo "Processing subject: $subj"
        
        # Resample ROI to functional space
        3dresample -master $DIR_seed/${subj}_${ind_seed}_blur3_Corr+tlrc. -prefix ${area}_s -input $DIR_roi/${area}.nii -overwrite
        
        # Taking average FC value within second ROI, get the time seires from the ROI
        3dmaskave -quiet -mask ${area}_s+tlrc.BRIK $DIR_seed/${subj}_${ind_seed}_blur3_Corr+tlrc.BRIK >> FC-${ind_seed}-${area}.txt

    done < "subj_folders.txt"
done
