from dataclasses import dataclass


@dataclass
class FPGAParameters:
    time: int = 0          # set to unix timestamp in us or however we want to do it
    delay: int = 0         # unsure, diego?
    attenuation: float = 0.0  # unsure, diego?
    threshold: int = 0     # unsure, diego?
    # more parameters to be added as needed
   
    # if you want to see the parameters in a nice format
    def to_dict(self): 
        return self.__dict__