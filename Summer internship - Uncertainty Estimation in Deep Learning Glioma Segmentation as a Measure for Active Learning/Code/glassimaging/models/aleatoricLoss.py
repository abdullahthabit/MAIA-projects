import torch.nn as nn
import torch

class AleatoricLoss(nn.Module):

    def __init__(self, numClasses = 5):
        super(AleatoricLoss, self).__init__()
        self.numClasses = numClasses
        self.std.requires_grad = False


    def forward(self, pred, true):
        std = torch.Tensor.sqrt(pred[:, self.numClasses])
        variance = torch.Tensor(pred[:, self.numClasses])
        varianceDepressor = torch.Tensor.exp(variance) - torch.ones_like(variance)
        predicted = torch.Tensor(pred[:,0:self.numClasses])
        undistored_loss = nn.CrossEntropyLoss(pred, true)


