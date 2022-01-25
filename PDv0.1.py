from mesa import Agent, Model
from mesa.time import RandomActivation
from mesa.datacollection import DataCollector
from mesa.batchrunner import BatchRunner
import random
import functools
import numpy as np
import pandas as pd

# TODO:
# * turtle's are getting strategies of None. Fix it!

# Convenience functions:

def binary_to_decimal(bin_list):
    l = len(bin_list)
    if l < 1:
        return 0
    bases = [2 ** i for i in range(l)][::-1]
    result = [b for b, i in zip(bases, bin_list) if i]
    functools.reduce(lambda a, b: a+b, result)

def strategy_freq(model): 
    strategies = ["".join(agent.strategy) for agent in model.schedule.agents]
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
        self.move = random.randint(0,1) # initial play 
        if self.model.num_groups > 1:
            self.group = self.random.choice(range(self.model.num_groups))
        else:
            self.group = 0

    def step(self):
        # choose partner from group
        my_group = [a for a in self.model.schedule.agents if a.group == self.group]
        # partner = self.random.choice(my_group) # do I need to make it another agent?
        # preferential attachment 
        partner = self.random.choice([(w.partner_history == self) + 1 for w in my_group])
        partner = self.model.schedule.agents[partner]
        # play multiple rounds of the game
        for r in range(self.model.num_rounds):
            self.move = self.return_move()
            partner.move = partner.return_move()
            my_gain, partner_gain = self.model.prisoners_dilemma(self, partner)
            self.wealth += my_gain
            partner.wealth += partner_gain
            self.history = self.history + [self.move, partner.move]
            partner.history = partner.history + [partner.move, self.move]
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
        if not self.strategy:
            return random.randint(0,1)
        history_index = len(self.history) - self.memory_length
        move = self.strategy[binary_to_decimal(self.history[history_index:])]
        if random.random() < self.model.prob_err:
            return abs(move - 1)
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
        # self.strategy = "".join([random.randint(0,1) for i in # range(self.memory_length)]) # binary string instead of list?

    def mutate_split(self):
        if self.memory_length > 1:
            self.memory_length -= 1
            if random.randint(0,1) == 1:
                self.strategy = self.strategy[:int(len(self.strategy)/2)]
            else:
                self.strategy = self.strategy[int(len(self.strategy)/2):]

    def mutate_duplicate(self):
        self.memory_length += 1
        self.strategy = self.strategy + self.strategy
        if len(self.history) < self.memory_length:
            self.history.append(random.randint(0,1)) 

    def mutate_point(self):
        point = random.randint(0,len(self.strategy))
        self.strategy[point] = abs(self.strategy[point] - 1)

    def existential_burden(self):
        fixed_term = (-1)
        linear_term = (-1) * self.memory_length
        quadratic_term = 0.10 * self.memory_length ** 2
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
            self.schedule.add(a)
        self.datacollector = DataCollector(
                model_reporters={"strategy_freq": strategy_freq})

    def step(self):
        for i in range(5):
            self.schedule.step()
        self.genetic_algorithm()
        self.datacollector.collect(self)

    def prisoners_dilemma(self, player1, player2):
        payoffs = [[1,1],[0,3]],[[3,0],[2,2]]
        return payoffs[player1.move][player2.move]

    def genetic_algorithm(self):
        turtles = self.schedule.agents
        sorted_turtles = sorted(turtles, key = lambda turtle: turtle.wealth)
        # TODO: update for weighted prob of spawn/death
        turnover_count = round(self.population * self.turnover_rate)
        turtles_to_die = sorted_turtles[(self.population - turnover_count):]
        turtles_to_sprout = sorted_turtles[:turnover_count]
        # self.schedule.agents with least wealth .remove
        for t in turtles_to_sprout:
            t.spawn()
        for t in turtles_to_die:
            self.schedule.remove(t)

    def spawn(self, parent):
        """create a new turtle with the same properties as parent"""
        child = Turtle(self.next_id, self)
        child.group = parent.group
        child.memory_length = parent.memory_length
        child.history = parent.history
        child.age = 0
        child.partner_history = parent.partner_history
        child.move = parent.move
        self.schedule.add(child)

# random seed
random.seed(42)

# batch run
fixed_params = {"N": 100}
variable_params ={"num_groups": range(1,5,1)}

batch_run = BatchRunner(World, variable_params, fixed_params, iterations=5, max_steps=1000, model_reporters={"Strategies": strategy_freq})
batch_run.run_all()
run_data = batch_run.get_model_vars_dataframe()
print(run_data.head())
