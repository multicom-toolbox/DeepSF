
import sys
import numpy as np
import os

if __name__ == '__main__':

    #print len(sys.argv)
    if len(sys.argv) != 5:
            print 'please input the right parameters: list, model, weight, kmax'
            sys.exit(1)
    
    
    test_list=sys.argv[1] 
    relationfile=sys.argv[2]
    prediction_dir=sys.argv[3]
    summary=sys.argv[4]
    with open(summary, "w") as myfile:
            myfile.write("pdb_name\ttrue_labelname\ttop1\ttop5\ttop10\ttop15\ttop20\n")
    sequence_file=open(relationfile,'r').readlines() 
    fold2label = dict()
    for i in xrange(len(sequence_file)):
        if sequence_file[i].find('Label') >0 :
            print "Skip line ",sequence_file[i]
            continue
        fold = sequence_file[i].rstrip().split('\t')[0]
        label = sequence_file[i].rstrip().split('\t')[1]
        if fold not in fold2label:
            fold2label[fold]=int(label)
    
    all_cases=0
    corrected_top1=0
    corrected_top5=0
    corrected_top10=0
    corrected_top15=0
    corrected_top20=0
    sequence_file=open(test_list,'r').readlines() 
    for i in xrange(len(sequence_file)):
        if sequence_file[i].find('Length') >0 : 
            print "Skip line ",sequence_file[i]
            continue
        pdb_name = sequence_file[i].split('\t')[0]
        true_labelname = sequence_file[i].split('\t')[2].rstrip()
        classid = sequence_file[i].split('\t')[2].rstrip().split('.') #d1y19b1 100     a.11.2.1        l.44
        foldid = classid[0]+'.'+classid[1]
        true_label_int= []
        true_label_int.append(fold2label[foldid])
        prediction_file = prediction_dir+'/'+pdb_name+'.prediction'
        if not os.path.isfile(prediction_file):
            raise Exception("prediciton file not exists: ",prediction_file, " pass!")
        #print "Loading ",prediction_file
        prediciton_results = np.loadtxt(prediction_file)     
        top1_prediction=prediciton_results.argsort()[-1:][::-1]
        top5_prediction=prediciton_results.argsort()[-5:][::-1]
        top10_prediction=prediciton_results.argsort()[-10:][::-1]
        top15_prediction=prediciton_results.argsort()[-15:][::-1]
        top20_prediction=prediciton_results.argsort()[-20:][::-1]
        all_cases +=1
        top1 = 'wrong'
        top5 = 'wrong'
        top10 = 'wrong'
        top15 = 'wrong'
        top20 = 'wrong'
        for da in top1_prediction:
            if da in true_label_int:
                corrected_top1 +=1
                #print "%s is predicted correctly in top 1, great!" % (pdb_name)
                top1 = "correct"
                break
        for da in top5_prediction:
            if da in true_label_int:
                corrected_top5 +=1
                #print "%s is predicted correctly in top 5, great!" % (pdb_name)
                top5 = "correct"
                break
        for da in top10_prediction:
            if da in true_label_int:
                corrected_top10 +=1
                #print "%s is predicted correctly in top 10, great!" % (pdb_name)
                top10 = "correct"
                break
        for da in top15_prediction:
            if da in true_label_int:
                corrected_top15 +=1
                #print "%s is predicted correctly in top 15, great!" % (pdb_name)
                top15 = "correct"
                break
        for da in top20_prediction:
            if da in true_label_int:
                corrected_top20 +=1
                #print "%s is predicted correctly in top 20, great!" % (pdb_name)
                top20 = "correct"
                break
        check = "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" % (pdb_name,true_labelname,top1,top5,top10,top15,top20);
        with open(summary, "a") as myfile:
            myfile.write(check)
        
    top1_acc = float(corrected_top1)/all_cases
    top5_acc = float(corrected_top5)/all_cases
    top10_acc = float(corrected_top10)/all_cases
    top15_acc = float(corrected_top15)/all_cases
    top20_acc = float(corrected_top20)/all_cases
    
    print 'The top1_acc accuracy is %.5f (%i/%i)' % (top1_acc,corrected_top1,all_cases)
    print 'The top5_acc accuracy is %.5f (%i/%i)' % (top5_acc,corrected_top5,all_cases)
    print 'The top10_acc accuracy is %.5f (%i/%i)' % (top10_acc,corrected_top10,all_cases)
    print 'The top15_acc accuracy is %.5f (%i/%i)' % (top15_acc,corrected_top15,all_cases)
    print 'The top20_acc accuracy is %.5f (%i/%i)' % (top20_acc,corrected_top20,all_cases)
    with open(summary, "a") as myfile:
        myfile.write("The top1_acc accuracy is %.5f (%i/%i)\n" % (top1_acc,corrected_top1,all_cases))
    with open(summary, "a") as myfile:
        myfile.write("The top5_acc accuracy is %.5f (%i/%i)\n" % (top5_acc,corrected_top5,all_cases))
    with open(summary, "a") as myfile:
        myfile.write("The top10_acc accuracy is %.5f (%i/%i)\n" % (top10_acc,corrected_top10,all_cases))
    with open(summary, "a") as myfile:
        myfile.write("The top15_acc accuracy is %.5f (%i/%i)\n" % (top15_acc,corrected_top15,all_cases))
    with open(summary, "a") as myfile:
        myfile.write("The top20_acc accuracy is %.5f (%i/%i)\n" % (top20_acc,corrected_top20,all_cases))

