__precompile__() # this module is safe to precompile
module Adaptive

using PyCall
const adaptive = PyNULL()
function __init__()
    copy!(adaptive, pyimport_conda("adaptive", "adaptive"))
end

import Base.getproperty

import TaskMaster: Learner, ask!, tell! 

abstract type AdaptiveLearner <: Learner end
ask!(learner::AdaptiveLearner) = learner.learner[:ask](1)[1][1]
tell!(learner::AdaptiveLearner,(xi,yi)) = learner.learner[:tell](xi,yi)

######### 1D #########

struct AdaptiveLearner1D <: AdaptiveLearner
    learner
end
AdaptiveLearner1D(box::Tuple{Number,Number}) = AdaptiveLearner1D(adaptive[:Learner1D](x->NaN,box))

function Base.getproperty(l::AdaptiveLearner1D,s::Symbol)
    learner = getfield(l,:learner)
    if s==:loss
        learner[:loss]()
    elseif s==:x
        d = [(key,value) for (key,value) in learner[:data]]
        x = Float64[i[1] for i in d]
        sort(x)
    elseif s==:y
        d = [(key,value) for (key,value) in learner[:data]]
        x = Float64[i[1] for i in d]
        y = Float64[i[2] for i in d]
        y[sortperm(x)]
    elseif s==:data
        learner[:data]
    elseif s==:pending
        Set(p for p in learner[:pending_points])        
    elseif s==:learner
        learner
    else
        error("No such field defined")
    end
end

########## 2D #############

struct AdaptiveLearner2D <: AdaptiveLearner
    learner
    AdaptiveLearner2D(box) = new(adaptive[:Learner2D](x->NaN,box))
end

function Base.getproperty(l::AdaptiveLearner2D,s::Symbol)
    learner = getfield(l,:learner)
    if s==:loss
        learner[:loss]()
    elseif s==:ip # Does not change a state, but rather represents it
        learner[:ip]()
    elseif s==:points
        tri = learner[:ip]()[:tri]
        tri[:points]
    elseif s==:vertices
        tri = learner[:ip]()[:tri]
        tri[:vertices] .+ 1
    elseif s==:data
        learner[:data]
    elseif s==:pending
        Set(p for p in learner[:pending_points])        
    elseif s==:values
        [v for v in py"$(learner.data).values()"]
    elseif s==:learner
        learner
    else
        error("No such field defined")
    end
end

export AdaptiveLearner1D, AdaptiveLearner2D, ask!, tell!

end 
