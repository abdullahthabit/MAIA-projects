# -*- coding: utf-8 -*-

"""
3D with ResNet blocks
"""
import torch
import torch.nn as nn
import torch.nn.functional as F

class ResUNetBody(nn.Module):

    def __init__(self, k=16, outputsize=2, inputsize=4):
        super(ResUNetBody, self).__init__()
        self.outputsize = outputsize
        self.inputsize = inputsize
        self. k = k

        self.conv = ConvBlock(inputsize, k, 3)
        self.denseBlock1 = DenseBlock(n=2, inputsize=k)
        self.TD1 = TD(inputsize=k, outputsize=k*2)
        self.denseBlock2 = DenseBlock(n=2, inputsize=k*2)
        self.TD2 = TD(inputsize=k*2, outputsize=k*4)
        self.denseBlock3 = DenseBlock(n=2, inputsize=k*4)
        self.TD3 = TD(inputsize=k*4, outputsize=k * 4)
        self.denseBlock4 = DenseBlock(n=2, inputsize=k*4)
        self.TD4 = TD(inputsize=k*4, outputsize=k*4)
        self.denseBlockmid = DenseBlock(n=2, inputsize=k*4)
        self.UP1 = nn.ConvTranspose3d(k*4, k*4, 2, stride=2)
        self.denseBlock4_right = DenseBlock(n=2, inputsize=k*8)
        self.UP2 = nn.ConvTranspose3d(k*8, k*4, 2, stride=2)
        self.denseBlock3_right = DenseBlock(n=2, inputsize=k*8)
        self.UP3 = nn.ConvTranspose3d(k*8, k*2, 2, stride=2)
        self.denseBlock2_right = DenseBlock(n=2, inputsize=k*4)
        self.UP4 = nn.ConvTranspose3d(k*4, k*1, 2, stride=2)
        self.denseBlock1_right = DenseBlock(n=2, inputsize=k*2)

    def forward(self, x):
        res = self.conv(x)
        res = self.denseBlock1(res)
        skip1 = res.clone()
        res = self.TD1(res)
        res = self.denseBlock2(res)
        skip2 = res.clone()
        res = self.TD2(res)
        res = self.denseBlock3(res)
        skip3 = res.clone()
        res = self.TD3(res)
        res = self.denseBlock4(res)
        skip4 = res.clone()
        res = self.TD4(res)
        res = self.denseBlockmid(res)
        res = self.UP1(res)
        skip4 = skip4
        res = torch.cat([res, skip4], dim=1)
        res = self.denseBlock4_right(res)
        res = self.UP2(res)
        skip3 = skip3
        res = torch.cat([res, skip3], dim=1)
        res = self.denseBlock3_right(res)
        res = self.UP3(res)
        skip2 = skip2
        res = torch.cat([res, skip2], dim=1)
        res = self.denseBlock2_right(res)
        res = self.UP4(res)
        skip1 = skip1
        res = torch.cat([res, skip1], dim=1)
        res = self.denseBlock1_right(res)
        return res

class UncertaintyHeads(nn.Module):

    def __init__(self, inputsize, outputsize=5):
        super(UncertaintyHeads, self).__init__()
        #self.uncer1_batchnorm_layer = nn.BatchNorm3d(inputsize)
        #self.uncer1_dropout_layer = nn.Dropout3d(p=0.5)
        #self.uncer1_dens_layer = nn.Conv3d(inputsize, inputsize, 1, padding=0)
        #self.uncer2_batchnorm_layer = nn.BatchNorm3d(inputsize)
        #self.uncer2_dropout_layer = nn.Dropout3d(p=0.5)
        #self.uncer2_dens_layer = nn.Conv3d(inputsize, inputsize, 1, padding=0)
        #self.uncer3_batchnorm_layer = nn.BatchNorm3d(inputsize)
        #self.uncer3_dropout_layer = nn.Dropout3d(p=0.5)
        self.logits = nn.Conv3d(inputsize, outputsize, 1, padding=0)
        self.variance_out = nn.Conv3d(inputsize, 1, 1, padding=0)


    def forward(self, x):
        #out = self.uncer1_batchnorm_layer(x)
        #out = self.uncer1_dropout_layer(out)
        #out = self.uncer1_dens_layer(out)
        #out = self.uncer2_batchnorm_layer(out)
        #out = self.uncer2_dropout_layer(out)
        #out = self.uncer2_dens_layer(out)
        #out = self.uncer3_batchnorm_layer(out)
        #out = self.uncer3_dropout_layer(out)
        out_pred = self.logits(x)
        out_var = self.variance_out(x)
        out_var = F.softplus(out_var)
        logit_variance = torch.cat([out_pred, out_var], dim=1)
        out_pred = F.softmax(out_pred, dim=1)

        return out_pred, logit_variance


