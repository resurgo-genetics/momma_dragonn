import yaml
from avutils import util

class AbstractPerEpochCallback(object):

    def __call__(self, **kwargs):
        raise NotImplementedError()


class SaveBestValidModel(AbstractPerEpochCallback):

    def __init__(self, directory):
        self.directory = directory

    def  __call__(self, model_wrapper, is_new_best_valid_perf, **kwargs):
        if (is_new_best_valid_perf):
            model_wrapper.create_files_to_save(
                directory=self.directory,
                prefix="model_"+model_wrapper.random_string)


class PrintPerfAfterEpoch(AbstractPerEpochCallback):

    def __init__(self, print_trend):
        #boolean controlling whether to print
        #what key metrics did in previous epochs
        self.print_trend = print_trend 

    def  __call__(self, epoch, valid_key_metric, train_key_metric,
                        valid_all_stats, performance_history, **kwargs):
        
        best_valid_perf_info = performance_history\
                               .get_best_valid_epoch_perf_info()
        best_valid_perf_epoch = best_valid_perf_info.epoch
        print("Finished epoch",epoch)
        print("Best valid perf epoch",best_valid_perf_epoch)
        print("Valid key metric:",valid_key_metric)
        print("Train key metric:",train_key_metric)
        print("Best valid perf info:",
         str(util.format_as_json(best_valid_perf_info.get_jsonable_object())))
        if (self.print_trend):
            valid_key_metric_trend = performance_history\
                                     .get_valid_key_metric_history()
            train_key_metric_trend = performance_history\
                                     .get_train_key_metric_history()
            print("epoch","train","valid")
            for (epoch, (train_key_metric, valid_key_metric)) in\
                enumerate(zip(train_key_metric_trend,
                              valid_key_metric_trend)):
                print(epoch,train_key_metric, valid_key_metric)
