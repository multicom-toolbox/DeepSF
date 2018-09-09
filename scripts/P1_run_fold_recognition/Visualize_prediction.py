# -*- coding: utf-8 -*-
"""
Created on Fri Mar 31 22:39:09 2017

@author: Jie Hou
"""


import matplotlib
# Force matplotlib to not use any Xwindows backend.
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import sys
import matplotlib.gridspec as gridspec

if __name__ == '__main__':

    #print len(sys.argv)
    if len(sys.argv) != 3:
            print 'please input the right parameters: list, model, weight, kmax'
            sys.exit(1)
    
    
    predictionfile=sys.argv[1] 
    outputfile=sys.argv[2]
    # visualize prediction  
    #relationfile="C:\\Users\\Jie Hou\\Downloads\\DLS2F\\d1ri9a_.rank_list"
    sequence_file=open(predictionfile,'r').readlines() 
    top_probs=[]
    top_types=[]
    for i in xrange(len(sequence_file)):
        if sequence_file[i].find('Fold') >0 :
            #print "Skip line ",sequence_file[i]
            continue
        if i >5:
            break
        fold = sequence_file[i].rstrip().split('\t')[1]
        prob = sequence_file[i].rstrip().split('\t')[3]
        top_probs.append(prob)
        top_types.append(fold)
        
    
        
    
    ###### More complex
     
    gs = gridspec.GridSpec(1, 1)
    fig = plt.figure(figsize=(10,8))
    
    fig.subplots_adjust(hspace=1)
    fig.subplots_adjust(wspace=0.2)
    
    ax05 = fig.add_subplot(gs[0:1,0:1])
    
    width=0.5
    ind = np.arange(len(top_probs))
    ax05.bar(ind,top_probs,width,align='center',color=['red', 'green', 'blue', 'cyan', 'magenta'],alpha=0.5)
    ax05.set_ylabel('Probability',size=15, weight='bold')
    ax05.set_xlabel('Top 5 folds',size=15, weight='bold')
    ax05.set_title('')
    ax05.set_yticks(np.arange(0, 1.2, 0.2))
    ax05.set_xticks(ind + width/10.)
    ax05.set_xticklabels(top_types, weight='bold')
    ax05.tick_params(axis='x', labelsize=13)
    ax05.tick_params(axis='y', labelsize=13)
    #ax05.set_axis_bgcolor('red')
    ax05.patch.set_facecolor('gray')
    ax05.patch.set_alpha(0.1)
    fig.savefig(outputfile, dpi = 300) 