class ResUNet(nn.Module):

    def __init__(self, k=16, outputsize=2, inputsize=4, uncertainty=False):
        super(ResUNet, self).__init__()
        self.outputsize = outputsize
        self.inputsize = inputsize
        self.uncertainty = uncertainty
        self. k = k
        self.body = ResUNetBody(k=k, outputsize=outputsize, inputsize=inputsize)
        self.FC = ConvBlock(k*2, k*2, 1, padding=False)

        if self.uncertainty:
            self.uncertaintyOutput = UncertaintyHeads(k*2, self.outputsize)
        else:
            self.classifier = nn.Conv3d(k*2, self.outputsize, 1, padding=0)
            self.softmax = nn.Softmax(dim=1)

    def forward(self, x):
        res = self.body(x)
        res = self.FC(res)
        if self.uncertainty:
            res_pred, res_var = self.uncertaintyOutput(res)
            return res_pred, res_var
        else:
            res = self.classifier(res)
            res = self.softmax(res)
            res_var = None
            return res, res_var



    @staticmethod
    def initFromDesc(desc):
        inputsize = desc['inputsize']
        outputsize = desc['outputsize']
        k = desc['k'] if 'k' in desc else 16
        return ResUNet(outputsize=outputsize, inputsize=inputsize, k=k)

    def getDesc(self):
        return ['resunet', {
            'inputsize': self.inputsize,
            'outputsize': self.outputsize,
            'k': self.k
        }]


class DenseBlock(nn.Module):

    def __init__(self, k=10, n=4, inputsize=32, normgroups=1):
        super(DenseBlock, self).__init__()
        self.k = k
        self.n = n
        self.inputsize = inputsize
        self.convolutions = nn.ModuleList([nn.Conv3d(inputsize, inputsize, 3, padding=1) for _ in range(0, self.n)])
        self.groupNorm = nn.ModuleList([nn.GroupNorm(inputsize, inputsize) for _ in range(0, self.n)])

    def forward(self, x):
        res = x
        for i in range(0, self.n):
            res = self.convolutions[i](res)
            res = self.groupNorm[i](res)
            res = F.leaky_relu(res)
        res.add(x)
        return res

    def getOutputImageSize(self, inputsize):
        outputsize = [i - (self.n * 2) for i in inputsize]
        return outputsize


class ConvBlock(nn.Module):

    def __init__(self, channels_in, channels_out, kernel_size, dropout=False, batchnorm=True, instancenorm=True,
                 padding=True):
        super(ConvBlock, self).__init__()
        self.batchnorm = batchnorm
        self.dropout = dropout
        self.instancenorm = instancenorm
        if batchnorm:
            self.batchnorm_layer = nn.BatchNorm3d(channels_out)
        if padding:
            padding = 1
        else:
            padding = 0
        self.conv = nn.Conv3d(channels_in, channels_out, kernel_size, padding=padding)
        if dropout:
            self.dropout_layer = nn.Dropout3d(p=0.2)
        if instancenorm:
            self.instance_layer = nn.InstanceNorm3d(channels_in)

    def forward(self, x):
        if self.dropout:
            x = self.dropout_layer(x)
        x = self.conv(x)
        if self.batchnorm:
            x = self.batchnorm_layer(x)
        if self.instancenorm:
            x = self.instance_layer(x)
        x = F.leaky_relu(x)
        return x


class TD(nn.Module):

    def __init__(self, inputsize=32, outputsize=32):
        super(TD, self).__init__()
        self.inputsize = inputsize
        self.outputsize = outputsize
        self.convolution = nn.Conv3d(self.inputsize, self.outputsize, 3, stride=2, padding=1)
        self.uncer_dropout_layer = nn.Dropout3d(p=0.1)


    def forward(self, x):
        res = self.convolution(x)
        res = self.uncer_dropout_layer(res)
        return res

    def getOutputImageSize(self, inputsize):
        outputsize = [i // 2 for i in inputsize]
        return outputsize

    def getOutputChannelSize(self):
        return self.k
