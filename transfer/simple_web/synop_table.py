
from jinja2 import Environment, FileSystemLoader
import os
import sys
from datetime import datetime
root = os.path.dirname(os.path.abspath(__file__))
templates_dir = os.path.join(root, 'templates')
env = Environment( loader = FileSystemLoader(templates_dir)  )

from prettytable import PrettyTable
from collections import OrderedDict


def update_index_file(template_file,output_file):
    # change the timestamp in index.html
    template = env.get_template(template_file)
    filename = os.path.join(root, 'html', output_file)
    lastmodified = datetime.strftime(datetime.now(),"%Y/%m/%d %H:%M:%S")
    #Set timestamp in the template
    with open(filename, 'w') as fh:
        fh.write(template.render(
             lastmodified = lastmodified
            			))


def update_scores_table(input_models,period): #period,model,domain,reference,stations):
    """
    Update elements of the table with all models and results
    @input is an OrderedDict with the data
    """
    table = PrettyTable(["models plotted","verif. domain", "period","scores"])
    nlink = 0
    scores_link = OrderedDict()
    for key in input_models.keys():
        variables = input_models[key]["SCORES"]["VARS"]
        models = ",".join(input_models[key]["SCORES"]["MODEL"])
        verif_domain = input_models[key]["SCORES"]["VERIF_DOM"]
        for domain in verif_domain:
            linkid = f"LINK{nlink}"
            htmlfile = f"scores_{key}_{domain}.html"
            scores_link[linkid] = f'<p><a href="{htmlfile}"> scores_{key}_{domain}  </a></p>'
            table.add_row([models, domain,period,linkid])
            nlink+=1
    replace_table = table.get_html_string()
    #make border appear: <table border="1">
    replace_table = replace_table.replace('<table>','<table border="1">')
    #do the replacement of the link afterwards, otherwise the markdown is mangled
    for key in scores_link.keys():
        replace_table = replace_table.replace(key,scores_link[key])

    return replace_table

def update_scorecards_table(input_models,period): 
    table = PrettyTable(["model","verif. domain", "period","scorecard"])
    nlink = 0
    scores_link = OrderedDict()
    for key in input_models.keys():
        verif_domain = input_models[key]["SCORES"]["VERIF_DOM"]
        models = input_models[key]["SCORES"]["MODEL"]
        for model in models:
            for domain in verif_domain:
                linkid = "LINK"+str(nlink).zfill(2)
                htmlfile = f"scorecards_{model}_{domain}.html"
                scores_link[linkid] = f'<p><a href="{htmlfile}"> scorecards_{domain}</a></p>'
                table.add_row([model, domain,period,linkid])
                nlink+=1
    replace_table = table.get_html_string()
    #make border appear: <table border="1">
    replace_table = replace_table.replace('<table>','<table border="1">')
    #do the replacement of the link afterwards, otherwise the markdown is mangled
    for key in scores_link.keys():
        replace_table = replace_table.replace(key,scores_link[key])
    return replace_table


def update_table_scores(models,table_scores,table_scorecards,template_file,output_file):
    #<p><a href="scorecards.html">Score cards for all stations in DINI domain </a></p>
    #Modify the html template for score cards
    lastmodified = datetime.strftime(datetime.now(),"%Y/%m/%d %H:%M:%S")
    template = env.get_template(template_file)
    filename = os.path.join(root, 'html', output_file)
    with open(filename, 'w') as fh:
            fh.write(template.render(
                 table_scores = table_scores,
                  table_scorecards  = table_scorecards,
                  lastmodified = lastmodified,
                  models = models
            			))

def create_scores_html(input_models,period,template_file,figspath):
    template = env.get_template(template_file)
    for key in input_models.keys():
        for domain in input_models[key]["SCORES"]["VERIF_DOM"]:
            filename = f"html/scores_{key}_{domain}.html"
            with open(filename, 'w') as fh:
                fh.write(template.render(
                     pngt2m="bias_stde_T2m_"+period+".png",
                     pngu10m="bias_stde_S10m_"+period+".png",
                     pngpmsl="bias_stde_Pmsl_"+period+".png",
                     pngrh2m="bias_stde_RH2m_"+period+".png",
                     figspath=figspath
                			))
def create_scorecards_html(input_models,period,template_file,figspath,ref_model="EC9"):
    template = env.get_template(template_file)
    for key in input_models.keys():
        for model in input_models[key]["SCORECARDS"]["MODEL"]:
            filename = f"html/scorecards_{model}_{key}.html"
            with open(filename, 'w') as fh:
                fh.write(template.render(
                 figspath=figspath,
                 pngfile="scorecards_"+model+"_"+period+".png",
                 domain = key,
                 model = ref_model,
                 period = period
                			))
