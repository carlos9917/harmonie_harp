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


    # change the timestamp in index.html
    template = env.get_template('index.html')
    filename = os.path.join(root, 'html', 'index.html')
    from datetime import datetime
    lastmodified = datetime.strftime(datetime.now(),"%Y/%m/%d %H:%M:%S")
    with open(filename, 'w') as fh:
        fh.write(template.render(
             lastmodified = lastmodified
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
    template = env.get_template('scores.html')
    if domain == "DINI" and score_type == "synop_scores":
        filename = os.path.join(root, 'html', 'scores.html')
        with open(filename, 'w') as fh:
            fh.write(template.render(
                 model = model,
                 figspath = figspath,
                 pngt2m="bias_stde_T2m_"+period+".png",
                 pngu10m="bias_stde_S10m_"+period+".png",
                 pngpmsl="bias_stde_Pmsl_"+period+".png",
                 pngrh2m="bias_stde_RH2m_"+period+".png",
            			))
    elif score_type == "synop_scores":
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
    template = env.get_template('vertical_profiles.html')
    filename = os.path.join(root, 'html', 'vertical_profiles_'+domain+'.html')
    
    if score_type == "temp":
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
        
    #TODO:
    #template = env.get_template('score_cards_threshold.html')
    #template = env.get_template('vertical_profiles.html')
