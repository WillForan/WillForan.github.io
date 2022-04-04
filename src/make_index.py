#!/usr/bin/env python3

# DO NOT EDIT OUTSIDE OF ORG-MODE FILE
# this file is tangled from readme.org
import os
import glob
import datetime
import re
import pprint

# we need to be in the correct directory. always start at script directory
# when sourcing __file__ might not be defined
try:
    thisdir=os.path.dirname(__file__)
except:
    thisdir=os.getcwd()
if not thisdir: thisdir='./'
os.chdir(thisdir)


# regexp for things we want to pull from org-file:
#  date and title
redict = {'date':
           re.compile('^#\+DATE:.*(\d{4}-\d{2}-\d{2})'),
          'title': re.compile('^#\+TITLE: ?(.*)')}

def file_stat(f):
    if not os.path.isfile(f):
         return({'f': f,'mt': None})
    fstat = os.stat(f)
    mt = datetime.datetime.fromtimestamp(
          fstat.st_mtime)
    return({'f': f,'mt': mt})

def file_sort_key(d : dict):
     """should have keys 'mt' (modified time) and 'date' (#DATE: YYYY...)
     but DATE might not be in the text. fallback on modfication time"""
     default = datetime.datetime.strftime(d['mt'],"%Y-%m-%d")
     return d.get('date', default)

def file_info(f):
    txtinfo = {}
    with open(f) as fp:
         for l in fp:
             # collect which of date and title we haven't
             # yet set in txtinfo
             need = [ k for k in redict.keys() if not txtinfo.get(k) ]
             # if we have both, we're done
             if len(need) == 0:
                 break

             # otherwise search for the ones we need
             for k in need:
                 m = redict[k].match(l)
                 if m:
                     txtinfo[k] = m.group(1)
                     print("matched %s => %s" % (k, txtinfo[k]))

    if not txtinfo.get('title'):
        print(f"WARNING: no '#+TITLE: in {f}")
        txtinfo['title']= re.sub('(.md|.org)$','', os.path.basename(f))
        # .replace('_',' '))

    if not txtinfo.get('date'):
        print(f"WARNING: no '#+DATE: YYYY-MM-DD' in {f}")
        txtinfo['date'] = "1800-01-01"

    return(txtinfo)

# ### find all the files we want to use as reports
import pandas
# editing org file we are in ../reports, as file we are in ../src
os.chdir('../reports')
all_org = glob.glob('*.org')
filelist = [{**file_stat(f), **file_info(f)} for f in all_org]
# reverse sort by date
filelist = sorted(filelist,key=file_sort_key,reverse=True)
# as a dataframe
file_df = pandas.DataFrame(filelist)

# build a list of exported files and their export (modification) date
# build those that need it
def export_info(file_df):
  file_df['export_to'] = [ '../html/%s.html'%t for t in file_df['title'] ]
  file_df['export_date'] =  [ file_stat(f)['mt'] for f in file_df['export_to'] ]
  return(file_df)
# update dataframe with export vars
file_df = export_info(file_df)
# find None (!= to self) or out-of-date
need_update = file_df.query('export_date != export_date or export_date < mt')

from subprocess import call
for i,n in need_update.iterrows():
    call(['org-export','html','--infile',n['f'],'--outfile',n['export_to'],'--bootstrap' ])

# update again, see if everything exported
file_df = export_info(file_df)
need_update = file_df.query('export_date != export_date or export_date < mt')
if len(need_update) != 0:
    print("some files failed to update: %s!"%(",".join(need_update['title'])))

# export_to is relative to this script. should be relative to index.html
# remove '../'
file_df['uri'] = [ re.sub('^\.\./','',x) for x in file_df['export_to'] ]
# index template
from wheezy.template.engine import Engine
from wheezy.template.ext.core import CoreExtension
from wheezy.template.loader import FileLoader
engine = Engine(loader=FileLoader(['../src/']), extensions=[CoreExtension()])
template = engine.get_template('index.tmp')
# write it out
index_str = template.render({'file_df': file_df,'title': 'WF log'})
with open('../index.html','w') as indexf:
    indexf.write(index_str)
