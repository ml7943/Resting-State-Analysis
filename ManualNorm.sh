###############################
## Manual Normalization script: reivised by Mu L from Sarah's and Jackie's scripts, Oct 6, 2023
## Normalization for resting-state data
# uniden file: *_uni.nii from xnat
# subject 515, 516, MPRAGE INSTEAD OF MP2RAGE
# acf notes are in the laurel/scripts/acf notes try with -detrend or without -detrend
# for acf, use the ball one
# acf only run on a few subjects
##### REMEMBER TO run the gray mask on the second level analysis #####
###############################
ml libGLw
ml libpng/12
# ml afni/22.3.03
ml afni/21.0.02
ml python/2.7.17

###### !!!!change all blur == 4 !!!! ###############

'''
the purpose of this script is to perform normalization manually using some of the outputs from the preprocessed data in Sapient
- this requires the following files: 
1) template anat file MNI152_T1_2009c+tlrc.
2) *_uni.nii native anatomical image without skull strip
3) native EPI downloaded from sapient or output from MEICA (e.g., *T1c_medn_nat.nii.gz)
4) Convert the AFNI files (.HEAD, .BRIK) to NIFTI files (.nii) (not required)
5) Smooth the tlrc by 5mm for cluster size calculation
6) Cluster size calculation, output will be in the text file, but not required for all subjects
'''

cd /sc/arion/projects/K01_VTA/users/lim39/rest
# Don't need to have subject list text file here, use awk to get a list of all folders only contain numbers in the current directory
# Get the subject list under current directory
subj_list=$(find ./ -maxdepth 1 -type d | awk -F/ '$NF ~ /^[0-9]*$/ {print $NF}')
echo "Subject list under current directory: $subj_list"

#### Only run once to create folders and copy all required files
# Create the empty list for subjects with all required files
subjWfile=""

# Other norm has finished, so manually build a norm list:
# subj_list="423 450 451 453 454 455 512 521 544 545 546 547 548 549 550 526 530"
# mv rest_T1c_medn_epi.nii.gz manual_rest_T1c_medn_nat.nii.gz # change the name of manual meica output
# 423 455 530
# mv rest_T1c_medn_nat.nii.gz rest_T1c_medn_nat_pre.nii.gz # change the name not delete the previous rest_T1c_medn_nat file
# 455 453 544


