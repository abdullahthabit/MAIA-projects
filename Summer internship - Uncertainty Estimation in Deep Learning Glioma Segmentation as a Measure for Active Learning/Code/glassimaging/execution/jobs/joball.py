# -*- coding: utf-8 -*-

"""
Job to setup, train and evaluate the network

@author: Abdullah Thaibt
"""

import sys
import os
import argparse
import pandas as pd
import matplotlib.pyplot as plt
from glassimaging.execution.jobs.job import Job
from glassimaging.training.standardTrainer import StandardTrainer
from torch.utils.data import DataLoader
from torch.nn import CrossEntropyLoss

from glassimaging.dataloading.brats18 import Brats18
from glassimaging.dataloading.transforms.randomcrop import RandomCrop
from glassimaging.dataloading.transforms.totensor import ToTensor
from glassimaging.dataloading.transforms.compose import Compose
from glassimaging.evaluation.utils import logDataLoader
from glassimaging.evaluation.evaluator import StandardEvaluator
from glassimaging.evaluation.utils import plotResultImage, getPerformanceMeasures
from glassimaging.models.diceloss import DiceLoss


class JobAll(Job):

    def __init__(self, configfile, name, tmpdir, homedir=None, uid=None):
        super().__init__(configfile, name, tmpdir, homedir, uid=uid)

    def getDataloader(self):
        n_workers = self.config['Num Workers']
        batchsize = self.config['Batch size']
        sequences = self.config["Sequences"]
        loc = os.path.join(self.datadir, self.config["Nifti Source"])

        # locate, organize and split the dataset
        dataset = Brats18.fromFile(loc)

        #Data specifics
        splits = self.config['Splits']
        testsplits = self.config['Testsplits']
        dataset.saveSplits(self.tmpdir)
        targetsize = tuple(self.config["Patch size"])
        imgsize = targetsize

        # initialize input transforms
        transforms = [
            RandomCrop(output_size=imgsize),
            ToTensor()
        ]
        transform = Compose(transforms)

        # prepare the training set loader
        trainset = dataset.getDataset(splits, sequences, transform=transform)
        trainset.saveListOfPatients(os.path.join(self.tmpdir, 'trainset.json'))
        self.logger.info('Generating patches with input size ' + str(imgsize) + ' and outputsize ' + str(targetsize))
        trainloader = DataLoader(trainset, batch_size=batchsize, num_workers=n_workers, shuffle=True)

        # prepare the testing set loader
        if len(testsplits) > 0:
            testset = dataset.getDataset(testsplits, sequences, transform=transform)
            testloader = DataLoader(testset, batch_size=batchsize, num_workers=n_workers, shuffle=True)
        else:
            testloader = None

        # plot and save samples of a mini-batch
        logDataLoader(trainloader, self.tmpdir)

        return trainloader, testloader

    def evaluate(self):
        # Create identifiers
        myconfig = self.config

        # Set network specifics
        patchsize = myconfig["Patch size"]
        batchsize = myconfig["Batch size"]
        output_type = myconfig["Output type"]
        only_first = myconfig["Only first"]
        sequences = myconfig["Sequences"]

        # Data specifics
        splits = myconfig["Testsplits"]

        # load data-manager
        loc = os.path.join(self.datadir, self.config["Nifti Source"])
        dataset = Brats18.fromFile(loc)

        transforms = [ToTensor()]
        transform = Compose(transforms)

        testset = dataset.getDataset(splits, sequences, transform=transform)
        dataloader = DataLoader(testset, batch_size=batchsize, num_workers=0, shuffle=True)
        self.logger.info('Dataloader has {n} images.'.format(n=len(testset)))

        # Load model from source step
        sourcestep = self.name
        loc_model = os.path.join(self.datadir, sourcestep)
        evaluator = StandardEvaluator.loadFromCheckpoint(os.path.join(loc_model, 'model.pt'))

        all_dice = []
        all_dice_core = []
        all_dice_enhancing = []
        results = pd.DataFrame(columns=['sample', 'subject', 'class', 'TP', 'FP', 'FN', 'TN', 'dice'])
        for i_batch, sample_batched in enumerate(dataloader):
            images = sample_batched['data']
            segfiles = sample_batched['seg_file']
            subjects = sample_batched['subject']
            segs = sample_batched['seg']
            resultpaths = [os.path.join(self.tmpdir, s + '_segmented.nii.gz') for s in subjects]
            uncertaintypaths = [os.path.join(self.tmpdir, s + '_epistimci.nii.gz') for s in subjects]
            classifications, epistemicUncertainty = evaluator.segmentNifti(images, segfiles, patchsize, resultpaths, uncertaintypaths)
            for i in range(0, len(subjects)):
                seg = segs[i].numpy()
                plotResultImage(dataset, resultpaths[i], uncertaintypaths[i], self.tmpdir, subjects[i], output_type=output_type)
                for c in range(0, 5):
                    truth = seg == c
                    positive = classifications[i] == c
                    (dice, TT, FP, FN, TN) = getPerformanceMeasures(positive, truth)
                    results = results.append(
                        {'sample': i_batch, 'class': c, 'subject': subjects[i], 'TP': TT, 'FP': FP, 'FN': FN, 'TN': TN,
                         'dice': dice}, ignore_index=True)
                    if c == 4:
                        all_dice_enhancing.append(dice)
                class_whole = classifications[i] > 0
                result_core = (classifications[i] == 1) | (classifications[i] == 4)
                truth_whole = seg > 0
                truth_core = (seg == 1) | (seg == 4)
                (dice, TT, FP, FN, TN) = getPerformanceMeasures(class_whole, truth_whole)
                (dice_core, TT_core, FP_core, FN_core, TN_core) = getPerformanceMeasures(result_core, truth_core)
                all_dice.append(dice)
                all_dice_core.append(dice_core)
                self.logger.info('Nifti image segmented for ' + subjects[i] + '. Dice: ' + str(dice))
                results = results.append(
                    {'sample': i_batch, 'class': 'whole', 'subject': subjects[i], 'TP': TT, 'FP': FP, 'FN': FN,
                     'TN': TN, 'dice': dice}, ignore_index=True)
                results = results.append(
                    {'sample': i_batch, 'class': 'core', 'subject': subjects[i], 'TP': TT_core, 'FP': FP_core,
                     'FN': FN_core,
                     'TN': TN_core, 'dice': dice_core}, ignore_index=True)
            if only_first: break

        dice_mean = sum(all_dice) / len(all_dice)
        dice_core = sum(all_dice_core) / len(all_dice_core)
        dice_enhancing = sum(all_dice_enhancing) / len(all_dice_enhancing)
        plt.boxplot(all_dice)
        plt.savefig(os.path.join(self.tmpdir, 'boxplot_dice.png'))
        plt.close()
        results.to_csv(os.path.join(self.tmpdir, 'results_eval.csv'))
        dataset.saveSplits(self.tmpdir)
        self.logger.info(
            'evaluation finished. Dice coefficient: whole: {}, core: {}, enhancing: {}'.format(dice_mean, dice_core,
                                                                                               dice_enhancing))

    def run(self):
        # Set network specifics
        myconfig = self.config

        # Get the model parameters from configuration file
        model_desc = myconfig["Model"]

        # Get the number of epochs and size of mini-batch
        epochs = myconfig['Epochs']
        maxBatchesPerEpoch = myconfig["Batches per epoch"]

        # Build the model and training tools
        trainer = StandardTrainer.initFromDesc(model_desc)
        self.logger.info('model initiated ...')

        # Set loss function
        if 'Loss' in myconfig:
            if myconfig['Loss'] == 'dice':
                if 'dice_loss_weights' in myconfig:
                    trainer.setLossFunction(DiceLoss(weights=tuple(myconfig['dice_loss_weights'])))
                else:
                    trainer.setLossFunction(DiceLoss())
            elif myconfig['Loss'] == 'crossentropy':
                trainer.setLossFunction(CrossEntropyLoss())

        # Prepare the data loader
        (trainloader, testloader) = self.getDataloader()

        # train the network
        trainer.trainWithLoader(trainloader, epochs, testloader=testloader, maxBatchesPerEpoch=maxBatchesPerEpoch)
        self.logger.info('training finished for ' + str(epochs) + ' epochs.')
        trainer.writeLog(self.tmpdir)

        # save the trained network
        modelpath = os.path.join(self.tmpdir, 'model.pt')
        trainer.saveModel(modelpath)
        self.logger.info('model and training log saved under ' + modelpath + '.')

        # evaluate the network on the testing split
        if myconfig['evaluate'] == True:
            import time
            start = time.time()
            self.evaluate()
            end = time.time()
            print("**********************")
            print(end - start)
            print("**********************")
        # delete the model and log handlers
        del trainer
        self.tearDown()



if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Run a job.')
    parser.add_argument('name', help='a name to call your job by.')
    parser.add_argument('configfile', help='path to a json config file.')
    parser.add_argument('tmpdir', help='directory for the output.')
    parser.add_argument('--log', help='additional directory to write logs to.')
    args = parser.parse_args()
    job = JobAll(args.configfile, args.name, args.tmpdir, args.log)
    job.run()

    # name = "TryMe"
    # configfile = "./../../../config/all_unet.json"
    # tmpdir = "./../../../experiments/"
    # job = JobAll(configfile, name, tmpdir)
    # job.run()
