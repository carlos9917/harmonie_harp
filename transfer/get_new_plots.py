"""
Check if there is a new file produced by duuw
and send it to my hirlam account
""" 
from rich import print
from datetime import date
from pathlib import Path, PurePath
import subprocess
import glob

def copy_over_plots(filepath,localpath):

    path = Path(filepath)
    timestamp = date.fromtimestamp(path.stat().st_mtime)
    if date.today() == timestamp:
        print(f"copying {filepath} to {localpath} (modified on {timestamp})")
        cmd = "cp "+filepath + " "+localpath
        try:
            ret = subprocess.check_output(cmd,shell=True)
        except subprocess.CalledProcessError as err:
            print("{cmd} failed with {err}")

if __name__ == "__main__":
    import argparse
    from argparse import RawTextHelpFormatter
    parser = argparse.ArgumentParser(description='''
     Example usage: python3 get_new_plots.py -origin path1 -dest path'''
            , formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-origin',help='Where I am copying the files from',
                        type=str,
                        default=None,
                        required=True)
    parser.add_argument('-dest',help='Where I am copying the files to',
                        type=str,
                        default=None,
                        required=True)
    args = parser.parse_args()
    duuwpath=args.origin
    localpath=args.dest
    #duuwpath = "/home/ms/ie/duuw/harmonie_harp/scr/"
    #localpath = "/home/ms/dk/nhd/scripts/harmonie_harp/transfer"
    files=[]
    for path in Path(duuwpath).rglob('*png'):
        files.append(str(PurePath(path)))
    for f in files:
        copy_over_plots(f,localpath)
