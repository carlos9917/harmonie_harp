# Copy VFLD files from ECFS for  given model
import subprocess
import os
import sys    
from pathlib import Path, PurePath

# In EC9 the data is stored under YEAR/MM
# In dini the data is stored in monthly files
datapath = {"EC9":"ec:/hlam/vfld/HRES",
           "cca_dini25a_l90_arome": "ec:/duuw/harmonie/cca_dini25a_l90_arome/vfld"}

def call_els(model,year,month):
    if "dini" in model:
        ecpath=datapath[model]
    else:
        ecpath=os.path.join(datapath[model],year,month)
    cmd="els "+ecpath
    try:
        ret = subprocess.check_output(cmd,shell=True)
        els_ret=ret.decode('utf-8').split("\n")
    except subprocess.CalledProcessError as err:
        print(f"subprocess failed with error {err}")
    #remove empty elements
    while("" in els_ret):
        els_ret.remove("")
    if "dini" in model:
        els_out = [os.path.join(datapath[model],f) for f in els_ret]
    else:
        els_out = [os.path.join(datapath[model],year,month,f) for f in els_ret]
    return els_out

def call_ecp(els_in,dest_path):
    for f in els_in:
        cmd ="ecp "+f+" "+dest_path
        try:
            ret = subprocess.check_output(cmd,shell=True)
        except subprocess.CalledProcessError as err:
            print(f"ecp failed with error {err}")
    files_copied = []
    for path in Path(dest_path).rglob('*tar.gz'):
        files_copied.append(str(PurePath(path)))
    #Sometimes the files do not have a  gz extension, doh!
    if len(files_copied) == 0:
        for path in Path(dest_path).rglob('*tar'):
            files_copied.append(str(PurePath(path)))
    return files_copied

def untar(files,destination) -> list:
    """
    Untar files copied from ecfs.
    Sometimes the directory contains only  tar.gz
    but sometimes the tar.gz are packed inside tar balls 
    Do a check after untaring files
    """
    for f in files:
        if f.endswith(".tar.gz"): 
            cmd = "cd "+destination+";tar -zxvf "+f.split("/")[-1]
        if f.endswith(".tar"): 
            cmd = "cd "+destination+";tar -xvf "+f.split("/")[-1]
        try:
            ret = subprocess.check_output(cmd,shell=True)
            ret_clean = ret.rstrip().decode('utf-8')
            print(f"Return from subprocess {ret_clean}")
        except subprocess.CalledProcessError as err:
            print(f"untar failed with error {err}")
        #Remove the tarball if tar command worked
        delete_tarball = os.path.join(destination,f)
        print(f"Removing tarball {delete_tarball} after untar")
        os.remove(delete_tarball)
    listfiles = os.listdir(destination)
    filter_tarballs = [f for f in listfiles if any(f.endswith(fend) for fend in ['.tar.gz','.tar'])]

    return filter_tarballs

def check_access(model):
    """
    Determine if the user has access to ecfs before proceeding
    """
    cmd = "echo $USER"
    ret = subprocess.check_output(cmd,shell=True)
    USER = ret.rstrip().decode('utf-8')
    try:
        ecpath=datapath[model]
        cmd="els "+ecpath
        ret = subprocess.check_output(cmd,shell=True)
        els_ret=ret.decode('utf-8').split("\n")
        status = True
    except subprocess.CalledProcessError as err:
        print(f"els command failed with error {err}")
        print(f"{USER} does not seem to have access to this path!")
        status = False
    return status
    

    
  
if __name__ == "__main__":
    MODEL="cca_dini25a_l90_arome"
    YEAR="2021"
    MONTH="09"
    OUTDIR="/scratch/ms/ie/duuw/vfld_vobs_sample/extract_temp/"
    els_in = call_els(MODEL,YEAR,MONTH)
    call_ecp(els_in,OUTDIR)
