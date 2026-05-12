This is a U-Net trained to make a set of useful predictions from any 3D brain image
(in vivo, ex vivo, single hemispheres, etc) using a common backbone/ It predicts:
- Segmentation:
- Registration to MNI atlas
- Joint super-resolution and synthesis of 1mm isotropic T1w, T2w, and FLAIR scans. 

The code relies on:
"A Modality-agnostic Multi-task Foundation Model for Human Brain Imaging"
Liu et al. (under revision)

##  Usage: 

The entry point / main script is mri_super_synth. There are two way of running the code:

A. For a single scan: just provide input file with --i, output directory with --o, and type of volume with --mode.

B. For a set of scans: you need to prepare a CSV file, where each row has 3 columns separated with commas:
- Column 1: input file
- Column 2: output directory
- Column 3: mode (must be invivo, exvivo, cerebrum, left-hemi, or right-hemi)

Please note that there is no leading/header row in the CSV file. The first row already corresponds to an input volume.
Tip: you can comment out a line by starting it with #

Important note: as opposed to the earlier versions of SuperSynth, inference is not tiled anymore.

The command line options are:

  --i [IMAGE_OR_CSV_FILE]
                        Input image to segment - mode A - or CSV file with list of scans - mode B (required argument)

  --o [OUTPUT_DIRECTORY]
                        Directory where outputs will be written (ignored in mode B)

  --mode [MODE]
                        Type of input. Must be invivo, exvivo, cerebrum, left-hemi, or right-hemi (ignored in mode B)

  --threads [THREADS]     
                        Number of cores to be used. You can use -1 to use all available cores. Default is -1 (optional)

  --device [DEV]     
                        Device used for computations (cpu or cuda). The default is to use cuda if a GPU is available (optional)
                        
  --sharpen_synths     
                        Sharpens the Synth-T1/-T2/-FLAIR predictions (optional)



## Prerequisites:

The first time you run the method, it will prompt you to download the machine learning model files, which are not distributed with the code.

## Standalone install (without full FreeSurfer), including Apple Silicon (M4)

SuperSynth can run with a minimal `FREESURFER_HOME` that only includes:

- `python/packages/SuperSynth/...`
- `models/SuperSynth_August_2025.pth`
- `FreeSurferColorLUT.txt` at the root of `FREESURFER_HOME`

### Option A (recommended): use the helper installer script

From this repository checkout:

```bash
cd /path/to/freesurfer-repo
./mri_super_synth/install_standalone_supersynth.sh \
  --dest /absolute/path/to/supersynth-standalone \
  --venv /absolute/path/to/supersynth-venv \
  --download-model
```

Then:

```bash
export FREESURFER_HOME=/absolute/path/to/supersynth-standalone
source /absolute/path/to/supersynth-venv/bin/activate
python "$FREESURFER_HOME/python/packages/SuperSynth/scripts/inference.py" --help
```

### Option B: manual setup

```bash
export STANDALONE_FS_HOME=/absolute/path/to/supersynth-standalone
mkdir -p "$STANDALONE_FS_HOME/python/packages" "$STANDALONE_FS_HOME/models"

cp -R /path/to/freesurfer-repo/mri_super_synth/SuperSynth \
  "$STANDALONE_FS_HOME/python/packages/"
cp /path/to/freesurfer-repo/distribution/FreeSurferColorLUT.txt \
  "$STANDALONE_FS_HOME/FreeSurferColorLUT.txt"

curl -fL \
  https://ftp.nmr.mgh.harvard.edu/pub/dist/lcnpublic/dist/SuperSynth_Iglesias_2025/SuperSynth_August_2025.pth \
  -o "$STANDALONE_FS_HOME/models/SuperSynth_August_2025.pth"
```

Create a Python environment and install runtime dependencies:

```bash
python3 -m venv /absolute/path/to/supersynth-venv
source /absolute/path/to/supersynth-venv/bin/activate
python -m pip install --upgrade pip
python -m pip install torch numpy scipy nibabel
```

Set `FREESURFER_HOME` and run:

```bash
export FREESURFER_HOME=/absolute/path/to/supersynth-standalone
python "$FREESURFER_HOME/python/packages/SuperSynth/scripts/inference.py" \
  --i /absolute/path/to/input.mgz \
  --o /absolute/path/to/output_dir \
  --mode invivo \
  --model_file "$FREESURFER_HOME/models/SuperSynth_August_2025.pth" \
  --device cpu
```

### Device note for M4 MacBook Air

Current SuperSynth code supports `--device cpu` and `--device cuda`.
On Apple Silicon, use `--device cpu`.
