---
title: Untitled Page
description: 
published: true
date: 2023-06-02T02:50:38.868Z
tags: 
editor: markdown
dateCreated: 2023-06-02T02:47:56.733Z
---

#!/usr/bin/env python

import os,sys

import math

import matplotlib

matplotlib.use('Agg')

import matplotlib.pyplot as plt

from pylab import \*

from collections import defaultdict

from lefse import \*

from numpy import \*

import argparse

import sys

reload(sys)

sys.setdefaultencoding('utf-8')

#colors = \['#CD79FF','#00BB57','#FE90C2','#FF7F00','#00B8E5','#F8766D','#BC9D00','#8086F9','#64A10E','#D00000','#FF00FF','#464E04','#930026','#4E0C66','#F34800','#049a0b','#c7475b','#B3B3B3','#A3FDFF','#E2D89E','#A5CFED','#f0301c','#2B8BC3','#FDA100','#54adf5','#CDD7E2','#9295C1',"#FF0000FF", "#FF9900FF", "#CCFF00FF", "#33FF00FF" ,"#00FF66FF", "#00FFFFFF" ,"#0066FFFF" ,"#3300FFFF","#CC00FFFF","#FF0099FF"\]

colors = \['r','g','b','m','c','#ac790F','k','#CD79FF','#FE90C2','#FF7F00','#00B8E5','#BC9D00','#8086F9','#64A10E','#D00000','#FF00FF','#464E04','#930026','#4E0C66','#F34800','#049a0b','#c7475b','#B3B3B3','#A3FDFF','#E2D89E','#A5CFED','#f0301c','#2B8BC3','#FDA100','#54adf5','#CDD7E2','#9295C1',"#FF0000FF", "#FF9900FF", "#CCFF00FF", "#33FF00FF" ,"#00FF66FF", "#00FFFFFF" ,"#0066FFFF" ,"#3300FFFF","#CC00FFFF","#FF0099FF"\]

def read\_params(args):

   parser = argparse.ArgumentParser(description='Plot results')

   parser.add\_argument('input\_file', metavar='INPUT\_FILE', type=str, help="tab delimited input file")

   parser.add\_argument('output\_file', metavar='OUTPUT\_FILE', type=str, help="the file for the output image")

   parser.add\_argument('--feature\_font\_size', dest="feature\_font\_size", type=int, default=7, help="the file for the output image")

   parser.add\_argument('--format', dest="format", choices=\["png","svg","pdf"\], default='png', type=str, help="the format for the output file")

   parser.add\_argument('--dpi',dest="dpi", type=int, default=72)

   parser.add\_argument('--title',dest="title", type=str, default="")

   parser.add\_argument('--title\_font\_size',dest="title\_font\_size", type=str, default="10")

   parser.add\_argument('--class\_legend\_font\_size',dest="class\_legend\_font\_size", type=str, default="6")

   parser.add\_argument('--width',dest="width", type=float, default=9.0 )

   parser.add\_argument('--height',dest="height", type=float, default=4.0, help="only for vertical histograms")

   parser.add\_argument('--left\_space',dest="ls", type=float, default=0.2 )

   parser.add\_argument('--right\_space',dest="rs", type=float, default=0.1 )

   parser.add\_argument('--orientation',dest="orientation", type=str, choices=\["h","v"\], default="h" )

   parser.add\_argument('--autoscale',dest="autoscale", type=int, choices=\[0,1\], default=1 )

   parser.add\_argument('--background\_color',dest="back\_color", type=str, choices=\["k","w"\], default="w", help="set the color of the background")

   parser.add\_argument('--subclades', dest="n\_scl", type=int, default=1, help="number of label levels to be dislayed (starting from the leaves, -1 means all the levels, 1 is default )")

   parser.add\_argument('--max\_feature\_len', dest="max\_feature\_len", type=int, default=60, help="Maximum length of feature strings (def 60)")

   parser.add\_argument('--all\_feats', dest="all\_feats", type=str, default="")

   parser.add\_argument('--otu\_only', dest="otu\_only", default=False, action='store\_true', help="Plot only species resolved OTUs (as opposed to all levels)")

   parser.add\_argument('--report\_features', dest="report\_features", default=False, action='store\_true', help="Report important features to STDOUT")

   args = parser.parse\_args()

   return vars(args)

def read\_data(input\_file,output\_file,otu\_only):

   with open(input\_file, 'r') as inp:

       if not otu\_only:

           rows = \[line.strip().split()\[:-1\] for line in inp.readlines() if len(line.strip().split())>3\]

       else:

           rows = \[line.strip().split()\[:-1\] for line in inp.readlines() if len(line.strip().split())>3 and len(line.strip().split()\[0\].split('.'))==8\] # a feature with length 8 will have an OTU id associated with it

   classes = list(set(\[v\[2\] for v in rows if len(v)>2\]))

   if len(classes) < 1:  

       print "No differentially abundant features found in "+input\_file

       os.system("touch "+output\_file)

       sys.exit()

   data = {}

   data\['rows'\] = rows

   data\['cls'\] = classes

   return data

