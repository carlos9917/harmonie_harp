"""
Copy over the files from EC9 I need to verify DINI
against
For the cycle 00 we use 24h forecast
for cycles 03,06,09,12,15,18,21 only 3h forecasts
"""

import os
import sys
import subprocess

""" I personally like to use rich for pretty printing, but
 this is not a standard library for most python3 installations
 Uncomment these lines if you want to use it, as well
 as references to rich below """
#from rich import print
#from rich.progress import track
#from rich.console import Console
#from rich.theme import Theme
#console = Console(theme=Theme({"repr.number": "bold red"}))
#console.print("Test")

def copy_tarballs(YYYY,MM,DD,MODEL,OPATH,DEST):
    import shutil
    files=os.listdir(OPATH)
    untarfiles=[]
    for f in files:
        pref="vfld"+MODEL+YYYY+MM
        if DD != None: pref=pref+DD
        if f.startswith(pref):
            shutil.copy(os.path.join(OPATH,f),os.path.join(DEST,f))
            untarfiles.append(os.path.join(DEST,f))
    check_files = [f for f in untarfiles if f.endswith("tar.gz")]
    if len(check_files) == 0:
        print("No need to untar")
        return
    else:
        import ecfs_copy as ecf
        ecf.untar(untarfiles,DEST)
    #delete the files
    for f in files:
        if f.endswith("tar.gz"):
            this_file = os.path.join(DEST,f)
            if os.path.isfile(this_file):
                print(f"Deleting {this_file}")
                os.remove(this_file)

def delete_analysis_files(datadir,model):
    """
    Remove analysis files, which have name with length vfldMODELYYYYMMDDCC
    Example. This file I want
    vfldcca_dini25a_l90_arome202109270303
    This file I don't
    vfldcca_dini25a_l90_arome2021091909  
    """
    SHORTLEN=10 #these are the short ones
    files=os.listdir(datadir)
    delete_files=[]
    for f in files:
        this_file = os.path.join(datadir,f)
        date = f.replace("vfld"+model,"")
        if (len(date) == SHORTLEN
          and not this_file.endswith(".tar")
          and not this_file.endswith(".gz")):
            print(f"Removing analysis file {this_file}")
            os.remove(this_file)

def select_dtg(YYYY,MM,DD,MODEL):
    """
    Select the files I need, otherwise too many (for example for EC9)
    Remember naming convention goes like
    vfldcca_dini25a_l90_arome202109250003
    YYYYMMDDCCHH
    where CC is for the cycle (or I what I call the init time)
    cycles 00 and 12 are 24h forecasts, otherwise 3h
    There should be 74 elements for each day
    """
    from calendar import monthrange
    if DD == None:
        ndays = monthrange(int(YYYY),int(MM))[1]
        days=[str(d).zfill(2) for d in range(1,ndays+1) ]
    else:
        days=[DD]
    cycles=[str(i).zfill(2) for i in range(0,22,3)]
    dates = [YYYY+MM+d for d in days]
    dtg=[]
    for d in dates:
        for cycle in cycles:
            if cycle == "00" or cycle == "12":
                temp = [d + cycle + str(h).zfill(2) for h in range(0,25)]
            else:
                temp = [d + cycle + str(h).zfill(2) for h in range(0,4)]
            dtg.extend(temp)
    return dtg

def sel_copy_vfld_files(YYYY,MM,DD,MODEL,OPATH):
    allfiles=os.listdir(OPATH)
    copy_files=[]
    ftimes=[]
    vpref="vfld"+MODEL
    valid_dtg= select_dtg(YYYY,MM,DD,MODEL)
    cycles=[str(i).zfill(2) for i in range(0,22,3)]
    print(f"NOTE: Copying only files for cycles: {cycles} ")
    #rich printing
    #print(f"NOTE: Copying only files for cycles: {cycles} ",style="red")
    #console.print(f"NOTE: Copying only files for cycles: {cycles} ",style="red")
    #only using rich. uncomment this and indent next loop
    #for n in track(range(100), description=f"Selecting files for {YYYY} {MM} from {OPATH}..."):
    for f in allfiles:
        #only take files with selected cycles and with date length 12
        this_dtg = f.split(vpref)[-1]
        if this_dtg in valid_dtg:
            copy_files.append(os.path.join(OPATH,f))
    #rich printing
    #console.print(f"Selected {len(copy_files)} to copy",style="red")
    #print(f"Selected {len(copy_files)} to copy",style="red")
    print(f"Selected {len(copy_files)} to copy")
    for f in copy_files:
        try:
            file_only=f.split("/")[-1]
            dest_file = os.path.join(DEST,file_only)
            cmd = "cp "+f+" "+DEST+"; chmod 755 "+dest_file
            if not os.path.isfile(dest_file):
                ret=subprocess.check_output(cmd,shell=True)
                #print(cmd)
            else:
                print(f"{dest_file} already copied!")
        except subprocess.CalledProcessError as err:
            print(f"subprocess failed with error {err}")

