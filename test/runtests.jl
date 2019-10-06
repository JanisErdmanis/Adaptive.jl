#using Revise

using Adaptive
using Distributed

@info "Testing ask! and tell! methods"
function simpledriver!(f, learner,step)
    while !(learner.loss() < step)
        xi = ask!(learner,true)
        yi = f(xi) 
        tell!(learner,(xi,yi))
    end
end

learner1d = AdaptiveLearner1D((0,1))
simpledriver!(x->exp(-x^2),learner1d,0.1)

learner2d = AdaptiveLearner2D([(0,1),(0,1)])
simpledriver!(x->exp(-x[1]^2 - x[2]^2),learner2d,0.1)




@info "Testing atribute access"

@show learner1d.loss
@show learner1d.x
@show learner1d.y
@show learner1d.data

@show learner2d.loss
@show learner2d.points
@show learner2d.vertices
@show learner2d.values
@show learner2d.ip

