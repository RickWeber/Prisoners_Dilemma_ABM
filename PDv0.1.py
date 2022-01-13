from mesa import Agent, Model
from mesa.time import RandomActivation
from mesa.datacollection import DataCollector
from mesa.batchrunner import BatchRunner
import random
import functools
import numpy as np
import pandas as pd

# Convenience functions:

def binary_to_decimal(bin_list):
    l = len(bin_list)
    if l < 1:
        return 0
    bases = [2 ** i for i in range(l)][::-1]
    result = [b for b, i in zip(bases, bin_list) if i]
    functools.reduce(lambda a, b: a+b, result)

def strategy_freq(model): 
    strategies = [agent.strategy for agent in model.schedule.agents]
    unique_strategies, frequencies = np.unique(strategies, return_counts = True)
    pd.DataFrame(data = {'strat': unique_strategies, 'freq': frequencies})

class Turtle(Agent):
    """A basic agent."""
    def __init__(self, unique_id, model):
        super().__init__(unique_id, model)
        self.memory_length = 1
        self.history = [random.randint(0,1)]
        self.partner_history = []
        self.wealth = 0
        self.age = 0
        self.strategy = self.random_strategy()
        self.move = random.randint(0,1)
        if self.model.num_groups > 1:
            self.group = self.random.choice(range(self.model.num_groups))
        else:
            self.group = 0

    def step(self):
        my_group = self.model.schedule.agents
        my_group = [a for a in my_group if a.group == self.group]
        # choose partner from group
        # partner = self.random.choice(my_group) # do I need to make it another agent?
        # preferential attachment 
        partner = self.random.choices(my_group, [(w.partner_history == self) + 1 for w in my_group])
        # play multiple rounds of the game
        for r in range(self.model.num_rounds):
            self.move = self.return_move()
            partner.move = partner.return_move()
            my_gain, partner_gain = self.model.prisoners_dilemma(self, partner)
            self.wealth += my_gain
            partner.wealth += partner_gain
            self.history = self.history.append(self.move)
            self.history = self.history.append(partner.move)
            partner.history = partner.history.append(self.move)
            partner.history = partner.history.append(partner.move)
        # determine costs of existence
        my_costs = self.existential_burden() * self.model.num_rounds
        partner_costs = partner.existential_burden() * self.model.num_rounds
        # update wealth
        self.wealth -= my_costs
        partner.wealth -= partner_costs
        # risk mutation
        self.risk_mutation()
        self.age += 1

    def return_move(self):
        slice_index = len(self.history) - self.memory_length
        item = binary_to_decimal(self.history[slice_index:])
        move = self.strategy[item]
        if random.random() < self.model.prob_err:
            if move == 1:
                return 0
            else:
                return 1
        else:
            return move

    def risk_mutation(self):
        if random.random() < self.model.prob_point:
            self.mutate_point()
        if random.random() < self.model.prob_split:
            self.mutate_split()
        if random.random() < self.model.prob_dupli:
            self.mutate_duplicate()

    def random_strategy(self):
        self.strategy = [random.randint(0,1) for i in range(self.memory_length)]

    def mutate_split(self):
        if self.memory_length <= 1:
            return False
        self.memory_length -= 1
        strategy_length = len(self.strategy)
        if random.randint(0,1) == 1:
            self.strategy = self.strategy[range(strategy_length / 2)]
        else:
            self.strategy = self.strategy[range(strategy_length / 2, strategy_length)]

    def mutate_duplicate(self):
        self.memory_length += 1
        self.strategy = self.strategy.append(self.strategy)
        if len(self.history) < self.memory_length:
            self.history.append(random.randint(0,1)) 

    def mutate_point(self):
        point = random.randint(0,len(self.strategy))
        if self.strategy[point] == 1:
            self.strategy[point] = 0
        else:
            self.strategy[point] = 1

    def existential_burden(self):
        fixed_term = (-1)
        linear_term = (-1) * self.memory_length
        linear_term = 0.10 * self.memory_length ** 2
        return fixed_term + linear_term + quadratic_term

class World(Model):
    """A model with some number of agents."""
    def __init__(self, N, num_groups):
        self.running = True
        self.population = N
        self.num_groups = num_groups
        self.prob_err = 0.01
        self.prob_split = 0.002
        self.prob_dupli = 0.002
        self.prob_point = 0.001
        self.schedule = RandomActivation(self)
        self.turnover_rate = 0.1
        self.num_rounds = 100
        # create agents
        for i in range(self.population):
            a = Turtle(i, self)
        self.datacollector = DataCollector(
                model_reporters={"strategy_freq": strategy_freq})

    def step(self):
        self.datacollector.collect(self)
        self.schedule.step()

    def genetic_algorithm(self):
        turtles = model.schedule.agents
        sorted_turtles = sorted(turtles, key = lambda turtle: turtle.wealth)
        #top_threshold = np.quantile(turtle_wealth, 0.9)
        #bottom_threshold = np.quantile(turtle_wealth, 0.1)
        # have least wealthy turtles die
        turnover_count = round(self.population * self.turnover_rate)
        turtles_to_die = sorted_turtles[(self.population - turnover_count):]
        turtles_to_sprout = sorted_turtles[:turnover_count]
        # self.schedule.agents with least wealth .remove
        for t in turtles_to_die:
            self.schedule.remove(t)
        for t in turtles_to_sprout:
            self.schedule.spawn(t) # I don't think spawn() exists.

        # have wealthiest turtles spawn

    def prisoners_dilemma(self, player1, player2):
        payoffs = [(1, 1), (3, 0), (0, 3), (2, 2)]
        return payoffs[binary_to_decimal([player1.move, player2.move])]


# random seed
random.seed(42)

# batch run
fixed_params = {"N": 100}
variable_params ={"num_groups": range(1,5,1)}

batch_run = BatchRunner(World, variable_params, fixed_params, iterations=5, max_steps=1000, model_reporters={"Strategies": strategy_freq})
batch_run.run_all()
run_data = batch_run.get_model_vars_dataframe()
print(run_data.head())