def clean_vfld_files(YYYY,MM,DD,MODEL,DEST):
    """
    Delete the files I dont need after I copied them from ecfs
    """
    if DD == None:
        print(f"Not cleaning files for {YYYY}{MM} {DD}")
        print("since I do not know precise day")
        return
    allfiles=os.listdir(DEST)
    vpref="vfld"+MODEL
    valid_dtg= select_dtg(YYYY,MM,DD,MODEL)
    delete_files=[]
    keep_files=[]
    keep_files=[f for f in allfiles if f.split(vpref)[-1] in valid_dtg]
    #print(f"Only keeping these")
    #print(sorted(keep_files))
    files=[f for f in allfiles if f.split(vpref)[-1][0:8] == YYYY+MM+DD]
    delete_files=[os.path.join(DEST,f) for f in files if f not in keep_files]
    for f in delete_files:
        if os.path.isfile(f):
            print(f"Deleting {f}")
            #os.remove(f)


if __name__== '__main__':
    import argparse
    from argparse import RawTextHelpFormatter
    parser = argparse.ArgumentParser(description='''
            Example usage: python3 count_dkrea_split.py -year 2021 -month 10 -model EC9 -vpath VFLDPATH'''
            , formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-date',metavar='date in YYYYMMDD if YYYYMM given, copy whole month',
                        type=str,
                        default=None,
                        required=True)

    parser.add_argument('-model',metavar='model (ie, EC9, dini)',
                        type=str,
                        default="EC9",
                        required=False)
    parser.add_argument('-dest',metavar='Destination of vfld files',
                        type=str,
                        default="/scratch/ms/dk/nhd/vfld_sample/",
                        required=False)
    parser.add_argument('-orig',metavar='Origin of of vfld files',
                        type=str,
                        default="/scratch/ms/dk/nhz/oprint/",
                        required=False)
    parser.add_argument('-sqlpath',metavar='Path where SQLite files are stored',
                        type=str,
                        default=None,
                        required=False)

    args = parser.parse_args()
    if args.date == "auto":
        if args.sqlpath == None:
            print(f"Please provide path for the sql files when using {args.date}")
            sys.exit(1)
        #determine year, month and date from sql file
        import sql_utils as squ
        date = squ.find_last(args.sqlpath,"vfld")
        #now get day after, since the one above is last date in file
        from datetime import datetime as dt
        from datetime import timedelta as tdelta
        day_after = dt.strftime(dt.strptime(date,"%Y%m%d") + tdelta(days=1),"%Y%m%d")
        YYYY = day_after[0:4]
        MM = day_after[4:6]
        DD = day_after[6:8]
    else:
        YYYY= args.date[0:4]
        MM = args.date[4:6]
        #NOTE: the date option will only work with local data!
        DD=None #change below if given
        if len(args.date) == 8: DD = args.date[6:8]
    print(f"{args.date} given, with year={YYYY}, month={MM}, day={DD}")
    MODEL = args.model
    DEST=os.path.join(args.dest,MODEL) #Destination
    #Doing this when I need to copy data from Xiaohuas account and chmod the files as nhd.
    #Otherwise using ecfs
    if args.orig != "ecfs":
        #OPATH=os.path.join(args.orig,MODEL) #Origin of the files
        OPATH=args.orig #Origin of the files
        print(f"Collecting local data for {MODEL} and period {YYYY}{MM} from {OPATH}")
        #When copying locally, first I select the tarballs, and untar them (if needed)
        copy_tarballs(YYYY,MM,DD,MODEL,OPATH,DEST)
        #Then I copy the selected DTGs I need
        sel_copy_vfld_files(YYYY,MM,DD,MODEL,DEST)
        #Then I delete the analysis files I do not need
        delete_analysis_files(DEST,MODEL)
    elif args.orig == "ecfs":
        import ecfs_copy as ecf
        #First check if user has access to this path:
        if ecf.check_access(MODEL):
            #DEST="/scratch/ms/ie/duuw/vfld_vobs_sample/extract_temp/"
            print(f"Extracting data from ECFS for {MODEL} and period {YYYY}{MM}")
            els_in = ecf.call_els(MODEL,YYYY,MM)
            tarcopied = ecf.call_ecp(els_in,DEST)
            check_files = ecf.untar(tarcopied,DEST)
            #sometimes data is in tar.gz, sometimes it is just a tar
            if len(check_files) != 0: 
                check_again = ecf.untar(check_files,DEST)
            clean_vfld_files(YYYY,MM,DD,MODEL,DEST)
            if MODEL != "EC9": #avoid this for the moment
                delete_analysis_files(DEST,MODEL)
            #for f in tarcopied:
            #    this_file=os.path.join(DEST,f)
            #    if this_file.endswith("tar.gz") and os.path.isfile(this_file):
            #        print(f"Deleting tarball {this_file}")
            #        #os.remove(this_file)

        else:
            print("Error calling els")
            sys.exit(1)
    else:
        print(f"Copy option {args.orig} unknwon")
        sys.exit(1)
