using Adaptive
using Base.Test

# write your own tests here
# @test 1 == 2

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

include("figures.jl")


