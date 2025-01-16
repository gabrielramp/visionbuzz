import numpy as np
from typing import List


class ClusterService:
    def __init__(self, config):
        pass

    def get_clusters(embeds: np.array) -> List[int] | np.array:
        """
        Takes in all embeds, returns cluster ID for each one in order
        TODO: Remove typing this is stupid
        NOTE: All points not in big enough cluster, will be labelled -1
        """
        pass
