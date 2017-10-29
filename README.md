# Adaptive

A wrapper to python adaptive package which allows to sample function wiselly so reducing need for . 

## Intallation

To use this package both Python3 and its adaptive library must be installed on the system, which can be done by executing `pip install adaptive`. --If PyCall is built using Conda (which is the default) then the underlying library of Adaptive will be installed via Conda when the package is first loaded.-- Not yet implemented! In julia then execute
```
Pkg.clone("link of this repo")
```
for adding this package and test it with `Pkg.test("Adaptive")`

## Usage

This package defines two structs Learner1D and Learner2D which are responsible for state of the evaluation. The methods to theese objects are added in lines with already present methods `map` and `pmpap`, but output is a dictionary. 

```
using Adaptive  

map(x->exp(-x^2),Learner1D(0:0.1:1))
map(p->((x,y)=p;exp(-x^2-y^2)),Learner2D(0:0.1:1,0:0.1:1))

# Balanced learner
# List of functions
zarr = 0:0.1:1
farr = [p->((x,y)=p;exp(-x^2-y^2)) for z in zarr]
larr = [Learner2D(0:0.1:1,0:0.1:1) for z in zarr]
map(farr,larr)

# Parallel test. 
pmap(x->exp(-x^2),Learner1D(0:0.1:1))
pmap(p->(sleep(0.1);(x,y)=p;exp(-x^2-y^2)),Learner2D(0:0.1:1,0:0.1:1))
pmap(farr,larr)

```