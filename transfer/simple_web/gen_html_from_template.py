from jinja2 import Environment, FileSystemLoader
import os
import sys
from datetime import datetime
root = os.path.dirname(os.path.abspath(__file__))
templates_dir = os.path.join(root, 'templates')
env = Environment( loader = FileSystemLoader(templates_dir)  )

#template = env.get_template('index.html')
#Crude argument reading. Only two options
#period = "20210907-20210928"
#model="EC9"
if __name__=="__main__":
    import argparse
    from argparse import RawTextHelpFormatter
    parser = argparse.ArgumentParser(description='''
		    Example usage: python3 gen_html_from_template.py -model "cca_dini" -period "20210907-20210928" -domain DINI -score_type "synop" '''
            , formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-model',metavar='model to evaluate',
                        type=str,
                        default=None,
                        required=True)

    parser.add_argument('-ref_model',metavar='Ref model for scorecards',
                        type=str,
                        default="EC9",
                        required=False)

    parser.add_argument('-domain',metavar='domain for the calculations',
                        type=str,
                        default=None,
                        required=True)

    parser.add_argument('-period',metavar='period, as a string with YYYYMMDD-YYYYMMDD',
                        type=str,
                        default=None,
                        required=True)

    parser.add_argument('-score_type',metavar='Type of score to select template (ie, synop)',
                        type=str,
                        default=None,
                        required=True)

    parser.add_argument('-figspath',metavar='Figs path in hirlam',
                        type=str,
                        default="https://hirlam.org/portal/uwc_west_validation/figs",
                        required=False)

    args = parser.parse_args()
    model = args.model
    ref_model = args.ref_model
    period = args.period
    domain = args.domain
    score_type = args.score_type
    figspath = args.figspath

    if not os.path.isdir(os.path.join(root, 'html')):
        os.makedirs(os.path.join(root, 'html'))

    verif_period = datetime.strftime(datetime.strptime(period.split("_")[0],"%Y%m%d%H"),"%B %Y")
    # change the timestamp in index.html
    template = env.get_template('index.html')
    filename = os.path.join(root, 'html', 'index.html')
    lastmodified = datetime.strftime(datetime.now(),"%Y/%m/%d %H:%M:%S")
    with open(filename, 'w') as fh:
        fh.write(template.render(
             lastmodified = lastmodified,
             verif_period = verif_period
            			))

    #Modify the html template for score cards
    template = env.get_template('scorecards.html')
    if domain == "DINI" and score_type == "synop_scorecards":
        filename = os.path.join(root, 'html', 'scorecards_'+model+'_'+ref_model+'.html')
        with open(filename, 'w') as fh:
            fh.write(template.render(
                 model = model,
                 ref_model = ref_model,
                 period = period.replace("_"," to "),
                 figspath = figspath,
                 pngfile="scorecards_"+model+"_"+period+".png",
                 domain = domain
            			))
    elif score_type == "synop_scorecards":
        filename = os.path.join(root, 'html', 'scorecards_'+model+'_'+ref_model+'_'+domain+'.html')
        with open(filename, 'w') as fh:
            fh.write(template.render(
                 model = model,
                 ref_model = ref_model,
                 period = period.replace("_"," to "),
                 figspath = figspath,
                 pngfile="scorecards_"+model+"_"+domain+"_"+period+".png",
                 domain = domain
            			))
    
    #Modify the html template for standard scores
    if domain == "DINI" and score_type == "synop_scores":
        template = env.get_template('scores.html')
        filename = os.path.join(root, 'html', 'scores.html')
        with open(filename, 'w') as fh:
            fh.write(template.render(
                 model = model,
                 figspath = figspath,
                 pngt2m="bias_stde_T2m_"+period+".png",
                 pngu10m="bias_stde_S10m_"+period+".png",
                 pngpmsl="bias_stde_Pmsl_"+period+".png",
                 pngrh2m="bias_stde_RH2m_"+period+".png",
                 domain = domain
            			))
    elif score_type == "synop_scores":
        template = env.get_template('scores.html')
        filename = os.path.join(root, 'html', 'scores_'+domain+'.html')
        with open(filename, 'w') as fh:
            fh.write(template.render(
                 model = model,
                 figspath = figspath,
                 pngt2m="bias_stde_T2m_"+period+"_"+domain+".png",
                 pngu10m="bias_stde_S10m_"+period+"_"+domain+".png",
                 pngpmsl="bias_stde_Pmsl_"+period+"_"+domain+".png",
                 pngrh2m="bias_stde_RH2m_"+period+"_"+domain+".png",
                 domain = domain
            			))
        
    #Modify the html template for vertical profiles
    if score_type == "temp":
        template = env.get_template('vertical_profiles.html')
        filename = os.path.join(root, 'html', 'vertical_profiles_'+domain+'.html')
        if "_" in period:
            print("Please provide only one date for period")
            sys.exit(1)
        day = period #.split("_")[-1]
        with open(filename, 'w') as fh:
            fh.write(template.render(
                 figspath = figspath,
                 model = model,
                 day = day,
                 pngT="_".join(["vprof_bias",day,"T",domain+".png"]),
                 pngS="_".join(["vprof_bias",day,"S",domain+".png"]),
                 pngRH="_".join(["vprof_bias",day,"RH",domain+".png"]),
                 domain = domain
            			))
        
    if domain == "DINI" and score_type == "synop_maps":
        template = env.get_template('maps.html')
        filename = os.path.join(root, 'html', "_".join(['maps',domain,'bias',model])+'.html')
        with open(filename, 'w') as fh:
            fh.write(template.render(
                 model = model,
                 period = period.replace("_"," to "),
                 figspath = figspath,
                 pngmap_bias_S10m="_".join(["map",model,"bias","S10m",period])+".png",
                 pngmap_bias_T2m="_".join(["map",model,"bias","T2m",period])+".png",
                 domain = domain
            			))
    if domain == "DINI" and score_type == "scatter_plots":
        template = env.get_template('scatter.html')
        filename = os.path.join(root, 'html', "_".join(['scatter',domain])+'.html')
        with open(filename, 'w') as fh:
            fh.write(template.render(
                 period = period.replace("_"," to "),
                 figspath = figspath,
                 pngscat_S10m="scatterplot_S10m_"+period+".png",
                 pngscat_T2m="scatterplot_T2m_"+period+".png",
                 pngscat_RH2m="scatterplot_RH2m_"+period+".png",
                 pngscat_Pmsl="scatterplot_Pmsl_"+period+".png",
                 domain = domain
                               ))
