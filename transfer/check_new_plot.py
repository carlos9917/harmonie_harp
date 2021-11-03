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
    duuwpath = "/home/ms/ie/duuw/harmonie_harp/scr/"
    files=[]
    for path in Path(duuwpath).rglob('*png'):
        files.append(str(PurePath(path)))
    localpath = "/home/ms/dk/nhd/scripts/harmonie_harp/transfer"
    for f in files:
        copy_over_plots(f,localpath)