def plot\_histo\_hor(path,params,data,bcl,report\_features):

   cls2 = \[\]

   if params\['all\_feats'\] != "":

       cls2 = sorted(params\['all\_feats'\].split(":"))

   cls = sorted(data\['cls'\])

   if bcl: data\['rows'\].sort(key=lambda ab: math.fabs(float(ab\[3\]))\*(cls.index(ab\[2\])\*2-1))

   else:  

       mmax = max(\[math.fabs(float(a)) for a in zip(\*data\['rows'\])\[3\]\])

       data\['rows'\].sort(key=lambda ab: math.fabs(float(ab\[3\]))/mmax+(cls.index(ab\[2\])+1))

   pos = arange(len(data\['rows'\]))

   head = 0.75

   tail = 0.5

   ht = head + tail

   ints = max(len(pos)\*0.2,1.5)

   fig = plt.figure(figsize=(params\['width'\], ints + ht), edgecolor=params\['back\_color'\],facecolor=params\['back\_color'\])

   ax = fig.add\_subplot(111,frame\_on=False,facecolor=params\['back\_color'\])

   ls, rs = params\['ls'\], 1.0-params\['rs'\]

   plt.subplots\_adjust(left=ls,right=rs,top=1-head\*(1.0-ints/(ints+ht)), bottom=tail\*(1.0-ints/(ints+ht)))

   fig.canvas.set\_window\_title('LDA results')

   l\_align = {'horizontalalignment':'left', 'verticalalignment':'baseline'}

   r\_align = {'horizontalalignment':'right', 'verticalalignment':'baseline'}

   added = \[\]

   m = 1 if data\['rows'\]\[0\]\[2\] == cls\[0\] else -1

   out\_data = defaultdict(list) # keep track of which OTUs result in the plot

   for i,v in enumerate(data\['rows'\]):

       if report\_features:

           otu = v\[0\].split('.')\[7\].replace('\_','.') # string replace retains format New.ReferenceOTUxxx

           score = v\[3\]

           otu\_class = v\[2\]

           out\_data\[otu\] = \[score, otu\_class\]

       indcl = cls.index(v\[2\])

       lab = str(v\[2\]) if str(v\[2\]) not in added else ""

       added.append(str(v\[2\]))  

       col = colors\[indcl%len(colors)\]  

       if len(cls2) > 0:  

           col = colors\[cls2.index(v\[2\])%len(colors)\]

       vv = math.fabs(float(v\[3\])) \* (m\*(indcl\*2-1)) if bcl else math.fabs(float(v\[3\]))

       ax.barh(pos\[i\],vv, align='center', color=col, label=lab, height=0.8, edgecolor=params\['fore\_color'\])

   mv = max(\[abs(float(v\[3\])) for v in data\['rows'\]\])  

   if report\_features:

       print 'OTU\\tLDA\_score\\tCLass'

       for i in out\_data:

           print '%s\\t%s\\t%s' %(i, out\_data\[i\]\[0\], out\_data\[i\]\[1\])

   for i,r in enumerate(data\['rows'\]):

       indcl = cls.index(data\['rows'\]\[i\]\[2\])

       if params\['n\_scl'\] < 0: rr = r\[0\]

       else: rr = ".".join(r\[0\].split(".")\[-params\['n\_scl'\]:\])

       if len(rr) > params\['max\_feature\_len'\]: rr = rr\[:params\['max\_feature\_len'\]/2-2\]+" \[..\]"+rr\[-params\['max\_feature\_len'\]/2+2:\]

       if m\*(indcl\*2-1) < 0 and bcl: ax.text(mv/40.0,float(i)-0.3,rr, l\_align, size=params\['feature\_font\_size'\],color=params\['fore\_color'\])

       else: ax.text(-mv/40.0,float(i)-0.3,rr, r\_align, size=params\['feature\_font\_size'\],color=params\['fore\_color'\])

   ax.set\_title(params\['title'\],size=params\['title\_font\_size'\],y=1.0+head\*(1.0-ints/(ints+ht))\*0.8,color=params\['fore\_color'\])

   ax.set\_yticks(\[\])

   ax.set\_xlabel("LDA SCORE (log 10)")

   ax.xaxis.grid(True)

   xlim = ax.get\_xlim()

   if params\['autoscale'\]:  

       ran = arange(0.0001,round(round((abs(xlim\[0\])+abs(xlim\[1\]))/10,4)\*100,0)/100)

       if len(ran) > 1 and len(ran) < 100:

           ax.set\_xticks(arange(xlim\[0\],xlim\[1\]+0.0001,min(xlim\[1\]+0.0001,round(round((abs(xlim\[0\])+abs(xlim\[1\]))/10,4)\*100,0)/100)))

   ax.set\_ylim((pos\[0\]-1,pos\[-1\]+1))