# Prepare the required files for each subject
for i in $subj_list; do
  # rm -r "/sc/arion/projects/K01_VTA/users/lim39/rest/$i/ManualNorm_Mu" # remove previous folder first
  # Check if we have all required files for subject $i
  if [ -e "/sc/arion/projects/K01_VTA/users/lim39/rest/MNI152_T1_2009c+tlrc.BRIK.gz" ] && \
     [ -e "/sc/arion/projects/K01_VTA/users/lim39/rest/MNI152_T1_2009c+tlrc.HEAD" ] && \
     [ -e "/sc/arion/projects/K01_VTA/users/lim39/rest/$i"/*_T1c_medn_nat.nii.gz ] && \
     [ -e "/sc/arion/projects/K01_VTA/users/lim39/rest/$i/${i}_uni.nii" ]; then
    # If we have all required files, then create the subfolders under each subject folder
    mkdir -p "/sc/arion/projects/K01_VTA/users/lim39/rest/$i/ManualNorm_Mu"
    # Copy the required files to the Normalization folder under each subject folder
    cp "/sc/arion/projects/K01_VTA/users/lim39/rest/MNI152_T1_2009c+tlrc.BRIK.gz" \
       "/sc/arion/projects/K01_VTA/users/lim39/rest/MNI152_T1_2009c+tlrc.HEAD" \
       "/sc/arion/projects/K01_VTA/users/lim39/rest/$i/"*_T1c_medn_nat.nii.gz \
       "/sc/arion/projects/K01_VTA/users/lim39/rest/$i/${i}_uni.nii" \
       "/sc/arion/projects/K01_VTA/users/lim39/rest/$i/ManualNorm_Mu/"
    ## Rename the *_T1c_medn_nat.nii.gz file to rest_T1c_medn_nat.nii.gz
    #old_file="/home/laurel/data/K01/proc/rest/$i/ManualNorm_Mu/"*_T1c_medn_nat.nii.gz
    #new_file="/home/laurel/data/K01/proc/rest/$i/ManualNorm_Mu/rest_T1c_medn_nat.nii.gz"
    #mv "$old_file" "$new_file"
    # Add the current subject to the list, to get the valid subject list
    subjWfile="$subjWfile $i"
  fi
done

# print the subjects with all required files
echo "Subjects with all required files: $subjWfile"
# Save the subjects with all required files to a text file
output_file="/sc/arion/projects/K01_VTA/users/lim39/rest/Norm_Valid_SubjList.txt"
echo "Subjects with all required files: $subjWfile" > "$output_file"
# Make sure the file is saved
echo "Valid norm subject list saved to: $output_file"

#### Run the normalization for each subject
for d in $subjWfile; do
    # cd to each subject's norm folder
    cd "/sc/arion/projects/K01_VTA/users/lim39/rest/$d/ManualNorm_Mu"
    # Step 1: skullstrip the T1 & put into MNI space; output of interest is uni_at.nii
    @auto_tlrc -base MNI152_T1_2009c+tlrc. -input ${d}_uni.nii -overwrite # input is the native T1 with skull, if you want to include the skull-strip T1, then add -no_ss
    # Step 2: Align functional to anatomical image, reference is the anatomical image in MNI space *_uni_at.nii, output of interest is _tlrc_a12anat
    # no mask version
    align_epi_anat.py -anat ${d}_uni.nii -epi *_T1c_medn_nat.nii.gz -epi_base 5 -ex_mode quiet -epi2anat -suffix _a12anat -tlrc_apar ${d}_uni_at.nii -overwrite
    # mask version
    # align_epi_anat.py -anat ${d}_uni.nii -epi *_T1c_medn_nat.nii.gz -epi_base 5 -ex_mode quiet -epi2anat -epi_strip None -mask MNI_caez.nii -suffix _a12anat -tlrc_apar ${d}_uni_at.nii -overwrite
    # Step 3: Smooth the tlrc by 5mm
    # AFNI file to NIFTI file (not required)
    # 3dAFNItoNIFTI *_a12anat+tlrc. -prefix _T1c_medn_nat_tlrc_al2anat.nii
    # Smooth by automask and nifti file (not required, since we could input the .HEAD file directly)
    # 3dBlurToFWHM -FWHM 5 -prefix a12anat_tlrc_blur.nii -input *_T1c_medn_nat_tlrc_al2anat.nii -automask
    # Smooth by 5mm (required)-change to 3mm
    3dBlurInMask -input *_a12anat+tlrc.HEAD -FWHM 3 -automask -prefix a12anat_tlrc_blur.nii -overwrite
    # Step 4: Calculate the ACF (only need to be done on a few subjects)
    # 3dFWHMx -acf -automask -detrend -input *_a12anat+tlrc.HEAD > acf.txt
    # Calculate the cluster size (only need to be done on a few subjects)
    # 3dClustSim -automask -acf `tail -n 1 acf.txt` -BALL -athr 0.05 -pthr 0.005 > cluster_size.txt
    cd ..
done

#### If you only want to get the blur files and calculation of cluster size on a few subjects
# cd to individual subject's norm folder
# Ex.: Subject 535
subj = 535 # changed by your subject ID
cd /home/laurel/data/K01/proc/rest/${subj}/ManualNorm_Mu

# Smooth first
3dAFNItoNIFTI ${subj}_a12anat+tlrc. -prefix _T1c_medn_nat_tlrc_al2anat.nii
3dBlurInMask -input ${subj}_a12anat+tlrc.HEAD -FWHM 5 -automask -prefix a12anat_tlrc_blur.nii
# Calculate the ACF
3dFWHMx -acf -mask a12anat_tlrc_blur.nii -input ${subj}_a12anat+tlrc.HEAD > acf.txt
# Calculate the cluster size
3dClustSim -automask -acf `tail -n 1 acf.txt` -athr 0.05 -pthr 0.005 > cluster_size.txt

#### Smooth the tlrc by 6mm
# AFNI file to NIFTI file
3dAFNItoNIFTI *_a12anat+tlrc. -prefix _T1c_medn_nat_tlrc_al2anat.nii
# smooth by 5mm
3dBlurToFWHM -FWHM 5 -prefix a12anat_tlrc_blur.nii -input *_T1c_medn_nat_tlrc_al2anat.nii -automask # take place the mask, also don't run the command in the same dir twice, the output need to be overlapped

#### Check the subject list with valid output files
# Create new list for the subject list with valid output files
valid_output_list=""

for vsub in $subjWfile; do
  # set output file path
  output_file_path=$(find "/home/laurel/data/K01/proc/rest/$vsub/ManualNorm_Mu/" -name "*_T1c_medn_nat_tlrc_a12anat+tlrc.HEAD")

  # Check if the output file exists
  if [ -n "$output_file_path" ]; then
    # If the output file exists, then add the current subject to the list
    valid_output_list="$valid_output_list $vsub"
  fi
done

# Echo the valid subject list
output_path="/home/laurel/data/K01/proc/rest/Output_Valid_SubjList.txt"
echo "Subjects with all required files: $valid_output_list"
echo "Subjects with all required files: $valid_output_list" > "$output_path"
echo "Subject list with valid output saved to: $output_path"

# 3dblurinmask command, directly input is .HEAD, GM mask, -FWHM 6, -prefix: NOT USE IN THE FIRST LEVEL ANALYSIS, use it in second level, and Laurel ran it in 535 norm folder. name should be GMmask...
# for the GM mask, use the MNI152_T1_2009c and do the segmentation to get GM part - done by laurel
# check for 3dBlurToFWHM -input: ddd = This required 'option' specifies the dataset that will be smoothed and output.
# First-level: 3dblurinmask -automask -FWHM 5...

# 1. add all subject including XNAT
# 2. run the automask and blur for all subjects
# 3. check the acf command input should be smooth or non-smooth one
# 4. check the cluster size for both smooth and non-smooth one
# 5. finish the normalization for all subjects

#### Option 2: run the Normalization for specific subjects
cd /home/laurel/data/K01/proc/rest
subj=534 # changed by your subject ID
mkdir -p "/home/laurel/data/K01/proc/rest/$subj/ManualNorm_Mu"
cp "/home/laurel/ROI/MNI152_T1_2009c+tlrc.BRIK.gz" "/home/laurel/ROI/MNI152_T1_2009c+tlrc.HEAD" "/home/laurel/data/K01/proc/rest/$subj/"*_T1c_medn_nat.nii.gz "/home/laurel/data/K01/proc/rest/$subj/${subj}_uni.nii" "/home/laurel/data/K01/proc/rest/$subj/ManualNorm_Mu/"
cd "/home/laurel/data/K01/proc/rest/$subj/ManualNorm_Mu"
# Step 1: skullstrip the T1 & put into MNI space; output of interest is uni_at.nii
@auto_tlrc -base MNI152_T1_2009c+tlrc. -input ${subj}_uni.nii # input is the native T1 with skull, if you want to include the skull-strip T1, then add -no_ss
# Step 2: Align functional to anatomical image, reference is the anatomical image in MNI space *_uni_at.nii, output of interest is _tlrc_a12anat
align_epi_anat.py -anat ${subj}_uni.nii -epi *_T1c_medn_nat.nii.gz -epi_base 5 -partial_axial -ex_mode quiet -epi2anat -suffix _a12anat -tlrc_apar ${subj}_uni_at.nii

## Not for all subjects
# Step 3: Smooth the tlrc by 5mm
# AFNI file to NIFTI file (not required)
3dAFNItoNIFTI *_a12anat+tlrc. -prefix _T1c_medn_nat_tlrc_al2anat.nii
# Smooth by automask and nifti file (not required, since we could input the .HEAD file directly)
# 3dBlurToFWHM -FWHM 5 -prefix a12anat_tlrc_blur.nii -input *_T1c_medn_nat_tlrc_al2anat.nii -automask
# Smooth by 5mm (required)
3dBlurInMask -input *_a12anat+tlrc.HEAD -FWHM 5 -automask -prefix a12anat_tlrc_blur.nii
# Step 4: Calculate the ACF (only need to be done on a few subjects)
3dFWHMx -acf -automask -detrend -input *_a12anat+tlrc.HEAD > acf.txt
# Calculate the cluster size (only need to be done on a few subjects)
3dClustSim -automask -acf `tail -n 1 acf.txt` -BALL -athr 0.05 -pthr 0.005 > cluster_size.txt
cd ..

#### Option 3: run the Normalization for specific subjects with cutoff image
cd /home/laurel/data/K01/proc/rest
subj=532 # changed by your subject ID
mkdir -p "/home/laurel/data/K01/proc/rest/$subj/ManualNorm_Mu"
cp "/home/laurel/ROI/MNI152_T1_2009c+tlrc.BRIK.gz" "/home/laurel/ROI/MNI152_T1_2009c+tlrc.HEAD" "/home/laurel/data/K01/proc/rest/$subj/"*_T1c_medn_nat.nii.gz "/home/laurel/data/K01/proc/rest/$subj/${subj}_uni.nii" "/home/laurel/data/K01/proc/rest/$subj/ManualNorm_Mu/"
cd "/home/laurel/data/K01/proc/rest/$subj/ManualNorm_Mu"
# Step 1: skullstrip the T1 & put into MNI space; output of interest is uni_at.nii
@auto_tlrc -base MNI152_T1_2009c+tlrc. -input ${subj}_uni.nii -overwrite # input is the native T1 with skull, if you want to include the skull-strip T1, then add -no_ss
# Step 2: Align functional to anatomical image, reference is the anatomical image in MNI space *_uni_at.nii, output of interest is _tlrc_a12anat
align_epi_anat.py -anat ${subj}_uni.nii -epi *_T1c_medn_nat.nii.gz -epi_base 5 -partial_axial -ex_mode quiet -epi2anat -suffix _a12anat -tlrc_apar ${subj}_uni_at.nii -overwrite #lpa is the default cost func, or -cost lpc or -edge #### methods - check 3dallineate webpage; check if -interp works
