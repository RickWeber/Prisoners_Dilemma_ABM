# batch run
fixed_params = {"N": 100}
variable_params ={"num_groups": range(1,5,1)}

batch_run = BatchRunner(World, variable_params, fixed_params, iterations=5, max_steps=1000, model_reporters={"Strategies": strategy_freq})
batch_run.run_all()
run_data = batch_run.get_model_vars_dataframe()
print(run_data.head())