\#    leg = ax.legend(bbox\_to\_anchor=(0.2, 1.02, 0.4, 1.102), loc=4, ncol=5, borderaxespad=0., frameon=False,prop={'size':params\['class\_legend\_font\_size'\]})

   leg = ax.legend(bbox\_to\_anchor=(0.09, 1.0), ncol=4, borderaxespad=0., frameon=False,prop={'size':params\['class\_legend\_font\_size'\]})

\#    leg = ax.legend(bbox\_to\_anchor=(0., 1.02, 1., .102), loc=3, ncol=6, borderaxespad=0., frameon=False,prop={'size':params\['class\_legend\_font\_size'\]})

   def get\_col\_attr(x):

               return hasattr(x, 'set\_color') and not hasattr(x, 'set\_facecolor')

   for o in leg.findobj(get\_col\_attr):

               o.set\_color(params\['fore\_color'\])

   for o in ax.findobj(get\_col\_attr):

               o.set\_color(params\['fore\_color'\])

   plt.savefig(path,format=params\['format'\],facecolor=params\['back\_color'\],edgecolor=params\['fore\_color'\],dpi=params\['dpi'\])

   plt.close()

def plot\_histo\_ver(path,params,data,report\_features):

   cls = data\['cls'\]

   mmax = max(\[math.fabs(float(a)) for a in zip(\*data\['rows'\])\[1\]\])

   data\['rows'\].sort(key=lambda ab: math.fabs(float(ab\[3\]))/mmax+(cls.index(ab\[2\])+1))

   pos = arange(len(data\['rows'\]))  

   if params\['n\_scl'\] < 0: nam = \[d\[0\] for d in data\['rows'\]\]

   else: nam = \[d\[0\].split(".")\[-min(d\[0\].count("."),params\['n\_scl'\])\] for d in data\['rows'\]\]

   fig = plt.figure(edgecolor=params\['back\_color'\],facecolor=params\['back\_color'\],figsize=(params\['width'\], params\['height'\]))  

   ax = fig.add\_subplot(111,facecolor=params\['back\_color'\])

   plt.subplots\_adjust(top=0.9, left=params\['ls'\], right=params\['rs'\], bottom=0.3)  

   fig.canvas.set\_window\_title('LDA results')    

   l\_align = {'horizontalalignment':'left', 'verticalalignment':'baseline'}

   r\_align = {'horizontalalignment':'right', 'verticalalignment':'baseline'}  

   added = \[\]

   out\_data = defaultdict(list) # keep track of which OTUs result in the plot

   for i,v in enumerate(data\['rows'\]):

       if report\_features:

           otu = v\[0\].split('.')\[7\].replace('\_','.') # string replace retains format New.ReferenceOTUxxx

           score = v\[3\]

           otu\_class = v\[2\]

           out\_data\[otu\] = \[score, otu\_class\]

       indcl = data\['cls'\].index(v\[2\])

       lab = str(v\[2\]) if str(v\[2\]) not in added else ""

       added.append(str(v\[2\]))  

       col = colors\[indcl%len(colors)\]

       vv = math.fabs(float(v\[3\]))  

       ax.bar(pos\[i\],vv, align='center', color=col, label=lab)

   if report\_features:

       print 'OTU\\tLDA\_score\\tCLass'

       for i in out\_data:

           print '%s\\t%s\\t%s' %(i, out\_data\[i\]\[0\], out\_data\[i\]\[1\])

   xticks(pos,nam,rotation=-20, ha = 'left',size=params\['feature\_font\_size'\])  

   ax.set\_title(params\['title'\],size=params\['title\_font\_size'\])

   ax.set\_ylabel("LDA SCORE (log 10)")

   ax.yaxis.grid(True)  

   a,b = ax.get\_xlim()

   dx = float(len(pos))/float((b-a))

   ax.set\_xlim((0-dx,max(pos)+dx))  

   plt.savefig(path,format=params\['format'\],facecolor=params\['back\_color'\],edgecolor=params\['fore\_color'\],dpi=params\['dpi'\])

   plt.close()  

if \_\_name\_\_ == '\_\_main\_\_':

   params = read\_params(sys.argv)

   params\['fore\_color'\] = 'w' if params\['back\_color'\] == 'k' else 'k'

   data = read\_data(params\['input\_file'\],params\['output\_file'\],params\['otu\_only'\])

   if params\['orientation'\] == 'v': plot\_histo\_ver(params\['output\_file'\],params,data,params\['report\_features'\])

   else: plot\_histo\_hor(params\['output\_file'\],params,data,len(data\['cls'\]) == 2,params\['report\_features'\])