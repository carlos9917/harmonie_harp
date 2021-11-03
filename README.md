# Harmonie_harp
harp scripts for plotting score cards for the Early Common DINI Suite (ECDS)

## scr
R scripts to call harp and plot score cards

## transfer

Some scripts to transfer vfld files from ecfs and 
also to copy files from user nhd and transfer plots to hirlam.org

Models used up to now
cca_dini25a_l90_arome
EC9

### STILL TO DO:
vobs data needs to be copied by hand. I guess I could copy
from EC9 path, but the data will be huge.
Currently copying from runnig cca_dini model
### Known issues:
Apparently duuw cannot access EC9 data via els:
```
duuw@ecgb11:~/harmonie_harp> els ec:/hlam/vfld/HRES/2021
els: Unable to stat file: /hlam/vfld/HRES/2021 - Permission denied

```

On the other hand, other users might not be able to access data from
duuw!

```
[nhd@ecgb11 harmonie_harp]$ els ec:/duuw/harmonie
els: List of directory /duuw/harmonie: Permission denied

```

