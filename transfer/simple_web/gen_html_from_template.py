from jinja2 import Environment, FileSystemLoader
import os
import sys
root = os.path.dirname(os.path.abspath(__file__))
templates_dir = os.path.join(root, 'templates')
env = Environment( loader = FileSystemLoader(templates_dir)  )

#template = env.get_template('index.html')


#Crude argument reading. Only two options
#period = "20210907-20210928"
#model="EC9"
if len(sys.argv) == 1:
    print("Please provide model, period and domain. Ex: EC9 20210901-20210930 DINI")
    print("WARNING: NOT CHECKING arguments at this moment")
    sys.exit(1)
else:
    model = sys.argv[1]
    period = sys.argv[2]
    domain = sys.argv[3]
    score_type = sys.argv[4]

# change the timestamp in index.html
template = env.get_template('index.html')
filename = os.path.join(root, 'html', 'index.html')
from datetime import datetime
lastmodified = datetime.strftime(datetime.now(),"%Y/%m/%d %H:%M:%S")
with open(filename, 'w') as fh:
    fh.write(template.render(
         lastmodified = lastmodified
        			))
sys.exit(1)

#Modify the html template for score cards
template = env.get_template('scorecards.html')
if domain == "DINI":
    filename = os.path.join(root, 'html', 'scorecards.html')
    with open(filename, 'w') as fh:
        fh.write(template.render(
             model = model,
             period = period.replace("_"," to "),
             pngfile="scorecards_"+period+".png"
        
        			))
else:
    filename = os.path.join(root, 'html', 'scorecards_'+domain+'.html')
    with open(filename, 'w') as fh:
        fh.write(template.render(
             model = model,
             period = period.replace("_"," to "),
             #pngfile="scorecards_"+period+"_"+domain+".png",
             pngfile="scorecards_"+domain+"_"+period+".png",
             domain = domain
        			))

#Modify the html template for standard scores
template = env.get_template('scores.html')
if domain == "DINI":
    filename = os.path.join(root, 'html', 'scores.html')
    with open(filename, 'w') as fh:
        fh.write(template.render(
             model = model,
             pngt2m="bias_stde_T2m_"+period+".png",
             pngu10m="bias_stde_S10m_"+period+".png",
             pngpmsl="bias_stde_Pmsl_"+period+".png",
             pngrh2m="bias_stde_RH2m_"+period+".png",
        			))
else:        
    filename = os.path.join(root, 'html', 'scores_'+domain+'.html')
    with open(filename, 'w') as fh:
        fh.write(template.render(
             model = model,
             pngt2m="bias_stde_T2m_"+period+"_"+domain+".png",
             pngu10m="bias_stde_S10m_"+period+"_"+domain+".png",
             pngpmsl="bias_stde_Pmsl_"+period+"_"+domain+".png",
             pngrh2m="bias_stde_RH2m_"+period+"_"+domain+".png",
             domain = domain
        			))
    
#Modify the html template for vertical profiles
template = env.get_template('vertical_profiles.html')
filename = os.path.join(root, 'html', 'vertical_profiles_'+domain+'.html')

if score_type == "temp":
    if "_" in period:
        print("Please provide only one date for period")
        sys.exit(1)
    day = period #.split("_")[-1]
    with open(filename, 'w') as fh:
        fh.write(template.render(
             model = model,
             day = day,
             pngT="_".join(["vprof_bias",day,"T",domain+".png"]),
             pngS="_".join(["vprof_bias",day,"S",domain+".png"]),
             pngRH="_".join(["vprof_bias",day,"RH",domain+".png"]),
             domain = domain
        			))
    
#TODO:
#template = env.get_template('score_cards_threshold.html')
#template = env.get_template('vertical_profiles.html')
