import numpy as np
from typing import List
from sklearn.cluster import DBSCAN

class ClusterService:
    def __init__(self, config):
        self.dbscan = DBSCAN(eps=config.CLUSTER_RADIUS, min_samples=config.CLUSTER_POINTS) # set params

    def get_clusters(self, embeds: np.array) -> List[int] | np.array:
        """
        Takes in all embeds, returns cluster ID for each one in order
        NOTE: All isolated points (not in any cluster) will be labelled -1
        """

        cluster_labels = self.dbscan.fit_predict(embeds) # compute clusters, get labels
        return cluster_labels

