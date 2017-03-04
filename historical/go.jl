#!/usr/bin/julia

type point
    x::Float64
    y::Float64
    a::Float64
end

type apoint{T}
    x::T
    y::T
    a::T
end

type points{T}
    x::Array{T}
    y::Array{T}
    a::Array{T}
end

function f(i,a,x,y)
    a[i] = x[i] * y[i]
    a[i] = a[i] / x[i] * y[i]
end

function run()
  n=1000000

  x=rand(n)
  y=rand(n)
  a=zeros(n)

  xx=zeros(n)
  yy=zeros(n)
  aa=zeros(n)

  myarray=Array(point,n)
  amyarray=Array(apoint{Float64},n)
  aamyarray=Array(apoint,n)
  arrayarray=points(x,y,a)

  for i in 1:n
     xx[i]        = x[i]
     yy[i]        = y[i]
     aa[i]        = a[i]
     myarray[i]   = point(x[i],y[i],a[i])
     amyarray[i]  = apoint{Float64}(x[i],y[i],a[i])
     aamyarray[i] = apoint{Float64}(x[i],y[i],a[i])
  end 

  print("Array Operations (comprehension)\n")
  @time begin
    aa = xx .* yy
    aa = aa ./ xx .* y
  end

  print("Multi Arrays\n")
  @time for i in 1:n
    a[i] = x[i] * y[i]
    a[i] = a[i] / x[i] * y[i]
  end

  print("Multi Arrays w/Function Call\n")
  @time for i in 1:n
    f(i,a,x,y)
  end

  print("Point Array\n")
  @time for i in 1:n
     myarray[i].a = myarray[i].x * myarray[i].y
     myarray[i].a = myarray[i].a / myarray[i].x * myarray[i].y
  end

  print("Dynamically Typed Point Array\n")
  @time for i in 1:n
     amyarray[i].a = amyarray[i].x * amyarray[i].y
     amyarray[i].a = amyarray[i].a / amyarray[i].x * amyarray[i].y
  end

  print("Very Dynamically Typed Point Array\n")
  @time for i in 1:n
     aamyarray[i].a = aamyarray[i].x * aamyarray[i].y
     aamyarray[i].a = aamyarray[i].a / aamyarray[i].x * aamyarray[i].y
  end

  print("Type of arrays\n")
  @time for i in 1:n
     arrayarray.a[i] = arrayarray.x[i] * arrayarray.y[i]
     arrayarray.a[i] = arrayarray.a[i] / arrayarray.x[i] * arrayarray.y[i]
  end
  
end

run()
