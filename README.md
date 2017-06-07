# AssociationsGUI

[![Build Status](https://travis-ci.org/yakir12/AssociationsGUI.jl.svg?branch=master)](https://travis-ci.org/yakir12/AssociationsGUI.jl)

[![Coverage Status](https://coveralls.io/repos/yakir12/AssociationsGUI.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/yakir12/AssociationsGUI.jl?branch=master)

[![codecov.io](http://codecov.io/github/yakir12/AssociationsGUI.jl/coverage.svg?branch=master)](http://codecov.io/github/yakir12/AssociationsGUI.jl?branch=master)

`AssociationsGUI.jl` helps scientists log video files and the experiments associated with these files. It outputs four files that together contain all the information necessary to process your videos. By meticulously logging your data early-on, later stages of the data-processing can be efficiently automated.

## How to install
1. If you haven't already, install [Julia](https://julialang.org/downloads/) -> you should be able to launch it (some icon on the Desktop or some such)
2. Start Julia -> a Julia-terminal popped up
3. Copy: `Pkg.clone("git://github.com/yakir12/Associations.jl.git"); Pkg.build("Associations"); Pkg.clone("git://github.com/yakir12/AssociationsGUI.jl.git")` and paste it in the newly opened Julia-terminal, press Enter
4. To test the package (not necessary), copy: `Pkg.test("Associations"); Pkg.test("AssociationsGUI")` and paste it in the Julia-terminal, press enter
5. You can close the Julia-terminal after it's done running

## Quick start
The user's interaction with this package is via GUI. Start a Julia terminal, copy: `include(joinpath(Pkg.dir("AssociationsGUI"), "src", "BeetleLog.jl"))`, and paste it in the Julia terminal. **Note the [Troubleshooting](#troubleshooting) section for problems with starting the program.** Navigate and choose the videos folder (choose a file inside the folder and press `Open`). 

## How to use

### Rational 
Recording, processing, and analysing videos of (behavioral) experiments usually includes some kind of manual work. This manual component might only include renaming and organizing video files, but could also mean manually tracking objects, in dozens of large files across multiple projects. The purpose of this package is to standardize your data at the earliest possible stage so that any subsequent manual involvement is either avoided altogether, or would be as easy and robust as possible. This allows for streamlining the flow of your data from the original raw-format video files to the results of your analysis (e.g. figures).

A typical workflow might look like this:
1. Setup experiment 
2. Run experiment & record videos 
3. Rename videos 
4. Organize files into categorical folders 
5. Track objects in the videos 
6. Collate tracking data into their experimental context 
7. Process (camera) calibrations 
8. Process the positions (normalizing directions, origin points, relative landmarks, etc.) 
9. Run analysis on the positional data
10. Produce figures

The researcher is often required to manually perform some of these steps. While this manual involvement is insignificant in small, one-person, projects, it could introduce errors in larger projects. Indeed, in projects that involve multiple investigators, span across many years, and involve different experiments, manual organisation is simply not practical. 

**The objective of this package is to constrain and control the points where manual involvement is unavoidable.** By taking care of the manual component of the process as early as possible, we:
1. allow for greater flexibility in subsequent stages of the analysis, 
2. guarantee that the data is kept at its original form,
3. pave the way for efficient automation of later stages in the analysis.

When logging videotaped experiments, it is useful to think of the whole process in terms of 4 different "entities":
1. **Video files**: the individual video files. One may contain a part, a whole, or multiple experimental runs. 
2. **POIs**: Points Of Interest (POI) you want to track in the video, tagging *when* in the video timeline they occur (the spatial *where* in the video frame comes later). These could be: burrow, food, calibration sequence, trajectory track, barrier, landmark, disturbance, cue, trigger, stimulus, etc.
3. **Runs**: These are the experimental runs. They differ from each other in terms of the treatment, location, repetition number, species, individual specimen, etc.
4. **Associations**: These describe how the **POI**s are associated to the **run**s. The calibration POI could for example be associated to a number of runs, while one run might be associated with multiple POIs (e.g. in one of the experiments you had multiple POIs: a burrow, a feeder, and a track).

By logging the video files and their dates, tagging the POIs, registering the various experimental runs you conducted, and noting the associations between these POIs and runs, we log *all* the information necessary for efficiently processing our data. If the objects in your videos can be tracked automatically then no further manual involvement is necessary. If the nature of the videos and objects in them prohibits automatic tracking, manual tracking of the objects can now be conveniently semi-automated. 

### File hierarchy
To tag the POIs, the user must supply the program with a list of possible POI-tags. This list should include all the possible names of the POIs. Similarly, the program must have a list of all the possible metadata for the experimental runs. This is achieved with two necessary `csv` files: `poi.csv` and `run.csv`.

The program will process all the video files within a given folder. While the organization of the video files within this folder doesn't matter at all (e.g. video files can be spread across nested folders), **the videos folder *must* contain another folder called `metadata`. This `metadata` folder *must* contain the `poi.csv` and `run.csv` files:**

```
videos_folder
│   some_file
│   some_video_file
│   ...
│
└───metadata
│       poi.csv
│       run.csv
│   
└───some_folder
    │   some_video_file
    │   other_video_file
    │   ...
    │   
    ...
```

The `poi.csv` file contains all the names of the possible POIs separated with a comma `,`. For example:

```
Nest, Home, North, South, Pellet, Search, Landmark, Gate, Barrier, Ramp
```
The `run.csv` file contains all the different categories affecting your runs as well as their possible values. Note how the following example file is structured:
```
Species, Scarabaeus lamarcki, Scarabaeus satyrus, Scarabaeus zambesianus, Scarabaeus galenus
Field station, Vryburg Stonehenge, BelaBela Thornwood, Pullen farm, Lund Skyroom
Experiment, Wind compass, Sun compass, Path integration, Orientation precision
Plot, Darkroom, Tent, Carpark, Volleyball court, Poolarea
Location, South Africa, Sweden, Spain
Condition, Transfered, Covered
Specimen ID,
```
Each row describes a metadatum. The first value (values are separated by a comma *`.csv`: comma separated values*) describes the name of that specific metadatum. The values following that are the possible values said metadatum can have. For instance, in the example above, `Condition` can take only two values: `Transfered` or `Covered`. In case the metadatum can not be limited to a finite number of discrete values and can only be described in free-text, leave the following values empty (as in the case of the `Specimen ID` in the example above). **Note: There is no need to include a `Comment` metadatum in the `run.csv` file. A `Comment` section is included in all Runs.**

You can have as many or as few metadata as you like, keeping only the metadata and POIs that are relevant to your specific setups. This flexibility allows the user to keep different `poi.csv` and `run.csv` metadata files in each of their videos folders.

Note that apart from the requirement that a `metadata` folder contain the two `poi.csv` and `run.csv` files, **the values in these files must be delimited by a comma** (as shown in the example above). You can produce these two files using your favourite word editor (or excel), but make sure the file extension is `csv` and that the delimiter is a comma.

An example of this file hierarchy, the metadata folder, and the two `csv` files is available [here](test/videofolder).

### Instructions
Once you've created the `metadata` folder and the two `csv` files in your videos folder (i.e. the folder that contains all the videos that you want to log), start the program (see [here](#Quick start)). After launching the program, a new window will appear, where you can add new POIs, Runs, and assign their appropriate associations. 

In the initial window you'll have two plus signs, `+`, to press on. The one to the top-right adds new POIs. The lower-left plus adds new Runs.

**POI section:** In the POI section the user can choose a specific POI to log: a video file and time stamp where the POI starts, a video file and time stamp where the POI ends, an optional label to tag the POI with (helps remembering stuff), and an optional comment. Pressing on the `>` button starts playing the chosen video in the background. Note that the `Done` button will not let you add a POI with a start time that is later than a stop time if the start and stop files are the same file (in fact, the stop time automatically adjusts when you set the start time). Nor would it work if you try to add a POI that already exists in the dataset: all POIs must be unique. Every time you press `Done` in the POI panel, the program will try to guess the temporal location of the next POI, updating the start and stop times accordingly. 

**Run section:** In the Run section the user can edit a run by setting the correct metadata and pressing `Done`. The `Comment` field in the Run section is permanent (but feel free to leave it empty). You'll notice that when adding identical runs (i.e. runs that are identical irrespective of their comments) the added runs are assigned with a repetition number (the last number in the Run's label). If you `Delete` or `Edit` a Run, the repetition numbers of the other identical runs will update accordingly. 

After adding some POIs and Runs, the Associations section will be populated with rows of runs and columns of POIs. Use the checkboxes to indicate the associations between the Runs and POIs. 

By clicking on a Run or POI, you can choose to: 
1. `Check`: check all the associations for all the Runs/POIs for that specific POI/Run (like checking a row/column) 
2. `Uncheck`: uncheck all the associations for all the Runs/POIs for that specific POI/Run (like checking a row/column) 
3. `Edit`: the POI/Run console will get populated with the details of the POI/Run you want to edit, change the details you like and press `Done`.
4. `Delete`: permanently deletes a specific POI/Run.

When done, press `Save`. To clear the board and start from scratch press `Clear`. 

Next, the program will attempt to automatically extract the original filming dates and times of the video files. It is however *imperrative* that you make sure these estimates are indeed correct. You will therefore be presented with another window containing all the videos you logged and their estimated dates and times. Adjust these accordingly (pressing the video filename starts playing the video). When finished press `Done`.

That is all! You will now find a new folder, `log`, in the videos folder with 4 files in it: 
1. `files.csv`: all the video file names, dates and times of when the video was recorded.
2. `pois.csv`: all the POI names, the video file where this POI started, the start time (in seconds), the video file where this POI ended, the stop time (in seconds), the POI's label, and eventual comments.
3. `runs.csv`: All the metadata and their values in the logged runs. The last field is the number of replicates for each of the runs (calculated automatically).
4. `associations.csv`: A two column table where the first column is the POI number and the second column is the Run number (both relative to the row numbers in the `pois.csv` and `runs.csv` files, excluding the header row of course). 

If you need to add video files, POIs, or metadata for the Runs, you can do so even after finishing logging some data. While you can always remove POIs from the `poi.csv` file, you can not remove any of the metadata in the `run.csv` file, nor should you delete any of the video files.   
## Troubleshooting
- *The initial navigation window is stuck, I can't choose the videos folder*
If this happens you'll have to run the program from within Julia:
    1. Start a Julia-terminal
    2. Copy and paste the following code in the Julia-terminal:
       ```julia
       using AssociationsGUI
       folder = "<videos folder>"
       main(folder)
       ```
       where `<videos folder>` is the path to the folder that contains all the videos you want to log (so replace `<videos folder>` with the actual path to your videos folder). 
    3. The program will run normally, and you can close the Julia terminal when you're done logging your videos.
