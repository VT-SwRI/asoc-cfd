from dataclasses import dataclass


@dataclass
class FPGAParameters:
    time: float = 0        
    delay: float = 0        
    attenuation: float = 0.0  
    threshold: float = 0     
    # more parameters to be added as needed
   
    # if you want to see the parameters in a nice format
    def to_dict(self): 
        return self.__dict__