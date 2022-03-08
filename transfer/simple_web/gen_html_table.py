from jinja2 import Environment, FileSystemLoader
import os
import sys
root = os.path.dirname(os.path.abspath(__file__))
templates_dir = os.path.join(root, 'templates')
env = Environment( loader = FileSystemLoader(templates_dir)  )

def read_yaml(file_path):
    import yaml
    with open(file_path, "r") as f:
        return yaml.safe_load(f)


if __name__=="__main__":
    # $MODEL ${DATE1}_${DATE2}  $DOMAIN "synop"
    import argparse
    from argparse import RawTextHelpFormatter
    parser = argparse.ArgumentParser(description='''
		    Example usage: python3 gen_html.py -model "cca_dini" -period "20210907-20210928" -domain DINI -score_type "synop" '''
            , formatter_class=argparse.ArgumentDefaultsHelpFormatter)

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
    #Read the models from a yml file, since I combine several in each plot

    conf = read_yaml("streams_verif.yaml")
    period = args.period
    score_type = args.score_type
    figspath = args.figspath
    if score_type == "synop":
        import synop_table as st

        #update timestamp
        #st.update_index_file(template_file="index_tables.html", output_file="index_tables.html")
       
        #generate the html files with the png files
        st.create_scores_html(conf,period,"scores.html",figspath)
        st.create_scorecards_html(conf,period,"scorecards.html",figspath)

        # update scores table
        table_scores=st.update_scores_table(conf,period)
        # update scorecards table
        table_scorecards=st.update_scorecards_table(conf,period)
        models = "_".join([key for key in conf.keys()])
        st.update_table_scores(models,table_scores,table_scorecards,template_file="index_tables.html", output_file="index_tables.html")

    elif score_type == "temp":
        pass
    else:
        print("Only synop or temp scores currently being processed")
        sys.exit(1)
