from abc import ABCMeta, abstractmethod

class BaseDriver(metaclass=ABCMeta):
    def __init__(self):
        pass

    @abstractmethod
    def create(self):
        raise NotImplementedError

    @abstractmethod
    def save(self):
        raise NotImplementedError

    @abstractmethod
    def read(self):
        raise NotImplementedError


