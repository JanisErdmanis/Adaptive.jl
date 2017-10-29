using Adaptive
using PyPlot

N = 17
addprocs(N)

#### 1D case ####
@everywhere f(x) = exp(-x^2)

fig = figure()

x = collect(linspace(-2,2,200))
plot(x,f.(x),label=L"e^{-x^2}")

xx = linspace(-2,2,20)
plot(collect(xx),f.(xx),".-",label="even sampling")

res1 = map(f,Learner1D(xx))
plot(res1[:p],res1[:v],".-",label="Adaptive 1D N=1")

res2 = pmap(x->(sleep(0.1);f(x)),Learner1D(xx))
plot(res2[:p],res2[:v],".-",label="Adaptive 1D N=$N")

legend()
savefig("1D.png")
close("all")

#### 2D case ####
#@everywhere f(p) = ((x,y)=p; exp(-(x^2 + y^2 - 0.75^2)^2/0.2^4))
@everywhere f(p) = ((x,y)=p; exp(-x^2 - y^2))

fig = figure()

xx = linspace(-3,3,1000)
yy = linspace(-3,3,1000)

res1 = map(f,Learner2D(xx,yy))

p,tri,v = res1[:p], res1[:tri], res1[:v]

tricontourf(p[:,1],p[:,2],tri,v)
triplot(p[:,1],p[:,2],tri,"k.-")

savefig("2D:N=1.png")
close("all")

#### 2D case parallel ########

fig = figure()

xx = linspace(-3,3,1000)
yy = linspace(-3,3,1000)

res1 = pmap(p->(sleep(0.1);f(p)),Learner2D(xx,yy))

p,tri,v = res1[:p], res1[:tri], res1[:v]

tricontourf(p[:,1],p[:,2],tri,v)
triplot(p[:,1],p[:,2],tri,"k.-")

savefig("2D:N=$(nprocs()).png")
close("all")

### 3D case parallel #####
@everywhere f(p) = (sleep(0.1);(x,y,z)=p; exp(-x^2 - y^2 - z^2))

fig = figure()

xx = linspace(-3,3,1000)
yy = linspace(-3,3,1000)
zz = linspace(0,1,10)

farr = [p->f((p...,zi)) for zi in zz]
larr = [Learner2D(xx,yy) for zi in zz]

res1 = pmap(farr,larr)

p,tri,v = res1[5][:p], res1[5][:tri], res1[5][:v] ### Slecting 5th layer

tricontourf(p[:,1],p[:,2],tri,v)
triplot(p[:,1],p[:,2],tri,"k.-")

savefig("3D:N=$(nprocs()).png")
close("all")
