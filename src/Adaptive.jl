module Adaptive

using PyCall
@pyimport adaptive
import Base.push!
import Base.pmap
import Base.map

################### 1D ####################

immutable Learner1D
    learner
    range
end
Learner1D(range) = Learner1D(adaptive.Learner1D(x->NaN,(minimum(range),maximum(range))),range)

loss(l::Learner1D) = l.learner[:loss]()
push!(l::Learner1D,p) = ((x,y) = p; l.learner[:add_point](x,y))
pnext(l::Learner1D) = l.learner[:choose_points](1,add_data=true)[1][1]
pdone(l::Learner1D) = l.learner[:loss]() < step(l.range)

function data(l::Learner1D)
    d = [(key,value) for (key,value) in l.learner[:data]]
    x = Float64[i[1] for i in d]
    y = Float64[i[2] for i in d]
    sp = sortperm(x)
    loss = l.learner[:loss]()
    interp = x->1 ### Needs to be implemented
    return Dict(:p=>x[sp], :v=>y[sp], :loss=>loss, :interp=>interp)
end

######## 2D #############

immutable Learner2D
    learner
    rangex
    rangey
end
Learner2D(rangex,rangey) = Learner2D(adaptive.Learner2D(x->NaN,[(minimum(rangex),maximum(rangex)),(minimum(rangey),maximum(rangey))]),rangex,rangey)

loss(l::Learner2D) = l.learner[:loss]()
ninterp(l::Learner2D) = length(ll.learner[:_interp])
push!(l::Learner2D,x) = ((p,v) = x; l.learner[:add_point](p,v))
pnext(l::Learner2D) = l.learner[:choose_points](1,add_data=true)[1][:]
pdone(l::Learner2D) = (x=loss(l);println(x);x) < (step(l.rangex) + step(l.rangey))/2 ### Somehow arbitrary

function data(l::Learner2D)
    tri = l.learner[:ip]()[:tri][:simplices]
    nmax = maximum(tri)+1
    points = l.learner[:_points][1:nmax,:] ### Why do I need to do this?
    values = l.learner[:_values][1:nmax]
    loss = l.learner[:loss]()
    ip(x,y) = l.learner[:ip]()(x,y)[1]
    return Dict(:p=>points, :v=>values, :loss=>loss, :ip=>ip, :tri=>tri)
end

######## pmap here ################
function pmap(f, l::Union{Learner1D,Learner2D},np)
    np = np==0 ? nprocs() : np
    #np = nprocs()  # determine the number of processes available
    @sync begin
        for p=1:np
            if p != myid() || np == 1
                @async begin
                    while !pdone(l)
                        #xi = pnext(l)[1]
                        xi = pnext(l)
                        #push!(l,(xi,NaN)) ### So no worker would try to pick it up
                        yi = remotecall_fetch(f, p, xi)
                        push!(l,(xi,yi))
                    end
                end
            end
        end
    end
    return data(l)
end

pmap(f, l::Union{Learner1D,Learner2D}) = pmap(f,l,0)
map(f, l::Union{Learner1D,Learner2D}) = pmap(f,l,1)

### one may need to implement loss(learner) for learner and nworkers(learner)
######## pmap here ################
"""
balancer takes as input a list of learners larr and outputs a list of numbers which represents probability at which next worker is going to be choosen. If sum(balancer(larr))==0 pmap stops. 
"""
function pmap(f, larr::Array{Learner2D}, balancer::Function, np)
    np = np==0 ? nprocs() : np
    #np = nprocs()  # determine the number of processes available
    @sync begin
        for p=1:np
            if p != myid() || np == 1
                @async begin
                    while !(sum(balancer(larr))==0) #pdone(l)
                        prob = balancer(larr) ### quick fix.
                        println(prob)
                        #xi = pnext(l)[1]
                        i = sum(rand() .>= cumsum([0; prob]))
                        li = larr[i]
                        xi = pnext(li)
                        #push!(l,(xi,NaN)) ### So no worker would try to pick it up
                        yi = remotecall_fetch(f[i], p, xi)
                        push!(li,(xi,yi))
                    end
                end
            end
        end
    end
    return [data(li) for li in larr]
end

function defaultbalancer(larr::Array{Learner2D})
    prob = []
    for li in larr
        lossi = loss(li)
        stepi = (step(li.rangex) + step(li.rangey))/2
        probi = stepi>lossi ? 0 : lossi
        push!(prob,probi)
    end
    if sum(prob)==0
        return prob
    else
        prob = prob/sum(prob) ### normalizing
        if sum(isnan.(prob))==0
            return prob
        else
            prob = [isnan(i) for i in prob/sum(prob)]
            prob = prob/sum(prob)
            return prob
        end
    end
end

function pmap(f,larr::Array{Learner2D}, balancer::Symbol, np)
    if balancer==:default
        return pmap(f,larr,defaultbalancer,np)
    else
        error("Not implemented")
    end
end

### Is it going to work?
pmap(f,larr::Array{Learner2D};balancer=:default) = pmap(f,larr,balancer,0)
map(f,larr::Array{Learner2D},balancer=:default) = pmap(f,larr,balancer,1)
#map(f,larr::Array{Learner2D}) = pmap(f,larr,balancer=:default;np=1)

export Learner1D, Learner2D, pmap, map, loss, ninterp

end # module
