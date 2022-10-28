"""
Copy vobs files, either fro
"""

import os
import sys
import subprocess

def untar(files,destination):
    cdir=os.getcwd()
    os.chdir(destination)
    for f in files:
        cmd = "tar -zxvf "+f.split("/")[-1]
        try:
            ret = subprocess.check_output(cmd,shell=True)
        except subprocess.CalledProcessError as err:
            print(f"untar failed with error {err}")
    os.chdir(cdir)


def copy_files(YYYY,MM,DD,OPATH,DEST):
    import shutil
    files=os.listdir(OPATH)
    untarfiles=[]
    for f in files:
        pref="vobs"+YYYY+MM
        if DD != None: pref=pref+DD
        if f.startswith(pref):
            shutil.copy(os.path.join(OPATH,f),os.path.join(DEST,f))
            untarfiles.append(os.path.join(DEST,f))
    check_files = [f for f in untarfiles if f.endswith(".tar.gz")]
    if len(check_files) == 0:
        print("No need to untar")  
        return
    else:
        untar(untarfiles,DEST)

if __name__== '__main__':
    import argparse
    from argparse import RawTextHelpFormatter
    parser = argparse.ArgumentParser(description='''
            Example usage: python3 copy_vobs_files.py -date 202110 -vobs_path VOBSPATH'''
            , formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-date',metavar='date in YYYYMMDD if YYYYMM given, copy whole month',
                        type=str,
                        default=None,
                        required=True)

    parser.add_argument('-dest',metavar='Destination of vobs files',
                        type=str,
                        default="/scratch/ms/dk/nhd/vfld_sample/vobs",
                        required=False)

    parser.add_argument('-orig',metavar='Origin of of vobs files',
                        type=str,
                        default="/scratch/ms/dk/nhz/oprint/",
                        required=False)

    parser.add_argument('-sqlpath',metavar='path where SQL files are stored',
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



    DEST=args.dest #destination
    OPATH=args.orig #Origin of the files
    print(f"Collecting local vobs data for period {YYYY}{MM}{DD} from {OPATH}")
    copy_files(YYYY,MM,DD,OPATH,DEST)


